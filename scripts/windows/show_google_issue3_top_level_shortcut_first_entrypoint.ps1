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
    issue = 'Google issue #3 top-level shortcut-first entrypoint'
    purpose = 'Print the shortest top-level route from the headed validation suite catalog into the newer issue #3 suite-router shortcut entrypoint, while also surfacing the attached-page compatibility branch and preserving repo-root, saved-summary, and pinned bundle-input context when it is already in play.'
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
        google_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $bundleArguments
        suite_router_handoff = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
    }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    replay_discovery_note_path = 'docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    notes = @(
        'Use this helper when the top-level headed validation suite catalog has already narrowed the route to issue #3 and you want the shortcut-first path printed without reopening the broader suite-catalog or replay-route surfaces first.',
        'Start with google_recommended when you want the broader localhost-first issue #3 runner named before the route narrows into the shortcut-first entrypoint.',
        'Start with google_input_change_area when the next replay is already known to stay inside issue #3 and you want the same top-level helper family reprinted before dropping into the suite-router shortcut entrypoint.',
        'Start with attached_html_change_area when the next replay should still come from the generic attached-page compatibility route before you jump into the shortcut-first issue #3 bridge.',
        'Start with google_attached_html_change_area when the next replay should still come from the Google-shaped attached-page route before you jump into the shorter issue #3 helper chain.',
        'Start with attached_bundle_change_area when the current saved or attached pages are still the known three-page compatibility bundle and you want that pinned branch reprinted from the top-level suite router first.',
        'Use suite_router_shortcut_entrypoint as the default next helper whenever no pinned bundle inputs need to take precedence, because it keeps the shortest bridge from the top-level suite catalog into replay_shortcuts, attached_html_shortcut, contextual_flow, the next-step matrix, and the broader compact helpers.',
        'Use attached_html_shortcut when the replay is already narrowed to attached-page follow-up and you want the broader attached-page compatibility branch kept visible before you widen back into replay_shortcuts, the next-step matrix, or the safe-route map.',
        'Use attached_bundle_first instead when explicit InputPath values are already pinned and the replay should stay on the known three-page compatibility set before widening back into the broader Google-only helpers.',
        'Use replay_shortcuts after the suite-router shortcut entrypoint when the route is already known to stay inside issue #3 and no saved summary, repo-root override, or pinned bundle inputs need to stay visible first.',
        'Keep the quickstart, replay-discovery, suite-router bridge, suite-catalog guide, and validation-chain notes nearby when you want the written route beside these commands.'
    )
}

$entrypoint.recommended_next_key = if ($entrypoint.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} else {
    'suite_router_shortcut_entrypoint'
}
$entrypoint.recommended_next_command = $entrypoint.helper_commands[$entrypoint.recommended_next_key]
$entrypoint.recommended_next_reason = if ($entrypoint.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader Google-only issue #3 path.'
} else {
    'No pinned bundle inputs are in play yet, so jump straight from the top-level suite router into the newer suite-router shortcut entrypoint and keep the narrower replay helpers visible from there.'
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 top-level shortcut-first entrypoint'
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
Write-Host 'Top-level suite-router bridge:'
Write-Host (("  1. Google recommended:    {0}") -f $entrypoint.top_level_commands.google_recommended)
Write-Host (("  2. Google input:          {0}") -f $entrypoint.top_level_commands.google_input_change_area)
Write-Host (("  3. Attached HTML:         {0}") -f $entrypoint.top_level_commands.attached_html_change_area)
Write-Host (("  4. Google attached HTML:  {0}") -f $entrypoint.top_level_commands.google_attached_html_change_area)
Write-Host (("  5. Attached bundle:       {0}") -f $entrypoint.top_level_commands.attached_bundle_change_area)
Write-Host (("  6. Google flow:           {0}") -f $entrypoint.top_level_commands.google_flow)
Write-Host (("  7. Shortcut entry:        {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host (("  8. Attached shortcut:     {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host (("  9. Replay shortcuts:      {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host ((" 10. Next-step matrix:      {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host ((" 11. Suite-catalog:         {0}") -f $entrypoint.helper_commands.suite_catalog_entrypoints)
Write-Host ''
Write-Host 'Companion helpers:'
Write-Host (("  Shortcut entrypoint: {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host (("  Attached shortcut:   {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:    {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host (("  Contextual flow:     {0}") -f $entrypoint.helper_commands.contextual_flow)
Write-Host (("  Next-step matrix:    {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host (("  Suite-catalog:       {0}") -f $entrypoint.helper_commands.suite_catalog_entrypoints)
Write-Host (("  Suite-router handoff:{0}") -f (' ' + $entrypoint.helper_commands.suite_router_handoff))
Write-Host (("  Replay route:        {0}") -f $entrypoint.helper_commands.replay_route)
Write-Host (("  Bundle first:        {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host (("  Safe-route map:      {0}") -f $entrypoint.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Quickstart note:      {0}") -f $entrypoint.quickstart_note_path)
Write-Host (("Replay discovery:     {0}") -f $entrypoint.replay_discovery_note_path)
Write-Host (("Suite-router bridge:  {0}") -f $entrypoint.suite_router_bridge_note_path)
Write-Host (("Suite-catalog guide:  {0}") -f $entrypoint.suite_catalog_entrypoint_note_path)
Write-Host (("Validation chain:     {0}") -f $entrypoint.validation_chain_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}
