[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$SharedInputText = "Q",
    [int]$SharedEnterOrderPort = 8157,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 60,
    [int]$HomeTitleWaitAttempts = 80,
    [int]$HomePollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-PowerShellSingleQuotedLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Add-SharedArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        $Value
    )

    if ($null -eq $Value) {
        return
    }
    if ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    $Arguments.Add("-$Name")
    if ($Value -is [string]) {
        $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $Value))
    } else {
        $Arguments.Add([string]$Value)
    }
}

$guidePath = 'docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md'
$surfaceCheckScript = '.\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1'
$flowScript = '.\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1'
$wrapperScript = '.\scripts\windows\run_google_form_controls_enter_order_validation.ps1'
$rawProbeScript = '.\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1'

$surfaceCheckArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $surfaceCheckArgs -Name RepoRoot -Value $RepoRoot

$sharedGuideArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedGuideArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedGuideArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $sharedGuideArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $sharedGuideArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $sharedGuideArgs -Name SharedEnterOrderPort -Value $SharedEnterOrderPort
Add-SharedArgument -Arguments $sharedGuideArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $sharedGuideArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $sharedGuideArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $sharedGuideArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds

$wrapperArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $wrapperArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $wrapperArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $wrapperArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $wrapperArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $wrapperArgs -Name SharedEnterOrderPort -Value $SharedEnterOrderPort
Add-SharedArgument -Arguments $wrapperArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $wrapperArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $wrapperArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $wrapperArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds

$rawProbeArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $rawProbeArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $rawProbeArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $rawProbeArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $rawProbeArgs -Name InputText -Value $SharedInputText
Add-SharedArgument -Arguments $rawProbeArgs -Name Port -Value $SharedEnterOrderPort
Add-SharedArgument -Arguments $rawProbeArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $rawProbeArgs -Name WindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $rawProbeArgs -Name TitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $rawProbeArgs -Name PollMilliseconds -Value $HomePollMilliseconds

$surfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File $surfaceCheckScript$(if ($surfaceCheckArgs.Count -gt 0) { ' ' + ($surfaceCheckArgs -join ' ') } else { '' })"
$flowCommand = "powershell -ExecutionPolicy Bypass -File $flowScript$(if ($sharedGuideArgs.Count -gt 0) { ' ' + ($sharedGuideArgs -join ' ') } else { '' })"
$wrapperCommand = "powershell -ExecutionPolicy Bypass -File $wrapperScript$(if ($wrapperArgs.Count -gt 0) { ' ' + ($wrapperArgs -join ' ') } else { '' })"
$rawProbeCommand = "powershell -ExecutionPolicy Bypass -File $rawProbeScript$(if ($rawProbeArgs.Count -gt 0) { ' ' + ($rawProbeArgs -join ' ') } else { '' })"

$guide = [ordered]@{
    issue = 'Google form-controls Enter-order trace guide'
    purpose = 'Translate the dedicated shared Google-style Enter-order probe markers and JSON fields into click-focus, typed-text, held-keydown, keypress, and submit stages before widening issue #3 validation again.'
    guide_path = $guidePath
    host = $Host
    shared_input_text = $SharedInputText
    shared_enter_order_port = $SharedEnterOrderPort
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
Write-Host ("Host:    {0}" -f $guide.host)
Write-Host ("Input:   {0}" -f $guide.shared_input_text)
Write-Host ("Port:    {0}" -f $guide.shared_enter_order_port)
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
