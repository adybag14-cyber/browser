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

function Test-JsonPropertyDefined {
    param(
        $Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($null -eq $Object) {
        return $false
    }

    return [bool]($Object.PSObject.Properties.Name -contains $Name)
}

function Test-PathMatches {
    param(
        [string]$RecordedPath,
        [string]$ExpectedPath
    )

    if ([string]::IsNullOrWhiteSpace($RecordedPath) -or [string]::IsNullOrWhiteSpace($ExpectedPath)) {
        return $false
    }

    return ([System.IO.Path]::GetFullPath($RecordedPath)).Equals(
        [System.IO.Path]::GetFullPath($ExpectedPath),
        [System.StringComparison]::OrdinalIgnoreCase
    )
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
$summaryRecordsRefreshPath = -not [string]::IsNullOrWhiteSpace($configuredSummaryRefreshPath)
$manifestRecordsRefreshPath = -not [string]::IsNullOrWhiteSpace($configuredManifestRefreshPath)
$configuredRefreshPath = if ($summaryRecordsRefreshPath) {
    $configuredSummaryRefreshPath
} elseif ($manifestRecordsRefreshPath) {
    $configuredManifestRefreshPath
} else {
    $null
}
$refreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredRefreshPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'

$configuredSummaryHandoffPath = $summary.handoff_artifact_path
$configuredManifestHandoffPath = if ($manifestRecord) { $manifestRecord.handoff_artifact_path } else { $null }
$summaryRecordsHandoffPath = -not [string]::IsNullOrWhiteSpace($configuredSummaryHandoffPath)
$manifestRecordsHandoffPath = -not [string]::IsNullOrWhiteSpace($configuredManifestHandoffPath)
$configuredHandoffPath = if ($summaryRecordsHandoffPath) {
    $configuredSummaryHandoffPath
} elseif ($manifestRecordsHandoffPath) {
    $configuredManifestHandoffPath
} else {
    $null
}
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredHandoffPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'

$summaryRefreshPathDefined = Test-JsonPropertyDefined -Object $summary -Name 'refresh_chain_artifact_path'
$summaryRefreshErrorDefined = Test-JsonPropertyDefined -Object $summary -Name 'refresh_chain_artifact_error'
$summaryHandoffPathDefined = Test-JsonPropertyDefined -Object $summary -Name 'handoff_artifact_path'
$summaryHandoffErrorDefined = Test-JsonPropertyDefined -Object $summary -Name 'handoff_artifact_error'
$manifestRefreshPathDefined = Test-JsonPropertyDefined -Object $manifestRecord -Name 'refresh_chain_artifact_path'
$manifestRefreshErrorDefined = Test-JsonPropertyDefined -Object $manifestRecord -Name 'refresh_chain_artifact_error'
$manifestHandoffPathDefined = Test-JsonPropertyDefined -Object $manifestRecord -Name 'handoff_artifact_path'
$manifestHandoffErrorDefined = Test-JsonPropertyDefined -Object $manifestRecord -Name 'handoff_artifact_error'

$summaryRefreshPathMatches = Test-PathMatches -RecordedPath $summary.refresh_chain_artifact_path -ExpectedPath $refreshPath
$manifestRefreshPathMatches = Test-PathMatches -RecordedPath $(if ($manifestRecord) { $manifestRecord.refresh_chain_artifact_path } else { $null }) -ExpectedPath $refreshPath
$summaryHandoffPathMatches = Test-PathMatches -RecordedPath $summary.handoff_artifact_path -ExpectedPath $handoffPath
$manifestHandoffPathMatches = Test-PathMatches -RecordedPath $(if ($manifestRecord) { $manifestRecord.handoff_artifact_path } else { $null }) -ExpectedPath $handoffPath

$refreshRecord = Read-ArtifactJson $refreshPath
$handoffRecord = Read-ArtifactJson $handoffPath
$refreshExists = Test-Path -LiteralPath $refreshPath -PathType Leaf
$handoffExists = Test-Path -LiteralPath $handoffPath -PathType Leaf
$refreshMatchesSummary = $false
if ($refreshRecord -and -not [string]::IsNullOrWhiteSpace($refreshRecord.summary_path)) {
    $refreshMatchesSummary = Test-PathMatches -RecordedPath $refreshRecord.summary_path -ExpectedPath $SummaryPath
}
$handoffMatchesSummary = $false
if ($handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffRecord.summary_path)) {
    $handoffMatchesSummary = Test-PathMatches -RecordedPath $handoffRecord.summary_path -ExpectedPath $SummaryPath
}

$refreshStatus = if ($refreshRecord -and $refreshRecord.status) {
    $refreshRecord.status
} elseif ($refreshExists) {
    'present-unreadable'
} else {
    'missing'
}
$handoffReady = [bool]($handoffExists -and $handoffMatchesSummary -and $handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffRecord.next_artifact_to_open))
$artifactChainCoherent = [bool]($manifestExists -and $refreshStatus -eq 'refreshed' -and $refreshMatchesSummary -and $handoffReady)

$runnerSelfContained = [bool](
    $summaryRefreshPathDefined -and
    $summaryRefreshErrorDefined -and
    $summaryHandoffPathDefined -and
    $summaryHandoffErrorDefined -and
    $manifestRefreshPathDefined -and
    $manifestRefreshErrorDefined -and
    $manifestHandoffPathDefined -and
    $manifestHandoffErrorDefined -and
    $summaryRefreshPathMatches -and
    $manifestRefreshPathMatches -and
    $summaryHandoffPathMatches -and
    $manifestHandoffPathMatches
)
$repairDependent = [bool]($artifactChainCoherent -and -not $runnerSelfContained)
$repairNeeded = [bool](-not $artifactChainCoherent)

$wiringGapCount = 0
foreach ($condition in @(
    $summaryRefreshPathDefined,
    $summaryRefreshErrorDefined,
    $summaryHandoffPathDefined,
    $summaryHandoffErrorDefined,
    $manifestRefreshPathDefined,
    $manifestRefreshErrorDefined,
    $manifestHandoffPathDefined,
    $manifestHandoffErrorDefined,
    $summaryRefreshPathMatches,
    $manifestRefreshPathMatches,
    $summaryHandoffPathMatches,
    $manifestHandoffPathMatches
)) {
    if (-not $condition) {
        $wiringGapCount += 1
    }
}

$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
$runnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

$state = 'repair-needed'
$reason = 'The saved helper chain is not coherent enough yet, so refresh repair still needs to run before the narrower issue #3 handoff is trustworthy.'
$nextFocus = 'Refresh the saved issue #3 helper chain first, then re-check whether the runner outputs are self-contained or still relying on later repair.'
$recommendedCommand = $refreshStatusCommand
$recommendedGuideCommand = $refreshStatusCommand
$nextArtifactToOpen = if ($refreshExists) { $refreshPath } else { $SummaryPath }

if ($runnerSelfContained -and $artifactChainCoherent) {
    $state = 'runner-self-contained'
    $reason = 'The saved summary and manifest already carry the refresh and handoff path/error wiring directly, and the saved refresh and handoff artifacts still match the current summary.'
    $nextFocus = 'Keep the next replay on the narrow handoff-first path, because the runner output is already self-contained.'
    $recommendedCommand = $handoffGuideCommand
    $recommendedGuideCommand = $handoffGuideCommand
    $nextArtifactToOpen = $handoffPath
} elseif ($repairDependent) {
    $state = 'repair-dependent-usable'
    $reason = 'The saved helper chain is usable, but the current summary or manifest still depends on later repair or fallback state to expose the refresh and handoff wiring cleanly.'
    $nextFocus = 'Use the current handoff helper for the next bounded replay, but keep the broader runner-side wiring fix on deck because the saved outputs are not yet self-contained.'
    $recommendedCommand = $handoffGuideCommand
    $recommendedGuideCommand = $handoffGuideCommand
    $nextArtifactToOpen = $handoffPath
}

$report = [ordered]@{
    issue = 'Google issue #3 runner repair dependency'
    purpose = 'Tell the next replay whether the saved issue #3 helper chain is runner-self-contained, merely usable because later repair filled wiring gaps, or still in need of refresh repair.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    refresh_artifact_path = $refreshPath
    refresh_artifact_exists = [bool]$refreshExists
    handoff_artifact_path = $handoffPath
    handoff_artifact_exists = [bool]$handoffExists
    refresh_status = $refreshStatus
    refresh_matches_summary = [bool]$refreshMatchesSummary
    handoff_matches_summary = [bool]$handoffMatchesSummary
    handoff_ready = [bool]$handoffReady
    summary_refresh_path_defined = [bool]$summaryRefreshPathDefined
    summary_refresh_error_defined = [bool]$summaryRefreshErrorDefined
    summary_handoff_path_defined = [bool]$summaryHandoffPathDefined
    summary_handoff_error_defined = [bool]$summaryHandoffErrorDefined
    manifest_refresh_path_defined = [bool]$manifestRefreshPathDefined
    manifest_refresh_error_defined = [bool]$manifestRefreshErrorDefined
    manifest_handoff_path_defined = [bool]$manifestHandoffPathDefined
    manifest_handoff_error_defined = [bool]$manifestHandoffErrorDefined
    summary_refresh_path_matches = [bool]$summaryRefreshPathMatches
    manifest_refresh_path_matches = [bool]$manifestRefreshPathMatches
    summary_handoff_path_matches = [bool]$summaryHandoffPathMatches
    manifest_handoff_path_matches = [bool]$manifestHandoffPathMatches
    artifact_chain_coherent = [bool]$artifactChainCoherent
    runner_self_contained = [bool]$runnerSelfContained
    repair_dependent = [bool]$repairDependent
    repair_needed = [bool]$repairNeeded
    wiring_gap_count = $wiringGapCount
    state = $state
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    refresh_status_command = $refreshStatusCommand
    refresh_chain_command = $refreshChainCommand
    broader_runner_command = $runnerCommand
    next_artifact_to_open = $nextArtifactToOpen
    reason = $reason
    next_focus = $nextFocus
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 runner repair dependency'
Write-Host ''
Write-Host ("Summary:  {0}" -f $report.summary_path)
Write-Host ("Manifest: {0}" -f $report.manifest_artifact_path)
Write-Host ("Refresh:  {0}" -f $report.refresh_artifact_path)
Write-Host ("Handoff:  {0}" -f $report.handoff_artifact_path)
Write-Host ("State:    {0}" -f $report.state)
Write-Host ("Coherent: {0}" -f $report.artifact_chain_coherent)
Write-Host ("Runner self-contained: {0}" -f $report.runner_self_contained)
Write-Host ("Repair-dependent: {0}" -f $report.repair_dependent)
Write-Host ("Repair needed: {0}" -f $report.repair_needed)
Write-Host ("Wiring gap count: {0}" -f $report.wiring_gap_count)
Write-Host ("Refresh status: {0}" -f $report.refresh_status)
Write-Host ("Refresh matches summary: {0}" -f $report.refresh_matches_summary)
Write-Host ("Handoff ready: {0}" -f $report.handoff_ready)
Write-Host ("Handoff matches summary: {0}" -f $report.handoff_matches_summary)
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
Write-Host ("Runner: {0}" -f $report.broader_runner_command)
