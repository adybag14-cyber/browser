[CmdletBinding()]
param(
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$guidePath = 'docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md'
$surfaceCheckCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1'
$flowCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1'
$wrapperCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1'
$rawProbeCommand = 'powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1'

$guide = [ordered]@{
    issue = 'Google form-controls Enter-order trace guide'
    purpose = 'Translate the dedicated shared Google-style Enter-order probe markers and JSON fields into click-focus, typed-text, held-keydown, keypress, and submit stages before widening issue #3 validation again.'
    guide_path = $guidePath
    surface_check_command = $surfaceCheckCommand
    flow_command = $flowCommand
    wrapper_command = $wrapperCommand
    raw_probe_command = $rawProbeCommand
    quick_diagnosis = @(
        'No title_after_click or no FOCUS marker means the headed click-focus path is still broken before typing starts.',
        'title_after_click plus no title_after_type means Enter-order is not the first failure; typed text never became visible after focus.',
        'keydown_held_without_submit = false means the page already submitted or navigated during held Enter keydown, before the later Enter phase settled.',
        'submit_record missing means the server-side proof never arrived, so do not treat a title-only transition as a green shared gate.',
        'submit_phase = keydown means the page still submitted too early, before keypress reached the form.',
        'An event_log with KD:Enter but no KP:Enter means the Enter keydown arrived but keypress still did not reach the page.',
        'KP:Enter plus no SUBMIT marker means keypress arrived but the form did not transition into submit.',
        'submit_phase = keypress with submit_after_keydown = true and submit_after_keypress = true is the exact green end-state for the dedicated gate.'
    )
    next_step = 'Run the dedicated surface checker first, print this guide or the full flow helper when needed, rerun the dedicated wrapper, and keep the JSON fields for issue notes before moving back to the wider shared Enter-order ladder or live Google follow-up.'
}

if ($Json) {
    $guide | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google form-controls Enter-order trace guide'
Write-Host ''
Write-Host ("Purpose: {0}" -f $guide.purpose)
Write-Host ("Guide:   {0}" -f $guide.guide_path)
Write-Host ("Check:   {0}" -f $guide.surface_check_command)
Write-Host ("Flow:    {0}" -f $guide.flow_command)
Write-Host ("Run:     {0}" -f $guide.wrapper_command)
Write-Host ("Raw:     {0}" -f $guide.raw_probe_command)
Write-Host ''
Write-Host 'Quick diagnosis:'
foreach ($rule in $guide.quick_diagnosis) {
    Write-Host ("- {0}" -f $rule)
}
Write-Host ''
Write-Host ("Next step: {0}" -f $guide.next_step)
