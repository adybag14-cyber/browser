[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$AnalysisPath,
    [string]$ArtifactPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot([string]$StartPath) {
    if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
        return $env:LIGHTPANDA_REPO_ROOT
    }

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor "build.zig")) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            throw "Could not resolve the Lightpanda repo root from $StartPath. Set LIGHTPANDA_REPO_ROOT to override."
        }
        $cursor = $parent
    }
}

$repoRoot = if ($RepoRoot) {
    $RepoRoot
} else {
    Resolve-RepoRoot $PSScriptRoot
}
$artifactRoot = Join-Path $repoRoot "tmp-browser-smoke\headed-probe"
if (-not $AnalysisPath) {
    $AnalysisPath = Join-Path $artifactRoot "google-title-probe-analysis.json"
}
if (-not (Test-Path -LiteralPath $AnalysisPath -PathType Leaf)) {
    throw "Google title-probe analysis not found: $AnalysisPath"
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot "google-title-probe-handoff.json"
}

$analysis = Get-Content -LiteralPath $AnalysisPath -Raw | ConvertFrom-Json
$classification = if ($analysis.classification) { [string]$analysis.classification } else { "unknown" }

$titleProbeCommand = 'powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1'
$titleAnalysisCommand = 'powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\analyze-google-title-probe.ps1 -OutputPath .\tmp-browser-smoke\headed-probe\google-title-probe-analysis.json'
$submitAnalysisCommand = 'powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\analyze-google-enter-trace.ps1 -OutputPath .\tmp-browser-smoke\headed-probe\google-enter-trace-analysis.json'
$submitHandoffCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_handoff.ps1'
$broaderRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

$nextRunnerCommand = $titleProbeCommand
$recommendedCommand = $titleAnalysisCommand
$nextFocus = 'Keep the next replay on the title probe until the earliest ready, typed, and submit signals are coherent.'
$reason = if ($analysis.recommendation) {
    [string]$analysis.recommendation
} else {
    'Use the saved title-probe analysis to choose the next bounded checkpoint before widening back out.'
}

switch ($classification) {
    'title_probe_ready_missing' {
        $nextFocus = 'Repair title-probe readiness, focus, and raw trace capture before reopening later submit-path helpers.'
    }
    'title_probe_typed_missing' {
        $nextFocus = 'Stay on the title probe until text visibly survives in the Google-shaped local field.'
    }
    'title_probe_submit_missing' {
        $nextRunnerCommand = $submitAnalysisCommand
        $recommendedCommand = $submitHandoffCommand
        $nextFocus = 'Use the title probe as the quick narrowing point, then reopen the reduced Enter analysis to compare keydown, keypress, and submit ordering.'
    }
    'title_probe_process_exit' {
        $nextFocus = 'Repair headed lifetime and backend traces before trusting later input sequencing conclusions.'
    }
    'title_probe_typed_value_mismatch' {
        $nextFocus = 'Inspect how the typed title state differs from the expected query before widening back out.'
    }
    'title_probe_value_dropped_before_submit' {
        $nextRunnerCommand = $submitAnalysisCommand
        $recommendedCommand = $submitHandoffCommand
        $nextFocus = 'Compare the title-probe drop point with the reduced Enter analysis to find where the query value disappears.'
    }
    'title_probe_submit_value_mismatch' {
        $nextRunnerCommand = $submitAnalysisCommand
        $recommendedCommand = $submitHandoffCommand
        $nextFocus = 'Use the reduced Enter analysis next, because the title probe already shows the value mutating or diverging near submit.'
    }
    'title_probe_last_value_mismatch' {
        $nextFocus = 'Inspect the title-probe tail state and raw trace summaries before moving back to broader issue #3 replay.'
    }
    'title_probe_sequence_complete' {
        $nextRunnerCommand = $submitAnalysisCommand
        $recommendedCommand = $submitHandoffCommand
        $nextFocus = 'The title probe is coherent, so reopen the reduced Enter analysis or the broader issue #3 replay chain next.'
    }
}

$handoff = [ordered]@{
    issue = 'Google title-probe handoff'
    purpose = 'Save one compact handoff artifact after the headed Google title-probe analysis so the next Windows replay can reopen the right bounded checkpoint without re-reading the raw logs by hand.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repo_root = $repoRoot
    analysis_path = $AnalysisPath
    artifact_path = $ArtifactPath
    classification = $classification
    failure_stage = $analysis.failure_stage
    recommendation = $analysis.recommendation
    ready_marker = $analysis.ready_marker
    typed_marker = $analysis.typed_marker
    enter_marker = $analysis.enter_marker
    last_marker = $analysis.last_marker
    typed_query_value = $analysis.typed_query_value
    enter_query_value = $analysis.enter_query_value
    last_query_value = $analysis.last_query_value
    typed_value_matches_input = $analysis.typed_value_matches_input
    enter_value_matches_input = $analysis.enter_value_matches_input
    last_value_matches_input = $analysis.last_value_matches_input
    helper_trace_path = $analysis.helper_trace_path
    helper_trace_count = $analysis.helper_trace_count
    trace_artifacts = $analysis.trace_artifacts
    backend_trace_files = $analysis.backend_trace_files
    wndproc_trace_files = $analysis.wndproc_trace_files
    title_probe_command = $titleProbeCommand
    analysis_command = $titleAnalysisCommand
    next_runner_command = $nextRunnerCommand
    recommended_command = $recommendedCommand
    broader_runner_command = $broaderRunnerCommand
    next_artifact_to_open = $AnalysisPath
    next_focus = $nextFocus
    reason = $reason
}

$handoff | ConvertTo-Json -Depth 6 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $handoff | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google title-probe handoff'
Write-Host ''
Write-Host ("Analysis: {0}" -f $handoff.analysis_path)
Write-Host ("Handoff:  {0}" -f $handoff.artifact_path)
Write-Host ("Class:    {0}" -f $handoff.classification)
if ($handoff.failure_stage) {
    Write-Host ("Failure:  {0}" -f $handoff.failure_stage)
}
if ($handoff.recommendation) {
    Write-Host ("Reason:   {0}" -f $handoff.recommendation)
}
Write-Host ("Focus:    {0}" -f $handoff.next_focus)
Write-Host ("Open:     {0}" -f $handoff.next_artifact_to_open)
Write-Host ("Replay:   {0}" -f $handoff.title_probe_command)
Write-Host ("Analyze:  {0}" -f $handoff.analysis_command)
Write-Host ("Run next: {0}" -f $handoff.next_runner_command)
Write-Host ("Guide:    {0}" -f $handoff.recommended_command)
Write-Host ("Broader:  {0}" -f $handoff.broader_runner_command)
