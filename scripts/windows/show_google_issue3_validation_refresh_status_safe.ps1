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
$artifactPathExplicit = -not [string]::IsNullOrWhiteSpace($ArtifactPath)
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json"
}
if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    throw "Issue #3 recommended validation summary not found: $SummaryPath"
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$summaryHasArtifactRootField = Test-HasProperty -Object $summary -Name 'artifact_root'
$artifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
if ([string]::IsNullOrWhiteSpace($artifactRoot)) {
    $artifactRoot = Split-Path -Parent $SummaryPath
}
if (-not $artifactPathExplicit) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-validation-refresh-status-safe.json'
}
$shouldPreserveRepoRoot = $PSBoundParameters.ContainsKey('RepoRoot') -or -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)
$recommendedRepoRoot = if ($shouldPreserveRepoRoot) {
    $repoRoot
} else {
    $null
}
$shouldPreserveSummaryPath = $PSBoundParameters.ContainsKey('SummaryPath') -or $shouldPreserveRepoRoot
$recommendedSummaryPath = if ($shouldPreserveSummaryPath) {
    $SummaryPath
} else {
    $null
}
$recommendedArtifactPath = if ($artifactPathExplicit) {
    $ArtifactPath
} else {
    $null
}

$recommendedRunnerCommand = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    SummaryPath = $recommendedSummaryPath
})
$runnerWiringStatusSafeCommand = Format-HelperCommand -ScriptName 'show_google_issue3_runner_output_wiring_status_safe.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    SummaryPath = $recommendedSummaryPath
})
$runnerContractRepairCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'repair_google_issue3_runner_output_contract.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$refreshStatusCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_refresh_status.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$refreshChainCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'refresh_google_issue3_validation_handoff_chain.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
    ArtifactPath = $recommendedArtifactPath
}) -RepoRootOverride $recommendedRepoRoot
$handoffSafeCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_handoff_safe.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$handoffSafeRefreshRouteCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_handoff_safe_refresh_route.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$manifestSafeCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_manifest_safe.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$artifactBundleCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_artifact_bundle.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$artifactBundleSafeCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_artifact_bundle_safe.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$summaryGuideCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_summary_guide_safe.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot

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

$configuredSummaryRefreshPath = Get-OptionalPropertyValue -Object $summary -Name 'refresh_chain_artifact_path'
$configuredManifestRefreshPath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'refresh_chain_artifact_path'
$configuredSummaryHandoffPath = Get-OptionalPropertyValue -Object $summary -Name 'handoff_artifact_path'
$configuredManifestHandoffPath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'handoff_artifact_path'
$configuredBundlePath = Get-OptionalPropertyValue -Object $summary -Name 'artifact_bundle_path'

$refreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if (-not [string]::IsNullOrWhiteSpace($configuredSummaryRefreshPath)) { $configuredSummaryRefreshPath } elseif (-not [string]::IsNullOrWhiteSpace($configuredManifestRefreshPath)) { $configuredManifestRefreshPath } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if (-not [string]::IsNullOrWhiteSpace($configuredSummaryHandoffPath)) { $configuredSummaryHandoffPath } elseif (-not [string]::IsNullOrWhiteSpace($configuredManifestHandoffPath)) { $configuredManifestHandoffPath } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
$bundlePath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredBundlePath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json'

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
$refreshSafeFieldsMissing = [System.Collections.Generic.List[string]]::new()
if ($refreshRecord) {
    foreach ($fieldName in @('status', 'summary_path', 'reason', 'recommended_command', 'recommended_guide_command', 'next_artifact_to_open', 'failed_step_count', 'failed_step_names')) {
        Add-MissingField -List $refreshSafeFieldsMissing -FieldName ("refresh.{0}" -f $fieldName) -Present (Test-HasProperty -Object $refreshRecord -Name $fieldName)
    }
}
$refreshMatchesSummary = $false
if ($refreshRecord -and (Test-HasProperty -Object $refreshRecord -Name 'summary_path') -and -not [string]::IsNullOrWhiteSpace($refreshRecord.summary_path)) {
    $refreshMatchesSummary = ([System.IO.Path]::GetFullPath($refreshRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}

$bundleExists = Test-Path -LiteralPath $bundlePath -PathType Leaf
$bundleRecord = $null
$bundleError = $null
if ($bundleExists) {
    try {
        $bundleRecord = Read-ArtifactJson $bundlePath
    } catch {
        $bundleError = $_.Exception.Message
    }
}
$bundleSafeFieldsMissing = [System.Collections.Generic.List[string]]::new()
if ($bundleRecord) {
    foreach ($fieldName in @('status', 'next_artifact_to_open', 'stale_cross_reference_detected', 'stale_cross_reference_labels', 'stale_summary_artifact_detected', 'stale_summary_artifact_labels', 'core_missing_count', 'core_missing_labels', 'phase_missing_artifact_count')) {
        Add-MissingField -List $bundleSafeFieldsMissing -FieldName ("bundle.{0}" -f $fieldName) -Present (Test-HasProperty -Object $bundleRecord -Name $fieldName)
    }
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
$handoffSafeFieldsMissing = [System.Collections.Generic.List[string]]::new()
if ($handoffRecord) {
    foreach ($fieldName in @('summary_path', 'next_artifact_to_open')) {
        Add-MissingField -List $handoffSafeFieldsMissing -FieldName ("handoff.{0}" -f $fieldName) -Present (Test-HasProperty -Object $handoffRecord -Name $fieldName)
    }
}
$handoffMatchesSummary = $false
if ($handoffRecord -and (Test-HasProperty -Object $handoffRecord -Name 'summary_path') -and -not [string]::IsNullOrWhiteSpace($handoffRecord.summary_path)) {
    $handoffMatchesSummary = ([System.IO.Path]::GetFullPath($handoffRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}

$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null

if (-not $summaryHasArtifactRootField) {
    $status = 'summary-artifact-root-missing'
    $reason = 'The saved summary omits artifact_root, so the existing refresh-status helper can fail under strict mode before it reaches fallback path resolution.'
    $nextFocus = 'Regenerate the broader issue #3 validation summary before trusting the existing refresh-status helper.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $runnerWiringStatusSafeCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ($runnerContractMissing) {
    $status = 'runner-contract-missing'
    $reason = 'The saved summary or manifest still omits part of the direct refresh or handoff runner-output contract that the existing refresh-status helper is easier to trust once it is normalized.'
    $nextFocus = 'Repair the saved runner-output contract first, then rerun the existing refresh-status helper or this safe checkpoint.'
    $recommendedCommand = $runnerContractRepairCommand
    $recommendedGuideCommand = $runnerWiringStatusSafeCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ((-not $refreshExists) -or $refreshError -or ($refreshRecord -and $refreshSafeFieldsMissing.Count -gt 0) -or ($refreshRecord -and -not $refreshMatchesSummary)) {
    $status = 'refresh-artifact-needs-rebuild'
    $reason = 'The saved refresh artifact is missing, unreadable, incomplete, or belongs to a different summary, so the existing refresh-status helper is not the safest next checkpoint yet.'
    $nextFocus = 'Refresh the saved helper chain from the current summary before relying on the existing refresh-status helper.'
    $recommendedCommand = $refreshChainCommand
    $recommendedGuideCommand = $manifestSafeCommand
    $nextArtifactToOpen = if ($refreshExists) { $refreshPath } else { $SummaryPath }
} elseif ((-not $bundleExists) -or $bundleError -or ($bundleRecord -and $bundleSafeFieldsMissing.Count -gt 0)) {
    $status = 'bundle-artifact-needs-rebuild'
    $reason = 'The saved artifact-bundle record is missing, unreadable, or incomplete for the current summary, so the existing refresh-status helper can still hit strict-mode gaps when it inspects bundle state.'
    $nextFocus = 'Refresh the helper chain or rebuild the bundle artifact through the safe bundle checkpoint before trusting the existing refresh-status helper.'
    $recommendedCommand = $refreshChainCommand
    $recommendedGuideCommand = $artifactBundleSafeCommand
    $nextArtifactToOpen = if ($bundleExists) { $bundlePath } else { $SummaryPath }
} elseif ((-not $handoffExists) -or $handoffError -or ($handoffRecord -and $handoffSafeFieldsMissing.Count -gt 0) -or ($handoffRecord -and -not $handoffMatchesSummary)) {
    $status = 'handoff-artifact-needs-rebuild'
    $reason = 'The saved handoff artifact is missing, unreadable, incomplete, or belongs to a different summary, so the existing refresh-status helper is safer to revisit after the helper chain is refreshed.'
    $nextFocus = 'Refresh the helper chain from the current summary, then reopen the combined handoff-safe refresh route before trusting the existing refresh-status helper.'
    $recommendedCommand = $refreshChainCommand
    $recommendedGuideCommand = $handoffSafeRefreshRouteCommand
    $nextArtifactToOpen = if ($handoffExists) { $handoffPath } else { $SummaryPath }
} else {
    $status = 'safe-to-run-existing-helper'
    $reason = 'The saved summary, refresh, bundle, and handoff artifacts expose the fields the existing refresh-status helper expects under strict mode for the current summary.'
    $nextFocus = 'Run the existing refresh-status helper or move on to the handoff-safe checkpoint for the next narrowed Windows replay.'
    $recommendedCommand = $refreshStatusCommand
    $recommendedGuideCommand = $handoffSafeCommand
    $nextArtifactToOpen = $refreshPath
}

$report = [ordered]@{
    issue = 'Google issue #3 validation refresh status safe helper'
    purpose = 'Check whether the existing refresh-status helper is safe to trust under strict mode for the current issue #3 summary and saved helper-chain artifacts.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repo_root = $repoRoot
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    artifact_root = $artifactRoot
    summary_has_artifact_root_field = [bool]$summaryHasArtifactRootField
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_error = $manifestError
    refresh_artifact_path = $refreshPath
    refresh_artifact_exists = [bool]$refreshExists
    refresh_artifact_error = $refreshError
    refresh_matches_summary = [bool]$refreshMatchesSummary
    refresh_safe_fields_missing = @($refreshSafeFieldsMissing)
    bundle_artifact_path = $bundlePath
    bundle_artifact_exists = [bool]$bundleExists
    bundle_artifact_error = $bundleError
    bundle_safe_fields_missing = @($bundleSafeFieldsMissing)
    handoff_artifact_path = $handoffPath
    handoff_artifact_exists = [bool]$handoffExists
    handoff_artifact_error = $handoffError
    handoff_matches_summary = [bool]$handoffMatchesSummary
    handoff_safe_fields_missing = @($handoffSafeFieldsMissing)
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
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    runner_wiring_status_safe_command = $runnerWiringStatusSafeCommand
    runner_contract_repair_command = $runnerContractRepairCommand
    refresh_status_command = $refreshStatusCommand
    refresh_chain_command = $refreshChainCommand
    manifest_safe_command = $manifestSafeCommand
    handoff_safe_command = $handoffSafeCommand
    handoff_safe_refresh_route_command = $handoffSafeRefreshRouteCommand
    artifact_bundle_command = $artifactBundleCommand
    artifact_bundle_safe_command = $artifactBundleSafeCommand
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

Write-Host 'Google issue #3 validation refresh status safe helper'
Write-Host ''
Write-Host ("Repo root: {0}" -f $report.repo_root)
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Refresh:   {0}" -f $report.refresh_artifact_path)
Write-Host ("Refresh exists: {0}" -f $report.refresh_artifact_exists)
Write-Host ("Refresh matches summary: {0}" -f $report.refresh_matches_summary)
if ($report.refresh_artifact_error) {
    Write-Host ("Refresh error: {0}" -f $report.refresh_artifact_error)
}
Write-Host ("Bundle:    {0}" -f $report.bundle_artifact_path)
Write-Host ("Bundle exists: {0}" -f $report.bundle_artifact_exists)
if ($report.bundle_artifact_error) {
    Write-Host ("Bundle error: {0}" -f $report.bundle_artifact_error)
}
Write-Host ("Handoff:   {0}" -f $report.handoff_artifact_path)
Write-Host ("Handoff exists: {0}" -f $report.handoff_artifact_exists)
Write-Host ("Handoff matches summary: {0}" -f $report.handoff_matches_summary)
if ($report.handoff_artifact_error) {
    Write-Host ("Handoff error: {0}" -f $report.handoff_artifact_error)
}
Write-Host ("Runner contract missing: {0}" -f $report.runner_contract_missing)
if ($report.runner_contract_missing_fields.Count -gt 0) {
    Write-Host 'Missing runner-contract fields:'
    foreach ($fieldName in $report.runner_contract_missing_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
if ($report.refresh_safe_fields_missing.Count -gt 0) {
    Write-Host 'Missing refresh fields:'
    foreach ($fieldName in $report.refresh_safe_fields_missing) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
if ($report.bundle_safe_fields_missing.Count -gt 0) {
    Write-Host 'Missing bundle fields:'
    foreach ($fieldName in $report.bundle_safe_fields_missing) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
if ($report.handoff_safe_fields_missing.Count -gt 0) {
    Write-Host 'Missing handoff fields:'
    foreach ($fieldName in $report.handoff_safe_fields_missing) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
