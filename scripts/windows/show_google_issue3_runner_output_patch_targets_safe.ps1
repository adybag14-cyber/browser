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

function Get-ConfiguredValue {
    param(
        [object]$Primary,
        [object]$Fallback,
        [Parameter(Mandatory = $true)]
        [string]$FieldName
    )

    if ((Test-HasProperty -Object $Primary -Name $FieldName) -and -not [string]::IsNullOrWhiteSpace([string]$Primary.$FieldName)) {
        return [pscustomobject]@{
            value = $Primary.$FieldName
            source = 'summary'
        }
    }

    if ((Test-HasProperty -Object $Fallback -Name $FieldName) -and -not [string]::IsNullOrWhiteSpace([string]$Fallback.$FieldName)) {
        return [pscustomobject]@{
            value = $Fallback.$FieldName
            source = 'manifest'
        }
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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-runner-output-patch-targets-safe.json'
}

$broaderRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$artifactPathRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_artifact_paths.ps1'
$runnerOutputPatchTargetsCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
$runnerOutputWiringStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$runnerContractRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1'
$refreshStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_safe.ps1'

$configuredManifestPath = Get-OptionalPropertyValue -Object $summary -Name 'manifest_artifact_path'
$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredManifestPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
$manifestRecord = $null
$manifestError = $null
if ($manifestExists) {
    try {
        $manifestRecord = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
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

$missingFields = [System.Collections.Generic.List[string]]::new()
Add-MissingField -List $missingFields -FieldName 'summary.refresh_chain_artifact_path' -Present $summaryHasRefreshPathField
Add-MissingField -List $missingFields -FieldName 'summary.refresh_chain_artifact_error' -Present $summaryHasRefreshErrorField
Add-MissingField -List $missingFields -FieldName 'summary.handoff_artifact_path' -Present $summaryHasHandoffPathField
Add-MissingField -List $missingFields -FieldName 'summary.handoff_artifact_error' -Present $summaryHasHandoffErrorField
Add-MissingField -List $missingFields -FieldName 'manifest.refresh_chain_artifact_path' -Present $manifestHasRefreshPathField
Add-MissingField -List $missingFields -FieldName 'manifest.refresh_chain_artifact_error' -Present $manifestHasRefreshErrorField
Add-MissingField -List $missingFields -FieldName 'manifest.handoff_artifact_path' -Present $manifestHasHandoffPathField
Add-MissingField -List $missingFields -FieldName 'manifest.handoff_artifact_error' -Present $manifestHasHandoffErrorField

$refreshConfigured = Get-ConfiguredValue -Primary $summary -Fallback $manifestRecord -FieldName 'refresh_chain_artifact_path'
$handoffConfigured = Get-ConfiguredValue -Primary $summary -Fallback $manifestRecord -FieldName 'handoff_artifact_path'
$resolvedRefreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($refreshConfigured) { $refreshConfigured.value } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$resolvedHandoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($handoffConfigured) { $handoffConfigured.value } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'

$runnerContractMissing = [bool]($missingFields.Count -gt 0)
$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null

if (-not $summaryHasArtifactRootField) {
    $status = 'summary-artifact-root-missing'
    $reason = 'The saved summary omits artifact_root, so the raw patch-target helper can fail under strict mode before it reaches fallback artifact-root resolution.'
    $nextFocus = 'Regenerate the broader issue #3 runner outputs before trusting the raw patch-target helper.'
    $recommendedCommand = $broaderRunnerCommand
    $recommendedGuideCommand = $refreshStatusSafeCommand
    $nextArtifactToOpen = $SummaryPath
} elseif (-not $summaryHasManifestArtifactPathField) {
    $status = 'summary-manifest-path-missing'
    $reason = 'The saved summary omits manifest_artifact_path, so the raw patch-target helper can fail under strict mode before it resolves the fallback manifest location.'
    $nextFocus = 'Repair the saved validation artifact paths first, then reopen the raw patch-target helper.'
    $recommendedCommand = $artifactPathRepairCommand
    $recommendedGuideCommand = $runnerOutputPatchTargetsCommand
    $nextArtifactToOpen = $SummaryPath
} elseif (-not $manifestExists) {
    $status = 'safe-to-run-patch-targets-manifest-missing'
    $reason = 'The summary exposes the strict-mode prerequisite fields the raw patch-target helper expects, and that helper already falls back cleanly when the manifest file is missing.'
    $nextFocus = 'Use the raw patch-target helper to capture the direct refresh and handoff targets, then rerun the broader runner so the manifest is recreated with the repaired contract.'
    $recommendedCommand = $runnerOutputPatchTargetsCommand
    $recommendedGuideCommand = $broaderRunnerCommand
    $nextArtifactToOpen = $SummaryPath
} elseif (-not $manifestReadable) {
    $status = 'safe-to-run-patch-targets-manifest-unreadable'
    $reason = 'The summary exposes the strict-mode prerequisite fields the raw patch-target helper expects, and that helper can still derive the direct targets from the summary plus fallback paths even if the current manifest cannot be parsed.'
    $nextFocus = 'Use the raw patch-target helper to capture the direct target values, then rerun the broader runner so the manifest is regenerated cleanly.'
    $recommendedCommand = $runnerOutputPatchTargetsCommand
    $recommendedGuideCommand = $broaderRunnerCommand
    $nextArtifactToOpen = $manifestPath
} elseif ($runnerContractMissing) {
    $status = 'runner-contract-missing-safe-repair'
    $reason = 'The saved summary and manifest are safe enough to inspect, but they still omit part of the direct refresh or handoff runner-output contract.'
    $nextFocus = 'Run the bounded runner-output contract repair helper first, then reopen the safe wiring audit to confirm the saved outputs are fully wired before trusting narrower refresh or handoff helpers.'
    $recommendedCommand = $runnerContractRepairCommand
    $recommendedGuideCommand = $runnerOutputWiringStatusSafeCommand
    $nextArtifactToOpen = $SummaryPath
} else {
    $status = 'already-direct'
    $reason = 'The summary and manifest already expose the direct refresh and handoff runner-output contract, so there is nothing left for the raw patch-target helper to prepare.'
    $nextFocus = 'Skip patch-target work and move straight to the safe wiring audit or the narrower refresh-status helper chain.'
    $recommendedCommand = $runnerOutputWiringStatusSafeCommand
    $recommendedGuideCommand = $refreshStatusSafeCommand
    $nextArtifactToOpen = $SummaryPath
}

$report = [ordered]@{
    issue = 'Google issue #3 runner output patch targets safe helper'
    purpose = 'Check whether the raw patch-target helper is safe to trust under strict mode for the current issue #3 summary and point the next replay at the safest command.'
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
    resolved_refresh_artifact_path = $resolvedRefreshPath
    resolved_handoff_artifact_path = $resolvedHandoffPath
    summary_has_refresh_artifact_path_field = [bool]$summaryHasRefreshPathField
    summary_has_refresh_artifact_error_field = [bool]$summaryHasRefreshErrorField
    summary_has_handoff_artifact_path_field = [bool]$summaryHasHandoffPathField
    summary_has_handoff_artifact_error_field = [bool]$summaryHasHandoffErrorField
    manifest_has_refresh_artifact_path_field = [bool]$manifestHasRefreshPathField
    manifest_has_refresh_artifact_error_field = [bool]$manifestHasRefreshErrorField
    manifest_has_handoff_artifact_path_field = [bool]$manifestHasHandoffPathField
    manifest_has_handoff_artifact_error_field = [bool]$manifestHasHandoffErrorField
    runner_contract_missing = [bool]$runnerContractMissing
    missing_runner_fields = @($missingFields)
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    broader_runner_command = $broaderRunnerCommand
    artifact_path_repair_command = $artifactPathRepairCommand
    runner_output_patch_targets_command = $runnerOutputPatchTargetsCommand
    runner_output_wiring_status_safe_command = $runnerOutputWiringStatusSafeCommand
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

Write-Host 'Google issue #3 runner output patch targets safe helper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
Write-Host ("Manifest readable: {0}" -f $report.manifest_artifact_readable)
if ($report.manifest_artifact_error) {
    Write-Host ("Manifest error: {0}" -f $report.manifest_artifact_error)
}
Write-Host ("Summary has artifact_root: {0}" -f $report.summary_has_artifact_root_field)
Write-Host ("Summary has manifest_artifact_path: {0}" -f $report.summary_has_manifest_artifact_path_field)
Write-Host ("Runner contract missing: {0}" -f $report.runner_contract_missing)
if ($report.missing_runner_fields.Count -gt 0) {
    Write-Host 'Missing runner-contract fields:'
    foreach ($fieldName in $report.missing_runner_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
Write-Host ("Refresh target: {0}" -f $report.resolved_refresh_artifact_path)
Write-Host ("Handoff target: {0}" -f $report.resolved_handoff_artifact_path)
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
