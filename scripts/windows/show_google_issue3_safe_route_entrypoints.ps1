[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
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

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [hashtable]$Arguments = @{},
        [string[]]$Switches = @()
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\$ScriptName"
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

        $command += (" -{0}" -f $switchName)
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
        return Format-HelperCommand -ScriptName $ScriptName -Arguments $Arguments -Switches $Switches
    }

    $command = "& '.\scripts\windows\$ScriptName'"
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

        $command += (" -{0}" -f $switchName)
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
$recommendedRepoRoot = if ($shouldPreserveRepoRoot) {
    $resolvedRepoRoot
} else {
    $null
}
$recommendedSummaryPath = if ($PSBoundParameters.ContainsKey('SummaryPath')) {
    $SummaryPath
} else {
    $null
}
$readFirstSuiteCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
    SuiteName = 'google-recommended'
}) -RepoRootOverride $recommendedRepoRoot
$readFirstChangeAreaCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
    ChangeArea = 'google-input'
}) -RepoRootOverride $recommendedRepoRoot
$readFirstGoogleFlowCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $recommendedRepoRoot
$suiteRouterHandoffCommand = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    SummaryPath = $recommendedSummaryPath
})
$suiteRouterNextStepsCommand = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    SummaryPath = $recommendedSummaryPath
})
$replayRouteCommand = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    SummaryPath = $recommendedSummaryPath
})
$replayShortcutsCommand = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    SummaryPath = $recommendedSummaryPath
})
$attachedBundleSuiteCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
    ChangeArea = 'attached-html-target-bundle'
}) -RepoRootOverride $recommendedRepoRoot
$attachedBundleFirstEntrypointCommand = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    SummaryPath = $recommendedSummaryPath
})
$attachedBundleFlowCommand = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
})
$attachedBundleRunnerCommand = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
}) -Switches @('Wait')
$runnerPatchNextStepCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_patch_next_step.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
    State = '<ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>'
}) -RepoRootOverride $recommendedRepoRoot

$entrypoints = [ordered]@{
    issue = 'Google issue #3 safe-route entrypoints'
    purpose = 'Keep the current issue #3 Windows replay on the newest safe-route helper first, while preserving repo-root and summary-path context for non-default checkouts and surfacing the suite-router handoff helper, suite-router next-step matrix, replay-route helper, and the one-command attached-bundle-first helper beside the same replay root when applicable.'
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    runner_patch_decision_table_path = 'docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md'
    runner_patch_next_step_helper_command = $runnerPatchNextStepCommand
    read_first_suite_command = $readFirstSuiteCommand
    read_first_change_area_command = $readFirstChangeAreaCommand
    read_first_google_flow_command = $readFirstGoogleFlowCommand
    suite_router_handoff_command = $suiteRouterHandoffCommand
    suite_router_next_steps_command = $suiteRouterNextStepsCommand
    replay_route_command = $replayRouteCommand
    replay_shortcuts_command = $replayShortcutsCommand
    attached_bundle_suite_command = $attachedBundleSuiteCommand
    attached_bundle_first_entrypoint_command = $attachedBundleFirstEntrypointCommand
    attached_bundle_flow_command = $attachedBundleFlowCommand
    attached_bundle_runner_command = $attachedBundleRunnerCommand
    repo_root = $resolvedRepoRoot
    summary_path = $recommendedSummaryPath
    fresh_replay_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    reuse_current_outputs_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    refresh_status_route_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_refresh_status_safe_path_route.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    handoff_safe_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_handoff_safe.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    summary_guide_safe_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_summary_guide_safe.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    runner_wiring_safe_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_output_wiring_status_safe.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    notes = @(
        'Use read_first_suite_command when re-entering issue #3 from the top-level headed validation suite catalog and you want the broader localhost-first runner surfaced quickly, with RepoRoot carried through for non-default checkouts.'
        'Use read_first_change_area_command when the next replay may need one of the narrower Google title, homepage-fixture, submit-path, submit-timing, shared Enter-order, attached-page, or live-trace slices instead of the broader recommended runner, while preserving RepoRoot when set.'
        'Use read_first_google_flow_command when you want the broader bounded Google flow printed before deciding whether to stay on the safe-route entrypoints or drop to another narrower helper, without losing the selected RepoRoot context.'
        'Use suite_router_handoff_command when you want the suite-router read-first commands plus the current replay-shortcuts, bundle-first, and safe-route-map helpers surfaced together before deciding whether the next replay should stay broad or narrow, while preserving RepoRoot and SummaryPath when set.'
        'Use suite_router_next_steps_command when you want the compact matrix that maps the higher-level suite-router entrypoints to the right current issue #3 helper without reopening the longer chain notes first.'
        'Use replay_route_command when issue #3 context is already confirmed and you want the tighter route that keeps the attached-bundle branch, replay-shortcuts helper, and safe-route entrypoints together before dropping into the wrapper-heavy path.'
        'Use replay_shortcuts_command when you want the broader discovery route, the attached three-page bundle branch, and the current safe-route shortcuts surfaced together in one compact helper before choosing whether to stay broad or narrow next.'
        'Use attached_bundle_suite_command when the next replay should stay pinned to the current attached three-page compatibility bundle instead of the broader Google-only ladder, while preserving RepoRoot when set.'
        'Use attached_bundle_first_entrypoint_command when you want the pinned three-page compatibility bundle route plus the return-to-safe-route command printed in one helper before deciding whether to widen back into the wrapper-heavy chain.'
        'Use attached_bundle_flow_command before the attached-page bundle rerun when you want the pinned checker, flow helper, and delegated localhost runner printed in one place, with RepoRoot carried through for non-default checkouts.'
        'Use attached_bundle_runner_command after the attached bundle flow when you want the current three-page compatibility targets exercised on the same narrower route, while preserving the selected RepoRoot when the helper was opened from a non-default checkout.'
        'Use fresh_replay_command when outputs may be stale or missing.'
        'Use reuse_current_outputs_command only when the current issue #3 artifacts are already present and trusted.'
        'Open quickstart_note_path for the shortest current replay note, validation_chain_note_path for wrapper precedence, and runner_patch_decision_table_path when the patch handoff reaches ready-for-runner-patch, already-direct, or runner-already-wired-regenerate-outputs.'
        'Use runner_patch_next_step_helper_command when the wrapper has already named one of those three states and you want the exact next move printed without reopening the longer decision-table note first.'
        'Use refresh_status_route_command before reopening narrower refresh or handoff helpers from a non-default summary.'
        'When LIGHTPANDA_REPO_ROOT is already anchoring the replay, the emitted read-first discovery commands, suite-router handoff helper, suite-router next-step matrix, replay-route helper, replay-shortcuts helper, attached-bundle suite router, runner next-step helper, and safe-route wrappers now preserve that same repo-root context instead of falling back to the default checkout.'
    )
}

if ($Json) {
    $entrypoints | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 safe-route entrypoints'
Write-Host ''
Write-Host ("Repo root:   {0}" -f $entrypoints.repo_root)
Write-Host ("Summary path:{0}" -f $(if ($entrypoints.summary_path) { " $($entrypoints.summary_path)" } else { ' <default>' }))
Write-Host ''
Write-Host 'Read-first discovery:'
Write-Host ("  Suite router:         {0}" -f $entrypoints.read_first_suite_command)
Write-Host ("  Change-area view:     {0}" -f $entrypoints.read_first_change_area_command)
Write-Host ("  Google flow helper:   {0}" -f $entrypoints.read_first_google_flow_command)
Write-Host ("  Suite-router handoff: {0}" -f $entrypoints.suite_router_handoff_command)
Write-Host ("  Next-step matrix:     {0}" -f $entrypoints.suite_router_next_steps_command)
Write-Host ("  Replay route:         {0}" -f $entrypoints.replay_route_command)
Write-Host ("  Replay shortcuts:     {0}" -f $entrypoints.replay_shortcuts_command)
Write-Host ''
Write-Host 'Attached-page bundle route:'
Write-Host ("  Suite router:         {0}" -f $entrypoints.attached_bundle_suite_command)
Write-Host ("  Bundle-first helper:  {0}" -f $entrypoints.attached_bundle_first_entrypoint_command)
Write-Host ("  Flow helper:          {0}" -f $entrypoints.attached_bundle_flow_command)
Write-Host ("  Runner:               {0}" -f $entrypoints.attached_bundle_runner_command)
Write-Host ''
Write-Host ("Fresh replay:          {0}" -f $entrypoints.fresh_replay_command)
Write-Host ("Reuse current outputs: {0}" -f $entrypoints.reuse_current_outputs_command)
Write-Host ("Refresh route:         {0}" -f $entrypoints.refresh_status_route_command)
Write-Host ("Handoff safe:          {0}" -f $entrypoints.handoff_safe_command)
Write-Host ("Summary guide safe:    {0}" -f $entrypoints.summary_guide_safe_command)
Write-Host ("Runner wiring safe:    {0}" -f $entrypoints.runner_wiring_safe_command)
Write-Host ''
Write-Host ("Quickstart note:       {0}" -f $entrypoints.quickstart_note_path)
Write-Host ("Validation chain note: {0}" -f $entrypoints.validation_chain_note_path)
Write-Host ("Decision table:        {0}" -f $entrypoints.runner_patch_decision_table_path)
Write-Host ("Runner patch helper:   {0}" -f $entrypoints.runner_patch_next_step_helper_command)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoints.notes) {
    Write-Host ("- {0}" -f $note)
}
