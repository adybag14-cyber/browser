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

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$googleAttachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $googleAttachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$windowsFullUseAttachedHtmlRouteSurfaceCheckCommand = Format-HelperCommand -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -Arguments $bundleArguments
$windowsFullUseValidationRouterAttachedHtmlBridgeCommand = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $bundleArguments
$windowsReplayAttachedHtmlQuickstartCommand = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments

$entrypoint = [ordered]@{
    issue = 'Google issue #3 Windows full-use attached HTML catalog quickstart'
    purpose = 'Keep the broader Windows full-use attached-page route, the broader attached-page flow helper, the dedicated Google-shaped attached-page flow helper, and the newer top-level attached-page catalog quickstart visible on one compact helper before the replay narrows into the suite-catalog attached-page bridge, the shorter attached-page shortcut, the pinned bundle-first path, or the wrapper-heavy safe-route map.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    top_level_commands = [ordered]@{
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $bundleArguments
        windows_full_use_attached_html_route_surface_check = $windowsFullUseAttachedHtmlRouteSurfaceCheckCommand
        windows_full_use_validation_router_attached_html_bridge = $windowsFullUseValidationRouterAttachedHtmlBridgeCommand
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
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $bundleArguments
        attached_html_validation_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        windows_replay_attached_html_quickstart = $windowsReplayAttachedHtmlQuickstartCommand
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        google_attached_html_validation_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
    }
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    windows_full_use_validation_router_attached_html_bridge_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md'
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    top_level_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    notes = @(
        'Use this helper when docs/WINDOWS_FULL_USE.md has already narrowed the next replay to attached localhost follow-up and you want the route-level surface check, the Windows-to-validation-router bridge, the broader attached-page flow helper, and the replay-side attached-page quickstart reprinted beside the newer top-level attached-page catalog quickstart.',
        'Use attached_html_change_area_quickstart after the broader Windows full-use route and the validation-router bridge when the broader attached-page router surface should stay visible before the compact replay-side and top-level quickstarts narrow the route again.',
        'Use attached_html_validation_flow after the change-area quickstart when the replay still needs the broader attached-page localhost helper visible, and keep pinned InputPath values attached to that helper before the route drops into the replay-side attached-page quickstart or the top-level attached-page quickstarts.',
        'Use windows_replay_attached_html_quickstart as the default next helper when no pinned bundle inputs, saved summary, or non-default repo root need to take precedence first, because it keeps the replay-side attached-page quickstart visible before the route narrows into the top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-router attached-page quickstart, the suite-catalog attached-page bridge, the shorter attached-page shortcut, replay shortcuts, or the safe-route map.',
        'Use top_level_attached_html_catalog_quickstart when you want the compact top-level attached-page quickstart and the suite-catalog-side attached-page bridge printed together before the route narrows into the shorter attached-page shortcut, replay shortcuts, contextual flow, or the safe-route map.',
        'Use suite_catalog_attached_html_entrypoint after the top-level catalog quickstart when the suite-catalog-side attached-page bridge should stay visible before the replay narrows again.',
        'Use google_attached_html_validation_flow when the current attached inputs are already Google-shaped and you want the dedicated attached-page flow helper visible beside the broader Windows and top-level attached-page ladders before the route narrows back into the shorter issue #3 helper chain.',
        'Use attached_bundle_first when explicit InputPath values are already pinned to the known three-page compatibility bundle and that bundle-first branch should stay visible before widening back into the broader issue #3 helper chain.',
        'Use contextual_flow when RepoRoot or SummaryPath is already in play and the next helper surface should keep that replay context aligned while you choose between the suite-catalog attached-page bridge, replay shortcuts, the next-step matrix, the bundle-first branch, or the safe-route map.',
        'Keep the Windows runbook, the Windows full-use attached-page route note, the Windows validation-router attached-page bridge note, the Windows replay attached-page quickstart note, the top-level attached-page catalog quickstart note, the suite-catalog attached-page bridge note, the Google attached-page validation-flow note, and the Windows replay quickstart nearby when you want the written route beside these commands.'
    )
}

$entrypoint.recommended_next_key = if ($entrypoint.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($entrypoint.repo_root) -or -not [string]::IsNullOrWhiteSpace($entrypoint.summary_path)) {
    'contextual_flow'
} else {
    'windows_replay_attached_html_quickstart'
}
$entrypoint.recommended_next_command = $entrypoint.helper_commands[$entrypoint.recommended_next_key]
$entrypoint.recommended_next_reason = if ($entrypoint.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so stay on the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($entrypoint.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing whether to reopen the replay-side attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, replay shortcuts, the next-step matrix, or the safe-route map.'
} else {
    'No pinned bundle inputs, saved summary, or non-default repo root are in play yet, so jump straight from the Windows full-use route into the replay-side attached-page quickstart while keeping the broader attached-page flow helper available before widening into the top-level attached-page quickstart and the top-level catalog quickstart.'
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 Windows full-use attached HTML catalog quickstart'
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
Write-Host 'Windows full-use catalog bridge:'
Write-Host (("  1. Windows route:         {0}") -f $entrypoint.top_level_commands.windows_full_use_attached_html_route)
Write-Host (("  2. Route check:           {0}") -f $entrypoint.top_level_commands.windows_full_use_attached_html_route_surface_check)
Write-Host (("  3. Validation bridge:     {0}") -f $entrypoint.top_level_commands.windows_full_use_validation_router_attached_html_bridge)
Write-Host (("  4. Attached HTML:         {0}") -f $entrypoint.top_level_commands.attached_html_change_area)
Write-Host (("  5. Google attached HTML:  {0}") -f $entrypoint.top_level_commands.google_attached_html_change_area)
Write-Host (("  6. Attached bundle:       {0}") -f $entrypoint.top_level_commands.attached_bundle_change_area)
Write-Host (("  7. Change-area bridge:    {0}") -f $entrypoint.helper_commands.attached_html_change_area_quickstart)
Write-Host (("  8. Attached flow:         {0}") -f $entrypoint.helper_commands.attached_html_validation_flow)
Write-Host (("  9. Replay quickstart:     {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)
Write-Host ((" 10. Top-level quickstart:  {0}") -f $entrypoint.helper_commands.top_level_attached_html_quickstart)
Write-Host ((" 11. Top-level bridge:      {0}") -f $entrypoint.helper_commands.top_level_attached_html_entrypoint)
Write-Host ((" 12. Catalog quickstart:    {0}") -f $entrypoint.helper_commands.top_level_attached_html_catalog_quickstart)
Write-Host ((" 13. Router quickstart:     {0}") -f $entrypoint.helper_commands.suite_router_attached_html_quickstart)
Write-Host ((" 14. Catalog bridge:        {0}") -f $entrypoint.helper_commands.suite_catalog_attached_html_entrypoint)
Write-Host ((" 15. Google attached:       {0}") -f $entrypoint.helper_commands.google_attached_html_entrypoint)
Write-Host ((" 16. Google attached flow:  {0}") -f $entrypoint.helper_commands.google_attached_html_validation_flow)
Write-Host ((" 17. Attached shortcut:     {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host ((" 18. Replay shortcuts:      {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host ((" 19. Next-step matrix:      {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host ((" 20. Contextual flow:       {0}") -f $entrypoint.helper_commands.contextual_flow)
Write-Host ((" 21. Bundle first:          {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host ((" 22. Safe-route map:        {0}") -f $entrypoint.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Windows runbook:            {0}") -f $entrypoint.windows_runbook_note_path)
Write-Host (("Windows attached route:     {0}") -f $entrypoint.windows_full_use_attached_html_route_note_path)
Write-Host (("Windows validation bridge:  {0}") -f $entrypoint.windows_full_use_validation_router_attached_html_bridge_note_path)
Write-Host (("Windows replay attached:    {0}") -f $entrypoint.windows_replay_attached_html_quickstart_note_path)
Write-Host (("Catalog quickstart note:    {0}") -f $entrypoint.top_level_catalog_quickstart_note_path)
Write-Host (("Catalog bridge note:        {0}") -f $entrypoint.suite_catalog_attached_html_bridge_note_path)
Write-Host (("Google attached flow note:  {0}") -f $entrypoint.google_attached_html_validation_flow_note_path)
Write-Host (("Replay quickstart note:     {0}") -f $entrypoint.windows_replay_quickstart_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}
