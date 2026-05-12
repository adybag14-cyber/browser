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
$artifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
if ([string]::IsNullOrWhiteSpace($artifactRoot)) {
    $artifactRoot = Split-Path -Parent $SummaryPath
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-probe-triage-safe.json'
}

$probeTriageCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_probe_triage.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$artifactPathRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_artifact_paths.ps1'
$runnerContractRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1'
$runnerWiringStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$runnerPatchTargetsCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
$refreshStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe.ps1'
$handoffSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe.ps1'
$manifestSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest_safe.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'

$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'manifest_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
$manifestRecord = Read-ArtifactJson $manifestPath
$manifestReadable = [bool]$manifestRecord

$summaryHasArtifactRootField = Test-HasProperty -Object $summary -Name 'artifact_root'
$summaryHasManifestArtifactPathField = Test-HasProperty -Object $summary -Name 'manifest_artifact_path'
$summaryHasGuideArtifactPathField = Test-HasProperty -Object $summary -Name 'guide_artifact_path'
$summaryHasBoundaryArtifactPathField = Test-HasProperty -Object $summary -Name 'boundary_artifact_path'
$summaryHasBundleArtifactPathField = Test-HasProperty -Object $summary -Name 'artifact_bundle_path'
$summaryHasRefreshPathField = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_path'
$summaryHasRefreshErrorField = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_error'
$summaryHasHandoffPathField = Test-HasProperty -Object $summary -Name 'handoff_artifact_path'
$summaryHasHandoffErrorField = Test-HasProperty -Object $summary -Name 'handoff_artifact_error'
$summaryHasGeneratedAtUtcField = Test-HasProperty -Object $summary -Name 'generated_at_utc'
$summaryHasCompletedField = Test-HasProperty -Object $summary -Name 'completed'
$summaryHasFirstFailedPhaseField = Test-HasProperty -Object $summary -Name 'first_failed_phase'
$summaryHasSurfaceCheckStatusField = Test-HasProperty -Object $summary -Name 'surface_check_status'

$summaryMissingPathFields = [System.Collections.Generic.List[string]]::new()
Add-MissingField -List $summaryMissingPathFields -FieldName 'summary.artifact_root' -Present $summaryHasArtifactRootField
Add-MissingField -List $summaryMissingPathFields -FieldName 'summary.manifest_artifact_path' -Present $summaryHasManifestArtifactPathField
Add-MissingField -List $summaryMissingPathFields -FieldName 'summary.guide_artifact_path' -Present $summaryHasGuideArtifactPathField
Add-MissingField -List $summaryMissingPathFields -FieldName 'summary.boundary_artifact_path' -Present $summaryHasBoundaryArtifactPathField
Add-MissingField -List $summaryMissingPathFields -FieldName 'summary.artifact_bundle_path' -Present $summaryHasBundleArtifactPathField

$summaryMissingRunnerFields = [System.Collections.Generic.List[string]]::new()
Add-MissingField -List $summaryMissingRunnerFields -FieldName 'summary.refresh_chain_artifact_path' -Present $summaryHasRefreshPathField
Add-MissingField -List $summaryMissingRunnerFields -FieldName 'summary.refresh_chain_artifact_error' -Present $summaryHasRefreshErrorField
Add-MissingField -List $summaryMissingRunnerFields -FieldName 'summary.handoff_artifact_path' -Present $summaryHasHandoffPathField
Add-MissingField -List $summaryMissingRunnerFields -FieldName 'summary.handoff_artifact_error' -Present $summaryHasHandoffErrorField

$summaryMissingStatusFields = [System.Collections.Generic.List[string]]::new()
Add-MissingField -List $summaryMissingStatusFields -FieldName 'summary.generated_at_utc' -Present $summaryHasGeneratedAtUtcField
Add-MissingField -List $summaryMissingStatusFields -FieldName 'summary.completed' -Present $summaryHasCompletedField
Add-MissingField -List $summaryMissingStatusFields -FieldName 'summary.first_failed_phase' -Present $summaryHasFirstFailedPhaseField
Add-MissingField -List $summaryMissingStatusFields -FieldName 'summary.surface_check_status' -Present $summaryHasSurfaceCheckStatusField

$existingHelperLikelySafe = [bool](($summaryMissingPathFields.Count -eq 0) -and ($summaryMissingRunnerFields.Count -eq 0) -and ($summaryMissingStatusFields.Count -eq 0))

$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null

if ($summaryMissingPathFields.Count -gt 0) {
    $status = 'summary-artifact-paths-missing'
    $reason = 'The saved issue #3 summary still omits one or more artifact-path fields that the existing probe triage helper reads directly under strict mode.'
    $nextFocus = 'Repair the saved artifact-path fields first, then reopen the probe triage helper or the safer handoff-first checkpoints.'
    $recommendedCommand = $artifactPathRepairCommand
    $recommendedGuideCommand = $manifestSafeCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ($summaryMissingRunnerFields.Count -gt 0) {
    $status = 'runner-contract-missing'
    $reason = 'The saved issue #3 summary still omits one or more direct refresh or handoff runner-output fields that the existing probe triage helper reads directly under strict mode.'
    $nextFocus = 'Repair the saved runner-output contract first, then rerun the safe wiring audit before trusting the raw triage helper.'
    $recommendedCommand = $runnerContractRepairCommand
    $recommendedGuideCommand = $runnerWiringStatusSafeCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ($summaryMissingStatusFields.Count -gt 0) {
    $status = 'summary-status-fields-missing'
    $reason = 'The saved issue #3 summary still omits one or more status fields that the existing probe triage helper prints directly under strict mode.'
    $nextFocus = 'Regenerate the broader issue #3 summary so the raw triage helper can read the current status contract safely.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $handoffSafeCommand
    $nextArtifactToOpen = $SummaryPath
} else {
    $status = 'safe-to-run-existing-helper'
    $reason = 'The saved issue #3 summary exposes the artifact-path, runner-contract, and status fields that the existing probe triage helper expects under strict mode.'
    $nextFocus = 'Run the raw probe triage helper and follow its handoff-first guidance for the next narrowed Windows replay.'
    $recommendedCommand = $probeTriageCommand
    $recommendedGuideCommand = $handoffSafeCommand
    $nextArtifactToOpen = $SummaryPath
}

$report = [ordered]@{
    issue = 'Google issue #3 probe triage safe helper'
    purpose = 'Audit whether the existing issue #3 probe triage helper can run safely under strict mode for the current summary, and route the next replay to the safest helper when it cannot.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_readable = [bool]$manifestReadable
    summary_has_artifact_root_field = [bool]$summaryHasArtifactRootField
    summary_has_manifest_artifact_path_field = [bool]$summaryHasManifestArtifactPathField
    summary_has_guide_artifact_path_field = [bool]$summaryHasGuideArtifactPathField
    summary_has_boundary_artifact_path_field = [bool]$summaryHasBoundaryArtifactPathField
    summary_has_artifact_bundle_path_field = [bool]$summaryHasBundleArtifactPathField
    summary_has_refresh_chain_artifact_path_field = [bool]$summaryHasRefreshPathField
    summary_has_refresh_chain_artifact_error_field = [bool]$summaryHasRefreshErrorField
    summary_has_handoff_artifact_path_field = [bool]$summaryHasHandoffPathField
    summary_has_handoff_artifact_error_field = [bool]$summaryHasHandoffErrorField
    summary_has_generated_at_utc_field = [bool]$summaryHasGeneratedAtUtcField
    summary_has_completed_field = [bool]$summaryHasCompletedField
    summary_has_first_failed_phase_field = [bool]$summaryHasFirstFailedPhaseField
    summary_has_surface_check_status_field = [bool]$summaryHasSurfaceCheckStatusField
    summary_missing_path_fields = @($summaryMissingPathFields)
    summary_missing_runner_fields = @($summaryMissingRunnerFields)
    summary_missing_status_fields = @($summaryMissingStatusFields)
    existing_probe_triage_likely_safe = [bool]$existingHelperLikelySafe
    probe_triage_command = $probeTriageCommand
    broader_runner_command = $recommendedRunnerCommand
    artifact_path_repair_command = $artifactPathRepairCommand
    runner_contract_repair_command = $runnerContractRepairCommand
    runner_wiring_status_safe_command = $runnerWiringStatusSafeCommand
    runner_patch_targets_command = $runnerPatchTargetsCommand
    refresh_status_safe_command = $refreshStatusSafeCommand
    handoff_safe_command = $handoffSafeCommand
    manifest_safe_command = $manifestSafeCommand
    summary_guide_command = $summaryGuideCommand
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
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

Write-Host 'Google issue #3 probe triage safe helper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
Write-Host ("Manifest readable: {0}" -f $report.manifest_artifact_readable)
Write-Host ("Existing triage helper likely safe: {0}" -f $report.existing_probe_triage_likely_safe)
if ($report.summary_missing_path_fields.Count -gt 0) {
    Write-Host 'Missing summary path fields:'
    foreach ($fieldName in $report.summary_missing_path_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
if ($report.summary_missing_runner_fields.Count -gt 0) {
    Write-Host 'Missing summary runner fields:'
    foreach ($fieldName in $report.summary_missing_runner_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
if ($report.summary_missing_status_fields.Count -gt 0) {
    Write-Host 'Missing summary status fields:'
    foreach ($fieldName in $report.summary_missing_status_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
