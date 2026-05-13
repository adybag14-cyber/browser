[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = '127.0.0.1',
    [string]$InputText = 'QZ',
    [string]$SharedInputText = 'Q',
    [string]$TraceInputText = 'lightpanda',
    [string]$SummaryPath,
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
    [switch]$ManualGoogleStyle,
    [switch]$LeaveOpen
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

        if ($value -is [System.Array]) {
            $escapedValues = @()
            foreach ($item in @($value)) {
                if ($null -eq $item) {
                    continue
                }
                if ($item -is [string] -and [string]::IsNullOrWhiteSpace($item)) {
                    continue
                }

                $escapedValues += (ConvertTo-PowerShellSingleQuotedLiteral -Value ([string]$item))
            }

            if ($escapedValues.Count -eq 0) {
                continue
            }

            $command += (" -{0} {1}" -f $entry.Key, ($escapedValues -join ' '))
            continue
        }

        $command += (" -{0} {1}" -f $entry.Key, (ConvertTo-PowerShellSingleQuotedLiteral -Value ([string]$value)))
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

$topLevelFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedPathArrayArgument -Arguments $topLevelFlowArguments -Name ManualInputPath -Values $InputPath
Add-SharedArgument -Arguments $topLevelFlowArguments -Name ManualInitialPage -Value $PreferredInitialPage
$topLevelFlowSwitches = @()
if ($ManualGoogleStyle) {
    $topLevelFlowSwitches += 'ManualGoogleStyle'
}
if ($LeaveOpen) {
    $topLevelFlowSwitches += 'LeaveOpen'
}

$contextualFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $contextualFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $contextualFlowArguments -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $contextualFlowArguments -Name Host -Value $Host
Add-SharedArgument -Arguments $contextualFlowArguments -Name InputText -Value $InputText
Add-SharedArgument -Arguments $contextualFlowArguments -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $contextualFlowArguments -Name TraceInputText -Value $TraceInputText
Add-SharedArgument -Arguments $contextualFlowArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $contextualFlowArguments -Name InputPath -Values $InputPath
Add-SharedArgument -Arguments $contextualFlowArguments -Name PreferredInitialPage -Value $PreferredInitialPage
$contextualFlowSwitches = @()
if ($ManualGoogleStyle) {
    $contextualFlowSwitches += 'ManualGoogleStyle'
}
if ($LeaveOpen) {
    $contextualFlowSwitches += 'LeaveOpen'
}

$shortcutArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $shortcutArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $shortcutArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $shortcutArguments -Name InputPath -Values $InputPath

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$bridge = [ordered]@{
    issue = 'Google issue #3 top-level flow context bridge'
    purpose = 'Keep the broad Google input validation flow, the repo-root-aware issue #3 helper chain, and the pinned attached-bundle route aligned when replay context already matters.'
    repo_root = $RepoRoot
    browser_exe = $BrowserExe
    host = $Host
    input_text = $InputText
    shared_input_text = $SharedInputText
    trace_input_text = $TraceInputText
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    preferred_initial_page = $PreferredInitialPage
    manual_google_style = [bool]$ManualGoogleStyle
    leave_open = [bool]$LeaveOpen
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    commands = [ordered]@{
        suite_router_google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        suite_router_google_input = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        suite_router_attached_bundle = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        top_level_google_flow = Format-HelperCommand -ScriptName 'show_google_input_validation_flow.ps1' -Arguments $topLevelFlowArguments -Switches $topLevelFlowSwitches
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $contextualFlowArguments -Switches $contextualFlowSwitches
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $shortcutArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $shortcutArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $shortcutArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $shortcutArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $shortcutArguments
        attached_bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleArguments
        attached_bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleArguments -Switches @('Wait')
    }
    notes = @(
        'Use top_level_google_flow when you want the familiar broad localhost-first ladder and only the manual follow-up inputs need to stay attached.',
        'Use contextual_flow when RepoRoot, BrowserExe, Host, SummaryPath, or fixed InputPath values already matter and the next helper chain should keep that context aligned.',
        'Use suite_catalog_entrypoints or suite_router_next_steps when you are re-entering issue #3 from the suite router and want the current helper recommendation printed before narrowing further.',
        'Use replay_shortcuts when the route is already narrowed and you want the tighter shortcut surface for the attached-bundle-first route and the safe-route entrypoints.',
        'Use safe_route_entrypoints after contextual_flow or replay_shortcuts when the replay is ready to move into the wrapper-heavy runner-state branch.',
        'Use suite_router_attached_bundle, attached_bundle_first, attached_bundle_flow, and attached_bundle_runner when the current saved or attached pages still match the known three-page compatibility bundle.',
        'Keep the quickstart, suite-router bridge, and validation-chain notes open beside this helper when you want the written route next to the emitted commands.',
        'The broad top-level Google flow helper does not carry SummaryPath into later issue #3 safe-route commands, so prefer contextual_flow whenever saved-summary routing matters.'
    )
}

$bridge.recommended_helper_key = if ($bridge.explicit_input_path_count -gt 0 -or -not [string]::IsNullOrWhiteSpace($bridge.summary_path)) {
    'contextual_flow'
} else {
    'top_level_google_flow'
}
$bridge.recommended_helper_command = $bridge.commands[$bridge.recommended_helper_key]
$bridge.recommended_helper_reason = if ($bridge.recommended_helper_key -eq 'contextual_flow') {
    'Pinned bundle inputs or a saved summary are already in play, so use the context-preserving issue #3 helper chain instead of the broader top-level flow alone.'
} else {
    'No saved summary or pinned bundle inputs are in play yet, so start with the broader top-level Google flow and narrow from there only if the replay needs more context.'
}

if ($Json) {
    $bridge | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 top-level flow context bridge'
Write-Host ''
Write-Host ("Repo root: {0}" -f $bridge.repo_root)
Write-Host ("Browser exe: {0}" -f $bridge.browser_exe)
Write-Host ("Host: {0}" -f $bridge.host)
if ($bridge.summary_path) {
    Write-Host ("Summary path: {0}" -f $bridge.summary_path)
}
if ($bridge.explicit_input_path_count -gt 0) {
    Write-Host ("Input paths: {0}" -f $bridge.explicit_input_path_count)
}
if ($bridge.preferred_initial_page) {
    Write-Host ("Preferred initial page: {0}" -f $bridge.preferred_initial_page)
}
Write-Host ("Manual Google-style attached follow-up: {0}" -f $bridge.manual_google_style)
Write-Host ("Leave open after selected helpers: {0}" -f $bridge.leave_open)
Write-Host ''
Write-Host ("Recommended helper: {0}" -f $bridge.recommended_helper_command)
Write-Host ("Why:                {0}" -f $bridge.recommended_helper_reason)
Write-Host ''
Write-Host 'Commands:'
Write-Host (("  Suite router (google-recommended): {0}") -f $bridge.commands.suite_router_google_recommended)
Write-Host (("  Suite router (google-input):       {0}") -f $bridge.commands.suite_router_google_input)
Write-Host (("  Suite router (attached bundle):    {0}") -f $bridge.commands.suite_router_attached_bundle)
Write-Host (("  Top-level Google flow:             {0}") -f $bridge.commands.top_level_google_flow)
Write-Host (("  Contextual flow:                   {0}") -f $bridge.commands.contextual_flow)
Write-Host (("  Suite catalog entrypoints:         {0}") -f $bridge.commands.suite_catalog_entrypoints)
Write-Host (("  Suite router next steps:           {0}") -f $bridge.commands.suite_router_next_steps)
Write-Host (("  Replay shortcuts:                  {0}") -f $bridge.commands.replay_shortcuts)
Write-Host (("  Safe-route entrypoints:            {0}") -f $bridge.commands.safe_route_entrypoints)
Write-Host (("  Attached bundle first:             {0}") -f $bridge.commands.attached_bundle_first)
Write-Host (("  Attached bundle flow:              {0}") -f $bridge.commands.attached_bundle_flow)
Write-Host (("  Attached bundle runner:            {0}") -f $bridge.commands.attached_bundle_runner)
Write-Host ''
Write-Host (("Quickstart note:       {0}") -f $bridge.quickstart_note_path)
Write-Host (("Suite-router bridge:   {0}") -f $bridge.suite_router_bridge_note_path)
Write-Host (("Validation chain note: {0}") -f $bridge.validation_chain_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $bridge.notes) {
    Write-Host (("- {0}") -f $note)
}
