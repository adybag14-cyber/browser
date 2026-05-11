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

    $helperOutcome = if ($helperFailure -or $helperExitCode -ne 0) {
        if ($helperResult -and $helperResult.failure_stage) {
            "failed:{0}" -f $helperResult.failure_stage
        } else {
            "failed"
        }
    } else {
        "completed"
    }

    $result = [pscustomobject]@{
        probe_url = $probeUrl
        helper_exit_code = $helperExitCode
        helper_failure = $helperFailure
        helper_outcome = $helperOutcome
        helper_failure_stage = if ($helperResult) { $helperResult.failure_stage } else { $null }
        helper_matched_ready_marker = if ($helperResult) { $helperResult.matched_ready_marker } else { $null }
        helper_ready_observed_at_utc = if ($helperResult) { $helperResult.ready_observed_at_utc } else { $null }
        helper_typed_observed_at_utc = if ($helperResult) { $helperResult.typed_observed_at_utc } else { $null }
        helper_enter_observed_at_utc = if ($helperResult) { $helperResult.enter_observed_at_utc } else { $null }
        helper_input_sent_at_utc = if ($helperResult) { $helperResult.input_sent_at_utc } else { $null }
        helper_enter_sent_at_utc = if ($helperResult) { $helperResult.enter_sent_at_utc } else { $null }
        helper_ready_title = if ($helperResult) { $helperResult.ready_title } else { $null }
        helper_ready_title_state = if ($helperResult) { $helperResult.ready_title_state } else { $null }
        helper_typed_title = if ($helperResult) { $helperResult.typed_title } else { $null }
        helper_typed_title_state = if ($helperResult) { $helperResult.typed_title_state } else { $null }
        helper_enter_title = if ($helperResult) { $helperResult.enter_title } else { $null }
        helper_enter_title_state = if ($helperResult) { $helperResult.enter_title_state } else { $null }
        helper_last_title = if ($helperResult) { $helperResult.last_title } else { $null }
        helper_last_title_state = if ($helperResult) { $helperResult.last_title_state } else { $null }
        helper_trace_path = if ($helperResult) { $helperResult.trace_path } else { $null }
        helper_trace_count = if ($helperResult -and $helperResult.trace) { @($helperResult.trace).Count } else { 0 }
        helper = $helperResult
        browse_trace = Get-TraceSummary $browseTrace
        renderer_trace = Get-TraceSummary $rendererTrace
        session_trace = Get-TraceSummary $sessionTrace
        trace_artifacts = @(Get-TraceArtifactPaths $scriptRoot)
        backend_trace_files = @(Get-ChildItem -Path $scriptRoot -Filter "runtime-input-backend-*.log" -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -ExpandProperty Name)
        wndproc_trace_files = @(Get-ChildItem -Path $scriptRoot -Filter "wndproc-input-*.log" -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -ExpandProperty Name)
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
