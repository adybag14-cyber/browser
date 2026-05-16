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

$routeSurfaceArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $routeSurfaceArguments -Name RepoRoot -Value $RepoRoot

$entrypoint = [ordered]@{
    issue = 'Google issue #3 attached HTML shortcut entrypoint'
    purpose = 'Print the shortest attached-page compatibility route from the headed validation suite router back into the current issue #3 shortcut helpers while also surfacing the broader Windows-first route guard, the replay-side attached-html quickstart, the newer attached-html change-area quickstart, the newer top-level attached-page quickstarts, and preserving repo-root, saved-summary, and pinned bundle-input context when it is already in play.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    top_level_commands = [ordered]@{
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $bundleArguments
        windows_route_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -Arguments $routeSurfaceArguments
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $bundleArguments
        windows_full_use_validation_router_attached_html_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $bundleArguments
        windows_full_use_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        top_level_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
    }
    helper_commands = [ordered]@{
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        attached_bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleFlowArguments
        attached_bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleFlowArguments -Switches @('Wait')
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
        fresh_safe_route_replay = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments $sharedArguments
        reuse_current_outputs = Format-HelperCommand -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments $sharedArguments
    }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    windows_full_use_validation_router_attached_html_bridge_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md'
    windows_full_use_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    attached_html_change_area_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_router_entrypoint_guide_note_path = 'docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    notes = @(
        'Start with attached_html_change_area when the next replay is already narrowed to the attached-page compatibility path and you want that top-level route reprinted before you drop into the shorter issue #3 helper chain.',
        'Use attached_bundle_change_area instead when the current saved or attached pages are still the known three-page compatibility bundle and the next replay should stay pinned to that route first.',
        'Use google_attached_html_flow when you want the broader attached-page localhost-first helper chain printed before you choose between the shortcut-first issue #3 route and the pinned bundle-first branch.',
        'Use windows_route_surface_check after reopening the broader Windows-first route so the current route guard still fails fast before the replay drops into the narrower attached-page helpers.',
        'Use windows_full_use_attached_html_route, windows_full_use_validation_router_attached_html_bridge, and windows_full_use_attached_html_catalog_quickstart when the replay is reopening from docs/WINDOWS_FULL_USE.md first and you want the route-level surface check, Windows-to-validation-router bridge, and Windows-side catalog step kept aligned with the shorter attached-page bridge.',
        'Use windows_replay_attached_html_quickstart when docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md already narrowed the replay to the attached localhost lane and you want that replay-side ladder visible before the shorter attached-page bridge takes over.',
        'Use attached_html_change_area_quickstart, top_level_attached_html_quickstart, and top_level_attached_html_entrypoint as the default middle of the ladder so the broader attached-page flow helper, the compact top-level route, and the broader top-level companion notes stay visible before you drop into the suite-router shortcut helper.',
        'Use top_level_attached_html_catalog_quickstart when you want the compact top-level attached-page quickstart and its catalog-side follow-up reprinted together before the route narrows again.',
        'Use suite_router_attached_html_quickstart when the route is already centered on attached localhost follow-up and you want the suite-router-side attached-page bridge visible before you narrow into the shortest shortcut helper.',
        'Use top_level_shortcut_entrypoint when you still want the broader top-level issue #3 bridge visible before narrowing into the suite-router shortcut helper.',
        'Use suite_router_shortcut_entrypoint as the default next helper when no explicit bundle inputs are pinned yet, because it keeps the shorter issue #3 bridge visible before you choose between replay_shortcuts, the next-step matrix, attached_bundle_first, or the safe-route map.',
        'Use attached_bundle_first as the default next helper whenever explicit InputPath values are already pinned, because that keeps the attached three-page compatibility set locked before widening back into the broader Google-only issue #3 helpers.',
        'Use replay_shortcuts after the suite-router shortcut entrypoint when the route is already known to stay inside issue #3 and you want the narrower helper surface before reopening the wrapper-heavy safe-route path.',
        'Use suite_router_next_steps when you want the explicit start-point matrix printed again after the attached-page bridge so you can choose between the replay route, bundle-first branch, or runner-state helpers.',
        'Use attached_bundle_flow and attached_bundle_runner when the current route should stay pinned to the three-page compatibility set all the way through the delegated localhost validation helper.',
        'Use safe_route_entrypoints only after the attached-page route has already narrowed the current replay into the wrapper-heavy issue #3 branch, and keep the same SummaryPath and InputPath values attached when they are already pinned.',
        'Use fresh_safe_route_replay when current outputs may be stale or missing. Use reuse_current_outputs only when a saved SummaryPath already exists and those outputs are still trusted.',
        'Keep the quickstart, Windows route, Windows bridge, Windows catalog, replay-side attached-html quickstart, attached-html change-area quickstart, top-level attached-page quickstart, top-level attached-page bridge, top-level attached-page catalog quickstart, suite-router attached-page quickstart, suite-router bridge, suite-router entrypoint guide, suite-catalog guide, validation-chain, and Windows runbook notes nearby when you want the written route beside these commands.'
    )
}

$entrypoint.recommended_next_helper_key = if ($entrypoint.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} else {
    'suite_router_shortcut_entrypoint'
}
$entrypoint.recommended_next_helper_command = $entrypoint.helper_commands[$entrypoint.recommended_next_helper_key]
$entrypoint.recommended_next_helper_reason = if ($entrypoint.recommended_next_helper_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so stay on the bundle-first branch before widening back into the broader Google-only issue #3 route.'
} else {
    'No explicit bundle inputs are pinned yet, so jump straight from the attached-page route into the compact suite-router shortcut helper and keep the shorter issue #3 bridge visible from there.'
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 attached HTML shortcut entrypoint'
Write-Host ''
if ($entrypoint.repo_root) {
    Write-Host (("Repo root:   {0}") -f $entrypoint.repo_root)
}
if ($entrypoint.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($entrypoint.summary_path)"))
}
if ($entrypoint.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $entrypoint.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $entrypoint.recommended_next_helper_command)
Write-Host (("Why:                    {0}") -f $entrypoint.recommended_next_helper_reason)
Write-Host ''
Write-Host 'Attached-page bridge:'
Write-Host (("  1. Attached HTML:      {0}") -f $entrypoint.top_level_commands.attached_html_change_area)
Write-Host (("  2. Attached bundle:    {0}") -f $entrypoint.top_level_commands.attached_bundle_change_area)
Write-Host (("  3. Google attached:    {0}") -f $entrypoint.top_level_commands.google_attached_html_flow)
Write-Host (("  4. Windows route chk:  {0}") -f $entrypoint.top_level_commands.windows_route_surface_check)
Write-Host (("  5. Windows route:      {0}") -f $entrypoint.top_level_commands.windows_full_use_attached_html_route)
Write-Host (("  6. Windows bridge:     {0}") -f $entrypoint.top_level_commands.windows_full_use_validation_router_attached_html_bridge)
Write-Host (("  7. Windows catalog:    {0}") -f $entrypoint.top_level_commands.windows_full_use_attached_html_catalog_quickstart)
Write-Host (("  8. Replay quickstart:  {0}") -f $entrypoint.top_level_commands.windows_replay_attached_html_quickstart)
Write-Host (("  9. Change-area quick:  {0}") -f $entrypoint.top_level_commands.attached_html_change_area_quickstart)
Write-Host ((" 10. Top-level quick:    {0}") -f $entrypoint.top_level_commands.top_level_attached_html_quickstart)
Write-Host ((" 11. Top-level bridge:   {0}") -f $entrypoint.top_level_commands.top_level_attached_html_entrypoint)
Write-Host ((" 12. Top-level catalog:  {0}") -f $entrypoint.top_level_commands.top_level_attached_html_catalog_quickstart)
Write-Host ((" 13. Top-level shortcut: {0}") -f $entrypoint.top_level_commands.top_level_shortcut_entrypoint)
Write-Host ((" 14. Router attached:    {0}") -f $entrypoint.top_level_commands.suite_router_attached_html_quickstart)
Write-Host ((" 15. Shortcut helper:    {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host ((" 16. Replay shortcuts:   {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host ((" 17. Next-step matrix:   {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host ((" 18. Bundle first:       {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host ''
Write-Host 'Companion helpers:'
Write-Host (("  Windows route:         {0}") -f $entrypoint.top_level_commands.windows_full_use_attached_html_route)
Write-Host (("  Windows bridge:        {0}") -f $entrypoint.top_level_commands.windows_full_use_validation_router_attached_html_bridge)
Write-Host (("  Windows catalog:       {0}") -f $entrypoint.top_level_commands.windows_full_use_attached_html_catalog_quickstart)
Write-Host (("  Replay quickstart:     {0}") -f $entrypoint.top_level_commands.windows_replay_attached_html_quickstart)
Write-Host (("  Change-area quick:     {0}") -f $entrypoint.top_level_commands.attached_html_change_area_quickstart)
Write-Host (("  Top-level quick:       {0}") -f $entrypoint.top_level_commands.top_level_attached_html_quickstart)
Write-Host (("  Top-level bridge:      {0}") -f $entrypoint.top_level_commands.top_level_attached_html_entrypoint)
Write-Host (("  Top-level catalog:     {0}") -f $entrypoint.top_level_commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  Router attached:       {0}") -f $entrypoint.top_level_commands.suite_router_attached_html_quickstart)
Write-Host (("  Shortcut helper:       {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host (("  Replay shortcuts:      {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host (("  Next-step matrix:      {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host (("  Bundle first:          {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host (("  Bundle flow helper:    {0}") -f $entrypoint.helper_commands.attached_bundle_flow)
Write-Host (("  Bundle runner:         {0}") -f $entrypoint.helper_commands.attached_bundle_runner)
Write-Host (("  Safe-route map:        {0}") -f $entrypoint.helper_commands.safe_route_entrypoints)
Write-Host (("  Fresh safe replay:     {0}") -f $entrypoint.helper_commands.fresh_safe_route_replay)
Write-Host (("  Reuse current outputs: {0}") -f $entrypoint.helper_commands.reuse_current_outputs)
Write-Host ''
Write-Host (("Quickstart note:         {0}") -f $entrypoint.quickstart_note_path)
Write-Host (("Windows route note:      {0}") -f $entrypoint.windows_full_use_attached_html_route_note_path)
Write-Host (("Windows bridge note:     {0}") -f $entrypoint.windows_full_use_validation_router_attached_html_bridge_note_path)
Write-Host (("Windows catalog note:    {0}") -f $entrypoint.windows_full_use_attached_html_catalog_quickstart_note_path)
Write-Host (("Replay quickstart note:  {0}") -f $entrypoint.windows_replay_attached_html_quickstart_note_path)
Write-Host (("Change-area note:        {0}") -f $entrypoint.attached_html_change_area_quickstart_note_path)
Write-Host (("Top-level quick note:    {0}") -f $entrypoint.top_level_attached_html_quickstart_note_path)
Write-Host (("Top-level bridge note:   {0}") -f $entrypoint.top_level_attached_html_bridge_note_path)
Write-Host (("Top-level catalog note:  {0}") -f $entrypoint.top_level_attached_html_catalog_quickstart_note_path)
Write-Host (("Router attached note:    {0}") -f $entrypoint.suite_router_attached_html_quickstart_note_path)
Write-Host (("Suite-router bridge:     {0}") -f $entrypoint.suite_router_bridge_note_path)
Write-Host (("Router guide note:       {0}") -f $entrypoint.suite_router_entrypoint_guide_note_path)
Write-Host (("Suite-catalog guide:     {0}") -f $entrypoint.suite_catalog_entrypoint_note_path)
Write-Host (("Validation chain:        {0}") -f $entrypoint.validation_chain_note_path)
Write-Host (("Windows runbook:         {0}") -f $entrypoint.windows_runbook_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}
