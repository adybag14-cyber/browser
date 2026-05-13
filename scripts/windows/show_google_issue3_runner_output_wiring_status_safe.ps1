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
$artifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
if ([string]::IsNullOrWhiteSpace($artifactRoot)) {
    $artifactRoot = Split-Path -Parent $SummaryPath
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-runner-output-wiring-safe.json'
}

$broaderRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$artifactPathRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_artifact_paths.ps1'
$runnerOutputWiringSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$runnerOutputWiringCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$runnerPatchTargetsSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe.ps1'
$runnerPatchTargetsSafeRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe_route.ps1'
$runnerPatchTargetsCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
$runnerContractRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1'
$refreshStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe.ps1'

$configuredManifestPath = Get-OptionalPropertyValue -Object $summary -Name 'manifest_artifact_path'
$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredManifestPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
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
$manifestReadable = [bool]$manifestRecord

$summaryHasRefreshPathField = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_path'
$summaryHasRefreshErrorField = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_error'
$summaryHasHandoffPathField = Test-HasProperty -Object $summary -Name 'handoff_artifact_path'
$summaryHasHandoffErrorField = Test-HasProperty -Object $summary -Name 'handoff_artifact_error'
$manifestHasRefreshPathField = Test-HasProperty -Object $manifestRecord -Name 'refresh_chain_artifact_path'
$manifestHasRefreshErrorField = Test-HasProperty -Object $manifestRecord -Name 'refresh_chain_artifact_error'
$manifestHasHandoffPathField = Test-HasProperty -Object $manifestRecord -Name 'handoff_artifact_path'
$manifestHasHandoffErrorField = Test-HasProperty -Object $manifestRecord -Name 'handoff_artifact_error'

$runnerContractMissingFields = [System.Collections.Generic.List[string]]::new()
Add-MissingField -List $runnerContractMissingFields -FieldName 'summary.refresh_chain_artifact_path' -Present $summaryHasRefreshPathField
Add-MissingField -List $runnerContractMissingFields -FieldName 'summary.refresh_chain_artifact_error' -Present $summaryHasRefreshErrorField
Add-MissingField -List $runnerContractMissingFields -FieldName 'summary.handoff_artifact_path' -Present $summaryHasHandoffPathField
Add-MissingField -List $runnerContractMissingFields -FieldName 'summary.handoff_artifact_error' -Present $summaryHasHandoffErrorField
Add-MissingField -List $runnerContractMissingFields -FieldName 'manifest.refresh_chain_artifact_path' -Present $manifestHasRefreshPathField
Add-MissingField -List $runnerContractMissingFields -FieldName 'manifest.refresh_chain_artifact_error' -Present $manifestHasRefreshErrorField
Add-MissingField -List $runnerContractMissingFields -FieldName 'manifest.handoff_artifact_path' -Present $manifestHasHandoffPathField
Add-MissingField -List $runnerContractMissingFields -FieldName 'manifest.handoff_artifact_error' -Present $manifestHasHandoffErrorField

$runnerContractMissing = [bool]($runnerContractMissingFields.Count -gt 0)
$prereqFieldsSafe = [bool]($summaryHasArtifactRootField -and $summaryHasManifestArtifactPathField -and $manifestReadable)
$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null

if (-not $summaryHasArtifactRootField) {
    $status = 'summary-artifact-root-missing'
    $reason = 'The saved summary omits artifact_root, so the existing runner-output wiring helper can fail under strict mode before it reaches fallback path resolution.'
    $nextFocus = 'Regenerate the broader issue #3 validation summary first, then rerun this safe runner-output wiring helper before trusting the raw wiring audit.'
    $recommendedCommand = $broaderRunnerCommand
    $recommendedGuideCommand = $runnerOutputWiringSafeCommand
    $nextArtifactToOpen = $SummaryPath
} elseif (-not $summaryHasManifestArtifactPathField) {
    $status = 'summary-manifest-path-missing'
    $reason = 'The saved summary omits manifest_artifact_path, so the existing runner-output wiring helper can fail under strict mode before it reaches the manifest fallback path.'
    $nextFocus = 'Repair the saved validation artifact paths first, then rerun this safe helper before reopening the raw runner-output wiring audit.'
    $recommendedCommand = $artifactPathRepairCommand
    $recommendedGuideCommand = $runnerOutputWiringSafeCommand
    $nextArtifactToOpen = $SummaryPath
} elseif (-not $manifestExists) {
    $status = 'manifest-missing'
    $reason = 'The summary points at a manifest path, but the manifest file is still missing for the current issue #3 replay.'
    $nextFocus = 'Regenerate the broader runner outputs so the manifest exists, then reopen this safe helper before trusting the raw runner-output wiring audit.'
    $recommendedCommand = $broaderRunnerCommand
    $recommendedGuideCommand = $runnerOutputWiringSafeCommand
    $nextArtifactToOpen = $manifestPath
} elseif (-not $manifestReadable) {
    $status = 'manifest-unreadable'
    $reason = 'The manifest file exists but could not be parsed cleanly, so the existing runner-output wiring helper is not the safest next checkpoint yet.'
    $nextFocus = 'Regenerate the broader runner outputs, then rerun this safe helper once the manifest is readable before reopening the raw runner-output wiring audit.'
    $recommendedCommand = $broaderRunnerCommand
    $recommendedGuideCommand = $runnerOutputWiringSafeCommand
    $nextArtifactToOpen = $manifestPath
} elseif ($runnerContractMissing) {
    $status = 'runner-contract-missing'
    $reason = 'The saved summary and manifest are safe enough to inspect, but they still omit part of the direct refresh or handoff runner-output contract.'
    $nextFocus = 'Repair the saved runner-output contract first, use the safe patch-target route if the repair still leaves a gap, and only then rerun the existing wiring helper to confirm the contract is fully wired.'
    $recommendedCommand = $runnerContractRepairCommand
    $recommendedGuideCommand = $runnerPatchTargetsSafeRouteCommand
    $nextArtifactToOpen = $SummaryPath
} else {
    $status = 'safe-to-run-existing-helper'
    $reason = 'The saved summary and manifest expose the prerequisite fields the existing runner-output wiring helper expects under strict mode, and the direct runner-output contract is already present.'
    $nextFocus = 'Run the existing runner-output wiring helper or move on to the narrower refresh-status chain.'
    $recommendedCommand = $runnerOutputWiringCommand
    $recommendedGuideCommand = $refreshStatusSafeCommand
    $nextArtifactToOpen = $SummaryPath
}

$report = [ordered]@{
    issue = 'Google issue #3 runner output wiring safe helper'
    purpose = 'Check whether the existing runner-output wiring helper is safe to trust under strict mode for the current issue #3 summary and manifest.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    artifact_root = $artifactRoot
    summary_has_artifact_root_field = [bool]$summaryHasArtifactRootField
    summary_has_manifest_artifact_path_field = [bool]$summaryHasManifestArtifactPathField
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_readable = [bool]$manifestReadable
    manifest_artifact_error = $manifestError
    summary_has_refresh_chain_artifact_path_field = [bool]$summaryHasRefreshPathField
    summary_has_refresh_chain_artifact_error_field = [bool]$summaryHasRefreshErrorField
    summary_has_handoff_artifact_path_field = [bool]$summaryHasHandoffPathField
    summary_has_handoff_artifact_error_field = [bool]$summaryHasHandoffErrorField
    manifest_has_refresh_chain_artifact_path_field = [bool]$manifestHasRefreshPathField
    manifest_has_refresh_chain_artifact_error_field = [bool]$manifestHasRefreshErrorField
    manifest_has_handoff_artifact_path_field = [bool]$manifestHasHandoffPathField
    manifest_has_handoff_artifact_error_field = [bool]$manifestHasHandoffErrorField
    runner_contract_missing = [bool]$runnerContractMissing
    runner_contract_missing_fields = @($runnerContractMissingFields)
    prereq_fields_safe = [bool]$prereqFieldsSafe
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    broader_runner_command = $broaderRunnerCommand
    artifact_path_repair_command = $artifactPathRepairCommand
    runner_output_wiring_safe_command = $runnerOutputWiringSafeCommand
    runner_output_wiring_command = $runnerOutputWiringCommand
    runner_patch_targets_safe_command = $runnerPatchTargetsSafeCommand
    runner_patch_targets_safe_route_command = $runnerPatchTargetsSafeRouteCommand
    runner_patch_targets_command = $runnerPatchTargetsCommand
    runner_contract_repair_command = $runnerContractRepairCommand
    refresh_status_safe_command = $refreshStatusSafeCommand
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

Write-Host 'Google issue #3 runner output wiring safe helper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
Write-Host ("Manifest readable: {0}" -f $report.manifest_artifact_readable)
Write-Host ("Prereq fields safe: {0}" -f $report.prereq_fields_safe)
Write-Host ("Runner contract missing: {0}" -f $report.runner_contract_missing)
if ($report.manifest_artifact_error) {
    Write-Host ("Manifest error: {0}" -f $report.manifest_artifact_error)
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
Write-Host ("Safe wiring gate: {0}" -f $report.runner_output_wiring_safe_command)
Write-Host ("Safe patch-target route: {0}" -f $report.runner_patch_targets_safe_route_command)
Write-Host ("Safe patch targets: {0}" -f $report.runner_patch_targets_safe_command)
