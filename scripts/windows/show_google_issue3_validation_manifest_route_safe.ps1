[CmdletBinding()]
param(
    [string]$SummaryPath,
    [string]$ArtifactPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-RepoRoot([string]$StartPath) {
    if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
        return $env:LIGHTPANDA_REPO_ROOT
    }

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor 'build.zig')) {
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
    $SummaryPath = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json'
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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-validation-manifest-route-safe.json'
}

$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$manifestGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest.ps1'
$manifestSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest_safe.ps1'
$handoffSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe.ps1'
$refreshStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_safe.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
$runnerWiringStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$runnerPatchTargetsSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe.ps1'
$runnerContractRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1'
$manifestContractRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_manifest_contract.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'

$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath (Get-OptionalPropertyValue -Object $summary -Name 'manifest_artifact_path') -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
$manifestRecord = $null
$manifestError = $null
if ($manifestExists) {
    try {
        $manifestRecord = Read-ArtifactJson $manifestPath
    } catch {
        $manifestError = $_.Exception.Message
    }
}

$summaryMissingRunnerFields = [System.Collections.Generic.List[string]]::new()
Add-MissingField -List $summaryMissingRunnerFields -FieldName 'summary.refresh_chain_artifact_path' -Present (Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_path')
Add-MissingField -List $summaryMissingRunnerFields -FieldName 'summary.refresh_chain_artifact_error' -Present (Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_error')
Add-MissingField -List $summaryMissingRunnerFields -FieldName 'summary.handoff_artifact_path' -Present (Test-HasProperty -Object $summary -Name 'handoff_artifact_path')
Add-MissingField -List $summaryMissingRunnerFields -FieldName 'summary.handoff_artifact_error' -Present (Test-HasProperty -Object $summary -Name 'handoff_artifact_error')

$manifestMissingRunnerFields = [System.Collections.Generic.List[string]]::new()
Add-MissingField -List $manifestMissingRunnerFields -FieldName 'manifest.refresh_chain_artifact_path' -Present (Test-HasProperty -Object $manifestRecord -Name 'refresh_chain_artifact_path')
Add-MissingField -List $manifestMissingRunnerFields -FieldName 'manifest.refresh_chain_artifact_error' -Present (Test-HasProperty -Object $manifestRecord -Name 'refresh_chain_artifact_error')
Add-MissingField -List $manifestMissingRunnerFields -FieldName 'manifest.handoff_artifact_path' -Present (Test-HasProperty -Object $manifestRecord -Name 'handoff_artifact_path')
Add-MissingField -List $manifestMissingRunnerFields -FieldName 'manifest.handoff_artifact_error' -Present (Test-HasProperty -Object $manifestRecord -Name 'handoff_artifact_error')

$manifestGuideFieldNames = @(
    'summary_path',
    'guide_artifact_path',
    'boundary_artifact_path',
    'artifact_bundle_path',
    'artifact_bundle_error',
    'handoff_artifact_path',
    'handoff_artifact_error',
    'refresh_chain_artifact_path',
    'refresh_chain_artifact_error',
    'surface_check_artifact_path',
    'phase_artifact_root',
    'first_failed_phase_primary_json_artifact_path',
    'manual_fixture_replay_command',
    'manual_fixture_replay_available'
)
$manifestGuideMissingFields = [System.Collections.Generic.List[string]]::new()
foreach ($fieldName in $manifestGuideFieldNames) {
    Add-MissingField -List $manifestGuideMissingFields -FieldName ("manifest.$fieldName") -Present (Test-HasProperty -Object $manifestRecord -Name $fieldName)
}

$configuredSummaryRefreshPath = Get-OptionalPropertyValue -Object $summary -Name 'refresh_chain_artifact_path'
$configuredManifestRefreshPath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'refresh_chain_artifact_path'
$configuredSummaryHandoffPath = Get-OptionalPropertyValue -Object $summary -Name 'handoff_artifact_path'
$configuredManifestHandoffPath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'handoff_artifact_path'

$refreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if (-not [string]::IsNullOrWhiteSpace($configuredSummaryRefreshPath)) { $configuredSummaryRefreshPath } elseif (-not [string]::IsNullOrWhiteSpace($configuredManifestRefreshPath)) { $configuredManifestRefreshPath } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if (-not [string]::IsNullOrWhiteSpace($configuredSummaryHandoffPath)) { $configuredSummaryHandoffPath } elseif (-not [string]::IsNullOrWhiteSpace($configuredManifestHandoffPath)) { $configuredManifestHandoffPath } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'

$refreshExists = Test-Path -LiteralPath $refreshPath -PathType Leaf
$refreshRecord = $null
$refreshError = $null
if ($refreshExists) {
    try {
        $refreshRecord = Read-ArtifactJson $refreshPath
    } catch {
        $refreshError = $_.Exception.Message
    }
}
$refreshMatchesSummary = $false
if ($refreshRecord -and -not [string]::IsNullOrWhiteSpace($refreshRecord.summary_path)) {
    $refreshMatchesSummary = ([System.IO.Path]::GetFullPath($refreshRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}

$handoffExists = Test-Path -LiteralPath $handoffPath -PathType Leaf

$runnerContractMissing = [bool](($summaryMissingRunnerFields.Count -gt 0) -or ($manifestMissingRunnerFields.Count -gt 0))
$manifestGuideContractMissing = [bool](($summaryMissingRunnerFields.Count -gt 0) -or ($manifestGuideMissingFields.Count -gt 0))
$existingManifestGuideLikelySafe = [bool]((-not $manifestError) -and (-not $manifestGuideContractMissing) -and $refreshMatchesSummary)

$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null

if (-not $manifestExists) {
    $status = 'manifest-missing'
    $reason = 'The saved manifest is missing for the current summary, so the next replay should regenerate the broader issue #3 outputs before trusting the manifest or handoff helpers.'
    $nextFocus = 'Rerun the broader issue #3 validation ladder, then reopen the saved summary and manifest artifacts.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $summaryGuideCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ($manifestError) {
    $status = 'manifest-unreadable'
    $reason = 'The saved manifest could not be read cleanly, so the next replay should use the safe runner wiring audit instead of the older raw helper chain.'
    $nextFocus = 'Rerun the broader validation ladder or inspect the safe runner wiring report before trusting narrower manifest guidance again.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $runnerWiringStatusSafeCommand
    $nextArtifactToOpen = $manifestPath
} elseif ($runnerContractMissing) {
    $status = 'runner-contract-missing'
    $reason = 'The current summary or manifest still omits one or more direct refresh or handoff runner-output fields, so the next replay should stay on the newer safe patch-target and wiring helpers.'
    $nextFocus = 'Use the safe patch-target helper to see the exact runner fields that still need wiring, then confirm the repaired contract with the safe wiring audit.'
    $recommendedCommand = $runnerPatchTargetsSafeCommand
    $recommendedGuideCommand = $runnerWiringStatusSafeCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ($manifestGuideMissingFields.Count -gt 0) {
    $status = 'manifest-guide-contract-missing'
    $reason = 'The broader runner contract is mostly present, but the manifest still omits additional fields that the raw manifest guide reads directly under strict mode.'
    $nextFocus = 'Repair the saved manifest contract first, then rerun the safe manifest audit before trusting the raw manifest guide again.'
    $recommendedCommand = $manifestContractRepairCommand
    $recommendedGuideCommand = $manifestSafeCommand
    $nextArtifactToOpen = $manifestPath
} elseif ((-not $refreshExists) -or (-not $refreshMatchesSummary) -or $refreshError) {
    $status = 'refresh-state-needs-rebuild'
    $reason = 'The saved refresh artifact is missing, unreadable, or belongs to a different summary, so the helper chain should be refreshed before using the raw manifest guide.'
    $nextFocus = 'Refresh the saved helper chain from the current summary, then reopen the safe refresh checkpoint before proceeding to the manifest or handoff guides.'
    $recommendedCommand = $refreshChainCommand
    $recommendedGuideCommand = $refreshStatusSafeCommand
    $nextArtifactToOpen = if ($refreshExists) { $refreshPath } else { $SummaryPath }
} else {
    $status = 'safe-to-run-manifest-guide'
    $reason = 'The manifest carries the fields the raw manifest guide expects, and the saved refresh artifact matches the current summary.'
    $nextFocus = 'Use the raw manifest guide, then continue to the safe handoff checkpoint for the next narrowed Windows replay.'
    $recommendedCommand = $manifestGuideCommand
    $recommendedGuideCommand = $handoffSafeCommand
    $nextArtifactToOpen = $manifestPath
}

$report = [ordered]@{
    issue = 'Google issue #3 validation manifest route safe helper'
    purpose = 'Route the next issue #3 manifest replay toward the newer safe patch-target and wiring helpers whenever the saved runner contract is still incomplete.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_error = $manifestError
    refresh_artifact_path = $refreshPath
    refresh_artifact_exists = [bool]$refreshExists
    refresh_artifact_error = $refreshError
    refresh_matches_summary = [bool]$refreshMatchesSummary
    handoff_artifact_path = $handoffPath
    handoff_artifact_exists = [bool]$handoffExists
    summary_missing_runner_fields = @($summaryMissingRunnerFields)
    manifest_missing_runner_fields = @($manifestMissingRunnerFields)
    manifest_guide_missing_fields = @($manifestGuideMissingFields)
    existing_manifest_guide_likely_safe = [bool]$existingManifestGuideLikelySafe
    broader_runner_command = $recommendedRunnerCommand
    manifest_guide_command = $manifestGuideCommand
    manifest_safe_command = $manifestSafeCommand
    handoff_safe_command = $handoffSafeCommand
    refresh_status_safe_command = $refreshStatusSafeCommand
    refresh_chain_command = $refreshChainCommand
    runner_wiring_status_safe_command = $runnerWiringStatusSafeCommand
    runner_patch_targets_safe_command = $runnerPatchTargetsSafeCommand
    runner_contract_repair_command = $runnerContractRepairCommand
    manifest_contract_repair_command = $manifestContractRepairCommand
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

Write-Host 'Google issue #3 validation manifest route safe helper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
if ($report.manifest_artifact_error) {
    Write-Host ("Manifest error: {0}" -f $report.manifest_artifact_error)
}
Write-Host ("Refresh:   {0}" -f $report.refresh_artifact_path)
Write-Host ("Refresh exists: {0}" -f $report.refresh_artifact_exists)
Write-Host ("Refresh matches summary: {0}" -f $report.refresh_matches_summary)
if ($report.refresh_artifact_error) {
    Write-Host ("Refresh error: {0}" -f $report.refresh_artifact_error)
}
Write-Host ("Handoff:   {0}" -f $report.handoff_artifact_path)
Write-Host ("Handoff exists: {0}" -f $report.handoff_artifact_exists)
Write-Host ("Existing manifest guide likely safe: {0}" -f $report.existing_manifest_guide_likely_safe)
if ($report.summary_missing_runner_fields.Count -gt 0) {
    Write-Host 'Summary runner fields missing:'
    foreach ($fieldName in $report.summary_missing_runner_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
if ($report.manifest_missing_runner_fields.Count -gt 0) {
    Write-Host 'Manifest runner fields missing:'
    foreach ($fieldName in $report.manifest_missing_runner_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
if ($report.manifest_guide_missing_fields.Count -gt 0) {
    Write-Host 'Manifest-guide fields missing:'
    foreach ($fieldName in $report.manifest_guide_missing_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
