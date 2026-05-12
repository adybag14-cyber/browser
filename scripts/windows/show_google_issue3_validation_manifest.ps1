[CmdletBinding()]
param(
    [string]$ManifestPath,
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

function Read-ArtifactJson {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
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

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $ManifestPath) {
    $ManifestPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-manifest.json"
}
if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "Issue #3 validation manifest not found: $ManifestPath"
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$phaseResults = @($manifest.phase_results)
$manifestFirstFailedPhase = Get-OptionalPropertyValue -Object $manifest -Name 'first_failed_phase'
$failedPhase = @($phaseResults | Where-Object { $_.name -eq $manifestFirstFailedPhase } | Select-Object -First 1)
$manifestSurfaceCheckStatus = Get-OptionalPropertyValue -Object $manifest -Name 'surface_check_status'
$surfaceCheckFailed = $manifestSurfaceCheckStatus -ne 'passed'
$surfaceCheckCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_recommended_validation_surface.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'
$probeTriageCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_probe_triage.ps1'
$phaseBoundaryCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_phase_boundary.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$artifactBundleCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1'

$manifestGeneratedAtUtc = Get-OptionalPropertyValue -Object $manifest -Name 'generated_at_utc'
$manifestCompleted = [bool](Get-OptionalPropertyValue -Object $manifest -Name 'completed')
$manifestSurfaceCheckError = Get-OptionalPropertyValue -Object $manifest -Name 'surface_check_error'
$manifestSurfaceCheckArtifactPath = Get-OptionalPropertyValue -Object $manifest -Name 'surface_check_artifact_path'
$manifestSurfaceCheckMissingCount = Get-OptionalPropertyValue -Object $manifest -Name 'surface_check_missing_count'
$manifestSurfaceCheckMissingPaths = if (Test-HasProperty -Object $manifest -Name 'surface_check_missing_paths') { @($manifest.surface_check_missing_paths) } else { @() }
$manifestSummaryPath = Get-OptionalPropertyValue -Object $manifest -Name 'summary_path'
$manifestGuideArtifactPath = Get-OptionalPropertyValue -Object $manifest -Name 'guide_artifact_path'
$manifestBoundaryArtifactPath = Get-OptionalPropertyValue -Object $manifest -Name 'boundary_artifact_path'
$manifestArtifactBundlePath = Get-OptionalPropertyValue -Object $manifest -Name 'artifact_bundle_path'
$manifestArtifactBundleError = Get-OptionalPropertyValue -Object $manifest -Name 'artifact_bundle_error'
$manifestHandoffArtifactPath = Get-OptionalPropertyValue -Object $manifest -Name 'handoff_artifact_path'
$manifestHandoffArtifactError = Get-OptionalPropertyValue -Object $manifest -Name 'handoff_artifact_error'
$manifestRefreshArtifactPath = Get-OptionalPropertyValue -Object $manifest -Name 'refresh_chain_artifact_path'
$manifestRefreshArtifactError = Get-OptionalPropertyValue -Object $manifest -Name 'refresh_chain_artifact_error'
$manifestNextFocus = Get-OptionalPropertyValue -Object $manifest -Name 'next_focus'
$manifestRecommendedCommand = Get-OptionalPropertyValue -Object $manifest -Name 'recommended_command'
$manifestRecommendedGuideCommand = Get-OptionalPropertyValue -Object $manifest -Name 'recommended_guide_command'
$manifestPhaseArtifactRoot = Get-OptionalPropertyValue -Object $manifest -Name 'phase_artifact_root'
$manifestFirstFailedPhaseLogPath = Get-OptionalPropertyValue -Object $manifest -Name 'first_failed_phase_log_path'
$manifestFirstFailedPhasePrimaryJsonArtifactPath = Get-OptionalPropertyValue -Object $manifest -Name 'first_failed_phase_primary_json_artifact_path'
$manifestManualFixtureReplayCommand = Get-OptionalPropertyValue -Object $manifest -Name 'manual_fixture_replay_command'
$manifestManualFixtureReplayAvailable = [bool](Get-OptionalPropertyValue -Object $manifest -Name 'manual_fixture_replay_available')
$artifactRoot = if (-not [string]::IsNullOrWhiteSpace((Get-OptionalPropertyValue -Object $manifest -Name 'artifact_root'))) {
    Get-OptionalPropertyValue -Object $manifest -Name 'artifact_root'
} elseif ($manifestSummaryPath) {
    Split-Path -Parent $manifestSummaryPath
} else {
    Split-Path -Parent $ManifestPath
}

$summaryPath = $manifestSummaryPath
$summaryRecord = $null
$summaryArtifactError = $null
if (-not [string]::IsNullOrWhiteSpace($summaryPath) -and (Test-Path -LiteralPath $summaryPath -PathType Leaf)) {
    try {
        $summaryRecord = Read-ArtifactJson $summaryPath
    } catch {
        $summaryArtifactError = $_.Exception.Message
    }
} elseif (-not [string]::IsNullOrWhiteSpace($summaryPath)) {
    $summaryArtifactError = "Summary artifact not found: $summaryPath"
}

$artifactBundlePath = Resolve-ArtifactCandidatePath -ConfiguredPath $manifestArtifactBundlePath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json'
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $manifestHandoffArtifactPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
$configuredSummaryRefreshPath = Get-OptionalPropertyValue -Object $summaryRecord -Name 'refresh_chain_artifact_path'
$configuredManifestRefreshPath = $manifestRefreshArtifactPath
$summaryRecordsRefreshArtifactPath = ($summaryRecord -and -not [string]::IsNullOrWhiteSpace($configuredSummaryRefreshPath))
$manifestRecordsRefreshArtifactPath = -not [string]::IsNullOrWhiteSpace($configuredManifestRefreshPath)
$configuredRefreshPath = if ($summaryRecordsRefreshArtifactPath) {
    $configuredSummaryRefreshPath
} elseif ($manifestRecordsRefreshArtifactPath) {
    $configuredManifestRefreshPath
} else {
    $null
}
$refreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredRefreshPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'

$artifactBundleExists = Test-Path -LiteralPath $artifactBundlePath -PathType Leaf
$artifactBundleRecord = $null
$artifactBundleError = if (-not [string]::IsNullOrWhiteSpace($manifestArtifactBundleError)) { $manifestArtifactBundleError } else { $null }
if ($artifactBundleExists) {
    try {
        $artifactBundleRecord = Read-ArtifactJson $artifactBundlePath
    } catch {
        $artifactBundleError = $_.Exception.Message
    }
}
$artifactBundleStatusValue = Get-OptionalPropertyValue -Object $artifactBundleRecord -Name 'status'
$artifactBundleRecommendedCommandValue = Get-OptionalPropertyValue -Object $artifactBundleRecord -Name 'recommended_command'
$artifactBundleRecommendedGuideCommandValue = Get-OptionalPropertyValue -Object $artifactBundleRecord -Name 'recommended_guide_command'
$artifactBundleNextArtifactToOpenValue = Get-OptionalPropertyValue -Object $artifactBundleRecord -Name 'next_artifact_to_open'
$artifactBundleNextFocusValue = Get-OptionalPropertyValue -Object $artifactBundleRecord -Name 'next_focus'
$artifactBundleFirstMissingPathValue = Get-OptionalPropertyValue -Object $artifactBundleRecord -Name 'first_missing_path'
$artifactBundleStatus = if ($artifactBundleStatusValue) {
    $artifactBundleStatusValue
} elseif ($artifactBundleError) {
    'helper-error'
} elseif ($artifactBundleExists) {
    'present-unreadable'
} else {
    'missing'
}
$artifactBundleNeedsRepair = $artifactBundleStatus -ne 'complete'
$artifactBundleRecommendedCommand = if ($artifactBundleRecommendedCommandValue) {
    $artifactBundleRecommendedCommandValue
} else {
    $recommendedRunnerCommand
}
$artifactBundleGuideCommand = if ($artifactBundleRecommendedGuideCommandValue) {
    $artifactBundleRecommendedGuideCommandValue
} else {
    $summaryGuideCommand
}
$artifactBundleReason = if ($artifactBundleError) {
    'The runner recorded an artifact-bundle generation error, so reopen the current summary before trusting the saved helper chain.'
} elseif ($artifactBundleStatus -eq 'missing') {
    'The recommended runner should auto-save the artifact bundle, so reopen the current summary and refresh the handoff files before following older helper output.'
} elseif ($artifactBundleStatus -ne 'complete') {
    "The auto-saved artifact bundle reports '$artifactBundleStatus', so trust the current summary first and refresh the helper named under Run before following older handoff files."
} else {
    'The auto-saved artifact bundle is the saved completeness audit across the summary, manifest, guide, boundary, and per-phase artifacts.'
}

$refreshExists = Test-Path -LiteralPath $refreshPath -PathType Leaf
$refreshRecord = $null
$summaryRefreshArtifactError = Get-OptionalPropertyValue -Object $summaryRecord -Name 'refresh_chain_artifact_error'
$refreshArtifactError = if (-not [string]::IsNullOrWhiteSpace($summaryRefreshArtifactError)) {
    $summaryRefreshArtifactError
} elseif (-not [string]::IsNullOrWhiteSpace($manifestRefreshArtifactError)) {
    $manifestRefreshArtifactError
} else {
    $null
}
if ($refreshExists) {
    try {
        $refreshRecord = Read-ArtifactJson $refreshPath
    } catch {
        $refreshArtifactError = $_.Exception.Message
    }
}
$refreshStatusValue = Get-OptionalPropertyValue -Object $refreshRecord -Name 'status'
$refreshReasonValue = Get-OptionalPropertyValue -Object $refreshRecord -Name 'reason'
$refreshNextFocusValue = Get-OptionalPropertyValue -Object $refreshRecord -Name 'next_focus'
$refreshRecommendedCommandValue = Get-OptionalPropertyValue -Object $refreshRecord -Name 'recommended_command'
$refreshNextArtifactToOpenValue = Get-OptionalPropertyValue -Object $refreshRecord -Name 'next_artifact_to_open'
$refreshFailedStepCountValue = Get-OptionalPropertyValue -Object $refreshRecord -Name 'failed_step_count'
$refreshFailedStepNamesValue = if (Test-HasProperty -Object $refreshRecord -Name 'failed_step_names') { @($refreshRecord.failed_step_names) } else { @() }
$refreshSummaryPathValue = Get-OptionalPropertyValue -Object $refreshRecord -Name 'summary_path'
$refreshStatus = if ($refreshStatusValue) {
    $refreshStatusValue
} elseif ($refreshArtifactError) {
    'helper-error'
} elseif ($refreshExists) {
    'present-unreadable'
} else {
    'missing'
}
$refreshNeedsRepair = $refreshStatus -ne 'refreshed'
$refreshPointerUsesManifest = (-not $summaryRecordsRefreshArtifactPath) -and $manifestRecordsRefreshArtifactPath
$refreshPointerUsesFallback = (-not $summaryRecordsRefreshArtifactPath) -and (-not $manifestRecordsRefreshArtifactPath) -and $refreshExists
$refreshReason = if ($refreshReasonValue) {
    $refreshReasonValue
} elseif ($refreshArtifactError) {
    'The saved refresh artifact could not be read cleanly, so refresh the helper chain before trusting the handoff or manifest guidance.'
} elseif ($refreshStatus -eq 'missing') {
    'The saved refresh artifact is missing for the current summary, so generate it before trusting older handoff output.'
} elseif ($refreshStatus -ne 'refreshed') {
    "The saved refresh artifact reports '$refreshStatus', so the helper chain still needs repair before the narrower handoff is trustworthy."
} elseif ($refreshPointerUsesManifest) {
    'The current summary does not record its refresh artifact path yet, but this manifest already does, so this guide is using the saved manifest-backed refresh path while keeping the helper chain aligned.'
} elseif ($refreshPointerUsesFallback) {
    'The current summary does not record its refresh artifact path yet, so this manifest is using the fallback refresh location while keeping the helper chain aligned.'
} else {
    'The saved refresh artifact already reports a stable helper chain for the current issue #3 summary.'
}

$handoffExists = Test-Path -LiteralPath $handoffPath -PathType Leaf
$handoffRecord = $null
$handoffArtifactError = if (-not [string]::IsNullOrWhiteSpace($manifestHandoffArtifactError)) { $manifestHandoffArtifactError } else { $null }
if ($handoffExists) {
    try {
        $handoffRecord = Read-ArtifactJson $handoffPath
    } catch {
        $handoffArtifactError = $_.Exception.Message
    }
} elseif (-not $handoffArtifactError) {
    $handoffArtifactError = "Handoff artifact not found: $handoffPath"
}
$handoffNextArtifactToOpenValue = Get-OptionalPropertyValue -Object $handoffRecord -Name 'next_artifact_to_open'
$handoffReasonValue = Get-OptionalPropertyValue -Object $handoffRecord -Name 'reason'
$handoffRecommendedCommandValue = Get-OptionalPropertyValue -Object $handoffRecord -Name 'recommended_command'
$handoffRecommendedGuideCommandValue = Get-OptionalPropertyValue -Object $handoffRecord -Name 'recommended_guide_command'
$handoffNextFocusValue = Get-OptionalPropertyValue -Object $handoffRecord -Name 'next_focus'
$handoffReady = $handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffNextArtifactToOpenValue)
$handoffReason = if ($refreshNeedsRepair) {
    'The saved handoff artifact should not be trusted yet because the refresh artifact still says the helper chain needs repair.'
} elseif ($handoffArtifactError) {
    'The saved handoff artifact could not be read, so fall back to the manifest and boundary outputs until the handoff helper is refreshed.'
} elseif ($handoffReady) {
    'The saved handoff artifact already points at the current next artifact, so prefer its narrower replay guidance before widening back out.'
} else {
    'The handoff helper has not produced a reusable next-artifact pointer yet, so keep using the manifest and boundary outputs for this replay.'
}

$boundaryRecord = $null
$boundaryArtifactError = $null
if (-not [string]::IsNullOrWhiteSpace($manifestBoundaryArtifactPath) -and (Test-Path -LiteralPath $manifestBoundaryArtifactPath -PathType Leaf)) {
    try {
        $boundaryRecord = Get-Content -LiteralPath $manifestBoundaryArtifactPath -Raw | ConvertFrom-Json
    } catch {
        $boundaryArtifactError = $_.Exception.Message
    }
} elseif (-not [string]::IsNullOrWhiteSpace($manifestBoundaryArtifactPath)) {
    $boundaryArtifactError = "Boundary artifact not found: $manifestBoundaryArtifactPath"
}
$boundaryNextArtifactToOpenValue = Get-OptionalPropertyValue -Object $boundaryRecord -Name 'next_artifact_to_open'
$boundaryLastPassedPhaseValue = Get-OptionalPropertyValue -Object $boundaryRecord -Name 'last_passed_phase'
$boundaryFirstFailedPhaseValue = Get-OptionalPropertyValue -Object $boundaryRecord -Name 'first_failed_phase'

$openNextReason = $null
$openNext = if ($surfaceCheckFailed -and $manifestSurfaceCheckArtifactPath) {
    $openNextReason = 'surface-check-failed'
    $manifestSurfaceCheckArtifactPath
} elseif ($refreshNeedsRepair) {
    $openNextReason = 'refresh-artifact'
    if ($refreshExists) {
        $refreshPath
    } elseif ($artifactBundleNextArtifactToOpenValue) {
        $artifactBundleNextArtifactToOpenValue
    } elseif ($summaryPath) {
        $summaryPath
    } else {
        $ManifestPath
    }
} elseif ($artifactBundleNeedsRepair -and $manifestSummaryPath) {
    $openNextReason = 'artifact-bundle-needs-repair'
    $manifestSummaryPath
} elseif ($handoffReady) {
    $openNextReason = 'handoff-artifact'
    $handoffNextArtifactToOpenValue
} elseif ($boundaryNextArtifactToOpenValue) {
    $openNextReason = 'phase-boundary-artifact'
    $boundaryNextArtifactToOpenValue
} elseif ($manifestFirstFailedPhasePrimaryJsonArtifactPath) {
    $openNextReason = 'first-failed-phase-artifact'
    $manifestFirstFailedPhasePrimaryJsonArtifactPath
} elseif ($handoffExists) {
    $openNextReason = 'handoff-fallback'
    $handoffPath
} elseif ($manifestBoundaryArtifactPath) {
    $openNextReason = 'phase-boundary-fallback'
    $manifestBoundaryArtifactPath
} elseif ($manifestGuideArtifactPath) {
    $openNextReason = 'summary-guide-fallback'
    $manifestGuideArtifactPath
} else {
    $openNextReason = 'summary-fallback'
    $manifestSummaryPath
}

$nextFocus = if ($surfaceCheckFailed) {
    'Resolve the recommended-validation surface mismatch before replaying later issue #3 phases.'
} elseif ($refreshNeedsRepair) {
    if ($refreshNextFocusValue) {
        $refreshNextFocusValue
    } elseif ($refreshArtifactError) {
        'Repair or regenerate the saved refresh artifact before trusting the handoff or manifest guidance.'
    } elseif ($refreshStatus -eq 'missing') {
        'Generate the saved refresh artifact for the current summary before trusting older handoff output.'
    } else {
        'Refresh the saved issue #3 helper chain before trusting handoff, manifest, or boundary guidance.'
    }
} elseif ($artifactBundleNeedsRepair) {
    if ($artifactBundleNextFocusValue) {
        $artifactBundleNextFocusValue
    } else {
        'Refresh the saved artifact-bundle handoff so the manifest, guide, boundary, and per-phase artifacts all point at the current summary before widening back out.'
    }
} elseif ($handoffReady -and $handoffNextFocusValue) {
    $handoffNextFocusValue
} else {
    $manifestNextFocus
}

$recommendedCommand = if ($surfaceCheckFailed) {
    $surfaceCheckCommand
} elseif ($refreshNeedsRepair) {
    if ($refreshRecommendedCommandValue) {
        $refreshRecommendedCommandValue
    } else {
        $refreshChainCommand
    }
} elseif ($artifactBundleNeedsRepair) {
    $artifactBundleRecommendedCommand
} elseif ($handoffReady -and $handoffRecommendedCommandValue) {
    $handoffRecommendedCommandValue
} else {
    $manifestRecommendedCommand
}

$recommendedGuideCommand = if ($surfaceCheckFailed) {
    $summaryGuideCommand
} elseif ($refreshNeedsRepair) {
    $refreshStatusCommand
} elseif ($artifactBundleNeedsRepair) {
    $artifactBundleGuideCommand
} elseif ($handoffReady -and $handoffRecommendedGuideCommandValue) {
    $handoffRecommendedGuideCommandValue
} else {
    $manifestRecommendedGuideCommand
}

$report = [ordered]@{
    issue = 'Google issue #3 validation manifest guide'
    purpose = 'Open the saved manifest first, prefer manifest-backed or summary-backed refresh artifacts while the helper chain still needs repair, and only trust the narrower handoff output once the saved refresh state is coherent.'
    manifest_path = $ManifestPath
    generated_at_utc = $manifestGeneratedAtUtc
    completed = $manifestCompleted
    surface_check_status = $manifestSurfaceCheckStatus
    surface_check_error = $manifestSurfaceCheckError
    surface_check_command = $surfaceCheckCommand
    summary_guide_command = $summaryGuideCommand
    probe_triage_command = $probeTriageCommand
    phase_boundary_command = $phaseBoundaryCommand
    handoff_guide_command = $handoffGuideCommand
    refresh_status_command = $refreshStatusCommand
    refresh_chain_command = $refreshChainCommand
    broader_runner_command = $recommendedRunnerCommand
    surface_check_artifact_path = $manifestSurfaceCheckArtifactPath
    surface_check_missing_count = $manifestSurfaceCheckMissingCount
    surface_check_missing_paths = @($manifestSurfaceCheckMissingPaths)
    summary_path = $manifestSummaryPath
    summary_artifact_error = $summaryArtifactError
    guide_artifact_path = $manifestGuideArtifactPath
    boundary_artifact_path = $manifestBoundaryArtifactPath
    summary_records_refresh_artifact_path = [bool]$summaryRecordsRefreshArtifactPath
    summary_refresh_artifact_path = if ($summaryRecordsRefreshArtifactPath) { $configuredSummaryRefreshPath } else { $null }
    manifest_records_refresh_artifact_path = [bool]$manifestRecordsRefreshArtifactPath
    manifest_refresh_artifact_path = if ($manifestRecordsRefreshArtifactPath) { $configuredManifestRefreshPath } else { $null }
    refresh_pointer_uses_manifest = [bool]$refreshPointerUsesManifest
    refresh_pointer_uses_fallback = [bool]$refreshPointerUsesFallback
    refresh_artifact_path = $refreshPath
    refresh_artifact_exists = [bool]$refreshExists
    refresh_artifact_error = $refreshArtifactError
    refresh_status = $refreshStatus
    refresh_reason = $refreshReason
    refresh_next_artifact_to_open = $refreshNextArtifactToOpenValue
    refresh_recommended_command = $refreshRecommendedCommandValue
    refresh_failed_step_count = if ($null -ne $refreshFailedStepCountValue) { [int]$refreshFailedStepCountValue } else { $null }
    refresh_failed_step_names = @($refreshFailedStepNamesValue)
    handoff_artifact_path = $handoffPath
    handoff_artifact_exists = [bool]$handoffExists
    handoff_artifact_error = $handoffArtifactError
    handoff_reason = $handoffReason
    handoff_next_artifact_to_open = $handoffNextArtifactToOpenValue
    handoff_next_focus = $handoffNextFocusValue
    handoff_recommended_command = $handoffRecommendedCommandValue
    handoff_recommended_guide_command = $handoffRecommendedGuideCommandValue
    artifact_bundle_command = $artifactBundleCommand
    artifact_bundle_path = $artifactBundlePath
    artifact_bundle_exists = [bool]$artifactBundleExists
    artifact_bundle_status = $artifactBundleStatus
    artifact_bundle_error = $artifactBundleError
    artifact_bundle_reason = $artifactBundleReason
    artifact_bundle_next_artifact_to_open = $artifactBundleNextArtifactToOpenValue
    artifact_bundle_recommended_command = $artifactBundleRecommendedCommand
    artifact_bundle_recommended_guide_command = $artifactBundleGuideCommand
    artifact_bundle_first_missing_path = $artifactBundleFirstMissingPathValue
    boundary_artifact_error = $boundaryArtifactError
    phase_artifact_root = $manifestPhaseArtifactRoot
    first_failed_phase = $manifestFirstFailedPhase
    first_failed_phase_log_path = $manifestFirstFailedPhaseLogPath
    first_failed_phase_primary_json_artifact_path = $manifestFirstFailedPhasePrimaryJsonArtifactPath
    first_failed_phase_artifact_paths = if ($failedPhase.Count -gt 0) { @($failedPhase[0].artifact_paths) } else { @() }
    boundary_last_passed_phase = $boundaryLastPassedPhaseValue
    boundary_first_failed_phase = $boundaryFirstFailedPhaseValue
    boundary_next_artifact_to_open = $boundaryNextArtifactToOpenValue
    next_artifact_to_open = $openNext
    next_artifact_reason = $openNextReason
    next_focus = $nextFocus
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    manual_fixture_replay_command = $manifestManualFixtureReplayCommand
    manual_fixture_replay_available = $manifestManualFixtureReplayAvailable
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 validation manifest guide'
Write-Host ''
Write-Host ("Manifest:  {0}" -f $report.manifest_path)
Write-Host ("Generated: {0}" -f $report.generated_at_utc)
Write-Host ("Completed: {0}" -f $report.completed)
Write-Host ("Surface:   {0}" -f $report.surface_check_status)
if ($report.surface_check_error) {
    Write-Host ("Surface error: {0}" -f $report.surface_check_error)
}
if ($report.surface_check_artifact_path) {
    Write-Host ("Surface JSON: {0}" -f $report.surface_check_artifact_path)
}
if ($null -ne $report.surface_check_missing_count -and $report.surface_check_missing_count -gt 0) {
    Write-Host ("Surface missing: {0}" -f $report.surface_check_missing_count)
    foreach ($missingPath in $report.surface_check_missing_paths) {
        Write-Host ("- {0}" -f $missingPath)
    }
}
if ($report.summary_path) {
    Write-Host ("Summary JSON: {0}" -f $report.summary_path)
}
if ($report.summary_artifact_error) {
    Write-Host ("Summary error: {0}" -f $report.summary_artifact_error)
}
if ($report.guide_artifact_path) {
    Write-Host ("Guide JSON: {0}" -f $report.guide_artifact_path)
}
if ($report.boundary_artifact_path) {
    Write-Host ("Boundary JSON: {0}" -f $report.boundary_artifact_path)
}
Write-Host ("Summary cmd: {0}" -f $report.summary_guide_command)
Write-Host ("Triage cmd: {0}" -f $report.probe_triage_command)
Write-Host ("Boundary cmd: {0}" -f $report.phase_boundary_command)
Write-Host ("Refresh cmd: {0}" -f $report.refresh_status_command)
Write-Host ("Refresh run: {0}" -f $report.refresh_chain_command)
Write-Host ("Handoff cmd: {0}" -f $report.handoff_guide_command)
Write-Host ("Broader cmd: {0}" -f $report.broader_runner_command)
Write-Host ("Bundle cmd: {0}" -f $report.artifact_bundle_command)
Write-Host ("Bundle target: {0}" -f $report.artifact_bundle_path)
Write-Host ("Bundle exists: {0}" -f $report.artifact_bundle_exists)
Write-Host ("Bundle status: {0}" -f $report.artifact_bundle_status)
if ($report.artifact_bundle_error) {
    Write-Host ("Bundle error: {0}" -f $report.artifact_bundle_error)
}
if ($report.artifact_bundle_next_artifact_to_open) {
    Write-Host ("Bundle open: {0}" -f $report.artifact_bundle_next_artifact_to_open)
}
if ($report.artifact_bundle_first_missing_path) {
    Write-Host ("Bundle first missing: {0}" -f $report.artifact_bundle_first_missing_path)
}
Write-Host ("Refresh target: {0}" -f $report.refresh_artifact_path)
Write-Host ("Refresh exists: {0}" -f $report.refresh_artifact_exists)
Write-Host ("Refresh status: {0}" -f $report.refresh_status)
Write-Host ("Summary refresh path recorded: {0}" -f $report.summary_records_refresh_artifact_path)
Write-Host ("Manifest refresh path recorded: {0}" -f $report.manifest_records_refresh_artifact_path)
if ($report.summary_refresh_artifact_path) {
    Write-Host ("Summary refresh path: {0}" -f $report.summary_refresh_artifact_path)
}
if ($report.manifest_refresh_artifact_path) {
    Write-Host ("Manifest refresh path: {0}" -f $report.manifest_refresh_artifact_path)
}
if ($report.refresh_pointer_uses_manifest) {
    Write-Host 'Refresh pointer source: Manifest'
}
if ($report.refresh_pointer_uses_fallback) {
    Write-Host 'Refresh pointer fallback: True'
}
if ($report.refresh_artifact_error) {
    Write-Host ("Refresh error: {0}" -f $report.refresh_artifact_error)
}
if ($report.refresh_reason) {
    Write-Host ("Refresh note: {0}" -f $report.refresh_reason)
}
if ($null -ne $report.refresh_failed_step_count -and $report.refresh_failed_step_count -gt 0) {
    Write-Host ("Refresh failed steps: {0}" -f ($report.refresh_failed_step_names -join ', '))
}
if ($report.refresh_next_artifact_to_open) {
    Write-Host ("Refresh open: {0}" -f $report.refresh_next_artifact_to_open)
}
if ($report.refresh_recommended_command) {
    Write-Host ("Refresh run next: {0}" -f $report.refresh_recommended_command)
}
Write-Host ("Handoff target: {0}" -f $report.handoff_artifact_path)
Write-Host ("Handoff exists: {0}" -f $report.handoff_artifact_exists)
if ($report.handoff_artifact_error) {
    Write-Host ("Handoff error: {0}" -f $report.handoff_artifact_error)
}
if ($report.handoff_next_artifact_to_open) {
    Write-Host ("Handoff open: {0}" -f $report.handoff_next_artifact_to_open)
}
if ($report.handoff_recommended_command) {
    Write-Host ("Handoff run: {0}" -f $report.handoff_recommended_command)
}
if ($report.handoff_recommended_guide_command) {
    Write-Host ("Handoff guide: {0}" -f $report.handoff_recommended_guide_command)
}
if ($report.handoff_next_focus) {
    Write-Host ("Handoff focus: {0}" -f $report.handoff_next_focus)
}
if ($report.boundary_artifact_error) {
    Write-Host ("Boundary error: {0}" -f $report.boundary_artifact_error)
}
if ($report.phase_artifact_root) {
    Write-Host ("Phase root: {0}" -f $report.phase_artifact_root)
}
Write-Host ("First fail: {0}" -f $(if ($report.first_failed_phase) { $report.first_failed_phase } else { 'none' }))
if ($report.first_failed_phase_log_path) {
    Write-Host ("Log:        {0}" -f $report.first_failed_phase_log_path)
}
if ($report.first_failed_phase_primary_json_artifact_path) {
    Write-Host ("JSON:       {0}" -f $report.first_failed_phase_primary_json_artifact_path)
}
if ($report.first_failed_phase_artifact_paths.Count -gt 0) {
    Write-Host 'Artifacts:'
    foreach ($artifactPath in $report.first_failed_phase_artifact_paths) {
        Write-Host ("- {0}" -f $artifactPath)
    }
}
if ($report.boundary_last_passed_phase -or $report.boundary_first_failed_phase) {
    Write-Host ("Boundary last pass: {0}" -f $(if ($report.boundary_last_passed_phase) { $report.boundary_last_passed_phase } else { 'none' }))
    Write-Host ("Boundary first fail: {0}" -f $(if ($report.boundary_first_failed_phase) { $report.boundary_first_failed_phase } else { 'none' }))
}
Write-Host ''
Write-Host ("Open next: {0}" -f $report.next_artifact_to_open)
Write-Host ("Reason:    {0}" -f $report.next_artifact_reason)
Write-Host ("Focus:     {0}" -f $report.next_focus)
Write-Host ("Bundle note: {0}" -f $report.artifact_bundle_reason)
Write-Host ("Handoff note: {0}" -f $report.handoff_reason)
if ($report.surface_check_command) {
    Write-Host ("Surface cmd: {0}" -f $report.surface_check_command)
}
if ($report.recommended_command) {
    Write-Host ("Run next:  {0}" -f $report.recommended_command)
}
if ($report.recommended_guide_command) {
    Write-Host ("Guide:     {0}" -f $report.recommended_guide_command)
}
if ($report.manual_fixture_replay_available -and $report.manual_fixture_replay_command) {
    Write-Host ("Manual replay: {0}" -f $report.manual_fixture_replay_command)
}
