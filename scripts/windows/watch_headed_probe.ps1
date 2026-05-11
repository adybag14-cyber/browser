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
    }

    $title = Get-SmokeWindowTitle ([IntPtr]$process.MainWindowHandle)
    if ($title -and $title -ne $lastTitle) {
        $stamp = (Get-Date).ToUniversalTime().ToString("o")
        $entry = [pscustomobject]@{
            observed_at_utc = $stamp
            title = $title
        }
        $trace.Add($entry) | Out-Null
        $lastTitle = $title
        Write-Host ("[{0}] {1}" -f $stamp, $title)
    }

    if (-not $matchedReady -and $title) {
        foreach ($marker in $readyMarkers) {
            if ($title.Contains($marker)) {
                $matchedReady = $true
                break
            }
        }
    }

    if ($matchedReady -and -not $inputSent) {
        Send-SmokeAsciiText $InputText
        $inputSent = $true
        if ([string]::IsNullOrWhiteSpace($ExpectedTypedTitleContains)) {
            $matchedTyped = $true
        }
    }

    if ($inputSent -and -not $matchedTyped -and $title -and $title.Contains($ExpectedTypedTitleContains)) {
        $matchedTyped = $true
    }

    if ($matchedReady -and $matchedTyped -and -not $enterSent) {
        Send-SmokeEnter
        $enterSent = $true
        if ([string]::IsNullOrWhiteSpace($ExpectedEnterTitleContains)) {
            $matchedEnter = $true
        }
    }

    if ($enterSent -and -not $matchedEnter -and $title -and $title.Contains($ExpectedEnterTitleContains)) {
        $matchedEnter = $true
    }

    if ($matchedReady -and $matchedTyped -and $matchedEnter -and -not $LeaveOpen) {
        break
    }

    Start-Sleep -Milliseconds $PollMilliseconds
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
    input_sent = $inputSent
    enter_sent = $enterSent
    last_title = $lastTitle
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
