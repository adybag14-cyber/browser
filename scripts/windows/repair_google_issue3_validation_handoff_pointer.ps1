[CmdletBinding()]
param(
    [string]$SummaryPath,
    [string]$ManifestPath,
    [string]$HandoffPath,
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

function Set-ObjectProperty {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        $Value
    )

    $property = $Object.PSObject.Properties[$Name]
    if ($property) {
        $property.Value = $Value
    } else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function Write-ArtifactJson {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $Object | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -Encoding Ascii
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
if (-not $ManifestPath) {
    $configuredManifestPath = if (Test-HasProperty -Object $summary -Name 'manifest_artifact_path') {
        $summary.manifest_artifact_path
    } else {
        $null
    }
    $ManifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredManifestPath -ArtifactRoot $artifactRoot -FallbackName "google-issue3-recommended-validation-manifest.json"
}
$manifestExists = Test-Path -LiteralPath $ManifestPath -PathType Leaf
$manifest = if ($manifestExists) {
    try {
        Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    } catch {
        $null
    }
} else {
    $null
}
$configuredSummaryHandoffPath = if (Test-HasProperty -Object $summary -Name 'handoff_artifact_path') {
    $summary.handoff_artifact_path
} else {
    $null
}
$configuredManifestHandoffPath = if (Test-HasProperty -Object $manifest -Name 'handoff_artifact_path') {
    $manifest.handoff_artifact_path
} else {
    $null
}
$summaryRecordsHandoffArtifactPath = -not [string]::IsNullOrWhiteSpace($configuredSummaryHandoffPath)
$manifestRecordsHandoffArtifactPath = -not [string]::IsNullOrWhiteSpace($configuredManifestHandoffPath)
$handoffPointerUsesManifest = (-not $summaryRecordsHandoffArtifactPath) -and $manifestRecordsHandoffArtifactPath
$handoffPointerUsesFallback = (-not $summaryRecordsHandoffArtifactPath) -and (-not $manifestRecordsHandoffArtifactPath)
if (-not $HandoffPath) {
    $configuredHandoffPath = if ($summaryRecordsHandoffArtifactPath) {
        $configuredSummaryHandoffPath
    } elseif ($manifestRecordsHandoffArtifactPath) {
        $configuredManifestHandoffPath
    } else {
        $null
    }
    $HandoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredHandoffPath -ArtifactRoot $artifactRoot -FallbackName "google-issue3-validation-handoff.json"
}

$handoffRecord = $null
$handoffArtifactExists = Test-Path -LiteralPath $HandoffPath -PathType Leaf
$handoffArtifactError = $null
if ($handoffArtifactExists) {
    try {
        $handoffRecord = Read-ArtifactJson $HandoffPath
    } catch {
        $handoffArtifactError = $_.Exception.Message
    }
} else {
    $handoffArtifactError = "Handoff artifact not found: $HandoffPath"
}

$handoffReady = [bool]($handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffRecord.next_artifact_to_open))
$handoffStatus = if ($handoffArtifactError) {
    if ($handoffArtifactExists) { "present-unreadable" } else { "missing" }
} elseif ($handoffReady) {
    "ready"
} else {
    "incomplete"
}
$handoffReason = if ($handoffRecord) { $handoffRecord.reason } else { $null }
$handoffNextArtifactToOpen = if ($handoffRecord) { $handoffRecord.next_artifact_to_open } else { $null }
$handoffRecommendedCommand = if ($handoffRecord) { $handoffRecord.recommended_command } else { $null }
$handoffRecommendedGuideCommand = if ($handoffRecord) { $handoffRecord.recommended_guide_command } else { $null }
$handoffRefreshStatusCommand = if ($handoffRecord) { $handoffRecord.refresh_status_command } else { $null }
$handoffRefreshChainCommand = if ($handoffRecord) { $handoffRecord.refresh_chain_command } else { $null }
$handoffSummaryPath = if ($handoffRecord) { $handoffRecord.summary_path } else { $null }
$handoffSummaryGeneratedAtUtc = if ($handoffRecord) { $handoffRecord.summary_generated_at_utc } else { $null }
$generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
$repairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_handoff_pointer.ps1'
$fallbackHandoffCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$fallbackRefreshCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'

Set-ObjectProperty -Object $summary -Name 'handoff_artifact_path' -Value $HandoffPath
Set-ObjectProperty -Object $summary -Name 'handoff_artifact_error' -Value $handoffArtifactError
Set-ObjectProperty -Object $summary -Name 'handoff_status' -Value $handoffStatus
Set-ObjectProperty -Object $summary -Name 'handoff_ready' -Value ([bool]$handoffReady)
Set-ObjectProperty -Object $summary -Name 'handoff_reason' -Value $handoffReason
Set-ObjectProperty -Object $summary -Name 'handoff_next_artifact_to_open' -Value $handoffNextArtifactToOpen
Set-ObjectProperty -Object $summary -Name 'handoff_recommended_command' -Value $handoffRecommendedCommand
Set-ObjectProperty -Object $summary -Name 'handoff_recommended_guide_command' -Value $handoffRecommendedGuideCommand
Set-ObjectProperty -Object $summary -Name 'handoff_refresh_status_command' -Value $handoffRefreshStatusCommand
Set-ObjectProperty -Object $summary -Name 'handoff_refresh_chain_command' -Value $handoffRefreshChainCommand
Set-ObjectProperty -Object $summary -Name 'handoff_summary_path' -Value $handoffSummaryPath
Set-ObjectProperty -Object $summary -Name 'handoff_summary_generated_at_utc' -Value $handoffSummaryGeneratedAtUtc
Set-ObjectProperty -Object $summary -Name 'handoff_pointer_repaired_at_utc' -Value $generatedAtUtc
Set-ObjectProperty -Object $summary -Name 'handoff_pointer_repair_command' -Value $repairCommand
Write-ArtifactJson -Object $summary -Path $SummaryPath

if ($manifest) {
    Set-ObjectProperty -Object $manifest -Name 'handoff_artifact_path' -Value $HandoffPath
    Set-ObjectProperty -Object $manifest -Name 'handoff_artifact_error' -Value $handoffArtifactError
    Set-ObjectProperty -Object $manifest -Name 'handoff_status' -Value $handoffStatus
    Set-ObjectProperty -Object $manifest -Name 'handoff_ready' -Value ([bool]$handoffReady)
    Set-ObjectProperty -Object $manifest -Name 'handoff_reason' -Value $handoffReason
    Set-ObjectProperty -Object $manifest -Name 'handoff_next_artifact_to_open' -Value $handoffNextArtifactToOpen
    Set-ObjectProperty -Object $manifest -Name 'handoff_recommended_command' -Value $handoffRecommendedCommand
    Set-ObjectProperty -Object $manifest -Name 'handoff_recommended_guide_command' -Value $handoffRecommendedGuideCommand
    Set-ObjectProperty -Object $manifest -Name 'handoff_refresh_status_command' -Value $handoffRefreshStatusCommand
    Set-ObjectProperty -Object $manifest -Name 'handoff_refresh_chain_command' -Value $handoffRefreshChainCommand
    Set-ObjectProperty -Object $manifest -Name 'handoff_summary_path' -Value $handoffSummaryPath
    Set-ObjectProperty -Object $manifest -Name 'handoff_summary_generated_at_utc' -Value $handoffSummaryGeneratedAtUtc
    Set-ObjectProperty -Object $manifest -Name 'handoff_pointer_repaired_at_utc' -Value $generatedAtUtc
    Set-ObjectProperty -Object $manifest -Name 'handoff_pointer_repair_command' -Value $repairCommand
    Write-ArtifactJson -Object $manifest -Path $ManifestPath
}

$status = if (-not $manifestExists) {
    'summary-only'
} elseif ($handoffArtifactError) {
    'synced-with-handoff-error'
} else {
    'synced'
}
$nextFocus = if ($handoffArtifactError) {
    'Regenerate or reread the saved handoff artifact, then rerun this repair helper so the summary and manifest stop depending on the fallback handoff location.'
} elseif (-not $handoffReady) {
    'Open the saved handoff artifact first, then rerun the narrower helper chain once the handoff record exposes the next artifact to open.'
} elseif ($handoffPointerUsesManifest) {
    'The saved manifest already carries the current handoff artifact path, so the summary is now aligned and the next bounded replay can continue without another handoff path guess.'
} else {
    'Open the repaired summary, manifest, or handoff helper and continue with the next bounded Windows replay step.'
}
$recommendedCommand = if ($handoffRecommendedCommand) {
    $handoffRecommendedCommand
} elseif ($handoffArtifactError) {
    $fallbackRefreshCommand
} else {
    $fallbackHandoffCommand
}

$report = [ordered]@{
    issue = 'Google issue #3 validation handoff pointer repair'
    purpose = 'Persist the handoff artifact path, readiness, and helper guidance directly into the saved issue #3 summary and manifest so later helpers stop depending on fallback handoff guesses.'
    generated_at_utc = $generatedAtUtc
    summary_path = $SummaryPath
    manifest_path = $ManifestPath
    manifest_exists = [bool]$manifestExists
    summary_records_handoff_artifact_path = [bool]$summaryRecordsHandoffArtifactPath
    summary_handoff_artifact_path = if ($summaryRecordsHandoffArtifactPath) { $configuredSummaryHandoffPath } else { $null }
    manifest_records_handoff_artifact_path = [bool]$manifestRecordsHandoffArtifactPath
    manifest_handoff_artifact_path = if ($manifestRecordsHandoffArtifactPath) { $configuredManifestHandoffPath } else { $null }
    handoff_pointer_uses_manifest = [bool]$handoffPointerUsesManifest
    handoff_pointer_uses_fallback = [bool]$handoffPointerUsesFallback
    handoff_artifact_path = $HandoffPath
    handoff_artifact_exists = [bool]$handoffArtifactExists
    handoff_status = $handoffStatus
    handoff_ready = [bool]$handoffReady
    handoff_artifact_error = $handoffArtifactError
    handoff_reason = $handoffReason
    handoff_summary_path = $handoffSummaryPath
    handoff_summary_generated_at_utc = $handoffSummaryGeneratedAtUtc
    handoff_next_artifact_to_open = $handoffNextArtifactToOpen
    handoff_recommended_command = $handoffRecommendedCommand
    handoff_recommended_guide_command = $handoffRecommendedGuideCommand
    handoff_refresh_status_command = $handoffRefreshStatusCommand
    handoff_refresh_chain_command = $handoffRefreshChainCommand
    repair_command = $repairCommand
    fallback_handoff_command = $fallbackHandoffCommand
    fallback_refresh_command = $fallbackRefreshCommand
    status = $status
    next_focus = $nextFocus
    recommended_command = $recommendedCommand
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    if ($handoffArtifactError) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 validation handoff pointer repair'
Write-Host ''
Write-Host ("Summary:  {0}" -f $report.summary_path)
Write-Host ("Manifest: {0}" -f $report.manifest_path)
Write-Host ("Summary handoff recorded: {0}" -f $report.summary_records_handoff_artifact_path)
Write-Host ("Manifest handoff recorded: {0}" -f $report.manifest_records_handoff_artifact_path)
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
Write-Host ("Handoff:  {0}" -f $report.handoff_artifact_path)
Write-Host ("Status:   {0}" -f $report.status)
Write-Host ("Handoff status: {0}" -f $report.handoff_status)
Write-Host ("Handoff ready:  {0}" -f $report.handoff_ready)
if ($report.handoff_artifact_error) {
    Write-Host ("Handoff error: {0}" -f $report.handoff_artifact_error)
}
if ($report.handoff_reason) {
    Write-Host ("Handoff reason: {0}" -f $report.handoff_reason)
}
if ($report.handoff_next_artifact_to_open) {
    Write-Host ("Open next: {0}" -f $report.handoff_next_artifact_to_open)
}
Write-Host ("Run next: {0}" -f $report.recommended_command)
Write-Host ("Focus:    {0}" -f $report.next_focus)

if ($report.handoff_artifact_error) {
    exit 1
}
