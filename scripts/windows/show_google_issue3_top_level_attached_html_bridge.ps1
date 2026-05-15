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
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $InputPath

$emptyArguments = [System.Collections.Generic.List[string]]::new()
$windowsReplayAttachedHtmlSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -RepoRootOverride $RepoRoot
$windowsReplayAttachedHtmlQuickstartCommand = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $sharedArguments

$helper = [ordered]@{
    issue = 'Google issue #3 top-level attached HTML bridge'
    purpose = 'Print the broader top-level attached-page bridge for issue #3 so the route guard, attached-shortcut guard, change-area quickstart, attached-page flow helper, top-level shortcut surface, top-level quickstart, newer Windows replay attached-html surface check, newer Windows replay attached-html quickstart, suite-router attached-page quickstart, suite-catalog bridge, replay-route helper, and bundle-first branch stay visible on one helper surface.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    commands = [ordered]@{
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $sharedArguments
        windows_full_use_attached_html_route_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -RepoRootOverride $RepoRoot
        windows_full_use_validation_router_attached_html_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $sharedArguments
        windows_full_use_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        windows_replay_attached_html_surface_check = $windowsReplayAttachedHtmlSurfaceCheckCommand
        windows_replay_attached_html_quickstart = $windowsReplayAttachedHtmlQuickstartCommand
        attached_html_shortcut_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_attached_html_shortcut_validation_surface.ps1' -RepoRootOverride $RepoRoot
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'attached-html' }) -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-attached-html' }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'attached-html-target-bundle' }) -RepoRootOverride $RepoRoot
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $sharedArguments
        attached_html_flow = Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $emptyArguments
        top_level_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $sharedArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $sharedArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        suite_catalog_top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $sharedArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $sharedArguments
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $sharedArguments
        replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $sharedArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $sharedArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $sharedArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $sharedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
    }
    note_paths = [ordered]@{
        windows_runbook = 'docs/WINDOWS_FULL_USE.md'
        production_execution_attached_html_route = 'docs/ISSUE3_PRODUCTION_EXECUTION_ATTACHED_HTML_ROUTE.md'
        windows_full_use_attached_html_route = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
        windows_full_use_validation_router_attached_html_bridge = 'docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md'
        windows_full_use_attached_html_catalog_quickstart = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md'
        windows_replay_quickstart = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
        windows_replay_attached_html_quickstart = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
        windows_validation_chain = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
        google_attached_html_validation_flow = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
        attached_html_change_area_quickstart = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
        validation_router_attached_html_quickstart = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
        top_level_attached_html_quickstart = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
        top_level_attached_html_bridge = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
        top_level_attached_html_catalog_quickstart = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
        suite_catalog_top_level_attached_html_catalog_quickstart = 'docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
        top_level_attached_html_companion_notes = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md'
        top_level_shortcut_first_entrypoint = 'docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md'
        top_level_shortcut_bridge = 'docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md'
        attached_html_shortcut_entrypoint = 'docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md'
        suite_router_attached_html_quickstart = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
        suite_router_shortcut_bridge = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
        suite_catalog_entrypoints = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
        suite_catalog_attached_html_bridge = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
        replay_route_shortcut_bridge = 'docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md'
        replay_discovery_handoff = 'docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md'
        attached_html_target_bundle_reference = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
    }
    notes = @(
        'Use this helper when issue #3 is already narrowed to attached localhost follow-up and you want the broader top-level bridge reprinted without reopening the longer validation-chain notes first.',
        'Use windows_full_use_attached_html_route, windows_full_use_attached_html_route_surface_check, windows_full_use_validation_router_attached_html_bridge, and windows_full_use_attached_html_catalog_quickstart when the replay is being resumed from the broader Windows-first route before it drops back into the top-level attached-page ladder.',
        'Use windows_replay_attached_html_surface_check and windows_replay_attached_html_quickstart when the replay has already been narrowed to the replay-side attached localhost lane and you want that Windows-side ladder kept visible before the broader top-level bridge takes over.',
        'Use attached_html_change_area, attached_html_change_area_quickstart, and attached_html_flow when the replay should still keep the broader attached-page compatibility branch visible before narrowing into the shorter issue #3 helper chain.',
        'Use top_level_shortcut_entrypoint when the route is already about to narrow into the shorter attached-page shortcut, replay-route shortcut, replay shortcuts, the next-step matrix, or the safe-route map.',
        'Use top_level_attached_html_quickstart when you want the shortest top-level companion surface before the broader top-level bridge or the catalog quickstart.',
        'Use top_level_attached_html_entrypoint when you want the broader top-level attached-page bridge reprinted before the suite-router sidecar or the suite-catalog sidecar takes over.',
        'Use top_level_attached_html_catalog_quickstart and suite_catalog_top_level_attached_html_catalog_quickstart when the top-level catalog route and the suite-catalog-side attached-page bridge should stay visible together before the helper chain narrows again.',
        'Use suite_router_attached_html_quickstart after the broader top-level bridge when no pinned bundle inputs, repo-root override, or saved summary need to take precedence first.',
        'Use google_attached_html_entrypoint, suite_catalog_entrypoints, and suite_catalog_attached_html_entrypoint when the route should stay visible on the issue-specific or suite-catalog side before narrowing again.',
        'Use attached_html_shortcut, suite_router_shortcut_entrypoint, replay_route_shortcut, and replay_shortcuts only after the broader top-level bridge is already in view and the replay is ready to stay inside the narrower issue #3 helper chain.',
        'Use contextual_flow when RepoRoot, SummaryPath, or pinned InputPath values already matter and the next helper surface should preserve that replay context before it narrows again.',
        'Use attached_bundle_change_area and attached_bundle_first when the current inputs are already pinned to the known three-page compatibility bundle and the replay should stay on that locked route before widening back into the broader helper chain.',
        'Use safe_route_entrypoints only after the attached-page route has already narrowed back into the wrapper-heavy issue #3 branch.'
    )
}

$helper.recommended_next_key = if ($helper.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($helper.repo_root) -or -not [string]::IsNullOrWhiteSpace($helper.summary_path)) {
    'contextual_flow'
} else {
    'suite_router_attached_html_quickstart'
}
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so keep the replay on the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($helper.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing the narrower attached-page helpers.'
} else {
    'No pinned bundle inputs, non-default repo root, or saved summary are in play yet, so jump from the broader top-level bridge into the suite-router attached-page quickstart while the attached-page route guards and top-level catalog quickstarts stay visible.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 top-level attached HTML bridge'
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
Write-Host (("Recommended next helper: {0}") -f $helper.recommended_next_command)
Write-Host (("Why:                    {0}") -f $helper.recommended_next_reason)
Write-Host ''
Write-Host 'Windows-first re-entry:'
Write-Host (("  Windows route:          {0}") -f $helper.commands.windows_full_use_attached_html_route)
Write-Host (("  Route surface check:    {0}") -f $helper.commands.windows_full_use_attached_html_route_surface_check)
Write-Host (("  Validation bridge:      {0}") -f $helper.commands.windows_full_use_validation_router_attached_html_bridge)
Write-Host (("  Catalog quickstart:     {0}") -f $helper.commands.windows_full_use_attached_html_catalog_quickstart)
Write-Host (("  Replay surface check:   {0}") -f $helper.commands.windows_replay_attached_html_surface_check)
Write-Host (("  Replay attached quick:  {0}") -f $helper.commands.windows_replay_attached_html_quickstart)
Write-Host ''
Write-Host 'Top-level attached-page bridge:'
Write-Host (("  Attached HTML route:    {0}") -f $helper.commands.attached_html_change_area)
Write-Host (("  Google attached route:  {0}") -f $helper.commands.google_attached_html_change_area)
Write-Host (("  Bundle route:           {0}") -f $helper.commands.attached_bundle_change_area)
Write-Host (("  Shortcut surface check: {0}") -f $helper.commands.attached_html_shortcut_surface_check)
Write-Host (("  Change-area quickstart: {0}") -f $helper.commands.attached_html_change_area_quickstart)
Write-Host (("  Attached flow helper:   {0}") -f $helper.commands.attached_html_flow)
Write-Host (("  Shortcut-first bridge:  {0}") -f $helper.commands.top_level_shortcut_entrypoint)
Write-Host (("  Top-level quickstart:   {0}") -f $helper.commands.top_level_attached_html_quickstart)
Write-Host (("  Top-level bridge:       {0}") -f $helper.commands.top_level_attached_html_entrypoint)
Write-Host (("  Catalog quickstart:     {0}") -f $helper.commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  Catalog bridge quick:   {0}") -f $helper.commands.suite_catalog_top_level_attached_html_catalog_quickstart)
Write-Host (("  Suite-router sidecar:   {0}") -f $helper.commands.suite_router_attached_html_quickstart)
Write-Host (("  Google attached helper: {0}") -f $helper.commands.google_attached_html_entrypoint)
Write-Host (("  Suite-catalog guide:    {0}") -f $helper.commands.suite_catalog_entrypoints)
Write-Host (("  Suite-catalog bridge:   {0}") -f $helper.commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  Attached shortcut:      {0}") -f $helper.commands.attached_html_shortcut)
Write-Host (("  Router shortcut:        {0}") -f $helper.commands.suite_router_shortcut_entrypoint)
Write-Host (("  Replay-route shortcut:  {0}") -f $helper.commands.replay_route_shortcut)
Write-Host (("  Replay shortcuts:       {0}") -f $helper.commands.replay_shortcuts)
Write-Host (("  Next-step matrix:       {0}") -f $helper.commands.suite_router_next_steps)
Write-Host (("  Contextual flow:        {0}") -f $helper.commands.contextual_flow)
Write-Host (("  Bundle first:           {0}") -f $helper.commands.attached_bundle_first)
Write-Host (("  Safe-route map:         {0}") -f $helper.commands.safe_route_entrypoints)
Write-Host ''
Write-Host 'Companion notes:'
foreach ($entry in $helper.note_paths.GetEnumerator()) {
    Write-Host (("  {0}: {1}") -f $entry.Key, $entry.Value)
}
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
