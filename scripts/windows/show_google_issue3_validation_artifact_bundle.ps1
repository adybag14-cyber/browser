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
$phaseRoot = if (-not [string]::IsNullOrWhiteSpace($summary.phase_artifact_root)) {
    $summary.phase_artifact_root
} else {
    Join-Path $artifactRoot "google-issue3-recommended-validation-phases"
}

$summaryRef = New-ArtifactReference -Label "summary" -Path $SummaryPath
$surfaceRef = New-ArtifactReference -Label "surface" -Path $surfacePath
$guideRef = New-ArtifactReference -Label "guide" -Path $guidePath
$manifestRef = New-ArtifactReference -Label "manifest" -Path $manifestPath
$boundaryRef = New-ArtifactReference -Label "boundary" -Path $boundaryPath
$coreRefs = @($summaryRef, $surfaceRef, $guideRef, $manifestRef, $boundaryRef)
$coreMissing = @($coreRefs | Where-Object { -not $_.exists })

$guideRecord = Read-ArtifactJson $guidePath
$boundaryRecord = Read-ArtifactJson $boundaryPath
$manifestRecord = Read-ArtifactJson $manifestPath

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
$nextArtifactToOpen = $null
if ($boundaryRecord -and $boundaryRecord.next_artifact_to_open) {
    $nextArtifactToOpen = $boundaryRecord.next_artifact_to_open
} elseif ($guideRecord -and $guideRecord.first_failed_phase_primary_json_artifact_path) {
    $nextArtifactToOpen = $guideRecord.first_failed_phase_primary_json_artifact_path
} elseif ($boundaryRef.exists) {
    $nextArtifactToOpen = $boundaryPath
} elseif ($guideRef.exists) {
    $nextArtifactToOpen = $guidePath
} elseif ($manifestRef.exists) {
    $nextArtifactToOpen = $manifestPath
} elseif ($surfaceRef.exists) {
    $nextArtifactToOpen = $surfacePath
} else {
    $nextArtifactToOpen = $SummaryPath
}

$recommendedCommand = if ($boundaryRecord -and $boundaryRecord.recommended_command) {
    $boundaryRecord.recommended_command
} elseif ($guideRecord -and $guideRecord.recommended_command) {
    $guideRecord.recommended_command
} else {
    $null
}
$recommendedGuideCommand = if ($boundaryRecord -and $boundaryRecord.recommended_guide_command) {
    $boundaryRecord.recommended_guide_command
} elseif ($guideRecord -and $guideRecord.recommended_guide_command) {
    $guideRecord.recommended_guide_command
} else {
    $null
}
$nextFocus = if ($boundaryRecord -and $boundaryRecord.next_focus) {
    $boundaryRecord.next_focus
} elseif ($guideRecord -and $guideRecord.next_focus) {
    $guideRecord.next_focus
} else {
    "Open the first failing phase artifact before widening back out to the full issue #3 replay."
}

$status = if ($coreMissing.Count -eq 0 -and $totalPhaseMissingCount -eq 0) {
    "complete"
} elseif (-not $summaryRef.exists) {
    "missing-summary"
} elseif ($coreMissing.Count -gt 0) {
    "missing-core-artifacts"
} else {
    "missing-phase-artifacts"
}

$bundle = [ordered]@{
    issue = "Google issue #3 validation artifact bundle"
    purpose = "Check whether the saved recommended-validation artifact family is complete and point the next Windows headed replay at the best artifact to open first."
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    summary_generated_at_utc = $summary.generated_at_utc
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
    core_missing_labels = @($coreMissing | ForEach-Object { $_.label })
    core_missing_paths = @($coreArtifactMissingPaths)
    phase_log_missing_count = $phaseLogMissingCount
    phase_json_missing_count = $phaseJsonMissingCount
    phase_missing_artifact_count = $totalPhaseMissingCount
    next_artifact_to_open = $nextArtifactToOpen
    boundary_last_passed_phase = if ($boundaryRecord) { $boundaryRecord.last_passed_phase } else { $null }
    boundary_first_failed_phase = if ($boundaryRecord) { $boundaryRecord.first_failed_phase } else { $null }
    boundary_focus = if ($boundaryRecord) { $boundaryRecord.boundary_focus } else { $null }
    boundary_reason = if ($boundaryRecord) { $boundaryRecord.reason } else { $null }
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    recommended_runner_command = if ($guideRecord -and $guideRecord.broader_runner_command) {
        $guideRecord.broader_runner_command
    } else {
        $recommendedCommand
    }
    phase_boundary_command = if ($guideRecord) { $guideRecord.phase_boundary_command } else { $null }
    next_focus = $nextFocus
    first_missing_path = if ($coreArtifactMissingPaths.Count -gt 0) {
        $coreArtifactMissingPaths[0]
    } elseif ($firstFailedPhaseHealth.Count -gt 0 -and $firstFailedPhaseHealth[0].missing_count -gt 0) {
        $firstFailedPhaseHealth[0].missing_paths[0]
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
    phase_statuses = $phaseStatuses
}

$bundle | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $bundle | ConvertTo-Json -Depth 8
    if ($status -ne "complete") {
        exit 1
    }
    exit 0
}

Write-Host "Google issue #3 validation artifact bundle"
Write-Host ""
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
if ($bundle.guide_artifact_error) {
    Write-Host ("Guide error: {0}" -f $bundle.guide_artifact_error)
}
if ($bundle.boundary_artifact_error) {
    Write-Host ("Boundary error: {0}" -f $bundle.boundary_artifact_error)
}
Write-Host ""
foreach ($reference in $coreRefs) {
    $marker = if ($reference.exists) { "OK" } else { "MISSING" }
    Write-Host ("[{0}] {1}: {2}" -f $marker, $reference.label, $reference.path)
}
if ($bundle.first_missing_path) {
    Write-Host ""
    Write-Host ("First missing path: {0}" -f $bundle.first_missing_path)
}
Write-Host ""
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
if ($bundle.phase_boundary_command) {
    Write-Host ("Phase boundary: {0}" -f $bundle.phase_boundary_command)
}
if ($bundle.recommended_runner_command) {
    Write-Host ("Broader runner: {0}" -f $bundle.recommended_runner_command)
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

if ($status -ne "complete") {
    exit 1
}
