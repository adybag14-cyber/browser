[CmdletBinding()]
param(
    [string]$SummaryPath,
    [string]$ArtifactPath,
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

function Test-HasProperty {
    param(
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [bool]($Object -and $Object.PSObject.Properties[$Name])
}

function Get-OptionalPropertyValue {
    param(
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (Test-HasProperty -Object $Object -Name $Name) {
        return $Object.$Name
    }

    return $null
}

function Resolve-ArtifactCandidatePath {
    param(
        [string]$ConfiguredPath,
        [Parameter(Mandatory = $true)]
        [string]$ArtifactRoot,
        [Parameter(Mandatory = $true)]
        [string]$FallbackName
    )

    if (-not [string]::IsNullOrWhiteSpace($ConfiguredPath)) {
        return $ConfiguredPath
    }

    return Join-Path $ArtifactRoot $FallbackName
}

function Get-PhaseReplayCommand([string]$PhaseName) {
    if ([string]::IsNullOrWhiteSpace($PhaseName)) {
        return $null
    }

    switch ($PhaseName) {
        'localhost' {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase localhost'
        }
        'quick' {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase quick'
        }
        'home' {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase home'
        }
        'homepage-fixture' {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1'
        }
        'input-phase-localhost' {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase input-phase-localhost'
        }
        'submit-timing' {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase submit-timing'
        }
        'shared-enter-order' {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase shared-enter-order'
        }
        'manual' {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_manual_fixture_replay.ps1'
        }
        default {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
        }
    }
}

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json"
}
if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    throw "Issue #3 recommended validation summary not found: $SummaryPath"
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$artifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
if ([string]::IsNullOrWhiteSpace($artifactRoot)) {
    $artifactRoot = Split-Path -Parent $SummaryPath
}
$configuredGuideArtifactPath = Get-OptionalPropertyValue -Object $summary -Name 'guide_artifact_path'
$guideArtifactPath = if (-not [string]::IsNullOrWhiteSpace($ArtifactPath)) {
    $ArtifactPath
} elseif (-not [string]::IsNullOrWhiteSpace($configuredGuideArtifactPath)) {
    $configuredGuideArtifactPath
} else {
    Join-Path $artifactRoot 'google-issue3-recommended-validation-guide.json'
}
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
$manifestGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest.ps1'
$artifactBundleGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$refreshStatusGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'

$surfaceCheckMissingPaths = @((Get-OptionalPropertyValue -Object $summary -Name 'surface_check_missing_paths'))
$configuredSurfaceCheckMissingCount = Get-OptionalPropertyValue -Object $summary -Name 'surface_check_missing_count'
$surfaceCheckMissingCount = if ($null -ne $configuredSurfaceCheckMissingCount) {
    [int]$configuredSurfaceCheckMissingCount
} else {
    @($surfaceCheckMissingPaths).Count
}
$configuredSurfaceCheckCheckedCount = Get-OptionalPropertyValue -Object $summary -Name 'surface_check_checked_count'
$surfaceCheckCheckedCount = if ($null -ne $configuredSurfaceCheckCheckedCount) {
    [int]$configuredSurfaceCheckCheckedCount
} else {
    $null
}
$missingFixtureAssetAudit = @((Get-OptionalPropertyValue -Object $summary -Name 'missing_fixture_asset_audit'))
$fixturesWithMissingAssets = @($missingFixtureAssetAudit | Where-Object { $_ -and $_.missing_asset_count -gt 0 })
$fixtureAssetsMissing = $fixturesWithMissingAssets.Count -gt 0
$manualPhaseUsesFixtureSelection = [bool](Get-OptionalPropertyValue -Object $summary -Name 'manual_phase_uses_fixture_selection')
$manualInputPath = @((Get-OptionalPropertyValue -Object $summary -Name 'manual_input_path'))
$manualFixtureReplayAvailable = [bool]$manualPhaseUsesFixtureSelection -and ($manualInputPath.Count -gt 0)
$manualQuotedInputPath = if ($manualFixtureReplayAvailable) {
    @($manualInputPath | ForEach-Object { Convert-ToQuotedPowerShellArgument $_ })
} else {
    @()
}
$manualInputPathArguments = if ($manualQuotedInputPath.Count -gt 0) {
    $manualQuotedInputPath -join ' '
} else {
    $null
}
$manualInitialPage = Get-OptionalPropertyValue -Object $summary -Name 'manual_initial_page'
$manualPreferredInitialPageArgument = if ($manualFixtureReplayAvailable -and -not [string]::IsNullOrWhiteSpace($manualInitialPage)) {
    " -PreferredInitialPage " + (Convert-ToQuotedPowerShellArgument $manualInitialPage)
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

$summaryGeneratedAt = Get-OptionalPropertyValue -Object $summary -Name 'generated_at_utc'
$surfaceCheckStatus = Get-OptionalPropertyValue -Object $summary -Name 'surface_check_status'
$summaryCompleted = [bool](Get-OptionalPropertyValue -Object $summary -Name 'completed')
$firstFailedPhase = Get-OptionalPropertyValue -Object $summary -Name 'first_failed_phase'
$recommendedCommand = $recommendedRunnerCommand
$recommendedGuideCommand = $probeTriageCommand
$nextFocus = 'Rerun the bounded issue #3 ladder and use the first failing phase to decide whether to stay on localhost probes or widen back out to attached HTML or live Google.'
$reason = 'The summary artifact did not record a single failing phase, so the safest next step is to keep the normal recommended runner as the source of truth.'

if ($surfaceCheckStatus -and $surfaceCheckStatus -ne 'passed') {
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
} elseif ($summaryCompleted) {
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

$phaseResultsValue = Get-OptionalPropertyValue -Object $summary -Name 'phase_results'
$phaseResults = if ($phaseResultsValue) { @($phaseResultsValue) } else { @() }
$passedPhaseResults = @($phaseResults | Where-Object { $_.status -eq 'passed' })
$lastPassedPhaseResult = if ($passedPhaseResults.Count -gt 0) { $passedPhaseResults[-1] } else { $null }
$failedPhaseResult = @($phaseResults | Where-Object { $_.name -eq $firstFailedPhase } | Select-Object -First 1)
$lastPassedPhaseReplayCommand = if ($lastPassedPhaseResult) { Get-PhaseReplayCommand $lastPassedPhaseResult.name } else { $null }
$firstFailedPhaseReplayCommand = if ($failedPhaseResult.Count -gt 0) { Get-PhaseReplayCommand $failedPhaseResult[0].name } else { $null }
$manifestArtifactPath = Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'manifest_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$boundaryArtifactPath = Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'boundary_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-phase-boundary.json'
$artifactBundlePath = Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'artifact_bundle_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json'
$handoffArtifactPath = Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'handoff_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
$refreshChainArtifactPath = Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'refresh_chain_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$boundaryRecord = $null
$boundaryArtifactError = $null
if (-not [string]::IsNullOrWhiteSpace($boundaryArtifactPath) -and (Test-Path -LiteralPath $boundaryArtifactPath -PathType Leaf)) {
    try {
        $boundaryRecord = Get-Content -LiteralPath $boundaryArtifactPath -Raw | ConvertFrom-Json
    } catch {
        $boundaryArtifactError = $_.Exception.Message
    }
} elseif (-not [string]::IsNullOrWhiteSpace($boundaryArtifactPath)) {
    $boundaryArtifactError = "Boundary artifact not found: $boundaryArtifactPath"
}
$boundaryRecommendedCommand = Get-OptionalPropertyValue -Object $boundaryRecord -Name 'recommended_command'
$boundaryRecommendedGuideCommand = Get-OptionalPropertyValue -Object $boundaryRecord -Name 'recommended_guide_command'
$boundaryManualFixtureReplayCommand = Get-OptionalPropertyValue -Object $boundaryRecord -Name 'manual_fixture_replay_command'
$boundaryNextArtifactToOpen = Get-OptionalPropertyValue -Object $boundaryRecord -Name 'next_artifact_to_open'
$boundaryLastPassedPhase = Get-OptionalPropertyValue -Object $boundaryRecord -Name 'last_passed_phase'
$boundaryFirstFailedPhase = Get-OptionalPropertyValue -Object $boundaryRecord -Name 'first_failed_phase'
$guide = [ordered]@{
    issue = 'Google issue #3 validation summary guide'
    purpose = 'Read the saved recommended-validation summary artifact and point the next Windows headed replay at the earliest failing checkpoint.'
    summary_path = $SummaryPath
    generated_at_utc = $summaryGeneratedAt
    completed = [bool]$summaryCompleted
    surface_check_status = $surfaceCheckStatus
    surface_check_error = Get-OptionalPropertyValue -Object $summary -Name 'surface_check_error'
    surface_check_artifact_path = Get-OptionalPropertyValue -Object $summary -Name 'surface_check_artifact_path'
    manifest_artifact_path = $manifestArtifactPath
    manifest_artifact_exists = [bool](-not [string]::IsNullOrWhiteSpace($manifestArtifactPath) -and (Test-Path -LiteralPath $manifestArtifactPath -PathType Leaf))
    guide_artifact_path = $guideArtifactPath
    boundary_artifact_path = $boundaryArtifactPath
    boundary_artifact_error = $boundaryArtifactError
    boundary_artifact_exists = [bool]$boundaryRecord
    artifact_bundle_path = $artifactBundlePath
    artifact_bundle_exists = [bool](-not [string]::IsNullOrWhiteSpace($artifactBundlePath) -and (Test-Path -LiteralPath $artifactBundlePath -PathType Leaf))
    handoff_artifact_path = $handoffArtifactPath
    handoff_artifact_exists = [bool](-not [string]::IsNullOrWhiteSpace($handoffArtifactPath) -and (Test-Path -LiteralPath $handoffArtifactPath -PathType Leaf))
    refresh_chain_artifact_path = $refreshChainArtifactPath
    refresh_chain_artifact_exists = [bool](-not [string]::IsNullOrWhiteSpace($refreshChainArtifactPath) -and (Test-Path -LiteralPath $refreshChainArtifactPath -PathType Leaf))
    surface_check_profile = Get-OptionalPropertyValue -Object $summary -Name 'surface_check_profile'
    surface_check_checked_count = $surfaceCheckCheckedCount
    surface_check_missing_count = $surfaceCheckMissingCount
    surface_check_missing_paths = @($surfaceCheckMissingPaths)
    phase_artifact_root = Get-OptionalPropertyValue -Object $summary -Name 'phase_artifact_root'
    first_failed_phase = $firstFailedPhase
    first_failed_phase_error = Get-OptionalPropertyValue -Object $summary -Name 'first_failed_phase_error'
    first_failed_phase_log_path = Get-OptionalPropertyValue -Object $summary -Name 'first_failed_phase_log_path'
    first_failed_phase_primary_json_artifact_path = if ($failedPhaseResult.Count -gt 0) { $failedPhaseResult[0].primary_json_artifact_path } else { Get-OptionalPropertyValue -Object $summary -Name 'first_failed_phase_primary_json_artifact_path' }
    first_failed_phase_artifact_paths = if ($failedPhaseResult.Count -gt 0) { @($failedPhaseResult[0].artifact_paths) } else { @() }
    first_failed_phase_replay_command = $firstFailedPhaseReplayCommand
    failed_phase_log_path = if ($failedPhaseResult.Count -gt 0) { $failedPhaseResult[0].log_path } else { $null }
    last_passed_phase = if ($lastPassedPhaseResult) { $lastPassedPhaseResult.name } else { $null }
    last_passed_phase_log_path = if ($lastPassedPhaseResult) { $lastPassedPhaseResult.log_path } else { $null }
    last_passed_phase_primary_json_artifact_path = if ($lastPassedPhaseResult) { $lastPassedPhaseResult.primary_json_artifact_path } else { $null }
    last_passed_phase_artifact_paths = if ($lastPassedPhaseResult) { @($lastPassedPhaseResult.artifact_paths) } else { @() }
    last_passed_phase_replay_command = $lastPassedPhaseReplayCommand
    boundary_last_passed_phase = $boundaryLastPassedPhase
    boundary_first_failed_phase = $boundaryFirstFailedPhase
    boundary_next_artifact_to_open = $boundaryNextArtifactToOpen
    manual_phase_enabled = [bool](Get-OptionalPropertyValue -Object $summary -Name 'manual_phase_enabled')
    manual_phase_google_style = [bool](Get-OptionalPropertyValue -Object $summary -Name 'manual_phase_google_style')
    manual_phase_uses_fixture_selection = [bool]$manualPhaseUsesFixtureSelection
    manual_initial_page = $manualInitialPage
    manual_input_path = @($manualInputPath)
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
    manifest_guide_command = $manifestGuideCommand
    artifact_bundle_guide_command = $artifactBundleGuideCommand
    handoff_guide_command = $handoffGuideCommand
    refresh_status_guide_command = $refreshStatusGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    reason = $reason
    next_focus = $nextFocus
    reminder = if ($boundaryRecord -and $boundaryNextArtifactToOpen) {
        'Keep the next replay on the earliest failing checkpoint first. Open the boundary helper artifact and inspect its next_artifact_to_open path before widening back out to the full recommended runner, attached HTML, or live Google.'
    } else {
        'Keep the next replay on the earliest failing checkpoint first. Read the saved phase-boundary helper to compare the last passing checkpoint with the first failing one before widening back out to the full recommended runner, attached HTML, or live Google.'
    }
}

$boundaryArtifact = [ordered]@{
    issue = 'Google issue #3 phase boundary'
    purpose = 'Persist the boundary between the last passing checkpoint and the first failing checkpoint from the saved recommended-validation summary, using the same rerun guidance the summary guide just computed.'
    summary_path = $SummaryPath
    boundary_artifact_path = $boundaryArtifactPath
    generated_at_utc = $summaryGeneratedAt
    completed = [bool]$summaryCompleted
    phase_count = @($phaseResults).Count
    passed_phase_count = @($passedPhaseResults).Count
    failed_phase_count = @(@($phaseResults | Where-Object { $_.status -ne 'passed' })).Count
    phase_artifact_root = Get-OptionalPropertyValue -Object $summary -Name 'phase_artifact_root'
    manifest_artifact_path = $manifestArtifactPath
    guide_artifact_path = $guideArtifactPath
    artifact_bundle_path = $artifactBundlePath
    handoff_artifact_path = $handoffArtifactPath
    refresh_chain_artifact_path = $refreshChainArtifactPath
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
    recommended_command = if ($guide.boundary_artifact_exists -and -not [string]::IsNullOrWhiteSpace($boundaryRecommendedCommand)) {
        $boundaryRecommendedCommand
    } else {
        $guide.recommended_command
    }
    recommended_guide_command = if ($guide.boundary_artifact_exists -and -not [string]::IsNullOrWhiteSpace($boundaryRecommendedGuideCommand)) {
        $boundaryRecommendedGuideCommand
    } else {
        $guide.recommended_guide_command
    }
    manual_fixture_replay_command = if ($guide.boundary_artifact_exists -and -not [string]::IsNullOrWhiteSpace($boundaryManualFixtureReplayCommand)) {
        $boundaryManualFixtureReplayCommand
    } else {
        $guide.manual_fixture_replay_command
    }
    reason = $guide.reason
    next_artifact_to_open = if ($guide.boundary_artifact_exists -and -not [string]::IsNullOrWhiteSpace($boundaryNextArtifactToOpen)) {
        $boundaryNextArtifactToOpen
    } elseif ($guide.first_failed_phase_primary_json_artifact_path) {
        $guide.first_failed_phase_primary_json_artifact_path
    } elseif ($lastPassedPhaseResult -and $lastPassedPhaseResult.primary_json_artifact_path) {
        $lastPassedPhaseResult.primary_json_artifact_path
    } elseif ($guideArtifactPath) {
        $guideArtifactPath
    } else {
        $SummaryPath
    }
}

$guide | ConvertTo-Json -Depth 6 | Set-Content -Path $guideArtifactPath -Encoding Ascii
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
if ($guide.artifact_bundle_path) {
    Write-Host ("Bundle JSON: {0}" -f $guide.artifact_bundle_path)
}
if ($guide.handoff_artifact_path) {
    Write-Host ("Handoff JSON: {0}" -f $guide.handoff_artifact_path)
}
if ($guide.refresh_chain_artifact_path) {
    Write-Host ("Refresh JSON: {0}" -f $guide.refresh_chain_artifact_path)
}
if ($guide.boundary_artifact_error) {
    Write-Host ("Boundary error: {0}" -f $guide.boundary_artifact_error)
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
if ($guide.first_failed_phase_replay_command) {
    Write-Host ("Replay:    {0}" -f $guide.first_failed_phase_replay_command)
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
if ($guide.last_passed_phase) {
    Write-Host ("Last pass: {0}" -f $guide.last_passed_phase)
    if ($guide.last_passed_phase_log_path) {
        Write-Host ("Last log:  {0}" -f $guide.last_passed_phase_log_path)
    }
    if ($guide.last_passed_phase_primary_json_artifact_path) {
        Write-Host ("Last JSON: {0}" -f $guide.last_passed_phase_primary_json_artifact_path)
    }
    if ($guide.last_passed_phase_replay_command) {
        Write-Host ("Last replay: {0}" -f $guide.last_passed_phase_replay_command)
    }
}
if ($guide.boundary_artifact_exists) {
    Write-Host ("Boundary last pass: {0}" -f $(if ($guide.boundary_last_passed_phase) { $guide.boundary_last_passed_phase } else { 'none' }))
    Write-Host ("Boundary first fail: {0}" -f $(if ($guide.boundary_first_failed_phase) { $guide.boundary_first_failed_phase } else { 'none' }))
    if ($guide.boundary_next_artifact_to_open) {
        Write-Host ("Open next: {0}" -f $guide.boundary_next_artifact_to_open)
    }
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
Write-Host ("Manifest cmd:  {0}" -f $guide.manifest_guide_command)
Write-Host ("Bundle cmd:    {0}" -f $guide.artifact_bundle_guide_command)
Write-Host ("Handoff cmd:   {0}" -f $guide.handoff_guide_command)
Write-Host ("Refresh cmd:   {0}" -f $guide.refresh_status_guide_command)
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
    if ($guide.manual_saved_page_flow_command) {
        Write-Host ("Saved-page: {0}" -f $guide.manual_saved_page_flow_command)
    }
}
Write-Host ''
Write-Host ("Reminder:  {0}" -f $guide.reminder)
