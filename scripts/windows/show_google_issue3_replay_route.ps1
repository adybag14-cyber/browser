[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-RepoRoot([string]$StartPath) {
    if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
        return $env:LIGHTPANDA_REPO_ROOT
    }

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor 'build.zig')) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            throw "Could not resolve the Lightpanda repo root from $StartPath. Set LIGHTPANDA_REPO_ROOT to override."
        }

        $cursor = $parent
    }
}

function ConvertTo-PowerShellSingleQuotedLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Format-ArgumentList {
    param(
        [hashtable]$Arguments = @{}
    )

    $parts = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in $Arguments.GetEnumerator()) {
        $value = $entry.Value
        if ($null -eq $value) {
            continue
        }

        if ($value -is [System.Array]) {
            $items = @($value | Where-Object { -not [string]::IsNullOrWhiteSpace("$_") })
            if ($items.Count -eq 0) {
                continue
            }

            $parts.Add("-$($entry.Key)")
            foreach ($item in $items) {
                $parts.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value "$item"))
            }
            continue
        }

        if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        $parts.Add("-$($entry.Key)")
        $parts.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value "$value"))
    }

    return $parts
}

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [hashtable]$Arguments = @{}
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\$ScriptName"
    $parts = Format-ArgumentList -Arguments $Arguments
    if ($parts.Count -gt 0) {
        $command += " " + ($parts -join ' ')
    }

    return $command
}

function Format-HelperCommandWithRepoRootEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [hashtable]$Arguments = @{},
        [string]$RepoRootOverride
    )

    if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        return Format-HelperCommand -ScriptName $ScriptName -Arguments $Arguments
    }

    $command = "& '.\scripts\windows\$ScriptName'"
    $parts = Format-ArgumentList -Arguments $Arguments
    if ($parts.Count -gt 0) {
        $command += " " + ($parts -join ' ')
    }

    $escapedRepoRoot = ("$RepoRootOverride") -replace "'", "''"
    return "powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$env:LIGHTPANDA_REPO_ROOT = '$escapedRepoRoot'; $command`""
}

$resolvedRepoRoot = if ($RepoRoot) {
    $RepoRoot
} else {
    Resolve-RepoRoot $PSScriptRoot
}
$shouldPreserveRepoRoot = $PSBoundParameters.ContainsKey('RepoRoot') -or -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)
$recommendedRepoRoot = if ($shouldPreserveRepoRoot) { $resolvedRepoRoot } else { $null }
$recommendedSummaryPath = if ($PSBoundParameters.ContainsKey('SummaryPath')) { $SummaryPath } else { $null }
$recommendedInputPath = if ($PSBoundParameters.ContainsKey('InputPath')) { $InputPath } else { @() }
$runnerPatchStatePlaceholder = '<ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>'

$route = [ordered]@{
    issue = 'Google issue #3 replay route'
    purpose = 'Bridge the higher-level headed validation catalog, the newer attached-page route, the shortcut-first suite-router entrypoint, the bounded Google flow helper, the attached three-page compatibility bundle branch, and the current safe-route replay helpers while preserving repo-root, summary-path, and pinned bundle-input context across the printed commands.'
    repo_root = $resolvedRepoRoot
    summary_path = $recommendedSummaryPath
    input_paths = $recommendedInputPath
    explicit_input_path_count = if ($recommendedInputPath) { @($recommendedInputPath).Count } else { 0 }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    replay_discovery_note_path = 'docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md'
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    read_first_suite_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
        SuiteName = 'google-recommended'
    }) -RepoRootOverride $recommendedRepoRoot
    read_first_change_area_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
        ChangeArea = 'google-input'
    }) -RepoRootOverride $recommendedRepoRoot
    attached_html_change_area_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
        ChangeArea = 'attached-html'
    }) -RepoRootOverride $recommendedRepoRoot
    suite_router_shortcut_entrypoint_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    read_first_google_flow_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $recommendedRepoRoot
    suite_catalog_entrypoints_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    suite_router_handoff_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    suite_router_next_steps_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    attached_bundle_change_area_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
        ChangeArea = 'attached-html-target-bundle'
    }) -RepoRootOverride $recommendedRepoRoot
    attached_bundle_entrypoint_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    replay_shortcuts_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    safe_route_entrypoints_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    fresh_replay_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    reuse_current_outputs_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    runner_patch_next_step_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_patch_next_step.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        State = $runnerPatchStatePlaceholder
    }) -RepoRootOverride $recommendedRepoRoot
    notes = @(
        'Start with read_first_suite_command when you want the broadest current issue #3 runner surfaced first, while preserving RepoRoot for non-default checkouts when it is already in play.'
        'Use read_first_change_area_command when the next replay may branch into a narrower title, homepage-fixture, submit-path, shared Enter-order, attached-page, or live-trace slice, without dropping the current RepoRoot context.'
        'Use attached_html_change_area_command when the next replay is already narrowed to the attached-page compatibility route and you want that top-level branch visible before deciding whether to jump into the shortcut-first helper or stay pinned to the bundle-first path.'
        'Use suite_router_shortcut_entrypoint_command when the higher-level suite router has already narrowed the route to issue #3 and you want the shortest printed bridge back into replay_shortcuts, the next-step matrix, the suite-catalog bridge, or the pinned bundle-first branch while preserving SummaryPath and InputPath context.'
        'Use read_first_google_flow_command when you want the full bounded localhost-first ladder printed before you choose a narrower replay, while keeping the same RepoRoot context as the later safe-route helpers.'
        'Use suite_catalog_entrypoints_command when you want the exact top-level suite-router entrypoints, the attached-page route, the shortcut-first suite-router entrypoint, the next-step matrix, and the current replay helpers printed together before narrowing further, while preserving SummaryPath and InputPath when they are already pinned.'
        'Use suite_router_handoff_command when you want the shortest printed bridge back into the higher-level suite-router entrypoints before reopening the narrower replay route, replay shortcuts, attached-bundle, or safe-route helpers with the same current context.'
        'Use suite_router_next_steps_command when you want the compact next-step matrix from the higher-level suite router reprinted beside the current replay-route surface without reopening the longer Windows runbook or bridge note first.'
        'If the current saved or attached pages are the known three-page compatibility bundle, use attached_bundle_change_area_command and attached_bundle_entrypoint_command before reopening the broader wrapper-heavy safe route.'
        'Use replay_shortcuts_command after the shortcut-first suite-router entrypoint or the suite-catalog bridge has already re-established the issue #3 route and you want that narrower surface kept beside the attached-page route, the bundle-aware branch, and the current safe-route bridge.'
        'Open safe_route_entrypoints_command when you are ready to choose between the fresh replay, reuse-current-outputs, refresh-status, handoff, summary-guide, and runner-wiring helpers.'
        'Use fresh_replay_command when issue #3 outputs may be stale or missing.'
        'Use reuse_current_outputs_command only when the current issue #3 outputs are already present and trusted.'
        'If the wrapper reports ready-for-runner-patch, already-direct, or runner-already-wired-regenerate-outputs, rerun runner_patch_next_step_command with that exact state while keeping the current repo-root and summary-path context attached.'
        'When LIGHTPANDA_REPO_ROOT, a saved SummaryPath, or pinned InputPath values are already guiding the replay, the emitted suite-catalog, attached-page, shortcut-entrypoint, read-first, suite-router-handoff, suite-router-next-steps, replay-shortcuts, attached-bundle, safe-route, and runner-next-step commands preserve that same context so the shortcut-first bridge can stay the default recommendation without losing the newer helper alignment.'
    )
}

$route.recommended_next_command = if ($route.explicit_input_path_count -gt 0) {
    $route.attached_bundle_entrypoint_command
} else {
    $route.suite_router_shortcut_entrypoint_command
}
$route.recommended_next_reason = if ($route.explicit_input_path_count -gt 0) {
    'Pinned input paths are already present, so stay on the attached three-page compatibility bundle branch first before widening back into the broader safe-route wrappers.'
} else {
    'No bundle inputs are pinned yet, so reopen the shortcut-first suite-router entrypoint next and let that compact bridge decide whether replay shortcuts, the next-step matrix, the suite-catalog bridge, or the attached bundle branch should be reopened from the same context.'
}

if ($Json) {
    $route | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 replay route'
Write-Host ''
Write-Host (("Repo root:   {0}") -f $route.repo_root)
Write-Host (("Summary path:{0}") -f $(if ($route.summary_path) { " $($route.summary_path)" } else { ' <default>' }))
if ($route.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $route.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next:    {0}") -f $route.recommended_next_command)
Write-Host (("Why:                 {0}") -f $route.recommended_next_reason)
Write-Host ''
Write-Host 'Read-first:'
Write-Host (("  Suite router:          {0}") -f $route.read_first_suite_command)
Write-Host (("  Change-area view:      {0}") -f $route.read_first_change_area_command)
Write-Host (("  Attached HTML route:   {0}") -f $route.attached_html_change_area_command)
Write-Host (("  Shortcut entrypoint:   {0}") -f $route.suite_router_shortcut_entrypoint_command)
Write-Host (("  Google flow helper:    {0}") -f $route.read_first_google_flow_command)
Write-Host (("  Suite-catalog bridge:  {0}") -f $route.suite_catalog_entrypoints_command)
Write-Host (("  Suite handoff:         {0}") -f $route.suite_router_handoff_command)
Write-Host (("  Next-step matrix:      {0}") -f $route.suite_router_next_steps_command)
Write-Host ''
Write-Host 'Attached-bundle branch:'
Write-Host (("  Bundle route:        {0}") -f $route.attached_bundle_change_area_command)
Write-Host (("  Bundle helper:       {0}") -f $route.attached_bundle_entrypoint_command)
Write-Host (("  Replay shortcuts:    {0}") -f $route.replay_shortcuts_command)
Write-Host ''
Write-Host 'Safe-route bridge:'
Write-Host (("  Entrypoints helper:  {0}") -f $route.safe_route_entrypoints_command)
Write-Host (("  Fresh replay:        {0}") -f $route.fresh_replay_command)
Write-Host (("  Reuse outputs:       {0}") -f $route.reuse_current_outputs_command)
Write-Host (("  Runner next step:    {0}") -f $route.runner_patch_next_step_command)
Write-Host ''
Write-Host 'Notes:'
Write-Host (("  Quickstart note:     {0}") -f $route.quickstart_note_path)
Write-Host (("  Replay discovery:    {0}") -f $route.replay_discovery_note_path)
Write-Host (("  Windows runbook:     {0}") -f $route.windows_runbook_note_path)
Write-Host (("  Suite-router bridge: {0}") -f $route.suite_router_bridge_note_path)
Write-Host (("  Validation chain:    {0}") -f $route.validation_chain_note_path)
Write-Host ''
Write-Host 'Guidance:'
foreach ($note in $route.notes) {
    Write-Host (("- {0}") -f $note)
}
