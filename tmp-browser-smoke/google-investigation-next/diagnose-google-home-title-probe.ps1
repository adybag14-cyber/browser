[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$InputText = "n",
    [int]$Port = 9582,
    [int]$TimeoutSeconds = 90,
    [int]$PollMilliseconds = 250,
    [string]$SummaryPath,
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $scriptRoot "..\..")).Path
}

$probeScript = Join-Path $scriptRoot "chrome-google-home-title-probe.ps1"
if (-not (Test-Path -LiteralPath $probeScript)) {
    throw "reduced Google title probe helper not found: $probeScript"
}

if (-not $SummaryPath) {
    $SummaryPath = Join-Path $scriptRoot "google-home-title.summary.json"
}

$tracePath = Join-Path $RepoRoot "tmp-browser-smoke\headed-probe\headed-probe-trace.json"

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

function Get-LastTraceEntry($Probe) {
    if ($null -eq $Probe) {
        return $null
    }

    $entries = @($Probe.helper_trace_tail)
    if ($entries.Count -eq 0) {
        return $null
    }

    return $entries[$entries.Count - 1]
}

function Get-LikelyRuntimeGap([string]$Stage, [int]$ExitCode) {
    switch ($Stage) {
        "ready_marker" {
            return "The reduced Google fixture never reached a stable focused query-input state before typing began. Recheck focus bootstrap, query binding, and early page lifecycle ordering."
        }
        "typed_marker" {
            return "Typed text did not commit after focus. Recheck the native keydown/keypress/text_input boundary, exact text-input suppression ordering, and whether real later text is being dropped."
        }
        "enter_marker" {
            return "Text reached the probe but Enter did not finish submit at the expected phase. Recheck deferred native Enter submit ordering between keydown, keypress, and form submission."
        }
        "process_exit" {
            return "The headed browser exited before the reduced Google probe satisfied its markers. Recheck headed startup stability, crash output, and trace artifacts."
        }
        default {
            if ($ExitCode -eq 0) {
                return "No runtime gap detected by the reduced Google probe."
            }
            return "The reduced Google probe runner failed before it could classify the headed runtime boundary. Recheck the helper output and artifact paths."
        }
    }
}

function Get-RecommendedNextStep([string]$Stage, [int]$ExitCode) {
    switch ($Stage) {
        "ready_marker" {
            return "Inspect helper_ready_title_state, helper_trace_tail, and the reduced probe page focus markers before changing runtime input code."
        }
        "typed_marker" {
            return "Compare helper_trace_tail, backend_trace_tails, and wndproc_trace_tails to confirm whether keypress landed without matching later text input."
        }
        "enter_marker" {
            return "Compare the KEYDOWN and SUBMIT title transitions, then revisit the deferred native Enter submit path in src/browser/Page.zig and src/display/win32_backend.zig."
        }
        "process_exit" {
            return "Inspect stdout, stderr, browse_trace, renderer_trace, and session_trace before retrying the reduced probe."
        }
        default {
            if ($ExitCode -eq 0) {
                return "Replay the real homepage probe only after this reduced probe stays green."
            }
            return "Run the reduced probe again with fresh artifacts and inspect the captured helper failure message before choosing the next slice."
        }
    }
}

function Get-Classification([string]$Stage, [int]$ExitCode) {
    switch ($Stage) {
        "ready_marker" { return "focus_or_ready_marker_missing" }
        "typed_marker" { return "typed_text_not_committed" }
        "enter_marker" { return "enter_submit_not_observed" }
        "process_exit" { return "browser_exited_before_probe_completed" }
        default {
            if ($ExitCode -eq 0) {
                return "passed"
            }
            return "probe_runner_failure"
        }
    }
}

$probeJson = $null
$probe = $null
$probeFailure = $null
$probeExitCode = 0

try {
    $probeJson = & $probeScript `
        -RepoRoot $RepoRoot `
        -BrowserExe $BrowserExe `
        -InputText $InputText `
        -Port $Port `
        -TimeoutSeconds $TimeoutSeconds `
        -PollMilliseconds $PollMilliseconds `
        -LeaveOpen:$LeaveOpen
    $probeExitCode = $LASTEXITCODE
    if (-not [string]::IsNullOrWhiteSpace($probeJson)) {
        $probe = $probeJson | ConvertFrom-Json -Depth 10
    }
}
catch {
    $probeFailure = $_.Exception.Message
    if ($LASTEXITCODE) {
        $probeExitCode = $LASTEXITCODE
    } else {
        $probeExitCode = 1
    }
}

if ($null -eq $probe -and (Test-Path -LiteralPath $tracePath)) {
    try {
        $probe = Get-Content -LiteralPath $tracePath -Raw | ConvertFrom-Json -Depth 10
    }
    catch {
        if (-not $probeFailure) {
            $probeFailure = $_.Exception.Message
        }
    }
}

$stage = if ($probe) { $probe.helper_failure_stage } else { $null }
if ([string]::IsNullOrWhiteSpace($stage) -and $probeExitCode -eq 0) {
    $stage = "passed"
}

$classification = Get-Classification $stage $probeExitCode
$lastTraceEntry = Get-LastTraceEntry $probe

$summary = [pscustomobject]@{
    probe_script = $probeScript
    summary_path = $SummaryPath
    classification = $classification
    failure_stage = $stage
    probe_exit_code = $probeExitCode
    probe_failure = $probeFailure
    likely_runtime_gap = Get-LikelyRuntimeGap $stage $probeExitCode
    recommended_next_step = Get-RecommendedNextStep $stage $probeExitCode
    probe_url = if ($probe) { $probe.probe_url } else { $null }
    input_text = $InputText
    helper_outcome = if ($probe) { $probe.helper_outcome } else { $null }
    helper_ready_marker = if ($probe) { $probe.helper_ready_marker } else { $null }
    helper_ready_active_element = if ($probe) { $probe.helper_ready_active_element } else { $null }
    helper_ready_query_element = if ($probe) { $probe.helper_ready_query_element } else { $null }
    helper_ready_query_value = if ($probe) { $probe.helper_ready_query_value } else { $null }
    helper_typed_marker = if ($probe) { $probe.helper_typed_marker } else { $null }
    helper_typed_query_value = if ($probe) { $probe.helper_typed_query_value } else { $null }
    helper_typed_last_event = if ($probe) { $probe.helper_typed_last_event } else { $null }
    helper_enter_marker = if ($probe) { $probe.helper_enter_marker } else { $null }
    helper_enter_query_value = if ($probe) { $probe.helper_enter_query_value } else { $null }
    helper_enter_last_event = if ($probe) { $probe.helper_enter_last_event } else { $null }
    helper_last_marker = if ($probe) { $probe.helper_last_marker } else { $null }
    helper_last_query_value = if ($probe) { $probe.helper_last_query_value } else { $null }
    helper_last_event = if ($probe) { $probe.helper_last_event } else { $null }
    helper_trace_count = if ($probe) { $probe.helper_trace_count } else { 0 }
    helper_trace_tail_markers = if ($probe) { @($probe.helper_trace_tail_markers) } else { @() }
    helper_trace_tail_query_values = if ($probe) { @($probe.helper_trace_tail_query_values) } else { @() }
    last_trace_marker = if ($lastTraceEntry) { Get-StateField $lastTraceEntry "marker" } else { $null }
    last_trace_query_value = if ($lastTraceEntry) { Get-StateField $lastTraceEntry "query_value" } else { $null }
    last_trace_event = if ($lastTraceEntry) { Get-StateField $lastTraceEntry "last_event" } else { $null }
    browse_trace = if ($probe) { $probe.browse_trace } else { $null }
    renderer_trace = if ($probe) { $probe.renderer_trace } else { $null }
    session_trace = if ($probe) { $probe.session_trace } else { $null }
    trace_artifacts = if ($probe) { @($probe.trace_artifacts) } else { @() }
    backend_trace_files = if ($probe) { @($probe.backend_trace_files) } else { @() }
    wndproc_trace_files = if ($probe) { @($probe.wndproc_trace_files) } else { @() }
}

$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $SummaryPath -Encoding Ascii
$summary | ConvertTo-Json -Depth 8

if ($probeExitCode -ne 0) {
    exit $probeExitCode
}
