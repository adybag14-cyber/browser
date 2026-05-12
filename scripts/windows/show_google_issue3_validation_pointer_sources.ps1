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

function Get-PointerSource {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$SummaryRecorded,
        [Parameter(Mandatory = $true)]
        [bool]$ManifestRecorded,
        [Parameter(Mandatory = $true)]
        [bool]$ArtifactExists
    )

    if ($SummaryRecorded) {
        return 'summary'
    }
    if ($ManifestRecorded) {
        return 'manifest'
    }
    if ($ArtifactExists) {
        return 'fallback'
    }

    return 'unavailable'
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
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
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
$refreshExists = Test-Path -LiteralPath $refreshPath -PathType Leaf
$refreshRecord = Read-ArtifactJson $refreshPath
$refreshMatchesSummary = $false
if ($refreshRecord -and -not [string]::IsNullOrWhiteSpace($refreshRecord.summary_path)) {
    $refreshMatchesSummary = ([System.IO.Path]::GetFullPath($refreshRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}
$refreshPointerSource = Get-PointerSource -SummaryRecorded $summaryRecordsRefreshArtifactPath -ManifestRecorded $manifestRecordsRefreshArtifactPath -ArtifactExists $refreshExists
$refreshArtifactUsable = [bool]($refreshExists -and $refreshMatchesSummary)

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
$handoffExists = Test-Path -LiteralPath $handoffPath -PathType Leaf
$handoffRecord = Read-ArtifactJson $handoffPath
$handoffMatchesSummary = $false
if ($handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffRecord.summary_path)) {
    $handoffMatchesSummary = ([System.IO.Path]::GetFullPath($handoffRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}
$handoffPointerSource = Get-PointerSource -SummaryRecorded $summaryRecordsHandoffArtifactPath -ManifestRecorded $manifestRecordsHandoffArtifactPath -ArtifactExists $handoffExists
$handoffArtifactUsable = [bool]($handoffExists -and $handoffMatchesSummary)

$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

$preferredStartHelper = if ($handoffArtifactUsable) {
    'handoff'
} elseif ($refreshArtifactUsable) {
    'refresh-status'
} else {
    'recommended-runner'
}

$recommendedCommand = if ($preferredStartHelper -eq 'handoff') {
    if ($handoffRecord -and $handoffRecord.recommended_command) {
        $handoffRecord.recommended_command
    } else {
        $handoffGuideCommand
    }
} elseif ($preferredStartHelper -eq 'refresh-status') {
    $refreshStatusCommand
} else {
    $recommendedRunnerCommand
}

$nextArtifactToOpen = if ($preferredStartHelper -eq 'handoff' -and $handoffRecord -and $handoffRecord.next_artifact_to_open) {
    $handoffRecord.next_artifact_to_open
} elseif ($preferredStartHelper -eq 'handoff') {
    $handoffPath
} elseif ($preferredStartHelper -eq 'refresh-status') {
    $refreshPath
} elseif ($manifestExists) {
    $manifestPath
} else {
    $SummaryPath
}

$staleHelperArtifactDetected = [bool](($refreshExists -and -not $refreshMatchesSummary) -or ($handoffExists -and -not $handoffMatchesSummary))
$reason = if ($staleHelperArtifactDetected) {
    'At least one saved helper artifact exists but belongs to a different recommended-validation summary, so this helper now falls back to the current summary or manifest instead of trusting stale replay guidance.'
} elseif ($refreshPointerSource -eq 'manifest' -or $handoffPointerSource -eq 'manifest') {
    'At least one current helper pointer is being recovered from the saved manifest instead of the summary, which is useful for replay but also a sign that the summary still needs pointer cleanup.'
} elseif ($refreshPointerSource -eq 'fallback' -or $handoffPointerSource -eq 'fallback') {
    'At least one current helper pointer is being inferred from the default artifact location instead of an explicit saved path, so the next replay should treat pointer repair as follow-up work.'
} elseif ($refreshPointerSource -eq 'summary' -and $handoffPointerSource -eq 'summary') {
    'Both helper pointers are coming directly from the saved summary, so the pointer chain is already explicit at the top level.'
} else {
    'The helper chain still has at least one missing saved pointer, so the next replay should expect some recovery work before trusting narrower guidance.'
}

$report = [ordered]@{
    issue = 'Google issue #3 validation pointer sources'
    purpose = 'Explain whether the saved refresh and handoff artifact pointers came from the summary, the manifest, or fallback discovery.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    refresh_pointer_source = $refreshPointerSource
    refresh_pointer_path = $refreshPath
    summary_records_refresh_artifact_path = [bool]$summaryRecordsRefreshArtifactPath
    summary_refresh_artifact_path = if ($summaryRecordsRefreshArtifactPath) { $configuredSummaryRefreshPath } else { $null }
    manifest_records_refresh_artifact_path = [bool]$manifestRecordsRefreshArtifactPath
    manifest_refresh_artifact_path = if ($manifestRecordsRefreshArtifactPath) { $configuredManifestRefreshPath } else { $null }
    refresh_pointer_fallback_used = [bool]($refreshPointerSource -eq 'fallback')
    refresh_artifact_exists = [bool]$refreshExists
    refresh_artifact_matches_summary = [bool]$refreshMatchesSummary
    refresh_artifact_usable = [bool]$refreshArtifactUsable
    refresh_artifact_summary_path = if ($refreshRecord) { $refreshRecord.summary_path } else { $null }
    handoff_pointer_source = $handoffPointerSource
    handoff_pointer_path = $handoffPath
    summary_records_handoff_artifact_path = [bool]$summaryRecordsHandoffArtifactPath
    summary_handoff_artifact_path = if ($summaryRecordsHandoffArtifactPath) { $configuredSummaryHandoffPath } else { $null }
    manifest_records_handoff_artifact_path = [bool]$manifestRecordsHandoffArtifactPath
    manifest_handoff_artifact_path = if ($manifestRecordsHandoffArtifactPath) { $configuredManifestHandoffPath } else { $null }
    handoff_pointer_fallback_used = [bool]($handoffPointerSource -eq 'fallback')
    handoff_artifact_exists = [bool]$handoffExists
    handoff_artifact_matches_summary = [bool]$handoffMatchesSummary
    handoff_artifact_usable = [bool]$handoffArtifactUsable
    handoff_artifact_summary_path = if ($handoffRecord) { $handoffRecord.summary_path } else { $null }
    stale_helper_artifact_detected = [bool]$staleHelperArtifactDetected
    preferred_start_helper = $preferredStartHelper
    next_artifact_to_open = $nextArtifactToOpen
    recommended_command = $recommendedCommand
    refresh_status_command = $refreshStatusCommand
    handoff_guide_command = $handoffGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    reason = $reason
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 validation pointer sources'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
Write-Host ("Refresh source: {0}" -f $report.refresh_pointer_source)
Write-Host ("Refresh path:   {0}" -f $report.refresh_pointer_path)
Write-Host ("Refresh exists: {0}" -f $report.refresh_artifact_exists)
Write-Host ("Refresh matches summary: {0}" -f $report.refresh_artifact_matches_summary)
Write-Host ("Refresh usable: {0}" -f $report.refresh_artifact_usable)
if ($report.summary_refresh_artifact_path) {
    Write-Host ("Summary refresh path: {0}" -f $report.summary_refresh_artifact_path)
}
if ($report.manifest_refresh_artifact_path) {
    Write-Host ("Manifest refresh path: {0}" -f $report.manifest_refresh_artifact_path)
}
Write-Host ("Handoff source: {0}" -f $report.handoff_pointer_source)
Write-Host ("Handoff path:   {0}" -f $report.handoff_pointer_path)
Write-Host ("Handoff exists: {0}" -f $report.handoff_artifact_exists)
Write-Host ("Handoff matches summary: {0}" -f $report.handoff_artifact_matches_summary)
Write-Host ("Handoff usable: {0}" -f $report.handoff_artifact_usable)
if ($report.summary_handoff_artifact_path) {
    Write-Host ("Summary handoff path: {0}" -f $report.summary_handoff_artifact_path)
}
if ($report.manifest_handoff_artifact_path) {
    Write-Host ("Manifest handoff path: {0}" -f $report.manifest_handoff_artifact_path)
}
Write-Host ("Stale helper artifacts detected: {0}" -f $report.stale_helper_artifact_detected)
Write-Host ("Preferred helper: {0}" -f $report.preferred_start_helper)
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
