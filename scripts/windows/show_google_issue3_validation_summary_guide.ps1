[CmdletBinding()]
param(
    [string]$SummaryPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot([string]$StartPath) {
    if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
        return $env:LIGHTPANDA_REPO_ROOT
    }

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor "build.zig")) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            throw "Could not resolve the Lightpanda repo root from $StartPath. Set LIGHTPANDA_REPO_ROOT to override."
        }
        $cursor = $parent
    }
}

function Convert-ToQuotedPowerShellArgument([string]$Value) {
    return "'" + $Value.Replace("'", "''") + "'"
}

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json"
}
if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    throw "Issue #3 recommended validation summary not found: $SummaryPath"
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$surfaceCheckCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_recommended_validation_surface.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$phaseRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1'
$homepageFixtureRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1'
$phaseBoundaryCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_phase_boundary.ps1'
$titleGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_probe_trace_guide.ps1'
$submitGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_trace_guide.ps1'
$formGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1'
$probeTriageCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_probe_triage.ps1'
$manualFixtureReplayCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_manual_fixture_replay.ps1'

$surfaceCheckMissingPaths = @($summary.surface_check_missing_paths)
$surfaceCheckMissingCount = if ($null -ne $summary.surface_check_missing_count) {
    [int]$summary.surface_check_missing_count
} else {
    @($surfaceCheckMissingPaths).Count
}
$surfaceCheckCheckedCount = if ($null -ne $summary.surface_check_checked_count) {
    [int]$summary.surface_check_checked_count
} else {
    $null
}
$missingFixtureAssetAudit = @($summary.missing_fixture_asset_audit)
$fixturesWithMissingAssets = @($missingFixtureAssetAudit | Where-Object { $_ -and $_.missing_asset_count -gt 0 })
$fixtureAssetsMissing = $fixturesWithMissingAssets.Count -gt 0
$manualFixtureReplayAvailable = [bool]$summary.manual_phase_uses_fixture_selection -and (@($summary.manual_input_path).Count -gt 0)
$manualQuotedInputPath = if ($manualFixtureReplayAvailable) {
    @($summary.manual_input_path | ForEach-Object { Convert-ToQuotedPowerShellArgument $_ })
} else {
    @()
}
$manualInputPathArguments = if ($manualQuotedInputPath.Count -gt 0) {
    $manualQuotedInputPath -join ' '
} else {
    $null
}
$manualPreferredInitialPageArgument = if ($manualFixtureReplayAvailable -and $summary.manual_initial_page) {
    " -PreferredInitialPage " + (Convert-ToQuotedPowerShellArgument $summary.manual_initial_page)
} else {
    ""
}
$manualAssetClosureCommand = if ($manualFixtureReplayAvailable -and $manualInputPathArguments) {
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_attached_html_local_asset_closure.ps1 -GoogleStyle -InputPath $manualInputPathArguments"
} else {
    $null
}
$manualAttachedHtmlFlowCommand = if ($manualFixtureReplayAvailable -and $manualInputPathArguments) {
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -InputPath $manualInputPathArguments$manualPreferredInitialPageArgument"
} else {
    $null
}
$manualAttachedHtmlRunnerCommand = if ($manualFixtureReplayAvailable -and $manualInputPathArguments) {
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait -InputPath $manualInputPathArguments$manualPreferredInitialPageArgument"
} else {
    $null
}
$manualSavedPageFlowCommand = if ($manualFixtureReplayAvailable -and $manualInputPathArguments) {
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_saved_page_google_validation_flow.ps1 -InputPath $manualInputPathArguments"
} else {
    $null
}

$firstFailedPhase = $summary.first_failed_phase
$recommendedCommand = $recommendedRunnerCommand
$recommendedGuideCommand = $probeTriageCommand
$nextFocus = 'Rerun the bounded issue #3 ladder and use the first failing phase to decide whether to stay on localhost probes or widen back out to attached HTML or live Google.'
$reason = 'The summary artifact did not record a single failing phase, so the safest next step is to keep the normal recommended runner as the source of truth.'

if ($summary.surface_check_status -and $summary.surface_check_status -ne 'passed') {
    $recommendedCommand = $surfaceCheckCommand
    $recommendedGuideCommand = $null
    $nextFocus = 'Fix the preflight validation surface before spending time on headed runtime behavior.'
    if ($surfaceCheckMissingCount -gt 0) {
        $reason = "The summary says the recommended issue #3 surface check failed before the phase ladder could run, and $surfaceCheckMissingCount required path(s) are currently missing."
    } else {
        $reason = 'The summary says the recommended issue #3 surface check failed before the phase ladder could run.'
    }
} elseif ($fixtureAssetsMissing -and $firstFailedPhase -eq 'manual') {
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = if ($manualFixtureReplayAvailable) { $manualFixtureReplayCommand } else { $null }
    $nextFocus = 'Restore the missing sibling assets for the saved attached HTML fixtures before trusting the manual Google-style follow-up.'
    $reason = "The manual follow-up is the first failing phase, and $($fixturesWithMissingAssets.Count) saved fixture selection(s) still reference missing local assets."
} elseif ($summary.completed) {
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $probeTriageCommand
    $nextFocus = 'The bounded localhost ladder completed, so the next replay can widen to attached HTML or live Google evidence gathering.'
    $reason = 'The summary says every recommended phase passed.'
} else {
    switch ($firstFailedPhase) {
        'localhost' {
            $recommendedCommand = $phaseRunnerCommand + ' -Phase localhost'
            $recommendedGuideCommand = $null
            $nextFocus = 'Restore the localhost fixture baseline before looking at the more Google-shaped phases.'
            $reason = 'The earliest failure happened before the issue #3 Google-shaped ladder moved past the plain localhost checkpoint.'
        }
        'quick' {
            $recommendedCommand = $phaseRunnerCommand + ' -Phase quick'
            $recommendedGuideCommand = $titleGuideCommand
            $nextFocus = 'Stay on the quick bounded title probe until focus and typed markers are stable.'
            $reason = 'The quick title-marker stage is the first failing checkpoint, so the smaller title-focused loop is still the sharpest repro.'
        }
        'home' {
            $recommendedCommand = $phaseRunnerCommand + ' -Phase home'
            $recommendedGuideCommand = $titleGuideCommand
            $nextFocus = 'Keep the investigation on the saved-home title path before widening to submit ordering or attached HTML.'
            $reason = 'The home checkpoint failed before the later submit-order phases had a chance to run.'
        }
        'homepage-fixture' {
            $recommendedCommand = $homepageFixtureRunnerCommand
            $recommendedGuideCommand = $titleGuideCommand
            $nextFocus = 'Fix the localhost homepage fixture behavior before trusting later Google-style checkpoints.'
            $reason = 'The dedicated homepage fixture phase is the first failing step in the recorded ladder.'
        }
        'input-phase-localhost' {
            $recommendedCommand = $phaseRunnerCommand + ' -Phase input-phase-localhost'
            $recommendedGuideCommand = $titleGuideCommand
            $nextFocus = 'Keep the replay on the bounded localhost input phase until typed text and focus stay stable.'
            $reason = 'The summary says the failure happened at the localhost input phase before the Enter-order checks.'
        }
        'submit-timing' {
            $recommendedCommand = $phaseRunnerCommand + ' -Phase submit-timing'
            $recommendedGuideCommand = $submitGuideCommand
            $nextFocus = 'Inspect the reduced-home submit timing path before reopening broader headed input changes.'
            $reason = 'The reduced-home submit timing phase is the first failing checkpoint in the saved summary.'
        }
        'shared-enter-order' {
            $recommendedCommand = $phaseRunnerCommand + ' -Phase shared-enter-order'
            $recommendedGuideCommand = $formGuideCommand
            $nextFocus = 'Stay on the shared Enter-order checkpoint until keydown, keypress, and submit ordering are proven.'
            $reason = 'The bounded shared Enter-order phase failed, so the next replay should stay on that ordering proof instead of widening back out.'
        }
        'manual' {
            $recommendedCommand = $recommendedRunnerCommand
            $recommendedGuideCommand = if ($manualFixtureReplayAvailable) { $manualFixtureReplayCommand } else { $probeTriageCommand }
            $nextFocus = 'The bounded phases passed and the attached HTML or Google-style manual follow-up is now the narrowest failing step.'
            $reason = 'The manual follow-up was the first failing phase, so the next replay should preserve the saved fixture selection and rerun the full recommended command.'
        }
    }
}

$phaseResults = @($summary.phase_results)
$passedPhaseResults = @($phaseResults | Where-Object { $_.status -eq 'passed' })
$lastPassedPhaseResult = if ($passedPhaseResults.Count -gt 0) { $passedPhaseResults[-1] } else { $null }
$failedPhaseResult = @($phaseResults | Where-Object { $_.name -eq $firstFailedPhase } | Select-Object -First 1)
$guideArtifactPath = if ($summary.guide_artifact_path) {
    $summary.guide_artifact_path
} else {
    Join-Path (Split-Path -Parent $SummaryPath) 'google-issue3-recommended-validation-guide.json'
}
$boundaryArtifactPath = Join-Path (Split-Path -Parent $SummaryPath) 'google-issue3-phase-boundary.json'
$guide = [ordered]@{
    issue = 'Google issue #3 validation summary guide'
    purpose = 'Read the saved recommended-validation summary artifact and point the next Windows headed replay at the earliest failing checkpoint.'
    summary_path = $SummaryPath
    generated_at_utc = $summary.generated_at_utc
    completed = [bool]$summary.completed
    surface_check_status = $summary.surface_check_status
    surface_check_error = $summary.surface_check_error
    surface_check_artifact_path = $summary.surface_check_artifact_path
    manifest_artifact_path = $summary.manifest_artifact_path
    guide_artifact_path = $guideArtifactPath
    boundary_artifact_path = $boundaryArtifactPath
    surface_check_profile = $summary.surface_check_profile
    surface_check_checked_count = $surfaceCheckCheckedCount
    surface_check_missing_count = $surfaceCheckMissingCount
    surface_check_missing_paths = @($surfaceCheckMissingPaths)
    phase_artifact_root = $summary.phase_artifact_root
    first_failed_phase = $firstFailedPhase
    first_failed_phase_error = $summary.first_failed_phase_error
    first_failed_phase_log_path = $summary.first_failed_phase_log_path
    first_failed_phase_primary_json_artifact_path = if ($failedPhaseResult.Count -gt 0) { $failedPhaseResult[0].primary_json_artifact_path } else { $summary.first_failed_phase_primary_json_artifact_path }
    first_failed_phase_artifact_paths = if ($failedPhaseResult.Count -gt 0) { @($failedPhaseResult[0].artifact_paths) } else { @() }
    failed_phase_log_path = if ($failedPhaseResult.Count -gt 0) { $failedPhaseResult[0].log_path } else { $null }
    manual_phase_enabled = [bool]$summary.manual_phase_enabled
    manual_phase_google_style = [bool]$summary.manual_phase_google_style
    manual_phase_uses_fixture_selection = [bool]$summary.manual_phase_uses_fixture_selection
    manual_initial_page = $summary.manual_initial_page
    manual_input_path = @($summary.manual_input_path)
    missing_fixture_asset_audit = @($missingFixtureAssetAudit)
    fixture_assets_missing = [bool]$fixtureAssetsMissing
    fixture_selection_missing_asset_count = $fixturesWithMissingAssets.Count
    manual_fixture_replay_available = [bool]$manualFixtureReplayAvailable
    manual_fixture_replay_command = if ($manualFixtureReplayAvailable) { $manualFixtureReplayCommand } else { $null }
    manual_fixture_replay_reason = if ($manualFixtureReplayAvailable) { 'Use this helper to print the exact asset-check, flow, and runner commands for the saved attached-HTML fixture bundle.' } else { $null }
    manual_asset_closure_command = $manualAssetClosureCommand
    manual_attached_html_flow_command = $manualAttachedHtmlFlowCommand
    manual_attached_html_runner_command = $manualAttachedHtmlRunnerCommand
    manual_saved_page_flow_command = $manualSavedPageFlowCommand
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    phase_boundary_command = $phaseBoundaryCommand
    broader_runner_command = $recommendedRunnerCommand
    reason = $reason
    next_focus = $nextFocus
    reminder = 'Keep the next replay on the earliest failing checkpoint first. Read the saved phase-boundary helper to compare the last passing checkpoint with the first failing one before widening back out to the full recommended runner, attached HTML, or live Google.'
}

$boundaryArtifact = [ordered]@{
    issue = 'Google issue #3 phase boundary'
    purpose = 'Persist the boundary between the last passing checkpoint and the first failing checkpoint from the saved recommended-validation summary, using the same rerun guidance the summary guide just computed.'
    summary_path = $SummaryPath
    boundary_artifact_path = $boundaryArtifactPath
    generated_at_utc = $summary.generated_at_utc
    completed = [bool]$summary.completed
    phase_count = @($phaseResults).Count
    passed_phase_count = @($passedPhaseResults).Count
    failed_phase_count = @(@($phaseResults | Where-Object { $_.status -ne 'passed' })).Count
    phase_artifact_root = $summary.phase_artifact_root
    manifest_artifact_path = $summary.manifest_artifact_path
    guide_artifact_path = $guideArtifactPath
    last_passed_phase = if ($lastPassedPhaseResult) { $lastPassedPhaseResult.name } else { $null }
    last_passed_phase_log_path = if ($lastPassedPhaseResult) { $lastPassedPhaseResult.log_path } else { $null }
    last_passed_phase_primary_json_artifact_path = if ($lastPassedPhaseResult) { $lastPassedPhaseResult.primary_json_artifact_path } else { $null }
    last_passed_phase_artifact_paths = if ($lastPassedPhaseResult) { @($lastPassedPhaseResult.artifact_paths) } else { @() }
    first_failed_phase = $guide.first_failed_phase
    first_failed_phase_error = $guide.first_failed_phase_error
    first_failed_phase_log_path = $guide.first_failed_phase_log_path
    first_failed_phase_primary_json_artifact_path = $guide.first_failed_phase_primary_json_artifact_path
    first_failed_phase_artifact_paths = @($guide.first_failed_phase_artifact_paths)
    boundary_focus = if ($guide.first_failed_phase) {
        'Compare the last passing phase artifact with the first failing phase artifact before widening back out to a broader issue #3 replay.'
    } elseif ($lastPassedPhaseResult) {
        'Every recorded phase passed, so the next replay can widen to attached HTML or live Google evidence gathering.'
    } else {
        'No passing phase was recorded yet, so start at the earliest recommended phase and repair the first checkpoint before widening out.'
    }
    next_focus = $guide.next_focus
    recommended_command = $guide.recommended_command
    recommended_guide_command = $guide.recommended_guide_command
    manual_fixture_replay_command = $guide.manual_fixture_replay_command
    reason = $guide.reason
    next_artifact_to_open = if ($guide.first_failed_phase_primary_json_artifact_path) {
        $guide.first_failed_phase_primary_json_artifact_path
    } elseif ($lastPassedPhaseResult -and $lastPassedPhaseResult.primary_json_artifact_path) {
        $lastPassedPhaseResult.primary_json_artifact_path
    } elseif ($guideArtifactPath) {
        $guideArtifactPath
    } else {
        $SummaryPath
    }
}

$boundaryArtifact | ConvertTo-Json -Depth 6 | Set-Content -Path $boundaryArtifactPath -Encoding Ascii

if ($Json) {
    $guide | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 validation summary guide'
Write-Host ''
Write-Host ("Summary:   {0}" -f $guide.summary_path)
Write-Host ("Generated: {0}" -f $guide.generated_at_utc)
Write-Host ("Completed: {0}" -f $guide.completed)
Write-Host ("Surface:   {0}" -f $guide.surface_check_status)
if ($guide.surface_check_artifact_path) {
    Write-Host ("Surface JSON: {0}" -f $guide.surface_check_artifact_path)
}
if ($guide.manifest_artifact_path) {
    Write-Host ("Manifest JSON: {0}" -f $guide.manifest_artifact_path)
}
if ($guide.guide_artifact_path) {
    Write-Host ("Guide JSON: {0}" -f $guide.guide_artifact_path)
}
if ($guide.boundary_artifact_path) {
    Write-Host ("Boundary JSON: {0}" -f $guide.boundary_artifact_path)
}
if ($guide.surface_check_profile) {
    Write-Host ("Surface profile: {0}" -f $guide.surface_check_profile)
}
if ($null -ne $guide.surface_check_checked_count) {
    Write-Host ("Surface checked: {0}" -f $guide.surface_check_checked_count)
}
if ($guide.surface_check_missing_count -gt 0) {
    Write-Host ("Surface missing: {0}" -f $guide.surface_check_missing_count)
    foreach ($missingPath in $guide.surface_check_missing_paths) {
        Write-Host ("- {0}" -f $missingPath)
    }
}
if ($guide.phase_artifact_root) {
    Write-Host ("Phase root: {0}" -f $guide.phase_artifact_root)
}
Write-Host ("First fail:{0}" -f $(if ($guide.first_failed_phase) { ' ' + $guide.first_failed_phase } else { ' none' }))
if ($guide.first_failed_phase_log_path) {
    Write-Host ("Log:       {0}" -f $guide.first_failed_phase_log_path)
}
if ($guide.first_failed_phase_primary_json_artifact_path) {
    Write-Host ("JSON:      {0}" -f $guide.first_failed_phase_primary_json_artifact_path)
}
if ($guide.first_failed_phase_artifact_paths.Count -gt 0) {
    Write-Host 'Artifacts:'
    foreach ($artifactPath in $guide.first_failed_phase_artifact_paths) {
        Write-Host ("- {0}" -f $artifactPath)
    }
}
if ($guide.first_failed_phase_error) {
    Write-Host ("Error:     {0}" -f $guide.first_failed_phase_error)
}
if ($guide.fixture_assets_missing) {
    Write-Host 'Missing fixture assets:'
    foreach ($fixtureAudit in ($guide.missing_fixture_asset_audit | Where-Object { $_.missing_asset_count -gt 0 })) {
        Write-Host ("- {0} ({1})" -f $fixtureAudit.path, $fixtureAudit.missing_asset_count)
        foreach ($assetPath in ($fixtureAudit.missing_assets | Select-Object -First 5)) {
            Write-Host ("  - {0}" -f $assetPath)
        }
        if ($fixtureAudit.missing_asset_count -gt 5) {
            Write-Host ("  - ... {0} more" -f ($fixtureAudit.missing_asset_count - 5))
        }
    }
}
Write-Host ''
Write-Host ("Reason:    {0}" -f $guide.reason)
Write-Host ("Focus:     {0}" -f $guide.next_focus)
Write-Host ("Run next:  {0}" -f $guide.recommended_command)
if ($guide.recommended_guide_command) {
    Write-Host ("Guide:     {0}" -f $guide.recommended_guide_command)
}
Write-Host ("Boundary cmd:  {0}" -f $guide.phase_boundary_command)
if ($guide.manual_fixture_replay_command) {
    Write-Host ("Manual replay: {0}" -f $guide.manual_fixture_replay_command)
}
Write-Host ("Broader:   {0}" -f $guide.broader_runner_command)
if ($guide.manual_phase_uses_fixture_selection -and $guide.manual_input_path.Count -gt 0) {
    Write-Host ''
    Write-Host 'Saved fixture selection:'
    foreach ($fixturePath in $guide.manual_input_path) {
        Write-Host ("- {0}" -f $fixturePath)
    }
    if ($guide.manual_initial_page) {
        Write-Host ("Initial page: {0}" -f $guide.manual_initial_page)
    }
    if ($guide.manual_fixture_replay_reason) {
        Write-Host ("Replay hint: {0}" -f $guide.manual_fixture_replay_reason)
    }
    if ($guide.manual_asset_closure_command) {
        Write-Host ("Asset check: {0}" -f $guide.manual_asset_closure_command)
    }
    if ($guide.manual_attached_html_flow_command) {
        Write-Host ("Flow:       {0}" -f $guide.manual_attached_html_flow_command)
    }
    if ($guide.manual_attached_html_runner_command) {
        Write-Host ("Runner:     {0}" -f $guide.manual_attached_html_runner_command)
    }
    if ($guide.manual_saved_page_flowCommand) {
        Write-Host ("Saved-page: {0}" -f $guide.manual_saved_page_flowCommand)
    }
}
Write-Host ''
Write-Host ("Reminder:  {0}" -f $guide.reminder)
