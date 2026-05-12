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

function Test-HasProperty {
    param(
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [bool]($Object -and $Object.PSObject.Properties[$Name])
}

function Add-MissingField {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$List,
        [Parameter(Mandatory = $true)]
        [string]$FieldName,
        [Parameter(Mandatory = $true)]
        [bool]$Present
    )

    if (-not $Present) {
        $List.Add($FieldName) | Out-Null
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
$artifactRoot = if ((Test-HasProperty -Object $summary -Name 'artifact_root') -and -not [string]::IsNullOrWhiteSpace($summary.artifact_root)) {
    $summary.artifact_root
} else {
    Split-Path -Parent $SummaryPath
}

$summaryHasManifestArtifactPathField = Test-HasProperty -Object $summary -Name 'manifest_artifact_path'
$summaryHasGuideArtifactPathField = Test-HasProperty -Object $summary -Name 'guide_artifact_path'
$summaryHasBoundaryArtifactPathField = Test-HasProperty -Object $summary -Name 'boundary_artifact_path'
$summaryHasBundleArtifactPathField = Test-HasProperty -Object $summary -Name 'artifact_bundle_path'

$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($summaryHasManifestArtifactPathField) { $summary.manifest_artifact_path } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$guidePath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($summaryHasGuideArtifactPathField) { $summary.guide_artifact_path } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-guide.json'
$boundaryPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($summaryHasBoundaryArtifactPathField) { $summary.boundary_artifact_path } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-phase-boundary.json'
$bundlePath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($summaryHasBundleArtifactPathField) { $summary.artifact_bundle_path } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json'

$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
$manifestRecord = Read-ArtifactJson $manifestPath
$manifestReadable = [bool]$manifestRecord

$summaryHasRefreshPathField = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_path'
$summaryHasRefreshErrorField = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_error'
$summaryHasHandoffPathField = Test-HasProperty -Object $summary -Name 'handoff_artifact_path'
$summaryHasHandoffErrorField = Test-HasProperty -Object $summary -Name 'handoff_artifact_error'
$manifestHasRefreshPathField = Test-HasProperty -Object $manifestRecord -Name 'refresh_chain_artifact_path'
$manifestHasRefreshErrorField = Test-HasProperty -Object $manifestRecord -Name 'refresh_chain_artifact_error'
$manifestHasHandoffPathField = Test-HasProperty -Object $manifestRecord -Name 'handoff_artifact_path'
$manifestHasHandoffErrorField = Test-HasProperty -Object $manifestRecord -Name 'handoff_artifact_error'

$summaryPathFieldsMissing = [System.Collections.Generic.List[string]]::new()
Add-MissingField -List $summaryPathFieldsMissing -FieldName 'summary.manifest_artifact_path' -Present $summaryHasManifestArtifactPathField
Add-MissingField -List $summaryPathFieldsMissing -FieldName 'summary.guide_artifact_path' -Present $summaryHasGuideArtifactPathField
Add-MissingField -List $summaryPathFieldsMissing -FieldName 'summary.boundary_artifact_path' -Present $summaryHasBoundaryArtifactPathField
Add-MissingField -List $summaryPathFieldsMissing -FieldName 'summary.artifact_bundle_path' -Present $summaryHasBundleArtifactPathField

$runnerContractMissingFields = [System.Collections.Generic.List[string]]::new()
Add-MissingField -List $runnerContractMissingFields -FieldName 'summary.refresh_chain_artifact_path' -Present $summaryHasRefreshPathField
Add-MissingField -List $runnerContractMissingFields -FieldName 'summary.refresh_chain_artifact_error' -Present $summaryHasRefreshErrorField
Add-MissingField -List $runnerContractMissingFields -FieldName 'summary.handoff_artifact_path' -Present $summaryHasHandoffPathField
Add-MissingField -List $runnerContractMissingFields -FieldName 'summary.handoff_artifact_error' -Present $summaryHasHandoffErrorField
Add-MissingField -List $runnerContractMissingFields -FieldName 'manifest.refresh_chain_artifact_path' -Present $manifestHasRefreshPathField
Add-MissingField -List $runnerContractMissingFields -FieldName 'manifest.refresh_chain_artifact_error' -Present $manifestHasRefreshErrorField
Add-MissingField -List $runnerContractMissingFields -FieldName 'manifest.handoff_artifact_path' -Present $manifestHasHandoffPathField
Add-MissingField -List $runnerContractMissingFields -FieldName 'manifest.handoff_artifact_error' -Present $manifestHasHandoffErrorField

$runnerPatchTargetsCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
$runnerWiringCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$manifestSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest_safe.ps1'
$broaderRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

$safeToRunRefreshStatus = [bool](($summaryPathFieldsMissing.Count -eq 0) -and ($runnerContractMissingFields.Count -eq 0))

$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null

if ($summaryPathFieldsMissing.Count -gt 0) {
    $status = 'summary-artifact-paths-missing'
    $reason = 'The saved issue #3 summary still omits one or more artifact-path fields that the narrower refresh-status helper reads directly under strict mode.'
    $nextFocus = 'Regenerate the broader recommended-validation outputs before trusting the narrower refresh-status helper.'
    $recommendedCommand = $broaderRunnerCommand
    $recommendedGuideCommand = $manifestSafeCommand
    $nextArtifactToOpen = $SummaryPath
} elseif (-not $manifestExists) {
    $status = 'manifest-missing'
    $reason = 'The saved issue #3 manifest is missing, so the narrower refresh-status helper would have to rely on fallback recovery instead of the current summary-plus-manifest contract.'
    $nextFocus = 'Regenerate the broader recommended-validation outputs so the manifest exists for the current summary.'
    $recommendedCommand = $broaderRunnerCommand
    $recommendedGuideCommand = $manifestSafeCommand
    $nextArtifactToOpen = $manifestPath
} elseif (-not $manifestReadable) {
    $status = 'manifest-unreadable'
    $reason = 'The saved issue #3 manifest exists but could not be parsed cleanly, so the narrower refresh-status helper is not the safest next checkpoint yet.'
    $nextFocus = 'Repair or regenerate the manifest before trusting the narrower refresh-status helper.'
    $recommendedCommand = $broaderRunnerCommand
    $recommendedGuideCommand = $manifestSafeCommand
    $nextArtifactToOpen = $manifestPath
} elseif ($runnerContractMissingFields.Count -gt 0) {
    $status = 'runner-contract-missing'
    $reason = 'The summary and manifest still omit part of the direct refresh or handoff runner-output contract, so the narrower refresh-status helper could still be compensating for missing top-level fields.'
    $nextFocus = 'Use the runner patch-target and runner wiring helpers first, then return to the narrower refresh-status helper after the direct contract is wired.'
    $recommendedCommand = $runnerPatchTargetsCommand
    $recommendedGuideCommand = $runnerWiringCommand
    $nextArtifactToOpen = $SummaryPath
} else {
    $status = 'safe-to-run-refresh-status'
    $reason = 'The saved summary exposes the artifact-path fields the narrower refresh-status helper expects, and the saved summary plus manifest already advertise the direct runner-output contract.'
    $nextFocus = 'Open the narrower refresh-status helper and continue the current issue #3 validation chain from there.'
    $recommendedCommand = $refreshStatusCommand
    $recommendedGuideCommand = $runnerWiringCommand
    $nextArtifactToOpen = $guidePath
}

$report = [ordered]@{
    issue = 'Google issue #3 validation refresh-status safe helper'
    purpose = 'Check whether the saved issue #3 summary and manifest are complete enough to trust the narrower refresh-status helper without another strict-mode or runner-contract detour.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_root = $artifactRoot
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_readable = [bool]$manifestReadable
    guide_artifact_path = $guidePath
    boundary_artifact_path = $boundaryPath
    artifact_bundle_path = $bundlePath
    summary_has_manifest_artifact_path_field = [bool]$summaryHasManifestArtifactPathField
    summary_has_guide_artifact_path_field = [bool]$summaryHasGuideArtifactPathField
    summary_has_boundary_artifact_path_field = [bool]$summaryHasBoundaryArtifactPathField
    summary_has_artifact_bundle_path_field = [bool]$summaryHasBundleArtifactPathField
    summary_path_fields_missing = @($summaryPathFieldsMissing)
    summary_has_refresh_chain_artifact_path_field = [bool]$summaryHasRefreshPathField
    summary_has_refresh_chain_artifact_error_field = [bool]$summaryHasRefreshErrorField
    summary_has_handoff_artifact_path_field = [bool]$summaryHasHandoffPathField
    summary_has_handoff_artifact_error_field = [bool]$summaryHasHandoffErrorField
    manifest_has_refresh_chain_artifact_path_field = [bool]$manifestHasRefreshPathField
    manifest_has_refresh_chain_artifact_error_field = [bool]$manifestHasRefreshErrorField
    manifest_has_handoff_artifact_path_field = [bool]$manifestHasHandoffPathField
    manifest_has_handoff_artifact_error_field = [bool]$manifestHasHandoffErrorField
    runner_contract_missing_fields = @($runnerContractMissingFields)
    safe_to_run_refresh_status = [bool]$safeToRunRefreshStatus
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    runner_patch_targets_command = $runnerPatchTargetsCommand
    runner_wiring_command = $runnerWiringCommand
    refresh_status_command = $refreshStatusCommand
    manifest_safe_command = $manifestSafeCommand
    broader_runner_command = $broaderRunnerCommand
    next_artifact_to_open = $nextArtifactToOpen
    status = $status
    reason = $reason
    next_focus = $nextFocus
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 validation refresh-status safe helper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Guide:     {0}" -f $report.guide_artifact_path)
Write-Host ("Boundary:  {0}" -f $report.boundary_artifact_path)
Write-Host ("Bundle:    {0}" -f $report.artifact_bundle_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Safe:      {0}" -f $report.safe_to_run_refresh_status)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
Write-Host ("Manifest readable: {0}" -f $report.manifest_artifact_readable)
if ($report.summary_path_fields_missing.Count -gt 0) {
    Write-Host 'Missing summary artifact-path fields:'
    foreach ($fieldName in $report.summary_path_fields_missing) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
if ($report.runner_contract_missing_fields.Count -gt 0) {
    Write-Host 'Missing runner-contract fields:'
    foreach ($fieldName in $report.runner_contract_missing_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
