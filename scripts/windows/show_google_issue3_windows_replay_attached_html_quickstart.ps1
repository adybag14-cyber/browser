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

$helper = [ordered]@{
    issue = 'Google issue #3 Windows replay attached HTML quickstart'
    purpose = 'Print the narrow attached-localhost ladder that matches the current Windows replay route for issue #3, while keeping the Windows full-use route-level surface check and the Windows-to-validation-router bridge visible before the route narrows back into the compact attached-page helpers.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    validation_router_attached_html_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    attached_html_change_area_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    windows_full_use_validation_router_attached_html_bridge_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    commands = [ordered]@{
        windows_full_use_attached_html_route_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -Arguments $routeSurfaceArguments
        windows_full_use_validation_router_attached_html_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $sharedArguments
        validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $sharedArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $sharedArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $sharedArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $sharedArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $sharedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Start here when docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md already narrowed the next replay to the attached localhost branch and you want the shortest helper ladder printed in one place.',
        'Use windows_full_use_attached_html_route_surface_check after branch moves or before trusting this route from another checkout, because it fails fast on missing route notes, helper scripts, or downstream attached-page surfaces before the replay narrows again.',
        'Use windows_full_use_validation_router_attached_html_bridge first when the replay is re-entering from docs/WINDOWS_FULL_USE.md or the broader Windows full-use attached-page note and you want the route-level surface check plus the Windows-to-validation-router handoff kept visible before the route drops back into the compact attached-page helpers.',
        'Use validation_router_attached_html_quickstart first when the replay already passed the broader Windows full-use guard rails and you still want the wider validation-router attached-page bridge visible before the top-level attached-page quickstarts.',
        'Then prefer attached_html_change_area_quickstart, top_level_attached_html_quickstart, and top_level_attached_html_entrypoint as the default middle of the ladder so the broader attached-page flow helper and the compact top-level route stay visible before you drop into the suite-catalog bridge or the shorter attached-page shortcut.',
        'Use top_level_attached_html_catalog_quickstart when you want the compact top-level quickstart and the suite-catalog attached-page bridge reprinted together before the route narrows again.',
        'Use suite_catalog_attached_html_entrypoint when you want the suite-catalog-side attached-page bridge without reopening broader router helpers first.',
        'Keep suite_router_attached_html_quickstart nearby as the sidecar helper when the route needs to widen back toward the suite-router surface instead of narrowing directly into the shorter attached-page bridge or the attached-page shortcut.',
        'Use attached_html_shortcut only after the top-level attached-page quickstart, change-area quickstart, or bridge is already in view and the replay is ready to stay inside the narrower issue #3 helper chain.',
        'Use replay_shortcuts after the attached-page shortcut or the suite-catalog bridge when you want the tightest current helper surface before widening back out.',
        'Use contextual_flow when RepoRoot, SummaryPath, or pinned InputPath values already matter and the next helper should preserve that replay context before it narrows again.',
        'Use attached_bundle_first when explicit InputPath values are already pinned to the known three-page compatibility bundle and the replay should stay on that locked route before widening back into the broader issue #3 helper stack.',
        'Use windows_full_use_attached_html_route when the replay came from docs/WINDOWS_FULL_USE.md first and you want the broader Windows runbook attached-page route visible beside this shorter replay ladder.',
        'Keep the Windows replay quickstart note, the Windows full-use attached-page route note, the Windows full-use validation-router attached-html bridge note, the validation-router attached-page note, the attached-html change-area quickstart note, the top-level attached-page quickstart note, the top-level attached-page bridge note, the top-level attached-page catalog quickstart note, the suite-catalog attached-page bridge note, the suite-router attached-page quickstart note, and the validation-chain note nearby when you want the written route beside these commands.'
    )
}

$helper.recommended_next_key = if ($helper.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($helper.repo_root) -or -not [string]::IsNullOrWhiteSpace($helper.summary_path)) {
    'contextual_flow'
} else {
    'windows_full_use_validation_router_attached_html_bridge'
}
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so keep the replay on the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($helper.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing between the narrower attached-page helpers.'
} else {
    'No pinned bundle inputs, non-default repo root, or saved summary are in play yet, so reopen the Windows full-use validation-router attached-html bridge first and keep the route-level surface checker nearby before dropping into the smaller attached-page quickstarts.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 Windows replay attached HTML quickstart'
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
Write-Host 'Route guard:'
Write-Host (("  Surface checker:          {0}") -f $helper.commands.windows_full_use_attached_html_route_surface_check)
Write-Host ''
Write-Host 'Broader Windows bridge:'
Write-Host (("  Windows full-use route:   {0}") -f $helper.commands.windows_full_use_attached_html_route)
Write-Host (("  Validation bridge:        {0}") -f $helper.commands.windows_full_use_validation_router_attached_html_bridge)
Write-Host ''
Write-Host 'Attached-page ladder:'
Write-Host (("  Validation-router quick:  {0}") -f $helper.commands.validation_router_attached_html_quickstart)
Write-Host (("  Change-area quick:        {0}") -f $helper.commands.attached_html_change_area_quickstart)
Write-Host (("  Top-level quickstart:     {0}") -f $helper.commands.top_level_attached_html_quickstart)
Write-Host (("  Top-level bridge:         {0}") -f $helper.commands.top_level_attached_html_entrypoint)
Write-Host (("  Catalog quickstart:       {0}") -f $helper.commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  Suite-catalog bridge:     {0}") -f $helper.commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  Suite-router sidecar:     {0}") -f $helper.commands.suite_router_attached_html_quickstart)
Write-Host (("  Attached shortcut:        {0}") -f $helper.commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:         {0}") -f $helper.commands.replay_shortcuts)
Write-Host (("  Contextual flow:          {0}") -f $helper.commands.contextual_flow)
Write-Host (("  Bundle-first helper:      {0}") -f $helper.commands.attached_bundle_first)
Write-Host (("  Safe-route map:           {0}") -f $helper.commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Windows replay note:         {0}") -f (' ' + $helper.windows_replay_quickstart_note_path))
Write-Host (("Windows route note:          {0}") -f (' ' + $helper.windows_full_use_attached_html_route_note_path))
Write-Host (("Windows bridge note:         {0}") -f (' ' + $helper.windows_full_use_validation_router_attached_html_bridge_note_path))
Write-Host (("Validation-router note:      {0}") -f (' ' + $helper.validation_router_attached_html_note_path))
Write-Host (("Change-area quickstart note: {0}") -f (' ' + $helper.attached_html_change_area_quickstart_note_path))
Write-Host (("Top-level quickstart note:   {0}") -f (' ' + $helper.top_level_attached_html_quickstart_note_path))
Write-Host (("Top-level bridge note:       {0}") -f (' ' + $helper.top_level_attached_html_bridge_note_path))
Write-Host (("Catalog quickstart note:     {0}") -f (' ' + $helper.top_level_attached_html_catalog_quickstart_note_path))
Write-Host (("Suite-catalog note:          {0}") -f (' ' + $helper.suite_catalog_attached_html_bridge_note_path))
Write-Host (("Suite-router note:           {0}") -f (' ' + $helper.suite_router_attached_html_quickstart_note_path))
Write-Host (("Validation chain note:       {0}") -f (' ' + $helper.validation_chain_note_path))
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
