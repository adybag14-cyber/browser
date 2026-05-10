[CmdletBinding()]
param(
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$guidePath = 'tmp-browser-smoke/google-investigation-next/GOOGLE_HOME_TITLE_PROBE_TRACE.md'
$wrapperCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_title_validation.ps1'
$flowCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_validation_flow.ps1'

$guide = [ordered]@{
    issue = 'Google title probe trace guide'
    purpose = 'Translate the bounded localhost title markers into focus, text-commit, and Enter-submit stages before widening issue #3 validation.'
    guide_path = $guidePath
    wrapper_command = $wrapperCommand
    flow_command = $flowCommand
    quick_diagnosis = @(
        'BOUND plus focus markers but no TYPED: means the failure is still before text commit.',
        'Character KEYDOWN: or KEYPRESS: markers with an empty V= field means events arrived without the value mutation landing.',
        'SUBMIT: with an empty value means Enter submit fired before the typed text committed.',
        'TYPED: plus the expected V= value without SUBMIT: means focus and text commit worked, but the Enter-submit path still diverged.'
    )
    next_step = 'Run the dedicated title wrapper first, then move to the quick, reduced homepage, submit-timing, or shared Enter-order helpers only after the title markers make the failing stage obvious.'
}

if ($Json) {
    $guide | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google title probe trace guide'
Write-Host ''
Write-Host ("Purpose: {0}" -f $guide.purpose)
Write-Host ("Guide:   {0}" -f $guide.guide_path)
Write-Host ("Flow:    {0}" -f $guide.flow_command)
Write-Host ("Run:     {0}" -f $guide.wrapper_command)
Write-Host ''
Write-Host 'Quick diagnosis:'
foreach ($rule in $guide.quick_diagnosis) {
    Write-Host ("- {0}" -f $rule)
}
Write-Host ''
Write-Host ("Next step: {0}" -f $guide.next_step)
