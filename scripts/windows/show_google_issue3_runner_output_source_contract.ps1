[CmdletBinding()]
param(
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

function Get-DirectFieldAssignmentCount {
    param(
        [string]$SourceText,
        [Parameter(Mandatory = $true)]
        [string]$AssignmentText
    )

    if ([string]::IsNullOrWhiteSpace($SourceText)) {
        return 0
    }

    return [regex]::Matches($SourceText, [regex]::Escape($AssignmentText)).Count
}

$repoRoot = Resolve-RepoRoot $PSScriptRoot
$artifactRoot = Join-Path $repoRoot "tmp-browser-smoke\headed-probe"
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot "google-issue3-runner-output-source-contract.json"
}
if (-not (Test-Path -LiteralPath $artifactRoot)) {
    New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
}

$runnerScriptPath = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation.ps1'
$runnerScriptExists = Test-Path -LiteralPath $runnerScriptPath -PathType Leaf
$runnerScriptSource = if ($runnerScriptExists) {
    Get-Content -LiteralPath $runnerScriptPath -Raw
} else {
    $null
}

$runnerRefreshPathAssignmentCount = Get-DirectFieldAssignmentCount -SourceText $runnerScriptSource -AssignmentText 'refresh_chain_artifact_path = $RefreshChainArtifactPath'
$runnerRefreshErrorAssignmentCount = Get-DirectFieldAssignmentCount -SourceText $runnerScriptSource -AssignmentText 'refresh_chain_artifact_error = $RefreshChainArtifactError'
$runnerHandoffPathAssignmentCount = Get-DirectFieldAssignmentCount -SourceText $runnerScriptSource -AssignmentText 'handoff_artifact_path = $HandoffArtifactPath'
$runnerHandoffErrorAssignmentCount = Get-DirectFieldAssignmentCount -SourceText $runnerScriptSource -AssignmentText 'handoff_artifact_error = $HandoffArtifactError'

$refreshPathFullyWired = $runnerRefreshPathAssignmentCount -ge 2
$refreshErrorFullyWired = $runnerRefreshErrorAssignmentCount -ge 2
$handoffPathFullyWired = $runnerHandoffPathAssignmentCount -ge 2
$handoffErrorFullyWired = $runnerHandoffErrorAssignmentCount -ge 2
$refreshContractFullyWired = [bool]($refreshPathFullyWired -and $refreshErrorFullyWired)
$handoffContractFullyWired = [bool]($handoffPathFullyWired -and $handoffErrorFullyWired)
$sourceDirectFieldsFullyWired = [bool]($refreshContractFullyWired -and $handoffContractFullyWired)
$refreshContractIncomplete = -not $refreshContractFullyWired
$handoffContractIncomplete = -not $handoffContractFullyWired
$missingFieldCount = @(
    if (-not $refreshPathFullyWired) { 'refresh_chain_artifact_path' }
    if (-not $refreshErrorFullyWired) { 'refresh_chain_artifact_error' }
    if (-not $handoffPathFullyWired) { 'handoff_artifact_path' }
    if (-not $handoffErrorFullyWired) { 'handoff_artifact_error' }
).Count

$patchTargetsSafeRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe_route.ps1'
$runnerOutputWiringStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

$status = $null
$reason = $null
$nextFocus = $null
if (-not $runnerScriptExists) {
    $status = 'runner-script-missing'
    $reason = 'The issue #3 recommended validation runner script is not present at the expected path, so the source contract cannot be audited yet.'
    $nextFocus = 'Restore or recreate the recommended validation runner before relying on source-contract or saved-output helpers.'
} elseif ($sourceDirectFieldsFullyWired) {
    $status = 'source-direct-fields-present'
    $reason = 'The runner source already writes direct refresh and handoff path plus error fields at least twice, which matches the summary and manifest output objects.'
    $nextFocus = 'Regenerate the issue #3 recommended validation outputs on Windows and confirm the saved artifacts with the safe runner-output wiring helper.'
} elseif ($refreshContractIncomplete -and (-not $handoffContractIncomplete)) {
    $status = 'source-refresh-fields-missing-only'
    $reason = 'The runner source already appears to wire the direct handoff fields into both output objects, but the refresh path or refresh error fields are still missing from at least one object.'
    $nextFocus = 'Use the patch-target safe route to land the direct refresh field wiring in the recommended runner, then rerun the wiring audit.'
} elseif ($handoffContractIncomplete -and (-not $refreshContractIncomplete)) {
    $status = 'source-handoff-fields-missing-only'
    $reason = 'The runner source already appears to wire the direct refresh fields into both output objects, but the handoff path or handoff error fields are still missing from at least one object.'
    $nextFocus = 'Use the patch-target safe route to land the direct handoff field wiring in the recommended runner, then rerun the wiring audit.'
} else {
    $status = 'source-direct-fields-missing'
    $reason = 'The runner source still misses at least one direct refresh or handoff field assignment in the saved summary or manifest object blocks.'
    $nextFocus = 'Use the patch-target safe route to compute the exact direct field values, patch the recommended runner, rerun the validation flow, and confirm the saved outputs with the safe wiring audit.'
}

$report = [ordered]@{
    issue = 'Google issue #3 runner output source contract'
    purpose = 'Audit whether the recommended validation runner source currently writes direct refresh and handoff path and error fields into both the saved summary and manifest outputs.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    artifact_path = $ArtifactPath
    runner_script_path = $runnerScriptPath
    runner_script_exists = [bool]$runnerScriptExists
    refresh_contract_fully_wired = [bool]$refreshContractFullyWired
    refresh_path_assignment_count = $runnerRefreshPathAssignmentCount
    refresh_error_assignment_count = $runnerRefreshErrorAssignmentCount
    handoff_contract_fully_wired = [bool]$handoffContractFullyWired
    handoff_path_assignment_count = $runnerHandoffPathAssignmentCount
    handoff_error_assignment_count = $runnerHandoffErrorAssignmentCount
    source_direct_fields_fully_wired = [bool]$sourceDirectFieldsFullyWired
    refresh_contract_incomplete = [bool]$refreshContractIncomplete
    handoff_contract_incomplete = [bool]$handoffContractIncomplete
    missing_field_count = $missingFieldCount
    recommended_patch_target = if ($sourceDirectFieldsFullyWired) { $null } else { 'scripts/windows/run_google_issue3_recommended_validation.ps1' }
    recommended_patch_helper_command = $patchTargetsSafeRouteCommand
    recommended_regeneration_command = $recommendedRunnerCommand
    recommended_verification_command = $runnerOutputWiringStatusSafeCommand
    status = $status
    reason = $reason
    next_focus = $nextFocus
}

$report | ConvertTo-Json -Depth 5 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 runner output source contract'
Write-Host ''
Write-Host ("Runner:    {0}" -f $report.runner_script_path)
Write-Host ("Exists:    {0}" -f $report.runner_script_exists)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Refresh path assignments: {0}" -f $report.refresh_path_assignment_count)
Write-Host ("Refresh error assignments: {0}" -f $report.refresh_error_assignment_count)
Write-Host ("Handoff path assignments: {0}" -f $report.handoff_path_assignment_count)
Write-Host ("Handoff error assignments: {0}" -f $report.handoff_error_assignment_count)
Write-Host ("Refresh fully wired: {0}" -f $report.refresh_contract_fully_wired)
Write-Host ("Handoff fully wired: {0}" -f $report.handoff_contract_fully_wired)
Write-Host ("Source fully wired: {0}" -f $report.source_direct_fields_fully_wired)
Write-Host ("Missing field count: {0}" -f $report.missing_field_count)
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
if ($report.recommended_patch_target) {
    Write-Host ("Patch:  {0}" -f $report.recommended_patch_target)
}
Write-Host ("Guide:  {0}" -f $report.recommended_patch_helper_command)
Write-Host ("Rerun:  {0}" -f $report.recommended_regeneration_command)
Write-Host ("Verify: {0}" -f $report.recommended_verification_command)
