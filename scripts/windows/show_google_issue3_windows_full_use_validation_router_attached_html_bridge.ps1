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

    $command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\$ScriptName"
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

    $command = "& '.\scripts\windows\$ScriptName'"
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

$googleAttachedHtmlFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $googleAttachedHtmlFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $googleAttachedHtmlFlowArguments -Name InputPath -Values $InputPath

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$helper = [ordered]@{
    issue = 'Google issue #3 Windows full-use validation-router attached HTML bridge'
    purpose = 'Print the shortest bridge from the Windows full-use attached-page route into the validation-router attached-html quickstart, while keeping the attached-html change-area route, the broader attached-page flow helper, the dedicated Google attached-page flow helper, the top-level attached-page quickstarts, the suite-router attached-page quickstart, and the replay shortcuts visible for the next narrow replay step.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    bridge_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md'
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    validation_router_attached_html_quickstart_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    attached_html_change_area_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    commands = [ordered]@{
        windows_full_use_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -RepoRootOverride $RepoRoot
        validation_router_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -RepoRootOverride $RepoRoot
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $bundleArguments
        validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $bundleArguments
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
    }
    notes = @(
        'Use this helper when docs/WINDOWS_FULL_USE.md or the Windows full-use attached-page route note already made attached localhost follow-up the next obvious branch and you want the validation-router attached-html quickstart reprinted before the route narrows again.',
        'Run windows_full_use_surface_check and validation_router_surface_check after branch moves or before trusting this bridge from another checkout, because they fail fast on missing notes, helper scripts, or downstream attached-page route surfaces.',
        'Use attached_html_change_area immediately after the Windows full-use route when you still want the main validation catalog to reprint the attached-html branch before the issue-specific helpers.',
        'Use validation_router_attached_html_quickstart as the default next helper when no pinned bundle inputs, saved summary, or repo-root override need to take precedence, because it keeps the broader validation-router attached-page bridge visible before the route drops back into the smaller attached-page quickstarts.',
        'Use attached_html_change_area_quickstart after the validation-router quickstart when you want the shorter change-area bridge and the compact top-level attached-page route kept visible together.',
        'Use attached_html_flow when the broader attached-page localhost flow should stay visible after the shorter change-area quickstart and explicit InputPath values should keep the same pinned page set instead of reopening auto-discovery.',
        'Use google_attached_html_flow when the dedicated Google-shaped attached-page flow helper should stay visible before the route drops from the validation-router bridge into the smaller top-level attached-page quickstarts.',
        'Use top_level_attached_html_quickstart when the route is already ready to stay on the shortest top-level attached-page bridge before narrowing again.',
        'Use top_level_attached_html_catalog_quickstart when you want the compact top-level attached-page route plus the suite-catalog-side attached-page bridge preserved before the route narrows again.',
        'Use suite_router_attached_html_quickstart when the next replay should stay closer to the suite-router side of the attached-page helper chain before dropping into the shorter attached-page shortcut or replay shortcuts.',
        'Use attached_html_shortcut or replay_shortcuts only after the attached-page bridge is already narrow enough that the replay should stay inside the tighter issue #3 helper chain.',
        'Use attached_bundle_change_area and attached_bundle_first when explicit InputPath values are already pinned to the known three-page compatibility bundle and that branch should stay visible before widening again.',
        'Use contextual_flow when RepoRoot, SummaryPath, or explicit InputPath values already matter and the next helper surface should keep that replay state aligned before the route narrows again.'
    )
}

$helper.recommended_next_key = if ($helper.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($helper.repo_root) -or -not [string]::IsNullOrWhiteSpace($helper.summary_path)) {
    'contextual_flow'
} else {
    'validation_router_attached_html_quickstart'
}
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($helper.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay state aligned before choosing whether to reopen the validation-router quickstart, the change-area quickstart, the broader attached-page flow helper, the dedicated Google attached-page flow helper, the compact top-level attached-page route, or the replay shortcuts.'
} else {
    'No pinned bundle inputs, non-default repo root, or saved summary are in play yet, so jump straight from the Windows full-use route into the validation-router attached-html quickstart before narrowing again.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 Windows full-use validation-router attached HTML bridge'
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
Write-Host 'Bridge guards:'
Write-Host (("  Windows full-use surface:  {0}") -f $helper.commands.windows_full_use_surface_check)
Write-Host (("  Validation-router surface: {0}") -f $helper.commands.validation_router_surface_check)
Write-Host ''
Write-Host 'Windows-to-validation route:'
Write-Host (("  1. Windows route:          {0}") -f $helper.commands.windows_full_use_attached_html_route)
Write-Host (("  2. Attached HTML route:    {0}") -f $helper.commands.attached_html_change_area)
Write-Host (("  3. Validation quickstart:  {0}") -f $helper.commands.validation_router_attached_html_quickstart)
Write-Host (("  4. Change-area quickstart: {0}") -f $helper.commands.attached_html_change_area_quickstart)
Write-Host (("  5. Attached flow helper:   {0}") -f $helper.commands.attached_html_flow)
Write-Host (("  6. Google attached flow:   {0}") -f $helper.commands.google_attached_html_flow)
Write-Host (("  7. Top-level quickstart:   {0}") -f $helper.commands.top_level_attached_html_quickstart)
Write-Host (("  8. Catalog quickstart:     {0}") -f $helper.commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  9. Router quickstart:      {0}") -f $helper.commands.suite_router_attached_html_quickstart)
Write-Host ((" 10. Attached shortcut:      {0}") -f $helper.commands.attached_html_shortcut)
Write-Host ((" 11. Replay shortcuts:       {0}") -f $helper.commands.replay_shortcuts)
Write-Host ''
Write-Host 'Context-preserving follow-up:'
Write-Host (("  Contextual flow:           {0}") -f $helper.commands.contextual_flow)
Write-Host (("  Bundle change-area:        {0}") -f $helper.commands.attached_bundle_change_area)
Write-Host (("  Bundle-first helper:       {0}") -f $helper.commands.attached_bundle_first)
Write-Host ''
Write-Host (("Bridge note:                {0}") -f (' ' + $helper.bridge_note_path))
Write-Host (("Windows full-use note:      {0}") -f (' ' + $helper.windows_full_use_attached_html_route_note_path))
Write-Host (("Validation quickstart note: {0}") -f (' ' + $helper.validation_router_attached_html_quickstart_note_path))
Write-Host (("Change-area quickstart:     {0}") -f (' ' + $helper.attached_html_change_area_quickstart_note_path))
Write-Host (("Google attached flow note:  {0}") -f (' ' + $helper.google_attached_html_validation_flow_note_path))
Write-Host (("Top-level quickstart note:  {0}") -f (' ' + $helper.top_level_attached_html_quickstart_note_path))
Write-Host (("Suite-router quickstart:    {0}") -f (' ' + $helper.suite_router_attached_html_quickstart_note_path))
Write-Host (("Windows replay quickstart:  {0}") -f (' ' + $helper.windows_replay_quickstart_note_path))

Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
