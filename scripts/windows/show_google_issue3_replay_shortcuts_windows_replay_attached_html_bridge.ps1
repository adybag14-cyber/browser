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

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $InputPath

$routeSurfaceArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $routeSurfaceArguments -Name RepoRoot -Value $RepoRoot

$bridge = [ordered]@{
    issue = 'Google issue #3 replay-shortcuts Windows replay attached HTML bridge'
    purpose = 'Print the shortest bridge from the replay-shortcuts surface into the Windows replay attached-page ladder while keeping the route-level fail-fast checks, Windows-first route bridge, and narrower attached-page follow-ups visible before the helper chain widens back into the safe-route map.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    replay_shortcuts_note_path = 'docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md'
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    windows_full_use_validation_router_attached_html_bridge_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md'
    windows_full_use_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    validation_router_attached_html_quickstart_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    attached_html_change_area_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_catalog_top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    attached_html_shortcut_note_path = 'docs/ISSUE3_ATTACHED_HTML_SHORTCUT_BRIDGE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    commands = [ordered]@{
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $sharedArguments
        windows_replay_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -Arguments $routeSurfaceArguments
        windows_route_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -Arguments $routeSurfaceArguments
        windows_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $sharedArguments
        windows_validation_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $sharedArguments
        windows_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        windows_replay_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $sharedArguments
        validation_router_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $sharedArguments
        top_level_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $sharedArguments
        top_level_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        top_level_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        suite_catalog_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        suite_catalog_attached_html = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $sharedArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $sharedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Start here when the route is already clearly inside show_google_issue3_replay_shortcuts.ps1 but the next replay should stay on the Windows replay attached-page ladder a little longer before widening back into the wrapper-heavy safe-route helpers.',
        'Run windows_replay_surface_check first after branch moves or before trusting the narrower replay-side ladder from another checkout, because it fails fast on missing note, helper, or downstream attached-page surfaces.',
        'Run windows_route_surface_check and windows_route when the replay should keep the broader Windows full-use attached-page route visible beside the shorter replay-side ladder.',
        'Use windows_validation_bridge and windows_catalog_quickstart when the route still needs the Windows-first validation-router bridge and Windows-side catalog step kept visible before the narrower replay-side helper takes over.',
        'Use windows_replay_quickstart as the default next helper whenever no explicit bundle inputs, saved summary, or non-default repo root need to take precedence first.',
        'Keep validation_router_quickstart, attached_html_change_area_quickstart, top_level_quickstart, top_level_entrypoint, top_level_catalog_quickstart, and suite_catalog_catalog_quickstart nearby when the narrower replay-side ladder still needs one broader attached-page checkpoint before it collapses into attached_html_shortcut or widens back into replay_shortcuts.',
        'Use suite_catalog_attached_html when the suite-catalog-side bridge should stay visible without reopening the broader router chain first.',
        'Use attached_html_shortcut when the route is already narrow enough to stay inside the shorter issue #3 attached-page bridge before replay_shortcuts or safe_route_entrypoints are reopened.',
        'Use contextual_flow when RepoRoot, SummaryPath, or pinned InputPath values already matter and the next helper should keep that replay context aligned.',
        'Use attached_bundle_first when explicit InputPath values are already pinned to the known three-page compatibility bundle and the replay should stay on that locked route before widening back out.',
        'Keep the replay-shortcuts note, the Windows replay attached-page quickstart note, the Windows full-use attached-page route note, the Windows full-use validation-router bridge note, the Windows full-use catalog quickstart note, the validation-router attached-page quickstart note, the attached-html change-area quickstart note, the top-level attached-page quickstart note, the top-level attached-page bridge note, the top-level attached-page catalog quickstart note, the suite-catalog-to-top-level attached-html catalog quickstart note, the suite-catalog attached-page bridge note, the attached-page shortcut note, and the validation-chain note nearby when you want the written route beside these commands.'
    )
}

$bridge.recommended_next_key = if ($bridge.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($bridge.repo_root) -or -not [string]::IsNullOrWhiteSpace($bridge.summary_path)) {
    'contextual_flow'
} else {
    'windows_replay_quickstart'
}
$bridge.recommended_next_command = $bridge.commands[$bridge.recommended_next_key]
$bridge.recommended_next_reason = if ($bridge.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so stay on the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($bridge.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing between the narrower attached-page helpers.'
} else {
    'No pinned bundle inputs, saved summary, or non-default repo root are already in play, so jump straight from replay shortcuts into the Windows replay attached-page quickstart and keep that replay-side ladder visible before narrowing further.'
}

if ($Json) {
    $bridge | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 replay-shortcuts Windows replay attached HTML bridge'
Write-Host ''
if ($bridge.repo_root) {
    Write-Host (("Repo root:   {0}") -f $bridge.repo_root)
}
if ($bridge.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($bridge.summary_path)"))
}
if ($bridge.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $bridge.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $bridge.recommended_next_command)
Write-Host (("Why:                    {0}") -f $bridge.recommended_next_reason)
Write-Host ''
Write-Host 'Replay-shortcuts bridge:'
Write-Host (("  Replay shortcuts:         {0}") -f $bridge.commands.replay_shortcuts)
Write-Host (("  Replay quickstart check:  {0}") -f $bridge.commands.windows_replay_surface_check)
Write-Host (("  Windows route check:      {0}") -f $bridge.commands.windows_route_surface_check)
Write-Host (("  Windows route:            {0}") -f $bridge.commands.windows_route)
Write-Host (("  Validation bridge:        {0}") -f $bridge.commands.windows_validation_bridge)
Write-Host (("  Windows catalog quick:    {0}") -f $bridge.commands.windows_catalog_quickstart)
Write-Host (("  Windows replay quick:     {0}") -f $bridge.commands.windows_replay_quickstart)
Write-Host (("  Validation-router quick:  {0}") -f $bridge.commands.validation_router_quickstart)
Write-Host (("  Change-area quickstart:   {0}") -f $bridge.commands.attached_html_change_area_quickstart)
Write-Host (("  Top-level quickstart:     {0}") -f $bridge.commands.top_level_quickstart)
Write-Host (("  Top-level bridge:         {0}") -f $bridge.commands.top_level_entrypoint)
Write-Host (("  Top-level catalog quick:  {0}") -f $bridge.commands.top_level_catalog_quickstart)
Write-Host (("  Catalog bridge quick:     {0}") -f $bridge.commands.suite_catalog_catalog_quickstart)
Write-Host (("  Suite-catalog bridge:     {0}") -f $bridge.commands.suite_catalog_attached_html)
Write-Host (("  Attached shortcut:        {0}") -f $bridge.commands.attached_html_shortcut)
Write-Host (("  Contextual flow:          {0}") -f $bridge.commands.contextual_flow)
Write-Host (("  Bundle first:             {0}") -f $bridge.commands.attached_bundle_first)
Write-Host (("  Safe-route map:           {0}") -f $bridge.commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Replay-shortcuts note:      {0}") -f (' ' + $bridge.replay_shortcuts_note_path))
Write-Host (("Windows replay note:        {0}") -f (' ' + $bridge.windows_replay_attached_html_quickstart_note_path))
Write-Host (("Windows route note:         {0}") -f (' ' + $bridge.windows_full_use_attached_html_route_note_path))
Write-Host (("Windows bridge note:        {0}") -f (' ' + $bridge.windows_full_use_validation_router_attached_html_bridge_note_path))
Write-Host (("Windows catalog note:       {0}") -f (' ' + $bridge.windows_full_use_attached_html_catalog_quickstart_note_path))
Write-Host (("Validation-router note:     {0}") -f (' ' + $bridge.validation_router_attached_html_quickstart_note_path))
Write-Host (("Change-area quickstart note:{0}") -f (' ' + $bridge.attached_html_change_area_quickstart_note_path))
Write-Host (("Top-level quickstart note:  {0}") -f (' ' + $bridge.top_level_attached_html_quickstart_note_path))
Write-Host (("Top-level bridge note:      {0}") -f (' ' + $bridge.top_level_attached_html_bridge_note_path))
Write-Host (("Top-level catalog note:     {0}") -f (' ' + $bridge.top_level_attached_html_catalog_quickstart_note_path))
Write-Host (("Catalog bridge note:        {0}") -f (' ' + $bridge.suite_catalog_top_level_attached_html_catalog_quickstart_note_path))
Write-Host (("Suite-catalog note:         {0}") -f (' ' + $bridge.suite_catalog_attached_html_bridge_note_path))
Write-Host (("Attached shortcut note:     {0}") -f (' ' + $bridge.attached_html_shortcut_note_path))
Write-Host (("Validation chain note:      {0}") -f (' ' + $bridge.validation_chain_note_path))
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $bridge.notes) {
    Write-Host (("- {0}") -f $note)
}