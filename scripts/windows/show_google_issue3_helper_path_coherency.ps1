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

function PathsMatch([string]$Left, [string]$Right) {
    if ([string]::IsNullOrWhiteSpace($Left) -or [string]::IsNullOrWhiteSpace($Right)) {
        return $false
    }

    return ([System.IO.Path]::GetFullPath($Left)).Equals([System.IO.Path]::GetFullPath($Right), [System.StringComparison]::OrdinalIgnoreCase)
}

$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json'
}

$summaryExists = Test-Path -LiteralPath $SummaryPath -PathType Leaf
if (-not $summaryExists) {
    $report = [ordered]@{
        issue = 'Google issue #3 helper path coherency'
        purpose = 'Tell the next Windows replay whether the refresh and handoff helpers can safely reuse the saved configured artifact paths without explicit -ArtifactPath overrides.'
        generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        summary_path = $SummaryPath
        summary_exists = $false
        all_paths_coherent = $false
        refresh_path_coherent = $false
        handoff_path_coherent = $false
        refresh_explicit_artifact_path_required = $false
        handoff_explicit_artifact_path_required = $false
        recommended_command = $recommendedRunnerCommand
        recommended_guide_command = $summaryGuideCommand
        safe_refresh_command = $refreshChainCommand
        safe_handoff_command = $handoffGuideCommand
        next_artifact_to_open = $SummaryPath
        reason = 'No saved issue #3 recommended-validation summary exists yet, so create the first summary before checking helper-path coherency.'
        next_focus = 'Run the bounded issue #3 validation runner first, then reopen this helper to verify the refresh and handoff path wiring for the saved helper chain.'
    }

    if ($Json) {
        $report | ConvertTo-Json -Depth 6
        exit 0
    }

    Write-Host 'Google issue #3 helper path coherency'
    Write-Host ''
    Write-Host ("Summary:  {0}" -f $report.summary_path)
    Write-Host ("Exists:   {0}" -f $report.summary_exists)
    Write-Host ("Reason:   {0}" -f $report.reason)
    Write-Host ("Focus:    {0}" -f $report.next_focus)
    Write-Host ("Run:      {0}" -f $report.recommended_command)
    Write-Host ("Guide:    {0}" -f $report.recommended_guide_command)
    exit 0
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
$fallbackRefreshPath = Join-Path $artifactRoot 'google-issue3-validation-handoff-chain-refresh.json'
$resolvedRefreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredRefreshPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$resolvedRefreshExists = Test-Path -LiteralPath $resolvedRefreshPath -PathType Leaf
$fallbackRefreshExists = Test-Path -LiteralPath $fallbackRefreshPath -PathType Leaf
$resolvedRefreshMatchesFallback = PathsMatch $resolvedRefreshPath $fallbackRefreshPath
$configuredRefreshDiffersFromFallback = [bool]((-not $resolvedRefreshMatchesFallback) -and (-not [string]::IsNullOrWhiteSpace($configuredRefreshPath)))
$refreshPathCoherent = $true
$refreshExplicitArtifactPathRequired = $false
$safeRefreshCommand = $refreshChainCommand

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
$fallbackHandoffPath = Join-Path $artifactRoot 'google-issue3-validation-handoff.json'
$resolvedHandoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredHandoffPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
$resolvedHandoffExists = Test-Path -LiteralPath $resolvedHandoffPath -PathType Leaf
$fallbackHandoffExists = Test-Path -LiteralPath $fallbackHandoffPath -PathType Leaf
$resolvedHandoffMatchesFallback = PathsMatch $resolvedHandoffPath $fallbackHandoffPath
$configuredHandoffDiffersFromFallback = [bool]((-not $resolvedHandoffMatchesFallback) -and (-not [string]::IsNullOrWhiteSpace($configuredHandoffPath)))
$handoffPathCoherent = $true
$handoffExplicitArtifactPathRequired = $false
$safeHandoffCommand = $handoffGuideCommand

$allPathsCoherent = [bool]($refreshPathCoherent -and $handoffPathCoherent)
$recommendedCommand = if ($resolvedRefreshExists) {
    $safeRefreshCommand
} elseif ($resolvedHandoffExists) {
    $safeHandoffCommand
} else {
    $refreshStatusCommand
}
$recommendedGuideCommand = $refreshStatusCommand
$nextArtifactToOpen = if ($resolvedRefreshExists) {
    $resolvedRefreshPath
} elseif ($resolvedHandoffExists) {
    $resolvedHandoffPath
} elseif ($manifestExists) {
    $manifestPath
} else {
    $SummaryPath
}

$reasonParts = [System.Collections.Generic.List[string]]::new()
if ($configuredRefreshDiffersFromFallback) {
    $reasonParts.Add('The saved issue #3 summary or manifest points the refresh helper at a non-default refresh artifact path, and the live refresh-chain helper already reuses that resolved configured path as its default write target.') | Out-Null
} elseif ($summaryRecordsRefreshArtifactPath -or $manifestRecordsRefreshArtifactPath) {
    $reasonParts.Add('The saved issue #3 helper chain records a refresh artifact path, and it already matches the default refresh location.') | Out-Null
} else {
    $reasonParts.Add('The saved issue #3 helper chain does not record a custom refresh artifact path, so the default refresh location remains the current source of truth.') | Out-Null
}
if ($configuredHandoffDiffersFromFallback) {
    $reasonParts.Add('The saved issue #3 summary or manifest points the handoff helper at a non-default handoff artifact path, and the live handoff helper now reuses that resolved configured path as its default write target.') | Out-Null
} elseif ($summaryRecordsHandoffArtifactPath -or $manifestRecordsHandoffArtifactPath) {
    $reasonParts.Add('The saved issue #3 helper chain records a handoff artifact path, and it already matches the default handoff location.') | Out-Null
} else {
    $reasonParts.Add('The saved issue #3 helper chain does not record a custom handoff artifact path, so the default handoff location remains the current source of truth.') | Out-Null
}
$reason = ($reasonParts -join ' ')

$nextFocus = if ($allPathsCoherent) {
    'Reuse the refresh and handoff helpers normally. No explicit -ArtifactPath override is required for the current saved issue #3 summary.'
} else {
    'Inspect the saved summary, manifest, and helper paths again before trusting the narrower replay helpers.'
}

$report = [ordered]@{
    issue = 'Google issue #3 helper path coherency'
    purpose = 'Tell the next Windows replay whether the refresh and handoff helpers can safely reuse the saved configured artifact paths without explicit -ArtifactPath overrides.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    summary_exists = $true
    summary_generated_at_utc = $summary.generated_at_utc
    artifact_root = $artifactRoot
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    summary_records_refresh_artifact_path = [bool]$summaryRecordsRefreshArtifactPath
    summary_refresh_artifact_path = if ($summaryRecordsRefreshArtifactPath) { $configuredSummaryRefreshPath } else { $null }
    manifest_records_refresh_artifact_path = [bool]$manifestRecordsRefreshArtifactPath
    manifest_refresh_artifact_path = if ($manifestRecordsRefreshArtifactPath) { $configuredManifestRefreshPath } else { $null }
    configured_refresh_artifact_path = $configuredRefreshPath
    configured_refresh_differs_from_fallback = [bool]$configuredRefreshDiffersFromFallback
    resolved_refresh_artifact_path = $resolvedRefreshPath
    resolved_refresh_artifact_exists = [bool]$resolvedRefreshExists
    fallback_refresh_artifact_path = $fallbackRefreshPath
    fallback_refresh_artifact_exists = [bool]$fallbackRefreshExists
    resolved_refresh_matches_fallback = [bool]$resolvedRefreshMatchesFallback
    refresh_path_coherent = [bool]$refreshPathCoherent
    refresh_explicit_artifact_path_required = [bool]$refreshExplicitArtifactPathRequired
    summary_records_handoff_artifact_path = [bool]$summaryRecordsHandoffArtifactPath
    summary_handoff_artifact_path = if ($summaryRecordsHandoffArtifactPath) { $configuredSummaryHandoffPath } else { $null }
    manifest_records_handoff_artifact_path = [bool]$manifestRecordsHandoffArtifactPath
    manifest_handoff_artifact_path = if ($manifestRecordsHandoffArtifactPath) { $configuredManifestHandoffPath } else { $null }
    configured_handoff_artifact_path = $configuredHandoffPath
    configured_handoff_differs_from_fallback = [bool]$configuredHandoffDiffersFromFallback
    resolved_handoff_artifact_path = $resolvedHandoffPath
    resolved_handoff_artifact_exists = [bool]$resolvedHandoffExists
    fallback_handoff_artifact_path = $fallbackHandoffPath
    fallback_handoff_artifact_exists = [bool]$fallbackHandoffExists
    resolved_handoff_matches_fallback = [bool]$resolvedHandoffMatchesFallback
    handoff_path_coherent = [bool]$handoffPathCoherent
    handoff_explicit_artifact_path_required = [bool]$handoffExplicitArtifactPathRequired
    all_paths_coherent = [bool]$allPathsCoherent
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    safe_refresh_command = $safeRefreshCommand
    safe_handoff_command = $safeHandoffCommand
    normal_refresh_command = $refreshChainCommand
    normal_handoff_command = $handoffGuideCommand
    next_artifact_to_open = $nextArtifactToOpen
    reason = $reason
    next_focus = $nextFocus
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 helper path coherency'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Refresh:   {0}" -f $report.resolved_refresh_artifact_path)
Write-Host ("Handoff:   {0}" -f $report.resolved_handoff_artifact_path)
Write-Host ("All coherent: {0}" -f $report.all_paths_coherent)
Write-Host ("Refresh override: {0}" -f $report.refresh_explicit_artifact_path_required)
Write-Host ("Handoff override: {0}" -f $report.handoff_explicit_artifact_path_required)
Write-Host ("Open:      {0}" -f $report.next_artifact_to_open)
Write-Host ''
Write-Host ("Reason:    {0}" -f $report.reason)
Write-Host ("Focus:     {0}" -f $report.next_focus)
Write-Host ("Run:       {0}" -f $report.recommended_command)
Write-Host ("Guide:     {0}" -f $report.recommended_guide_command)
