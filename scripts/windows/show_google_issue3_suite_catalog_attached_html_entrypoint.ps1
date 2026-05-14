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
        [string[]]$Switches = @(),
        [System.Collections.Generic.List[string]]$Arguments
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
    issue = 'Google issue #3 suite-catalog attached-html entrypoint'
    purpose = 'Keep the attached-page follow-up route visible directly from the issue #3 suite-catalog surface before it narrows into the current shortcut-first, issue-specific attached-page, and bundle-aware helpers.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    top_level_commands = [ordered]@{
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
    }
    helper_commands = [ordered]@{
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $bundleArguments
        top_level_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
    }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    notes = @(
        'Use this helper when the issue #3 suite-catalog surface already has your attention and the next replay needs the attached-page route kept visible before you drop into the narrower shortcut-first helper chain.',
        'Start with attached_html_change_area when the next replay should still come from the broader attached-page compatibility route before it narrows into issue-specific attached-page follow-up.',
        'Start with google_attached_html_change_area when the next replay is already narrowed to the issue-specific attached-page route but the broader suite-catalog commands still need to stay visible on the same surface.',
        'Use google_attached_html_entrypoint as the default next helper when explicit InputPath values are not already pinned, because it keeps the issue-specific attached-page bridge visible before you decide whether to drop into the shorter attached_html_shortcut helper or widen back into replay_shortcuts and the next-step matrix.',
        'Use attached_html_shortcut after the issue-specific attached-page entrypoint when you want the shortest bridge into replay_shortcuts, the next-step matrix, or the bundle-first branch.',
        'Use attached_bundle_change_area or attached_bundle_first when the current saved or attached pages are already the known three-page compatibility bundle and that pinned branch should stay visible before widening back into the broader Google-only issue #3 helpers.',
        'Use top_level_shortcut_entrypoint when the broader top-level issue #3 bridge still needs to stay visible before you narrow into the attached-page helper chain.',
        'Use suite_router_shortcut_entrypoint after the attached-page helper chain when the route is already known to stay inside issue #3 and no extra suite-catalog explanation is needed first.',
        'Use contextual_flow instead when RepoRoot or SummaryPath is already in play and the next helper surface should keep that replay context aligned while you choose between replay shortcuts, the next-step matrix, or the bundle-first branch.',
        'Keep the quickstart note, the suite-router attached-page quickstart note, the suite-router bridge note, the suite-catalog attached-page bridge note, the suite-catalog guide, and the validation-chain note nearby when you want the written route beside these commands.'
    )
}

$entrypoint.recommended_next_key = if ($entrypoint.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} else {
    'google_attached_html_entrypoint'
}
$entrypoint.recommended_next_command = $entrypoint.helper_commands[$entrypoint.recommended_next_key]
$entrypoint.recommended_next_reason = if ($entrypoint.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader Google-only issue #3 helper chain.'
} else {
    'No explicit bundle inputs are pinned yet, so jump straight from the suite-catalog attached-page surface into the issue-specific attached-page entrypoint and keep the narrower helper chain visible from there.'
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 suite-catalog attached-html entrypoint'
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
Write-Host 'Suite-catalog attached-page bridge:'
Write-Host (("  1. Google recommended:   {0}") -f $entrypoint.top_level_commands.google_recommended)
Write-Host (("  2. Google input:         {0}") -f $entrypoint.top_level_commands.google_input_change_area)
Write-Host (("  3. Attached HTML:        {0}") -f $entrypoint.top_level_commands.attached_html_change_area)
Write-Host (("  4. Google attached HTML: {0}") -f $entrypoint.top_level_commands.google_attached_html_change_area)
Write-Host (("  5. Attached bundle:      {0}") -f $entrypoint.top_level_commands.attached_bundle_change_area)
Write-Host (("  6. Suite-catalog:        {0}") -f $entrypoint.helper_commands.suite_catalog_entrypoints)
Write-Host (("  7. Top-level shortcut:   {0}") -f $entrypoint.helper_commands.top_level_shortcut_entrypoint)
Write-Host (("  8. Google attached:      {0}") -f $entrypoint.helper_commands.google_attached_html_entrypoint)
Write-Host (("  9. Attached shortcut:    {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host ((" 10. Router shortcut:      {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host ((" 11. Replay shortcuts:     {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host ((" 12. Next-step matrix:     {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host ((" 13. Contextual flow:      {0}") -f $entrypoint.helper_commands.contextual_flow)
Write-Host ((" 14. Bundle first:         {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host ''
Write-Host 'Companion helpers:'
Write-Host (("  Suite-catalog:       {0}") -f $entrypoint.helper_commands.suite_catalog_entrypoints)
Write-Host (("  Top-level shortcut:  {0}") -f $entrypoint.helper_commands.top_level_shortcut_entrypoint)
Write-Host (("  Google attached:     {0}") -f $entrypoint.helper_commands.google_attached_html_entrypoint)
Write-Host (("  Attached shortcut:   {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host (("  Router shortcut:     {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host (("  Replay shortcuts:    {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host (("  Next-step matrix:    {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host (("  Contextual flow:     {0}") -f $entrypoint.helper_commands.contextual_flow)
Write-Host (("  Bundle first:        {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host ''
Write-Host (("Quickstart note:           {0}") -f $entrypoint.quickstart_note_path)
Write-Host (("Router attached quickstart:{0}") -f (' ' + $entrypoint.suite_router_attached_html_quickstart_note_path))
Write-Host (("Suite-router bridge:       {0}") -f $entrypoint.suite_router_bridge_note_path)
Write-Host (("Catalog attached bridge:   {0}") -f $entrypoint.suite_catalog_attached_html_bridge_note_path)
Write-Host (("Suite-catalog guide:       {0}") -f $entrypoint.suite_catalog_entrypoint_note_path)
Write-Host (("Validation chain:          {0}") -f $entrypoint.validation_chain_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}
