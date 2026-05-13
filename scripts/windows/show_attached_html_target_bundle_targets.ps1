[CmdletBinding()]
param(
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$targets = @(
    [ordered]@{
        name = 'google-safety-centre'
        display_name = 'Control your online safety and privacy – Google Safety Centre'
        purpose = 'Google-like content-heavy compatibility target that should stay first in the attached bundle replay because it aligns with the issue #3 localhost-first ladder.'
        expected_signals = @(
            'google safety centre',
            'control your online safety and privacy',
            'online security and privacy',
            'safety.google'
        )
        primary_change_area = 'attached-html-target-bundle'
        first_bounded_step = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle'
        follow_up = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait'
    }
    [ordered]@{
        name = 'anthropic-job-application'
        display_name = 'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic'
        purpose = 'Form-heavy compatibility target that helps distinguish general headed input regressions from the narrower Google-only path.'
        expected_signals = @(
            'job application',
            'interpretability at anthropic',
            'job-boards.greenhouse.io',
            'ashbyhq.com'
        )
        primary_change_area = 'input'
        first_bounded_step = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea input'
        follow_up = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_localhost_html_validation_recommended.ps1 -Wait'
    }
    [ordered]@{
        name = 'uap-encounters'
        display_name = 'Presidential Unsealing and Reporting System for UAP Encounters'
        purpose = 'Dense document and script-heavy compatibility target that helps separate rendering-path failures from input-only issues.'
        expected_signals = @(
            'presidential unsealing and reporting system for uap encounters',
            'department of war',
            'pursue'
        )
        primary_change_area = 'rendering'
        first_bounded_step = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering'
        follow_up = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1'
    }
)

$result = [ordered]@{
    issue = 'Attached HTML compatibility bundle targets'
    purpose = 'Expose the pinned three-page attached HTML bundle in one helper so future headed replays can confirm the expected targets before debugging bundle discovery or localhost follow-up routing.'
    target_count = $targets.Count
    bundle_surface_check = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle_validation_surface.ps1'
    bundle_checker = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_target_bundle.ps1'
    bundle_flow = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1'
    bundle_runner = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait'
    targets = $targets
    notes = @(
        'Use this helper before the bundle checker when you want one stable reminder of the expected pages and route priorities.',
        'Keep the Google Safety Centre page first when the bundle is complete so the issue #3 localhost-first follow-up stays aligned with the current Windows runbook.',
        'Treat the Anthropic page as the form-heavy general input check and the UAP page as the denser rendering-path check once the pinned bundle route is understood.'
    )
}

if ($Json) {
    $result | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Attached HTML compatibility bundle targets'
Write-Host ''
Write-Host ("Purpose: {0}" -f $result.purpose)
Write-Host ("Target count: {0}" -f $result.target_count)
Write-Host ("Bundle surface check: {0}" -f $result.bundle_surface_check)
Write-Host ("Bundle checker: {0}" -f $result.bundle_checker)
Write-Host ("Bundle flow helper: {0}" -f $result.bundle_flow)
Write-Host ("Bundle runner: {0}" -f $result.bundle_runner)
Write-Host ''

foreach ($target in $result.targets) {
    Write-Host ("[{0}] {1}" -f $target.name, $target.display_name)
    Write-Host ("  Purpose: {0}" -f $target.purpose)
    Write-Host ("  Expected signals: {0}" -f ($target.expected_signals -join ', '))
    Write-Host ("  Primary change area: {0}" -f $target.primary_change_area)
    Write-Host ("  First bounded step: {0}" -f $target.first_bounded_step)
    Write-Host ("  Follow-up: {0}" -f $target.follow_up)
    Write-Host ''
}

Write-Host 'Notes:'
foreach ($note in $result.notes) {
    Write-Host ("- {0}" -f $note)
}
