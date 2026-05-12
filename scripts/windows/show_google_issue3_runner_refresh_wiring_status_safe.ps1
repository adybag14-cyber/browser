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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-runner-refresh-wiring-safe.json'
}

$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$runnerRefreshWiringStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_refresh_wiring_status.ps1'
$runnerOutputWiringStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$runnerPatchTargetsCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'

$summaryHasManifestPathField = Test-HasProperty -Object $summary -Name 'manifest_artifact_path'
$summaryHasRefreshPathField = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_path'
$summaryHasHandoffPathField = Test-HasProperty -Object $summary -Name 'handoff_artifact_path'

$configuredManifestPath = Get-OptionalPropertyValue -Object $summary -Name 'manifest_artifact_path'
$configuredSummaryRefreshPath = Get-OptionalPropertyValue -Object $summary -Name 'refresh_chain_artifact_path'
$configuredSummaryHandoffPath = Get-OptionalPropertyValue -Object $summary -Name 'handoff_artifact_path'

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

$manifestHasRefreshPathField = Test-HasProperty -Object $manifestRecord -Name 'refresh_chain_artifact_path'
$manifestHasHandoffPathField = Test-HasProperty -Object $manifestRecord -Name 'handoff_artifact_path'
$configuredManifestRefreshPath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'refresh_chain_artifact_path'
$configuredManifestHandoffPath = Get-OptionalPropertyValue -Object $manifestRecord -Name 'handoff_artifact_path'

$summaryRecordsRefreshArtifactPath = -not [string]::IsNullOrWhiteSpace($configuredSummaryRefreshPath)
$summaryRecordsHandoffArtifactPath = -not [string]::IsNullOrWhiteSpace($configuredSummaryHandoffPath)
$manifestRefreshPointerRequired = -not $summaryRecordsRefreshArtifactPath
$manifestHandoffPointerRequired = -not $summaryRecordsHandoffArtifactPath
$manifestRefreshPointerSafe = (-not $manifestRefreshPointerRequired) -or $manifestHasRefreshPathField
$manifestHandoffPointerSafe = (-not $manifestHandoffPointerRequired) -or $manifestHasHandoffPathField

$missingFields = [System.Collections.Generic.List[string]]::new()
Add-MissingField -List $missingFields -FieldName 'summary.manifest_artifact_path' -Present $summaryHasManifestPathField
Add-MissingField -List $missingFields -FieldName 'summary.refresh_chain_artifact_path' -Present $summaryHasRefreshPathField
Add-MissingField -List $missingFields -FieldName 'summary.handoff_artifact_path' -Present $summaryHasHandoffPathField
if ($manifestRefreshPointerRequired -and $manifestRecord) {
    Add-MissingField -List $missingFields -FieldName 'manifest.refresh_chain_artifact_path' -Present $manifestHasRefreshPathField
}
if ($manifestHandoffPointerRequired -and $manifestRecord) {
    Add-MissingField -List $missingFields -FieldName 'manifest.handoff_artifact_path' -Present $manifestHasHandoffPathField
}

$refreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($summaryRecordsRefreshArtifactPath) { $configuredSummaryRefreshPath } elseif (-not [string]::IsNullOrWhiteSpace($configuredManifestRefreshPath)) { $configuredManifestRefreshPath } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($summaryRecordsHandoffArtifactPath) { $configuredSummaryHandoffPath } elseif (-not [string]::IsNullOrWhiteSpace($configuredManifestHandoffPath)) { $configuredManifestHandoffPath } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'

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
if ($handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffRecord.summary_path)) {
    $handoffMatchesSummary = ([System.IO.Path]::GetFullPath($handoffRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}

$runnerContractMissing = [bool]($missingFields.Count -gt 0)
$existingRunnerRefreshHelperLikelySafe = [bool](
    $summaryHasManifestPathField -and
    $summaryHasRefreshPathField -and
    $summaryHasHandoffPathField -and
    (-not $manifestError) -and
    $manifestRefreshPointerSafe -and
    $manifestHandoffPointerSafe
)

$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null

if (-not $summaryHasManifestPathField) {
    $status = 'summary-manifest-path-field-missing'
    $reason = 'The saved summary still omits manifest_artifact_path, so the existing runner refresh wiring helper can fail immediately under strict mode before it reaches any refresh guidance.'
    $nextFocus = 'Regenerate the broader runner outputs first, then reopen the runner-output wiring audit before trusting the narrower refresh wiring helper again.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $runnerOutputWiringStatusCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ($manifestError) {
    $status = 'manifest-unreadable'
    $reason = 'The saved manifest could not be read cleanly, so the existing runner refresh wiring helper cannot rely on manifest-backed pointer recovery for this summary.'
    $nextFocus = 'Regenerate the saved runner outputs, then reopen the runner-output wiring audit before trusting the narrower refresh wiring helper.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $runnerOutputWiringStatusCommand
    $nextArtifactToOpen = if ($manifestExists) { $manifestPath } else { $SummaryPath }
} elseif ($runnerContractMissing) {
    $status = 'runner-pointer-fields-missing'
    $reason = 'The summary or manifest still omits at least one refresh or handoff pointer field that the existing runner refresh wiring helper reads directly under strict mode.'
    $nextFocus = 'Patch the recommended runner output contract first, then rerun the wiring audit before trusting the narrower refresh wiring helper.'
    $recommendedCommand = $runnerPatchTargetsCommand
    $recommendedGuideCommand = $runnerOutputWiringStatusCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ((-not $refreshExists) -or $refreshError -or (-not $refreshMatchesSummary)) {
    $status = 'refresh-state-needs-rebuild'
    $reason = 'The saved refresh artifact is missing, unreadable, or belongs to a different summary, so the helper chain should be refreshed before relying on the existing runner refresh wiring helper.'
    $nextFocus = 'Refresh the issue #3 helper chain from the current summary before trusting the runner refresh wiring helper output.'
    $recommendedCommand = $refreshChainCommand
    $recommendedGuideCommand = $refreshStatusCommand
    $nextArtifactToOpen = if ($refreshExists) { $refreshPath } else { $SummaryPath }
} else {
    $status = 'safe-to-run-existing-helper'
    $reason = 'The current summary and manifest expose the pointer fields the existing runner refresh wiring helper expects, and the saved refresh artifact matches the current summary.'
    $nextFocus = 'Use the existing runner refresh wiring helper or refresh-status helper for the next narrowed Windows replay step.'
    $recommendedCommand = $runnerRefreshWiringStatusCommand
    $recommendedGuideCommand = $refreshStatusCommand
    $nextArtifactToOpen = if ($refreshExists) { $refreshPath } elseif ($manifestExists) { $manifestPath } else { $SummaryPath }
}

$report = [ordered]@{
    issue = 'Google issue #3 runner refresh wiring safe helper'
    purpose = 'Audit whether the existing runner refresh wiring helper can be trusted under strict mode for the current summary before the next Windows replay follows its guidance.'
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
    summary_has_manifest_artifact_path_field = [bool]$summaryHasManifestPathField
    summary_has_refresh_artifact_path_field = [bool]$summaryHasRefreshPathField
    summary_has_handoff_artifact_path_field = [bool]$summaryHasHandoffPathField
    summary_records_refresh_artifact_path = [bool]$summaryRecordsRefreshArtifactPath
    summary_records_handoff_artifact_path = [bool]$summaryRecordsHandoffArtifactPath
    manifest_has_refresh_artifact_path_field = [bool]$manifestHasRefreshPathField
    manifest_has_handoff_artifact_path_field = [bool]$manifestHasHandoffPathField
    manifest_refresh_pointer_required = [bool]$manifestRefreshPointerRequired
    manifest_handoff_pointer_required = [bool]$manifestHandoffPointerRequired
    manifest_refresh_pointer_safe = [bool]$manifestRefreshPointerSafe
    manifest_handoff_pointer_safe = [bool]$manifestHandoffPointerSafe
    existing_runner_refresh_helper_likely_safe = [bool]$existingRunnerRefreshHelperLikelySafe
    runner_contract_missing = [bool]$runnerContractMissing
    missing_runner_fields = @($missingFields)
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    runner_refresh_wiring_status_command = $runnerRefreshWiringStatusCommand
    runner_output_wiring_status_command = $runnerOutputWiringStatusCommand
    runner_patch_targets_command = $runnerPatchTargetsCommand
    refresh_status_command = $refreshStatusCommand
    refresh_chain_command = $refreshChainCommand
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

Write-Host 'Google issue #3 runner refresh wiring safe helper'
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
Write-Host ("Existing helper likely safe: {0}" -f $report.existing_runner_refresh_helper_likely_safe)
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
