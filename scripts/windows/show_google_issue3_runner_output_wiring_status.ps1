[CmdletBinding()]
param(
    [string]$SummaryPath,
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
$runnerScriptPath = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation.ps1'
$runnerScriptExists = Test-Path -LiteralPath $runnerScriptPath -PathType Leaf
$runnerScriptSource = if ($runnerScriptExists) {
    Get-Content -LiteralPath $runnerScriptPath -Raw
} else {
    $null
}
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json"
}
if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    throw "Issue #3 recommended validation summary not found: $SummaryPath"
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$configuredArtifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
$artifactRoot = if (-not [string]::IsNullOrWhiteSpace($configuredArtifactRoot)) {
    $configuredArtifactRoot
} else {
    Split-Path -Parent $SummaryPath
}

$configuredManifestPath = Get-OptionalPropertyValue -Object $summary -Name 'manifest_artifact_path'
$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredManifestPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
$manifestRecord = Read-ArtifactJson $manifestPath
$manifestReadable = [bool]$manifestRecord

$summaryHasRefreshPathField = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_path'
$summaryHasRefreshErrorField = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_error'
$summaryHasHandoffPathField = Test-HasProperty -Object $summary -Name 'handoff_artifact_path'
$summaryHasHandoffErrorField = Test-HasProperty -Object $summary -Name 'handoff_artifact_error'
$summaryHasAllRunnerFields = [bool]($summaryHasRefreshPathField -and $summaryHasRefreshErrorField -and $summaryHasHandoffPathField -and $summaryHasHandoffErrorField)

$manifestHasRefreshPathField = Test-HasProperty -Object $manifestRecord -Name 'refresh_chain_artifact_path'
$manifestHasRefreshErrorField = Test-HasProperty -Object $manifestRecord -Name 'refresh_chain_artifact_error'
$manifestHasHandoffPathField = Test-HasProperty -Object $manifestRecord -Name 'handoff_artifact_path'
$manifestHasHandoffErrorField = Test-HasProperty -Object $manifestRecord -Name 'handoff_artifact_error'
$manifestHasAllRunnerFields = [bool]($manifestHasRefreshPathField -and $manifestHasRefreshErrorField -and $manifestHasHandoffPathField -and $manifestHasHandoffErrorField)

$summaryMissingRefreshFields = [bool]((-not $summaryHasRefreshPathField) -or (-not $summaryHasRefreshErrorField))
$summaryMissingHandoffFields = [bool]((-not $summaryHasHandoffPathField) -or (-not $summaryHasHandoffErrorField))
$manifestMissingRefreshFields = [bool]((-not $manifestHasRefreshPathField) -or (-not $manifestHasRefreshErrorField))
$manifestMissingHandoffFields = [bool]((-not $manifestHasHandoffPathField) -or (-not $manifestHasHandoffErrorField))
$refreshContractIncomplete = [bool]($summaryMissingRefreshFields -or $manifestMissingRefreshFields)
$handoffContractIncomplete = [bool]($summaryMissingHandoffFields -or $manifestMissingHandoffFields)
$onlyRefreshContractIncomplete = [bool]($refreshContractIncomplete -and (-not $handoffContractIncomplete))
$onlyHandoffContractIncomplete = [bool]($handoffContractIncomplete -and (-not $refreshContractIncomplete))

$configuredSummaryRefreshPath = if ($summaryHasRefreshPathField) { $summary.refresh_chain_artifact_path } else { $null }
$configuredSummaryHandoffPath = if ($summaryHasHandoffPathField) { $summary.handoff_artifact_path } else { $null }
$configuredManifestRefreshPath = if ($manifestHasRefreshPathField) { $manifestRecord.refresh_chain_artifact_path } else { $null }
$configuredManifestHandoffPath = if ($manifestHasHandoffPathField) { $manifestRecord.handoff_artifact_path } else { $null }

$summaryRecordsRefreshPath = [bool](-not [string]::IsNullOrWhiteSpace($configuredSummaryRefreshPath))
$summaryRecordsHandoffPath = [bool](-not [string]::IsNullOrWhiteSpace($configuredSummaryHandoffPath))
$manifestRecordsRefreshPath = [bool](-not [string]::IsNullOrWhiteSpace($configuredManifestRefreshPath))
$manifestRecordsHandoffPath = [bool](-not [string]::IsNullOrWhiteSpace($configuredManifestHandoffPath))

$refreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($summaryRecordsRefreshPath) { $configuredSummaryRefreshPath } elseif ($manifestRecordsRefreshPath) { $configuredManifestRefreshPath } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($summaryRecordsHandoffPath) { $configuredSummaryHandoffPath } elseif ($manifestRecordsHandoffPath) { $configuredManifestHandoffPath } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
$resolvedRefreshPathSource = if ($summaryRecordsRefreshPath) { 'summary' } elseif ($manifestRecordsRefreshPath) { 'manifest' } else { 'fallback' }
$resolvedHandoffPathSource = if ($summaryRecordsHandoffPath) { 'summary' } elseif ($manifestRecordsHandoffPath) { 'manifest' } else { 'fallback' }

$summaryRefreshErrorPopulated = [bool]($summaryHasRefreshErrorField -and -not [string]::IsNullOrWhiteSpace($summary.refresh_chain_artifact_error))
$summaryHandoffErrorPopulated = [bool]($summaryHasHandoffErrorField -and -not [string]::IsNullOrWhiteSpace($summary.handoff_artifact_error))
$manifestRefreshErrorPopulated = [bool]($manifestHasRefreshErrorField -and -not [string]::IsNullOrWhiteSpace($manifestRecord.refresh_chain_artifact_error))
$manifestHandoffErrorPopulated = [bool]($manifestHasHandoffErrorField -and -not [string]::IsNullOrWhiteSpace($manifestRecord.handoff_artifact_error))

$missingFields = [System.Collections.Generic.List[string]]::new()
Add-MissingField -List $missingFields -FieldName 'summary.refresh_chain_artifact_path' -Present $summaryHasRefreshPathField
Add-MissingField -List $missingFields -FieldName 'summary.refresh_chain_artifact_error' -Present $summaryHasRefreshErrorField
Add-MissingField -List $missingFields -FieldName 'summary.handoff_artifact_path' -Present $summaryHasHandoffPathField
Add-MissingField -List $missingFields -FieldName 'summary.handoff_artifact_error' -Present $summaryHasHandoffErrorField
Add-MissingField -List $missingFields -FieldName 'manifest.refresh_chain_artifact_path' -Present $manifestHasRefreshPathField
Add-MissingField -List $missingFields -FieldName 'manifest.refresh_chain_artifact_error' -Present $manifestHasRefreshErrorField
Add-MissingField -List $missingFields -FieldName 'manifest.handoff_artifact_path' -Present $manifestHasHandoffPathField
Add-MissingField -List $missingFields -FieldName 'manifest.handoff_artifact_error' -Present $manifestHasHandoffErrorField

$runnerRefreshWiringCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_refresh_wiring_status.ps1'
$pointerSourcesCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_pointer_sources.ps1'
$patchTargetsCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$repairRunnerOutputContractCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1'

$runnerOutputsFullyWired = [bool]($summaryHasAllRunnerFields -and $manifestHasAllRunnerFields)
$manifestBackfillsSummary = [bool]((-not $summaryHasAllRunnerFields) -and $manifestHasAllRunnerFields)
$summaryOutrunsManifest = [bool]($summaryHasAllRunnerFields -and (-not $manifestHasAllRunnerFields))
$runnerRefreshPathAssignmentCount = Get-DirectFieldAssignmentCount -SourceText $runnerScriptSource -AssignmentText 'refresh_chain_artifact_path = $RefreshChainArtifactPath'
$runnerRefreshErrorAssignmentCount = Get-DirectFieldAssignmentCount -SourceText $runnerScriptSource -AssignmentText 'refresh_chain_artifact_error = $RefreshChainArtifactError'
$runnerHandoffPathAssignmentCount = Get-DirectFieldAssignmentCount -SourceText $runnerScriptSource -AssignmentText 'handoff_artifact_path = $HandoffArtifactPath'
$runnerHandoffErrorAssignmentCount = Get-DirectFieldAssignmentCount -SourceText $runnerScriptSource -AssignmentText 'handoff_artifact_error = $HandoffArtifactError'
$runnerSourceIndicatesDirectFieldWiring = [bool](
    $runnerRefreshPathAssignmentCount -ge 2 -and
    $runnerRefreshErrorAssignmentCount -ge 2 -and
    $runnerHandoffPathAssignmentCount -ge 2 -and
    $runnerHandoffErrorAssignmentCount -ge 2
)
$runnerPatchStillRequired = [bool](($refreshContractIncomplete -or $handoffContractIncomplete) -and (-not $runnerSourceIndicatesDirectFieldWiring))

$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null

if (-not $manifestExists) {
    $status = 'manifest-missing'
    $reason = 'The recommended runner summary exists, but the saved manifest is missing, so the runner output contract cannot be fully wired yet.'
    $nextFocus = 'Regenerate the recommended runner outputs first, then reopen the runner wiring helpers once both summary and manifest exist for the same replay.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $runnerRefreshWiringCommand
    $nextArtifactToOpen = $SummaryPath
} elseif (-not $manifestReadable) {
    $status = 'manifest-unreadable'
    $reason = 'The saved manifest exists but could not be parsed cleanly, so later helpers may still be compensating for unreadable runner output.'
    $nextFocus = 'Repair or regenerate the saved manifest before trusting narrower handoff or refresh guidance.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $runnerRefreshWiringCommand
    $nextArtifactToOpen = $manifestPath
} elseif ($runnerOutputsFullyWired) {
    $status = 'fully-wired'
    $reason = 'The recommended runner now exposes refresh and handoff path plus error fields directly in both the saved summary and manifest outputs.'
    $nextFocus = 'Use the narrower refresh or handoff helpers now that the runner outputs already advertise the top-level pointer contract directly.'
    $recommendedCommand = $refreshStatusCommand
    $recommendedGuideCommand = $handoffGuideCommand
    $nextArtifactToOpen = if ($summaryRecordsHandoffPath) { $configuredSummaryHandoffPath } elseif ($manifestRecordsHandoffPath) { $configuredManifestHandoffPath } else { $handoffPath }
} elseif ($runnerSourceIndicatesDirectFieldWiring) {
    $status = 'saved-artifacts-stale-runner-already-wired'
    $reason = 'The saved summary or manifest still omits direct refresh or handoff fields, but the live runner source already writes those fields into both output objects.'
    $nextFocus = 'Regenerate the recommended validation outputs on Windows, or run the saved-output repair helper on the current artifacts before trusting patch-target guidance again.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $repairRunnerOutputContractCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ($onlyRefreshContractIncomplete) {
    $status = 'refresh-fields-missing-only'
    $reason = 'The remaining runner-output gap is limited to refresh path or refresh error fields; the handoff contract is already present in both saved outputs.'
    $nextFocus = 'Use the runner output patch-target helper to wire the direct refresh path and refresh error fields into the recommended runner outputs, then rerun the wiring audit.'
    $recommendedCommand = $runnerRefreshWiringCommand
    $recommendedGuideCommand = $patchTargetsCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ($onlyHandoffContractIncomplete) {
    $status = 'handoff-fields-missing-only'
    $reason = 'The remaining runner-output gap is limited to handoff path or handoff error fields; the refresh contract is already present in both saved outputs.'
    $nextFocus = 'Use the runner output patch-target helper to wire the direct handoff path and handoff error fields into the recommended runner outputs, then rerun the wiring audit.'
    $recommendedCommand = $runnerRefreshWiringCommand
    $recommendedGuideCommand = $patchTargetsCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ($manifestBackfillsSummary) {
    $status = 'summary-still-needs-direct-fields'
    $reason = 'The manifest already carries the full refresh and handoff runner-output contract, but the summary still omits at least one of those top-level fields.'
    $nextFocus = 'Use the runner output patch-target helper to add the missing direct fields to the summary so later helpers stop relying on manifest-only recovery.'
    $recommendedCommand = $runnerRefreshWiringCommand
    $recommendedGuideCommand = $patchTargetsCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ($summaryOutrunsManifest) {
    $status = 'manifest-still-needs-direct-fields'
    $reason = 'The summary already exposes the refresh and handoff runner-output contract, but the manifest still omits at least one of those top-level fields.'
    $nextFocus = 'Use the runner output patch-target helper to add the missing direct fields to the manifest so it matches the summary contract.'
    $recommendedCommand = $runnerRefreshWiringCommand
    $recommendedGuideCommand = $patchTargetsCommand
    $nextArtifactToOpen = $manifestPath
} else {
    $status = 'runner-contract-incomplete'
    $reason = 'Both the saved summary and manifest still omit at least one top-level refresh or handoff runner-output field, so later helpers are still recovering part of the chain indirectly.'
    $nextFocus = 'Keep the issue #3 helper chain on the direct runner-output contract until both summary and manifest expose refresh and handoff path plus error fields directly.'
    $recommendedCommand = $runnerRefreshWiringCommand
    $recommendedGuideCommand = $patchTargetsCommand
    $nextArtifactToOpen = $SummaryPath
}

$report = [ordered]@{
    issue = 'Google issue #3 runner output wiring status'
    purpose = 'Audit whether the recommended validation runner writes refresh and handoff path and error fields directly into the saved summary and manifest outputs.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_readable = [bool]$manifestReadable
    resolved_refresh_artifact_path = $refreshPath
    resolved_refresh_artifact_path_source = $resolvedRefreshPathSource
    resolved_handoff_artifact_path = $handoffPath
    resolved_handoff_artifact_path_source = $resolvedHandoffPathSource
    summary_has_refresh_artifact_path_field = [bool]$summaryHasRefreshPathField
    summary_has_refresh_artifact_error_field = [bool]$summaryHasRefreshErrorField
    summary_has_handoff_artifact_path_field = [bool]$summaryHasHandoffPathField
    summary_has_handoff_artifact_error_field = [bool]$summaryHasHandoffErrorField
    summary_has_all_runner_fields = [bool]$summaryHasAllRunnerFields
    summary_refresh_artifact_path = if ($summaryHasRefreshPathField) { $configuredSummaryRefreshPath } else { $null }
    summary_handoff_artifact_path = if ($summaryHasHandoffPathField) { $configuredSummaryHandoffPath } else { $null }
    summary_records_refresh_artifact_path = [bool]$summaryRecordsRefreshPath
    summary_records_handoff_artifact_path = [bool]$summaryRecordsHandoffPath
    summary_refresh_artifact_error_populated = [bool]$summaryRefreshErrorPopulated
    summary_handoff_artifact_error_populated = [bool]$summaryHandoffErrorPopulated
    summary_missing_refresh_fields = [bool]$summaryMissingRefreshFields
    summary_missing_handoff_fields = [bool]$summaryMissingHandoffFields
    manifest_has_refresh_artifact_path_field = [bool]$manifestHasRefreshPathField
    manifest_has_refresh_artifact_error_field = [bool]$manifestHasRefreshErrorField
    manifest_has_handoff_artifact_path_field = [bool]$manifestHasHandoffPathField
    manifest_has_handoff_artifact_error_field = [bool]$manifestHasHandoffErrorField
    manifest_has_all_runner_fields = [bool]$manifestHasAllRunnerFields
    manifest_refresh_artifact_path = if ($manifestHasRefreshPathField) { $configuredManifestRefreshPath } else { $null }
    manifest_handoff_artifact_path = if ($manifestHasHandoffPathField) { $configuredManifestHandoffPath } else { $null }
    manifest_records_refresh_artifact_path = [bool]$manifestRecordsRefreshPath
    manifest_records_handoff_artifact_path = [bool]$manifestRecordsHandoffPath
    manifest_refresh_artifact_error_populated = [bool]$manifestRefreshErrorPopulated
    manifest_handoff_artifact_error_populated = [bool]$manifestHandoffErrorPopulated
    manifest_missing_refresh_fields = [bool]$manifestMissingRefreshFields
    manifest_missing_handoff_fields = [bool]$manifestMissingHandoffFields
    refresh_contract_incomplete = [bool]$refreshContractIncomplete
    handoff_contract_incomplete = [bool]$handoffContractIncomplete
    runner_outputs_fully_wired = [bool]$runnerOutputsFullyWired
    manifest_backfills_summary = [bool]$manifestBackfillsSummary
    summary_outruns_manifest = [bool]$summaryOutrunsManifest
    runner_script_path = $runnerScriptPath
    runner_script_exists = [bool]$runnerScriptExists
    runner_source_indicates_direct_field_wiring = [bool]$runnerSourceIndicatesDirectFieldWiring
    runner_patch_still_required = [bool]$runnerPatchStillRequired
    runner_direct_field_assignment_counts = [ordered]@{
        refresh_chain_artifact_path = $runnerRefreshPathAssignmentCount
        refresh_chain_artifact_error = $runnerRefreshErrorAssignmentCount
        handoff_artifact_path = $runnerHandoffPathAssignmentCount
        handoff_artifact_error = $runnerHandoffErrorAssignmentCount
    }
    missing_runner_fields = @($missingFields)
    next_artifact_to_open = $nextArtifactToOpen
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    runner_refresh_wiring_command = $runnerRefreshWiringCommand
    pointer_sources_command = $pointerSourcesCommand
    patch_targets_command = $patchTargetsCommand
    refresh_status_command = $refreshStatusCommand
    handoff_guide_command = $handoffGuideCommand
    repair_runner_output_contract_command = $repairRunnerOutputContractCommand
    broader_runner_command = $recommendedRunnerCommand
    status = $status
    reason = $reason
    next_focus = $nextFocus
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 runner output wiring status'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
Write-Host ("Manifest readable: {0}" -f $report.manifest_artifact_readable)
Write-Host ("Refresh:   {0}" -f $report.resolved_refresh_artifact_path)
Write-Host ("Refresh source: {0}" -f $report.resolved_refresh_artifact_path_source)
Write-Host ("Handoff:   {0}" -f $report.resolved_handoff_artifact_path)
Write-Host ("Handoff source: {0}" -f $report.resolved_handoff_artifact_path_source)
Write-Host ("Summary has all fields: {0}" -f $report.summary_has_all_runner_fields)
Write-Host ("Manifest has all fields: {0}" -f $report.manifest_has_all_runner_fields)
Write-Host ("Summary missing refresh fields: {0}" -f $report.summary_missing_refresh_fields)
Write-Host ("Summary missing handoff fields: {0}" -f $report.summary_missing_handoff_fields)
Write-Host ("Manifest missing refresh fields: {0}" -f $report.manifest_missing_refresh_fields)
Write-Host ("Manifest missing handoff fields: {0}" -f $report.manifest_missing_handoff_fields)
Write-Host ("Refresh contract incomplete: {0}" -f $report.refresh_contract_incomplete)
Write-Host ("Handoff contract incomplete: {0}" -f $report.handoff_contract_incomplete)
Write-Host ("Fully wired: {0}" -f $report.runner_outputs_fully_wired)
Write-Host ("Runner script: {0}" -f $report.runner_script_path)
Write-Host ("Runner source wired: {0}" -f $report.runner_source_indicates_direct_field_wiring)
Write-Host ("Runner patch still required: {0}" -f $report.runner_patch_still_required)
if ($report.manifest_backfills_summary) {
    Write-Host 'Manifest backfills summary: True'
}
if ($report.summary_outruns_manifest) {
    Write-Host 'Summary outruns manifest: True'
}
if ($report.missing_runner_fields.Count -gt 0) {
    Write-Host 'Missing fields:'
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
Write-Host ("Repair: {0}" -f $report.repair_runner_output_contract_command)
