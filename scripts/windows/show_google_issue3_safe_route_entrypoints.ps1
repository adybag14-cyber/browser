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
        [hashtable]$Arguments = @{}
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

$entrypoints = [ordered]@{
    issue = 'Google issue #3 safe-route entrypoints'
    purpose = 'Keep the current issue #3 Windows replay on the newest safe-route helper first, while preserving repo-root and summary-path context for non-default checkouts and env-anchored replays.'
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    runner_patch_decision_table_path = 'docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md'
    runner_patch_next_step_helper_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_patch_next_step.ps1 -State <ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>'
    read_first_suite_command = '.\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended'
    read_first_change_area_command = '.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input'
    read_first_google_flow_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1'
    attached_bundle_suite_command = '.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle'
    attached_bundle_flow_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_target_bundle_validation_flow.ps1'
    attached_bundle_runner_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_attached_html_target_bundle_validation.ps1 -Wait'
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
        'Use read_first_suite_command when re-entering issue #3 from the top-level headed validation suite catalog and you want the broader localhost-first runner surfaced quickly.'
        'Use read_first_change_area_command when the next replay may need one of the narrower Google title, homepage-fixture, submit-path, submit-timing, shared Enter-order, attached-page, or live-trace slices instead of the broader recommended runner.'
        'Use read_first_google_flow_command when you want the broader bounded Google flow printed before deciding whether to stay on the safe-route entrypoints or drop to another narrower helper.'
        'Use attached_bundle_suite_command when the next replay should stay pinned to the current attached three-page compatibility bundle instead of the broader Google-only ladder.'
        'Use attached_bundle_flow_command before the attached-page bundle rerun when you want the pinned checker, flow helper, and delegated localhost runner printed in one place.'
        'Use attached_bundle_runner_command after the attached bundle flow when you want the current three-page compatibility targets exercised on the same narrower route.'
        'Use fresh_replay_command when outputs may be stale or missing.'
        'Use reuse_current_outputs_command only when the current issue #3 artifacts are already present and trusted.'
        'Open quickstart_note_path for the shortest current replay note, validation_chain_note_path for wrapper precedence, and runner_patch_decision_table_path when the patch handoff reaches ready-for-runner-patch, already-direct, or runner-already-wired-regenerate-outputs.'
        'Use runner_patch_next_step_helper_command when the wrapper has already named one of those three states and you want the exact next move printed without reopening the longer decision-table note first.'
        'Use refresh_status_route_command before reopening narrower refresh or handoff helpers from a non-default summary.'
        'When LIGHTPANDA_REPO_ROOT is already anchoring the replay, the emitted commands now preserve that same repo-root context instead of falling back to the default checkout.'
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
Write-Host ("  Suite router:       {0}" -f $entrypoints.read_first_suite_command)
Write-Host ("  Change-area view:   {0}" -f $entrypoints.read_first_change_area_command)
Write-Host ("  Google flow helper: {0}" -f $entrypoints.read_first_google_flow_command)
Write-Host ''
Write-Host 'Attached-page bundle route:'
Write-Host ("  Suite router:       {0}" -f $entrypoints.attached_bundle_suite_command)
Write-Host ("  Flow helper:        {0}" -f $entrypoints.attached_bundle_flow_command)
Write-Host ("  Runner:             {0}" -f $entrypoints.attached_bundle_runner_command)
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
