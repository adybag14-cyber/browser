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

function Test-ExistingFile([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }

    return Test-Path -LiteralPath $Path -PathType Leaf
}

function New-ArtifactReference {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [string]$Path
    )

    [pscustomobject]@{
        label = $Label
        path = $Path
        exists = Test-ExistingFile $Path
    }
}

function Read-ArtifactJson {
    param([string]$Path)

    if (-not (Test-ExistingFile $Path)) {
        return $null
    }

    try {
        return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function New-CrossReferenceMismatch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [string]$Path,
        [string]$RecordedSummaryPath,
        [string]$RepairCommand
    )

    [pscustomobject]@{
        label = $Label
        path = $Path
        recorded_summary_path = $RecordedSummaryPath
        repair_command = $RepairCommand
    }
}

function New-StaleSummaryArtifactDetail {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [string]$Path,
        [string]$ExpectedSummaryGeneratedAtUtc,
        [string]$RecordedSummaryGeneratedAtUtc,
        [string]$RepairCommand
    )

    [pscustomobject]@{
        label = $Label
        path = $Path
        expected_summary_generated_at_utc = $ExpectedSummaryGeneratedAtUtc
        recorded_summary_generated_at_utc = $RecordedSummaryGeneratedAtUtc
        repair_command = $RepairCommand
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
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot "google-issue3-validation-artifact-bundle.json"
}

$surfacePath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.surface_check_artifact_path -ArtifactRoot $artifactRoot -FallbackName "google-issue3-recommended-validation-surface.json"
$guidePath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.guide_artifact_path -ArtifactRoot $artifactRoot -FallbackName "google-issue3-recommended-validation-guide.json"
$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.manifest_artifact_path -ArtifactRoot $artifactRoot -FallbackName "google-issue3-recommended-validation-manifest.json"
$boundaryPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.boundary_artifact_path -ArtifactRoot $artifactRoot -FallbackName "google-issue3-phase-boundary.json"
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.handoff_artifact_path -ArtifactRoot $artifactRoot -FallbackName "google-issue3-validation-handoff.json"
$refreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.refresh_chain_artifact_path -ArtifactRoot $artifactRoot -FallbackName "google-issue3-validation-handoff-chain-refresh.json"
$phaseRoot = if (-not [string]::IsNullOrWhiteSpace($summary.phase_artifact_root)) {
    $summary.phase_artifact_root
} else {
    Join-Path $artifactRoot "google-issue3-recommended-validation-phases"
}
$summaryRecordsHandoffArtifactPath = -not [string]::IsNullOrWhiteSpace($summary.handoff_artifact_path)
$summaryRecordsRefreshArtifactPath = -not [string]::IsNullOrWhiteSpace($summary.refresh_chain_artifact_path)
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'
$manifestGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest.ps1'
$boundaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_phase_boundary.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'

$summaryRef = New-ArtifactReference -Label "summary" -Path $SummaryPath
$surfaceRef = New-ArtifactReference -Label "surface" -Path $surfacePath
$guideRef = New-ArtifactReference -Label "guide" -Path $guidePath
$manifestRef = New-ArtifactReference -Label "manifest" -Path $manifestPath
$boundaryRef = New-ArtifactReference -Label "boundary" -Path $boundaryPath
$handoffRef = New-ArtifactReference -Label "handoff" -Path $handoffPath
$refreshRef = New-ArtifactReference -Label "refresh" -Path $refreshPath
$coreRefs = @($summaryRef, $surfaceRef, $guideRef, $manifestRef, $boundaryRef, $handoffRef, $refreshRef)
$coreMissing = @($coreRefs | Where-Object { -not $_.exists })
$coreMissingLabels = @($coreMissing | ForEach-Object { $_.label })

$guideRecord = Read-ArtifactJson $guidePath
$boundaryRecord = Read-ArtifactJson $boundaryPath
$manifestRecord = Read-ArtifactJson $manifestPath
$handoffRecord = Read-ArtifactJson $handoffPath
$refreshRecord = Read-ArtifactJson $refreshPath

$crossReferenceMismatches = [System.Collections.Generic.List[object]]::new()
if ($manifestRecord -and $manifestRecord.summary_path -and $manifestRecord.summary_path -ne $SummaryPath) {
    $crossReferenceMismatches.Add((New-CrossReferenceMismatch -Label 'manifest' -Path $manifestPath -RecordedSummaryPath $manifestRecord.summary_path -RepairCommand $refreshChainCommand)) | Out-Null
}
if ($guideRecord -and $guideRecord.summary_path -and $guideRecord.summary_path -ne $SummaryPath) {
    $crossReferenceMismatches.Add((New-CrossReferenceMismatch -Label 'guide' -Path $guidePath -RecordedSummaryPath $guideRecord.summary_path -RepairCommand $refreshChainCommand)) | Out-Null
}
if ($boundaryRecord -and $boundaryRecord.summary_path -and $boundaryRecord.summary_path -ne $SummaryPath) {
    $crossReferenceMismatches.Add((New-CrossReferenceMismatch -Label 'boundary' -Path $boundaryPath -RecordedSummaryPath $boundaryRecord.summary_path -RepairCommand $refreshChainCommand)) | Out-Null
}
if ($handoffRecord -and $handoffRecord.summary_path -and $handoffRecord.summary_path -ne $SummaryPath) {
    $crossReferenceMismatches.Add((New-CrossReferenceMismatch -Label 'handoff' -Path $handoffPath -RecordedSummaryPath $handoffRecord.summary_path -RepairCommand $refreshChainCommand)) | Out-Null
}
if ($refreshRecord -and $refreshRecord.summary_path -and $refreshRecord.summary_path -ne $SummaryPath) {
    $crossReferenceMismatches.Add((New-CrossReferenceMismatch -Label 'refresh' -Path $refreshPath -RecordedSummaryPath $refreshRecord.summary_path -RepairCommand $refreshChainCommand)) | Out-Null
}
$staleCrossReferenceDetected = $crossReferenceMismatches.Count -gt 0
$staleCrossReferenceLabels = @($crossReferenceMismatches | ForEach-Object { $_.label })
$staleCrossReferencePaths = @($crossReferenceMismatches | ForEach-Object { $_.path })
$staleCrossReferenceRepairCommands = @($crossReferenceMismatches | ForEach-Object { $_.repair_command } | Select-Object -Unique)
$preferredStaleRepairCommand = if ($staleCrossReferenceDetected) {
    $refreshChainCommand
} else {
    $null
}

$summaryGeneratedAtUtc = $summary.generated_at_utc
$staleSummaryArtifactDetails = [System.Collections.Generic.List[object]]::new()
$guideSummaryGeneratedAtUtc = if ($guideRecord -and -not [string]::IsNullOrWhiteSpace($guideRecord.generated_at_utc)) {
    $guideRecord.generated_at_utc
} else {
    $null
}
$boundarySummaryGeneratedAtUtc = if ($boundaryRecord -and -not [string]::IsNullOrWhiteSpace($boundaryRecord.generated_at_utc)) {
    $boundaryRecord.generated_at_utc
} else {
    $null
}
$handoffSummaryGeneratedAtUtc = if ($handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffRecord.summary_generated_at_utc)) {
    $handoffRecord.summary_generated_at_utc
} else {
    $null
}
if (-not [string]::IsNullOrWhiteSpace($summaryGeneratedAtUtc)) {
    if ($guideRecord -and $guideSummaryGeneratedAtUtc -and $guideSummaryGeneratedAtUtc -ne $summaryGeneratedAtUtc) {
        $staleSummaryArtifactDetails.Add((New-StaleSummaryArtifactDetail -Label 'guide' -Path $guidePath -ExpectedSummaryGeneratedAtUtc $summaryGeneratedAtUtc -RecordedSummaryGeneratedAtUtc $guideSummaryGeneratedAtUtc -RepairCommand $refreshChainCommand)) | Out-Null
    }
    if ($boundaryRecord -and $boundarySummaryGeneratedAtUtc -and $boundarySummaryGeneratedAtUtc -ne $summaryGeneratedAtUtc) {
        $staleSummaryArtifactDetails.Add((New-StaleSummaryArtifactDetail -Label 'boundary' -Path $boundaryPath -ExpectedSummaryGeneratedAtUtc $summaryGeneratedAtUtc -RecordedSummaryGeneratedAtUtc $boundarySummaryGeneratedAtUtc -RepairCommand $refreshChainCommand)) | Out-Null
    }
    if ($handoffRecord -and $handoffSummaryGeneratedAtUtc -and $handoffSummaryGeneratedAtUtc -ne $summaryGeneratedAtUtc) {
        $staleSummaryArtifactDetails.Add((New-StaleSummaryArtifactDetail -Label 'handoff' -Path $handoffPath -ExpectedSummaryGeneratedAtUtc $summaryGeneratedAtUtc -RecordedSummaryGeneratedAtUtc $handoffSummaryGeneratedAtUtc -RepairCommand $refreshChainCommand)) | Out-Null
    }
}
$staleSummaryArtifactDetected = $staleSummaryArtifactDetails.Count -gt 0
$staleSummaryArtifactLabels = @($staleSummaryArtifactDetails | ForEach-Object { $_.label })
$staleSummaryArtifactPaths = @($staleSummaryArtifactDetails | ForEach-Object { $_.path })
$staleSummaryArtifactRepairCommands = @($staleSummaryArtifactDetails | ForEach-Object { $_.repair_command } | Select-Object -Unique)

$phaseResults = @($summary.phase_results)
$phaseStatuses = [ordered]@{}
$phaseHealth = [System.Collections.Generic.List[object]]::new()
$coreArtifactMissingPaths = [System.Collections.Generic.List[string]]::new()
foreach ($missingCore in $coreMissing) {
    if (-not [string]::IsNullOrWhiteSpace($missingCore.path)) {
        $coreArtifactMissingPaths.Add($missingCore.path) | Out-Null
    }
}

foreach ($phase in $phaseResults) {
    $phaseMissing = [System.Collections.Generic.List[string]]::new()
    $logExists = Test-ExistingFile $phase.log_path
    if (-not $logExists -and -not [string]::IsNullOrWhiteSpace($phase.log_path)) {
        $phaseMissing.Add($phase.log_path) | Out-Null
    }

    $primaryJsonExists = Test-ExistingFile $phase.primary_json_artifact_path
    if ($phase.primary_json_artifact_path -and -not $primaryJsonExists) {
        $phaseMissing.Add($phase.primary_json_artifact_path) | Out-Null
    }

    $artifactPaths = @($phase.artifact_paths)
    $missingArtifactPaths = @($artifactPaths | Where-Object { -not (Test-ExistingFile $_) })
    foreach ($missingArtifactPath in $missingArtifactPaths) {
        $phaseMissing.Add($missingArtifactPath) | Out-Null
    }

    $phaseRecord = [pscustomobject]@{
        name = $phase.name
        status = $phase.status
        log_path = $phase.log_path
        log_exists = $logExists
        primary_json_artifact_path = $phase.primary_json_artifact_path
        primary_json_artifact_exists = $primaryJsonExists
        artifact_count = @($artifactPaths).Count
        missing_paths = @($phaseMissing | Select-Object -Unique)
        missing_count = @($phaseMissing | Select-Object -Unique).Count
        error = $phase.error
    }
    $phaseHealth.Add($phaseRecord) | Out-Null
    $phaseStatuses[$phase.name] = $phase.status
}

$phaseLogMissingCount = @($phaseHealth | Where-Object { -not $_.log_exists }).Count
$phaseJsonMissingCount = @($phaseHealth | Where-Object { $_.primary_json_artifact_path -and -not $_.primary_json_artifact_exists }).Count
$totalPhaseMissingCount = 0
foreach ($phaseRecord in $phaseHealth) {
    $totalPhaseMissingCount += $phaseRecord.missing_count
}

$firstFailedPhaseHealth = @($phaseHealth | Where-Object { $_.name -eq $summary.first_failed_phase } | Select-Object -First 1)
$nextArtifactToOpen = if ($staleCrossReferenceDetected -or $staleSummaryArtifactDetected) {
    $SummaryPath
} elseif (-not $summaryRecordsRefreshArtifactPath -and $refreshRef.exists) {
    $refreshPath
} elseif (-not $summaryRecordsHandoffArtifactPath -and $handoffRef.exists) {
    $handoffPath
} elseif (-not $refreshRef.exists) {
    $SummaryPath
} elseif (-not $handoffRef.exists) {
    $SummaryPath
} elseif ($handoffRecord -and $handoffRecord.next_artifact_to_open) {
    $handoffRecord.next_artifact_to_open
} elseif ($handoffRef.exists) {
    $handoffPath
} elseif ($boundaryRecord -and $boundaryRecord.next_artifact_to_open) {
    $boundaryRecord.next_artifact_to_open
} elseif ($guideRecord -and $guideRecord.first_failed_phase_primary_json_artifact_path) {
    $guideRecord.first_failed_phase_primary_json_artifact_path
} elseif ($boundaryRef.exists) {
    $boundaryPath
} elseif ($guideRef.exists) {
    $guidePath
} elseif ($manifestRef.exists) {
    $manifestPath
} elseif ($surfaceRef.exists) {
    $surfacePath
} else {
    $SummaryPath
}

$recommendedCommand = if ($staleCrossReferenceDetected -or $staleSummaryArtifactDetected) {
    $refreshChainCommand
} elseif ($coreMissingLabels -contains 'refresh') {
    $refreshChainCommand
} elseif ($coreMissingLabels -contains 'handoff') {
    $refreshChainCommand
} elseif ($handoffRecord -and $handoffRecord.recommended_command) {
    $handoffRecord.recommended_command
} elseif ($boundaryRecord -and $boundaryRecord.recommended_command) {
    $boundaryRecord.recommended_command
} elseif ($guideRecord -and $guideRecord.recommended_command) {
    $guideRecord.recommended_command
} else {
    $null
}
$recommendedGuideCommand = if ($staleCrossReferenceDetected -or $staleSummaryArtifactDetected) {
    $refreshStatusCommand
} elseif ($coreMissingLabels -contains 'refresh') {
    $refreshStatusCommand
} elseif ($coreMissingLabels -contains 'handoff') {
    $handoffGuideCommand
} elseif ($handoffRecord -and $handoffRecord.recommended_guide_command) {
    $handoffRecord.recommended_guide_command
} elseif ($boundaryRecord -and $boundaryRecord.recommended_guide_command) {
    $boundaryRecord.recommended_guide_command
} elseif ($guideRecord -and $guideRecord.recommended_guide_command) {
    $guideRecord.recommended_guide_command
} else {
    $null
}
$nextFocus = if ($staleCrossReferenceDetected) {
    'Refresh the saved issue #3 handoff chain so the refresh, handoff, manifest, guide, and boundary helpers all point at the current recommended-validation summary before trusting the next replay handoff.'
} elseif ($staleSummaryArtifactDetected) {
    'Refresh the saved issue #3 helper artifacts so the guide, boundary, and handoff outputs match the current recommended-validation summary generation before trusting the next replay handoff.'
} elseif (-not $summaryRecordsRefreshArtifactPath) {
    'The summary artifact does not record its refresh JSON path yet, so open the saved refresh artifact directly and keep the refresh-chain helper ready until the runner catches up.'
} elseif (-not $summaryRecordsHandoffArtifactPath) {
    'The summary artifact does not record its handoff JSON path yet, so open the saved handoff artifact directly and keep the refresh-chain helper ready until the runner catches up.'
} elseif ($coreMissingLabels -contains 'refresh') {
    'Regenerate the saved refresh artifact so the next Windows replay can tell whether the summary-derived helper chain already converged before trusting the narrower handoff.'
} elseif ($coreMissingLabels -contains 'handoff') {
    'Regenerate the saved handoff artifact so the next Windows replay can reopen the current bounded checkpoint without guessing which helper artifact to trust first.'
} elseif ($handoffRecord -and $handoffRecord.next_focus) {
    $handoffRecord.next_focus
} elseif ($boundaryRecord -and $boundaryRecord.next_focus) {
    $boundaryRecord.next_focus
} elseif ($guideRecord -and $guideRecord.next_focus) {
    $guideRecord.next_focus
} else {
    'Open the first failing phase artifact before widening back out to the full issue #3 replay.'
}

$status = if ($coreMissing.Count -eq 0 -and $totalPhaseMissingCount -eq 0 -and -not $staleCrossReferenceDetected -and -not $staleSummaryArtifactDetected) {
    'complete'
} elseif (-not $summaryRef.exists) {
    'missing-summary'
} elseif ($coreMissing.Count -gt 0) {
    'missing-core-artifacts'
} elseif ($staleCrossReferenceDetected -or $staleSummaryArtifactDetected) {
    'stale-helper-artifacts'
} else {
    'missing-phase-artifacts'
}

$bundle = [ordered]@{
    issue = 'Google issue #3 validation artifact bundle'
    purpose = 'Check whether the saved recommended-validation artifact family is complete, including the handoff and refresh artifacts, call out stale cross-references or stale summary-derived helper state, and point the next Windows headed replay at the best artifact to open first.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_generated_at_utc = $summaryGeneratedAtUtc
    artifact_bundle_path = $ArtifactPath
    repo_root = $repoRoot
    artifact_root = $artifactRoot
    phase_artifact_root = $phaseRoot
    status = $status
    completed = [bool]$summary.completed
    first_failed_phase = $summary.first_failed_phase
    first_failed_phase_error = $summary.first_failed_phase_error
    surface_check_status = $summary.surface_check_status
    guide_artifact_error = if ($summary.guide_artifact_error) { $summary.guide_artifact_error } else { $null }
    boundary_artifact_error = if ($summary.boundary_artifact_error) { $summary.boundary_artifact_error } else { $null }
    phase_result_count = $phaseResults.Count
    core_missing_count = $coreMissing.Count
    core_missing_labels = @($coreMissingLabels)
    core_missing_paths = @($coreArtifactMissingPaths)
    phase_log_missing_count = $phaseLogMissingCount
    phase_json_missing_count = $phaseJsonMissingCount
    phase_missing_artifact_count = $totalPhaseMissingCount
    stale_cross_reference_detected = [bool]$staleCrossReferenceDetected
    stale_cross_reference_count = $crossReferenceMismatches.Count
    stale_cross_reference_labels = @($staleCrossReferenceLabels)
    stale_cross_reference_paths = @($staleCrossReferencePaths)
    stale_cross_reference_details = @($crossReferenceMismatches)
    stale_cross_reference_repair_commands = @($staleCrossReferenceRepairCommands)
    stale_summary_artifact_detected = [bool]$staleSummaryArtifactDetected
    stale_summary_artifact_count = $staleSummaryArtifactDetails.Count
    stale_summary_artifact_labels = @($staleSummaryArtifactLabels)
    stale_summary_artifact_paths = @($staleSummaryArtifactPaths)
    stale_summary_artifact_details = @($staleSummaryArtifactDetails)
    stale_summary_artifact_repair_commands = @($staleSummaryArtifactRepairCommands)
    handoff_artifact_path = $handoffPath
    handoff_artifact_exists = [bool]$handoffRef.exists
    refresh_artifact_path = $refreshPath
    refresh_artifact_exists = [bool]$refreshRef.exists
    refresh_status = if ($refreshRecord -and $refreshRecord.status) {
        $refreshRecord.status
    } elseif ($refreshRef.exists) {
        'present'
    } else {
        'missing'
    }
    refresh_summary_path = if ($refreshRecord) { $refreshRecord.summary_path } else { $null }
    refresh_summary_generated_at_utc = if ($refreshRecord) { $refreshRecord.generated_at_utc } else { $null }
    refresh_summary_path_matches = if ($refreshRecord -and $refreshRecord.summary_path) {
        $refreshRecord.summary_path -eq $SummaryPath
    } else {
        $null
    }
    refresh_reason = if ($refreshRecord) { $refreshRecord.reason } else { $null }
    refresh_recommended_command = if ($refreshRecord -and $refreshRecord.recommended_command) {
        $refreshRecord.recommended_command
    } else {
        $refreshChainCommand
    }
    refresh_recommended_guide_command = if ($refreshRecord -and $refreshRecord.recommended_guide_command) {
        $refreshRecord.recommended_guide_command
    } else {
        $refreshStatusCommand
    }
    refresh_next_artifact_to_open = if ($refreshRecord) { $refreshRecord.next_artifact_to_open } else { $null }
    summary_records_handoff_artifact_path = [bool]$summaryRecordsHandoffArtifactPath
    summary_handoff_artifact_path = if ($summaryRecordsHandoffArtifactPath) { $summary.handoff_artifact_path } else { $null }
    summary_missing_handoff_pointer = [bool](-not $summaryRecordsHandoffArtifactPath)
    summary_records_refresh_artifact_path = [bool]$summaryRecordsRefreshArtifactPath
    summary_refresh_artifact_path = if ($summaryRecordsRefreshArtifactPath) { $summary.refresh_chain_artifact_path } else { $null }
    summary_missing_refresh_pointer = [bool](-not $summaryRecordsRefreshArtifactPath)
    refresh_chain_command = $refreshChainCommand
    refresh_status_command = $refreshStatusCommand
    next_artifact_to_open = $nextArtifactToOpen
    boundary_last_passed_phase = if ($boundaryRecord) { $boundaryRecord.last_passed_phase } else { $null }
    boundary_first_failed_phase = if ($boundaryRecord) { $boundaryRecord.first_failed_phase } else { $null }
    boundary_focus = if ($boundaryRecord) { $boundaryRecord.boundary_focus } else { $null }
    boundary_reason = if ($boundaryRecord) { $boundaryRecord.reason } else { $null }
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    recommended_runner_command = if ($handoffRecord -and $handoffRecord.broader_runner_command) {
        $handoffRecord.broader_runner_command
    } elseif ($guideRecord -and $guideRecord.broader_runner_command) {
        $guideRecord.broader_runner_command
    } else {
        $recommendedRunnerCommand
    }
    phase_boundary_command = if ($guideRecord) { $guideRecord.phase_boundary_command } else { $boundaryGuideCommand }
    summary_guide_command = $summaryGuideCommand
    manifest_guide_command = $manifestGuideCommand
    handoff_guide_command = $handoffGuideCommand
    next_focus = $nextFocus
    first_missing_path = if ($coreArtifactMissingPaths.Count -gt 0) {
        $coreArtifactMissingPaths[0]
    } elseif ($firstFailedPhaseHealth.Count -gt 0 -and $firstFailedPhaseHealth[0].missing_count -gt 0) {
        $firstFailedPhaseHealth[0].missing_paths[0]
    } elseif ($staleCrossReferenceDetected) {
        $staleCrossReferencePaths[0]
    } elseif ($staleSummaryArtifactDetected) {
        $staleSummaryArtifactPaths[0]
    } else {
        $null
    }
    manual_fixture_replay_available = if ($guideRecord) { [bool]$guideRecord.manual_fixture_replay_available } else { $false }
    manual_fixture_replay_command = if ($guideRecord) { $guideRecord.manual_fixture_replay_command } else { $null }
    manual_asset_closure_command = if ($guideRecord) { $guideRecord.manual_asset_closure_command } else { $null }
    manual_attached_html_flow_command = if ($guideRecord) { $guideRecord.manual_attached_html_flow_command } else { $null }
    manual_attached_html_runner_command = if ($guideRecord) { $guideRecord.manual_attached_html_runner_command } else { $null }
    manual_saved_page_flow_command = if ($guideRecord) { $guideRecord.manual_saved_page_flow_command } else { $null }
    core_artifacts = @($coreRefs)
    phase_health = @($phaseHealth)
    manifest_summary_path_matches = if ($manifestRecord -and $manifestRecord.summary_path) {
        $manifestRecord.summary_path -eq $SummaryPath
    } else {
        $null
    }
    guide_summary_path_matches = if ($guideRecord -and $guideRecord.summary_path) {
        $guideRecord.summary_path -eq $SummaryPath
    } else {
        $null
    }
    boundary_summary_path_matches = if ($boundaryRecord -and $boundaryRecord.summary_path) {
        $boundaryRecord.summary_path -eq $SummaryPath
    } else {
        $null
    }
    handoff_summary_path_matches = if ($handoffRecord -and $handoffRecord.summary_path) {
        $handoffRecord.summary_path -eq $SummaryPath
    } else {
        $null
    }
    phase_statuses = $phaseStatuses
}

$bundle | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $bundle | ConvertTo-Json -Depth 8
    if ($status -ne 'complete') {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 validation artifact bundle'
Write-Host ''
Write-Host ("Summary:   {0}" -f $SummaryPath)
Write-Host ("Bundle:    {0}" -f $ArtifactPath)
Write-Host ("Status:    {0}" -f $status)
Write-Host ("Completed: {0}" -f $bundle.completed)
Write-Host ("Surface:   {0}" -f $bundle.surface_check_status)
Write-Host ("First fail:{0}" -f $(if ($bundle.first_failed_phase) { ' ' + $bundle.first_failed_phase } else { ' none' }))
Write-Host ("Core missing: {0}" -f $bundle.core_missing_count)
Write-Host ("Phase log missing: {0}" -f $bundle.phase_log_missing_count)
Write-Host ("Phase JSON missing: {0}" -f $bundle.phase_json_missing_count)
Write-Host ("Phase artifact gaps: {0}" -f $bundle.phase_missing_artifact_count)
Write-Host ("Stale refs: {0}" -f $bundle.stale_cross_reference_count)
Write-Host ("Stale summary helpers: {0}" -f $bundle.stale_summary_artifact_count)
Write-Host ("Refresh exists: {0}" -f $bundle.refresh_artifact_exists)
Write-Host ("Refresh status: {0}" -f $bundle.refresh_status)
Write-Host ("Summary refresh path recorded: {0}" -f $bundle.summary_records_refresh_artifact_path)
if ($bundle.summary_refresh_artifact_path) {
    Write-Host ("Summary refresh path: {0}" -f $bundle.summary_refresh_artifact_path)
}
Write-Host ("Handoff exists: {0}" -f $bundle.handoff_artifact_exists)
Write-Host ("Summary handoff path recorded: {0}" -f $bundle.summary_records_handoff_artifact_path)
if ($bundle.summary_handoff_artifact_path) {
    Write-Host ("Summary handoff path: {0}" -f $bundle.summary_handoff_artifact_path)
}
if ($bundle.guide_artifact_error) {
    Write-Host ("Guide error: {0}" -f $bundle.guide_artifact_error)
}
if ($bundle.boundary_artifact_error) {
    Write-Host ("Boundary error: {0}" -f $bundle.boundary_artifact_error)
}
Write-Host ''
foreach ($reference in $coreRefs) {
    $marker = if ($reference.exists) { 'OK' } else { 'MISSING' }
    Write-Host ("[{0}] {1}: {2}" -f $marker, $reference.label, $reference.path)
}
if ($bundle.stale_cross_reference_detected) {
    Write-Host ''
    Write-Host 'Stale cross-references:'
    foreach ($mismatch in $bundle.stale_cross_reference_details) {
        Write-Host ("- {0}: {1}" -f $mismatch.label, $mismatch.path)
        Write-Host ("  Recorded summary: {0}" -f $mismatch.recorded_summary_path)
        Write-Host ("  Refresh: {0}" -f $mismatch.repair_command)
    }
}
if ($bundle.stale_summary_artifact_detected) {
    Write-Host ''
    Write-Host 'Stale summary-derived helpers:'
    foreach ($detail in $bundle.stale_summary_artifact_details) {
        Write-Host ("- {0}: {1}" -f $detail.label, $detail.path)
        Write-Host ("  Expected summary timestamp: {0}" -f $detail.expected_summary_generated_at_utc)
        Write-Host ("  Recorded summary timestamp: {0}" -f $detail.recorded_summary_generated_at_utc)
        Write-Host ("  Refresh: {0}" -f $detail.repair_command)
    }
}
if (-not $bundle.summary_records_refresh_artifact_path) {
    Write-Host ''
    Write-Host 'Summary refresh-pointer gap:'
    Write-Host ("- The current summary did not record a refresh artifact path, so this audit is using the fallback refresh location: {0}" -f $bundle.refresh_artifact_path)
    Write-Host ("- Open the refresh JSON directly or rerun the chain refresh helper before trusting older cached cross-links: {0}" -f $bundle.refresh_chain_command)
}
if (-not $bundle.summary_records_handoff_artifact_path) {
    Write-Host ''
    Write-Host 'Summary handoff-pointer gap:'
    Write-Host ("- The current summary did not record a handoff artifact path, so this audit is using the fallback handoff location: {0}" -f $bundle.handoff_artifact_path)
    Write-Host ("- Open the handoff JSON directly or refresh the helper chain before trusting older cached cross-links: {0}" -f $bundle.refresh_chain_command)
}
if ($bundle.first_missing_path) {
    Write-Host ''
    Write-Host ("First missing path: {0}" -f $bundle.first_missing_path)
}
Write-Host ''
Write-Host ("Open:  {0}" -f $bundle.next_artifact_to_open)
if ($bundle.boundary_last_passed_phase -or $bundle.boundary_first_failed_phase) {
    Write-Host ("Boundary last pass: {0}" -f $(if ($bundle.boundary_last_passed_phase) { $bundle.boundary_last_passed_phase } else { 'none' }))
    Write-Host ("Boundary first fail: {0}" -f $(if ($bundle.boundary_first_failed_phase) { $bundle.boundary_first_failed_phase } else { 'none' }))
}
if ($bundle.boundary_focus) {
    Write-Host ("Boundary focus: {0}" -f $bundle.boundary_focus)
}
if ($bundle.boundary_reason) {
    Write-Host ("Boundary reason: {0}" -f $bundle.boundary_reason)
}
if ($bundle.recommended_command) {
    Write-Host ("Run:   {0}" -f $bundle.recommended_command)
}
if ($bundle.recommended_guide_command) {
    Write-Host ("Guide: {0}" -f $bundle.recommended_guide_command)
}
if ($bundle.refresh_status_command) {
    Write-Host ("Refresh status: {0}" -f $bundle.refresh_status_command)
}
if ($bundle.handoff_guide_command) {
    Write-Host ("Handoff: {0}" -f $bundle.handoff_guide_command)
}
if ($bundle.summary_guide_command) {
    Write-Host ("Summary guide: {0}" -f $bundle.summary_guide_command)
}
if ($bundle.manifest_guide_command) {
    Write-Host ("Manifest guide: {0}" -f $bundle.manifest_guide_command)
}
if ($bundle.phase_boundary_command) {
    Write-Host ("Phase boundary: {0}" -f $bundle.phase_boundary_command)
}
if ($bundle.recommended_runner_command) {
    Write-Host ("Broader runner: {0}" -f $bundle.recommended_runner_command)
}
if ($bundle.refresh_chain_command) {
    Write-Host ("Refresh chain: {0}" -f $bundle.refresh_chain_command)
}
if (($bundle.stale_cross_reference_detected -and $bundle.stale_cross_reference_repair_commands.Count -gt 0) -or ($bundle.stale_summary_artifact_detected -and $bundle.stale_summary_artifact_repair_commands.Count -gt 0)) {
    $repairCommands = @($bundle.stale_cross_reference_repair_commands + $bundle.stale_summary_artifact_repair_commands | Select-Object -Unique)
    Write-Host 'Refresh order:'
    foreach ($repairCommand in $repairCommands) {
        Write-Host ("- {0}" -f $repairCommand)
    }
}
Write-Host ("Focus: {0}" -f $bundle.next_focus)
if ($bundle.manual_fixture_replay_command) {
    Write-Host ("Manual replay: {0}" -f $bundle.manual_fixture_replay_command)
}
if ($bundle.manual_asset_closure_command) {
    Write-Host ("Asset check: {0}" -f $bundle.manual_asset_closure_command)
}
if ($bundle.manual_attached_html_flow_command) {
    Write-Host ("Manual flow: {0}" -f $bundle.manual_attached_html_flow_command)
}
if ($bundle.manual_attached_html_runner_command) {
    Write-Host ("Manual runner: {0}" -f $bundle.manual_attached_html_runner_command)
}
if ($bundle.manual_saved_page_flow_command) {
    Write-Host ("Saved-page flow: {0}" -f $bundle.manual_saved_page_flow_command)
}

if ($status -ne 'complete') {
    exit 1
}
