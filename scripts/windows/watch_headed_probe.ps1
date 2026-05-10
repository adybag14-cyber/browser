[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Url = "http://127.0.0.1:9582/src/browser/tests/page/google_home_title_probe.html",
    [string]$ExpectedTitleContains = "BOUND|",
    [int]$TimeoutSeconds = 90,
    [int]$PollMilliseconds = 250,
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not ("LightpandaProbeUser32" -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class LightpandaProbeUser32 {
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int GetWindowTextW(IntPtr hWnd, StringBuilder text, int count);
}
"@
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

$artifactRoot = Join-Path $RepoRoot "tmp-browser-smoke\headed-probe"
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null

$stdoutPath = Join-Path $artifactRoot "headed-probe.stdout.txt"
$stderrPath = Join-Path $artifactRoot "headed-probe.stderr.txt"
$tracePath = Join-Path $artifactRoot "headed-probe-trace.json"
if (Test-Path -LiteralPath $stdoutPath) { Remove-Item -LiteralPath $stdoutPath -Force }
if (Test-Path -LiteralPath $stderrPath) { Remove-Item -LiteralPath $stderrPath -Force }
if (Test-Path -LiteralPath $tracePath) { Remove-Item -LiteralPath $tracePath -Force }

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
$matchedExpectation = $false
$trace = New-Object System.Collections.Generic.List[object]

Write-Host ("Watching headed probe at {0}" -f $Url)
Write-Host ("Expected title marker: {0}" -f $ExpectedTitleContains)

while ((Get-Date) -lt $deadline) {
    if ($process.HasExited) {
        break
    }

    if ($process.MainWindowHandle -ne 0) {
        $buffer = New-Object System.Text.StringBuilder 2048
        [void][LightpandaProbeUser32]::GetWindowTextW($process.MainWindowHandle, $buffer, $buffer.Capacity)
        $title = $buffer.ToString()
        if ($title -and $title -ne $lastTitle) {
            $stamp = (Get-Date).ToUniversalTime().ToString("o")
            $entry = [pscustomobject]@{
                observed_at_utc = $stamp
                title = $title
            }
            $trace.Add($entry) | Out-Null
            $lastTitle = $title
            Write-Host ("[{0}] {1}" -f $stamp, $title)
            if ($ExpectedTitleContains -and $title.Contains($ExpectedTitleContains)) {
                $matchedExpectation = $true
                if (-not $LeaveOpen) {
                    break
                }
            }
        }
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
    matched_expectation = $matchedExpectation
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

if (-not $matchedExpectation) {
    throw "headed probe did not observe the expected title marker"
}
