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

$googleAttachedHtmlFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $googleAttachedHtmlFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $googleAttachedHtmlFlowArguments -Name InputPath -Values $InputPath

$bridge = [ordered]@{
    issue = 'Google issue #3 suite-catalog validation-router attached HTML bridge'
    purpose = 'Print the shortest route from the headed validation suite catalog into the validation-router attached-html quickstart while also keeping the broader attached-page flow helper, the Google-style attached-page flow helper, the Windows replay attached-html quickstart, and the narrower top-level follow-ups visible on one command surface.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    suite_catalog_entrypoints_note_path = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
    validation_router_attached_html_quickstart_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    attached_html_change_area_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    commands = [ordered]@{
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $bundleArguments
        suite_catalog_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1' -RepoRootOverride $RepoRoot
        google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        google_input_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        validation_router_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -RepoRootOverride $RepoRoot
        validation_router_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $bundleArguments
        attached_html_flow = Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments ([System.Collections.Generic.List[string]]::new())
        google_attached_html_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments
        windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments
        suite_catalog_top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
    }
    notes = @(
        'Start with suite_catalog_entrypoints or the narrower show_headed_validation_suites entrypoints when the replay is still reopening from the broader validation catalog and you want that higher-level surface visible before the attached-html route narrows again.',
        'Run suite_catalog_surface_check after branch updates or helper renames so the compact suite-catalog route fails fast before the validation-router attached-html quickstart becomes the main handoff.',
        'Use validation_router_surface_check when the replay is already pointed at the validation-router attached-html quickstart and you want missing notes, helper scripts, or downstream route surfaces caught before the shorter attached-page bridge takes over.',
        'Use attached_html_change_area_quickstart when the replay is already reopening from show_headed_validation_suites.ps1 -ChangeArea attached-html and you want the broader attached-page flow helper plus the validation-router quickstart on the same bridge.',
        'Use attached_html_flow when the route is still ambiguous and the broader attached-page localhost helper should stay visible before the validation-router quickstart or the narrower top-level attached-page notes.',
        'Use google_attached_html_flow when the current attached-page set already includes a Google-like page and you want the Google-shaped attached-page surface kept visible before the validation-router quickstart, the issue-specific Google attached-page bridge, or the narrower top-level attached-page route.',
        'Use windows_replay_attached_html_quickstart when the replay is already back on the Windows replay attached-html lane and you want that replay-side branch reprinted before the validation-router quickstart or the top-level attached-page quickstart.',
        'Use suite_catalog_top_level_attached_html_catalog_quickstart when the suite-catalog surface should stay visible a little longer while the route narrows from validation-router into the top-level attached-page catalog lane.',
        'Use top_level_attached_html_quickstart as the default next helper when there is no pinned bundle input, non-default repo root, or saved summary to preserve first.',
        'Use attached_bundle_first when explicit input paths are already pinned to the current three-page compatibility set and the replay should stay bundle-first before widening back into the broader issue #3 helper chain.'
    )
}

$bridge.recommended_next_key = if ($bridge.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} else {
    'validation_router_quickstart'
}
$bridge.recommended_next_command = $bridge.commands[$bridge.recommended_next_key]
$bridge.recommended_next_reason = if ($bridge.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so keep the replay pinned to the known attached-html compatibility bundle before widening back into the broader issue #3 helper chain.'
} else {
    'The suite-catalog route is already in view, so jump straight into the validation-router attached-html quickstart and keep the broader attached-page helpers available from the same bridge.'
}

if ($Json) {
    $bridge | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 suite-catalog validation-router attached HTML bridge'
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
Write-Host 'Suite-catalog resurfacing:'
Write-Host (("  Guide:                    {0}") -f $bridge.commands.suite_catalog_entrypoints)
Write-Host (("  Surface check:            {0}") -f $bridge.commands.suite_catalog_surface_check)
Write-Host (("  Google recommended:       {0}") -f $bridge.commands.google_recommended)
Write-Host (("  Google input:             {0}") -f $bridge.commands.google_input_change_area)
Write-Host (("  Attached HTML:            {0}") -f $bridge.commands.attached_html_change_area)
Write-Host (("  Google attached HTML:     {0}") -f $bridge.commands.google_attached_html_change_area)
Write-Host (("  Attached bundle:          {0}") -f $bridge.commands.attached_bundle_change_area)
Write-Host ''
Write-Host 'Validation-router bridge:'
Write-Host (("  Surface check:            {0}") -f $bridge.commands.validation_router_surface_check)
Write-Host (("  Validation-router quick:  {0}") -f $bridge.commands.validation_router_quickstart)
Write-Host (("  Attached quickstart:      {0}") -f $bridge.commands.attached_html_change_area_quickstart)
Write-Host (("  Attached flow:            {0}") -f $bridge.commands.attached_html_flow)
Write-Host (("  Google attached flow:     {0}") -f $bridge.commands.google_attached_html_flow)
Write-Host ''
Write-Host 'Narrower follow-ups:'
Write-Host (("  Windows replay quick:     {0}") -f $bridge.commands.windows_replay_attached_html_quickstart)
Write-Host (("  Catalog handoff quick:    {0}") -f $bridge.commands.suite_catalog_top_level_attached_html_catalog_quickstart)
Write-Host (("  Top-level quickstart:     {0}") -f $bridge.commands.top_level_attached_html_quickstart)
Write-Host (("  Top-level bridge:         {0}") -f $bridge.commands.top_level_attached_html_entrypoint)
Write-Host (("  Router attached quick:    {0}") -f $bridge.commands.suite_router_attached_html_quickstart)
Write-Host (("  Google attached bridge:   {0}") -f $bridge.commands.google_attached_html_entrypoint)
Write-Host (("  Bundle-first helper:      {0}") -f $bridge.commands.attached_bundle_first)
Write-Host ''
Write-Host (("Suite-catalog guide note:   {0}") -f $bridge.suite_catalog_entrypoints_note_path)
Write-Host (("Validation-router note:     {0}") -f $bridge.validation_router_attached_html_quickstart_note_path)
Write-Host (("Attached quickstart note:    {0}") -f $bridge.attached_html_change_area_quickstart_note_path)
Write-Host (("Google flow note:           {0}") -f $bridge.google_attached_html_validation_flow_note_path)
Write-Host (("Top-level quickstart note:  {0}") -f $bridge.top_level_attached_html_quickstart_note_path)
Write-Host (("Top-level bridge note:      {0}") -f $bridge.top_level_attached_html_bridge_note_path)
Write-Host (("Router attached note:       {0}") -f $bridge.suite_router_attached_html_quickstart_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $bridge.notes) {
    Write-Host (("- {0}") -f $note)
}
