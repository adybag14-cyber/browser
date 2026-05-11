[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Url = "http://127.0.0.1:9582/src/browser/tests/page/google_home_title_probe.html",
    [string]$ExpectedTitleContains = "BOUND|",
    [string[]]$ExpectedTitleContainsAny = @(),
    [string]$ExpectedTypedTitleContains,
    [string]$ExpectedEnterTitleContains,
    [string]$InputText,
    [int]$TimeoutSeconds = 90,
    [int]$PollMilliseconds = 250,
    [switch]$SendEnter,
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

. (Join-Path $RepoRoot "tmp-browser-smoke\common\Win32Input.ps1")

$artifactRoot = Join-Path $RepoRoot "tmp-browser-smoke\headed-probe"
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null

$stdoutPath = Join-Path $artifactRoot "headed-probe.stdout.txt"
$stderrPath = Join-Path $artifactRoot "headed-probe.stderr.txt"
$tracePath = Join-Path $artifactRoot "headed-probe-trace.json"
if (Test-Path -LiteralPath $stdoutPath) { Remove-Item -LiteralPath $stdoutPath -Force }
if (Test-Path -LiteralPath $stderrPath) { Remove-Item -LiteralPath $stderrPath -Force }
if (Test-Path -LiteralPath $tracePath) { Remove-Item -LiteralPath $tracePath -Force }

$readyMarkers = New-Object System.Collections.Generic.List[string]
if (-not [string]::IsNullOrWhiteSpace($ExpectedTitleContains)) {
    $readyMarkers.Add($ExpectedTitleContains)
}
foreach ($marker in $ExpectedTitleContainsAny) {
    if ([string]::IsNullOrWhiteSpace($marker)) {
        continue
    }
    if (-not $readyMarkers.Contains($marker)) {
        $readyMarkers.Add($marker)
    }
}

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $BrowserExe
$psi.Arguments = "browse --browser_mode headed --window_width 1366 --window_height 768 `"$Url`""
$psi.WorkingDirectory = $RepoRoot
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $psi
$process.Start() | Out-Null

$stdoutTask = $process.StandardOutput.ReadToEndAsync()
$stderrTask = $process.StandardError.ReadToEndAsync()

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$lastTitle = ""
$matchedReady = ($readyMarkers.Count -eq 0)
$matchedTyped = [string]::IsNullOrEmpty($InputText)
$matchedEnter = -not $SendEnter
$inputSent = [string]::IsNullOrEmpty($InputText)
$enterSent = -not $SendEnter
$preparedWindow = $false
$trace = New-Object System.Collections.Generic.List[object]
$readyMarkerMatched = $null
$readyObservedAtUtc = $null
$readyTitle = $null
$readyTitleState = $null
$inputSentAtUtc = $null
$titleAtInputSend = $null
$typedObservedAtUtc = $null
$typedTitle = $null
$typedTitleState = $null
$enterSentAtUtc = $null
$titleAtEnterSend = $null
$enterObservedAtUtc = $null
$enterTitle = $null
$enterTitleState = $null
$failureStage = "window_handle"

function Convert-TitleState {
    param(
        [string]$Title
    )

    if ([string]::IsNullOrWhiteSpace($Title)) {
        return $null
    }

    $parts = $Title -split '\|'
    $state = [ordered]@{
        raw_title = $Title
        marker = if ($parts.Count -gt 0) { $parts[0] } else { $Title }
    }

    for ($i = 1; $i -lt $parts.Count; $i++) {
        $segment = $parts[$i]
        if ([string]::IsNullOrWhiteSpace($segment)) {
            continue
        }

        $pair = $segment -split '=', 2
        if ($pair.Count -ne 2) {
            $state[("extra_{0}" -f $i)] = $segment
            continue
        }

        $name = switch ($pair[0]) {
            'A' { 'active_element' }
            'Q' { 'query_element' }
            'V' { 'query_value' }
            'S' { 'selection' }
            'E' { 'last_event' }
            default { $pair[0].ToLowerInvariant() }
        }
        $state[$name] = $pair[1]
    }

    return [pscustomobject]$state
}

Write-Host ("Watching headed probe at {0}" -f $Url)
if ($readyMarkers.Count -gt 0) {
    Write-Host ("Expected ready title markers: {0}" -f ($readyMarkers -join " | "))
}
if ($InputText) {
    Write-Host ("Input text: {0}" -f $InputText)
}
if ($ExpectedTypedTitleContains) {
    Write-Host ("Expected typed title marker: {0}" -f $ExpectedTypedTitleContains)
}
if ($SendEnter) {
    Write-Host "Enter will be sent after the ready or typed condition is met."
}
if ($ExpectedEnterTitleContains) {
    Write-Host ("Expected enter title marker: {0}" -f $ExpectedEnterTitleContains)
}

while ((Get-Date) -lt $deadline) {
    if ($process.HasExited) {
        break
    }

    if ($process.MainWindowHandle -eq 0) {
        Start-Sleep -Milliseconds $PollMilliseconds
        continue
    }

    if (-not $preparedWindow) {
        Show-SmokeWindow ([IntPtr]$process.MainWindowHandle)
        $preparedWindow = $true
        if (-not $matchedReady) {
            $failureStage = "ready_marker"
        } elseif (-not $matchedTyped) {
            $failureStage = "typed_marker"
        } elseif (-not $matchedEnter) {
            $failureStage = "enter_marker"
        }
    }

    $title = Get-SmokeWindowTitle ([IntPtr]$process.MainWindowHandle)
    $titleState = Convert-TitleState $title
    if ($title -and $title -ne $lastTitle) {
        $stamp = (Get-Date).ToUniversalTime().ToString("o")
        $entry = [pscustomobject]@{
            observed_at_utc = $stamp
            title = $title
            state = $titleState
        }
        $trace.Add($entry) | Out-Null
        $lastTitle = $title
        Write-Host ("[{0}] {1}" -f $stamp, $title)
    }

    if (-not $matchedReady -and $title) {
        foreach ($marker in $readyMarkers) {
            if ($title.Contains($marker)) {
                $matchedReady = $true
                $readyMarkerMatched = $marker
                $readyObservedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
                $readyTitle = $title
                $readyTitleState = $titleState
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

    if ($matchedReady -and -not $inputSent) {
        Send-SmokeAsciiText $InputText
        $inputSent = $true
        $inputSentAtUtc = (Get-Date).ToUniversalTime().ToString("o")
        $titleAtInputSend = $title
        if ([string]::IsNullOrWhiteSpace($ExpectedTypedTitleContains)) {
            $matchedTyped = $true
            $typedObservedAtUtc = $inputSentAtUtc
            $typedTitle = $title
            $typedTitleState = $titleState
            if (-not $matchedEnter) {
                $failureStage = "enter_marker"
            } else {
                $failureStage = $null
            }
        }
    }

    if ($inputSent -and -not $matchedTyped -and $title -and $title.Contains($ExpectedTypedTitleContains)) {
        $matchedTyped = $true
        $typedObservedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
        $typedTitle = $title
        $typedTitleState = $titleState
        if (-not $matchedEnter) {
            $failureStage = "enter_marker"
        } else {
            $failureStage = $null
        }
    }

    if ($matchedReady -and $matchedTyped -and -not $enterSent) {
        Send-SmokeEnter
        $enterSent = $true
        $enterSentAtUtc = (Get-Date).ToUniversalTime().ToString("o")
        $titleAtEnterSend = $title
        if ([string]::IsNullOrWhiteSpace($ExpectedEnterTitleContains)) {
            $matchedEnter = $true
            $enterObservedAtUtc = $enterSentAtUtc
            $enterTitle = $title
            $enterTitleState = $titleState
            $failureStage = $null
        }
    }

    if ($enterSent -and -not $matchedEnter -and $title -and $title.Contains($ExpectedEnterTitleContains)) {
        $matchedEnter = $true
        $enterObservedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
        $enterTitle = $title
        $enterTitleState = $titleState
        $failureStage = $null
    }

    if ($matchedReady -and $matchedTyped -and $matchedEnter -and -not $LeaveOpen) {
        break
    }

    Start-Sleep -Milliseconds $PollMilliseconds
}

if ($process.HasExited -and -not ($matchedReady -and $matchedTyped -and $matchedEnter)) {
    $failureStage = "process_exit"
}

if (-not $LeaveOpen -and -not $process.HasExited) {
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
}

$stdoutTask.Wait()
$stderrTask.Wait()
$stdoutTask.Result | Set-Content -Path $stdoutPath -Encoding Ascii
$stderrTask.Result | Set-Content -Path $stderrPath -Encoding Ascii

$result = [pscustomobject]@{
    url = $Url
    expected_title_contains = $ExpectedTitleContains
    expected_title_contains_any = $readyMarkers
    expected_typed_title_contains = $ExpectedTypedTitleContains
    expected_enter_title_contains = $ExpectedEnterTitleContains
    input_text = $InputText
    send_enter = [bool]$SendEnter
    matched_ready = $matchedReady
    matched_typed = $matchedTyped
    matched_enter = $matchedEnter
    matched_ready_marker = $readyMarkerMatched
    ready_observed_at_utc = $readyObservedAtUtc
    ready_title = $readyTitle
    ready_title_state = $readyTitleState
    typed_observed_at_utc = $typedObservedAtUtc
    typed_title = $typedTitle
    typed_title_state = $typedTitleState
    enter_observed_at_utc = $enterObservedAtUtc
    enter_title = $enterTitle
    enter_title_state = $enterTitleState
    input_sent = $inputSent
    input_sent_at_utc = $inputSentAtUtc
    title_at_input_send = $titleAtInputSend
    enter_sent = $enterSent
    enter_sent_at_utc = $enterSentAtUtc
    title_at_enter_send = $titleAtEnterSend
    failure_stage = $failureStage
    last_title = $lastTitle
    last_title_state = Convert-TitleState $lastTitle
    leave_open = [bool]$LeaveOpen
    process_exited = $process.HasExited
    exit_code = if ($process.HasExited) { $process.ExitCode } else { $null }
    stdout_path = $stdoutPath
    stderr_path = $stderrPath
    trace_path = $tracePath
    trace = $trace
}

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $tracePath -Encoding Ascii
$result | ConvertTo-Json -Depth 6

if (-not ($matchedReady -and $matchedTyped -and $matchedEnter)) {
    throw "headed probe did not observe the expected title markers"
}
