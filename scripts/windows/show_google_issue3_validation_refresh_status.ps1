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

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json"
}
if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    throw "Issue #3 recommended validation summary not found: $SummaryPath"
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$artifactRoot = if (-not [string]::IsNullOrWhiteSpace($summary.artifact_root)) {
    $summary.artifact_root
} else {
    Split-Path -Parent $SummaryPath
}

$bundlePath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.artifact_bundle_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json'
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.handoff_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
$guidePath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.guide_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-guide.json'
$boundaryPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.boundary_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-phase-boundary.json'
$refreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.refresh_chain_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'

$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$bundleGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'

$bundleExists = Test-Path -LiteralPath $bundlePath -PathType Leaf
$bundleRecord = $null
$bundleError = if ($summary.artifact_bundle_error) { $summary.artifact_bundle_error } else { $null }
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
$refreshError = $null
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

$summaryRecordsHandoffArtifactPath = -not [string]::IsNullOrWhiteSpace($summary.handoff_artifact_path)
$summaryRecordsRefreshArtifactPath = -not [string]::IsNullOrWhiteSpace($summary.refresh_chain_artifact_path)
$refreshPointerUsesFallback = (-not $summaryRecordsRefreshArtifactPath) -and $refreshExists
$refreshReady = ($refreshStatus -eq 'refreshed')
$refreshNeeded = if ($refreshReady) {
    $false
} else {
    (-not $summaryRecordsHandoffArtifactPath) -or ($bundleStatus -ne 'complete')
}
$staleCrossReferenceDetected = if ($bundleRecord) { [bool]$bundleRecord.stale_cross_reference_detected } else { $false }
$staleSummaryArtifactDetected = if ($bundleRecord) { [bool]$bundleRecord.stale_summary_artifact_detected } else { $false }
$coreMissingCount = if ($bundleRecord -and $null -ne $bundleRecord.core_missing_count) { [int]$bundleRecord.core_missing_count } else { $null }
$phaseArtifactGapCount = if ($bundleRecord -and $null -ne $bundleRecord.phase_missing_artifact_count) { [int]$bundleRecord.phase_missing_artifact_count } else { $null }

$recommendedCommand = if ($refreshNeeded) { $refreshChainCommand } else { $handoffGuideCommand }
$recommendedGuideCommand = if ($refreshNeeded) { $bundleGuideCommand } else { $handoffGuideCommand }
$nextArtifactToOpen = if ($refreshNeeded) {
    if ($refreshExists) {
        $refreshPath
    } elseif ($bundleRecord -and $bundleRecord.next_artifact_to_open) {
        $bundleRecord.next_artifact_to_open
    } else {
        $SummaryPath
    }
} elseif (Test-Path -LiteralPath $handoffPath -PathType Leaf) {
    $handoffPath
} elseif ($bundleRecord -and $bundleRecord.next_artifact_to_open) {
    $bundleRecord.next_artifact_to_open
} else {
    $SummaryPath
}

$reason = if ($refreshReady) {
    'The saved refresh artifact already reports a stable helper chain for the current issue #3 summary, so the handoff guidance is ready to trust.'
} elseif ($refreshError) {
    'The saved refresh artifact exists but could not be read cleanly, so rerun the refresh helper before trusting the narrower handoff.'
} elseif ($refreshStatus -eq 'helper-failures') {
    'The saved refresh artifact says one or more summary-derived helpers still failed during the last repair pass.'
} elseif ($refreshStatus -eq 'manifest-missing') {
    'The saved refresh artifact says the helper chain reran, but the manifest is still missing and the recommended validation runner should be rerun.'
} elseif ($refreshStatus -eq 'bundle-incomplete') {
    'The saved refresh artifact says the helper chain reran, but the bundle audit still reports missing or stale artifacts.'
} elseif ($refreshStatus -eq 'handoff-incomplete') {
    'The saved refresh artifact says the helper chain reran, but the handoff artifact still lacks the next-artifact pointer needed for narrow replay.'
} elseif (-not $summaryRecordsRefreshArtifactPath -and $refreshExists) {
    'The current summary does not record its refresh artifact path yet, so this helper is using the fallback refresh location while keeping the runner and helper chain aligned.'
} elseif (-not $summaryRecordsHandoffArtifactPath) {
    'The current summary does not record its handoff artifact path yet, so refresh the saved helper chain before trusting older handoff links.'
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

$nextFocus = if ($refreshReady) {
    'Open the handoff helper and follow its next_artifact_to_open guidance for the narrowest current replay step.'
} elseif ($refreshExists) {
    'Inspect the saved refresh artifact first, then rerun the refresh helper if the helper chain still is not settled for the current summary.'
} elseif (-not $summaryRecordsRefreshArtifactPath) {
    'Keep the recommended runner and refresh-status helper aligned on the same saved refresh artifact before trusting older summary links.'
} elseif ($refreshNeeded) {
    'Repair or refresh the saved issue #3 helper chain first, then reopen the handoff artifact once the current summary, bundle, guide, boundary, and handoff outputs agree.'
} else {
    'Open the handoff helper and follow its next_artifact_to_open guidance for the narrowest current replay step.'
}

$status = if ($refreshReady) {
    'ready'
} elseif ($refreshNeeded) {
    'refresh-recommended'
} else {
    'ready'
}

$report = [ordered]@{
    issue = 'Google issue #3 validation refresh status'
    purpose = 'Tell the next Windows headed replay whether the saved issue #3 helper chain is fresh enough to trust or whether it should be refreshed first from the current recommended-validation summary.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    summary_generated_at_utc = $summary.generated_at_utc
    artifact_root = $artifactRoot
    status = $status
    completed = [bool]$summary.completed
    surface_check_status = $summary.surface_check_status
    first_failed_phase = $summary.first_failed_phase
    summary_records_handoff_artifact_path = [bool]$summaryRecordsHandoffArtifactPath
    summary_handoff_artifact_path = if ($summaryRecordsHandoffArtifactPath) { $summary.handoff_artifact_path } else { $null }
    summary_records_refresh_artifact_path = [bool]$summaryRecordsRefreshArtifactPath
    summary_refresh_artifact_path = if ($summaryRecordsRefreshArtifactPath) { $summary.refresh_chain_artifact_path } else { $null }
    summary_missing_refresh_pointer = [bool](-not $summaryRecordsRefreshArtifactPath)
    refresh_pointer_uses_fallback = [bool]$refreshPointerUsesFallback
    refresh_artifact_path = $refreshPath
    refresh_artifact_exists = [bool]$refreshExists
    refresh_status = $refreshStatus
    refresh_reason = if ($refreshRecord) { $refreshRecord.reason } else { $null }
    refresh_failed_step_count = if ($refreshRecord -and $null -ne $refreshRecord.failed_step_count) { [int]$refreshRecord.failed_step_count } else { $null }
    refresh_failed_step_names = if ($refreshRecord) { @($refreshRecord.failed_step_names) } else { @() }
    refresh_next_artifact_to_open = if ($refreshRecord) { $refreshRecord.next_artifact_to_open } else { $null }
    refresh_recommended_command = if ($refreshRecord) { $refreshRecord.recommended_command } else { $null }
    bundle_artifact_path = $bundlePath
    bundle_artifact_exists = [bool]$bundleExists
    bundle_status = $bundleStatus
    bundle_error = $bundleError
    handoff_artifact_path = $handoffPath
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
Write-Host ("Refresh:  {0}" -f $report.refresh_artifact_path)
Write-Host ("Bundle:   {0}" -f $report.bundle_artifact_path)
Write-Host ("Handoff:  {0}" -f $report.handoff_artifact_path)
Write-Host ("Status:   {0}" -f $report.status)
Write-Host ("Surface:  {0}" -f $report.surface_check_status)
Write-Host ("First fail:{0}" -f $(if ($report.first_failed_phase) { ' ' + $report.first_failed_phase } else { ' none' }))
Write-Host ("Refresh status: {0}" -f $report.refresh_status)
Write-Host ("Bundle status: {0}" -f $report.bundle_status)
Write-Host ("Summary handoff path recorded: {0}" -f $report.summary_records_handoff_artifact_path)
Write-Host ("Summary refresh path recorded: {0}" -f $report.summary_records_refresh_artifact_path)
if ($report.summary_refresh_artifact_path) {
    Write-Host ("Summary refresh path: {0}" -f $report.summary_refresh_artifact_path)
}
if ($report.refresh_reason) {
    Write-Host ("Refresh reason: {0}" -f $report.refresh_reason)
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
