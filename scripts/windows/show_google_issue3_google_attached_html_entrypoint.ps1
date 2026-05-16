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

$googleAttachedHtmlFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $googleAttachedHtmlFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $googleAttachedHtmlFlowArguments -Name InputPath -Values $InputPath

$entrypoint = [ordered]@{
    issue = 'Google issue #3 attached-html entrypoint'
    purpose = 'Keep the issue-specific attached-page route visible as the shortest bridge from the top-level headed validation suite router into the current Google attached-html surface check, validation flow, shortcut-first, context-preserving, and bundle-aware helpers.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    top_level_commands = [ordered]@{
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        google_input_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot
        google_attached_html_validation_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
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
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
    google_attached_html_entrypoint_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    notes = @(
        'Use this helper when the top-level suite router has already narrowed the replay to the issue #3 attached-page route and you want the shortest current bridge back into the narrower helper chain.',
        'Keep google_attached_html_change_area as the first top-level command when the replay should stay on the issue-specific attached-page route before any bundle paths are pinned.',
        'Use google_attached_html_surface_check when the replay is already narrowed to the issue-specific attached-page route and you want the fail-fast Google attached-html validation surface reprinted before the broader flow helper or its downstream runner handoff.',
        'Use google_attached_html_validation_flow when the broader Google-style attached-page flow helper still needs to stay visible after the fail-fast surface check and before the route narrows into the shorter issue #3 shortcut-first, replay-shortcut, context-preserving, or bundle-aware branches.',
        'Use attached_html_change_area when the next replay still needs the broader attached-page compatibility route rather than the issue-specific Google-attached path.',
        'Use attached_bundle_change_area or attached_bundle_first when the current saved or attached pages are already the known three-page compatibility bundle and that pinned branch should stay visible before widening back into the broader issue #3 helpers.',
        'Use suite_router_shortcut_entrypoint as the default next helper when no saved summary, non-default repo root, or pinned bundle inputs need to take precedence first.',
        'Use contextual_flow instead when RepoRoot or SummaryPath is already in play and the next helper surface should keep that replay context aligned while you choose between replay shortcuts, replay route, the next-step matrix, the attached bundle branch, or the safe-route helpers.',
        'Use replay_shortcuts after the shortcut entrypoint when the route is already known to stay inside issue #3 and no pinned bundle inputs or saved summary need to stay visible first.',
        'Use suite_router_next_steps when you still want the compact start-point matrix after re-entering from the issue-specific attached-page route.',
        'Keep the quickstart, suite-router bridge, suite-catalog guide, issue-specific Google attached-html entrypoint guide, Google attached-html validation-flow guide, and validation-chain notes nearby when you want the written route beside these commands.'
    )
}

$entrypoint.recommended_next_key = if ($entrypoint.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($entrypoint.repo_root) -or -not [string]::IsNullOrWhiteSpace($entrypoint.summary_path)) {
    'contextual_flow'
} else {
    'suite_router_shortcut_entrypoint'
}
$entrypoint.recommended_next_command = $entrypoint.helper_commands[$entrypoint.recommended_next_key]
$entrypoint.recommended_next_reason = if ($entrypoint.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader Google-only issue #3 helper chain.'
} elseif ($entrypoint.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing between replay shortcuts, replay route, the next-step matrix, the attached bundle branch, or the safe-route helpers.'
} else {
    'No pinned bundle inputs, saved summary, or non-default repo root are in play yet, so jump straight from the issue-specific attached-page entrypoint into the newer shortcut-first helper.'
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 attached-html entrypoint'
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
Write-Host (("  1. Google attached HTML: {0}") -f $entrypoint.top_level_commands.google_attached_html_change_area)
Write-Host (("  2. Attached HTML:        {0}") -f $entrypoint.top_level_commands.attached_html_change_area)
Write-Host (("  3. Attached bundle:      {0}") -f $entrypoint.top_level_commands.attached_bundle_change_area)
Write-Host (("  4. Google input:         {0}") -f $entrypoint.top_level_commands.google_input_change_area)
Write-Host (("  5. Google recommended:   {0}") -f $entrypoint.top_level_commands.google_recommended)
Write-Host (("  6. Google surface check: {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)
Write-Host (("  7. Google attached flow: {0}") -f $entrypoint.helper_commands.google_attached_html_validation_flow)
Write-Host (("  8. Shortcut entry:       {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host (("  9. Replay shortcuts:     {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host ((" 10. Contextual flow:      {0}") -f $entrypoint.helper_commands.contextual_flow)
Write-Host ((" 11. Next-step matrix:     {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host ((" 12. Bundle first:         {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host ''
Write-Host 'Companion helpers:'
Write-Host (("  Google surface check: {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)
Write-Host (("  Google attached flow: {0}") -f $entrypoint.helper_commands.google_attached_html_validation_flow)
Write-Host (("  Shortcut entrypoint:  {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host (("  Replay shortcuts:     {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host (("  Contextual flow:      {0}") -f $entrypoint.helper_commands.contextual_flow)
Write-Host (("  Next-step matrix:     {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host (("  Suite-catalog:        {0}") -f $entrypoint.helper_commands.suite_catalog_entrypoints)
Write-Host (("  Suite-router handoff: {0}") -f $entrypoint.helper_commands.suite_router_handoff)
Write-Host (("  Replay route:         {0}") -f $entrypoint.helper_commands.replay_route)
Write-Host (("  Bundle first:         {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host (("  Safe-route map:       {0}") -f $entrypoint.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Quickstart note:              {0}") -f $entrypoint.quickstart_note_path)
Write-Host (("Suite-router bridge:          {0}") -f $entrypoint.suite_router_bridge_note_path)
Write-Host (("Suite-catalog guide:          {0}") -f $entrypoint.suite_catalog_entrypoint_note_path)
Write-Host (("Google attached-html note:    {0}") -f $entrypoint.google_attached_html_entrypoint_note_path)
Write-Host (("Google attached-html flow:    {0}") -f $entrypoint.google_attached_html_validation_flow_note_path)
Write-Host (("Validation chain:             {0}") -f $entrypoint.validation_chain_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}
