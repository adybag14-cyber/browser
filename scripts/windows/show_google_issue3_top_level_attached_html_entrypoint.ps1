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
    issue = 'Google issue #3 top-level attached HTML entrypoint'
    purpose = 'Print the top-level attached-page bridge from the headed validation suite router into the current issue #3 helper chain, while keeping the broader attached-page route, the narrower attached-page shortcut, and the pinned bundle branch visible on one compact surface.'
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
        top_level_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
    }
    helper_commands = [ordered]@{
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $bundleArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
    }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    notes = @(
        'Use this helper when show_headed_validation_suites.ps1 -ChangeArea attached-html has already identified the broader attached-page route and you want the next issue #3 bridge chosen quickly without reopening the longer Windows runbook first.',
        'Start with attached_html_change_area when the next replay should still come from the broader attached-page compatibility route before you decide whether to stay on the pinned bundle branch or narrow into the issue-specific attached-page helpers.',
        'Start with google_attached_html_change_area when the replay is already narrowed to the issue-specific attached-page route but you still want the higher-level attached-page entry surface kept visible beside it.',
        'Start with attached_bundle_change_area when the current saved or attached pages are still the known three-page compatibility bundle and that pinned branch should stay visible before widening back into the broader Google-only issue #3 path.',
        'Use attached_html_shortcut as the default next helper when no explicit bundle inputs are already pinned, because it keeps the shorter attached-page issue #3 bridge visible before you choose between replay_shortcuts, the next-step matrix, or the broader suite-router shortcut helper.',
        'Use suite_catalog_attached_html_entrypoint when RepoRoot or SummaryPath already matters and you want the attached-page route preserved together with the suite-catalog bridge before narrowing further.',
        'Use suite_catalog_entrypoints or top_level_shortcut_entrypoint when the broader issue #3 helper family still needs to stay visible before the route narrows back into the attached-page shortcut chain.',
        'Use attached_bundle_first when explicit InputPath values are already pinned and the replay should stay on the known three-page compatibility set before widening back into the broader Google-only helpers.',
        'Use safe_route_entrypoints only after the attached-page route has already narrowed into the wrapper-heavy issue #3 branch and you want the current safe-route map printed before the next replay or reuse-current-outputs step.',
        'Keep the quickstart, suite-router bridge, suite-catalog guide, and validation-chain notes nearby when you want the written route beside these commands.'
    )
}

$entrypoint.recommended_next_key = if ($entrypoint.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($entrypoint.repo_root) -or -not [string]::IsNullOrWhiteSpace($entrypoint.summary_path)) {
    'suite_catalog_attached_html_entrypoint'
} else {
    'attached_html_shortcut'
}
$entrypoint.recommended_next_command = $entrypoint.helper_commands[$entrypoint.recommended_next_key]
$entrypoint.recommended_next_reason = if ($entrypoint.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so stay on the known three-page compatibility bundle before widening back into the broader Google-only issue #3 route.'
} elseif ($entrypoint.recommended_next_key -eq 'suite_catalog_attached_html_entrypoint') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned together with the suite-catalog bridge before narrowing again.'
} else {
    'No explicit bundle inputs, saved summary, or repo-root override are in play yet, so jump straight from the broader attached-page route into the shorter attached-page issue #3 bridge.'
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 top-level attached HTML entrypoint'
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
Write-Host 'Top-level attached-page bridge:'
Write-Host (("  1. Attached HTML:        {0}") -f $entrypoint.top_level_commands.attached_html_change_area)
Write-Host (("  2. Google attached HTML: {0}") -f $entrypoint.top_level_commands.google_attached_html_change_area)
Write-Host (("  3. Attached bundle:      {0}") -f $entrypoint.top_level_commands.attached_bundle_change_area)
Write-Host (("  4. Top-level shortcut:   {0}") -f $entrypoint.top_level_commands.top_level_shortcut_entrypoint)
Write-Host (("  5. Suite-catalog bridge: {0}") -f $entrypoint.helper_commands.suite_catalog_entrypoints)
Write-Host (("  6. Attached catalog:     {0}") -f $entrypoint.helper_commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  7. Attached shortcut:    {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host (("  8. Router shortcut:      {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host (("  9. Replay shortcuts:     {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host ((" 10. Next-step matrix:     {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host ((" 11. Bundle first:         {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host ''
Write-Host 'Companion helpers:'
Write-Host (("  Suite-catalog bridge: {0}") -f $entrypoint.helper_commands.suite_catalog_entrypoints)
Write-Host (("  Attached catalog:     {0}") -f $entrypoint.helper_commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  Attached shortcut:    {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host (("  Router shortcut:      {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host (("  Replay shortcuts:     {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host (("  Next-step matrix:     {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host (("  Bundle first:         {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host (("  Safe-route map:       {0}") -f $entrypoint.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Quickstart note:      {0}") -f $entrypoint.quickstart_note_path)
Write-Host (("Suite-router bridge:  {0}") -f $entrypoint.suite_router_bridge_note_path)
Write-Host (("Suite-catalog guide:  {0}") -f $entrypoint.suite_catalog_entrypoint_note_path)
Write-Host (("Validation chain:     {0}") -f $entrypoint.validation_chain_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}
