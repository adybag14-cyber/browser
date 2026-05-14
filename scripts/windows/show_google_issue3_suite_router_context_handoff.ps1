[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
    [string]$BrowserExe,
    [string]$Host = '127.0.0.1',
    [string]$SubmitTimingInputText = 'QZ',
    [string]$SharedInputText = 'Q',
    [string]$TraceInputText = 'lightpanda',
    [switch]$LeaveOpen,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

function Add-SharedPathArrayArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string[]]$Values
    )

    if (-not $Values -or $Values.Count -eq 0) {
        return
    }

    $Arguments.Add("-$Name")
    foreach ($value in $Values) {
        $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $value))
    }
}

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [System.Collections.Generic.List[string]]$Arguments,
        [string[]]$Switches = @()
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\$ScriptName"
    if ($Arguments -and $Arguments.Count -gt 0) {
        $command += " " + ($Arguments -join ' ')
    }
    foreach ($switchName in $Switches) {
        if ([string]::IsNullOrWhiteSpace($switchName)) {
            continue
        }

        $command += " -$switchName"
    }

    return $command
}

function Format-HelperCommandWithRepoRootEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [hashtable]$Arguments = @{},
        [string[]]$Switches = @(),
        [string]$RepoRootOverride
    )

    if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        $fallbackArguments = [System.Collections.Generic.List[string]]::new()
        foreach ($entry in $Arguments.GetEnumerator()) {
            Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $entry.Value
        }
        return Format-HelperCommand -ScriptName $ScriptName -Arguments $fallbackArguments -Switches $Switches
    }

    $command = "& '.\\scripts\\windows\\$ScriptName'"
    foreach ($entry in $Arguments.GetEnumerator()) {
        $value = $entry.Value
        if ($null -eq $value) {
            continue
        }
        if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        $escapedValue = ("$value") -replace "'", "''"
        $command += (" -{0} '{1}'" -f $entry.Key, $escapedValue)
    }

    foreach ($switchName in $Switches) {
        if ([string]::IsNullOrWhiteSpace($switchName)) {
            continue
        }

        $command += " -$switchName"
    }

    $escapedRepoRoot = ("$RepoRootOverride") -replace "'", "''"
    return "powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$env:LIGHTPANDA_REPO_ROOT = '$escapedRepoRoot'; $command`""
}

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\\..')).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot 'zig-out\\bin\\lightpanda.exe'
}

$explicitRepoRoot = $PSBoundParameters.ContainsKey('RepoRoot') -or -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)
$explicitSummaryPath = $PSBoundParameters.ContainsKey('SummaryPath')
$explicitBrowserExe = $PSBoundParameters.ContainsKey('BrowserExe')
$explicitInputPath = $InputPath -and @($InputPath).Count -gt 0
$hasPinnedContext = $explicitRepoRoot -or $explicitSummaryPath -or $explicitBrowserExe -or $explicitInputPath -or $Host -ne '127.0.0.1' -or $SubmitTimingInputText -ne 'QZ' -or $SharedInputText -ne 'Q' -or $TraceInputText -ne 'lightpanda' -or $LeaveOpen

$suiteRouterNextStepsArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $suiteRouterNextStepsArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $suiteRouterNextStepsArgs -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $suiteRouterNextStepsArgs -Name InputPath -Values $InputPath
Add-SharedArgument -Arguments $suiteRouterNextStepsArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $suiteRouterNextStepsArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $suiteRouterNextStepsArgs -Name SubmitTimingInputText -Value $SubmitTimingInputText
Add-SharedArgument -Arguments $suiteRouterNextStepsArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $suiteRouterNextStepsArgs -Name TraceInputText -Value $TraceInputText

$contextualFlowArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $contextualFlowArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $contextualFlowArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $contextualFlowArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $contextualFlowArgs -Name InputText -Value $SubmitTimingInputText
Add-SharedArgument -Arguments $contextualFlowArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $contextualFlowArgs -Name TraceInputText -Value $TraceInputText
Add-SharedArgument -Arguments $contextualFlowArgs -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $contextualFlowArgs -Name InputPath -Values $InputPath
$contextualFlowSwitches = @()
if ($LeaveOpen) {
    $contextualFlowSwitches += 'LeaveOpen'
}

$submitTimingArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $submitTimingArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $submitTimingArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $submitTimingArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $submitTimingArgs -Name InputText -Value $SubmitTimingInputText

$sharedEnterArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedEnterArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedEnterArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $sharedEnterArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $sharedEnterArgs -Name SharedInputText -Value $SharedInputText

$traceArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $traceArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $traceArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $traceArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $traceArgs -Name InputText -Value $TraceInputText
$traceSwitches = @()
if ($LeaveOpen) {
    $traceSwitches += 'LeaveOpen'
}

$attachedGoogleArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedPathArrayArgument -Arguments $attachedGoogleArgs -Name InputPath -Values $InputPath
$attachedGoogleSwitches = @()
if ($LeaveOpen) {
    $attachedGoogleSwitches += 'LeaveOpen'
}

$bundleArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArgs -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleArgs -Name InputPath -Values $InputPath

$helper = [ordered]@{
    issue = 'Google issue #3 suite-router context handoff'
    purpose = 'Provide a one-command bridge from the top-level headed validation suite router into the context-preserving issue #3 helper stack when repo root, browser path, host, saved summary, pinned bundle inputs, or later-stage input strings already matter.'
    repo_root = $RepoRoot
    browser_exe = $BrowserExe
    host = $Host
    summary_path = $SummaryPath
    submit_timing_input_text = $SubmitTimingInputText
    shared_input_text = $SharedInputText
    trace_input_text = $TraceInputText
    explicit_input_path_count = if ($explicitInputPath) { @($InputPath).Count } else { 0 }
    leave_open = [bool]$LeaveOpen
    recommended_next_key = if ($hasPinnedContext) { 'contextual_flow' } else { 'suite_router_next_steps' }
    recommended_next_reason = if ($hasPinnedContext) {
        'Context is already pinned, so switch to the contextual-flow helper next and keep the same repo root, browser path, host, summary path, bundle inputs, and later-stage issue #3 text values aligned.'
    } else {
        'No extra replay context is pinned yet, so use the next-step matrix first to confirm the likely route before narrowing into the broader contextual flow.'
    }
    note_path = 'docs/ISSUE3_SUITE_ROUTER_CONTEXT_HANDOFF.md'
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    commands = [ordered]@{
        google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        google_input_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $suiteRouterNextStepsArgs
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $contextualFlowArgs -Switches $contextualFlowSwitches
        submit_timing_flow = Format-HelperCommand -ScriptName 'show_google_submit_timing_validation_flow.ps1' -Arguments $submitTimingArgs
        shared_enter_order_flow = Format-HelperCommand -ScriptName 'show_google_shared_enter_order_validation_flow.ps1' -Arguments $sharedEnterArgs
        live_trace_flow = Format-HelperCommand -ScriptName 'show_google_trace_validation_flow.ps1' -Arguments $traceArgs -Switches $traceSwitches
        attached_google_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedGoogleArgs -Switches $attachedGoogleSwitches
        attached_bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleArgs
    }
    notes = @(
        'Start with google_recommended or google_input_change_area when the replay is still choosing its broad route from the main headed validation catalog.',
        'Use suite_router_next_steps while the route still needs branch selection and you only want the fastest current helper recommendation printed from that routed state.',
        'Switch to contextual_flow as soon as repo root, browser path, host, summary path, pinned bundle inputs, or later-stage issue #3 text values need to stay aligned across multiple helpers.',
        'Use submit_timing_flow when the next question is still the bounded keydown, keypress, and submit-order slice on the current repo root, browser, and host.',
        'Use shared_enter_order_flow when the stricter shared keypress-before-submit ladder is the next narrow checkpoint on the same host, browser, and repo-root context.',
        'Use live_trace_flow only after the bounded localhost and shared Enter-order gates are green and you want the reduced-home or live-trace handoff reopened without rebuilding the same context by hand.',
        'Use attached_google_flow when the next replay should keep the current attached-page set pinned before widening back into the broader manual Google-style follow-up.',
        'Use attached_bundle_flow when the current saved or attached pages are still the known three-page compatibility bundle and that narrower route should run before another broader Google-only replay.',
        'Keep note_path, quickstart_note_path, and validation_chain_note_path open beside this helper when the next Windows replay needs both the command surface and the written route guidance.'
    )
}

$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 suite-router context handoff'
Write-Host ''
Write-Host ("Purpose: {0}" -f $helper.purpose)
Write-Host ("Repo root: {0}" -f $helper.repo_root)
Write-Host ("Browser exe: {0}" -f $helper.browser_exe)
Write-Host ("Host: {0}" -f $helper.host)
Write-Host ("Submit text: {0}" -f $helper.submit_timing_input_text)
Write-Host ("Shared text: {0}" -f $helper.shared_input_text)
Write-Host ("Trace text: {0}" -f $helper.trace_input_text)
if ($helper.summary_path) {
    Write-Host ("Summary path: {0}" -f $helper.summary_path)
}
if ($helper.explicit_input_path_count -gt 0) {
    Write-Host ("Input paths: {0}" -f $helper.explicit_input_path_count)
}
Write-Host ("Leave open: {0}" -f $helper.leave_open)
Write-Host ''
Write-Host ("Recommended next helper: {0}" -f $helper.recommended_next_command)
Write-Host ("Why:                   {0}" -f $helper.recommended_next_reason)
Write-Host ''
Write-Host 'Read-first commands:'
Write-Host ("  Google recommended: {0}" -f $helper.commands.google_recommended)
Write-Host ("  Google input:       {0}" -f $helper.commands.google_input_change_area)
Write-Host ("  Next-step matrix:   {0}" -f $helper.commands.suite_router_next_steps)
Write-Host ("  Contextual flow:    {0}" -f $helper.commands.contextual_flow)
Write-Host ''
Write-Host 'Narrower follow-up commands:'
Write-Host ("  Submit timing:      {0}" -f $helper.commands.submit_timing_flow)
Write-Host ("  Shared enter order: {0}" -f $helper.commands.shared_enter_order_flow)
Write-Host ("  Live trace:         {0}" -f $helper.commands.live_trace_flow)
Write-Host ("  Attached Google:    {0}" -f $helper.commands.attached_google_flow)
Write-Host ("  Attached bundle:    {0}" -f $helper.commands.attached_bundle_flow)
Write-Host ''
Write-Host ("Context handoff note: {0}" -f $helper.note_path)
Write-Host ("Quickstart note:      {0}" -f $helper.quickstart_note_path)
Write-Host ("Validation chain:     {0}" -f $helper.validation_chain_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host ("- {0}" -f $note)
}
