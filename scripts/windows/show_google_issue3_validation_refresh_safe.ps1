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
    $ArtifactPath = Join-Path $artifactRoot "google-issue3-validation-refresh-safe.json"
}

$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
$bundleGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$runnerWiringStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
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
$configuredManifestRefreshPath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'refresh_chain_artifact_path'
$configuredSummaryHandoffPath = Get-OptionalPropertyValue -Object $summary -Name 'handoff_artifact_path'
$configuredManifestHandoffPath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'handoff_artifact_path'
$configuredBundlePath = Get-OptionalPropertyValue -Object $summary -Name 'artifact_bundle_path'

$refreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if (-not [string]::IsNullOrWhiteSpace($configuredSummaryRefreshPath)) { $configuredSummaryRefreshPath } elseif (-not [string]::IsNullOrWhiteSpace($configuredManifestRefreshPath)) { $configuredManifestRefreshPath } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if (-not [string]::IsNullOrWhiteSpace($configuredSummaryHandoffPath)) { $configuredSummaryHandoffPath } elseif (-not [string]::IsNullOrWhiteSpace($configuredManifestHandoffPath)) { $configuredManifestHandoffPath } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
$bundlePath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredBundlePath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json'

$bundleExists = Test-Path -LiteralPath $bundlePath -PathType Leaf
$bundleRecord = $null
$bundleError = if ((Test-HasProperty -Object $summary -Name 'artifact_bundle_error') -and -not [string]::IsNullOrWhiteSpace([string]$summary.artifact_bundle_error)) {
    $summary.artifact_bundle_error
} else {
    $null
}
if ($bundleExists) {
    try {
        $bundleRecord = Read-ArtifactJson $bundlePath
    } catch {
        $bundleError = $_.Exception.Message
    }
}
$bundleStatus = if ($bundleRecord -and $bundleRecord.status) {
    $bundleRecord.status
} elseif ($bundleError) {
    'helper-error'
} elseif ($bundleExists) {
    'present-unreadable'
} else {
    'missing'
}

$refreshExists = Test-Path -LiteralPath $refreshPath -PathType Leaf
$refreshRecord = $null
$refreshError = if ((Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_error') -and -not [string]::IsNullOrWhiteSpace([string]$summary.refresh_chain_artifact_error)) {
    $summary.refresh_chain_artifact_error
} elseif ((Test-HasProperty -Object $manifestRecord -Name 'refresh_chain_artifact_error') -and -not [string]::IsNullOrWhiteSpace([string]$manifestRecord.refresh_chain_artifact_error)) {
    $manifestRecord.refresh_chain_artifact_error
} else {
    $null
}
if ($refreshExists) {
    try {
        $refreshRecord = Read-ArtifactJson $refreshPath
    } catch {
        $refreshError = $_.Exception.Message
    }
}
$refreshStatus = if ($refreshRecord -and $refreshRecord.status) {
    $refreshRecord.status
} elseif ($refreshError) {
    'helper-error'
} elseif ($refreshExists) {
    'present-unreadable'
} else {
    'missing'
}
$refreshMatchesSummary = $false
if ($refreshRecord -and -not [string]::IsNullOrWhiteSpace($refreshRecord.summary_path)) {
    $refreshMatchesSummary = ([System.IO.Path]::GetFullPath($refreshRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}

$handoffExists = Test-Path -LiteralPath $handoffPath -PathType Leaf
$handoffRecord = $null
$handoffError = if ((Test-HasProperty -Object $summary -Name 'handoff_artifact_error') -and -not [string]::IsNullOrWhiteSpace([string]$summary.handoff_artifact_error)) {
    $summary.handoff_artifact_error
} elseif ((Test-HasProperty -Object $manifestRecord -Name 'handoff_artifact_error') -and -not [string]::IsNullOrWhiteSpace([string]$manifestRecord.handoff_artifact_error)) {
    $manifestRecord.handoff_artifact_error
} else {
    $null
}
if ($handoffExists) {
    try {
        $handoffRecord = Read-ArtifactJson $handoffPath
    } catch {
        $handoffError = $_.Exception.Message
    }
}
$handoffMatchesSummary = $false
if ($handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffRecord.summary_path)) {
    $handoffMatchesSummary = ([System.IO.Path]::GetFullPath($handoffRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}

$runnerContractMissing = $missingFields.Count -gt 0
$existingRefreshHelperLikelySafe = [bool]((-not $manifestError) -and (-not $runnerContractMissing))
$bundleReady = [bool]($bundleStatus -eq 'complete')
$refreshArtifactReady = [bool]($refreshExists -and $refreshRecord -and (-not $refreshError) -and $refreshMatchesSummary)

$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null

if ($manifestError) {
    $status = 'manifest-unreadable'
    $reason = 'The saved manifest could not be read cleanly, so the narrower refresh flow should not rely on manifest-backed runner contract recovery yet.'
    $nextFocus = 'Regenerate the manifest from the recommended runner, then reopen the runner wiring audit before trusting the existing refresh helper.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $runnerWiringStatusCommand
    $nextArtifactToOpen = if ($manifestExists) { $manifestPath } else { $SummaryPath }
} elseif ($runnerContractMissing) {
    $status = 'runner-contract-missing'
    $reason = 'The current summary or manifest still omits at least one direct refresh or handoff runner-output field, so the next replay should repair that saved contract before trusting the narrower refresh flow.'
    $nextFocus = 'Run the runner-output contract repair helper first, then rerun the wiring audit before reopening the existing refresh helper.'
    $recommendedCommand = $runnerContractRepairCommand
    $recommendedGuideCommand = $runnerWiringStatusCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ($bundleError) {
    $status = 'bundle-unreadable'
    $reason = 'The saved artifact-bundle record could not be read cleanly, so the helper chain should be refreshed before trusting the current refresh status.'
    $nextFocus = 'Refresh the helper chain from the current summary, then reopen the bundle and refresh artifacts.'
    $recommendedCommand = $refreshChainCommand
    $recommendedGuideCommand = $bundleGuideCommand
    $nextArtifactToOpen = if ($bundleExists) { $bundlePath } else { $SummaryPath }
} elseif (-not $bundleReady) {
    $status = 'bundle-incomplete'
    $reason = 'The saved artifact-bundle record is missing or still reports an incomplete helper chain for the current summary.'
    $nextFocus = 'Refresh the helper chain from the current summary before trusting the existing refresh status helper.'
    $recommendedCommand = $refreshChainCommand
    $recommendedGuideCommand = $bundleGuideCommand
    $nextArtifactToOpen = if ($bundleExists) { $bundlePath } else { $SummaryPath }
} elseif (-not $refreshArtifactReady) {
    $status = 'refresh-state-needs-rebuild'
    $reason = 'The saved refresh artifact is missing, unreadable, or points at a different summary, so the helper chain should be rebuilt before using the narrower refresh flow.'
    $nextFocus = 'Refresh the helper chain from the current summary and then reopen the saved refresh artifact.'
    $recommendedCommand = $refreshChainCommand
    $recommendedGuideCommand = $bundleGuideCommand
    $nextArtifactToOpen = if ($refreshExists) { $refreshPath } else { $SummaryPath }
} else {
    $status = 'safe-to-run-refresh-status'
    $reason = 'The direct runner contract fields are present, the bundle audit is complete, and the saved refresh artifact matches the current summary.'
    $nextFocus = 'Use the existing refresh status helper, then continue to the handoff helper for the next narrowed replay step.'
    $recommendedCommand = $refreshStatusCommand
    $recommendedGuideCommand = $handoffGuideCommand
    $nextArtifactToOpen = $refreshPath
}

$report = [ordered]@{
    issue = 'Google issue #3 validation refresh safe helper'
    purpose = 'Audit whether the current refresh helper can be trusted before the next Windows replay follows the narrower refresh flow, and route the replay toward contract repair or helper-chain refresh when needed.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_error = $manifestError
    bundle_artifact_path = $bundlePath
    bundle_artifact_exists = [bool]$bundleExists
    bundle_status = $bundleStatus
    bundle_error = $bundleError
    refresh_artifact_path = $refreshPath
    refresh_artifact_exists = [bool]$refreshExists
    refresh_artifact_error = $refreshError
    refresh_status = $refreshStatus
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
    existing_refresh_helper_likely_safe = [bool]$existingRefreshHelperLikelySafe
    runner_contract_missing = [bool]$runnerContractMissing
    missing_runner_fields = @($missingFields)
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    refresh_status_command = $refreshStatusCommand
    refresh_chain_command = $refreshChainCommand
    bundle_guide_command = $bundleGuideCommand
    summary_guide_command = $summaryGuideCommand
    handoff_guide_command = $handoffGuideCommand
    runner_wiring_status_command = $runnerWiringStatusCommand
    runner_patch_targets_command = $runnerPatchTargetsCommand
    runner_contract_repair_command = $runnerContractRepairCommand
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

Write-Host 'Google issue #3 validation refresh safe helper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
if ($report.manifest_artifact_error) {
    Write-Host ("Manifest error: {0}" -f $report.manifest_artifact_error)
}
Write-Host ("Bundle:    {0}" -f $report.bundle_artifact_path)
Write-Host ("Bundle exists: {0}" -f $report.bundle_artifact_exists)
Write-Host ("Bundle status: {0}" -f $report.bundle_status)
if ($report.bundle_error) {
    Write-Host ("Bundle error: {0}" -f $report.bundle_error)
}
Write-Host ("Refresh:   {0}" -f $report.refresh_artifact_path)
Write-Host ("Refresh exists: {0}" -f $report.refresh_artifact_exists)
Write-Host ("Refresh status: {0}" -f $report.refresh_status)
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
Write-Host ("Existing refresh helper likely safe: {0}" -f $report.existing_refresh_helper_likely_safe)
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
