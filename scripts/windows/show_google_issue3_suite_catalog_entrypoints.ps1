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
        [string[]]$Switches = @(),
        [System.Collections.Generic.List[string]]$Arguments
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

$googleFlowCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $RepoRoot
$contextualFlowCommand = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments

$entrypoints = [ordered]@{
    issue = 'Google issue #3 suite catalog entrypoints'
    purpose = 'Keep the exact top-level show_headed_validation_suites entrypoints, the newer suite-catalog attached-page bridge, the current top-level shortcut bridge, the current Google flow helper, the issue-specific attached-page helpers, the current shortcut-first issue #3 replay helper, the compact next-step matrix, the context-preserving issue #3 replay flow, and the current safe-route replay helpers on one compact command surface before the route narrows into replay-route or the wrapper-heavy safe-route helpers.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    suite_catalog_commands = [ordered]@{
        google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        google_input_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_quickstart.ps1' -Arguments $bundleArguments
        top_level_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        google_flow = $googleFlowCommand
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = $contextualFlowCommand
        suite_router_handoff = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
        fresh_safe_route_replay = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments $sharedArguments
        reuse_current_outputs = Format-HelperCommand -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments $sharedArguments
    }
    bridge_sequence = [ordered]@{
        google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        google_input_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_quickstart.ps1' -Arguments $bundleArguments
        top_level_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        google_flow = $googleFlowCommand
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        suite_router_handoff = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
    }
    notes = @(
        'Start with google_recommended when you want the broader localhost-first issue #3 runner surfaced from the suite catalog before choosing a narrower branch.',
        'Use google_input_change_area when the next replay may need the title, homepage-fixture, submit-path, shared Enter-order, live-trace, saved-page, or attached-page slices instead of the full recommended runner.',
        'Use attached_html_change_area when the next replay is already narrowed to attached-page follow-up but pinned bundle inputs are not yet locked, so the route can still prefer the new suite-catalog attached-page bridge before it falls back to the bundle-first branch.',
        'Use google_attached_html_change_area when the next replay is already narrowed to the issue-specific attached-page follow-up route but the broader suite-catalog entry surface still needs to stay visible on the same command surface.',
        'Use suite_catalog_attached_html_entrypoint as the default next helper after the top-level suite catalog when no pinned bundle inputs, repo-root override, or saved summary need to take precedence, because it keeps the newer attached-page chain visible before you choose between the top-level shortcut bridge, the issue-specific attached-page entrypoint, the attached-page shortcut, replay shortcuts, the next-step matrix, or the bundle-first branch.',
        'Use suite_router_quickstart when the top-level suite router already made issue #3 obvious and you want the shortest bridge into replay shortcuts, the next-step matrix, the bundle-first helper, and the safe-route map without reopening the wider catalog note first.',
        'Use top_level_shortcut_entrypoint when the route is already known to stay inside issue #3 and you want the shorter top-level bridge that still keeps the attached-page shortcut beside replay shortcuts, contextual flow, the next-step matrix, and the broader compact helpers.',
        'Use google_flow when you want the localhost-first issue #3 ladder printed before you decide whether to narrow into the shortcut-first replay helper, the suite-catalog attached-page bridge, the top-level shortcut bridge, the issue-specific attached-page entrypoint, the next-step matrix, context-preserving flow, replay route, or the wrapper-heavy safe-route branches, while keeping LIGHTPANDA_REPO_ROOT aligned to the current non-default checkout when RepoRoot is already in play.',
        'Use google_attached_html_entrypoint as the default issue-specific attached-page bridge after the suite-catalog attached-page entrypoint when explicit InputPath values are not already pinned, because it keeps the narrower issue #3 attached-page route visible before you decide whether to drop into attached_html_shortcut or widen back into replay_shortcuts and the next-step matrix.',
        'Use attached_html_shortcut after the issue-specific attached-page entrypoint when you want the shortest bridge into replay_shortcuts, the next-step matrix, or the bundle-first branch.',
        'Use replay_shortcuts as the default next helper after the top-level shortcut bridge or attached-page helpers when the current route is already known to be issue #3 and no pinned bundle inputs, saved summary, or non-default repo root need to take precedence first.',
        'Use suite_router_next_steps when you want the compact next-step matrix reprinted after the shortcut-first or attached-page bridges, or when the route still needs the explicit start-point table before you reopen replay route, contextual flow, attached bundle, or the safe-route wrappers.',
        'Use contextual_flow when RepoRoot, SummaryPath, or fixed InputPath values already matter and you want the next helper surface to keep that context aligned while you choose between the recommended runner, the suite-catalog attached-page bridge, the top-level shortcut bridge, the issue-specific attached-page entrypoint, replay route, replay shortcuts, live trace, attached bundle, or later-stage follow-up commands.',
        'Use attached_bundle_change_area when the current saved or attached inputs are the known three-page compatibility bundle and you want the suite catalog itself to reopen on that pinned branch first.',
        'Use replay_route after the shortcut-first bridge, the suite-catalog attached-page bridge, or the next-step matrix when you want the smallest read-first helper that keeps the suite catalog entrypoints, Google flow, contextual flow, attached-bundle branch, and safe-route bridge on one surface before narrowing further.',
        'Use suite_router_handoff when you want the wider compact bridge that keeps the exact top-level suite-router entrypoints beside the current replay helpers before narrowing further.',
        'Use attached_bundle_first when explicit input paths are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only issue #3 path.',
        'Use safe_route_entrypoints after the shortcut-first bridge, the suite-catalog attached-page bridge, the top-level shortcut bridge, the issue-specific attached-page helpers, the next-step matrix, contextual flow, suite-router handoff, or replay-route helper when you want the current wrapper-heavy issue #3 path, notes, and next-state helpers surfaced in one place.',
        'Use fresh_safe_route_replay when current issue #3 outputs may be stale or missing and you already know you want the one-command fresh wrapper instead of reopening the safe-route map first.',
        'Use reuse_current_outputs only when the current issue #3 artifacts are already present and trusted and you want the narrower safe-route wrapper without another broader regeneration pass.',
        'Keep the quickstart, suite-router bridge, suite-catalog guide, and validation-chain notes nearby when you want the written route beside these commands without reopening the broader Windows runbook first.'
    )
}

$entrypoints.recommended_next_key = if ($entrypoints.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($entrypoints.repo_root) -or -not [string]::IsNullOrWhiteSpace($entrypoints.summary_path)) {
    'contextual_flow'
} else {
    'suite_catalog_attached_html_entrypoint'
}
$entrypoints.recommended_next_command = switch ($entrypoints.recommended_next_key) {
    'attached_bundle_first' { $entrypoints.helper_commands.attached_bundle_first }
    'contextual_flow' { $entrypoints.helper_commands.contextual_flow }
    default { $entrypoints.helper_commands.suite_catalog_attached_html_entrypoint }
}
$entrypoints.recommended_next_reason = if ($entrypoints.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($entrypoints.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so open the context-preserving helper next and keep that replay state aligned before choosing between the suite-catalog attached-page bridge, the top-level shortcut bridge, the issue-specific attached-page entrypoint, replay shortcuts, the next-step matrix, replay route, attached bundle, or the safe-route helpers.'
} else {
    'No pinned bundle inputs, non-default repo root, or saved summary are in play yet, so jump straight from the suite catalog into the newer suite-catalog attached-page bridge before narrowing into the issue-specific attached-page chain, the top-level shortcut bridge, replay shortcuts, or the next-step matrix.'
}

if ($Json) {
    $entrypoints | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 suite catalog entrypoints'
Write-Host ''
if ($entrypoints.repo_root) {
    Write-Host (("Repo root:   {0}") -f $entrypoints.repo_root)
}
if ($entrypoints.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($entrypoints.summary_path)"))
}
if ($entrypoints.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $entrypoints.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $entrypoints.recommended_next_command)
Write-Host (("Why:                    {0}") -f $entrypoints.recommended_next_reason)
Write-Host ''
Write-Host 'Read-first bridge:'
Write-Host (("  1. Google recommended:      {0}") -f $entrypoints.bridge_sequence.google_recommended)
Write-Host (("  2. Google input:            {0}") -f $entrypoints.bridge_sequence.google_input_change_area)
Write-Host (("  3. Attached HTML:           {0}") -f $entrypoints.bridge_sequence.attached_html_change_area)
Write-Host (("  4. Google attached HTML:    {0}") -f $entrypoints.bridge_sequence.google_attached_html_change_area)
Write-Host (("  5. Catalog attached bridge: {0}") -f $entrypoints.bridge_sequence.suite_catalog_attached_html_entrypoint)
Write-Host (("  6. Router quickstart:       {0}") -f $entrypoints.bridge_sequence.suite_router_quickstart)
Write-Host (("  7. Top-level shortcut:      {0}") -f $entrypoints.bridge_sequence.top_level_shortcut_entrypoint)
Write-Host (("  8. Google flow:             {0}") -f $entrypoints.bridge_sequence.google_flow)
Write-Host (("  9. Google attached bridge:  {0}") -f $entrypoints.bridge_sequence.google_attached_html_entrypoint)
Write-Host ((" 10. Attached shortcut:       {0}") -f $entrypoints.bridge_sequence.attached_html_shortcut)
Write-Host ((" 11. Replay shortcuts:        {0}") -f $entrypoints.bridge_sequence.replay_shortcuts)
Write-Host ((" 12. Next-step matrix:        {0}") -f $entrypoints.bridge_sequence.suite_router_next_steps)
Write-Host ((" 13. Contextual flow:         {0}") -f $entrypoints.bridge_sequence.contextual_flow)
Write-Host ((" 14. Suite handoff:           {0}") -f $entrypoints.bridge_sequence.suite_router_handoff)
Write-Host ((" 15. Replay route:            {0}") -f $entrypoints.bridge_sequence.replay_route)
Write-Host ((" 16. Bundle-first route:      {0}") -f $entrypoints.bridge_sequence.attached_bundle_first)
Write-Host ''
Write-Host 'Top-level suite catalog entrypoints:'
Write-Host (("  Google recommended:   {0}") -f $entrypoints.suite_catalog_commands.google_recommended)
Write-Host (("  Google input:         {0}") -f $entrypoints.suite_catalog_commands.google_input_change_area)
Write-Host (("  Attached HTML:        {0}") -f $entrypoints.suite_catalog_commands.attached_html_change_area)
Write-Host (("  Google attached HTML: {0}") -f $entrypoints.suite_catalog_commands.google_attached_html_change_area)
Write-Host (("  Attached bundle:      {0}") -f $entrypoints.suite_catalog_commands.attached_bundle_change_area)
Write-Host ''
Write-Host 'Issue #3 replay helpers:'
Write-Host (("  Catalog attached bridge: {0}") -f $entrypoints.helper_commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  Router quickstart:      {0}") -f $entrypoints.helper_commands.suite_router_quickstart)
Write-Host (("  Top-level shortcut:     {0}") -f $entrypoints.helper_commands.top_level_shortcut_entrypoint)
Write-Host (("  Google flow:            {0}") -f $entrypoints.helper_commands.google_flow)
Write-Host (("  Google attached bridge: {0}") -f $entrypoints.helper_commands.google_attached_html_entrypoint)
Write-Host (("  Attached shortcut:      {0}") -f $entrypoints.helper_commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:       {0}") -f $entrypoints.helper_commands.replay_shortcuts)
Write-Host (("  Next-step matrix:       {0}") -f $entrypoints.helper_commands.suite_router_next_steps)
Write-Host (("  Contextual flow:        {0}") -f $entrypoints.helper_commands.contextual_flow)
Write-Host (("  Replay route:           {0}") -f $entrypoints.helper_commands.replay_route)
Write-Host (("  Suite handoff:          {0}") -f $entrypoints.helper_commands.suite_router_handoff)
Write-Host (("  Bundle first:           {0}") -f $entrypoints.helper_commands.attached_bundle_first)
Write-Host (("  Safe-route map:         {0}") -f $entrypoints.helper_commands.safe_route_entrypoints)
Write-Host (("  Fresh safe replay:      {0}") -f $entrypoints.helper_commands.fresh_safe_route_replay)
Write-Host (("  Reuse current output:   {0}") -f $entrypoints.helper_commands.reuse_current_outputs)
Write-Host ''
Write-Host (("Quickstart note:      {0}") -f $entrypoints.quickstart_note_path)
Write-Host (("Suite-router bridge:  {0}") -f $entrypoints.suite_router_bridge_note_path)
Write-Host (("Suite-catalog guide:  {0}") -f $entrypoints.suite_catalog_entrypoint_note_path)
Write-Host (("Validation chain:     {0}") -f $entrypoints.validation_chain_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoints.notes) {
    Write-Host (("- {0}") -f $note)
}
