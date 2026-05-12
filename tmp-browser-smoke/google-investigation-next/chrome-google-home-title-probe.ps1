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

function Get-StateField($State, [string]$Name) {
    if ($null -eq $State) {
        return $null
    }

    $property = $State.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function Get-TraceTailSummary($Trace) {
    if ($null -eq $Trace) {
        return @()
    }

    $entries = @($Trace)
    if ($entries.Count -eq 0) {
        return @()
    }

    $start = [Math]::Max(0, $entries.Count - 5)
    $tail = @()
    for ($i = $start; $i -lt $entries.Count; $i++) {
        $entry = $entries[$i]
        $state = if ($entry) { $entry.state } else { $null }
        $tail += [pscustomobject]@{
            observed_at_utc = if ($entry) { $entry.observed_at_utc } else { $null }
            marker = Get-StateField $state "marker"
            active_element = Get-StateField $state "active_element"
            query_element = Get-StateField $state "query_element"
            query_value = Get-StateField $state "query_value"
            selection = Get-StateField $state "selection"
            last_event = Get-StateField $state "last_event"
            title = if ($entry) { $entry.title } else { $null }
        }
    }

    return $tail
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
            -ExpectedTitleContainsAny @("A=INPUT:q::1", "FOCUSED|") `
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

    $readyState = if ($helperResult) { $helperResult.ready_title_state } else { $null }
    $typedState = if ($helperResult) { $helperResult.typed_title_state } else { $null }
    $enterState = if ($helperResult) { $helperResult.enter_title_state } else { $null }
    $lastState = if ($helperResult) { $helperResult.last_title_state } else { $null }
    $helperTraceTail = if ($helperResult) { @(Get-TraceTailSummary $helperResult.trace) } else { @() }

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
        helper_ready_title_state = $readyState
        helper_ready_marker = Get-StateField $readyState "marker"
        helper_ready_active_element = Get-StateField $readyState "active_element"
        helper_ready_query_element = Get-StateField $readyState "query_element"
        helper_ready_query_value = Get-StateField $readyState "query_value"
        helper_ready_selection = Get-StateField $readyState "selection"
        helper_ready_last_event = Get-StateField $readyState "last_event"
        helper_typed_title = if ($helperResult) { $helperResult.typed_title } else { $null }
        helper_typed_title_state = $typedState
        helper_typed_marker = Get-StateField $typedState "marker"
        helper_typed_active_element = Get-StateField $typedState "active_element"
        helper_typed_query_element = Get-StateField $typedState "query_element"
        helper_typed_query_value = Get-StateField $typedState "query_value"
        helper_typed_selection = Get-StateField $typedState "selection"
        helper_typed_last_event = Get-StateField $typedState "last_event"
        helper_enter_title = if ($helperResult) { $helperResult.enter_title } else { $null }
        helper_enter_title_state = $enterState
        helper_enter_marker = Get-StateField $enterState "marker"
        helper_enter_active_element = Get-StateField $enterState "active_element"
        helper_enter_query_element = Get-StateField $enterState "query_element"
        helper_enter_query_value = Get-StateField $enterState "query_value"
        helper_enter_selection = Get-StateField $enterState "selection"
        helper_enter_last_event = Get-StateField $enterState "last_event"
        helper_last_title = if ($helperResult) { $helperResult.last_title } else { $null }
        helper_last_title_state = $lastState
        helper_last_marker = Get-StateField $lastState "marker"
        helper_last_active_element = Get-StateField $lastState "active_element"
        helper_last_query_element = Get-StateField $lastState "query_element"
        helper_last_query_value = Get-StateField $lastState "query_value"
        helper_last_selection = Get-StateField $lastState "selection"
        helper_last_event = Get-StateField $lastState "last_event"
        helper_trace_path = if ($helperResult) { $helperResult.trace_path } else { $null }
        helper_trace_count = if ($helperResult -and $helperResult.trace) { @($helperResult.trace).Count } else { 0 }
        helper_trace_tail = $helperTraceTail
        helper_trace_tail_markers = @($helperTraceTail | ForEach-Object { $_.marker })
        helper_trace_tail_query_values = @($helperTraceTail | ForEach-Object { $_.query_value })
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
