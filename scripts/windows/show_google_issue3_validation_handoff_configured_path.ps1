[CmdletBinding()]
param(
    [string]$SummaryPath,
    [string]$ArtifactPath,
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
$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.manifest_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$manifestRecord = $null
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    try {
        $manifestRecord = Read-ArtifactJson $manifestPath
    } catch {
        $manifestRecord = $null
    }
}

if (-not $ArtifactPath) {
    $configuredSummaryHandoffPath = $summary.handoff_artifact_path
    $configuredManifestHandoffPath = if ($manifestRecord) { $manifestRecord.handoff_artifact_path } else { $null }
    $configuredHandoffPath = if (-not [string]::IsNullOrWhiteSpace($configuredSummaryHandoffPath)) {
        $configuredSummaryHandoffPath
    } elseif (-not [string]::IsNullOrWhiteSpace($configuredManifestHandoffPath)) {
        $configuredManifestHandoffPath
    } else {
        $null
    }
    $ArtifactPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredHandoffPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
}

$helperScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_handoff.ps1'
if (-not (Test-Path -LiteralPath $helperScript -PathType Leaf)) {
    throw "Issue #3 validation handoff helper not found: $helperScript"
}

if ($Json) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $helperScript -SummaryPath $SummaryPath -ArtifactPath $ArtifactPath -Json
    exit $LASTEXITCODE
}

Write-Host 'Google issue #3 validation handoff (configured path wrapper)'
Write-Host ''
Write-Host ("Summary:  {0}" -f $SummaryPath)
Write-Host ("Manifest: {0}" -f $manifestPath)
Write-Host ("Handoff:  {0}" -f $ArtifactPath)
Write-Host ''

& powershell -NoProfile -ExecutionPolicy Bypass -File $helperScript -SummaryPath $SummaryPath -ArtifactPath $ArtifactPath
exit $LASTEXITCODE
