[CmdletBinding()]
param(
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$titleGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_probe_trace_guide.ps1'
$submitGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_trace_guide.ps1'
$formGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$submitRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1'
$sharedEnterRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1'

$guide = [ordered]@{
    issue = 'Google issue #3 probe triage'
    purpose = 'Route the newer issue #3 title, reduced-home submit-path, and shared Enter-order outputs into the next smallest headed validation step before widening back out to attached HTML or live Google replay.'
    title_trace_guide_command = $titleGuideCommand
    submit_path_trace_guide_command = $submitGuideCommand
    form_controls_trace_guide_command = $formGuideCommand
    recommended_runner_command = $recommendedRunnerCommand
    submit_path_runner_command = $submitRunnerCommand
    shared_enter_runner_command = $sharedEnterRunnerCommand
    triage_order = @(
        '1. Start with the title wrapper when the failure point is still unclear.',
        '2. Move to the reduced-home submit-path ladder only after focus and typed text look stable.',
        '3. Use the shared Enter-order gate when Google-shaped probes look green but keydown, keypress, and submit ordering still needs proof.',
        '4. Widen to attached HTML or live Google replay only after the bounded slices agree on the failing stage.'
    )
    quick_diagnosis = @(
        'A title-wrapper failure_stage of window_handle, ready_marker, typed_marker, enter_marker, or process_exit is still an early bounded failure; read that stage first before rerunning the broader issue #3 stack.',
        'If the title wrapper collected browse, session, runtime-input, or wndproc traces but never reached TYPED:, stay on the title checkpoint and inspect the native focus and text-delivery traces before reopening large backend changes.',
        'If the reduced-home submit-path output stops before typed_observed_at_utc or submit_observed_at_utc, the saved-homepage checkpoint is still failing earlier than the shared Enter-order gate.',
        'If keydown_observed_at_utc appears without keypress_observed_at_utc or doc_keypress_observed_at_utc, Enter reached the page too early in the chain; keep the investigation on the reduced-home or shared Enter-order checkpoints.',
        'If the reduced-home submit-path and shared Enter-order outputs both stay green, stop re-running the same bounded slices and move on to attached HTML or live Google replay to capture the next divergence.'
    )
    next_step = 'Print the narrower trace guide that matches the earliest failing checkpoint, rerun only that bounded helper, and keep attached HTML or live Google follow-up for after the bounded markers agree.'
}

if ($Json) {
    $guide | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 probe triage'
Write-Host ''
Write-Host ("Purpose: {0}" -f $guide.purpose)
Write-Host ("Title:   {0}" -f $guide.title_trace_guide_command)
Write-Host ("Submit:  {0}" -f $guide.submit_path_trace_guide_command)
Write-Host ("Shared:  {0}" -f $guide.form_controls_trace_guide_command)
Write-Host ("Run:     {0}" -f $guide.recommended_runner_command)
Write-Host ("Submit:  {0}" -f $guide.submit_path_runner_command)
Write-Host ("Shared:  {0}" -f $guide.shared_enter_runner_command)
Write-Host ''
Write-Host 'Triage order:'
foreach ($step in $guide.triage_order) {
    Write-Host ("- {0}" -f $step)
}
Write-Host ''
Write-Host 'Quick diagnosis:'
foreach ($rule in $guide.quick_diagnosis) {
    Write-Host ("- {0}" -f $rule)
}
Write-Host ''
Write-Host ("Next step: {0}" -f $guide.next_step)
