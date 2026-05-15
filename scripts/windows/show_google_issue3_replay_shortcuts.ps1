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

$bundleFirstArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleFirstArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleFirstArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleFirstArguments -Name InputPath -Values $InputPath

$bundleRouteArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleRouteArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleRouteArguments -Name InputPath -Values $InputPath

$safeRouteArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $safeRouteArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $safeRouteArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $safeRouteArguments -Name InputPath -Values $InputPath

$runnerPatchStatePlaceholder = '<ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>'

$recommendedFirstHelperKey = 'fresh_safe_route_replay'
$recommendedFirstHelperReason = 'Current issue #3 outputs may be stale or missing, so start with the fresh safe-route replay that regenerates the current handoff artifact in one command.'
if ($InputPath -and @($InputPath).Count -gt 0) {
    $recommendedFirstHelperKey = 'attached_bundle_first'
    $recommendedFirstHelperReason = 'Explicit input paths are already in play, so start with the pinned three-page bundle route before widening back into the broader Google-only helper chain.'
} elseif (-not [string]::IsNullOrWhiteSpace($SummaryPath)) {
    $recommendedFirstHelperKey = 'reuse_current_outputs'
    $recommendedFirstHelperReason = 'A saved SummaryPath is already in play, so reopen the safe-route wrapper against the current outputs before widening into a broader regeneration pass.'
}

$shortcuts = [ordered]@{
    issue = 'Google issue #3 replay shortcuts'
    purpose = 'Keep the top-level issue #3 read-first commands, the Windows full-use attached-page route, the Windows full-use attached-page catalog quickstart, the replay-shortcuts-to-Windows-replay attached-page bridge, the Windows replay attached-page quickstart, the broader attached-page route, the attached-html change-area quickstart, the newer top-level attached-page quickstart and top-level attached-page catalog quickstart, the broader top-level attached-page bridge, the dedicated attached-page shortcut helper, the newer suite-router shortcut-first entrypoint, the suite-catalog bridge, the compact next-step matrix, the context-preserving helper, the narrower safe-route helper, the attached three-page bundle route, and the runner-state next-step helper on one compact command surface.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    windows_full_use_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    replay_shortcuts_windows_replay_attached_html_bridge_note_path = 'docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md'
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    decision_table_note_path = 'docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md'
    patch_rules_note_path = 'docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md'
    read_first_commands = [ordered]@{
        suite_router = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $bundleFirstArguments
        windows_full_use_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Arguments $bundleFirstArguments
        replay_shortcuts_windows_replay_attached_html_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1' -Arguments $bundleFirstArguments
        windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleFirstArguments
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $bundleFirstArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleFirstArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleFirstArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleFirstArguments
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleFirstArguments
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $bundleFirstArguments
        google_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $RepoRoot
        suite_router_handoff = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleFirstArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleFirstArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleFirstArguments
        attached_bundle_suite = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $bundleFirstArguments
        windows_full_use_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Arguments $bundleFirstArguments
        replay_shortcuts_windows_replay_attached_html_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1' -Arguments $bundleFirstArguments
        windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleFirstArguments
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleFirstArguments
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $bundleFirstArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleFirstArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleFirstArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleFirstArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleFirstArguments
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $bundleFirstArguments
        suite_router_handoff = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleFirstArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleFirstArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleFirstArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleFirstArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $safeRouteArguments
        runner_patch_next_step = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_patch_next_step.ps1' -Arguments ([ordered]@{
            SummaryPath = $SummaryPath
            State = $runnerPatchStatePlaceholder
        }) -RepoRootOverride $RepoRoot
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleFirstArguments
        attached_bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleRouteArguments
        attached_bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleRouteArguments -Switches @('Wait')
        fresh_safe_route_replay = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments $sharedArguments
        reuse_current_outputs = Format-HelperCommand -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Start with suite_router when you want the higher-level catalog to surface the broader issue #3 runner first, while preserving LIGHTPANDA_REPO_ROOT for a non-default checkout when it is already set.',
        'Use change_area when you may need a narrower title, homepage-fixture, submit-path, shared Enter-order, attached-page, or live-trace branch instead of the broader recommended replay, without dropping the current repo-root context.',
        'Use windows_full_use_attached_html_route when docs/WINDOWS_FULL_USE.md or the broader Windows headed runbook has already narrowed the replay to attached localhost follow-up and you want that Windows-first attached-page route reprinted before the helper chain narrows again.',
        'Use windows_full_use_attached_html_catalog_quickstart when the broader Windows-first attached-page route is already in focus and you want the compact Windows-full-use-to-catalog bridge printed before you reopen the replay-shortcuts-to-Windows-replay bridge, the Windows replay attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, the attached-page shortcut, replay shortcuts, contextual flow, or the safe-route map.',
        'Use replay_shortcuts_windows_replay_attached_html_bridge when replay_shortcuts is already the current surface and you want the shortest companion bridge into the Windows replay attached-page ladder before reopening the broader attached-page checkpoints.',
        'Use windows_replay_attached_html_quickstart when the route is already narrow enough to stay on the replay-side attached-page ladder directly after the replay-shortcuts bridge or the broader Windows full-use route surfaces.',
        'Use attached_html_change_area when the replay is already narrowed to the broader attached-page compatibility route and you want that top-level branch reprinted before deciding whether to stay pinned to the bundle-first path or narrow again into the newer attached-html change-area quickstart, the newer top-level attached-page quickstart, the broader top-level attached-page bridge, or the dedicated attached-page shortcut helper.',
        'Use attached_html_change_area_quickstart when the replay is already narrowed to show_headed_validation_suites.ps1 -ChangeArea attached-html and you want the shorter issue-specific bridge that keeps the broader attached-page flow helper, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-router attached-page quickstart, and the attached-page shortcut visible before the route narrows again.',
        'Use top_level_attached_html_quickstart when the replay has already re-entered from the top-level validation router and you want the compact top-level attached-page helper kept visible before deciding between the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the attached-page shortcut helper, replay shortcuts, the next-step matrix, suite-router handoff, or the pinned bundle-first path.',
        'Use top_level_attached_html_entrypoint when the replay is already narrowed to attached-page follow-up and you want the broader top-level attached-page bridge reprinted before widening back into replay shortcuts, the next-step matrix, suite-router handoff, replay route, or the pinned bundle-first path.',
        'Use top_level_attached_html_catalog_quickstart when the replay should keep the compact top-level attached-page quickstart plus the suite-catalog-side attached-page bridge visible together before narrowing into the shorter attached-page shortcut, replay shortcuts, contextual flow, or the safe-route map.',
        'Use suite_router_shortcut_entrypoint when the higher-level suite router has already made issue #3 obvious and you want the shorter bridge back into replay shortcuts, the replay-shortcuts-to-Windows-replay bridge, the Windows replay attached-page quickstart, the attached-page shortcut helper, contextual flow, the next-step matrix, or the pinned bundle-first branch before reopening the wider compact helpers.',
        'Use attached_html_shortcut when the replay is already inside the attached-page follow-up route and you want that dedicated shortcut kept visible before widening back into replay shortcuts, the next-step matrix, suite-router handoff, replay route, or the pinned bundle-first path.',
        'Use suite_catalog_entrypoints when you want the shortest current bridge from the top-level suite catalog into the issue #3 next-step matrix, replay-route helper, replay-shortcuts helper, replay-shortcuts-to-Windows-replay bridge, Windows replay attached-page quickstart, attached-page shortcut helper, or pinned bundle-first path while keeping RepoRoot, SummaryPath, and InputPath context attached.',
        'Use google_flow when you want the current localhost-first issue #3 ladder printed before you choose between the narrower safe-route replay, the attached bundle route, or a later-stage Google slice, while keeping the same repo-root context.',
        'Use suite_router_handoff when you want the higher-level suite-router entrypoints, the Windows full-use attached-page route, the Windows full-use attached-page catalog quickstart, the replay-shortcuts-to-Windows-replay bridge, the Windows replay attached-page quickstart, the attached-page route, the attached-html change-area quickstart, the top-level attached-page quickstart, the top-level attached-page bridge, the top-level attached-page catalog quickstart, the shortcut-first suite-router entrypoint, the suite-catalog bridge, and the current replay-shortcuts helper reprinted together in one compact surface before you drop into the next-step matrix, replay-route, attached-page shortcut, contextual-flow, safe-route, or bundle-first helpers.',
        'Use suite_router_next_steps when you want the compact next-step matrix that keeps the current start points, the Windows-first attached-page route, the Windows-full-use catalog bridge, the replay-shortcuts-to-Windows-replay bridge, the Windows replay attached-page quickstart, the attached-page route, the attached-html change-area quickstart, the top-level attached-page quickstart, the top-level attached-page bridge, the top-level attached-page catalog quickstart, the shortcut-first suite-router bridge, replay-route branch, attached-bundle branch, contextual-flow branch, and runner-state helper choices together before you pick one narrower replay path.',
        'Use replay_route when you want the attached-bundle branch, the safe-route bridge, the context-preserving helper, and the repo-root-aware runner next-step helper printed in one slightly broader surface before you return to the narrower replay-shortcuts, replay-shortcuts-to-Windows-replay, Windows replay attached-page quickstart, or attached-page shortcut helpers.',
        'Use contextual_flow when you already know repo-root overrides, saved-summary state, or pinned attached pages should stay visible while you choose between the recommended runner, replay shortcuts, the replay-shortcuts-to-Windows-replay bridge, the Windows replay attached-page quickstart, the Windows full-use attached-page route, the Windows full-use attached-page catalog quickstart, the attached-html change-area quickstart, the top-level attached-page quickstart, the top-level attached-page bridge, the top-level attached-page catalog quickstart, attached-page shortcut, live trace, or bundle follow-up commands.',
        'Use safe_route_entrypoints when outputs may already exist and you want the newest issue #3 wrapper commands, notes, and next-state helpers printed in one place. When InputPath is already pinned, this helper now preserves that same fixed bundle context instead of falling back to auto-discovery.',
        'Use runner_patch_next_step after the safe-route wrapper or reuse-current-outputs helper names one of the three current runner-patch states; when RepoRoot or SummaryPath is already in play, this command now keeps that same replay context attached to the next-step helper.',
        'Use attached_bundle_first when explicit input paths are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only safe-route ladder.',
        'Use attached_bundle_suite when you want the higher-level suite router itself to reopen on the pinned bundle branch before widening back into the broader Google-only helpers.',
        'Use fresh_safe_route_replay when current issue #3 outputs may be stale or missing and no explicit bundle inputs are already pinned. Use reuse_current_outputs only when the current saved outputs are already trusted.',
        'Keep quickstart_note_path open for the shortest current replay note, windows_runbook_note_path when the route is being resumed from the broader Windows headed runbook, windows_full_use_attached_html_route_note_path for the shorter Windows-first attached-page route, windows_full_use_attached_html_catalog_quickstart_note_path for the compact Windows-full-use-to-catalog bridge, replay_shortcuts_windows_replay_attached_html_bridge_note_path for the replay-shortcuts-to-Windows-replay handoff, windows_replay_attached_html_quickstart_note_path for the replay-side attached-page ladder itself, validation_chain_note_path for wrapper precedence, suite_router_bridge_note_path for the narrow prose bridge into replay shortcuts, suite_catalog_entrypoint_note_path for the shortest bridge from the top-level suite router into the current helper chain, top_level_attached_html_quickstart_note_path for the compact top-level attached-page handoff, top_level_attached_html_bridge_note_path for the broader top-level attached-page route, decision_table_note_path when the replay lands on ready-for-runner-patch, already-direct, or runner-already-wired-regenerate-outputs, and patch_rules_note_path when the replay is already narrowed to a direct runner-source edit.'
    )
}

$shortcuts.recommended_first_helper_key = $recommendedFirstHelperKey
$shortcuts.recommended_first_helper_reason = $recommendedFirstHelperReason
$shortcuts.recommended_first_helper_command = $shortcuts.helper_commands[$recommendedFirstHelperKey]

if ($Json) {
    $shortcuts | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 replay shortcuts'
Write-Host ''
if ($shortcuts.repo_root) {
    Write-Host (("Repo root:   {0}") -f $shortcuts.repo_root)
}
if ($shortcuts.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($shortcuts.summary_path)"))
}
if ($shortcuts.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $shortcuts.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended first helper: {0}") -f $shortcuts.recommended_first_helper_command)
Write-Host (("Why:                     {0}") -f $shortcuts.recommended_first_helper_reason)
Write-Host ''
Write-Host 'Read-first discovery:'
Write-Host (("  Suite router:                {0}") -f $shortcuts.read_first_commands.suite_router)
Write-Host (("  Change-area view:            {0}") -f $shortcuts.read_first_commands.change_area)
Write-Host (("  Windows full-use route:      {0}") -f $shortcuts.read_first_commands.windows_full_use_attached_html_route)
Write-Host (("  Windows catalog quickstart:  {0}") -f $shortcuts.read_first_commands.windows_full_use_attached_html_catalog_quickstart)
Write-Host (("  Replay->Windows bridge:      {0}") -f $shortcuts.read_first_commands.replay_shortcuts_windows_replay_attached_html_bridge)
Write-Host (("  Windows replay quickstart:   {0}") -f $shortcuts.read_first_commands.windows_replay_attached_html_quickstart)
Write-Host (("  Attached HTML route:         {0}") -f $shortcuts.read_first_commands.attached_html_change_area)
Write-Host (("  Attached HTML quickstart:    {0}") -f $shortcuts.read_first_commands.attached_html_change_area_quickstart)
Write-Host (("  Top-level quickstart:        {0}") -f $shortcuts.read_first_commands.top_level_attached_html_quickstart)
Write-Host (("  Top-level attached:          {0}") -f $shortcuts.read_first_commands.top_level_attached_html_entrypoint)
Write-Host (("  Top-level catalog quickstart:{0}") -f (' ' + $shortcuts.read_first_commands.top_level_attached_html_catalog_quickstart))
Write-Host (("  Shortcut entrypoint:         {0}") -f $shortcuts.read_first_commands.suite_router_shortcut_entrypoint)
Write-Host (("  Suite-catalog helper:        {0}") -f $shortcuts.read_first_commands.suite_catalog_entrypoints)
Write-Host (("  Google flow helper:          {0}") -f $shortcuts.read_first_commands.google_flow)
Write-Host (("  Suite-router handoff:        {0}") -f $shortcuts.read_first_commands.suite_router_handoff)
Write-Host (("  Next-step matrix:            {0}") -f $shortcuts.read_first_commands.suite_router_next_steps)
Write-Host (("  Replay route:                {0}") -f $shortcuts.read_first_commands.replay_route)
Write-Host (("  Bundle suite route:          {0}") -f $shortcuts.read_first_commands.attached_bundle_suite)
Write-Host ''
Write-Host 'Shortcut helpers:'
Write-Host (("  Windows full-use route:      {0}") -f $shortcuts.helper_commands.windows_full_use_attached_html_route)
Write-Host (("  Windows catalog quickstart:  {0}") -f $shortcuts.helper_commands.windows_full_use_attached_html_catalog_quickstart)
Write-Host (("  Replay->Windows bridge:      {0}") -f $shortcuts.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)
Write-Host (("  Windows replay quickstart:   {0}") -f $shortcuts.helper_commands.windows_replay_attached_html_quickstart)
Write-Host (("  Suite-router shortcut:       {0}") -f $shortcuts.helper_commands.suite_router_shortcut_entrypoint)
Write-Host (("  Attached HTML quickstart:    {0}") -f $shortcuts.helper_commands.attached_html_change_area_quickstart)
Write-Host (("  Top-level quickstart:        {0}") -f $shortcuts.helper_commands.top_level_attached_html_quickstart)
Write-Host (("  Top-level attached:          {0}") -f $shortcuts.helper_commands.top_level_attached_html_entrypoint)
Write-Host (("  Top-level catalog quickstart:{0}") -f (' ' + $shortcuts.helper_commands.top_level_attached_html_catalog_quickstart))
Write-Host (("  Attached HTML helper:        {0}") -f $shortcuts.helper_commands.attached_html_shortcut)
Write-Host (("  Suite-catalog helper:        {0}") -f $shortcuts.helper_commands.suite_catalog_entrypoints)
Write-Host (("  Suite-router handoff:        {0}") -f $shortcuts.helper_commands.suite_router_handoff)
Write-Host (("  Next-step matrix:            {0}") -f $shortcuts.helper_commands.suite_router_next_steps)
Write-Host (("  Replay route:                {0}") -f $shortcuts.helper_commands.replay_route)
Write-Host (("  Contextual flow:             {0}") -f $shortcuts.helper_commands.contextual_flow)
Write-Host (("  Safe route entrypoints:      {0}") -f $shortcuts.helper_commands.safe_route_entrypoints)
Write-Host (("  Runner next-step helper:     {0}") -f $shortcuts.helper_commands.runner_patch_next_step)
Write-Host (("  Bundle-first helper:         {0}") -f $shortcuts.helper_commands.attached_bundle_first)
Write-Host (("  Bundle flow helper:          {0}") -f $shortcuts.helper_commands.attached_bundle_flow)
Write-Host (("  Bundle runner:               {0}") -f $shortcuts.helper_commands.attached_bundle_runner)
Write-Host (("  Fresh safe replay:           {0}") -f $shortcuts.helper_commands.fresh_safe_route_replay)
Write-Host (("  Reuse current outputs:       {0}") -f $shortcuts.helper_commands.reuse_current_outputs)
Write-Host ''
Write-Host (("Quickstart note:          {0}") -f $shortcuts.quickstart_note_path)
Write-Host (("Windows runbook:          {0}") -f $shortcuts.windows_runbook_note_path)
Write-Host (("Windows route note:       {0}") -f $shortcuts.windows_full_use_attached_html_route_note_path)
Write-Host (("Windows catalog note:     {0}") -f $shortcuts.windows_full_use_attached_html_catalog_quickstart_note_path)
Write-Host (("Replay->Windows note:     {0}") -f $shortcuts.replay_shortcuts_windows_replay_attached_html_bridge_note_path)
Write-Host (("Windows replay note:      {0}") -f $shortcuts.windows_replay_attached_html_quickstart_note_path)
Write-Host (("Validation chain note:    {0}") -f $shortcuts.validation_chain_note_path)
Write-Host (("Suite-router bridge note: {0}") -f $shortcuts.suite_router_bridge_note_path)
Write-Host (("Suite-catalog guide note: {0}") -f $shortcuts.suite_catalog_entrypoint_note_path)
Write-Host (("Top-level quickstart note:{0}") -f (' ' + $shortcuts.top_level_attached_html_quickstart_note_path))
Write-Host (("Top-level bridge note:    {0}") -f (' ' + $shortcuts.top_level_attached_html_bridge_note_path))
Write-Host (("Decision table:           {0}") -f $shortcuts.decision_table_note_path)
Write-Host (("Patch rules note:         {0}") -f $shortcuts.patch_rules_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $shortcuts.notes) {
    Write-Host (("- {0}") -f $note)
}
