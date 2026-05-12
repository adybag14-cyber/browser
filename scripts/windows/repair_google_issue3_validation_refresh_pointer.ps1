[CmdletBinding()]
param(
    [string]$SummaryPath,
    [string]$ManifestPath,
    [string]$RefreshPath,
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
if (-not $RefreshPath) {
    $configuredRefreshPath = if (Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_path') {
        $summary.refresh_chain_artifact_path
    } else {
        $null
    }
    $RefreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredRefreshPath -ArtifactRoot $artifactRoot -FallbackName "google-issue3-validation-handoff-chain-refresh.json"
}

$refreshRecord = $null
$refreshArtifactExists = Test-Path -LiteralPath $RefreshPath -PathType Leaf
$refreshArtifactError = $null
if ($refreshArtifactExists) {
    try {
        $refreshRecord = Read-ArtifactJson $RefreshPath
    } catch {
        $refreshArtifactError = $_.Exception.Message
    }
} else {
    $refreshArtifactError = "Refresh artifact not found: $RefreshPath"
}

$refreshStatus = if ($refreshRecord -and $refreshRecord.status) {
    $refreshRecord.status
} elseif ($refreshArtifactError) {
    if ($refreshArtifactExists) { "present-unreadable" } else { "missing" }
} else {
    $null
}
$refreshReason = if ($refreshRecord -and $refreshRecord.reason) { $refreshRecord.reason } else { $null }
$refreshNextArtifactToOpen = if ($refreshRecord) { $refreshRecord.next_artifact_to_open } else { $null }
$refreshRecommendedCommand = if ($refreshRecord) { $refreshRecord.recommended_command } else { $null }
$refreshRecommendedGuideCommand = if ($refreshRecord) { $refreshRecord.recommended_guide_command } else { $null }
$refreshFailedStepCount = if ($refreshRecord -and $null -ne $refreshRecord.failed_step_count) { [int]$refreshRecord.failed_step_count } else { $null }
$refreshFailedStepNames = if ($refreshRecord) { @($refreshRecord.failed_step_names) } else { @() }
$generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
$repairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_refresh_pointer.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'

Set-ObjectProperty -Object $summary -Name 'refresh_chain_artifact_path' -Value $RefreshPath
Set-ObjectProperty -Object $summary -Name 'refresh_chain_artifact_error' -Value $refreshArtifactError
Set-ObjectProperty -Object $summary -Name 'refresh_chain_status' -Value $refreshStatus
Set-ObjectProperty -Object $summary -Name 'refresh_chain_reason' -Value $refreshReason
Set-ObjectProperty -Object $summary -Name 'refresh_chain_next_artifact_to_open' -Value $refreshNextArtifactToOpen
Set-ObjectProperty -Object $summary -Name 'refresh_chain_recommended_command' -Value $refreshRecommendedCommand
Set-ObjectProperty -Object $summary -Name 'refresh_chain_recommended_guide_command' -Value $refreshRecommendedGuideCommand
Set-ObjectProperty -Object $summary -Name 'refresh_chain_failed_step_count' -Value $refreshFailedStepCount
Set-ObjectProperty -Object $summary -Name 'refresh_chain_failed_step_names' -Value @($refreshFailedStepNames)
Set-ObjectProperty -Object $summary -Name 'refresh_pointer_repaired_at_utc' -Value $generatedAtUtc
Set-ObjectProperty -Object $summary -Name 'refresh_pointer_repair_command' -Value $repairCommand
Write-ArtifactJson -Object $summary -Path $SummaryPath

$manifestExists = Test-Path -LiteralPath $ManifestPath -PathType Leaf
$manifest = $null
$manifestError = $null
if ($manifestExists) {
    try {
        $manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    } catch {
        $manifestError = $_.Exception.Message
    }
}
if ($manifest) {
    Set-ObjectProperty -Object $manifest -Name 'refresh_chain_artifact_path' -Value $RefreshPath
    Set-ObjectProperty -Object $manifest -Name 'refresh_chain_artifact_error' -Value $refreshArtifactError
    Set-ObjectProperty -Object $manifest -Name 'refresh_chain_status' -Value $refreshStatus
    Set-ObjectProperty -Object $manifest -Name 'refresh_chain_reason' -Value $refreshReason
    Set-ObjectProperty -Object $manifest -Name 'refresh_chain_next_artifact_to_open' -Value $refreshNextArtifactToOpen
    Set-ObjectProperty -Object $manifest -Name 'refresh_chain_recommended_command' -Value $refreshRecommendedCommand
    Set-ObjectProperty -Object $manifest -Name 'refresh_chain_recommended_guide_command' -Value $refreshRecommendedGuideCommand
    Set-ObjectProperty -Object $manifest -Name 'refresh_chain_failed_step_count' -Value $refreshFailedStepCount
    Set-ObjectProperty -Object $manifest -Name 'refresh_chain_failed_step_names' -Value @($refreshFailedStepNames)
    Set-ObjectProperty -Object $manifest -Name 'refresh_pointer_repaired_at_utc' -Value $generatedAtUtc
    Set-ObjectProperty -Object $manifest -Name 'refresh_pointer_repair_command' -Value $repairCommand
    Write-ArtifactJson -Object $manifest -Path $ManifestPath
}

$status = if (-not $manifestExists) {
    'summary-only'
} elseif ($manifestError) {
    'summary-synced-manifest-unreadable'
} elseif ($refreshArtifactError) {
    'synced-with-refresh-error'
} else {
    'synced'
}
$nextFocus = if ($manifestError) {
    'Repair or regenerate the saved manifest JSON, then rerun this repair helper so both outputs advertise the same direct refresh-pointer contract.'
} elseif ($refreshArtifactError) {
    'Regenerate or reread the saved refresh artifact, then rerun this repair helper so the summary and manifest stop depending on fallback refresh-location guesses.'
} elseif ($refreshStatus -and $refreshStatus -ne 'refreshed') {
    'Open the saved refresh artifact first, then rerun the narrower handoff helper once the helper chain reports a stable refreshed state.'
} else {
    'Open the manifest or handoff helper from the repaired summary and continue with the next bounded Windows replay step.'
}
$recommendedCommand = if ($refreshRecommendedCommand) {
    $refreshRecommendedCommand
} elseif ($manifestError -or $refreshArtifactError) {
    $refreshChainCommand
} else {
    $repairCommand
}

$report = [ordered]@{
    issue = 'Google issue #3 validation refresh pointer repair'
    purpose = 'Persist the refresh artifact path, status, and helper error details directly into the saved issue #3 summary and manifest so later helpers stop depending on fallback guesses.'
    generated_at_utc = $generatedAtUtc
    summary_path = $SummaryPath
    manifest_path = $ManifestPath
    manifest_exists = [bool]$manifestExists
    manifest_error = $manifestError
    refresh_artifact_path = $RefreshPath
    refresh_artifact_exists = [bool]$refreshArtifactExists
    refresh_chain_status = $refreshStatus
    refresh_chain_artifact_error = $refreshArtifactError
    refresh_chain_reason = $refreshReason
    refresh_chain_failed_step_count = $refreshFailedStepCount
    refresh_chain_failed_step_names = @($refreshFailedStepNames)
    refresh_chain_next_artifact_to_open = $refreshNextArtifactToOpen
    refresh_chain_recommended_command = $refreshRecommendedCommand
    refresh_chain_recommended_guide_command = $refreshRecommendedGuideCommand
    repair_command = $repairCommand
    fallback_refresh_command = $refreshChainCommand
    status = $status
    next_focus = $nextFocus
    recommended_command = $recommendedCommand
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    if ($manifestError -or $refreshArtifactError) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 validation refresh pointer repair'
Write-Host ''
Write-Host ("Summary:  {0}" -f $report.summary_path)
Write-Host ("Manifest: {0}" -f $report.manifest_path)
Write-Host ("Refresh:  {0}" -f $report.refresh_artifact_path)
Write-Host ("Status:   {0}" -f $report.status)
Write-Host ("Refresh status: {0}" -f $report.refresh_chain_status)
if ($report.manifest_error) {
    Write-Host ("Manifest error: {0}" -f $report.manifest_error)
}
if ($report.refresh_chain_artifact_error) {
    Write-Host ("Refresh error: {0}" -f $report.refresh_chain_artifact_error)
}
if ($report.refresh_chain_reason) {
    Write-Host ("Refresh reason: {0}" -f $report.refresh_chain_reason)
}
if ($null -ne $report.refresh_chain_failed_step_count -and $report.refresh_chain_failed_step_count -gt 0) {
    Write-Host ("Refresh failed steps: {0}" -f ($report.refresh_chain_failed_step_names -join ', '))
}
if ($report.refresh_chain_next_artifact_to_open) {
    Write-Host ("Open next: {0}" -f $report.refresh_chain_next_artifact_to_open)
}
Write-Host ("Run next: {0}" -f $report.recommended_command)
Write-Host ("Focus:    {0}" -f $report.next_focus)

if ($report.manifest_error -or $report.refresh_chain_artifact_error) {
    exit 1
}
