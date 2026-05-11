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

$probeUrl = "http://127.0.0.1:$Port/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1"
$readyUrl = "http://127.0.0.1:$Port/src/browser/tests/page/google_home_title_probe.html"
$server = $null
$ready = $false
$serverOut = Join-Path $scriptRoot "google-home-title.server.stdout.txt"
$serverErr = Join-Path $scriptRoot "google-home-title.server.stderr.txt"
$browseTrace = Join-Path $scriptRoot "browse-render.log"
$rendererTrace = Join-Path $scriptRoot "runtime-renderer.log"
$sessionTrace = Join-Path $scriptRoot "session-wait.log"
if (Test-Path -LiteralPath $serverOut) { Remove-Item -LiteralPath $serverOut -Force }
if (Test-Path -LiteralPath $serverErr) { Remove-Item -LiteralPath $serverErr -Force }
if (Test-Path -LiteralPath $browseTrace) { Remove-Item -LiteralPath $browseTrace -Force }
if (Test-Path -LiteralPath $rendererTrace) { Remove-Item -LiteralPath $rendererTrace -Force }
if (Test-Path -LiteralPath $sessionTrace) { Remove-Item -LiteralPath $sessionTrace -Force }
Get-ChildItem -Path $scriptRoot -Filter "runtime-input-backend-*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $scriptRoot -Filter "wndproc-input-*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

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

try {
    $server = Start-Process -FilePath "python" -ArgumentList "-m", "http.server", $Port, "--bind", "127.0.0.1" -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
    for ($i = 0; $i -lt 40; $i++) {
        Start-Sleep -Milliseconds 250
        try {
            $resp = Invoke-WebRequest -UseBasicParsing -Uri $readyUrl -TimeoutSec 2
            if ($resp.StatusCode -eq 200) {
                $ready = $true
                break
            }
        } catch {}
    }
    if (-not $ready) {
        throw "google home title probe server did not become ready"
    }

    $helperJson = $null
    $helperResult = $null
    $helperFailure = $null
    $helperExitCode = 0
    try {
        $helperJson = & $helper `
            -RepoRoot $RepoRoot `
            -BrowserExe $BrowserExe `
            -Url $probeUrl `
            -ExpectedTitleContainsAny @("Q=INPUT:q::1", "BOUND|", "FOCUSED|") `
            -InputText $InputText `
            -ExpectedTypedTitleContains ("TYPED:{0}" -f $InputText) `
            -SendEnter `
            -ExpectedEnterTitleContains ("SUBMIT:{0}" -f $InputText) `
            -TimeoutSeconds $TimeoutSeconds `
            -PollMilliseconds $PollMilliseconds `
            -LeaveOpen:$LeaveOpen
        $helperExitCode = $LASTEXITCODE
        if (-not [string]::IsNullOrWhiteSpace($helperJson)) {
            $helperResult = $helperJson | ConvertFrom-Json
        }
    }
    catch {
        $helperFailure = $_.Exception.Message
        if ($LASTEXITCODE) {
            $helperExitCode = $LASTEXITCODE
        } else {
            $helperExitCode = 1
        }
    }

    $result = [pscustomobject]@{
        probe_url = $probeUrl
        helper_exit_code = $helperExitCode
        helper_failure = $helperFailure
        helper = $helperResult
        browse_trace = Get-TraceSummary $browseTrace
        renderer_trace = Get-TraceSummary $rendererTrace
        session_trace = Get-TraceSummary $sessionTrace
        backend_trace_files = @(Get-ChildItem -Path $scriptRoot -Filter "runtime-input-backend-*.log" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
        wndproc_trace_files = @(Get-ChildItem -Path $scriptRoot -Filter "wndproc-input-*.log" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
        server_stdout = if (Test-Path -LiteralPath $serverOut) { Get-Content -LiteralPath $serverOut -Raw } else { $null }
        server_stderr = if (Test-Path -LiteralPath $serverErr) { Get-Content -LiteralPath $serverErr -Raw } else { $null }
    }

    $result | ConvertTo-Json -Depth 8
    if ($helperFailure -or $helperExitCode -ne 0) {
        exit 1
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
