[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$InputText = "n",
    [int]$Port = 9582,
    [int]$TimeoutSeconds = 90,
    [int]$PollMilliseconds = 250,
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $scriptRoot "..\..")).Path
}

$helper = Join-Path $RepoRoot "scripts\windows\watch_headed_probe.ps1"
if (-not (Test-Path -LiteralPath $helper)) {
    throw "headed probe helper not found: $helper"
}

$server = $null
$ready = $false
$serverOut = Join-Path $scriptRoot "google-home-title.server.stdout.txt"
$serverErr = Join-Path $scriptRoot "google-home-title.server.stderr.txt"
if (Test-Path -LiteralPath $serverOut) { Remove-Item -LiteralPath $serverOut -Force }
if (Test-Path -LiteralPath $serverErr) { Remove-Item -LiteralPath $serverErr -Force }

try {
    $server = Start-Process -FilePath "python" -ArgumentList "-m", "http.server", $Port, "--bind", "127.0.0.1" -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
    for ($i = 0; $i -lt 40; $i++) {
        Start-Sleep -Milliseconds 250
        try {
            $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$Port/src/browser/tests/page/google_home_title_probe.html" -TimeoutSec 2
            if ($resp.StatusCode -eq 200) {
                $ready = $true
                break
            }
        } catch {}
    }
    if (-not $ready) {
        throw "google home title probe server did not become ready"
    }

    & $helper `
        -RepoRoot $RepoRoot `
        -BrowserExe $BrowserExe `
        -Url "http://127.0.0.1:$Port/src/browser/tests/page/google_home_title_probe.html" `
        -ExpectedTitleContainsAny @("Q=INPUT:q::1", "BOUND|", "FOCUSED|") `
        -InputText $InputText `
        -ExpectedTypedTitleContains ("TYPED:{0}" -f $InputText) `
        -SendEnter `
        -ExpectedEnterTitleContains ("SUBMIT:{0}" -f $InputText) `
        -TimeoutSeconds $TimeoutSeconds `
        -PollMilliseconds $PollMilliseconds `
        -LeaveOpen:$LeaveOpen
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        exit $exitCode
    }
}
finally {
    if ($server) {
        $meta = Get-CimInstance Win32_Process -Filter "ProcessId=$($server.Id)" -ErrorAction SilentlyContinue |
            Select-Object Name, ProcessId, CommandLine, CreationDate
        if ($meta -and $meta.CommandLine -and $meta.CommandLine -notmatch "codex\.js|@openai/codex") {
            Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
        }
    }
}
