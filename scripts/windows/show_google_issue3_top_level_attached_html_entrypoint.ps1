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

$entrypoint = [ordered]@{
    issue = 'Google issue #3 top-level attached HTML entrypoint'
    purpose = 'Keep the shortest attached-page route visible from the top-level headed validation suite router, including the newer attached-html change-area quickstart that already surfaces the broader attached-page flow helper, the compact top-level attached-page quickstart, and the suite-router attached-page quickstart, before the replay narrows into the issue-specific attached-page bridge, the replay-route shortcut companion, or the pinned bundle-first branch.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    top_level_commands = [ordered]@{
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        windows_full_use_attached_html_route_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -RepoRootOverride $RepoRoot
        attached_html_shortcut_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_attached_html_shortcut_validation_surface.ps1' -RepoRootOverride $RepoRoot
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $bundleArguments
        top_level_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
    }
    helper_commands = [ordered]@{
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $bundleArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
        fresh_safe_route_replay = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments $sharedArguments
        reuse_current_outputs = Format-HelperCommand -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments $sharedArguments
    }
    attached_html_change_area_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    top_level_attached_html_companion_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md'
    attached_html_shortcut_note_path = 'docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md'
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    replay_discovery_handoff_note_path = 'docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    notes = @(
        'Start with attached_html_change_area when the replay is already narrowed to the generic attached-page compatibility route and you want that top-level command reprinted before dropping into the issue-specific helper chain.',
        'Start with google_attached_html_change_area when the replay is already narrowed to the Google-shaped attached-page lane and you want the issue-specific route reopened from the top-level headed validation router.',
        'Use attached_bundle_change_area or attached_bundle_first when the current pages are still the known three-page compatibility bundle and that pinned branch should stay visible before widening back into the broader Google-only helper stack.',
        'Run windows_full_use_attached_html_route_surface_check before the attached-html change-area quickstart or the broader top-level attached-page bridge when you want the Windows full-use route, its companion notes, and the linked helper chain to fail fast after branch moves.',
        'Run attached_html_shortcut_surface_check before attached_html_shortcut when the replay is already narrowed to the shortest issue-specific attached-page route and you want that shortcut note plus its linked helper chain to fail fast before choosing the next branch.',
        'Use attached_html_change_area_quickstart when you want the top-level attached-page route to reopen through the newer compact change-area helper that already prints the broader attached-page flow helper alongside the shorter issue #3 quickstarts and shortcut companion.',
        'Use top_level_attached_html_quickstart when you want the shorter top-level companion surface kept visible before the replay widens back into the broader entrypoint or narrows further into the suite-router attached-page quickstart.',
        'Use suite_router_attached_html_quickstart as the default next helper when no bundle inputs are pinned, because it keeps the shortest suite-router-side attached-page bridge visible after the compact top-level quickstart before you decide whether to drop to the issue-specific attached-page bridge, attached_html_shortcut, replay_route_shortcut, replay_shortcuts, the next-step matrix, or the safe-route map.',
        'Use google_attached_html_entrypoint when you want the issue-specific attached-page bridge surfaced directly after the suite-router attached-page quickstart without reopening the broader suite-catalog helpers first.',
        'Use attached_html_shortcut when the replay is already narrowed to attached-page follow-up and you want the shortest issue-specific bridge before widening into replay_route_shortcut, replay_shortcuts, the next-step matrix, or the pinned bundle-first branch.',
        'Use replay_route_shortcut when the attached-page route is already confirmed and you want the smaller replay-route companion surface before widening back into replay_shortcuts, the next-step matrix, or the safe-route map.',
        'Use contextual_flow when RepoRoot or SummaryPath is already in play and the next helper surface should keep that replay context aligned while you choose between the compact change-area quickstart, the compact top-level quickstart, the suite-router attached-page quickstart, issue-specific attached-page bridge, replay shortcuts, the next-step matrix, or the safe-route helpers.',
        'Use fresh_safe_route_replay when current outputs may be stale or missing. Use reuse_current_outputs only when a saved SummaryPath already exists and those outputs are still trusted.',
        'Keep the attached-html change-area quickstart note, the top-level attached-page quickstart note, the broader top-level attached-page bridge note, the top-level attached-page catalog quickstart, the top-level attached-page companion note, the attached-page shortcut note, the Windows replay quickstart, the replay discovery handoff, the suite-router attached-page quickstart, the suite-router bridge, the suite-catalog guide, the suite-catalog attached-page bridge, the Windows full-use attached-page route, the validation-chain note, and the Windows runbook nearby when you want the written route beside these commands.'
    )
}

$entrypoint.recommended_next_key = if ($entrypoint.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($entrypoint.repo_root) -or -not [string]::IsNullOrWhiteSpace($entrypoint.summary_path)) {
    'contextual_flow'
} else {
    'suite_router_attached_html_quickstart'
}
$entrypoint.recommended_next_command = $entrypoint.helper_commands[$entrypoint.recommended_next_key]
$entrypoint.recommended_next_reason = if ($entrypoint.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($entrypoint.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing between the attached-html change-area quickstart, the compact top-level quickstart, the suite-router attached-page quickstart, the issue-specific attached-page bridge, replay shortcuts, the next-step matrix, the bundle-first branch, or the safe-route helpers.'
} else {
    'No pinned bundle inputs, saved summary, or non-default repo root are in play yet, so jump straight from the broader top-level attached-page bridge into the shorter suite-router attached-page quickstart while keeping the newer change-area quickstart, fail-fast checkers, and compact top-level quickstart visible on the same surface.'
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 top-level attached HTML entrypoint'
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
Write-Host (("Recommended next helper: {0}") -f $entrypoint.recommended_next_command)
Write-Host (("Why:                    {0}") -f $entrypoint.recommended_next_reason)
Write-Host ''
Write-Host 'Top-level attached-page bridge:'
Write-Host (("  1. Attached HTML:              {0}") -f $entrypoint.top_level_commands.attached_html_change_area)
Write-Host (("  2. Google attached HTML:       {0}") -f $entrypoint.top_level_commands.google_attached_html_change_area)
Write-Host (("  3. Attached bundle:            {0}") -f $entrypoint.top_level_commands.attached_bundle_change_area)
Write-Host (("  4. Windows route check:        {0}") -f $entrypoint.top_level_commands.windows_full_use_attached_html_route_surface_check)
Write-Host (("  5. Attached shortcut check:    {0}") -f $entrypoint.top_level_commands.attached_html_shortcut_surface_check)
Write-Host (("  6. Change-area quickstart:     {0}") -f $entrypoint.top_level_commands.attached_html_change_area_quickstart)
Write-Host (("  7. Top-level shortcut:         {0}") -f $entrypoint.top_level_commands.top_level_shortcut_entrypoint)
Write-Host (("  8. Top-level quickstart:       {0}") -f $entrypoint.helper_commands.top_level_attached_html_quickstart)
Write-Host (("  9. Router attached quick:      {0}") -f $entrypoint.helper_commands.suite_router_attached_html_quickstart)
Write-Host ((" 10. Attached bridge:            {0}") -f $entrypoint.helper_commands.google_attached_html_entrypoint)
Write-Host ((" 11. Suite-catalog bridge:       {0}") -f $entrypoint.helper_commands.suite_catalog_entrypoints)
Write-Host ((" 12. Catalog attached:           {0}") -f $entrypoint.helper_commands.suite_catalog_attached_html_entrypoint)
Write-Host ((" 13. Attached shortcut:          {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host ((" 14. Router shortcut:            {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host ((" 15. Replay-route helper:        {0}") -f $entrypoint.helper_commands.replay_route_shortcut)
Write-Host ((" 16. Replay shortcuts:           {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host ((" 17. Next-step matrix:           {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host ((" 18. Bundle first:               {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host ''
Write-Host 'Companion helpers:'
Write-Host (("  Windows route check:     {0}") -f $entrypoint.top_level_commands.windows_full_use_attached_html_route_surface_check)
Write-Host (("  Attached shortcut check: {0}") -f $entrypoint.top_level_commands.attached_html_shortcut_surface_check)
Write-Host (("  Change-area quickstart:  {0}") -f $entrypoint.top_level_commands.attached_html_change_area_quickstart)
Write-Host (("  Top-level quickstart:    {0}") -f $entrypoint.helper_commands.top_level_attached_html_quickstart)
Write-Host (("  Router attached quick:   {0}") -f $entrypoint.helper_commands.suite_router_attached_html_quickstart)
Write-Host (("  Attached bridge:         {0}") -f $entrypoint.helper_commands.google_attached_html_entrypoint)
Write-Host (("  Suite-catalog bridge:    {0}") -f $entrypoint.helper_commands.suite_catalog_entrypoints)
Write-Host (("  Catalog attached:        {0}") -f $entrypoint.helper_commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  Attached shortcut:       {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host (("  Router shortcut:         {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host (("  Replay-route helper:     {0}") -f $entrypoint.helper_commands.replay_route_shortcut)
Write-Host (("  Replay shortcuts:        {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host (("  Next-step matrix:        {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host (("  Contextual flow:         {0}") -f $entrypoint.helper_commands.contextual_flow)
Write-Host (("  Bundle first:            {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host (("  Safe-route map:          {0}") -f $entrypoint.helper_commands.safe_route_entrypoints)
Write-Host (("  Fresh safe replay:       {0}") -f $entrypoint.helper_commands.fresh_safe_route_replay)
Write-Host (("  Reuse current outputs:   {0}") -f $entrypoint.helper_commands.reuse_current_outputs)
Write-Host ''
Write-Host (("Change-area quickstart:         {0}") -f (' ' + $entrypoint.attached_html_change_area_quickstart_note_path))
Write-Host (("Top-level quickstart:           {0}") -f (' ' + $entrypoint.top_level_attached_html_quickstart_note_path))
Write-Host (("Top-level bridge note:          {0}") -f (' ' + $entrypoint.top_level_attached_html_bridge_note_path))
Write-Host (("Top-level catalog quickstart:   {0}") -f (' ' + $entrypoint.top_level_attached_html_catalog_quickstart_note_path))
Write-Host (("Top-level companion notes:      {0}") -f (' ' + $entrypoint.top_level_attached_html_companion_note_path))
Write-Host (("Attached shortcut note:         {0}") -f (' ' + $entrypoint.attached_html_shortcut_note_path))
Write-Host (("Quickstart note:                {0}") -f $entrypoint.quickstart_note_path)
Write-Host (("Replay discovery handoff:       {0}") -f $entrypoint.replay_discovery_handoff_note_path)
Write-Host (("Suite-router attached note:     {0}") -f $entrypoint.suite_router_attached_html_quickstart_note_path)
Write-Host (("Suite-router bridge:            {0}") -f $entrypoint.suite_router_bridge_note_path)
Write-Host (("Suite-catalog guide:            {0}") -f $entrypoint.suite_catalog_entrypoint_note_path)
Write-Host (("Suite-catalog attached note:    {0}") -f $entrypoint.suite_catalog_attached_html_bridge_note_path)
Write-Host (("Windows full-use attached route:{0}") -f (' ' + $entrypoint.windows_full_use_attached_html_route_note_path))
Write-Host (("Validation chain:               {0}") -f $entrypoint.validation_chain_note_path)
Write-Host (("Windows runbook:                {0}") -f $entrypoint.windows_runbook_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}