[CmdletBinding()]
param(
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$guidePath = 'docs/GOOGLE_SUBMIT_PATH_VALIDATION.md'
$surfaceCheckCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_submit_path_validation_surface.ps1'
$flowCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_validation_flow.ps1'
$runnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1'
$homepageFixtureCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1'
$submitTimingCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_submit_timing_validation.ps1'
$sharedEnterOrderCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1'

$guide = [ordered]@{
    issue = 'Google submit-path trace guide'
    purpose = 'Translate the later issue #3 submit-path outputs into the next narrowing step before widening back out to attached HTML or live Google replay.'
    guide_path = $guidePath
    surface_check_command = $surfaceCheckCommand
    flow_command = $flowCommand
    runner_command = $runnerCommand
    homepage_fixture_command = $homepageFixtureCommand
    submit_timing_command = $submitTimingCommand
    shared_enter_order_command = $sharedEnterOrderCommand
    quick_diagnosis = @(
        'No title_after_focus or no FOCUS marker in the saved homepage fixture means the later submit path is not the first failure; click focus never stabilized on the reduced saved-homepage checkpoint.',
        'title_after_focus plus no title_after_type means the saved homepage fixture still lost typed text before Enter ordering became relevant.',
        'title_after_type plus no title_after_submit means the saved homepage fixture never observed Enter submit, so keep the investigation on that checkpoint before trusting the later timing slices.',
        'A submit-timing result with title_after_enter but keypress_before_submit = false means the Google-shaped headed timing slice still submits too early, before keypress reaches submit.',
        'A green saved homepage fixture and submit-timing slice plus a failing shared Enter-order runner means the remaining gap likely lives in the stricter shared form-controls or inline-flow handoff rather than the reduced Google-shaped probes.',
        'When the saved homepage fixture, submit-timing slice, and shared Enter-order ladder all stay green together, move on to attached HTML or live Google trace capture instead of re-running the same bounded submit-path steps.'
    )
    next_step = 'Run the submit-path surface checker first, print the flow or this guide when needed, rerun the one-command submit-path runner, and widen back out only after the bounded homepage-fixture, submit-timing, and shared Enter-order slices agree.'
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
Write-Host ("Run:     {0}" -f $guide.runner_command)
Write-Host ("Fixture: {0}" -f $guide.homepage_fixture_command)
Write-Host ("Timing:  {0}" -f $guide.submit_timing_command)
Write-Host ("Shared:  {0}" -f $guide.shared_enter_order_command)
Write-Host ''
Write-Host 'Quick diagnosis:'
foreach ($rule in $guide.quick_diagnosis) {
    Write-Host ("- {0}" -f $rule)
}
Write-Host ''
Write-Host ("Next step: {0}" -f $guide.next_step)
