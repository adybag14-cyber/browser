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

function Get-StringArray {
    param(
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $value = Get-OptionalPropertyValue -Object $Object -Name $Name
    if ($null -eq $value) {
        return @()
    }

    return @($value)
}

function Get-BoolValue {
    param(
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [bool]$Default = $false
    )

    $value = Get-OptionalPropertyValue -Object $Object -Name $Name
    if ($null -eq $value) {
        return $Default
    }

    return [bool]$value
}

function Get-FirstNonEmptyValue {
    param([object[]]$Values)

    foreach ($value in $Values) {
        if ($null -eq $value) {
            continue
        }

        if ($value -is [string]) {
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                return $value
            }
            continue
        }

        return $value
    }

    return $null
}

function Get-PhaseReplayCommand([string]$PhaseName) {
    if ([string]::IsNullOrWhiteSpace($PhaseName)) {
        return $null
    }

    switch ($PhaseName) {
        'localhost' { return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase localhost' }
        'quick' { return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase quick' }
        'home' { return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase home' }
        'homepage-fixture' { return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1' }
        'input-phase-localhost' { return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase input-phase-localhost' }
        'submit-timing' { return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase submit-timing' }
        'shared-enter-order' { return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase shared-enter-order' }
        'manual' { return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_manual_fixture_replay.ps1' }
        default { return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1' }
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
$artifactRoot = Get-FirstNonEmptyValue -Values @(
    Get-OptionalPropertyValue -Object $summary -Name 'artifact_root',
    (Split-Path -Parent $SummaryPath)
)
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-guide-safe.json'
}

$surfaceCheckCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_recommended_validation_surface.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$titleGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_probe_trace_guide.ps1'
$submitGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_trace_guide.ps1'
$formGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1'
$probeTriageCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_probe_triage.ps1'
$manualFixtureReplayCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_manual_fixture_replay.ps1'
$artifactPathRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_artifact_paths.ps1'
$summaryContractRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_summary_contract.ps1'
$phaseBoundaryCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_phase_boundary.ps1'
$manifestGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest.ps1'
$artifactBundleGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe.ps1'
$refreshStatusGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe.ps1'

$manifestArtifactPath = Get-FirstNonEmptyValue -Values @(
    Get-OptionalPropertyValue -Object $summary -Name 'manifest_artifact_path',
    (Join-Path $artifactRoot 'google-issue3-recommended-validation-manifest.json')
)
$guideArtifactPath = Get-FirstNonEmptyValue -Values @(
    Get-OptionalPropertyValue -Object $summary -Name 'guide_artifact_path',
    $ArtifactPath
)
$boundaryArtifactPath = Get-FirstNonEmptyValue -Values @(
    Get-OptionalPropertyValue -Object $summary -Name 'boundary_artifact_path',
    (Join-Path $artifactRoot 'google-issue3-phase-boundary.json')
)
$artifactBundlePath = Get-FirstNonEmptyValue -Values @(
    Get-OptionalPropertyValue -Object $summary -Name 'artifact_bundle_path',
    (Join-Path $artifactRoot 'google-issue3-validation-artifact-bundle.json')
)
$handoffArtifactPath = Get-FirstNonEmptyValue -Values @(
    Get-OptionalPropertyValue -Object $summary -Name 'handoff_artifact_path',
    (Join-Path $artifactRoot 'google-issue3-validation-handoff.json')
)
$refreshChainArtifactPath = Get-FirstNonEmptyValue -Values @(
    Get-OptionalPropertyValue -Object $summary -Name 'refresh_chain_artifact_path',
    (Join-Path $artifactRoot 'google-issue3-validation-handoff-chain-refresh.json')
)

$surfaceCheckStatus = Get-OptionalPropertyValue -Object $summary -Name 'surface_check_status'
$surfaceCheckError = Get-OptionalPropertyValue -Object $summary -Name 'surface_check_error'
$surfaceCheckArtifactPath = Get-OptionalPropertyValue -Object $summary -Name 'surface_check_artifact_path'
$surfaceCheckMissingPaths = @(Get-StringArray -Object $summary -Name 'surface_check_missing_paths')
$surfaceCheckMissingCount = Get-OptionalPropertyValue -Object $summary -Name 'surface_check_missing_count'
if ($null -eq $surfaceCheckMissingCount) {
    $surfaceCheckMissingCount = $surfaceCheckMissingPaths.Count
}
$phaseResults = @(Get-StringArray -Object $summary -Name 'phase_results')
$passedPhaseResults = @($phaseResults | Where-Object { $_ -and (Get-OptionalPropertyValue -Object $_ -Name 'status') -eq 'passed' })
$lastPassedPhaseResult = if ($passedPhaseResults.Count -gt 0) { $passedPhaseResults[-1] } else { $null }
$firstFailedPhase = Get-OptionalPropertyValue -Object $summary -Name 'first_failed_phase'
$firstFailedPhaseError = Get-OptionalPropertyValue -Object $summary -Name 'first_failed_phase_error'
$firstFailedPhaseLogPath = Get-OptionalPropertyValue -Object $summary -Name 'first_failed_phase_log_path'
$firstFailedPhasePrimaryJson = Get-OptionalPropertyValue -Object $summary -Name 'first_failed_phase_primary_json_artifact_path'
$manualInputPath = @(Get-StringArray -Object $summary -Name 'manual_input_path')
$manualFixtureReplayAvailable = $manualInputPath.Count -gt 0
$missingFixtureAssetAudit = @(Get-StringArray -Object $summary -Name 'missing_fixture_asset_audit')
$fixturesWithMissingAssets = @($missingFixtureAssetAudit | Where-Object { $_ -and (Get-OptionalPropertyValue -Object $_ -Name 'missing_asset_count') -gt 0 })
$fixtureAssetsMissing = $fixturesWithMissingAssets.Count -gt 0
$completed = Get-BoolValue -Object $summary -Name 'completed'

$missingSummaryContractFields = [System.Collections.Generic.List[string]]::new()
foreach ($fieldName in @(
    'artifact_root',
    'manifest_artifact_path',
    'guide_artifact_path',
    'boundary_artifact_path',
    'artifact_bundle_path',
    'handoff_artifact_path',
    'refresh_chain_artifact_path'
)) {
    if (-not (Test-HasProperty -Object $summary -Name $fieldName)) {
        $missingSummaryContractFields.Add($fieldName) | Out-Null
    }
}

$recommendedCommand = $recommendedRunnerCommand
$recommendedGuideCommand = $probeTriageCommand
$nextFocus = 'Keep the next replay on the earliest failing checkpoint before widening back out to attached HTML or live Google.'
$reason = 'The safe guide did not need to correct the saved issue #3 summary, so the normal recommended runner remains the source of truth.'

if ($missingSummaryContractFields.Count -gt 0) {
    $recommendedCommand = $artifactPathRepairCommand
    $recommendedGuideCommand = $summaryContractRepairCommand
    $nextFocus = 'Repair the saved summary contract first so older issue #3 artifacts can be reopened safely under strict mode.'
    $reason = 'The saved summary still omits one or more optional artifact-path fields that newer helpers expect to read directly.'
} elseif ($surfaceCheckStatus -and $surfaceCheckStatus -ne 'passed') {
    $recommendedCommand = $surfaceCheckCommand
    $recommendedGuideCommand = $summaryContractRepairCommand
    $nextFocus = 'Restore the recommended validation surface before spending time on headed runtime behavior.'
    if ([int]$surfaceCheckMissingCount -gt 0) {
        $reason = "The saved summary says the recommended validation surface check failed and still reports $surfaceCheckMissingCount missing path(s)."
    } else {
        $reason = 'The saved summary says the recommended validation surface check failed before the phase ladder could run.'
    }
} elseif ($fixtureAssetsMissing -and $firstFailedPhase -eq 'manual') {
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $manualFixtureReplayCommand
    $nextFocus = 'Restore the missing sibling assets for the saved Google-style manual fixtures before trusting the manual follow-up.'
    $reason = "The manual follow-up is still the first failing checkpoint, and $($fixturesWithMissingAssets.Count) fixture selection(s) reference missing local assets."
} elseif ($completed) {
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $probeTriageCommand
    $nextFocus = 'The bounded localhost ladder completed, so the next replay can widen to attached HTML or live Google evidence gathering.'
    $reason = 'The saved summary says every recommended phase passed.'
} else {
    switch ($firstFailedPhase) {
        'localhost' {
            $recommendedCommand = Get-PhaseReplayCommand 'localhost'
            $recommendedGuideCommand = $titleGuideCommand
            $nextFocus = 'Restore the localhost fixture baseline before looking at the more Google-shaped phases.'
            $reason = 'The earliest failure happened at the plain localhost checkpoint.'
        }
        'quick' {
            $recommendedCommand = Get-PhaseReplayCommand 'quick'
            $recommendedGuideCommand = $titleGuideCommand
            $nextFocus = 'Stay on the quick bounded title probe until focus and typed markers are stable.'
            $reason = 'The quick title-marker stage is the first failing checkpoint.'
        }
        'home' {
            $recommendedCommand = Get-PhaseReplayCommand 'home'
            $recommendedGuideCommand = $titleGuideCommand
            $nextFocus = 'Keep the investigation on the saved-home title path before widening to submit ordering or attached HTML.'
            $reason = 'The home checkpoint failed before the later submit-order phases had a chance to run.'
        }
        'homepage-fixture' {
            $recommendedCommand = Get-PhaseReplayCommand 'homepage-fixture'
            $recommendedGuideCommand = $titleGuideCommand
            $nextFocus = 'Fix the localhost homepage fixture behavior before trusting later Google-style checkpoints.'
            $reason = 'The dedicated homepage fixture phase is the first failing step in the saved ladder.'
        }
        'input-phase-localhost' {
            $recommendedCommand = Get-PhaseReplayCommand 'input-phase-localhost'
            $recommendedGuideCommand = $titleGuideCommand
            $nextFocus = 'Keep the replay on the bounded localhost input phase until typed text and focus stay stable.'
            $reason = 'The saved summary says the failure happened at the localhost input phase before the Enter-order checks.'
        }
        'submit-timing' {
            $recommendedCommand = Get-PhaseReplayCommand 'submit-timing'
            $recommendedGuideCommand = $submitGuideCommand
            $nextFocus = 'Inspect the reduced-home submit timing path before reopening broader headed input changes.'
            $reason = 'The reduced-home submit timing phase is the first failing checkpoint in the saved summary.'
        }
        'shared-enter-order' {
            $recommendedCommand = Get-PhaseReplayCommand 'shared-enter-order'
            $recommendedGuideCommand = $formGuideCommand
            $nextFocus = 'Stay on the shared Enter-order checkpoint until keydown, keypress, and submit ordering are proven.'
            $reason = 'The bounded shared Enter-order phase failed, so the next replay should stay on that ordering proof.'
        }
        'manual' {
            $recommendedCommand = $recommendedRunnerCommand
            $recommendedGuideCommand = if ($manualFixtureReplayAvailable) { $manualFixtureReplayCommand } else { $probeTriageCommand }
            $nextFocus = 'The bounded phases passed and the Google-style manual follow-up is now the narrowest failing step.'
            $reason = 'The manual follow-up was the first failing phase, so the next replay should preserve the saved fixture selection.'
        }
    }
}

$lastPassedPhaseName = if ($lastPassedPhaseResult) { Get-OptionalPropertyValue -Object $lastPassedPhaseResult -Name 'name' } else { $null }
$lastPassedPhaseLogPath = if ($lastPassedPhaseResult) { Get-OptionalPropertyValue -Object $lastPassedPhaseResult -Name 'log_path' } else { $null }
$lastPassedPhaseJson = if ($lastPassedPhaseResult) { Get-OptionalPropertyValue -Object $lastPassedPhaseResult -Name 'primary_json_artifact_path' } else { $null }

$report = [ordered]@{
    issue = 'Google issue #3 validation summary guide safe helper'
    purpose = 'Read the saved recommended-validation summary with optional-field guards so older issue #3 artifacts can still produce a bounded next-step recommendation under strict mode.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    artifact_root = $artifactRoot
    missing_summary_contract_fields = @($missingSummaryContractFields)
    manifest_artifact_path = $manifestArtifactPath
    guide_artifact_path = $guideArtifactPath
    boundary_artifact_path = $boundaryArtifactPath
    artifact_bundle_path = $artifactBundlePath
    handoff_artifact_path = $handoffArtifactPath
    refresh_chain_artifact_path = $refreshChainArtifactPath
    surface_check_status = $surfaceCheckStatus
    surface_check_error = $surfaceCheckError
    surface_check_artifact_path = $surfaceCheckArtifactPath
    surface_check_missing_count = [int]$surfaceCheckMissingCount
    surface_check_missing_paths = @($surfaceCheckMissingPaths)
    completed = [bool]$completed
    first_failed_phase = $firstFailedPhase
    first_failed_phase_error = $firstFailedPhaseError
    first_failed_phase_log_path = $firstFailedPhaseLogPath
    first_failed_phase_primary_json_artifact_path = $firstFailedPhasePrimaryJson
    first_failed_phase_replay_command = Get-PhaseReplayCommand $firstFailedPhase
    last_passed_phase = $lastPassedPhaseName
    last_passed_phase_log_path = $lastPassedPhaseLogPath
    last_passed_phase_primary_json_artifact_path = $lastPassedPhaseJson
    last_passed_phase_replay_command = Get-PhaseReplayCommand $lastPassedPhaseName
    manual_fixture_replay_available = [bool]$manualFixtureReplayAvailable
    manual_fixture_replay_command = if ($manualFixtureReplayAvailable) { $manualFixtureReplayCommand } else { $null }
    fixture_assets_missing = [bool]$fixtureAssetsMissing
    fixture_selection_missing_asset_count = $fixturesWithMissingAssets.Count
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    artifact_path_repair_command = $artifactPathRepairCommand
    summary_contract_repair_command = $summaryContractRepairCommand
    phase_boundary_command = $phaseBoundaryCommand
    manifest_guide_command = $manifestGuideCommand
    artifact_bundle_guide_command = $artifactBundleGuideCommand
    handoff_guide_command = $handoffGuideCommand
    refresh_status_guide_command = $refreshStatusGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    reason = $reason
    next_focus = $nextFocus
}

$report | ConvertTo-Json -Depth 6 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 validation summary guide safe helper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Completed: {0}" -f $report.completed)
if ($report.missing_summary_contract_fields.Count -gt 0) {
    Write-Host 'Missing summary contract fields:'
    foreach ($fieldName in $report.missing_summary_contract_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
Write-Host ("First fail: {0}" -f $(if ($report.first_failed_phase) { $report.first_failed_phase } else { 'none recorded' }))
if ($report.first_failed_phase_log_path) {
    Write-Host ("Fail log:   {0}" -f $report.first_failed_phase_log_path)
}
if ($report.last_passed_phase) {
    Write-Host ("Last pass:  {0}" -f $report.last_passed_phase)
}
if ($report.fixture_assets_missing) {
    Write-Host ("Fixture selections with missing assets: {0}" -f $report.fixture_selection_missing_asset_count)
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Run:    {0}" -f $report.recommended_command)
if ($report.recommended_guide_command) {
    Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
}
