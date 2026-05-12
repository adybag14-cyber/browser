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
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json'
}

$summaryExists = Test-Path -LiteralPath $SummaryPath -PathType Leaf
if (-not $summaryExists) {
    $report = [ordered]@{
        issue = 'Google issue #3 handoff path coherency'
        purpose = 'Tell the next Windows replay whether the current handoff helper can safely reuse the saved handoff artifact path without an explicit -ArtifactPath override.'
        generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        summary_path = $SummaryPath
        summary_exists = $false
        recommended_command = $recommendedRunnerCommand
        recommended_guide_command = $summaryGuideCommand
        safe_handoff_command = $handoffGuideCommand
        path_coherent = $false
        explicit_artifact_path_required = $false
        reason = 'No saved issue #3 recommended-validation summary exists yet, so create the first summary before checking handoff path coherency.'
        next_focus = 'Run the bounded issue #3 validation runner first, then reopen this helper to see whether the existing handoff helper can safely reuse the saved handoff path.'
        next_artifact_to_open = $SummaryPath
    }

    if ($Json) {
        $report | ConvertTo-Json -Depth 6
        exit 0
    }

    Write-Host 'Google issue #3 handoff path coherency'
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
$resolvedPathMatchesFallback = PathsMatch $resolvedHandoffPath $fallbackHandoffPath
$configuredPathDiffersFromFallback = [bool]((-not $resolvedPathMatchesFallback) -and (-not [string]::IsNullOrWhiteSpace($configuredHandoffPath)))
$pathCoherent = $true
$explicitArtifactPathRequired = $false
$safeHandoffCommand = $handoffGuideCommand

$reason = if ($configuredPathDiffersFromFallback) {
    'The saved issue #3 summary or manifest points the handoff helper at a non-default artifact path, and the current handoff helper now reuses that resolved configured path as its default write target, so no explicit -ArtifactPath override is required.'
} elseif ($summaryRecordsHandoffArtifactPath -or $manifestRecordsHandoffArtifactPath) {
    'The saved issue #3 helper chain records a handoff artifact path, and it already matches the default handoff location, so the existing handoff helper can be reused without an explicit -ArtifactPath override.'
} else {
    'The saved issue #3 helper chain does not record a custom handoff artifact path, so the default handoff location remains the current source of truth.'
}

$nextFocus = if ($configuredPathDiffersFromFallback) {
    'Reuse the existing handoff helper normally. It now keeps reads and writes on the same resolved configured handoff artifact path even when that path differs from the fallback default.'
} else {
    'Reuse the existing handoff helper normally. No explicit -ArtifactPath override is needed for the current saved issue #3 summary.'
}

$nextArtifactToOpen = if ($resolvedHandoffExists) {
    $resolvedHandoffPath
} elseif ($fallbackHandoffExists) {
    $fallbackHandoffPath
} else {
    $SummaryPath
}

$report = [ordered]@{
    issue = 'Google issue #3 handoff path coherency'
    purpose = 'Tell the next Windows replay whether the current handoff helper can safely reuse the saved handoff artifact path without an explicit -ArtifactPath override.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    summary_exists = $true
    summary_generated_at_utc = $summary.generated_at_utc
    artifact_root = $artifactRoot
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    summary_records_handoff_artifact_path = [bool]$summaryRecordsHandoffArtifactPath
    summary_handoff_artifact_path = if ($summaryRecordsHandoffArtifactPath) { $configuredSummaryHandoffPath } else { $null }
    manifest_records_handoff_artifact_path = [bool]$manifestRecordsHandoffArtifactPath
    manifest_handoff_artifact_path = if ($manifestRecordsHandoffArtifactPath) { $configuredManifestHandoffPath } else { $null }
    configured_handoff_artifact_path = $configuredHandoffPath
    configured_path_differs_from_fallback = [bool]$configuredPathDiffersFromFallback
    resolved_path_matches_fallback = [bool]$resolvedPathMatchesFallback
    resolved_handoff_artifact_path = $resolvedHandoffPath
    resolved_handoff_artifact_exists = [bool]$resolvedHandoffExists
    fallback_handoff_artifact_path = $fallbackHandoffPath
    fallback_handoff_artifact_exists = [bool]$fallbackHandoffExists
    path_coherent = [bool]$pathCoherent
    explicit_artifact_path_required = [bool]$explicitArtifactPathRequired
    recommended_command = $safeHandoffCommand
    recommended_guide_command = $handoffGuideCommand
    safe_handoff_command = $safeHandoffCommand
    normal_handoff_command = $handoffGuideCommand
    next_artifact_to_open = $nextArtifactToOpen
    reason = $reason
    next_focus = $nextFocus
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 handoff path coherency'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Resolved:  {0}" -f $report.resolved_handoff_artifact_path)
Write-Host ("Fallback:  {0}" -f $report.fallback_handoff_artifact_path)
Write-Host ("Coherent:  {0}" -f $report.path_coherent)
Write-Host ("Override:  {0}" -f $report.explicit_artifact_path_required)
Write-Host ("Open:      {0}" -f $report.next_artifact_to_open)
Write-Host ''
Write-Host ("Reason:    {0}" -f $report.reason)
Write-Host ("Focus:     {0}" -f $report.next_focus)
Write-Host ("Run:       {0}" -f $report.recommended_command)
Write-Host ("Guide:     {0}" -f $report.recommended_guide_command)
