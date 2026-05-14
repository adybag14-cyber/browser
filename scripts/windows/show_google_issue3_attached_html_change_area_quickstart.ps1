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

$helper = [ordered]@{
    issue = 'Google issue #3 attached-html change-area quickstart'
    purpose = 'Print the shortest follow-up from show_headed_validation_suites.ps1 -ChangeArea attached-html into the compact issue #3 attached-page helper chain while also surfacing the broader attached-page flow helper, and preserving repo-root, saved-summary, and pinned bundle-input context.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    attached_html_change_area_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    commands = [ordered]@{
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        attached_html_flow = Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $emptyArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $sharedArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        top_level_shortcut_first_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $sharedArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $sharedArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $sharedArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $sharedArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $sharedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Start with attached_html_change_area when the top-level headed validation router already narrowed the replay to the generic attached localhost compatibility route and you want that route reprinted before you choose a smaller issue #3 helper.',
        'Use attached_html_flow when you want the broader attached-page helper surface visible from that same change-area entry before dropping into the issue-specific quickstarts or the shortcut companion.',
        'Use google_attached_html_change_area when the replay still needs the broader Google-shaped attached-page route visible before you narrow again.',
        'Use top_level_attached_html_quickstart as the default next helper when no pinned bundle inputs, non-default repo root, or saved summary need to take precedence, because it keeps the compact top-level attached-page route visible before you drop into the narrower bridge and shortcut helpers.',
        'Use suite_router_attached_html_quickstart when the next replay should stay closer to the suite-router-side attached-page branch before widening back into the broader helper chain.',
        'Use top_level_attached_html_entrypoint when the route is already clearly inside the issue-specific attached-page branch and you want the broader top-level attached-page bridge reprinted before the shorter quickstart or shortcut helpers.',
        'Use top_level_shortcut_first_entrypoint when the replay is already narrowed enough that the shortest top-level shortcut bridge is the most useful follow-up.',
        'Use suite_catalog_attached_html_entrypoint when the suite-catalog-side attached-page bridge should stay visible before you narrow again.',
        'Use attached_html_shortcut when the route is already clearly inside attached-page follow-up and you want the shortest bridge before widening back into replay_shortcuts, the next-step matrix, contextual_flow, or the safe-route map.',
        'Use replay_shortcuts when the route is already narrow enough that the compact issue #3 replay surface is the next best layer.',
        'Use attached_bundle_change_area and attached_bundle_first when the current replay should stay pinned to the known three-page compatibility bundle before widening back into the broader helper chain.',
        'Use contextual_flow when RepoRoot, SummaryPath, or fixed InputPath values already matter and you want the next helper surface to keep that replay context aligned before you choose between the quickstarts, the broader attached-page flow helper, shortcuts, next-step matrix, or safe-route wrapper.',
        'Use safe_route_entrypoints only after the replay is already narrowed enough that the wrapper-heavy issue #3 command surface is the next useful layer.',
        'Keep the attached-html change-area quickstart note, the Windows full-use attached-html route note, the Windows replay quickstart note, the top-level attached-page quickstart note, the suite-router attached-page quickstart note, the top-level attached-page bridge note, the suite-catalog attached-page bridge note, and the validation-chain note nearby when you want the written route beside these commands.'
    )
}

$helper.recommended_next_key = if ($helper.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($helper.repo_root) -or -not [string]::IsNullOrWhiteSpace($helper.summary_path)) {
    'contextual_flow'
} else {
    'top_level_attached_html_quickstart'
}
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader issue #3 attached-page helper chain.'
} elseif ($helper.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing between the broader attached-page flow helper, the attached-page quickstarts, shortcuts, next-step matrix, or the safe-route helper.'
} else {
    'No pinned bundle inputs, non-default repo root, or saved summary are in play yet, so jump straight from the top-level attached-html change-area route into the compact top-level attached-page quickstart while keeping the broader attached-page flow helper and the shortcut companion nearby.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 attached-html change-area quickstart'
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
Write-Host 'Top-level attached-page router surfaces:'
Write-Host (("  Attached HTML:        {0}") -f $helper.commands.attached_html_change_area)
Write-Host (("  Google attached HTML: {0}") -f $helper.commands.google_attached_html_change_area)
Write-Host (("  Attached bundle:      {0}") -f $helper.commands.attached_bundle_change_area)
Write-Host (("  Attached flow helper: {0}") -f $helper.commands.attached_html_flow)
Write-Host ''
Write-Host 'Compact attached-page follow-up helpers:'
Write-Host (("  Top-level quickstart:     {0}") -f $helper.commands.top_level_attached_html_quickstart)
Write-Host (("  Suite-router quickstart:  {0}") -f $helper.commands.suite_router_attached_html_quickstart)
Write-Host (("  Top-level attached route: {0}") -f $helper.commands.top_level_attached_html_entrypoint)
Write-Host (("  Top-level shortcut:       {0}") -f $helper.commands.top_level_shortcut_first_entrypoint)
Write-Host (("  Catalog attached bridge:  {0}") -f $helper.commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  Attached shortcut:        {0}") -f $helper.commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:         {0}") -f $helper.commands.replay_shortcuts)
Write-Host (("  Next-step matrix:         {0}") -f $helper.commands.suite_router_next_steps)
Write-Host (("  Contextual flow:          {0}") -f $helper.commands.contextual_flow)
Write-Host (("  Bundle-first helper:      {0}") -f $helper.commands.attached_bundle_first)
Write-Host (("  Safe-route map:           {0}") -f $helper.commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Change-area quickstart:   {0}") -f (' ' + $helper.attached_html_change_area_quickstart_note_path))
Write-Host (("Windows full-use route:    {0}") -f (' ' + $helper.windows_full_use_attached_html_route_note_path))
Write-Host (("Windows replay quickstart: {0}") -f (' ' + $helper.windows_replay_quickstart_note_path))
Write-Host (("Top-level quickstart note: {0}") -f (' ' + $helper.top_level_attached_html_quickstart_note_path))
Write-Host (("Suite-router quickstart:   {0}") -f (' ' + $helper.suite_router_attached_html_quickstart_note_path))
Write-Host (("Top-level bridge note:     {0}") -f (' ' + $helper.top_level_attached_html_bridge_note_path))
Write-Host (("Catalog bridge note:       {0}") -f (' ' + $helper.suite_catalog_attached_html_bridge_note_path))
Write-Host (("Validation chain note:     {0}") -f (' ' + $helper.validation_chain_note_path))
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
