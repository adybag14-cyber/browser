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
$surfaceCheckFailed = $manifest.surface_check_status -ne "passed"
$surfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_recommended_validation_surface.ps1"
$summaryGuideCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1"
$probeTriageCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_probe_triage.ps1"
$phaseBoundaryCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_phase_boundary.ps1"
$handoffGuideCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1"
$recommendedRunnerCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1"
$artifactBundleCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1"
$artifactRoot = if (-not [string]::IsNullOrWhiteSpace($manifest.artifact_root)) {
    $manifest.artifact_root
} elseif ($manifest.summary_path) {
    Split-Path -Parent $manifest.summary_path
} else {
    Split-Path -Parent $ManifestPath
}
$artifactBundlePath = Resolve-ArtifactCandidatePath -ConfiguredPath $manifest.artifact_bundle_path -ArtifactRoot $artifactRoot -FallbackName "google-issue3-validation-artifact-bundle.json"
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $manifest.handoff_artifact_path -ArtifactRoot $artifactRoot -FallbackName "google-issue3-validation-handoff.json"
$artifactBundleExists = Test-Path -LiteralPath $artifactBundlePath -PathType Leaf
$artifactBundleRecord = $null
$artifactBundleError = if ($manifest.artifact_bundle_error) { $manifest.artifact_bundle_error } else { $null }
if ($artifactBundleExists) {
    try {
        $artifactBundleRecord = Read-ArtifactJson $artifactBundlePath
    } catch {
        $artifactBundleError = $_.Exception.Message
    }
}
$artifactBundleStatus = if ($artifactBundleRecord -and $artifactBundleRecord.status) {
    $artifactBundleRecord.status
} elseif ($artifactBundleError) {
    "helper-error"
} elseif ($artifactBundleExists) {
    "present-unreadable"
} else {
    "missing"
}
$artifactBundleNeedsRepair = $artifactBundleStatus -ne "complete"
$artifactBundleRecommendedCommand = if ($artifactBundleRecord -and $artifactBundleRecord.recommended_command) {
    $artifactBundleRecord.recommended_command
} else {
    $recommendedRunnerCommand
}
$artifactBundleGuideCommand = if ($artifactBundleRecord -and $artifactBundleRecord.recommended_guide_command) {
    $artifactBundleRecord.recommended_guide_command
} else {
    $summaryGuideCommand
}
$artifactBundleReason = if ($artifactBundleError) {
    "The runner recorded an artifact-bundle generation error, so reopen the current summary before trusting the saved helper chain."
} elseif ($artifactBundleStatus -eq "missing") {
    "The recommended runner should auto-save the artifact bundle, so reopen the current summary and refresh the handoff files before following older helper output."
} elseif ($artifactBundleStatus -ne "complete") {
    "The auto-saved artifact bundle reports '$artifactBundleStatus', so trust the current summary first and refresh the helper named under Run before following older handoff files."
} else {
    "The auto-saved artifact bundle is the saved completeness audit across the summary, manifest, guide, boundary, and per-phase artifacts."
}
$handoffExists = Test-Path -LiteralPath $handoffPath -PathType Leaf
$handoffRecord = $null
$handoffArtifactError = if ($manifest.handoff_artifact_error) { $manifest.handoff_artifact_error } else { $null }
if ($handoffExists) {
    try {
        $handoffRecord = Read-ArtifactJson $handoffPath
    } catch {
        $handoffArtifactError = $_.Exception.Message
    }
} elseif (-not $handoffArtifactError) {
    $handoffArtifactError = "Handoff artifact not found: $handoffPath"
}
$handoffReady = $handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffRecord.next_artifact_to_open)
$handoffReason = if ($handoffArtifactError) {
    "The saved handoff artifact could not be read, so fall back to the manifest and boundary outputs until the handoff helper is refreshed."
} elseif ($handoffReady) {
    "The saved handoff artifact already points at the current next artifact, so prefer its narrower replay guidance before widening back out."
} else {
    "The handoff helper has not produced a reusable next-artifact pointer yet, so keep using the manifest and boundary outputs for this replay."
}
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

$openNextReason = $null
$openNext = if ($surfaceCheckFailed -and $manifest.surface_check_artifact_path) {
    $openNextReason = "surface-check-failed"
    $manifest.surface_check_artifact_path
} elseif ($artifactBundleNeedsRepair -and $manifest.summary_path) {
    $openNextReason = "artifact-bundle-needs-repair"
    $manifest.summary_path
} elseif ($handoffReady) {
    $openNextReason = "handoff-artifact"
    $handoffRecord.next_artifact_to_open
} elseif ($boundaryRecord -and $boundaryRecord.next_artifact_to_open) {
    $openNextReason = "phase-boundary-artifact"
    $boundaryRecord.next_artifact_to_open
} elseif ($manifest.first_failed_phase_primary_json_artifact_path) {
    $openNextReason = "first-failed-phase-artifact"
    $manifest.first_failed_phase_primary_json_artifact_path
} elseif ($handoffExists) {
    $openNextReason = "handoff-fallback"
    $handoffPath
} elseif ($manifest.boundary_artifact_path) {
    $openNextReason = "phase-boundary-fallback"
    $manifest.boundary_artifact_path
} elseif ($manifest.guide_artifact_path) {
    $openNextReason = "summary-guide-fallback"
    $manifest.guide_artifact_path
} else {
    $openNextReason = "summary-fallback"
    $manifest.summary_path
}

$nextFocus = if ($surfaceCheckFailed) {
    "Resolve the recommended-validation surface mismatch before replaying later issue #3 phases."
} elseif ($artifactBundleNeedsRepair) {
    if ($artifactBundleRecord -and $artifactBundleRecord.next_focus) {
        $artifactBundleRecord.next_focus
    } else {
        "Refresh the saved artifact-bundle handoff so the manifest, guide, boundary, and per-phase artifacts all point at the current summary before widening back out."
    }
} elseif ($handoffReady -and $handoffRecord.next_focus) {
    $handoffRecord.next_focus
} else {
    $manifest.next_focus
}

$recommendedCommand = if ($surfaceCheckFailed) {
    $surfaceCheckCommand
} elseif ($artifactBundleNeedsRepair) {
    $artifactBundleRecommendedCommand
} elseif ($handoffReady -and $handoffRecord.recommended_command) {
    $handoffRecord.recommended_command
} else {
    $manifest.recommended_command
}

$recommendedGuideCommand = if ($surfaceCheckFailed) {
    $summaryGuideCommand
} elseif ($artifactBundleNeedsRepair) {
    $artifactBundleGuideCommand
} elseif ($handoffReady -and $handoffRecord.recommended_guide_command) {
    $handoffRecord.recommended_guide_command
} else {
    $manifest.recommended_guide_command
}

$report = [ordered]@{
    issue = "Google issue #3 validation manifest guide"
    purpose = "Open the saved manifest first, prefer the newer handoff artifact when it is available, and fall back to boundary or summary guidance only when the handoff chain still needs repair."
    manifest_path = $ManifestPath
    generated_at_utc = $manifest.generated_at_utc
    completed = [bool]$manifest.completed
    surface_check_status = $manifest.surface_check_status
    surface_check_error = $manifest.surface_check_error
    surface_check_command = $surfaceCheckCommand
    summary_guide_command = $summaryGuideCommand
    probe_triage_command = $probeTriageCommand
    phase_boundary_command = $phaseBoundaryCommand
    handoff_guide_command = $handoffGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    surface_check_artifact_path = $manifest.surface_check_artifact_path
    surface_check_missing_count = $manifest.surface_check_missing_count
    surface_check_missing_paths = @($manifest.surface_check_missing_paths)
    summary_path = $manifest.summary_path
    guide_artifact_path = $manifest.guide_artifact_path
    boundary_artifact_path = $manifest.boundary_artifact_path
    handoff_artifact_path = $handoffPath
    handoff_artifact_exists = [bool]$handoffExists
    handoff_artifact_error = $handoffArtifactError
    handoff_reason = $handoffReason
    handoff_next_artifact_to_open = if ($handoffRecord) { $handoffRecord.next_artifact_to_open } else { $null }
    handoff_next_focus = if ($handoffRecord) { $handoffRecord.next_focus } else { $null }
    handoff_recommended_command = if ($handoffRecord) { $handoffRecord.recommended_command } else { $null }
    handoff_recommended_guide_command = if ($handoffRecord) { $handoffRecord.recommended_guide_command } else { $null }
    artifact_bundle_command = $artifactBundleCommand
    artifact_bundle_path = $artifactBundlePath
    artifact_bundle_exists = [bool]$artifactBundleExists
    artifact_bundle_status = $artifactBundleStatus
    artifact_bundle_error = $artifactBundleError
    artifact_bundle_reason = $artifactBundleReason
    artifact_bundle_next_artifact_to_open = if ($artifactBundleRecord) { $artifactBundleRecord.next_artifact_to_open } else { $null }
    artifact_bundle_recommended_command = $artifactBundleRecommendedCommand
    artifact_bundle_recommended_guide_command = $artifactBundleGuideCommand
    artifact_bundle_first_missing_path = if ($artifactBundleRecord) { $artifactBundleRecord.first_missing_path } else { $null }
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
    next_artifact_reason = $openNextReason
    next_focus = $nextFocus
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
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
Write-Host ("Summary cmd: {0}" -f $report.summary_guide_command)
Write-Host ("Triage cmd: {0}" -f $report.probe_triage_command)
Write-Host ("Boundary cmd: {0}" -f $report.phase_boundary_command)
Write-Host ("Handoff cmd: {0}" -f $report.handoff_guide_command)
Write-Host ("Broader cmd: {0}" -f $report.broader_runner_command)
Write-Host ("Bundle cmd: {0}" -f $report.artifact_bundle_command)
Write-Host ("Bundle target: {0}" -f $report.artifact_bundle_path)
Write-Host ("Bundle exists: {0}" -f $report.artifact_bundle_exists)
Write-Host ("Bundle status: {0}" -f $report.artifact_bundle_status)
if ($report.artifact_bundle_error) {
    Write-Host ("Bundle error: {0}" -f $report.artifact_bundle_error)
}
if ($report.artifact_bundle_next_artifact_to_open) {
    Write-Host ("Bundle open: {0}" -f $report.artifact_bundle_next_artifact_to_open)
}
if ($report.artifact_bundle_first_missing_path) {
    Write-Host ("Bundle first missing: {0}" -f $report.artifact_bundle_first_missing_path)
}
Write-Host ("Handoff target: {0}" -f $report.handoff_artifact_path)
Write-Host ("Handoff exists: {0}" -f $report.handoff_artifact_exists)
if ($report.handoff_artifact_error) {
    Write-Host ("Handoff error: {0}" -f $report.handoff_artifact_error)
}
if ($report.handoff_next_artifact_to_open) {
    Write-Host ("Handoff open: {0}" -f $report.handoff_next_artifact_to_open)
}
if ($report.handoff_recommended_command) {
    Write-Host ("Handoff run: {0}" -f $report.handoff_recommended_command)
}
if ($report.handoff_recommended_guide_command) {
    Write-Host ("Handoff guide: {0}" -f $report.handoff_recommended_guide_command)
}
if ($report.handoff_next_focus) {
    Write-Host ("Handoff focus: {0}" -f $report.handoff_next_focus)
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
Write-Host ("Reason:    {0}" -f $report.next_artifact_reason)
Write-Host ("Focus:     {0}" -f $report.next_focus)
Write-Host ("Bundle note: {0}" -f $report.artifact_bundle_reason)
Write-Host ("Handoff note: {0}" -f $report.handoff_reason)
if ($report.surface_check_command) {
    Write-Host ("Surface cmd: {0}" -f $report.surface_check_command)
}
if ($report.recommended_command) {
    Write-Host ("Run next:  {0}" -f $report.recommended_command)
}
if ($report.recommended_guide_command) {
    Write-Host ("Guide:     {0}" -f $report.recommended_guide_command)
}
if ($report.manual_fixture_replay_available -and $report.manual_fixture_replay_command) {
    Write-Host ("Manual replay: {0}" -f $report.manual_fixture_replay_command)
}
