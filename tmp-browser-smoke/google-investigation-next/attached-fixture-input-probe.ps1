[CmdletBinding()]
param(
    [string]$FixturePath,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$InputText = "n",
    [string]$ReadyTitleContains,
    [string[]]$ReadyTitleContainsAny = @(),
    [string]$ExpectedTypedTitleContains,
    [string]$ExpectedEnterTitleContains,
    [int]$Port = 9586,
    [int]$TimeoutSeconds = 90,
    [int]$PollMilliseconds = 250,
    [int]$ClickX = -1,
    [int]$ClickY = -1,
    [switch]$SendEnter,
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($FixturePath)) {
    throw "FixturePath is required."
}

$scriptRoot = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $scriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}
if (-not (Test-Path -LiteralPath $BrowserExe)) {
    throw "headed browser binary not found: $BrowserExe"
}

$fixtureItem = Get-Item -LiteralPath $FixturePath -ErrorAction Stop
if ($fixtureItem.PSIsContainer) {
    throw "FixturePath must point to a single HTML file."
}

. (Join-Path $RepoRoot "tmp-browser-smoke\common\Win32Input.ps1")

$artifactRoot = Join-Path $scriptRoot "attached-fixture-probe"
$serverRoot = Join-Path $artifactRoot "server-root"
$serverStdout = Join-Path $artifactRoot "fixture-server.stdout.txt"
$serverStderr = Join-Path $artifactRoot "fixture-server.stderr.txt"
$browserStdout = Join-Path $artifactRoot "fixture-browser.stdout.txt"
$browserStderr = Join-Path $artifactRoot "fixture-browser.stderr.txt"
$browseTrace = Join-Path $scriptRoot "browse-render.log"
$rendererTrace = Join-Path $scriptRoot "runtime-renderer.log"
$sessionTrace = Join-Path $scriptRoot "session-wait.log"

if (Test-Path -LiteralPath $artifactRoot) {
    Remove-Item -LiteralPath $artifactRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $serverRoot | Out-Null

foreach ($path in @($serverStdout, $serverStderr, $browserStdout, $browserStderr, $browseTrace, $rendererTrace, $sessionTrace)) {
    if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Force
    }
}
Get-ChildItem -Path $scriptRoot -Filter "runtime-input-backend-*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $scriptRoot -Filter "wndproc-input-*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

$baseName = [System.IO.Path]::GetFileNameWithoutExtension($fixtureItem.Name)
$extension = $fixtureItem.Extension
$safeStem = [System.Text.RegularExpressions.Regex]::Replace($baseName, "[^A-Za-z0-9._-]", "_")
if ([string]::IsNullOrWhiteSpace($safeStem)) {
    $safeStem = "fixture"
}
$stagedName = "{0}{1}" -f $safeStem, $extension
$stagedPath = Join-Path $serverRoot $stagedName
Copy-Item -LiteralPath $fixtureItem.FullName -Destination $stagedPath -Force

function Get-TraceSummary([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $content = Get-Content -LiteralPath $Path -Raw
    if ([string]::IsNullOrWhiteSpace($content)) {
        return ""
    }

    $lines = $content -split "`r?`n" | Where-Object { $_ -ne "" }
    if ($lines.Count -le 6) {
        return ($lines -join "`n")
    }

    return (($lines[-6..-1]) -join "`n")
}

function Get-TraceTailSummaries([string]$Root, [string]$Pattern) {
    $summaries = @()
    $files = Get-ChildItem -Path $Root -Filter $Pattern -File -ErrorAction SilentlyContinue |
        Sort-Object FullName
    foreach ($file in $files) {
        $summaries += [pscustomobject]@{
            name = $file.Name
            path = $file.FullName
            tail = Get-TraceSummary $file.FullName
        }
    }
    return $summaries
}

function Get-TraceArtifactPaths([string]$Root) {
    $artifacts = @()
    $patterns = @(
        "browse-render.log",
        "runtime-renderer.log",
        "session-wait.log",
        "runtime-input-backend-*.log",
        "wndproc-input-*.log"
    )
    foreach ($pattern in $patterns) {
        $artifacts += Get-ChildItem -Path $Root -Filter $pattern -File -ErrorAction SilentlyContinue |
            Sort-Object FullName |
            Select-Object -ExpandProperty FullName
    }
    return $artifacts
}

function Wait-HttpReady([string]$Url, [int]$Attempts) {
    for ($i = 0; $i -lt $Attempts; $i++) {
        Start-Sleep -Milliseconds 250
        try {
            $resp = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
            if ($resp.StatusCode -eq 200) {
                return $true
            }
        } catch {
        }
    }
    return $false
}

$readyMarkers = New-Object System.Collections.Generic.List[string]
if (-not [string]::IsNullOrWhiteSpace($ReadyTitleContains)) {
    $readyMarkers.Add($ReadyTitleContains)
}
foreach ($marker in $ReadyTitleContainsAny) {
    if ([string]::IsNullOrWhiteSpace($marker)) {
        continue
    }
    if (-not $readyMarkers.Contains($marker)) {
        $readyMarkers.Add($marker)
    }
}

$probeUrl = "http://127.0.0.1:$Port/$stagedName?google-home-probe=1"
$readyUrl = "http://127.0.0.1:$Port/$stagedName"
$server = $null
$browser = $null
$serverReady = $false
$failureStage = "server_start"
$trace = New-Object System.Collections.Generic.List[object]
$lastTitle = ""
$matchedReady = ($readyMarkers.Count -eq 0)
$matchedTyped = [string]::IsNullOrWhiteSpace($ExpectedTypedTitleContains)
$matchedEnter = (-not $SendEnter) -or [string]::IsNullOrWhiteSpace($ExpectedEnterTitleContains)
$typedSent = [string]::IsNullOrWhiteSpace($InputText)
$enterSent = -not $SendEnter
$windowPrepared = $false
$clickSent = ($ClickX -lt 0 -or $ClickY -lt 0)
$clickRequested = ($ClickX -ge 0 -and $ClickY -ge 0)
$readyMarkerMatched = $null

try {
    $server = Start-Process -FilePath "python" -ArgumentList "-m", "http.server", $Port, "--bind", "127.0.0.1" -WorkingDirectory $serverRoot -PassThru -RedirectStandardOutput $serverStdout -RedirectStandardError $serverStderr
    $serverReady = Wait-HttpReady -Url $readyUrl -Attempts 40
    if (-not $serverReady) {
        throw "fixture probe server did not become ready"
    }

    $failureStage = "window_handle"
    $browser = Start-Process -FilePath $BrowserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "1366", "--window_height", "900", $probeUrl) -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $browserStdout -RedirectStandardError $browserStderr
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $deadline) {
        if ($browser.HasExited) {
            break
        }

        if ($browser.MainWindowHandle -eq 0) {
            Start-Sleep -Milliseconds $PollMilliseconds
            continue
        }

        if (-not $windowPrepared) {
            Show-SmokeWindow ([IntPtr]$browser.MainWindowHandle)
            $windowPrepared = $true
            if (-not $matchedReady) {
                $failureStage = "ready_marker"
            } elseif (-not $matchedTyped) {
                $failureStage = "typed_marker"
            } elseif (-not $matchedEnter) {
                $failureStage = "enter_marker"
            } else {
                $failureStage = $null
            }
        }

        if (-not $clickSent) {
            [void](Invoke-SmokeClientClick -Hwnd ([IntPtr]$browser.MainWindowHandle) -X $ClickX -Y $ClickY)
            $clickSent = $true
        }

        $title = Get-SmokeWindowTitle ([IntPtr]$browser.MainWindowHandle)
        if ($title -and $title -ne $lastTitle) {
            $stamp = (Get-Date).ToUniversalTime().ToString("o")
            $trace.Add([pscustomobject]@{
                observed_at_utc = $stamp
                title = $title
            }) | Out-Null
            $lastTitle = $title
        }

        if (-not $matchedReady -and $title) {
            foreach ($marker in $readyMarkers) {
                if ($title.Contains($marker)) {
                    $matchedReady = $true
                    $readyMarkerMatched = $marker
                    if (-not $matchedTyped) {
                        $failureStage = "typed_marker"
                    } elseif (-not $matchedEnter) {
                        $failureStage = "enter_marker"
                    } else {
                        $failureStage = $null
                    }
                    break
                }
            }
        }

        if ($matchedReady -and -not $typedSent) {
            Send-SmokeAsciiText $InputText
            $typedSent = $true
            if ([string]::IsNullOrWhiteSpace($ExpectedTypedTitleContains)) {
                $matchedTyped = $true
                if (-not $matchedEnter) {
                    $failureStage = "enter_marker"
                } else {
                    $failureStage = $null
                }
            }
        }

        if ($typedSent -and -not $matchedTyped -and $title -and $title.Contains($ExpectedTypedTitleContains)) {
            $matchedTyped = $true
            if (-not $matchedEnter) {
                $failureStage = "enter_marker"
            } else {
                $failureStage = $null
            }
        }

        if ($matchedReady -and $matchedTyped -and -not $enterSent) {
            Send-SmokeEnter
            $enterSent = $true
            if ([string]::IsNullOrWhiteSpace($ExpectedEnterTitleContains)) {
                $matchedEnter = $true
                $failureStage = $null
            }
        }

        if ($enterSent -and -not $matchedEnter -and $title -and $title.Contains($ExpectedEnterTitleContains)) {
            $matchedEnter = $true
            $failureStage = $null
        }

        if ($matchedReady -and $matchedTyped -and $matchedEnter -and -not $LeaveOpen) {
            break
        }

        Start-Sleep -Milliseconds $PollMilliseconds
    }

    if ($browser.HasExited -and -not ($matchedReady -and $matchedTyped -and $matchedEnter)) {
        $failureStage = "process_exit"
    }
} finally {
    if (-not $LeaveOpen -and $browser -and -not $browser.HasExited) {
        Stop-Process -Id $browser.Id -Force -ErrorAction SilentlyContinue
    }
    if ($server -and -not $server.HasExited) {
        Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
    }
}

$result = [pscustomobject]@{
    fixture_path = $fixtureItem.FullName
    staged_path = $stagedPath
    probe_url = $probeUrl
    ready_markers = @($readyMarkers)
    ready_marker_matched = $readyMarkerMatched
    input_text = $InputText
    send_enter = [bool]$SendEnter
    click_requested = $clickRequested
    click_sent = $clickRequested -and $clickSent
    matched_ready = $matchedReady
    matched_typed = $matchedTyped
    matched_enter = $matchedEnter
    failure_stage = $failureStage
    last_title = $lastTitle
    trace = $trace
    browse_trace = Get-TraceSummary $browseTrace
    renderer_trace = Get-TraceSummary $rendererTrace
    session_trace = Get-TraceSummary $sessionTrace
    trace_artifacts = @(Get-TraceArtifactPaths $scriptRoot)
    backend_trace_tails = @(Get-TraceTailSummaries $scriptRoot "runtime-input-backend-*.log")
    wndproc_trace_tails = @(Get-TraceTailSummaries $scriptRoot "wndproc-input-*.log")
    browser_stdout = if (Test-Path -LiteralPath $browserStdout) { Get-Content -LiteralPath $browserStdout -Raw } else { $null }
    browser_stderr = if (Test-Path -LiteralPath $browserStderr) { Get-Content -LiteralPath $browserStderr -Raw } else { $null }
    server_stdout = if (Test-Path -LiteralPath $serverStdout) { Get-Content -LiteralPath $serverStdout -Raw } else { $null }
    server_stderr = if (Test-Path -LiteralPath $serverStderr) { Get-Content -LiteralPath $serverStderr -Raw } else { $null }
}

$result | ConvertTo-Json -Depth 8

if (-not ($matchedReady -and $matchedTyped -and $matchedEnter)) {
    exit 1
}
