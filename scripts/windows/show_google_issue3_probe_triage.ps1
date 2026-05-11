[CmdletBinding()]
param(
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$manifestGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest.ps1'
$artifactBundleCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1'
$titleGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_probe_trace_guide.ps1'
$submitGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_trace_guide.ps1'
$formGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1'
$phaseBoundaryCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_phase_boundary.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$submitRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1'
$sharedEnterRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1'

$guide = [ordered]@{
    issue = 'Google issue #3 probe triage'
    purpose = 'Route the newer issue #3 refresh-status, handoff, manifest, artifact-bundle audit, title, reduced-home submit-path, and shared Enter-order outputs into the next smallest headed validation step before widening back out to attached HTML or live Google replay.'
    refresh_status_command = $refreshStatusCommand
    handoff_guide_command = $handoffGuideCommand
    manifest_guide_command = $manifestGuideCommand
    artifact_bundle_command = $artifactBundleCommand
    title_trace_guide_command = $titleGuideCommand
    submit_path_trace_guide_command = $submitGuideCommand
    form_controls_trace_guide_command = $formGuideCommand
    phase_boundary_command = $phaseBoundaryCommand
    recommended_runner_command = $recommendedRunnerCommand
    submit_path_runner_command = $submitRunnerCommand
    shared_enter_runner_command = $sharedEnterRunnerCommand
    triage_order = @(
        '1. Start with the saved refresh-status helper after a recommended runner replay so you know whether the current issue #3 guide, boundary, bundle, and handoff artifacts are fresh enough to trust.',
        '2. If the refresh-status helper recommends a refresh, run that command before trusting the saved handoff, manifest, guide, or boundary helpers.',
        '3. Once the refresh-status helper says the chain is ready, open the saved handoff helper so one bundle-first artifact can point at the best current narrow replay step.',
        '4. Use the saved manifest helper once the handoff says the helper chain is coherent and you want the richest artifact index for the current replay.',
        '5. Read the saved phase-boundary helper when you need the exact last-pass / first-fail handoff after the manifest points at a failing checkpoint.',
        '6. Start with the title wrapper when the failure point is still unclear and you need the earliest bounded real-surface markers.',
        '7. Move to the reduced-home submit-path ladder only after focus and typed text look stable.',
        '8. Use the shared Enter-order gate when Google-shaped probes look green but keydown, keypress, and submit ordering still needs proof.',
        '9. Widen to attached HTML or live Google replay only after the bounded slices and the saved helper chain agree on the failing stage.'
    )
    quick_diagnosis = @(
        'If the refresh-status helper reports refresh-recommended, rebuild the helper chain before trusting older handoff, manifest, guide, or boundary output.',
        'If the refresh-status helper reports stale cross-references or stale summary helpers, refresh the current helper chain before rerunning broader issue #3 probes.',
        'If the handoff helper reports a non-passed surface_check_status, restore the recommended validation surface before rerunning later issue #3 phases.',
        'If the handoff helper reports an artifact_bundle_status other than complete, refresh the current helper chain before trusting older manifest, guide, or boundary output.',
        'If the manifest or boundary helper already names the next JSON artifact to open, read that file before scanning the broader logs or rerunning a larger wrapper.',
        'A title-wrapper failure_stage of window_handle, ready_marker, typed_marker, enter_marker, or process_exit is still an early bounded failure; read that stage first before rerunning the broader issue #3 stack.',
        'If the title wrapper collected browse, session, runtime-input, or wndproc traces but never reached TYPED:, stay on the title checkpoint and inspect the native focus and text-delivery traces before reopening large backend changes.',
        'If the reduced-home submit-path output stops before typed_observed_at_utc or submit_observed_at_utc, the saved-homepage checkpoint is still failing earlier than the shared Enter-order gate.',
        'If keydown_observed_at_utc appears without keypress_observed_at_utc or doc_keypress_observed_at_utc, Enter reached the page too early in the chain; keep the investigation on the reduced-home or shared Enter-order checkpoints.',
        'If the reduced-home submit-path and shared Enter-order outputs both stay green, stop re-running the same bounded slices and move on to attached HTML or live Google replay to capture the next divergence.'
    )
    next_step = 'Run the refresh-status helper first. If it recommends refreshing the saved helper chain, do that before opening the handoff helper; otherwise open the handoff helper and rerun only the narrower bounded helper or phase that matches its next_artifact_to_open guidance.'
}

if ($Json) {
    $guide | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 probe triage'
Write-Host ''
Write-Host ("Purpose: {0}" -f $guide.purpose)
Write-Host ("Refresh:  {0}" -f $guide.refresh_status_command)
Write-Host ("Handoff:  {0}" -f $guide.handoff_guide_command)
Write-Host ("Manifest: {0}" -f $guide.manifest_guide_command)
Write-Host ("Bundle:   {0}" -f $guide.artifact_bundle_command)
Write-Host ("Title:    {0}" -f $guide.title_trace_guide_command)
Write-Host ("Submit:   {0}" -f $guide.submit_path_trace_guide_command)
Write-Host ("Shared:   {0}" -f $guide.form_controls_trace_guide_command)
Write-Host ("Boundary: {0}" -f $guide.phase_boundary_command)
Write-Host ("Run:      {0}" -f $guide.recommended_runner_command)
Write-Host ("Submit:   {0}" -f $guide.submit_path_runner_command)
Write-Host ("Shared:   {0}" -f $guide.shared_enter_runner_command)
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
