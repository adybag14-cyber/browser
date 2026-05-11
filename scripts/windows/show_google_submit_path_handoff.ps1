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
    $AnalysisPath = Join-Path $artifactRoot "google-enter-trace-analysis.json"
}
if (-not (Test-Path -LiteralPath $AnalysisPath -PathType Leaf)) {
    throw "Reduced Google Enter-trace analysis not found: $AnalysisPath"
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot "google-submit-path-handoff.json"
}

$analysis = Get-Content -LiteralPath $AnalysisPath -Raw | ConvertFrom-Json
$classification = if ($analysis.classification) { [string]$analysis.classification } else { "unknown" }

$surfaceCheckCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_submit_path_validation_surface.ps1'
$flowCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_validation_flow.ps1'
$traceGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_trace_guide.ps1'
$runnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1'
$homepageFixtureCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1'
$submitTimingCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_submit_timing_validation.ps1'
$sharedEnterOrderCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1'

$nextRunnerCommand = $runnerCommand
$nextFocus = 'Refresh the bounded submit-path stack and reopen the reduced Enter analysis before widening back out.'
$reason = if ($analysis.recommendation) {
    [string]$analysis.recommendation
} else {
    'Use the saved reduced Enter analysis to choose the next bounded submit-path checkpoint before widening back out.'
}

switch ($classification) {
    'server_not_ready' {
        $nextRunnerCommand = $homepageFixtureCommand
        $nextFocus = 'Repair the saved homepage fixture and localhost readiness before trusting later submit timing.'
    }
    'window_not_ready' {
        $nextRunnerCommand = $homepageFixtureCommand
        $nextFocus = 'Repair the headed window and saved homepage fixture checkpoint before the later submit-path ladder.'
    }
    'focus_not_observed' {
        $nextRunnerCommand = $homepageFixtureCommand
        $nextFocus = 'Stay on the saved homepage fixture until focus stabilizes before reopening later submit timing.'
    }
    'typed_text_not_observed' {
        $nextRunnerCommand = $homepageFixtureCommand
        $nextFocus = 'Stay on the saved homepage fixture until typed text survives before reopening later submit timing.'
    }
    'enter_keydown_missing' {
        $nextRunnerCommand = $homepageFixtureCommand
        $nextFocus = 'Keep the next replay on the saved homepage fixture until native Enter reaches the reduced path at all.'
    }
    'submit_before_keypress_or_keypress_missing' {
        $nextRunnerCommand = $submitTimingCommand
        $nextFocus = 'Keep the next replay on the reduced Enter and submit-timing checkpoints until keypress is observed before submit.'
    }
    'keypress_missing' {
        $nextRunnerCommand = $submitTimingCommand
        $nextFocus = 'Stay on the bounded submit-timing slice until keypress shows up on the reduced path.'
    }
    'submit_missing_after_keypress' {
        $nextRunnerCommand = $submitTimingCommand
        $nextFocus = 'Stay on the bounded submit-timing slice until submit consistently follows keypress on the reduced path.'
    }
    'submit_value_mismatch' {
        $nextRunnerCommand = $sharedEnterOrderCommand
        $nextFocus = 'Compare the reduced Enter analysis with the stricter shared Enter-order ladder to see where the query value changes.'
    }
    'enter_sequence_complete' {
        $nextRunnerCommand = $sharedEnterOrderCommand
        $nextFocus = 'The reduced Google-shaped Enter path is green, so move to the stricter shared Enter-order ladder before widening back out.'
    }
}

$handoff = [ordered]@{
    issue = 'Google submit-path handoff'
    purpose = 'Save one compact handoff artifact after the reduced Google Enter analysis so the next Windows replay can reopen the right bounded submit-path checkpoint without re-deriving the diagnosis.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repo_root = $repoRoot
    analysis_path = $AnalysisPath
    artifact_path = $ArtifactPath
    classification = $classification
    failure_stage = $analysis.failure_stage
    recommendation = $analysis.recommendation
    focused_worked = $analysis.focused_worked
    typed_worked = $analysis.typed_worked
    submitted_worked = $analysis.submitted_worked
    keydown_observed = $analysis.keydown_observed
    keypress_observed = $analysis.keypress_observed
    doc_keypress_observed = $analysis.doc_keypress_observed
    keypress_before_submit = $analysis.keypress_before_submit
    submit_value = $analysis.submit_value
    submit_value_matches_input = $analysis.submit_value_matches_input
    trace_artifacts = $analysis.trace_artifacts
    surface_check_command = $surfaceCheckCommand
    flow_command = $flowCommand
    recommended_command = $traceGuideCommand
    next_runner_command = $nextRunnerCommand
    broader_runner_command = $runnerCommand
    next_artifact_to_open = $AnalysisPath
    next_focus = $nextFocus
    reason = $reason
  }

$handoff | ConvertTo-Json -Depth 6 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $handoff | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google submit-path handoff'
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
Write-Host ("Guide:    {0}" -f $handoff.recommended_command)
Write-Host ("Run next: {0}" -f $handoff.next_runner_command)
Write-Host ("Surface:  {0}" -f $handoff.surface_check_command)
Write-Host ("Flow:     {0}" -f $handoff.flow_command)
Write-Host ("Broader:  {0}" -f $handoff.broader_runner_command)
