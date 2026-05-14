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

$entrypoint = [ordered]@{
    issue = 'Google issue #3 top-level attached HTML catalog quickstart'
    purpose = 'Keep the top-level attached-page route and the suite-catalog attached-page bridge visible on one compact helper before the replay narrows into the issue-specific attached-page entrypoints, shortcuts, or bundle-first path.'
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
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
    }
    helper_commands = [ordered]@{
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
    }
    top_level_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    notes = @(
        'Use this helper when the top-level attached HTML route is already in focus but you still want the suite-catalog attached-page bridge printed immediately beside it.',
        'Use suite_catalog_attached_html_entrypoint as the default next helper when no bundle inputs, saved summary, or non-default repo root need to take precedence first, because it keeps the suite-catalog-side attached-page route visible before you decide whether to widen into the broader Google-shaped attached-page bridge, the attached-page shortcut, replay shortcuts, the next-step matrix, or the safe-route map.',
        'Use attached_bundle_first when explicit InputPath values are already pinned to the known three-page compatibility bundle and that branch should stay visible before the route widens back into the broader issue #3 helper stack.',
        'Use contextual_flow when RepoRoot or SummaryPath is already in play and the next helper surface should keep that replay context aligned while you choose between the suite-catalog attached-page bridge, the Google-shaped attached-page helper, replay shortcuts, the next-step matrix, or the safe-route map.',
        'Keep the top-level attached-page quickstart note, the suite-catalog attached-page bridge note, the validation-chain note, and the Windows runbook nearby when you want the written route beside these commands.'
    )
}

$entrypoint.recommended_next_key = if ($entrypoint.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($entrypoint.repo_root) -or -not [string]::IsNullOrWhiteSpace($entrypoint.summary_path)) {
    'contextual_flow'
} else {
    'suite_catalog_attached_html_entrypoint'
}
$entrypoint.recommended_next_command = $entrypoint.helper_commands[$entrypoint.recommended_next_key]
$entrypoint.recommended_next_reason = if ($entrypoint.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so stay on the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($entrypoint.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing between the suite-catalog attached-page bridge, replay shortcuts, the next-step matrix, or the safe-route map.'
} else {
    'No pinned bundle inputs, saved summary, or non-default repo root are in play yet, so jump straight from the top-level attached-page route to the suite-catalog attached-page bridge.'
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 top-level attached HTML catalog quickstart'
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
Write-Host 'Top-level attached-page catalog bridge:'
Write-Host (("  1. Attached HTML:         {0}") -f $entrypoint.top_level_commands.attached_html_change_area)
Write-Host (("  2. Google attached HTML:  {0}") -f $entrypoint.top_level_commands.google_attached_html_change_area)
Write-Host (("  3. Attached bundle:       {0}") -f $entrypoint.top_level_commands.attached_bundle_change_area)
Write-Host (("  4. Top-level entrypoint:  {0}") -f $entrypoint.top_level_commands.top_level_attached_html_entrypoint)
Write-Host (("  5. Top-level quickstart:  {0}") -f $entrypoint.helper_commands.top_level_attached_html_quickstart)
Write-Host (("  6. Router quickstart:     {0}") -f $entrypoint.helper_commands.suite_router_attached_html_quickstart)
Write-Host (("  7. Catalog bridge:        {0}") -f $entrypoint.helper_commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  8. Google attached route: {0}") -f $entrypoint.helper_commands.google_attached_html_entrypoint)
Write-Host (("  9. Attached shortcut:     {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host ((" 10. Replay shortcuts:      {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host ((" 11. Next-step matrix:      {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host ((" 12. Contextual flow:       {0}") -f $entrypoint.helper_commands.contextual_flow)
Write-Host ((" 13. Bundle first:          {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host ((" 14. Safe-route map:        {0}") -f $entrypoint.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Top-level quickstart note:  {0}") -f $entrypoint.top_level_quickstart_note_path)
Write-Host (("Catalog bridge note:        {0}") -f $entrypoint.suite_catalog_attached_html_bridge_note_path)
Write-Host (("Validation chain note:      {0}") -f $entrypoint.validation_chain_note_path)
Write-Host (("Windows runbook:            {0}") -f $entrypoint.windows_runbook_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}
