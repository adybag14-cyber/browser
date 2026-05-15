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
        if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
            $valueList = @($value | Where-Object {
                if ($_ -is [string]) {
                    -not [string]::IsNullOrWhiteSpace($_)
                } else {
                    $null -ne $_
                }
            })
            if ($valueList.Count -eq 0) {
                continue
            }

            $command += " -$($entry.Key)"
            foreach ($item in $valueList) {
                $escapedItem = ("$item") -replace "'", "''"
                $command += " '$escapedItem'"
            }
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

$helper = [ordered]@{
    issue = 'Google issue #3 suite-catalog attached-html change-area quickstart'
    purpose = 'Print the shortest suite-catalog bridge into the current Windows full-use attached-html catalog quickstart and attached-html change-area quickstart before the route narrows into the validation-router, replay-side, top-level, shortcut, bundle-first, or safe-route helpers.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    route_commands = [ordered]@{
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $sharedArguments
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
        windows_full_use_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $sharedArguments
        validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $sharedArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $sharedArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $sharedArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $sharedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
    }
    suite_catalog_entrypoints_note_path = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
    windows_full_use_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    attached_html_change_area_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    validation_router_attached_html_quickstart_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    notes = @(
        'Use this helper when the suite-catalog surface is already open and you want the missing Windows-first catalog and attached-html change-area bridge reprinted before you narrow into smaller issue #3 helpers.',
        'Use windows_full_use_attached_html_catalog_quickstart when the broader Windows runbook or attached localhost route still matters and you want that Windows-side catalog bridge visible before the route narrows again.',
        'Use attached_html_change_area_quickstart after the Windows-side catalog quickstart, or directly from the suite-catalog surface, when the broader attached-html compatibility route should stay visible before the validation-router and replay-side quickstarts.',
        'Use validation_router_attached_html_quickstart after the change-area quickstart when the route should stay aligned with the current validation-router-side attached-html ladder before replay-side follow-up.',
        'Use windows_replay_attached_html_quickstart after the validation-router quickstart when the replay should still match the Windows replay attached-html ladder before it narrows into the top-level helpers.',
        'Use top_level_attached_html_quickstart and top_level_attached_html_catalog_quickstart when the route is already narrow enough that the compact top-level attached-page bridge should stay visible before widening again.',
        'Use suite_catalog_attached_html_entrypoint when you want the broader suite-catalog-side attached-page bridge reprinted after the newer Windows and change-area quickstarts.',
        'Use attached_bundle_change_area and attached_bundle_first when explicit InputPath values are already pinned to the known three-page compatibility bundle and that bundle-first branch should stay visible before widening back into the broader issue #3 helper chain.',
        'Use contextual_flow when RepoRoot or SummaryPath is already in play and the next helper surface should keep that replay context aligned while you choose between replay shortcuts, the bundle-first branch, or the safe-route map.',
        'Keep the suite-catalog guide, the Windows full-use attached-html catalog quickstart note, the attached-html change-area quickstart note, the validation-router quickstart note, the Windows replay attached-html quickstart note, the top-level attached-html quickstart note, the top-level attached-html catalog quickstart note, and the suite-catalog attached-html bridge note nearby when you want the written route beside these commands.'
    )
}

$helper.recommended_next_key = if ($helper.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($helper.repo_root) -or -not [string]::IsNullOrWhiteSpace($helper.summary_path)) {
    'contextual_flow'
} else {
    'attached_html_change_area_quickstart'
}
$helper.recommended_next_command = $helper.helper_commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so stay on the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($helper.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing between the newer attached-html quickstarts, replay shortcuts, the bundle-first branch, or the safe-route map.'
} else {
    'No pinned bundle inputs, non-default repo root, or saved summary are in play yet, so jump from the suite-catalog surface into the attached-html change-area quickstart while keeping the Windows-side catalog bridge and the validation-router ladder nearby.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 suite-catalog attached-html change-area quickstart'
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
Write-Host 'Suite-catalog attached-html bridge:'
Write-Host (("  1. Suite-catalog guide:        {0}") -f $helper.route_commands.suite_catalog_entrypoints)
Write-Host (("  2. Attached HTML:             {0}") -f $helper.route_commands.attached_html_change_area)
Write-Host (("  3. Google attached HTML:      {0}") -f $helper.route_commands.google_attached_html_change_area)
Write-Host (("  4. Attached bundle:           {0}") -f $helper.route_commands.attached_bundle_change_area)
Write-Host (("  5. Windows catalog quick:     {0}") -f $helper.helper_commands.windows_full_use_attached_html_catalog_quickstart)
Write-Host (("  6. Change-area quickstart:    {0}") -f $helper.helper_commands.attached_html_change_area_quickstart)
Write-Host (("  7. Validation-router quick:   {0}") -f $helper.helper_commands.validation_router_attached_html_quickstart)
Write-Host (("  8. Windows replay quick:      {0}") -f $helper.helper_commands.windows_replay_attached_html_quickstart)
Write-Host (("  9. Top-level quickstart:      {0}") -f $helper.helper_commands.top_level_attached_html_quickstart)
Write-Host ((" 10. Top-level catalog quick:   {0}") -f $helper.helper_commands.top_level_attached_html_catalog_quickstart)
Write-Host ((" 11. Catalog attached bridge:   {0}") -f $helper.helper_commands.suite_catalog_attached_html_entrypoint)
Write-Host ((" 12. Replay shortcuts:          {0}") -f $helper.helper_commands.replay_shortcuts)
Write-Host ((" 13. Contextual flow:           {0}") -f $helper.helper_commands.contextual_flow)
Write-Host ((" 14. Bundle first:              {0}") -f $helper.helper_commands.attached_bundle_first)
Write-Host ((" 15. Safe-route map:            {0}") -f $helper.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Suite-catalog guide note:     {0}") -f (' ' + $helper.suite_catalog_entrypoints_note_path))
Write-Host (("Windows catalog note:         {0}") -f (' ' + $helper.windows_full_use_attached_html_catalog_quickstart_note_path))
Write-Host (("Change-area quickstart note: {0}") -f (' ' + $helper.attached_html_change_area_quickstart_note_path))
Write-Host (("Validation-router note:      {0}") -f (' ' + $helper.validation_router_attached_html_quickstart_note_path))
Write-Host (("Windows replay note:         {0}") -f (' ' + $helper.windows_replay_attached_html_quickstart_note_path))
Write-Host (("Top-level quickstart note:   {0}") -f (' ' + $helper.top_level_attached_html_quickstart_note_path))
Write-Host (("Top-level catalog note:      {0}") -f (' ' + $helper.top_level_attached_html_catalog_quickstart_note_path))
Write-Host (("Catalog bridge note:         {0}") -f (' ' + $helper.suite_catalog_attached_html_bridge_note_path))
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
