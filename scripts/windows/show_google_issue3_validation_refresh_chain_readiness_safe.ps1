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

function Get-OptionalPropertyValue {
    param(
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (Test-HasProperty -Object $Object -Name $Name) {
        return $Object.$Name
    }

    return $null
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
$summaryHasArtifactRootField = Test-HasProperty -Object $summary -Name 'artifact_root'
$summaryHasManifestArtifactPathField = Test-HasProperty -Object $summary -Name 'manifest_artifact_path'
$summaryHasRefreshArtifactPathField = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_path'
$summaryHasRefreshArtifactErrorField = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_error'
$summaryHasHandoffArtifactPathField = Test-HasProperty -Object $summary -Name 'handoff_artifact_path'
$summaryHasArtifactBundlePathField = Test-HasProperty -Object $summary -Name 'artifact_bundle_path'
$summaryHasArtifactBundleErrorField = Test-HasProperty -Object $summary -Name 'artifact_bundle_error'

$artifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
if ([string]::IsNullOrWhiteSpace($artifactRoot)) {
    $artifactRoot = Split-Path -Parent $SummaryPath
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-validation-refresh-chain-readiness-safe.json'
}

$rawReadinessCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_chain_readiness.ps1'
$broaderRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$artifactPathRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_artifact_paths.ps1'
$runnerContractRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1'
$runnerWiringStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
$refreshStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe.ps1'
$artifactBundleCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'

$configuredManifestPath = Get-OptionalPropertyValue -Object $summary -Name 'manifest_artifact_path'
$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredManifestPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
$manifestRecord = Read-ArtifactJson $manifestPath
$manifestReadable = [bool]$manifestRecord

$missingFields = [System.Collections.Generic.List[string]]::new()
Add-MissingField -List $missingFields -FieldName 'summary.artifact_root' -Present $summaryHasArtifactRootField
Add-MissingField -List $missingFields -FieldName 'summary.manifest_artifact_path' -Present $summaryHasManifestArtifactPathField
Add-MissingField -List $missingFields -FieldName 'summary.refresh_chain_artifact_path' -Present $summaryHasRefreshArtifactPathField
Add-MissingField -List $missingFields -FieldName 'summary.refresh_chain_artifact_error' -Present $summaryHasRefreshArtifactErrorField
Add-MissingField -List $missingFields -FieldName 'summary.handoff_artifact_path' -Present $summaryHasHandoffArtifactPathField
Add-MissingField -List $missingFields -FieldName 'summary.artifact_bundle_path' -Present $summaryHasArtifactBundlePathField
Add-MissingField -List $missingFields -FieldName 'summary.artifact_bundle_error' -Present $summaryHasArtifactBundleErrorField

$existingHelperLikelySafe = [bool](
    $summaryHasArtifactRootField -and
    $summaryHasManifestArtifactPathField -and
    $summaryHasRefreshArtifactPathField -and
    $summaryHasRefreshArtifactErrorField -and
    $summaryHasHandoffArtifactPathField -and
    $summaryHasArtifactBundlePathField -and
    $summaryHasArtifactBundleErrorField
)

$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null

if (-not $summaryHasArtifactRootField) {
    $status = 'summary-artifact-root-missing'
    $reason = 'The saved summary omits artifact_root, so the raw refresh-chain readiness helper can fail under strict mode before it reaches its fallback artifact-root path.'
    $nextFocus = 'Regenerate the broader issue #3 validation outputs before trusting the raw refresh-chain readiness helper.'
    $recommendedCommand = $broaderRunnerCommand
    $recommendedGuideCommand = $summaryGuideCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ((-not $summaryHasManifestArtifactPathField) -or (-not $summaryHasArtifactBundlePathField)) {
    $status = 'summary-path-fields-missing'
    $reason = 'The saved summary still omits one or more top-level artifact paths the raw refresh-chain readiness helper reads under strict mode.'
    $nextFocus = 'Repair the saved summary artifact paths first, then reopen the raw refresh-chain readiness helper.'
    $recommendedCommand = $artifactPathRepairCommand
    $recommendedGuideCommand = $rawReadinessCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ((-not $summaryHasRefreshArtifactPathField) -or (-not $summaryHasRefreshArtifactErrorField) -or (-not $summaryHasHandoffArtifactPathField)) {
    $status = 'summary-runner-contract-missing'
    $reason = 'The saved summary still omits at least one direct refresh or handoff field that the raw refresh-chain readiness helper reads under strict mode.'
    $nextFocus = 'Repair the saved runner-output contract first, then rerun the safe wiring audit before trusting the raw refresh-chain readiness helper.'
    $recommendedCommand = $runnerContractRepairCommand
    $recommendedGuideCommand = $runnerWiringStatusSafeCommand
    $nextArtifactToOpen = $SummaryPath
} elseif (-not $summaryHasArtifactBundleErrorField) {
    $status = 'bundle-audit-field-missing'
    $reason = 'The saved summary omits artifact_bundle_error, so the raw refresh-chain readiness helper cannot safely fall back when the bundle artifact is unreadable.'
    $nextFocus = 'Refresh the saved helper chain so the bundle audit fields are rewritten before reopening the raw readiness helper.'
    $recommendedCommand = $refreshChainCommand
    $recommendedGuideCommand = $artifactBundleCommand
    $nextArtifactToOpen = $SummaryPath
} else {
    $status = 'safe-to-run-existing-helper'
    $reason = 'The saved summary exposes the top-level fields the raw refresh-chain readiness helper expects under strict mode, so the next Windows replay can use it directly.'
    $nextFocus = 'Run the raw refresh-chain readiness helper and follow its preferred_start_helper guidance for the next bounded replay step.'
    $recommendedCommand = $rawReadinessCommand
    $recommendedGuideCommand = $refreshStatusSafeCommand
    $nextArtifactToOpen = $SummaryPath
}

$report = [ordered]@{
    issue = 'Google issue #3 refresh-chain readiness safe helper'
    purpose = 'Check whether the raw issue #3 refresh-chain readiness helper is safe to trust under strict mode for the current saved summary and route the next replay to the safest command when it is not.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    artifact_root = $artifactRoot
    summary_has_artifact_root_field = [bool]$summaryHasArtifactRootField
    summary_has_manifest_artifact_path_field = [bool]$summaryHasManifestArtifactPathField
    summary_has_refresh_chain_artifact_path_field = [bool]$summaryHasRefreshArtifactPathField
    summary_has_refresh_chain_artifact_error_field = [bool]$summaryHasRefreshArtifactErrorField
    summary_has_handoff_artifact_path_field = [bool]$summaryHasHandoffArtifactPathField
    summary_has_artifact_bundle_path_field = [bool]$summaryHasArtifactBundlePathField
    summary_has_artifact_bundle_error_field = [bool]$summaryHasArtifactBundleErrorField
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_readable = [bool]$manifestReadable
    missing_summary_fields = @($missingFields)
    existing_refresh_chain_readiness_helper_likely_safe = [bool]$existingHelperLikelySafe
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    raw_refresh_chain_readiness_command = $rawReadinessCommand
    broader_runner_command = $broaderRunnerCommand
    artifact_path_repair_command = $artifactPathRepairCommand
    runner_contract_repair_command = $runnerContractRepairCommand
    runner_wiring_status_safe_command = $runnerWiringStatusSafeCommand
    refresh_chain_command = $refreshChainCommand
    refresh_status_safe_command = $refreshStatusSafeCommand
    artifact_bundle_command = $artifactBundleCommand
    summary_guide_command = $summaryGuideCommand
    next_artifact_to_open = $nextArtifactToOpen
    status = $status
    reason = $reason
    next_focus = $nextFocus
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host 'Google issue #3 refresh-chain readiness safe helper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
Write-Host ("Manifest readable: {0}" -f $report.manifest_artifact_readable)
Write-Host ("Existing helper likely safe: {0}" -f $report.existing_refresh_chain_readiness_helper_likely_safe)
if ($report.missing_summary_fields.Count -gt 0) {
    Write-Host 'Missing summary fields:'
    foreach ($fieldName in $report.missing_summary_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
