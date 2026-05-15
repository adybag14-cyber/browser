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

$helper = [ordered]@{
    issue = 'Google issue #3 validation-router attached HTML quickstart'
    purpose = 'Print the shortest bridge from the broader headed validation router into the newer suite-catalog-to-top-level attached-page catalog quickstart and top-level attached-page quickstarts for issue #3, while also surfacing the validation-router surface check, the attached-html change-area quickstart, the broader attached-page flow helper, the top-level shortcut-first bridge, the Google-shaped attached-page branch, the pinned bundle branch, and the Windows full-use attached-page route when those broader reopening surfaces still matter.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    validation_router_attached_html_quickstart_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    attached_html_change_area_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    top_level_shortcut_first_entrypoint_note_path = 'docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md'
    suite_catalog_top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    commands = [ordered]@{
        google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        google_input = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_target = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        validation_router_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -RepoRootOverride $RepoRoot
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $bundleArguments
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $bundleArguments
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $bundleArguments
        suite_catalog_top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        suite_router_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        top_level_shortcut_first = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
    }
    notes = @(
        'Start with google_recommended or google_input when you are re-entering issue #3 from the broader headed validation router and want that higher-level surface visible before you narrow into the attached localhost branch.',
        'Run validation_router_attached_html_surface_check after branch moves or before trusting this helper from a different checkout, because it fails fast on missing notes, helper scripts, or downstream route surfaces before the shorter attached-page bridge narrows again.',
        'Use attached_html when the replay is already centered on the attached localhost compatibility pages and you still want the broader validation catalog branch reprinted before dropping into the issue-specific helper chain.',
        'Use google_attached_html when the replay still needs the broader Google-shaped attached-page branch visible before dropping into the compact top-level attached-page quickstarts.',
        'Use attached_bundle_target when the broader validation router already knows the current pages are the pinned three-page compatibility bundle and you still want that top-level bundle branch visible before dropping into the compact helper chain.',
        'Use windows_full_use_attached_html_route when the replay is reopening from docs/WINDOWS_FULL_USE.md and you want the dedicated Windows runbook attached-page route reprinted before falling back to the shorter validation-router bridge.',
        'Use attached_html_change_area_quickstart when the replay is already reopening from show_headed_validation_suites.ps1 -ChangeArea attached-html and you want the broader attached-page flow helper plus the compact top-level attached-page route surfaced together before the route narrows again.',
        'Use attached_html_flow when you want the broader attached-page localhost flow helper printed directly from the validation-router bridge before the replay narrows into the compact top-level attached-page quickstart, the top-level shortcut-first bridge, or the suite-router attached-page branch.',
        'Use suite_catalog_entrypoints when RepoRoot, SummaryPath, or pinned InputPath values already matter and you want the broader issue #3 helper bridge to preserve that replay state before narrowing again.',
        'Use suite_catalog_top_level_attached_html_catalog_quickstart when the suite-catalog surface is already open and you want the replay-side attached-html ladder plus the top-level attached-page catalog quickstart visible together before the route narrows into the suite-catalog attached-page bridge, the top-level attached-page quickstart, or the shorter attached-page shortcut.',
        'Use suite_router_quickstart when the top-level suite router already made issue #3 obvious and you want the shortest router-side bridge before you reopen the compact top-level attached-page quickstarts.',
        'Use top_level_attached_html_quickstart as the default next helper when no pinned bundle inputs, non-default repo root, or saved summary need to take precedence, because it keeps the shortest top-level attached-page route visible before reopening the catalog quickstart, the broader top-level bridge, the attached-page shortcut, replay shortcuts, or the next-step matrix.',
        'Use top_level_attached_html_catalog_quickstart when you want the compact top-level attached-page quickstart plus the suite-catalog attached-page bridge kept visible together before the route narrows again.',
        'Use top_level_attached_html_entrypoint when you want the broader top-level attached-page bridge beside the compact quickstarts before widening back into replay shortcuts or the next-step matrix.',
        'Use top_level_shortcut_first when the route is about to collapse from the broader top-level attached-page chain into the attached-page shortcut, replay-route shortcut, replay shortcuts, the next-step matrix, or the safe-route map.',
        'Use suite_router_attached_html_quickstart when the route has already dropped back to the suite-router side and you want the shorter attached-page bridge preserved there.',
        'Use attached_html_shortcut or replay_shortcuts only after the compact top-level attached-page route is already in view and the replay is ready to stay inside the narrower issue #3 helper chain.',
        'Use attached_bundle_first when explicit input paths are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.',
        'Keep the Windows replay quickstart note, the Windows full-use attached-page route note, the validation-router attached-html quickstart note, the attached-html change-area quickstart note, the top-level attached-page quickstart note, the top-level attached-page catalog quickstart note, the top-level shortcut-first note, the suite-catalog top-level attached-page catalog quickstart note, and the suite-router attached-page quickstart note nearby when you want the written route beside these commands.'
    )
}

$helper.recommended_next_key = if ($helper.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($helper.repo_root) -or -not [string]::IsNullOrWhiteSpace($helper.summary_path)) {
    'suite_catalog_entrypoints'
} else {
    'top_level_attached_html_quickstart'
}
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($helper.recommended_next_key -eq 'suite_catalog_entrypoints') {
    'A non-default repo root or saved summary is already in play, so keep that replay state aligned through the broader issue #3 bridge before narrowing into the compact top-level attached-page quickstarts.'
} else {
    'No pinned bundle inputs, non-default repo root, or saved summary are in play yet, so jump straight from the broader validation router into the compact top-level attached-page quickstart.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 validation-router attached HTML quickstart'
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
Write-Host 'Validation-router guard:'
Write-Host (("  Surface checker:            {0}") -f $helper.commands.validation_router_attached_html_surface_check)
Write-Host ''
Write-Host 'Broader validation-router entrypoints:'
Write-Host (("  Google recommended:          {0}") -f $helper.commands.google_recommended)
Write-Host (("  Google input:                {0}") -f $helper.commands.google_input)
Write-Host (("  Attached HTML:               {0}") -f $helper.commands.attached_html)
Write-Host (("  Google attached HTML:        {0}") -f $helper.commands.google_attached_html)
Write-Host (("  Attached bundle:             {0}") -f $helper.commands.attached_bundle_target)
Write-Host (("  Attached HTML quickstart:    {0}") -f $helper.commands.attached_html_change_area_quickstart)
Write-Host (("  Attached HTML flow:          {0}") -f $helper.commands.attached_html_flow)
Write-Host ''
Write-Host 'Windows runbook bridge:'
Write-Host (("  Windows full-use route:      {0}") -f $helper.commands.windows_full_use_attached_html_route)
Write-Host ''
Write-Host 'Issue #3 bridge helpers:'
Write-Host (("  Suite catalog:               {0}") -f $helper.commands.suite_catalog_entrypoints)
Write-Host (("  Catalog handoff quickstart:  {0}") -f $helper.commands.suite_catalog_top_level_attached_html_catalog_quickstart)
Write-Host (("  Suite router quickstart:     {0}") -f $helper.commands.suite_router_quickstart)
Write-Host (("  Top-level quickstart:        {0}") -f $helper.commands.top_level_attached_html_quickstart)
Write-Host (("  Catalog quickstart:          {0}") -f $helper.commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  Top-level attached:          {0}") -f $helper.commands.top_level_attached_html_entrypoint)
Write-Host (("  Top-level shortcut:          {0}") -f $helper.commands.top_level_shortcut_first)
Write-Host (("  Router attached quick:       {0}") -f $helper.commands.suite_router_attached_html_quickstart)
Write-Host (("  Attached shortcut:           {0}") -f $helper.commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:            {0}") -f $helper.commands.replay_shortcuts)
Write-Host (("  Next-step matrix:            {0}") -f $helper.commands.suite_router_next_steps)
Write-Host (("  Bundle-first helper:         {0}") -f $helper.commands.attached_bundle_first)
Write-Host ''
Write-Host (("Windows replay note:           {0}") -f $helper.windows_replay_quickstart_note_path)
Write-Host (("Windows full-use note:         {0}") -f $helper.windows_full_use_attached_html_route_note_path)
Write-Host (("Validation-router note:        {0}") -f $helper.validation_router_attached_html_quickstart_note_path)
Write-Host (("Attached-html quickstart note: {0}") -f $helper.attached_html_change_area_quickstart_note_path)
Write-Host (("Top-level quickstart note:     {0}") -f $helper.top_level_attached_html_quickstart_note_path)
Write-Host (("Catalog quickstart note:       {0}") -f $helper.top_level_attached_html_catalog_quickstart_note_path)
Write-Host (("Top-level shortcut note:       {0}") -f $helper.top_level_shortcut_first_entrypoint_note_path)
Write-Host (("Catalog handoff note:          {0}") -f $helper.suite_catalog_top_level_attached_html_catalog_quickstart_note_path)
Write-Host (("Router-attached note:          {0}") -f $helper.suite_router_attached_html_quickstart_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}