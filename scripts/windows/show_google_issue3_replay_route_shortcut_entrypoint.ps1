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

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$entrypoint = [ordered]@{
    issue = 'Google issue #3 replay-route shortcut entrypoint'
    purpose = 'Print the shortest replay-route follow-up from the headed validation suite router into the attached-page shortcut, replay shortcuts, pinned bundle route, and current safe-route helpers while preserving repo-root, saved-summary, and pinned bundle-input context when it is already in play.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    top_level_commands = [ordered]@{
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
    }
    helper_commands = [ordered]@{
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
        fresh_safe_route_replay = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments $sharedArguments
        reuse_current_outputs = Format-HelperCommand -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments $sharedArguments
    }
    replay_discovery_note_path = 'docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    notes = @(
        'Start with replay_route when the broader replay helper has already narrowed the current route and you now want the shortest attached-page and replay-shortcuts follow-up surfaced on one smaller command surface.',
        'Use attached_html_change_area when you want the top-level attached-page route reprinted before you drop into the shorter attached-page shortcut or bundle-first branch.',
        'Use attached_bundle_change_area when the current saved or attached pages are still the known three-page compatibility bundle and the replay should stay pinned to that route first.',
        'Use attached_html_shortcut as the default next helper whenever no explicit bundle inputs are already pinned, because it keeps the attached-page bridge visible before reopening replay_shortcuts, the next-step matrix, contextual_flow, or the safe-route map.',
        'Use suite_router_shortcut_entrypoint when you want the broader issue #3 shortcut-first bridge reprinted again before narrowing back into replay_shortcuts or the attached-page branch.',
        'Use replay_shortcuts after the attached_html_shortcut helper when the route is already clearly inside issue #3 and you want the narrower compact helper surface kept beside the attached bundle and safe-route follow-up commands.',
        'Use suite_router_next_steps when you want the compact start-point matrix reprinted again after the replay-route shortcut bridge so you can choose between replay_route, contextual_flow, the bundle-first branch, or the runner-state follow-up.',
        'Use contextual_flow when RepoRoot, SummaryPath, or fixed InputPath values already matter and you want the next helper surface to keep that context aligned before narrowing further.',
        'Use attached_bundle_first whenever explicit InputPath values are already pinned or when the replay should stay on the known three-page compatibility set before widening back into the broader Google-only issue #3 helpers.',
        'Use safe_route_entrypoints only after the attached-page and replay-shortcuts surfaces have already clarified that the route should reopen the wrapper-heavy issue #3 chain from the same SummaryPath and InputPath state.',
        'Use fresh_safe_route_replay when current outputs may be stale or missing. Use reuse_current_outputs only when a saved SummaryPath already exists and those outputs are still trusted.',
        'Keep the replay-discovery, suite-router bridge, suite-catalog guide, validation-chain, and Windows runbook notes nearby when you want the written route beside these commands.'
    )
}

$entrypoint.recommended_next_helper_key = if ($entrypoint.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($entrypoint.repo_root) -or -not [string]::IsNullOrWhiteSpace($entrypoint.summary_path)) {
    'contextual_flow'
} else {
    'attached_html_shortcut'
}
$entrypoint.recommended_next_helper_command = $entrypoint.helper_commands[$entrypoint.recommended_next_helper_key]
$entrypoint.recommended_next_helper_reason = if ($entrypoint.recommended_next_helper_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so stay on the bundle-first branch before widening back into the broader Google-only issue #3 route.'
} elseif ($entrypoint.recommended_next_helper_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so reopen the context-preserving helper next and keep that replay state aligned before choosing between the attached-page shortcut, replay shortcuts, the next-step matrix, or the safe-route branch.'
} else {
    'No explicit bundle inputs, non-default repo root, or saved summary are already pinned, so jump straight from replay-route into the smaller attached-page shortcut helper and keep the shorter issue #3 bridge visible from there.'
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 replay-route shortcut entrypoint'
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
Write-Host (("Recommended next helper: {0}") -f $entrypoint.recommended_next_helper_command)
Write-Host (("Why:                    {0}") -f $entrypoint.recommended_next_helper_reason)
Write-Host ''
Write-Host 'Replay-route bridge:'
Write-Host (("  1. Replay route:      {0}") -f $entrypoint.top_level_commands.replay_route)
Write-Host (("  2. Attached HTML:     {0}") -f $entrypoint.top_level_commands.attached_html_change_area)
Write-Host (("  3. Attached bundle:   {0}") -f $entrypoint.top_level_commands.attached_bundle_change_area)
Write-Host (("  4. Attached shortcut: {0}") -f $entrypoint.top_level_commands.attached_html_shortcut)
Write-Host (("  5. Shortcut helper:   {0}") -f $entrypoint.top_level_commands.suite_router_shortcut_entrypoint)
Write-Host (("  6. Replay shortcuts:  {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host (("  7. Next-step matrix:  {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host (("  8. Contextual flow:   {0}") -f $entrypoint.helper_commands.contextual_flow)
Write-Host ''
Write-Host 'Companion helpers:'
Write-Host (("  Attached shortcut:    {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:     {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host (("  Next-step matrix:     {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host (("  Contextual flow:      {0}") -f $entrypoint.helper_commands.contextual_flow)
Write-Host (("  Bundle first:         {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host (("  Safe-route map:       {0}") -f $entrypoint.helper_commands.safe_route_entrypoints)
Write-Host (("  Fresh safe replay:    {0}") -f $entrypoint.helper_commands.fresh_safe_route_replay)
Write-Host (("  Reuse current outputs:{0}") -f (' ' + $entrypoint.helper_commands.reuse_current_outputs))
Write-Host ''
Write-Host (("Replay discovery:      {0}") -f $entrypoint.replay_discovery_note_path)
Write-Host (("Suite-router bridge:   {0}") -f $entrypoint.suite_router_bridge_note_path)
Write-Host (("Suite-catalog guide:   {0}") -f $entrypoint.suite_catalog_entrypoint_note_path)
Write-Host (("Validation chain:      {0}") -f $entrypoint.validation_chain_note_path)
Write-Host (("Windows runbook:       {0}") -f $entrypoint.windows_runbook_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}
