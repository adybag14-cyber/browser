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
$artifactRoot = if (-not [string]::IsNullOrWhiteSpace($summary.artifact_root)) {
    $summary.artifact_root
} else {
    Split-Path -Parent $SummaryPath
}

$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.manifest_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
$manifestRecord = Read-ArtifactJson $manifestPath
$manifestReadable = [bool]$manifestRecord

$refreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.refresh_chain_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.handoff_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'

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

$summaryRecordsRefreshPath = [bool]($summaryHasRefreshPathField -and -not [string]::IsNullOrWhiteSpace($summary.refresh_chain_artifact_path))
$summaryRecordsHandoffPath = [bool]($summaryHasHandoffPathField -and -not [string]::IsNullOrWhiteSpace($summary.handoff_artifact_path))
$manifestRecordsRefreshPath = [bool]($manifestHasRefreshPathField -and -not [string]::IsNullOrWhiteSpace($manifestRecord.refresh_chain_artifact_path))
$manifestRecordsHandoffPath = [bool]($manifestHasHandoffPathField -and -not [string]::IsNullOrWhiteSpace($manifestRecord.handoff_artifact_path))

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
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

$runnerOutputsFullyWired = [bool]($summaryHasAllRunnerFields -and $manifestHasAllRunnerFields)
$manifestBackfillsSummary = [bool]((-not $summaryHasAllRunnerFields) -and $manifestHasAllRunnerFields)
$summaryOutrunsManifest = [bool]($summaryHasAllRunnerFields -and (-not $manifestHasAllRunnerFields))

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
    $nextArtifactToOpen = if ($summaryRecordsHandoffPath) { $summary.handoff_artifact_path } elseif ($manifestRecordsHandoffPath) { $manifestRecord.handoff_artifact_path } else { $handoffPath }
} elseif ($manifestBackfillsSummary) {
    $status = 'summary-still-needs-direct-fields'
    $reason = 'The manifest already carries the full refresh and handoff runner-output contract, but the summary still omits at least one of those top-level fields.'
    $nextFocus = 'Keep the issue #3 helper chain on the runner wiring audit until the summary exposes the same direct refresh and handoff fields without relying on manifest recovery.'
    $recommendedCommand = $runnerRefreshWiringCommand
    $recommendedGuideCommand = $pointerSourcesCommand
    $nextArtifactToOpen = $SummaryPath
} elseif ($summaryOutrunsManifest) {
    $status = 'manifest-still-needs-direct-fields'
    $reason = 'The summary already exposes the refresh and handoff runner-output contract, but the manifest still omits at least one of those top-level fields.'
    $nextFocus = 'Keep the issue #3 helper chain on the runner wiring audit until the manifest advertises the same direct refresh and handoff fields as the summary.'
    $recommendedCommand = $runnerRefreshWiringCommand
    $recommendedGuideCommand = $pointerSourcesCommand
    $nextArtifactToOpen = $manifestPath
} else {
    $status = 'runner-contract-incomplete'
    $reason = 'Both the saved summary and manifest still omit at least one top-level refresh or handoff runner-output field, so later helpers are still recovering part of the chain indirectly.'
    $nextFocus = 'Keep the issue #3 helper chain on the runner-output contract until both summary and manifest expose refresh and handoff path plus error fields directly.'
    $recommendedCommand = $runnerRefreshWiringCommand
    $recommendedGuideCommand = $pointerSourcesCommand
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
    resolved_handoff_artifact_path = $handoffPath
    summary_has_refresh_artifact_path_field = [bool]$summaryHasRefreshPathField
    summary_has_refresh_artifact_error_field = [bool]$summaryHasRefreshErrorField
    summary_has_handoff_artifact_path_field = [bool]$summaryHasHandoffPathField
    summary_has_handoff_artifact_error_field = [bool]$summaryHasHandoffErrorField
    summary_has_all_runner_fields = [bool]$summaryHasAllRunnerFields
    summary_records_refresh_artifact_path = [bool]$summaryRecordsRefreshPath
    summary_records_handoff_artifact_path = [bool]$summaryRecordsHandoffPath
    summary_refresh_artifact_error_populated = [bool]$summaryRefreshErrorPopulated
    summary_handoff_artifact_error_populated = [bool]$summaryHandoffErrorPopulated
    manifest_has_refresh_artifact_path_field = [bool]$manifestHasRefreshPathField
    manifest_has_refresh_artifact_error_field = [bool]$manifestHasRefreshErrorField
    manifest_has_handoff_artifact_path_field = [bool]$manifestHasHandoffPathField
    manifest_has_handoff_artifact_error_field = [bool]$manifestHasHandoffErrorField
    manifest_has_all_runner_fields = [bool]$manifestHasAllRunnerFields
    manifest_records_refresh_artifact_path = [bool]$manifestRecordsRefreshPath
    manifest_records_handoff_artifact_path = [bool]$manifestRecordsHandoffPath
    manifest_refresh_artifact_error_populated = [bool]$manifestRefreshErrorPopulated
    manifest_handoff_artifact_error_populated = [bool]$manifestHandoffErrorPopulated
    runner_outputs_fully_wired = [bool]$runnerOutputsFullyWired
    manifest_backfills_summary = [bool]$manifestBackfillsSummary
    summary_outruns_manifest = [bool]$summaryOutrunsManifest
    missing_runner_fields = @($missingFields)
    next_artifact_to_open = $nextArtifactToOpen
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    runner_refresh_wiring_command = $runnerRefreshWiringCommand
    pointer_sources_command = $pointerSourcesCommand
    refresh_status_command = $refreshStatusCommand
    handoff_guide_command = $handoffGuideCommand
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
Write-Host ("Handoff:   {0}" -f $report.resolved_handoff_artifact_path)
Write-Host ("Summary has all fields: {0}" -f $report.summary_has_all_runner_fields)
Write-Host ("Manifest has all fields: {0}" -f $report.manifest_has_all_runner_fields)
Write-Host ("Fully wired: {0}" -f $report.runner_outputs_fully_wired)
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
