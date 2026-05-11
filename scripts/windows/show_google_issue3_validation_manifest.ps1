[CmdletBinding()]
param(
    [string]$ManifestPath,
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

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $ManifestPath) {
    $ManifestPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-manifest.json"
}
if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "Issue #3 validation manifest not found: $ManifestPath"
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$phaseResults = @($manifest.phase_results)
$failedPhase = @($phaseResults | Where-Object { $_.name -eq $manifest.first_failed_phase } | Select-Object -First 1)
$boundaryRecord = $null
$boundaryArtifactError = $null
if (-not [string]::IsNullOrWhiteSpace($manifest.boundary_artifact_path) -and (Test-Path -LiteralPath $manifest.boundary_artifact_path -PathType Leaf)) {
    try {
        $boundaryRecord = Get-Content -LiteralPath $manifest.boundary_artifact_path -Raw | ConvertFrom-Json
    } catch {
        $boundaryArtifactError = $_.Exception.Message
    }
} elseif (-not [string]::IsNullOrWhiteSpace($manifest.boundary_artifact_path)) {
    $boundaryArtifactError = "Boundary artifact not found: $($manifest.boundary_artifact_path)"
}

$openNext = if ($boundaryRecord -and $boundaryRecord.next_artifact_to_open) {
    $boundaryRecord.next_artifact_to_open
} elseif ($manifest.first_failed_phase_primary_json_artifact_path) {
    $manifest.first_failed_phase_primary_json_artifact_path
} elseif ($manifest.boundary_artifact_path) {
    $manifest.boundary_artifact_path
} elseif ($manifest.guide_artifact_path) {
    $manifest.guide_artifact_path
} else {
    $manifest.summary_path
}

$report = [ordered]@{
    issue = "Google issue #3 validation manifest guide"
    purpose = "Open the saved manifest first, summarize the current boundary, and point the next Windows headed replay at the earliest failing checkpoint."
    manifest_path = $ManifestPath
    generated_at_utc = $manifest.generated_at_utc
    completed = [bool]$manifest.completed
    surface_check_status = $manifest.surface_check_status
    surface_check_error = $manifest.surface_check_error
    surface_check_artifact_path = $manifest.surface_check_artifact_path
    surface_check_missing_count = $manifest.surface_check_missing_count
    surface_check_missing_paths = @($manifest.surface_check_missing_paths)
    summary_path = $manifest.summary_path
    guide_artifact_path = $manifest.guide_artifact_path
    boundary_artifact_path = $manifest.boundary_artifact_path
    boundary_artifact_error = $boundaryArtifactError
    phase_artifact_root = $manifest.phase_artifact_root
    first_failed_phase = $manifest.first_failed_phase
    first_failed_phase_log_path = $manifest.first_failed_phase_log_path
    first_failed_phase_primary_json_artifact_path = $manifest.first_failed_phase_primary_json_artifact_path
    first_failed_phase_artifact_paths = if ($failedPhase.Count -gt 0) { @($failedPhase[0].artifact_paths) } else { @() }
    boundary_last_passed_phase = if ($boundaryRecord) { $boundaryRecord.last_passed_phase } else { $null }
    boundary_first_failed_phase = if ($boundaryRecord) { $boundaryRecord.first_failed_phase } else { $null }
    boundary_next_artifact_to_open = if ($boundaryRecord) { $boundaryRecord.next_artifact_to_open } else { $null }
    next_artifact_to_open = $openNext
    next_focus = $manifest.next_focus
    recommended_command = $manifest.recommended_command
    recommended_guide_command = $manifest.recommended_guide_command
    manual_fixture_replay_command = $manifest.manual_fixture_replay_command
    manual_fixture_replay_available = [bool]$manifest.manual_fixture_replay_available
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Google issue #3 validation manifest guide"
Write-Host ""
Write-Host ("Manifest:  {0}" -f $report.manifest_path)
Write-Host ("Generated: {0}" -f $report.generated_at_utc)
Write-Host ("Completed: {0}" -f $report.completed)
Write-Host ("Surface:   {0}" -f $report.surface_check_status)
if ($report.surface_check_error) {
    Write-Host ("Surface error: {0}" -f $report.surface_check_error)
}
if ($report.surface_check_artifact_path) {
    Write-Host ("Surface JSON: {0}" -f $report.surface_check_artifact_path)
}
if ($report.surface_check_missing_count -gt 0) {
    Write-Host ("Surface missing: {0}" -f $report.surface_check_missing_count)
    foreach ($missingPath in $report.surface_check_missing_paths) {
        Write-Host ("- {0}" -f $missingPath)
    }
}
if ($report.summary_path) {
    Write-Host ("Summary JSON: {0}" -f $report.summary_path)
}
if ($report.guide_artifact_path) {
    Write-Host ("Guide JSON: {0}" -f $report.guide_artifact_path)
}
if ($report.boundary_artifact_path) {
    Write-Host ("Boundary JSON: {0}" -f $report.boundary_artifact_path)
}
if ($report.boundary_artifact_error) {
    Write-Host ("Boundary error: {0}" -f $report.boundary_artifact_error)
}
if ($report.phase_artifact_root) {
    Write-Host ("Phase root: {0}" -f $report.phase_artifact_root)
}
Write-Host ("First fail: {0}" -f $(if ($report.first_failed_phase) { $report.first_failed_phase } else { "none" }))
if ($report.first_failed_phase_log_path) {
    Write-Host ("Log:        {0}" -f $report.first_failed_phase_log_path)
}
if ($report.first_failed_phase_primary_json_artifact_path) {
    Write-Host ("JSON:       {0}" -f $report.first_failed_phase_primary_json_artifact_path)
}
if ($report.first_failed_phase_artifact_paths.Count -gt 0) {
    Write-Host "Artifacts:"
    foreach ($artifactPath in $report.first_failed_phase_artifact_paths) {
        Write-Host ("- {0}" -f $artifactPath)
    }
}
if ($report.boundary_last_passed_phase -or $report.boundary_first_failed_phase) {
    Write-Host ("Boundary last pass: {0}" -f $(if ($report.boundary_last_passed_phase) { $report.boundary_last_passed_phase } else { "none" }))
    Write-Host ("Boundary first fail: {0}" -f $(if ($report.boundary_first_failed_phase) { $report.boundary_first_failed_phase } else { "none" }))
}
Write-Host ""
Write-Host ("Open next: {0}" -f $report.next_artifact_to_open)
Write-Host ("Focus:     {0}" -f $report.next_focus)
if ($report.recommended_command) {
    Write-Host ("Run next:  {0}" -f $report.recommended_command)
}
if ($report.recommended_guide_command) {
    Write-Host ("Guide:     {0}" -f $report.recommended_guide_command)
}
if ($report.manual_fixture_replay_available -and $report.manual_fixture_replay_command) {
    Write-Host ("Manual replay: {0}" -f $report.manual_fixture_replay_command)
}
