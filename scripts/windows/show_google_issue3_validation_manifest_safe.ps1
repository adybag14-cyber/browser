[CmdletBinding()]
param(
    [string]$RepoRoot,
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

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [hashtable]$Arguments = @{}
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\$ScriptName"
    foreach ($entry in $Arguments.GetEnumerator()) {
        $value = $entry.Value
        if ($null -eq $value) {
            continue
        }

        if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        $escapedValue = ("$value") -replace "'", "''"
        $command += (" -{0} '{1}'" -f $entry.Key, $escapedValue)
    }

    return $command
}

function Format-HelperCommandWithRepoRootEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [hashtable]$Arguments = @{},
        [string]$RepoRootOverride
    )

    if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        return Format-HelperCommand -ScriptName $ScriptName -Arguments $Arguments
    }

    $command = "& '.\\scripts\\windows\\$ScriptName'"
    foreach ($entry in $Arguments.GetEnumerator()) {
        $value = $entry.Value
        if ($null -eq $value) {
            continue
        }

        if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        $escapedValue = ("$value") -replace "'", "''"
        $command += (" -{0} '{1}'" -f $entry.Key, $escapedValue)
    }

    $escapedRepoRoot = ("$RepoRootOverride") -replace "'", "''"
    return "powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$env:LIGHTPANDA_REPO_ROOT = '$escapedRepoRoot'; $command`""
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

$repoRoot = if ($RepoRoot) {
    $RepoRoot
} else {
    Resolve-RepoRoot $PSScriptRoot
}
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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-validation-manifest-safe.json'
}
$recommendedRepoRoot = if ($PSBoundParameters.ContainsKey('RepoRoot')) {
    $repoRoot
} else {
    $null
}
$recommendedSummaryPath = if ($PSBoundParameters.ContainsKey('SummaryPath')) {
    $SummaryPath
} else {
    $null
}

$recommendedRunnerCommand = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    SummaryPath = $recommendedSummaryPath
})
$manifestSafeCommand = Format-HelperCommand -ScriptName 'show_google_issue3_validation_manifest_safe.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    SummaryPath = $recommendedSummaryPath
})
$manifestGuideCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_manifest.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$handoffSafeCommand = Format-HelperCommand -ScriptName 'show_google_issue3_validation_handoff_safe.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    SummaryPath = $recommendedSummaryPath
})
$handoffSafeRefreshRouteCommand = Format-HelperCommand -ScriptName 'show_google_issue3_validation_handoff_safe_refresh_route.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    SummaryPath = $recommendedSummaryPath
})
$handoffGuideCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_handoff.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$refreshStatusCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_refresh_status.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$refreshStatusSafeCommand = Format-HelperCommand -ScriptName 'show_google_issue3_validation_refresh_status_safe.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    SummaryPath = $recommendedSummaryPath
})
$refreshChainCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'refresh_google_issue3_validation_handoff_chain.ps1' -Arguments ([ordered]@{}) -RepoRootOverride $recommendedRepoRoot
$runnerWiringStatusCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_output_wiring_status.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$runnerWiringStatusSafeCommand = Format-HelperCommand -ScriptName 'show_google_issue3_runner_output_wiring_status_safe.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    SummaryPath = $recommendedSummaryPath
})
$runnerPatchTargetsCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_output_patch_targets.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$artifactBundleCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_artifact_bundle.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$summaryGuideCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_summary_guide_safe.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$manifestContractRepairCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'repair_google_issue3_validation_manifest_contract.ps1' -Arguments ([ordered]@{}) -RepoRootOverride $recommendedRepoRoot
$runnerContractRepairCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'repair_google_issue3_runner_output_contract.ps1' -Arguments ([ordered]@{}) -RepoRootOverride $recommendedRepoRoot

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

$summaryRefreshPathPresent = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_path'
$summaryRefreshErrorPresent = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_error'

$manifestFieldNames = @(
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
$manifestMissingFields = [System.Collections.Generic.List[string]]::new()
foreach ($fieldName in $manifestFieldNames) {
    Add-MissingField -List $manifestMissingFields -FieldName ("manifest.{0}" -f $fieldName) -Present (Test-HasProperty -Object $manifestRecord -Name $fieldName)
}

$summaryMissingFields = [System.Collections.Generic.List[string]]::new()
Add-MissingField -List $summaryMissingFields -FieldName 'summary.refresh_chain_artifact_path' -Present $summaryRefreshPathPresent
Add-MissingField -List $summaryMissingFields -FieldName 'summary.refresh_chain_artifact_error' -Present $summaryRefreshErrorPresent

$configuredSummaryRefreshPath = Get-OptionalPropertyValue -Object $summary -Name 'refresh_chain_artifact_path'
$configuredManifestRefreshPath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'refresh_chain_artifact_path'
$configuredSummaryHandoffPath = Get-OptionalPropertyValue -Object $summary -Name 'handoff_artifact_path'
$configuredManifestHandoffPath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'handoff_artifact_path'
$configuredArtifactBundlePath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'artifact_bundle_path'
$configuredGuidePath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'guide_artifact_path'
$configuredBoundaryPath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'boundary_artifact_path'
$configuredManifestSummaryPath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'summary_path'

$resolvedRefreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if (-not [string]::IsNullOrWhiteSpace($configuredSummaryRefreshPath)) { $configuredSummaryRefreshPath } elseif (-not [string]::IsNullOrWhiteSpace($configuredManifestRefreshPath)) { $configuredManifestRefreshPath } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$resolvedHandoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if (-not [string]::IsNullOrWhiteSpace($configuredSummaryHandoffPath)) { $configuredSummaryHandoffPath } elseif (-not [string]::IsNullOrWhiteSpace($configuredManifestHandoffPath)) { $configuredManifestHandoffPath } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
$resolvedBundlePath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredArtifactBundlePath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json'
$resolvedGuidePath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredGuidePath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-guide.json'
$resolvedBoundaryPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredBoundaryPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-phase-boundary.json'
$resolvedManifestSummaryPath = if (-not [string]::IsNullOrWhiteSpace($configuredManifestSummaryPath)) { $configuredManifestSummaryPath } else { $SummaryPath }

$refreshExists = Test-Path -LiteralPath $resolvedRefreshPath -PathType Leaf
$refreshRecord = $null
$refreshError = $null
if ($refreshExists) {
    try {
        $refreshRecord = Read-ArtifactJson $resolvedRefreshPath
    } catch {
        $refreshError = $_.Exception.Message
    }
}
$refreshMatchesSummary = $false
$refreshSummaryPath = Get-OptionalPropertyValue -Object $refreshRecord -Name 'summary_path'
if (-not [string]::IsNullOrWhiteSpace($refreshSummaryPath)) {
    $refreshMatchesSummary = ([System.IO.Path]::GetFullPath($refreshSummaryPath)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}

$bundleExists = Test-Path -LiteralPath $resolvedBundlePath -PathType Leaf
$guideExists = Test-Path -LiteralPath $resolvedGuidePath -PathType Leaf
$boundaryExists = Test-Path -LiteralPath $resolvedBoundaryPath -PathType Leaf
$handoffExists = Test-Path -LiteralPath $resolvedHandoffPath -PathType Leaf

$runnerContractMissing = [bool]($summaryMissingFields.Count -gt 0 -or ($manifestMissingFields | Where-Object { $_ -like 'manifest.refresh_*' -or $_ -like 'manifest.handoff_*' }).Count -gt 0)
$manifestGuideContractMissing = [bool]($summaryMissingFields.Count -gt 0 -or $manifestMissingFields.Count -gt 0)
$existingManifestGuideLikelySafe = [bool]((-not $manifestError) -and (-not $manifestGuideContractMissing))

$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null

if (-not $manifestExists) {
    $status = 'manifest-missing'
    $reason = 'The saved manifest is missing for the current summary, so the existing manifest guide cannot be trusted yet.'
    $nextFocus = 'Regenerate the saved issue #3 outputs with the broader runner, then reopen the summary or runner wiring audit before trusting the manifest guide.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $summaryGuideCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ($manifestError) {
    $status = 'manifest-unreadable'
    $reason = 'The saved manifest could not be read cleanly, so the existing manifest guide should not be trusted under strict mode for this summary.'
    $nextFocus = 'Regenerate the saved issue #3 outputs with the broader runner, then reopen the safe runner wiring audit before trusting the manifest guide again.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $runnerWiringStatusSafeCommand
    $nextArtifactToOpen = if ($manifestExists) { $manifestPath } else { $SummaryPath }
} elseif ($runnerContractMissing) {
    $status = 'runner-contract-missing'
    $reason = 'The summary or manifest still omits at least one direct refresh or handoff field that the existing manifest guide reads under strict mode, but the branch now includes a bounded repair helper for normalizing those saved outputs immediately after a run.'
    $nextFocus = 'Run the runner-output contract repair helper first, then rerun the safe runner wiring audit before returning to the manifest guide.'
    $recommendedCommand = $runnerContractRepairCommand
    $recommendedGuideCommand = $runnerWiringStatusSafeCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ($manifestGuideContractMissing) {
    $status = 'manifest-guide-contract-missing'
    $reason = 'The broader runner contract is mostly present, but the existing manifest guide still depends on additional manifest-facing fields that are missing under strict mode.'
    $nextFocus = 'Run the manifest-contract repair helper first, then rerun the safe manifest audit before trusting the existing manifest guide.'
    $recommendedCommand = $manifestContractRepairCommand
    $recommendedGuideCommand = $manifestSafeCommand
    $nextArtifactToOpen = $manifestPath
} elseif ((-not $refreshExists) -or (-not $refreshMatchesSummary) -or $refreshError) {
    $status = 'refresh-state-needs-rebuild'
    $reason = 'The saved refresh artifact is missing, unreadable, or belongs to a different summary, so the helper chain should be refreshed before relying on the manifest guide.'
    $nextFocus = 'Refresh the saved helper chain from the current summary, then reopen the newer handoff-safe refresh route before using the narrower manifest or handoff guidance.'
    $recommendedCommand = $handoffSafeRefreshRouteCommand
    $recommendedGuideCommand = $handoffSafeRefreshRouteCommand
    $nextArtifactToOpen = if ($refreshExists) { $resolvedRefreshPath } else { $SummaryPath }
} else {
    $status = 'safe-to-run-manifest-guide'
    $reason = 'The manifest carries the fields the existing manifest guide expects, and the saved refresh artifact matches the current summary.'
    $nextFocus = 'Use the existing manifest guide or move on to the newer handoff-safe refresh route for the next narrowed Windows replay.'
    $recommendedCommand = $manifestGuideCommand
    $recommendedGuideCommand = $handoffSafeRefreshRouteCommand
    $nextArtifactToOpen = $manifestPath
}

$report = [ordered]@{
    issue = 'Google issue #3 validation manifest safe helper'
    purpose = 'Audit whether the existing issue #3 manifest guide can run safely under strict mode for the current summary, and route the next replay to the safest helper when it cannot.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repo_root = $repoRoot
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_error = $manifestError
    manifest_summary_path = $resolvedManifestSummaryPath
    refresh_artifact_path = $resolvedRefreshPath
    refresh_artifact_exists = [bool]$refreshExists
    refresh_artifact_error = $refreshError
    refresh_matches_summary = [bool]$refreshMatchesSummary
    handoff_artifact_path = $resolvedHandoffPath
    handoff_artifact_exists = [bool]$handoffExists
    artifact_bundle_path = $resolvedBundlePath
    artifact_bundle_exists = [bool]$bundleExists
    guide_artifact_path = $resolvedGuidePath
    guide_artifact_exists = [bool]$guideExists
    boundary_artifact_path = $resolvedBoundaryPath
    boundary_artifact_exists = [bool]$boundaryExists
    summary_has_refresh_artifact_path_field = [bool]$summaryRefreshPathPresent
    summary_has_refresh_artifact_error_field = [bool]$summaryRefreshErrorPresent
    manifest_missing_fields = @($manifestMissingFields)
    summary_missing_fields = @($summaryMissingFields)
    runner_contract_missing = [bool]$runnerContractMissing
    manifest_guide_contract_missing = [bool]$manifestGuideContractMissing
    existing_manifest_guide_likely_safe = [bool]$existingManifestGuideLikelySafe
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    runner_contract_repair_command = $runnerContractRepairCommand
    manifest_contract_repair_command = $manifestContractRepairCommand
    manifest_safe_command = $manifestSafeCommand
    manifest_guide_command = $manifestGuideCommand
    handoff_safe_command = $handoffSafeCommand
    handoff_safe_refresh_route_command = $handoffSafeRefreshRouteCommand
    handoff_guide_command = $handoffGuideCommand
    refresh_status_command = $refreshStatusCommand
    refresh_status_safe_command = $refreshStatusSafeCommand
    refresh_chain_command = $refreshChainCommand
    runner_wiring_status_command = $runnerWiringStatusCommand
    runner_wiring_status_safe_command = $runnerWiringStatusSafeCommand
    runner_patch_targets_command = $runnerPatchTargetsCommand
    artifact_bundle_command = $artifactBundleCommand
    summary_guide_command = $summaryGuideCommand
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

Write-Host 'Google issue #3 validation manifest safe helper'
Write-Host ''
Write-Host ("Repo root: {0}" -f $report.repo_root)
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
if ($report.manifest_artifact_error) {
    Write-Host ("Manifest error: {0}" -f $report.manifest_artifact_error)
}
Write-Host ("Manifest summary: {0}" -f $report.manifest_summary_path)
Write-Host ("Refresh:   {0}" -f $report.refresh_artifact_path)
Write-Host ("Refresh exists: {0}" -f $report.refresh_artifact_exists)
Write-Host ("Refresh matches summary: {0}" -f $report.refresh_matches_summary)
if ($report.refresh_artifact_error) {
    Write-Host ("Refresh error: {0}" -f $report.refresh_artifact_error)
}
Write-Host ("Handoff:   {0}" -f $report.handoff_artifact_path)
Write-Host ("Handoff exists: {0}" -f $report.handoff_artifact_exists)
Write-Host ("Bundle:    {0}" -f $report.artifact_bundle_path)
Write-Host ("Bundle exists: {0}" -f $report.artifact_bundle_exists)
Write-Host ("Guide:     {0}" -f $report.guide_artifact_path)
Write-Host ("Guide exists: {0}" -f $report.guide_artifact_exists)
Write-Host ("Boundary:  {0}" -f $report.boundary_artifact_path)
Write-Host ("Boundary exists: {0}" -f $report.boundary_artifact_exists)
Write-Host ("Existing manifest guide likely safe: {0}" -f $report.existing_manifest_guide_likely_safe)
Write-Host ("Runner contract missing: {0}" -f $report.runner_contract_missing)
Write-Host ("Manifest guide contract missing: {0}" -f $report.manifest_guide_contract_missing)
if ($report.summary_missing_fields.Count -gt 0) {
    Write-Host 'Summary fields missing:'
    foreach ($fieldName in $report.summary_missing_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
if ($report.manifest_missing_fields.Count -gt 0) {
    Write-Host 'Manifest fields missing:'
    foreach ($fieldName in $report.manifest_missing_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
