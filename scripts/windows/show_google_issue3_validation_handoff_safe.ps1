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
$artifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
if ([string]::IsNullOrWhiteSpace($artifactRoot)) {
    $artifactRoot = Split-Path -Parent $SummaryPath
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot "google-issue3-validation-handoff-safe.json"
}

$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$refreshStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
$handoffSafeRefreshRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe_refresh_route.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'
$runnerWiringStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$runnerWiringStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$runnerPatchTargetsCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
$runnerContractRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1'

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
if ($manifestRecord) {
    Add-MissingField -List $missingFields -FieldName 'manifest.refresh_chain_artifact_path' -Present $manifestHasRefreshPathField
    Add-MissingField -List $missingFields -FieldName 'manifest.refresh_chain_artifact_error' -Present $manifestHasRefreshErrorField
    Add-MissingField -List $missingFields -FieldName 'manifest.handoff_artifact_path' -Present $manifestHasHandoffPathField
    Add-MissingField -List $missingFields -FieldName 'manifest.handoff_artifact_error' -Present $manifestHasHandoffErrorField
}

$configuredSummaryRefreshPath = Get-OptionalPropertyValue -Object $summary -Name 'refresh_chain_artifact_path'
$configuredSummaryHandoffPath = Get-OptionalPropertyValue -Object $summary -Name 'handoff_artifact_path'
$configuredManifestRefreshPath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'refresh_chain_artifact_path'
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
$refreshSummaryPath = Get-OptionalPropertyValue -Object $refreshRecord -Name 'summary_path'
if (-not [string]::IsNullOrWhiteSpace($refreshSummaryPath)) {
    $refreshMatchesSummary = ([System.IO.Path]::GetFullPath($refreshSummaryPath)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}

$handoffExists = Test-Path -LiteralPath $handoffPath -PathType Leaf
$handoffRecord = $null
$handoffError = $null
if ($handoffExists) {
    try {
        $handoffRecord = Read-ArtifactJson $handoffPath
    } catch {
        $handoffError = $_.Exception.Message
    }
}
$handoffMatchesSummary = $false
$handoffSummaryPath = Get-OptionalPropertyValue -Object $handoffRecord -Name 'summary_path'
if (-not [string]::IsNullOrWhiteSpace($handoffSummaryPath)) {
    $handoffMatchesSummary = ([System.IO.Path]::GetFullPath($handoffSummaryPath)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}

$runnerContractMissing = $missingFields.Count -gt 0
$existingHelperLikelySafe = [bool]((-not $runnerContractMissing) -and (-not $manifestError) -and $refreshExists -and $refreshMatchesSummary -and (-not $refreshError))

$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null

if ($manifestError) {
    $status = 'manifest-unreadable'
    $reason = 'The saved manifest could not be read cleanly, so the current handoff helper cannot rely on manifest-backed runner contract recovery.'
    $nextFocus = 'Regenerate the manifest from the recommended runner, then reopen the safe runner wiring audit before trusting the existing handoff helper.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $runnerWiringStatusSafeCommand
    $nextArtifactToOpen = if ($manifestExists) { $manifestPath } else { $SummaryPath }
} elseif ($runnerContractMissing) {
    $status = 'runner-contract-missing'
    $reason = 'The current summary or manifest still omits at least one direct refresh or handoff field that the existing handoff helper reads under strict mode, but the branch now includes a bounded repair helper for normalizing those saved outputs immediately after a run.'
    $nextFocus = 'Run the runner-output contract repair helper first, then rerun the safe wiring audit before trusting the existing handoff helper again.'
    $recommendedCommand = $runnerContractRepairCommand
    $recommendedGuideCommand = $runnerWiringStatusSafeCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ((-not $refreshExists) -or (-not $refreshMatchesSummary) -or $refreshError) {
    $status = 'refresh-state-needs-rebuild'
    $reason = 'The refresh artifact is missing, unreadable, or belongs to a different summary, so the helper chain should be refreshed before using the narrower handoff path.'
    $nextFocus = 'Reopen the safe handoff refresh route so it can re-check the current handoff state and immediately continue through the narrower refresh-safe checkpoint.'
    $recommendedCommand = $handoffSafeRefreshRouteCommand
    $recommendedGuideCommand = $refreshStatusSafeCommand
    $nextArtifactToOpen = if ($refreshExists) { $refreshPath } else { $SummaryPath }
} else {
    $status = 'safe-to-run-handoff'
    $reason = 'The direct runner contract fields are present and the refresh artifact matches the current summary, so the existing handoff helper is the right next checkpoint.'
    $nextFocus = 'Use the existing handoff helper or open the saved handoff artifact to continue the next narrowed Windows replay.'
    $recommendedCommand = $handoffGuideCommand
    $recommendedGuideCommand = $handoffGuideCommand
    $nextArtifactToOpen = if ($handoffExists) { $handoffPath } else { $SummaryPath }
}

$report = [ordered]@{
    issue = 'Google issue #3 validation handoff safe helper'
    purpose = 'Audit whether the current handoff helper can be trusted under strict mode before the runner-side direct field patch lands, and point the next replay at the safest follow-up command.'
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
    handoff_artifact_error = $handoffError
    handoff_matches_summary = [bool]$handoffMatchesSummary
    summary_has_refresh_artifact_path_field = [bool]$summaryHasRefreshPathField
    summary_has_refresh_artifact_error_field = [bool]$summaryHasRefreshErrorField
    summary_has_handoff_artifact_path_field = [bool]$summaryHasHandoffPathField
    summary_has_handoff_artifact_error_field = [bool]$summaryHasHandoffErrorField
    manifest_has_refresh_artifact_path_field = [bool]$manifestHasRefreshPathField
    manifest_has_refresh_artifact_error_field = [bool]$manifestHasRefreshErrorField
    manifest_has_handoff_artifact_path_field = [bool]$manifestHasHandoffPathField
    manifest_has_handoff_artifact_error_field = [bool]$manifestHasHandoffErrorField
    existing_handoff_helper_likely_safe = [bool]$existingHelperLikelySafe
    runner_contract_missing = [bool]$runnerContractMissing
    missing_runner_fields = @($missingFields)
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    runner_wiring_status_command = $runnerWiringStatusCommand
    runner_wiring_status_safe_command = $runnerWiringStatusSafeCommand
    runner_patch_targets_command = $runnerPatchTargetsCommand
    runner_contract_repair_command = $runnerContractRepairCommand
    refresh_status_command = $refreshStatusCommand
    refresh_status_safe_command = $refreshStatusSafeCommand
    refresh_chain_command = $refreshChainCommand
    handoff_safe_refresh_route_command = $handoffSafeRefreshRouteCommand
    handoff_guide_command = $handoffGuideCommand
    next_focus = $nextFocus
    reason = $reason
    next_artifact_to_open = $nextArtifactToOpen
    status = $status
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host 'Google issue #3 validation handoff safe helper'
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
Write-Host ("Handoff matches summary: {0}" -f $report.handoff_matches_summary)
if ($report.handoff_artifact_error) {
    Write-Host ("Handoff error: {0}" -f $report.handoff_artifact_error)
}
Write-Host ("Existing handoff helper likely safe: {0}" -f $report.existing_handoff_helper_likely_safe)
Write-Host ("Runner contract missing: {0}" -f $report.runner_contract_missing)
if ($report.missing_runner_fields.Count -gt 0) {
    Write-Host 'Missing runner fields:'
    foreach ($fieldName in $report.missing_runner_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
