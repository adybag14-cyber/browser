[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
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

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$bundleFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleFlowArguments -Name InputPath -Values $InputPath

$runnerPatchStatePlaceholder = '<ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>'
$recommendedHelperKey = 'suite_router_handoff'
$recommendedHelperReason = 'Start from the higher-level suite-router handoff so the broader issue #3 entrypoints and the compact replay-route surface stay visible together before the replay narrows further.'
if ($InputPath -and @($InputPath).Count -gt 0) {
    $recommendedHelperKey = 'attached_bundle_first'
    $recommendedHelperReason = 'Explicit input paths are already pinned, so the fastest correct next step is the attached bundle-first helper before reopening the broader Google-only wrappers.'
} elseif (-not [string]::IsNullOrWhiteSpace($SummaryPath)) {
    $recommendedHelperKey = 'replay_route'
    $recommendedHelperReason = 'A saved SummaryPath is already available, so jump straight to the replay-route helper and preserve the existing replay context instead of reopening the broader suite-router handoff first.'
}

$matrix = @(
    [ordered]@{
        start_point = 'show_headed_validation_suites.ps1 -SuiteName google-recommended'
        default_next_helper = 'show_google_issue3_suite_router_handoff.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleArguments
        use_when = 'Start from the top-level suite catalog and want the current issue #3 read-first commands, replay-route helper, replay-shortcuts helper, attached-bundle helper, and safe-route map reprinted together before choosing the next route.'
    }
    [ordered]@{
        start_point = 'show_headed_validation_suites.ps1 -ChangeArea google-input'
        default_next_helper = 'show_google_issue3_replay_route.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        use_when = 'You already know the work stays inside issue #3 and want the compact replay-route surface right away.'
    }
    [ordered]@{
        start_point = 'show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle'
        default_next_helper = 'show_google_issue3_attached_bundle_first_entrypoint.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        use_when = 'The current saved or attached inputs are still the pinned three-page compatibility bundle and you want the one-command bundle-first helper to keep that locked route plus the safe-route return visible before the broader Google-only wrappers.'
    }
    [ordered]@{
        start_point = 'show_google_issue3_suite_router_handoff.ps1'
        default_next_helper = 'show_google_issue3_replay_route.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        use_when = 'The higher-level issue #3 router state is already confirmed and you want the tighter replay-route surface next.'
    }
    [ordered]@{
        start_point = 'show_google_issue3_replay_route.ps1'
        default_next_helper = 'show_google_issue3_replay_shortcuts.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        use_when = 'You want the narrower shortcut map before deciding between the attached-bundle-first route, the fresh safe-route replay, or the safe-route entrypoints helper.'
    }
    [ordered]@{
        start_point = 'wrapper-emitted runner state'
        default_next_helper = 'show_google_issue3_runner_patch_next_step.ps1'
        command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_patch_next_step.ps1' -Arguments ([ordered]@{
            SummaryPath = $SummaryPath
            State = $runnerPatchStatePlaceholder
        }) -RepoRootOverride $RepoRoot
        use_when = 'The current replay already has a saved summary path plus one of the three runner-patch states and you want the shortest exact next-step map.'
    }
)

$helper = [ordered]@{
    issue = 'Google issue #3 suite-router next steps'
    purpose = 'Print the fastest correct issue #3 helper after the top-level headed validation router, while preserving repo-root, saved-summary, and attached-bundle context when it already exists.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    recommended_helper_key = $recommendedHelperKey
    recommended_helper_reason = $recommendedHelperReason
    recommended_helper_command = switch ($recommendedHelperKey) {
        'attached_bundle_first' { Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments }
        'replay_route' { Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments }
        default { Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleArguments }
    }
    suite_router_commands = [ordered]@{
        suite_name_google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        change_area_google_input = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        change_area_attached_bundle = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        google_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        suite_router_handoff = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        attached_bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleFlowArguments
        attached_bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleFlowArguments -Switches @('Wait')
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
        fresh_safe_route_replay = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments $sharedArguments
        reuse_current_outputs = Format-HelperCommand -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments $sharedArguments
        runner_patch_next_step = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_patch_next_step.ps1' -Arguments ([ordered]@{
            SummaryPath = $SummaryPath
            State = $runnerPatchStatePlaceholder
        }) -RepoRootOverride $RepoRoot
    }
    suite_router_matrix = $matrix
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    decision_table_note_path = 'docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md'
    windows_runbook_path = 'docs/WINDOWS_FULL_USE.md'
    notes = @(
        'Use this helper when issue #3 work starts from the higher-level Windows validation router and you want the next helper chosen quickly without reopening the longer chain notes first.',
        'When RepoRoot is supplied, the top-level suite-router and Google-flow commands preserve that same LIGHTPANDA_REPO_ROOT context instead of falling back to the default checkout path.',
        'When SummaryPath is supplied, the replay-route, replay-shortcuts, safe-route entrypoints, fresh safe-route replay, reuse-current-outputs, and runner next-step helpers keep that same saved summary context attached.',
        'When InputPath is supplied, the suite-router handoff, replay-route, replay-shortcuts, and attached-bundle-first helpers keep the current fixed bundle inputs pinned instead of relying on auto-discovery.',
        'Use attached_bundle_first when the saved or attached pages are still the known three-page compatibility set and you want that route exercised before reopening the broader Google-only safe-route ladder.',
        'Use safe_route_entrypoints after the suite-router work is already out of the way and you want the current wrapper-heavy issue #3 commands, notes, and next-state helper surfaced in one place.',
        'Keep suite_router_bridge_note_path open for the prose bridge, quickstart_note_path for the shortest replay note, validation_chain_note_path for wrapper precedence, decision_table_note_path when the replay lands on ready-for-runner-patch, already-direct, or runner-already-wired-regenerate-outputs, and windows_runbook_path when the next replay should widen back into the broader attached or saved localhost HTML follow-up.'
    )
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 suite-router next steps'
Write-Host ''
if ($helper.repo_root) {
    Write-Host (("Repo root:   {0}") -f $helper.repo_root)
}
if ($helper.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($helper.summary_path)"))
}
if ($helper.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $helper.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended helper: {0}") -f $helper.recommended_helper_command)
Write-Host (("Why:                {0}") -f $helper.recommended_helper_reason)
Write-Host ''
Write-Host 'Read-first suite-router commands:'
Write-Host (("  Suite name:         {0}") -f $helper.suite_router_commands.suite_name_google_recommended)
Write-Host (("  Change area:        {0}") -f $helper.suite_router_commands.change_area_google_input)
Write-Host (("  Bundle change area: {0}") -f $helper.suite_router_commands.change_area_attached_bundle)
Write-Host (("  Google flow helper: {0}") -f $helper.suite_router_commands.google_flow)
Write-Host ''
Write-Host 'Next-step matrix:'
foreach ($entry in $helper.suite_router_matrix) {
    Write-Host (("- Start: {0}") -f $entry.start_point)
    Write-Host (("  Next helper: {0}") -f $entry.default_next_helper)
    Write-Host (("  Command:     {0}") -f $entry.command)
    Write-Host (("  Use when:    {0}") -f $entry.use_when)
    Write-Host ''
}
Write-Host 'Key helper commands:'
Write-Host (("  Suite-router handoff:   {0}") -f $helper.helper_commands.suite_router_handoff)
Write-Host (("  Replay route:           {0}") -f $helper.helper_commands.replay_route)
Write-Host (("  Replay shortcuts:       {0}") -f $helper.helper_commands.replay_shortcuts)
Write-Host (("  Bundle-first helper:    {0}") -f $helper.helper_commands.attached_bundle_first)
Write-Host (("  Bundle flow helper:     {0}") -f $helper.helper_commands.attached_bundle_flow)
Write-Host (("  Bundle runner:          {0}") -f $helper.helper_commands.attached_bundle_runner)
Write-Host (("  Safe route entrypoints: {0}") -f $helper.helper_commands.safe_route_entrypoints)
Write-Host (("  Fresh safe replay:      {0}") -f $helper.helper_commands.fresh_safe_route_replay)
Write-Host (("  Reuse current outputs:  {0}") -f $helper.helper_commands.reuse_current_outputs)
Write-Host (("  Runner next-step helper:{0}") -f (' ' + $helper.helper_commands.runner_patch_next_step))
Write-Host ''
Write-Host (("Quickstart note:         {0}") -f $helper.quickstart_note_path)
Write-Host (("Suite-router bridge note:{0}") -f (' ' + $helper.suite_router_bridge_note_path))
Write-Host (("Validation chain note:   {0}") -f $helper.validation_chain_note_path)
Write-Host (("Decision table:          {0}") -f $helper.decision_table_note_path)
Write-Host (("Windows runbook:         {0}") -f $helper.windows_runbook_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
