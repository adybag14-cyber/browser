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

    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    } catch {
        return $null
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
$artifactRoot = if (-not [string]::IsNullOrWhiteSpace($summary.artifact_root)) {
    $summary.artifact_root
} else {
    Split-Path -Parent $SummaryPath
}

$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.manifest_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$manifestRecord = Read-ArtifactJson $manifestPath

$configuredSummaryRefreshPath = $summary.refresh_chain_artifact_path
$configuredManifestRefreshPath = if ($manifestRecord) { $manifestRecord.refresh_chain_artifact_path } else { $null }
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

$configuredSummaryHandoffPath = $summary.handoff_artifact_path
$configuredManifestHandoffPath = if ($manifestRecord) { $manifestRecord.handoff_artifact_path } else { $null }
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

$bundlePath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.artifact_bundle_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json'

$refreshRecord = Read-ArtifactJson $refreshPath
$handoffRecord = Read-ArtifactJson $handoffPath
$bundleRecord = Read-ArtifactJson $bundlePath

$refreshExists = Test-Path -LiteralPath $refreshPath -PathType Leaf
$handoffExists = Test-Path -LiteralPath $handoffPath -PathType Leaf
$bundleExists = Test-Path -LiteralPath $bundlePath -PathType Leaf

$refreshMatchesSummary = $false
if ($refreshRecord -and -not [string]::IsNullOrWhiteSpace($refreshRecord.summary_path)) {
    $refreshMatchesSummary = ([System.IO.Path]::GetFullPath($refreshRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}

$handoffMatchesSummary = $false
if ($handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffRecord.summary_path)) {
    $handoffMatchesSummary = ([System.IO.Path]::GetFullPath($handoffRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}

$bundleStatus = if ($bundleRecord -and $bundleRecord.status) {
    $bundleRecord.status
} elseif ($summary.artifact_bundle_error) {
    'helper-error'
} elseif ($bundleExists) {
    'present-unreadable'
} else {
    'missing'
}

$refreshStatus = if ($refreshRecord -and $refreshRecord.status) {
    $refreshRecord.status
} elseif ($summary.refresh_chain_artifact_error -or ($manifestRecord -and $manifestRecord.refresh_chain_artifact_error)) {
    'helper-error'
} elseif ($refreshExists) {
    'present-unreadable'
} else {
    'missing'
}

$handoffReady = [bool]($handoffRecord -and $handoffMatchesSummary -and -not [string]::IsNullOrWhiteSpace($handoffRecord.next_artifact_to_open))
$refreshPointerTrusted = [bool]($summaryRecordsRefreshArtifactPath -or $manifestRecordsRefreshArtifactPath -or $refreshMatchesSummary)
$handoffPointerTrusted = [bool]($summaryRecordsHandoffArtifactPath -or $manifestRecordsHandoffArtifactPath -or $handoffMatchesSummary)
$artifactChainCoherent = [bool]($bundleStatus -eq 'complete' -and $refreshStatus -eq 'refreshed' -and $refreshMatchesSummary -and $handoffMatchesSummary)
$pointerRepairNeeded = [bool](($refreshMatchesSummary -and -not $summaryRecordsRefreshArtifactPath) -or ($handoffMatchesSummary -and -not $summaryRecordsHandoffArtifactPath))

$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$bundleGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

$preferredStartHelper = if ($artifactChainCoherent -and $handoffReady) {
    'handoff'
} elseif ($refreshStatus -eq 'missing' -and -not $refreshExists) {
    'recommended-runner'
} else {
    'refresh-status'
}

$recommendedGuideCommand = if ($preferredStartHelper -eq 'handoff') {
    $handoffGuideCommand
} elseif ($preferredStartHelper -eq 'refresh-status') {
    $refreshStatusCommand
} else {
    $bundleGuideCommand
}

$recommendedCommand = if ($preferredStartHelper -eq 'handoff' -and $handoffRecord -and $handoffRecord.recommended_command) {
    $handoffRecord.recommended_command
} elseif ($preferredStartHelper -eq 'refresh-status' -and $refreshRecord -and $refreshRecord.recommended_command) {
    $refreshRecord.recommended_command
} elseif ($preferredStartHelper -eq 'refresh-status') {
    $refreshChainCommand
} else {
    $recommendedRunnerCommand
}

$nextArtifactToOpen = if ($preferredStartHelper -eq 'handoff' -and $handoffRecord -and $handoffRecord.next_artifact_to_open) {
    $handoffRecord.next_artifact_to_open
} elseif ($preferredStartHelper -eq 'refresh-status') {
    $refreshPath
} else {
    $SummaryPath
}

$reason = if ($artifactChainCoherent -and $handoffReady) {
    'The saved refresh, bundle, and handoff artifacts all align with the current summary, so the handoff helper is ready to drive the next narrow replay step.'
} elseif ($refreshStatus -eq 'missing' -and -not $refreshExists) {
    'No saved refresh artifact exists yet for the current summary, so rerun the recommended validator to rebuild the helper chain from scratch.'
} elseif ($bundleStatus -ne 'complete') {
    "The saved artifact bundle reports '$bundleStatus', so refresh and repair the helper chain before trusting narrower handoff guidance."
} elseif (-not $refreshMatchesSummary) {
    'The saved refresh artifact does not match the current summary path yet, so reopen refresh status and repair the helper chain first.'
} elseif (-not $handoffMatchesSummary) {
    'The saved handoff artifact does not match the current summary path yet, so reopen refresh status and repair the helper chain first.'
} elseif (-not $handoffReady) {
    'The saved handoff artifact still lacks a next-artifact pointer, so refresh status remains the safest starting point.'
} else {
    'The helper chain still needs a refresh-first pass before the next narrower replay.'
}

$nextFocus = if ($preferredStartHelper -eq 'handoff') {
    'Open the saved handoff helper and follow its next_artifact_to_open guidance.'
} elseif ($preferredStartHelper -eq 'refresh-status') {
    'Open refresh status first, then run the refresh-chain repair if the helper chain is still stale or incomplete.'
} else {
    'Rerun the recommended validation so the issue #3 helper chain is recreated from the current summary.'
}

$report = [ordered]@{
    issue = 'Google issue #3 refresh-chain readiness'
    purpose = 'Expose one compact readiness summary for the saved issue #3 refresh, bundle, and handoff helper chain.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    manifest_artifact_path = $manifestPath
    refresh_artifact_path = $refreshPath
    refresh_artifact_exists = [bool]$refreshExists
    refresh_status = $refreshStatus
    refresh_matches_summary = [bool]$refreshMatchesSummary
    refresh_pointer_trusted = [bool]$refreshPointerTrusted
    summary_records_refresh_artifact_path = [bool]$summaryRecordsRefreshArtifactPath
    manifest_records_refresh_artifact_path = [bool]$manifestRecordsRefreshArtifactPath
    handoff_artifact_path = $handoffPath
    handoff_artifact_exists = [bool]$handoffExists
    handoff_matches_summary = [bool]$handoffMatchesSummary
    handoff_pointer_trusted = [bool]$handoffPointerTrusted
    handoff_ready = [bool]$handoffReady
    summary_records_handoff_artifact_path = [bool]$summaryRecordsHandoffArtifactPath
    manifest_records_handoff_artifact_path = [bool]$manifestRecordsHandoffArtifactPath
    artifact_bundle_path = $bundlePath
    artifact_bundle_exists = [bool]$bundleExists
    artifact_bundle_status = $bundleStatus
    artifact_chain_coherent = [bool]$artifactChainCoherent
    pointer_repair_needed = [bool]$pointerRepairNeeded
    preferred_start_helper = $preferredStartHelper
    next_artifact_to_open = $nextArtifactToOpen
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    refresh_status_command = $refreshStatusCommand
    refresh_chain_command = $refreshChainCommand
    handoff_guide_command = $handoffGuideCommand
    bundle_guide_command = $bundleGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    reason = $reason
    next_focus = $nextFocus
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 refresh-chain readiness'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Refresh:   {0}" -f $report.refresh_artifact_path)
Write-Host ("Handoff:   {0}" -f $report.handoff_artifact_path)
Write-Host ("Bundle:    {0}" -f $report.artifact_bundle_path)
Write-Host ("Refresh status: {0}" -f $report.refresh_status)
Write-Host ("Refresh matches summary: {0}" -f $report.refresh_matches_summary)
Write-Host ("Refresh pointer trusted: {0}" -f $report.refresh_pointer_trusted)
Write-Host ("Handoff ready: {0}" -f $report.handoff_ready)
Write-Host ("Handoff matches summary: {0}" -f $report.handoff_matches_summary)
Write-Host ("Handoff pointer trusted: {0}" -f $report.handoff_pointer_trusted)
Write-Host ("Artifact bundle status: {0}" -f $report.artifact_bundle_status)
Write-Host ("Artifact chain coherent: {0}" -f $report.artifact_chain_coherent)
Write-Host ("Pointer repair needed: {0}" -f $report.pointer_repair_needed)
Write-Host ("Preferred helper: {0}" -f $report.preferred_start_helper)
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
