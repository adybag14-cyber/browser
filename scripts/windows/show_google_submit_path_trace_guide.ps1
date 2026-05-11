[CmdletBinding()]
param(
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$guidePath = 'docs/GOOGLE_SUBMIT_PATH_VALIDATION.md'
$surfaceCheckCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_submit_path_validation_surface.ps1'
$flowCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_validation_flow.ps1'
$handoffCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_handoff.ps1'
$runnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1'
$homepageFixtureCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1'
$reducedEnterTraceAnalysisCommand = 'powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\analyze-google-enter-trace.ps1 -OutputPath .\tmp-browser-smoke\headed-probe\google-enter-trace-analysis.json'
$submitTimingCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_submit_timing_validation.ps1'
$sharedEnterOrderCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1'
$reducedEnterTraceArtifactPath = 'tmp-browser-smoke\headed-probe\google-enter-trace-analysis.json'
$handoffArtifactPath = 'tmp-browser-smoke\headed-probe\google-submit-path-handoff.json'

$guide = [ordered]@{
    issue = 'Google submit-path trace guide'
    purpose = 'Translate the later issue #3 submit-path outputs into the next narrowing step before widening back out to attached HTML or live Google replay.'
    guide_path = $guidePath
    surface_check_command = $surfaceCheckCommand
    flow_command = $flowCommand
    handoff_command = $handoffCommand
    runner_command = $runnerCommand
    homepage_fixture_command = $homepageFixtureCommand
    reduced_enter_trace_analysis_command = $reducedEnterTraceAnalysisCommand
    reduced_enter_trace_artifact_path = $reducedEnterTraceArtifactPath
    handoff_artifact_path = $handoffArtifactPath
    submit_timing_command = $submitTimingCommand
    shared_enter_order_command = $sharedEnterOrderCommand
    quick_diagnosis = @(
        'Run the submit-path handoff helper first after a bounded rerun; it reads google-enter-trace-analysis.json and points the next Windows replay at the right saved checkpoint before you widen back out.',
        'No title_after_focus or no FOCUS marker in the saved homepage fixture means the later submit path is not the first failure; click focus never stabilized on the reduced saved-homepage checkpoint.',
        'title_after_focus plus no title_after_type means the saved homepage fixture still lost typed text before Enter ordering became relevant.',
        'title_after_type plus no title_after_submit means the saved homepage fixture never observed Enter submit, so keep the investigation on that checkpoint before trusting the later timing slices.',
        'If google-enter-trace-analysis.json reports classification = submit_before_keypress_or_keypress_missing, stay on the reduced Enter checkpoint before trusting the later submit-timing or shared Enter-order slices.',
        'If google-enter-trace-analysis.json reports classification = keypress_missing or submit_missing_after_keypress, inspect the saved trace_artifacts listed in that JSON before widening back out to larger issue #3 helpers.',
        'If google-enter-trace-analysis.json reports classification = enter_sequence_complete but a later submit-timing or shared Enter-order slice still fails, the remaining gap is downstream of the reduced homepage Enter path.',
        'If google-submit-path-handoff.json points next_runner_command back to the homepage fixture, do not skip ahead to submit-timing or shared Enter-order yet.',
        'A submit-timing result with title_after_enter but keypress_before_submit = false means the Google-shaped headed timing slice still submits too early, before keypress reaches submit.',
        'A green saved homepage fixture, reduced Enter-trace analysis, and submit-timing slice plus a failing shared Enter-order runner means the remaining gap likely lives in the stricter shared form-controls or inline-flow handoff rather than the reduced Google-shaped probes.',
        'When the saved homepage fixture, reduced Enter-trace analysis, submit-timing slice, and shared Enter-order ladder all stay green together, move on to attached HTML or live Google trace capture instead of re-running the same bounded submit-path steps.'
    )
    next_step = 'Run the submit-path surface checker first, then the submit-path runner. After the bounded rerun, print the handoff helper. If the saved homepage fixture is green but later timing is still unclear, open tmp-browser-smoke\headed-probe\google-enter-trace-analysis.json and tmp-browser-smoke\headed-probe\google-submit-path-handoff.json before rerunning anything broader.'
}

if ($Json) {
    $guide | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google submit-path trace guide'
Write-Host ''
Write-Host ("Purpose: {0}" -f $guide.purpose)
Write-Host ("Guide:   {0}" -f $guide.guide_path)
Write-Host ("Check:   {0}" -f $guide.surface_check_command)
Write-Host ("Flow:    {0}" -f $guide.flow_command)
Write-Host ("Handoff: {0}" -f $guide.handoff_command)
Write-Host ("Run:     {0}" -f $guide.runner_command)
Write-Host ("Fixture: {0}" -f $guide.homepage_fixture_command)
Write-Host ("Trace:   {0}" -f $guide.reduced_enter_trace_analysis_command)
Write-Host ("Trace JSON: {0}" -f $guide.reduced_enter_trace_artifact_path)
Write-Host ("Handoff JSON: {0}" -f $guide.handoff_artifact_path)
Write-Host ("Timing:  {0}" -f $guide.submit_timing_command)
Write-Host ("Shared:  {0}" -f $guide.shared_enter_order_command)
Write-Host ''
Write-Host 'Quick diagnosis:'
foreach ($rule in $guide.quick_diagnosis) {
    Write-Host ("- {0}" -f $rule)
}
Write-Host ''
Write-Host ("Next step: {0}" -f $guide.next_step)
