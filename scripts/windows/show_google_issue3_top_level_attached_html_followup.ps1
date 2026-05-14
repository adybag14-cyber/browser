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
    issue = 'Google issue #3 top-level attached-html follow-up helper'
    purpose = 'Reopen the top-level attached-html route from show_headed_validation_suites.ps1 while keeping both the broader attached-page flow helper and the direct attached-page shortcut visible on one compact surface.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    attached_html_change_area_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    commands = [ordered]@{
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_html_flow = Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $emptyArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $sharedArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        top_level_shortcut_first_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $sharedArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $sharedArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $sharedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Start with attached_html_change_area when the top-level headed validation router already narrowed the replay to the generic attached localhost route and you want that branch reprinted before choosing a smaller issue #3 helper.',
        'Use attached_html_flow when you want the broader attached-page flow helper surfaced immediately from that same top-level route before dropping into the issue-specific quickstarts.',
        'Use top_level_attached_html_quickstart as the default next helper when no pinned bundle inputs or saved summary need to take precedence, because it keeps the compact top-level attached-page branch visible before you narrow again.',
        'Use top_level_attached_html_entrypoint when the replay is already clearly inside the issue-specific attached-page branch and you want the broader attached-page bridge reprinted before the shorter shortcut companion.',
        'Use top_level_shortcut_first_entrypoint when the route is already narrow enough that the shorter top-level shortcut bridge is the best next surface.',
        'Use suite_router_attached_html_quickstart or suite_catalog_attached_html_entrypoint when the suite-router-side attached-page helpers should stay visible before you narrow again.',
        'Use attached_html_shortcut when the route is already clearly inside attached-page follow-up and you want the shortest attached-page bridge before widening back into the next-step matrix or the safe-route map.',
        'Use attached_bundle_first when explicit input paths are already pinned to the known three-page compatibility bundle.',
        'Keep the quickstart and bridge notes nearby when you want the written route beside these commands.'
    )
}

$helper.recommended_next_key = if ($helper.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($helper.summary_path)) {
    'top_level_attached_html_entrypoint'
} else {
    'top_level_attached_html_quickstart'
}
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so stay on the known three-page compatibility bundle before widening back into the broader attached-page helper chain.'
} elseif ($helper.recommended_next_key -eq 'top_level_attached_html_entrypoint') {
    'A saved summary is already in play, so keep the broader attached-page bridge visible before choosing the shorter shortcut companion.'
} else {
    'No pinned bundle inputs or saved summary are in play yet, so reopen the compact top-level attached-page quickstart first while keeping the broader attached-page flow helper and direct shortcut nearby.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 top-level attached-html follow-up helper'
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
Write-Host (("  Attached HTML route:   {0}") -f $helper.commands.attached_html_change_area)
Write-Host (("  Attached flow helper:  {0}") -f $helper.commands.attached_html_flow)
Write-Host ''
Write-Host 'Issue #3 attached-page follow-up helpers:'
Write-Host (("  Top-level quickstart:     {0}") -f $helper.commands.top_level_attached_html_quickstart)
Write-Host (("  Top-level attached route: {0}") -f $helper.commands.top_level_attached_html_entrypoint)
Write-Host (("  Top-level shortcut:       {0}") -f $helper.commands.top_level_shortcut_first_entrypoint)
Write-Host (("  Suite-router quickstart:  {0}") -f $helper.commands.suite_router_attached_html_quickstart)
Write-Host (("  Catalog attached bridge:  {0}") -f $helper.commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  Attached shortcut:        {0}") -f $helper.commands.attached_html_shortcut)
Write-Host (("  Next-step matrix:         {0}") -f $helper.commands.suite_router_next_steps)
Write-Host (("  Bundle-first helper:      {0}") -f $helper.commands.attached_bundle_first)
Write-Host (("  Safe-route map:           {0}") -f $helper.commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Change-area quickstart:   {0}") -f (' ' + $helper.attached_html_change_area_quickstart_note_path))
Write-Host (("Top-level quickstart note: {0}") -f (' ' + $helper.top_level_attached_html_quickstart_note_path))
Write-Host (("Top-level bridge note:     {0}") -f (' ' + $helper.top_level_attached_html_bridge_note_path))
Write-Host (("Suite-router quickstart:   {0}") -f (' ' + $helper.suite_router_attached_html_quickstart_note_path))
Write-Host (("Catalog bridge note:       {0}") -f (' ' + $helper.suite_catalog_attached_html_bridge_note_path))
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
