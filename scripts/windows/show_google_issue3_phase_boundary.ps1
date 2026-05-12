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

function Get-PhaseReplayCommand([string]$PhaseName) {
    if ([string]::IsNullOrWhiteSpace($PhaseName)) {
        return $null
    }

    switch ($PhaseName) {
        'localhost' {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase localhost'
        }
        'quick' {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase quick'
        }
        'home' {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase home'
        }
        'homepage-fixture' {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1'
        }
        'input-phase-localhost' {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase input-phase-localhost'
        }
        'submit-timing' {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase submit-timing'
        }
        'shared-enter-order' {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_input_validation.ps1 -Phase shared-enter-order'
        }
        'manual' {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_manual_fixture_replay.ps1'
        }
        default {
            return 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
        }
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
$configuredBoundaryPath = if ($summary.PSObject.Properties['boundary_artifact_path'] -and -not [string]::IsNullOrWhiteSpace($summary.boundary_artifact_path)) {
    $summary.boundary_artifact_path
} else {
    $null
}
$resolvedBoundaryArtifactPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredBoundaryPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-phase-boundary.json'
if (-not $ArtifactPath) {
    $ArtifactPath = $resolvedBoundaryArtifactPath
}

$phaseResults = @($summary.phase_results)
$passedPhases = @($phaseResults | Where-Object { $_.status -eq 'passed' })
$failedPhases = @($phaseResults | Where-Object { $_.status -ne 'passed' })
$lastPassed = if ($passedPhases.Count -gt 0) { $passedPhases[-1] } else { $null }
$firstFailed = if ($failedPhases.Count -gt 0) { $failedPhases[0] } else { $null }
$lastPassedReplayCommand = if ($lastPassed) { Get-PhaseReplayCommand $lastPassed.name } else { $null }
$firstFailedReplayCommand = if ($firstFailed) { Get-PhaseReplayCommand $firstFailed.name } else { $null }

$guideRecord = $null
$guideArtifactError = $null
$guideArtifactPath = $summary.guide_artifact_path
if (-not [string]::IsNullOrWhiteSpace($guideArtifactPath) -and (Test-Path -LiteralPath $guideArtifactPath -PathType Leaf)) {
    try {
        $guideRecord = Read-ArtifactJson $guideArtifactPath
    } catch {
        $guideArtifactError = $_.Exception.Message
    }
} elseif (-not [string]::IsNullOrWhiteSpace($guideArtifactPath)) {
    $guideArtifactError = "Guide artifact not found: $guideArtifactPath"
}

$artifactBundleCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1'
$artifactBundlePath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.artifact_bundle_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json'
$artifactBundleExists = Test-Path -LiteralPath $artifactBundlePath -PathType Leaf
$artifactBundleRecord = $null
$artifactBundleError = if ($summary.artifact_bundle_error) { $summary.artifact_bundle_error } else { $null }
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
    'helper-error'
} elseif ($artifactBundleExists) {
    'present-unreadable'
} else {
    'missing'
}
$artifactBundleNeedsRepair = $artifactBundleStatus -ne 'complete'
$artifactBundleRecommendedCommand = if ($artifactBundleRecord -and $artifactBundleRecord.recommended_command) {
    $artifactBundleRecord.recommended_command
} elseif ($guideRecord) {
    $guideRecord.recommended_command
} else {
    $null
}
$artifactBundleGuideCommand = if ($artifactBundleRecord -and $artifactBundleRecord.recommended_guide_command) {
    $artifactBundleRecord.recommended_guide_command
} elseif ($guideRecord) {
    $guideRecord.recommended_guide_command
} else {
    $null
}
$artifactBundleReason = if ($artifactBundleError) {
    'The saved artifact bundle could not be parsed cleanly, so reopen the current summary before trusting older boundary or guide output.'
} elseif ($artifactBundleStatus -eq 'missing') {
    'The bundle audit is missing for this summary, so reopen the current summary and refresh the helper chain before trusting the saved boundary handoff.'
} elseif ($artifactBundleStatus -ne 'complete') {
    "The saved artifact bundle reports '$artifactBundleStatus', so direct boundary users should return to the current summary until the handoff set is refreshed."
} else {
    'The saved artifact bundle agrees the current handoff set is complete, so the boundary artifact is safe to use as the next narrowing step.'
}

$boundaryFocus = if ($artifactBundleNeedsRepair) {
    'Refresh the saved artifact-bundle handoff so the manifest, guide, boundary, and per-phase artifacts all point at the current summary before widening back out.'
} elseif ($firstFailed) {
    'Compare the last passing phase artifact with the first failing phase artifact before widening back out to a broader issue #3 replay.'
} elseif ($lastPassed) {
    'Every recorded phase passed, so the next replay can widen to attached HTML or live Google evidence gathering.'
} else {
    'No passing phase was recorded yet, so start at the earliest recommended phase and repair the first checkpoint before widening out.'
}

$boundary = [ordered]@{
    issue = 'Google issue #3 phase boundary'
    purpose = 'Persist the boundary between the last passing checkpoint and the first failing checkpoint from the saved recommended-validation summary, but route direct boundary users back to the current summary when the saved artifact-bundle audit says the helper chain is incomplete or stale.'
    summary_path = $SummaryPath
    boundary_artifact_path = $ArtifactPath
    generated_at_utc = $summary.generated_at_utc
    completed = [bool]$summary.completed
    phase_count = @($phaseResults).Count
    passed_phase_count = @($passedPhases).Count
    failed_phase_count = @($failedPhases).Count
    phase_artifact_root = $summary.phase_artifact_root
    manifest_artifact_path = $summary.manifest_artifact_path
    guide_artifact_path = $guideArtifactPath
    guide_artifact_error = $guideArtifactError
    artifact_bundle_path = $artifactBundlePath
    artifact_bundle_exists = [bool]$artifactBundleExists
    artifact_bundle_status = $artifactBundleStatus
    artifact_bundle_error = $artifactBundleError
    artifact_bundle_reason = $artifactBundleReason
    artifact_bundle_next_artifact_to_open = if ($artifactBundleRecord) { $artifactBundleRecord.next_artifact_to_open } else { $null }
    artifact_bundle_recommended_command = $artifactBundleRecommendedCommand
    artifact_bundle_recommended_guide_command = $artifactBundleGuideCommand
    artifact_bundle_first_missing_path = if ($artifactBundleRecord) { $artifactBundleRecord.first_missing_path } else { $null }
    last_passed_phase = if ($lastPassed) { $lastPassed.name } else { $null }
    last_passed_phase_log_path = if ($lastPassed) { $lastPassed.log_path } else { $null }
    last_passed_phase_primary_json_artifact_path = if ($lastPassed) { $lastPassed.primary_json_artifact_path } else { $null }
    last_passed_phase_artifact_paths = if ($lastPassed) { @($lastPassed.artifact_paths) } else { @() }
    last_passed_phase_replay_command = $lastPassedReplayCommand
    first_failed_phase = if ($firstFailed) { $firstFailed.name } else { $null }
    first_failed_phase_error = if ($firstFailed) { $firstFailed.error } else { $null }
    first_failed_phase_log_path = if ($firstFailed) { $firstFailed.log_path } else { $null }
    first_failed_phase_primary_json_artifact_path = if ($firstFailed) { $firstFailed.primary_json_artifact_path } else { $null }
    first_failed_phase_artifact_paths = if ($firstFailed) { @($firstFailed.artifact_paths) } else { @() }
    first_failed_phase_replay_command = $firstFailedReplayCommand
    boundary_focus = $boundaryFocus
    next_focus = if ($artifactBundleNeedsRepair) {
        if ($artifactBundleRecord -and $artifactBundleRecord.next_focus) {
            $artifactBundleRecord.next_focus
        } else {
            $boundaryFocus
        }
    } elseif ($guideRecord -and $guideRecord.next_focus) {
        $guideRecord.next_focus
    } else {
        $boundaryFocus
    }
    recommended_command = if ($artifactBundleNeedsRepair) {
        $artifactBundleRecommendedCommand
    } elseif ($guideRecord) {
        $guideRecord.recommended_command
    } else {
        $null
    }
    recommended_guide_command = if ($artifactBundleNeedsRepair) {
        $artifactBundleGuideCommand
    } elseif ($guideRecord) {
        $guideRecord.recommended_guide_command
    } else {
        $null
    }
    manual_fixture_replay_command = if ($guideRecord) { $guideRecord.manual_fixture_replay_command } else { $null }
    reason = if ($artifactBundleNeedsRepair) {
        $artifactBundleReason
    } elseif ($guideRecord) {
        $guideRecord.reason
    } else {
        $null
    }
    next_artifact_to_open = if ($artifactBundleNeedsRepair) {
        $SummaryPath
    } elseif ($firstFailed -and $firstFailed.primary_json_artifact_path) {
        $firstFailed.primary_json_artifact_path
    } elseif ($lastPassed -and $lastPassed.primary_json_artifact_path) {
        $lastPassed.primary_json_artifact_path
    } elseif ($guideArtifactPath) {
        $guideArtifactPath
    } else {
        $SummaryPath
    }
}

$boundary | ConvertTo-Json -Depth 6 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $boundary | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 phase boundary'
Write-Host ''
Write-Host ("Summary:   {0}" -f $boundary.summary_path)
Write-Host ("Boundary:  {0}" -f $boundary.boundary_artifact_path)
Write-Host ("Generated: {0}" -f $boundary.generated_at_utc)
Write-Host ("Completed: {0}" -f $boundary.completed)
Write-Host ("Phases:    {0} total / {1} passed / {2} failed" -f $boundary.phase_count, $boundary.passed_phase_count, $boundary.failed_phase_count)
if ($boundary.phase_artifact_root) {
    Write-Host ("Phase root: {0}" -f $boundary.phase_artifact_root)
}
if ($boundary.manifest_artifact_path) {
    Write-Host ("Manifest:  {0}" -f $boundary.manifest_artifact_path)
}
if ($boundary.guide_artifact_path) {
    Write-Host ("Guide:     {0}" -f $boundary.guide_artifact_path)
}
if ($boundary.guide_artifact_error) {
    Write-Host ("Guide error: {0}" -f $boundary.guide_artifact_error)
}
Write-Host ("Bundle cmd: {0}" -f $artifactBundleCommand)
Write-Host ("Bundle:    {0}" -f $boundary.artifact_bundle_path)
Write-Host ("Bundle exists: {0}" -f $boundary.artifact_bundle_exists)
Write-Host ("Bundle status: {0}" -f $boundary.artifact_bundle_status)
if ($boundary.artifact_bundle_error) {
    Write-Host ("Bundle error: {0}" -f $boundary.artifact_bundle_error)
}
if ($boundary.artifact_bundle_next_artifact_to_open) {
    Write-Host ("Bundle open: {0}" -f $boundary.artifact_bundle_next_artifact_to_open)
}
if ($boundary.artifact_bundle_first_missing_path) {
    Write-Host ("Bundle first missing: {0}" -f $boundary.artifact_bundle_first_missing_path)
}
Write-Host ''
Write-Host ("Last pass: {0}" -f $(if ($boundary.last_passed_phase) { $boundary.last_passed_phase } else { 'none' }))
if ($boundary.last_passed_phase_log_path) {
    Write-Host ("  Log:  {0}" -f $boundary.last_passed_phase_log_path)
}
if ($boundary.last_passed_phase_primary_json_artifact_path) {
    Write-Host ("  JSON: {0}" -f $boundary.last_passed_phase_primary_json_artifact_path)
}
if ($boundary.last_passed_phase_replay_command) {
    Write-Host ("  Replay: {0}" -f $boundary.last_passed_phase_replay_command)
}
Write-Host ("First fail: {0}" -f $(if ($boundary.first_failed_phase) { $boundary.first_failed_phase } else { 'none' }))
if ($boundary.first_failed_phase_log_path) {
    Write-Host ("  Log:  {0}" -f $boundary.first_failed_phase_log_path)
}
if ($boundary.first_failed_phase_primary_json_artifact_path) {
    Write-Host ("  JSON: {0}" -f $boundary.first_failed_phase_primary_json_artifact_path)
}
if ($boundary.first_failed_phase_replay_command) {
    Write-Host ("  Replay: {0}" -f $boundary.first_failed_phase_replay_command)
}
if ($boundary.first_failed_phase_error) {
    Write-Host ("  Error: {0}" -f $boundary.first_failed_phase_error)
}
Write-Host ''
if ($boundary.reason) {
    Write-Host ("Reason: {0}" -f $boundary.reason)
}
Write-Host ("Focus: {0}" -f $boundary.next_focus)
Write-Host ("Open:  {0}" -f $boundary.next_artifact_to_open)
if ($boundary.recommended_command) {
    Write-Host ("Run:   {0}" -f $boundary.recommended_command)
}
if ($boundary.recommended_guide_command) {
    Write-Host ("Guide: {0}" -f $boundary.recommended_guide_command)
}
if ($boundary.manual_fixture_replay_command) {
    Write-Host ("Manual replay: {0}" -f $boundary.manual_fixture_replay_command)
}
