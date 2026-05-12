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

$configuredManifestPath = Get-OptionalPropertyValue -Object $summary -Name 'manifest_artifact_path'
$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredManifestPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
$manifestRecord = $null
$manifestError = $null
if ($manifestExists) {
    try {
        $manifestRecord = Read-ArtifactJson $manifestPath
    } catch {
        $manifestError = $_.Exception.Message
    }
}

$configuredBundlePath = Get-OptionalPropertyValue -Object $summary -Name 'artifact_bundle_path'
$configuredGuidePath = Get-OptionalPropertyValue -Object $summary -Name 'guide_artifact_path'
$configuredBoundaryPath = Get-OptionalPropertyValue -Object $summary -Name 'boundary_artifact_path'
$bundlePath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredBundlePath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json'
$guidePath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredGuidePath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-guide.json'
$boundaryPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredBoundaryPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-phase-boundary.json'
$configuredSummaryHandoffPath = if (Test-HasProperty -Object $summary -Name 'handoff_artifact_path') { $summary.handoff_artifact_path } else { $null }
$configuredManifestHandoffPath = if ($manifestRecord -and (Test-HasProperty -Object $manifestRecord -Name 'handoff_artifact_path')) { $manifestRecord.handoff_artifact_path } else { $null }
$summaryRecordsHandoffArtifactPath = -not [string]::IsNullOrWhiteSpace($configuredSummaryHandoffPath)
$manifestRecordsHandoffArtifactPath = -not [string]::IsNullOrWhiteSpace($configuredManifestHandoffPath)
$configuredHandoffPath = if ($summaryRecordsHandoffArtifactPath) {
    $configuredSummaryHandoffPath
} elseif ($manifestRecordsHandoffArtifactPath) {
    $configuredManifestHandoffPath
} else {
    $null
}
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredHandoffPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
$configuredSummaryRefreshPath = if (Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_path') { $summary.refresh_chain_artifact_path } else { $null }
$configuredManifestRefreshPath = if ($manifestRecord -and (Test-HasProperty -Object $manifestRecord -Name 'refresh_chain_artifact_path')) { $manifestRecord.refresh_chain_artifact_path } else { $null }
$summaryRecordsRefreshArtifactPath = -not [string]::IsNullOrWhiteSpace($configuredSummaryRefreshPath)
$manifestRecordsRefreshArtifactPath = -not [string]::IsNullOrWhiteSpace($configuredManifestRefreshPath)
$configuredRefreshPath = if ($summaryRecordsRefreshArtifactPath) {
    $configuredSummaryRefreshPath
} elseif ($manifestRecordsRefreshArtifactPath) {
    $configuredManifestRefreshPath
} else {
    $null
}
$refreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredRefreshPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'

$summaryHasRefreshArtifactErrorField = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_error'
$summaryHasHandoffArtifactErrorField = Test-HasProperty -Object $summary -Name 'handoff_artifact_error'
$manifestHasRefreshArtifactErrorField = Test-HasProperty -Object $manifestRecord -Name 'refresh_chain_artifact_error'
$manifestHasHandoffArtifactErrorField = Test-HasProperty -Object $manifestRecord -Name 'handoff_artifact_error'
$summaryRefreshArtifactErrorPopulated = [bool]($summaryHasRefreshArtifactErrorField -and -not [string]::IsNullOrWhiteSpace([string]$summary.refresh_chain_artifact_error))
$summaryHandoffArtifactErrorPopulated = [bool]($summaryHasHandoffArtifactErrorField -and -not [string]::IsNullOrWhiteSpace([string]$summary.handoff_artifact_error))
$manifestRefreshArtifactErrorPopulated = [bool]($manifestHasRefreshArtifactErrorField -and -not [string]::IsNullOrWhiteSpace([string]$manifestRecord.refresh_chain_artifact_error))
$manifestHandoffArtifactErrorPopulated = [bool]($manifestHasHandoffArtifactErrorField -and -not [string]::IsNullOrWhiteSpace([string]$manifestRecord.handoff_artifact_error))

$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$bundleGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'

$bundleExists = Test-Path -LiteralPath $bundlePath -PathType Leaf
$bundleRecord = $null
$bundleError = if ((Test-HasProperty -Object $summary -Name 'artifact_bundle_error') -and -not [string]::IsNullOrWhiteSpace([string]$summary.artifact_bundle_error)) { $summary.artifact_bundle_error } else { $null }
if ($bundleExists) {
    try {
        $bundleRecord = Read-ArtifactJson $bundlePath
    } catch {
        $bundleError = $_.Exception.Message
    }
}

$bundleStatus = if ($bundleRecord -and $bundleRecord.status) {
    $bundleRecord.status
} elseif ($bundleError) {
    'helper-error'
} elseif ($bundleExists) {
    'present-unreadable'
} else {
    'missing'
}

$refreshExists = Test-Path -LiteralPath $refreshPath -PathType Leaf
$refreshRecord = $null
$refreshError = if ($summaryRefreshArtifactErrorPopulated) {
    $summary.refresh_chain_artifact_error
} elseif ($manifestRefreshArtifactErrorPopulated) {
    $manifestRecord.refresh_chain_artifact_error
} else {
    $null
}
if ($refreshExists) {
    try {
        $refreshRecord = Read-ArtifactJson $refreshPath
    } catch {
        $refreshError = $_.Exception.Message
    }
}

$refreshStatus = if ($refreshRecord -and $refreshRecord.status) {
    $refreshRecord.status
} elseif ($refreshError) {
    'helper-error'
} elseif ($refreshExists) {
    'present-unreadable'
} else {
    'missing'
}
$refreshMatchesSummary = $false
if ($refreshRecord -and -not [string]::IsNullOrWhiteSpace($refreshRecord.summary_path)) {
    $refreshMatchesSummary = ([System.IO.Path]::GetFullPath($refreshRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}

$refreshPointerUsesFallback = (-not $summaryRecordsRefreshArtifactPath) -and (-not $manifestRecordsRefreshArtifactPath) -and $refreshExists
$refreshPointerUsesManifest = (-not $summaryRecordsRefreshArtifactPath) -and $manifestRecordsRefreshArtifactPath
$refreshReady = ($refreshStatus -eq 'refreshed') -and $refreshMatchesSummary
$refreshNeeded = -not $refreshReady

$handoffExists = Test-Path -LiteralPath $handoffPath -PathType Leaf
$handoffRecord = $null
$handoffError = if ($summaryHandoffArtifactErrorPopulated) {
    $summary.handoff_artifact_error
} elseif ($manifestHandoffArtifactErrorPopulated) {
    $manifestRecord.handoff_artifact_error
} else {
    $null
}
if ($handoffExists) {
    try {
        $handoffRecord = Read-ArtifactJson $handoffPath
    } catch {
        $handoffError = $_.Exception.Message
    }
}

$handoffMatchesSummary = $false
if ($handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffRecord.summary_path)) {
    $handoffMatchesSummary = ([System.IO.Path]::GetFullPath($handoffRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}
$handoffPointerUsesFallback = (-not $summaryRecordsHandoffArtifactPath) -and (-not $manifestRecordsHandoffArtifactPath) -and $handoffExists
$handoffPointerUsesManifest = (-not $summaryRecordsHandoffArtifactPath) -and $manifestRecordsHandoffArtifactPath
$handoffPointerTrusted = [bool]($summaryRecordsHandoffArtifactPath -or $manifestRecordsHandoffArtifactPath -or $handoffMatchesSummary)
$handoffReady = [bool]($handoffExists -and $handoffMatchesSummary -and $handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffRecord.next_artifact_to_open))
$handoffNeedsRepair = -not $handoffReady

$staleCrossReferenceDetected = if ($bundleRecord) { [bool]$bundleRecord.stale_cross_reference_detected } else { $false }
$staleSummaryArtifactDetected = if ($bundleRecord) { [bool]$bundleRecord.stale_summary_artifact_detected } else { $false }
$coreMissingCount = if ($bundleRecord -and $null -ne $bundleRecord.core_missing_count) { [int]$bundleRecord.core_missing_count } else { $null }
$phaseArtifactGapCount = if ($bundleRecord -and $null -ne $bundleRecord.phase_missing_artifact_count) { [int]$bundleRecord.phase_missing_artifact_count } else { $null }

$recommendedCommand = if ($refreshNeeded -or $handoffNeedsRepair) {
    if ($refreshRecord -and -not [string]::IsNullOrWhiteSpace($refreshRecord.recommended_command)) {
        $refreshRecord.recommended_command
    } else {
        $refreshChainCommand
    }
} else {
    $handoffGuideCommand
}
$recommendedGuideCommand = if ($refreshNeeded -or $handoffNeedsRepair) {
    if ($refreshRecord -and -not [string]::IsNullOrWhiteSpace($refreshRecord.recommended_guide_command)) {
        $refreshRecord.recommended_guide_command
    } else {
        $bundleGuideCommand
    }
} else {
    $handoffGuideCommand
}
$nextArtifactToOpen = if ($refreshNeeded) {
    if ($refreshRecord -and -not [string]::IsNullOrWhiteSpace($refreshRecord.next_artifact_to_open)) {
        $refreshRecord.next_artifact_to_open
    } elseif ($refreshExists) {
        $refreshPath
    } elseif ($bundleRecord -and $bundleRecord.next_artifact_to_open) {
        $bundleRecord.next_artifact_to_open
    } else {
        $SummaryPath
    }
} elseif ($handoffNeedsRepair) {
    if ($refreshRecord -and -not [string]::IsNullOrWhiteSpace($refreshRecord.next_artifact_to_open)) {
        $refreshRecord.next_artifact_to_open
    } elseif ($handoffExists) {
        $handoffPath
    } elseif ($refreshExists) {
        $refreshPath
    } elseif ($bundleRecord -and $bundleRecord.next_artifact_to_open) {
        $bundleRecord.next_artifact_to_open
    } else {
        $SummaryPath
    }
} elseif ($handoffRecord -and $handoffRecord.next_artifact_to_open) {
    $handoffRecord.next_artifact_to_open
} elseif ($handoffExists) {
    $handoffPath
} elseif ($bundleRecord -and $bundleRecord.next_artifact_to_open) {
    $bundleRecord.next_artifact_to_open
} else {
    $SummaryPath
}

$reason = if ($refreshReady -and $handoffReady) {
    'The saved refresh and handoff artifacts already report a stable helper chain for the current issue #3 summary, so the handoff guidance is ready to trust.'
} elseif ($manifestError) {
    'The saved manifest for the current issue #3 summary could not be read cleanly, so fall back to the summary-derived artifact paths and rerun refresh before trusting narrower handoff guidance.'
} elseif ($refreshError) {
    'The saved refresh artifact exists but could not be read cleanly, so rerun the refresh helper before trusting the narrower handoff.'
} elseif ($refreshRecord -and -not $refreshMatchesSummary) {
    'The saved refresh artifact points at a different recommended-validation summary, so regenerate the helper chain from the current summary before trusting the narrower handoff.'
} elseif ($refreshStatus -eq 'helper-failures') {
    'The saved refresh artifact says one or more summary-derived helpers still failed during the last repair pass.'
} elseif ($refreshStatus -eq 'manifest-missing') {
    'The saved refresh artifact says the helper chain reran, but the manifest is still missing and the recommended validation runner should be rerun.'
} elseif ($refreshStatus -eq 'bundle-incomplete') {
    'The saved refresh artifact says the helper chain reran, but the bundle audit still reports missing or stale artifacts.'
} elseif ($refreshStatus -eq 'handoff-incomplete') {
    'The saved refresh artifact says the helper chain reran, but the handoff artifact still lacks the next-artifact pointer needed for narrow replay.'
} elseif ($refreshPointerUsesManifest) {
    'The current summary omitted its refresh artifact path, but the saved manifest still records the matching refresh artifact for this summary, so this helper can stay aligned without falling back to a guessed location.'
} elseif ($refreshPointerUsesFallback) {
    'Neither the current summary nor the saved manifest records the refresh artifact path yet, so this helper is using the fallback refresh location while keeping the runner and helper chain aligned.'
} elseif ($handoffError) {
    'The saved handoff artifact exists but could not be read cleanly, so rerun the refresh helper before trusting the narrower replay handoff.'
} elseif ($handoffRecord -and -not $handoffMatchesSummary) {
    'The saved handoff artifact points at a different recommended-validation summary, so regenerate the helper chain from the current summary before trusting handoff-first replay.'
} elseif (-not $handoffExists) {
    'The saved handoff artifact is missing for the current summary, so rebuild the helper chain before trusting narrower replay guidance.'
} elseif ($handoffExists -and -not $handoffReady) {
    'The saved handoff artifact exists for the current summary, but it still lacks the next-artifact pointer needed for narrow replay.'
} elseif ($handoffPointerUsesManifest -and $handoffExists -and $handoffMatchesSummary) {
    'The current summary omitted its handoff artifact path, but the saved manifest still records the matching handoff artifact for this summary, so pointer repair is follow-up cleanup instead of a blocker.'
} elseif ($handoffPointerUsesFallback) {
    'Neither the current summary nor the saved manifest records the handoff artifact path yet, so this helper is trusting the matching saved handoff artifact at the default location until pointer repair catches up.'
} elseif ($bundleError) {
    'The saved artifact-bundle helper could not be read cleanly, so refresh the summary-derived helper chain before trusting the handoff.'
} elseif ($bundleStatus -eq 'missing') {
    'The artifact-bundle helper is missing for the current summary, so rebuild the helper chain before trusting narrower replay guidance.'
} elseif ($bundleStatus -eq 'stale-helper-artifacts') {
    'The artifact-bundle helper says one or more saved guide, boundary, or handoff artifacts are stale for the current summary.'
} elseif ($bundleStatus -eq 'missing-core-artifacts') {
    'The artifact-bundle helper says core saved artifacts are missing for the current summary.'
} elseif ($bundleStatus -eq 'missing-phase-artifacts') {
    'The artifact-bundle helper says one or more phase logs or JSON artifacts are missing from the saved replay chain.'
} elseif ($bundleStatus -ne 'complete') {
    "The artifact-bundle helper reports '$bundleStatus', so refresh the helper chain before trusting the next narrower replay handoff."
} else {
    'The saved helper chain looks coherent enough to open the handoff helper and stay on the current narrow replay path.'
}

$nextFocus = if ($refreshReady -and $handoffReady) {
    'Open the handoff helper and follow its next_artifact_to_open guidance for the narrowest current replay step.'
} elseif ($refreshRecord -and -not $refreshMatchesSummary) {
    'Refresh the saved issue #3 helper chain from the current summary first, then reopen the handoff artifact once the refresh record matches the same summary path.'
} elseif ($handoffRecord -and -not $handoffMatchesSummary) {
    'Refresh the saved issue #3 helper chain from the current summary first, then reopen the handoff artifact once the handoff record matches the same summary path.'
} elseif ($refreshExists -and $refreshNeeded) {
    'Inspect the saved refresh artifact first, then rerun the refresh helper if the helper chain still is not settled for the current summary.'
} elseif ($refreshPointerUsesManifest) {
    'Keep the recommended runner, saved manifest, and refresh-status helper aligned on the same saved refresh artifact while the summary-side pointer catches up.'
} elseif ($refreshPointerUsesFallback) {
    'Keep the recommended runner and refresh-status helper aligned on the same saved refresh artifact before trusting older summary links.'
} elseif ($handoffPointerUsesManifest) {
    'Keep the recommended runner, saved manifest, and handoff helper aligned on the same saved handoff artifact while the summary-side pointer catches up.'
} elseif ($handoffPointerUsesFallback) {
    'Keep the recommended runner and handoff helper aligned on the same saved handoff artifact while treating missing pointer fields as follow-up cleanup instead of a blocker.'
} elseif ($handoffExists -and -not $handoffReady) {
    'Repair or refresh the saved issue #3 handoff artifact first, then reopen it once it exposes the next bounded replay step.'
} elseif ($refreshNeeded -or $handoffNeedsRepair) {
    'Repair or refresh the saved issue #3 helper chain first, then reopen the handoff artifact once the current summary, bundle, guide, boundary, and handoff outputs agree.'
} else {
    'Open the handoff helper and follow its next_artifact_to_open guidance for the narrowest current replay step.'
}

$status = if ($refreshReady -and $handoffReady) {
    'ready'
} elseif ($refreshNeeded -or $handoffNeedsRepair) {
    'refresh-recommended'
} else {
    'ready'
}

$summaryGeneratedAtUtc = Get-OptionalPropertyValue -Object $summary -Name 'generated_at_utc'
$summaryCompleted = [bool](Get-OptionalPropertyValue -Object $summary -Name 'completed')
$surfaceCheckStatus = Get-OptionalPropertyValue -Object $summary -Name 'surface_check_status'
$firstFailedPhase = Get-OptionalPropertyValue -Object $summary -Name 'first_failed_phase'

$report = [ordered]@{
    issue = 'Google issue #3 validation refresh status'
    purpose = 'Tell the next Windows headed replay whether the saved issue #3 helper chain is fresh enough to trust or whether it should be refreshed first from the current recommended-validation summary.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    summary_generated_at_utc = $summaryGeneratedAtUtc
    artifact_root = $artifactRoot
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_error = $manifestError
    status = $status
    completed = $summaryCompleted
    surface_check_status = $surfaceCheckStatus
    first_failed_phase = $firstFailedPhase
    summary_has_refresh_artifact_error_field = [bool]$summaryHasRefreshArtifactErrorField
    summary_has_handoff_artifact_error_field = [bool]$summaryHasHandoffArtifactErrorField
    summary_refresh_artifact_error_populated = [bool]$summaryRefreshArtifactErrorPopulated
    summary_handoff_artifact_error_populated = [bool]$summaryHandoffArtifactErrorPopulated
    manifest_has_refresh_artifact_error_field = [bool]$manifestHasRefreshArtifactErrorField
    manifest_has_handoff_artifact_error_field = [bool]$manifestHasHandoffArtifactErrorField
    manifest_refresh_artifact_error_populated = [bool]$manifestRefreshArtifactErrorPopulated
    manifest_handoff_artifact_error_populated = [bool]$manifestHandoffArtifactErrorPopulated
    summary_records_handoff_artifact_path = [bool]$summaryRecordsHandoffArtifactPath
    summary_handoff_artifact_path = if ($summaryRecordsHandoffArtifactPath) { $configuredSummaryHandoffPath } else { $null }
    manifest_records_handoff_artifact_path = [bool]$manifestRecordsHandoffArtifactPath
    manifest_handoff_artifact_path = if ($manifestRecordsHandoffArtifactPath) { $configuredManifestHandoffPath } else { $null }
    handoff_pointer_uses_manifest = [bool]$handoffPointerUsesManifest
    handoff_pointer_uses_fallback = [bool]$handoffPointerUsesFallback
    summary_records_refresh_artifact_path = [bool]$summaryRecordsRefreshArtifactPath
    summary_refresh_artifact_path = if ($summaryRecordsRefreshArtifactPath) { $configuredSummaryRefreshPath } else { $null }
    manifest_records_refresh_artifact_path = [bool]$manifestRecordsRefreshArtifactPath
    manifest_refresh_artifact_path = if ($manifestRecordsRefreshArtifactPath) { $configuredManifestRefreshPath } else { $null }
    summary_missing_refresh_pointer = [bool](-not $summaryRecordsRefreshArtifactPath)
    refresh_pointer_uses_manifest = [bool]$refreshPointerUsesManifest
    refresh_pointer_uses_fallback = [bool]$refreshPointerUsesFallback
    refresh_artifact_path = $refreshPath
    refresh_artifact_exists = [bool]$refreshExists
    refresh_status = $refreshStatus
    refresh_matches_summary = [bool]$refreshMatchesSummary
    refresh_summary_path = if ($refreshRecord) { $refreshRecord.summary_path } else { $null }
    refresh_reason = if ($refreshRecord) { $refreshRecord.reason } else { $null }
    refresh_failed_step_count = if ($refreshRecord -and $null -ne $refreshRecord.failed_step_count) { [int]$refreshRecord.failed_step_count } else { $null }
    refresh_failed_step_names = if ($refreshRecord) { @($refreshRecord.failed_step_names) } else { @() }
    refresh_next_artifact_to_open = if ($refreshRecord) { $refreshRecord.next_artifact_to_open } else { $null }
    refresh_recommended_command = if ($refreshRecord) { $refreshRecord.recommended_command } else { $null }
    refresh_recommended_guide_command = if ($refreshRecord) { $refreshRecord.recommended_guide_command } else { $null }
    bundle_artifact_path = $bundlePath
    bundle_artifact_exists = [bool]$bundleExists
    bundle_status = $bundleStatus
    bundle_error = $bundleError
    handoff_artifact_path = $handoffPath
    handoff_artifact_exists = [bool]$handoffExists
    handoff_error = $handoffError
    handoff_matches_summary = [bool]$handoffMatchesSummary
    handoff_summary_path = if ($handoffRecord) { $handoffRecord.summary_path } else { $null }
    handoff_pointer_trusted = [bool]$handoffPointerTrusted
    handoff_ready = [bool]$handoffReady
    guide_artifact_path = $guidePath
    boundary_artifact_path = $boundaryPath
    stale_cross_reference_detected = [bool]$staleCrossReferenceDetected
    stale_cross_reference_labels = if ($bundleRecord) { @($bundleRecord.stale_cross_reference_labels) } else { @() }
    stale_summary_artifact_detected = [bool]$staleSummaryArtifactDetected
    stale_summary_artifact_labels = if ($bundleRecord) { @($bundleRecord.stale_summary_artifact_labels) } else { @() }
    core_missing_count = $coreMissingCount
    core_missing_labels = if ($bundleRecord) { @($bundleRecord.core_missing_labels) } else { @() }
    phase_missing_artifact_count = $phaseArtifactGapCount
    next_artifact_to_open = $nextArtifactToOpen
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    refresh_chain_command = $refreshChainCommand
    handoff_guide_command = $handoffGuideCommand
    bundle_guide_command = $bundleGuideCommand
    summary_guide_command = $summaryGuideCommand
    reason = $reason
    next_focus = $nextFocus
}

if ($Json) {
    $report | ConvertTo-Json -Depth 7
    exit 0
}

Write-Host 'Google issue #3 validation refresh status'
Write-Host ''
Write-Host ("Summary:  {0}" -f $report.summary_path)
Write-Host ("Manifest: {0}" -f $report.manifest_artifact_path)
Write-Host ("Refresh:  {0}" -f $report.refresh_artifact_path)
Write-Host ("Bundle:   {0}" -f $report.bundle_artifact_path)
Write-Host ("Handoff:  {0}" -f $report.handoff_artifact_path)
Write-Host ("Status:   {0}" -f $report.status)
Write-Host ("Surface:  {0}" -f $report.surface_check_status)
Write-Host ("First fail:{0}" -f $(if ($report.first_failed_phase) { ' ' + $report.first_failed_phase } else { ' none' }))
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
if ($report.manifest_artifact_error) {
    Write-Host ("Manifest error: {0}" -f $report.manifest_artifact_error)
}
Write-Host ("Refresh status: {0}" -f $report.refresh_status)
Write-Host ("Refresh matches summary: {0}" -f $report.refresh_matches_summary)
if ($report.refresh_summary_path) {
    Write-Host ("Refresh summary path: {0}" -f $report.refresh_summary_path)
}
Write-Host ("Bundle status: {0}" -f $report.bundle_status)
Write-Host ("Handoff exists: {0}" -f $report.handoff_artifact_exists)
Write-Host ("Handoff matches summary: {0}" -f $report.handoff_matches_summary)
Write-Host ("Handoff pointer trusted: {0}" -f $report.handoff_pointer_trusted)
Write-Host ("Handoff ready: {0}" -f $report.handoff_ready)
if ($report.handoff_summary_path) {
    Write-Host ("Handoff summary path: {0}" -f $report.handoff_summary_path)
}
Write-Host ("Summary refresh error field recorded: {0}" -f $report.summary_has_refresh_artifact_error_field)
Write-Host ("Summary handoff error field recorded: {0}" -f $report.summary_has_handoff_artifact_error_field)
Write-Host ("Summary refresh error populated: {0}" -f $report.summary_refresh_artifact_error_populated)
Write-Host ("Summary handoff error populated: {0}" -f $report.summary_handoff_artifact_error_populated)
Write-Host ("Manifest refresh error field recorded: {0}" -f $report.manifest_has_refresh_artifact_error_field)
Write-Host ("Manifest handoff error field recorded: {0}" -f $report.manifest_has_handoff_artifact_error_field)
Write-Host ("Manifest refresh error populated: {0}" -f $report.manifest_refresh_artifact_error_populated)
Write-Host ("Manifest handoff error populated: {0}" -f $report.manifest_handoff_artifact_error_populated)
Write-Host ("Summary handoff path recorded: {0}" -f $report.summary_records_handoff_artifact_path)
Write-Host ("Manifest handoff path recorded: {0}" -f $report.manifest_records_handoff_artifact_path)
if ($report.summary_handoff_artifact_path) {
    Write-Host ("Summary handoff path: {0}" -f $report.summary_handoff_artifact_path)
}
if ($report.manifest_handoff_artifact_path) {
    Write-Host ("Manifest handoff path: {0}" -f $report.manifest_handoff_artifact_path)
}
if ($report.handoff_pointer_uses_manifest) {
    Write-Host 'Handoff pointer source: Manifest'
}
if ($report.handoff_pointer_uses_fallback) {
    Write-Host 'Handoff pointer fallback: True'
}
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
if ($report.refresh_reason) {
    Write-Host ("Refresh reason: {0}" -f $report.refresh_reason)
}
if ($report.refresh_recommended_command) {
    Write-Host ("Refresh recommended command: {0}" -f $report.refresh_recommended_command)
}
if ($report.refresh_recommended_guide_command) {
    Write-Host ("Refresh recommended guide: {0}" -f $report.refresh_recommended_guide_command)
}
if ($report.handoff_error) {
    Write-Host ("Handoff error: {0}" -f $report.handoff_error)
}
if ($null -ne $report.refresh_failed_step_count -and $report.refresh_failed_step_count -gt 0) {
    Write-Host ("Refresh failed steps: {0}" -f ($report.refresh_failed_step_names -join ', '))
}
if ($report.bundle_error) {
    Write-Host ("Bundle error: {0}" -f $report.bundle_error)
}
if ($report.stale_cross_reference_detected) {
    Write-Host ("Stale cross-references: {0}" -f ($report.stale_cross_reference_labels -join ', '))
}
if ($report.stale_summary_artifact_detected) {
    Write-Host ("Stale summary helpers: {0}" -f ($report.stale_summary_artifact_labels -join ', '))
}
if ($null -ne $report.core_missing_count -and $report.core_missing_count -gt 0) {
    Write-Host ("Core artifacts missing: {0}" -f $report.core_missing_count)
}
if ($null -ne $report.phase_missing_artifact_count -and $report.phase_missing_artifact_count -gt 0) {
    Write-Host ("Phase artifact gaps: {0}" -f $report.phase_missing_artifact_count)
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
Write-Host ("Bundle cmd:  {0}" -f $report.bundle_guide_command)
Write-Host ("Summary cmd: {0}" -f $report.summary_guide_command)
Write-Host ("Refresh: {0}" -f $report.refresh_chain_command)
Write-Host ("Handoff: {0}" -f $report.handoff_guide_command)
