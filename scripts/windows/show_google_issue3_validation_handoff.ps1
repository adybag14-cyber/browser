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
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot "google-issue3-validation-handoff.json"
}

$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'
$manifestGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest.ps1'
$boundaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_phase_boundary.ps1'
$bundleGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1'

$guidePath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.guide_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-guide.json'
$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.manifest_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
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

$boundaryPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.boundary_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-phase-boundary.json'
$bundlePath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.artifact_bundle_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json'
$configuredSummaryHandoffPath = $summary.handoff_artifact_path
$configuredManifestHandoffPath = if ($manifestRecord) { $manifestRecord.handoff_artifact_path } else { $null }
$summaryRecordsHandoffArtifactPath = -not [string]::IsNullOrWhiteSpace($configuredSummaryHandoffPath)
$manifestRecordsHandoffArtifactPath = -not [string]::IsNullOrWhiteSpace($configuredManifestHandoffPath)
$configuredHandoffPath = if ($summaryRecordsHandoffArtifactPath) {
    $configuredSummaryHandoffPath
} elseif ($manifestRecordsHandoffArtifactPath) {
    $configuredManifestHandoffPath
} else {
    $null
}
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredHandoffPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
if (-not $ArtifactPath) {
    $ArtifactPath = $handoffPath
}
$configuredSummaryRefreshPath = $summary.refresh_chain_artifact_path
$configuredManifestRefreshPath = if ($manifestRecord) { $manifestRecord.refresh_chain_artifact_path } else { $null }
$summaryRecordsRefreshArtifactPath = -not [string]::IsNullOrWhiteSpace($configuredSummaryRefreshPath)
$manifestRecordsRefreshArtifactPath = -not [string]::IsNullOrWhiteSpace($configuredManifestRefreshPath)
$configuredRefreshPath = if ($summaryRecordsRefreshArtifactPath) {
    $configuredSummaryRefreshPath
} elseif ($manifestRecordsRefreshArtifactPath) {
    $configuredManifestRefreshPath
} else {
    $null
}
$refreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredRefreshPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'

$guideRecord = $null
$guideError = $null
if (Test-Path -LiteralPath $guidePath -PathType Leaf) {
    try {
        $guideRecord = Read-ArtifactJson $guidePath
    } catch {
        $guideError = $_.Exception.Message
    }
} else {
    $guideError = "Guide artifact not found: $guidePath"
}

$boundaryRecord = $null
$boundaryError = $null
if (Test-Path -LiteralPath $boundaryPath -PathType Leaf) {
    try {
        $boundaryRecord = Read-ArtifactJson $boundaryPath
    } catch {
        $boundaryError = $_.Exception.Message
    }
} else {
    $boundaryError = "Boundary artifact not found: $boundaryPath"
}

$bundleRecord = $null
$bundleError = if ($summary.artifact_bundle_error) { $summary.artifact_bundle_error } else { $null }
$bundleExists = Test-Path -LiteralPath $bundlePath -PathType Leaf
if ($bundleExists) {
    try {
        $bundleRecord = Read-ArtifactJson $bundlePath
    } catch {
        $bundleError = $_.Exception.Message
    }
}
$bundleStatus = if ($bundleRecord -and $bundleRecord.status) {
    $bundleRecord.status
} elseif ($bundleError) {
    'helper-error'
} elseif ($bundleExists) {
    'present-unreadable'
} else {
    'missing'
}
$bundleNeedsRepair = $bundleStatus -ne 'complete'
$bundleReason = if ($bundleError) {
    'The saved artifact-bundle audit could not be read cleanly, so reopen the current summary and refresh the helper chain before trusting narrower replay guidance.'
} elseif ($bundleStatus -eq 'missing') {
    'The saved artifact-bundle audit is missing for this summary, so regenerate it before trusting older guide, manifest, or boundary output.'
} elseif ($bundleStatus -ne 'complete') {
    "The saved artifact-bundle audit reports '$bundleStatus', so the current handoff set is incomplete or stale and should be refreshed first."
} else {
    'The saved artifact-bundle audit reports a complete helper chain, so the next replay can trust the narrower guidance from the saved summary artifacts.'
}

$refreshRecord = $null
$refreshError = if ($summary.refresh_chain_artifact_error) {
    $summary.refresh_chain_artifact_error
} elseif ($manifestRecord -and $manifestRecord.refresh_chain_artifact_error) {
    $manifestRecord.refresh_chain_artifact_error
} else {
    $null
}
$refreshExists = Test-Path -LiteralPath $refreshPath -PathType Leaf
if ($refreshExists) {
    try {
        $refreshRecord = Read-ArtifactJson $refreshPath
    } catch {
        $refreshError = $_.Exception.Message
    }
}
$refreshStatus = if ($refreshRecord -and $refreshRecord.status) {
    $refreshRecord.status
} elseif ($refreshError) {
    'helper-error'
} elseif ($refreshExists) {
    'present-unreadable'
} else {
    'missing'
}
$refreshMatchesSummary = $false
if ($refreshRecord -and -not [string]::IsNullOrWhiteSpace($refreshRecord.summary_path)) {
    $refreshMatchesSummary = ([System.IO.Path]::GetFullPath($refreshRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}
$refreshPointerUsesFallback = (-not $summaryRecordsRefreshArtifactPath) -and (-not $manifestRecordsRefreshArtifactPath) -and $refreshExists
$refreshPointerUsesManifest = (-not $summaryRecordsRefreshArtifactPath) -and $manifestRecordsRefreshArtifactPath
$refreshPointerTrusted = [bool]($summaryRecordsRefreshArtifactPath -or $manifestRecordsRefreshArtifactPath -or $refreshMatchesSummary)
$refreshReady = ($refreshStatus -eq 'refreshed') -and $refreshMatchesSummary
$refreshNeeded = -not $refreshReady

$handoffExists = Test-Path -LiteralPath $handoffPath -PathType Leaf
$handoffRecord = $null
$handoffError = if ($summary.handoff_artifact_error) {
    $summary.handoff_artifact_error
} elseif ($manifestRecord -and $manifestRecord.handoff_artifact_error) {
    $manifestRecord.handoff_artifact_error
} else {
    $null
}
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
$handoffPointerUsesFallback = (-not $summaryRecordsHandoffArtifactPath) -and (-not $manifestRecordsHandoffArtifactPath) -and $handoffExists
$handoffPointerUsesManifest = (-not $summaryRecordsHandoffArtifactPath) -and $manifestRecordsHandoffArtifactPath
$handoffPointerTrusted = [bool]($summaryRecordsHandoffArtifactPath -or $manifestRecordsHandoffArtifactPath -or $handoffMatchesSummary)
$handoffReady = [bool]($handoffExists -and $handoffMatchesSummary -and $handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffRecord.next_artifact_to_open))
$handoffNeedsRepair = -not $handoffReady

$phaseResults = @($summary.phase_results)
$failedPhase = @($phaseResults | Where-Object { $_.status -ne 'passed' } | Select-Object -First 1)
$firstFailedPhase = if ($failedPhase.Count -gt 0) { $failedPhase[0].name } else { $summary.first_failed_phase }
$firstFailedReplayCommand = if ($failedPhase.Count -gt 0) {
    Get-PhaseReplayCommand $failedPhase[0].name
} else {
    Get-PhaseReplayCommand $summary.first_failed_phase
}

$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextFocus = $null
$reason = $null
$nextArtifactToOpen = $null

if ($summary.surface_check_status -and $summary.surface_check_status -ne 'passed') {
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $summaryGuideCommand
    $nextFocus = 'Repair the preflight issue #3 validation surface before trusting the later headed replay phases.'
    $reason = 'The saved summary says the recommended validation run failed before the phase ladder could start cleanly.'
    $nextArtifactToOpen = if ($summary.surface_check_artifact_path) { $summary.surface_check_artifact_path } else { $SummaryPath }
} elseif ($manifestError) {
    $recommendedCommand = $refreshChainCommand
    $recommendedGuideCommand = $refreshStatusCommand
    $nextFocus = 'Repair or regenerate the saved issue #3 manifest before trusting manifest-backed refresh or handoff pointers for the next narrow replay.'
    $reason = 'The saved manifest for the current issue #3 summary could not be read cleanly, so this helper cannot safely trust manifest-backed pointer recovery yet.'
    $nextArtifactToOpen = if ($manifestExists) { $manifestPath } else { $SummaryPath }
} elseif ($refreshNeeded) {
    $recommendedCommand = if ($refreshRecord -and $refreshRecord.recommended_command) {
        $refreshRecord.recommended_command
    } else {
        $refreshChainCommand
    }
    $recommendedGuideCommand = $refreshStatusCommand
    $nextFocus = if ($refreshRecord -and $refreshRecord.next_focus) {
        $refreshRecord.next_focus
    } elseif ($refreshError) {
        'Repair or regenerate the saved refresh artifact before trusting the narrower handoff.'
    } elseif ($refreshRecord -and -not $refreshMatchesSummary) {
        'Refresh the helper chain from the current summary because the saved refresh artifact belongs to a different summary.'
    } else {
        'Refresh the saved issue #3 helper chain before trusting the narrower replay guidance.'
    }
    $reason = if ($refreshError) {
        'The saved refresh artifact could not be read cleanly, so rerun the refresh helper before trusting the handoff.'
    } elseif ($refreshRecord -and -not $refreshMatchesSummary) {
        'The saved refresh artifact points at a different summary path, so the current helper chain needs to be regenerated from the current summary first.'
    } elseif ($refreshStatus -eq 'missing') {
        'The saved refresh artifact is missing for this summary, so generate it before trusting narrower handoff guidance.'
    } elseif ($refreshStatus -ne 'refreshed') {
        "The saved refresh artifact reports '$refreshStatus', so the helper chain still needs repair before the handoff can trust narrower replay guidance."
    } else {
        'The saved refresh artifact still needs to be regenerated from the current summary before the narrower handoff can be trusted.'
    }
    $nextArtifactToOpen = if ($refreshExists) { $refreshPath } else { $SummaryPath }
} elseif ($bundleNeedsRepair) {
    $recommendedCommand = if ($bundleRecord -and $bundleRecord.recommended_command) {
        $bundleRecord.recommended_command
    } else {
        $recommendedRunnerCommand
    }
    $recommendedGuideCommand = if ($bundleRecord -and $bundleRecord.recommended_guide_command) {
        $bundleRecord.recommended_guide_command
    } else {
        $bundleGuideCommand
    }
    $nextFocus = if ($bundleRecord -and $bundleRecord.next_focus) {
        $bundleRecord.next_focus
    } else {
        'Refresh the saved artifact-bundle handoff so the manifest, guide, boundary, and per-phase artifacts all point at the current summary before rerunning narrower probes.'
    }
    $reason = $bundleReason
    $nextArtifactToOpen = if ($bundleRecord -and $bundleRecord.next_artifact_to_open) {
        $bundleRecord.next_artifact_to_open
    } else {
        $SummaryPath
    }
} elseif ($refreshPointerUsesManifest) {
    $recommendedCommand = if ($handoffRecord -and $handoffRecord.recommended_command) {
        $handoffRecord.recommended_command
    } elseif ($boundaryRecord -and $boundaryRecord.recommended_command) {
        $boundaryRecord.recommended_command
    } elseif ($guideRecord -and $guideRecord.recommended_command) {
        $guideRecord.recommended_command
    } else {
        $firstFailedReplayCommand
    }
    $recommendedGuideCommand = $handoffGuideCommand
    $nextFocus = 'The current summary omitted its refresh pointer, but the saved manifest still records the matching refresh artifact for this summary, so keep the helper chain on that manifest-backed refresh path while summary cleanup catches up.'
    $reason = 'The current summary omitted refresh_chain_artifact_path, but the saved manifest still records the matching refresh artifact for this summary, so pointer repair is follow-up cleanup instead of a blocker.'
    $nextArtifactToOpen = $refreshPath
} elseif ($handoffPointerUsesManifest) {
    $recommendedCommand = if ($handoffRecord -and $handoffRecord.recommended_command) {
        $handoffRecord.recommended_command
    } elseif ($boundaryRecord -and $boundaryRecord.recommended_command) {
        $boundaryRecord.recommended_command
    } elseif ($guideRecord -and $guideRecord.recommended_command) {
        $guideRecord.recommended_command
    } else {
        $firstFailedReplayCommand
    }
    $recommendedGuideCommand = $handoffGuideCommand
    $nextFocus = 'The current summary omitted its handoff pointer, but the saved manifest still records the matching handoff artifact for this summary, so keep the next replay on that bounded checkpoint while summary cleanup catches up.'
    $reason = 'The current summary omitted handoff_artifact_path, but the saved manifest still records the matching handoff artifact for this summary, so pointer repair is follow-up cleanup instead of a blocker.'
    $nextArtifactToOpen = $ArtifactPath
} elseif ($refreshPointerUsesFallback) {
    $recommendedCommand = $refreshChainCommand
    $recommendedGuideCommand = $refreshStatusCommand
    $nextFocus = 'Neither the summary nor the manifest records the refresh pointer yet, so keep the helper chain aligned on the fallback refresh artifact until pointer repair catches up.'
    $reason = 'Neither the current summary nor the saved manifest records refresh_chain_artifact_path yet, so this helper is using the fallback refresh location while repair catches up.'
    $nextArtifactToOpen = $refreshPath
} elseif ($handoffPointerUsesFallback) {
    $recommendedCommand = if ($handoffRecord -and $handoffRecord.recommended_command) {
        $handoffRecord.recommended_command
    } elseif ($boundaryRecord -and $boundaryRecord.recommended_command) {
        $boundaryRecord.recommended_command
    } elseif ($guideRecord -and $guideRecord.recommended_command) {
        $guideRecord.recommended_command
    } else {
        $firstFailedReplayCommand
    }
    $recommendedGuideCommand = $bundleGuideCommand
    $nextFocus = 'The helper chain is usable, but neither the summary nor the manifest records the handoff pointer yet. Use this saved handoff artifact as the bounded checkpoint while pointer repair catches up.'
    $reason = 'Neither the current summary nor the saved manifest records handoff_artifact_path yet, so this helper is trusting the matching saved handoff artifact at the default location until pointer repair catches up.'
    $nextArtifactToOpen = $ArtifactPath
} elseif ($boundaryRecord -and $boundaryRecord.next_artifact_to_open) {
    $recommendedCommand = if ($boundaryRecord.recommended_command) {
        $boundaryRecord.recommended_command
    } elseif ($guideRecord -and $guideRecord.recommended_command) {
        $guideRecord.recommended_command
    } else {
        $firstFailedReplayCommand
    }
    $recommendedGuideCommand = if ($boundaryRecord.recommended_guide_command) {
        $boundaryRecord.recommended_guide_command
    } elseif ($guideRecord -and $guideRecord.recommended_guide_command) {
        $guideRecord.recommended_guide_command
    } else {
        $boundaryGuideCommand
    }
    $nextFocus = if ($boundaryRecord.next_focus) {
        $boundaryRecord.next_focus
    } elseif ($guideRecord -and $guideRecord.next_focus) {
        $guideRecord.next_focus
    } else {
        'Inspect the last passing and first failing phase artifacts before widening back out.'
    }
    $reason = if ($boundaryRecord.reason) {
        $boundaryRecord.reason
    } elseif ($guideRecord -and $guideRecord.reason) {
        $guideRecord.reason
    } else {
        'The saved boundary artifact already points at the current narrowest failing checkpoint.'
    }
    $nextArtifactToOpen = $boundaryRecord.next_artifact_to_open
} elseif ($guideRecord) {
    $recommendedCommand = if ($guideRecord.recommended_command) {
        $guideRecord.recommended_command
    } else {
        $firstFailedReplayCommand
    }
    $recommendedGuideCommand = if ($guideRecord.recommended_guide_command) {
        $guideRecord.recommended_guide_command
    } else {
        $summaryGuideCommand
    }
    $nextFocus = if ($guideRecord.next_focus) {
        $guideRecord.next_focus
    } else {
        'Keep the next replay on the earliest failing checkpoint before widening out.'
    }
    $reason = if ($guideRecord.reason) {
        $guideRecord.reason
    } else {
        'The saved summary guide already points at the current narrowest replay step.'
    }
    $nextArtifactToOpen = if ($guideRecord.first_failed_phase_primary_json_artifact_path) {
        $guideRecord.first_failed_phase_primary_json_artifact_path
    } else {
        $guidePath
    }
} else {
    $recommendedCommand = if ($firstFailedReplayCommand) {
        $firstFailedReplayCommand
    } else {
        $recommendedRunnerCommand
    }
    $recommendedGuideCommand = $summaryGuideCommand
    $nextFocus = 'The saved helper chain is incomplete, so start from the current summary and rebuild the narrower handoff artifacts.'
    $reason = 'No readable guide or boundary artifact was available for the current summary.'
    $nextArtifactToOpen = $SummaryPath
}

$artifactChainCoherent = [bool](-not $refreshNeeded -and -not $bundleNeedsRepair -and $refreshMatchesSummary -and $handoffMatchesSummary)
$pointerRepairNeeded = [bool](($refreshMatchesSummary -and -not $summaryRecordsRefreshArtifactPath) -or ($handoffMatchesSummary -and -not $summaryRecordsHandoffArtifactPath))
$preferredStartHelper = if ($recommendedGuideCommand -eq $handoffGuideCommand) {
    'handoff'
} elseif ($recommendedGuideCommand -eq $refreshStatusCommand -or $recommendedCommand -eq $refreshChainCommand) {
    'refresh-status'
} else {
    'recommended-runner'
}

$handoff = [ordered]@{
    issue = 'Google issue #3 validation handoff'
    purpose = 'Save one refresh-aware handoff artifact that tells the next Windows headed replay whether to trust the narrow replay guidance yet or repair the saved helper chain first.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    handoff_artifact_path = $ArtifactPath
    handoff_artifact_exists = [bool]$handoffExists
    summary_generated_at_utc = $summary.generated_at_utc
    completed = [bool]$summary.completed
    surface_check_status = $summary.surface_check_status
    surface_check_error = $summary.surface_check_error
    first_failed_phase = $firstFailedPhase
    first_failed_phase_error = $summary.first_failed_phase_error
    first_failed_phase_replay_command = $firstFailedReplayCommand
    refresh_status_command = $refreshStatusCommand
    refresh_chain_command = $refreshChainCommand
    summary_guide_command = $summaryGuideCommand
    manifest_guide_command = $manifestGuideCommand
    boundary_guide_command = $boundaryGuideCommand
    bundle_guide_command = $bundleGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_error = $manifestError
    summary_records_refresh_artifact_path = [bool]$summaryRecordsRefreshArtifactPath
    summary_refresh_artifact_path = if ($summaryRecordsRefreshArtifactPath) { $configuredSummaryRefreshPath } else { $null }
    manifest_records_refresh_artifact_path = [bool]$manifestRecordsRefreshArtifactPath
    manifest_refresh_artifact_path = if ($manifestRecordsRefreshArtifactPath) { $configuredManifestRefreshPath } else { $null }
    refresh_pointer_uses_manifest = [bool]$refreshPointerUsesManifest
    refresh_pointer_uses_fallback = [bool]$refreshPointerUsesFallback
    refresh_pointer_trusted = [bool]$refreshPointerTrusted
    summary_records_handoff_artifact_path = [bool]$summaryRecordsHandoffArtifactPath
    summary_handoff_artifact_path = if ($summaryRecordsHandoffArtifactPath) { $configuredSummaryHandoffPath } else { $null }
    manifest_records_handoff_artifact_path = [bool]$manifestRecordsHandoffArtifactPath
    manifest_handoff_artifact_path = if ($manifestRecordsHandoffArtifactPath) { $configuredManifestHandoffPath } else { $null }
    handoff_pointer_uses_manifest = [bool]$handoffPointerUsesManifest
    handoff_pointer_uses_fallback = [bool]$handoffPointerUsesFallback
    refresh_artifact_path = $refreshPath
    refresh_artifact_exists = [bool]$refreshExists
    refresh_status = $refreshStatus
    refresh_error = $refreshError
    refresh_matches_summary = [bool]$refreshMatchesSummary
    refresh_summary_path = if ($refreshRecord) { $refreshRecord.summary_path } else { $null }
    refresh_reason = if ($refreshRecord) { $refreshRecord.reason } else { $null }
    refresh_failed_step_count = if ($refreshRecord -and $null -ne $refreshRecord.failed_step_count) { [int]$refreshRecord.failed_step_count } else { $null }
    refresh_failed_step_names = if ($refreshRecord) { @($refreshRecord.failed_step_names) } else { @() }
    refresh_recommended_command = if ($refreshRecord) { $refreshRecord.recommended_command } else { $null }
    refresh_next_artifact_to_open = if ($refreshRecord) { $refreshRecord.next_artifact_to_open } else { $null }
    guide_artifact_path = $guidePath
    guide_artifact_error = $guideError
    boundary_artifact_path = $boundaryPath
    boundary_artifact_error = $boundaryError
    artifact_bundle_path = $bundlePath
    artifact_bundle_exists = [bool]$bundleExists
    artifact_bundle_status = $bundleStatus
    artifact_bundle_error = $bundleError
    artifact_bundle_reason = $bundleReason
    artifact_bundle_recommended_command = if ($bundleRecord) { $bundleRecord.recommended_command } else { $null }
    artifact_bundle_recommended_guide_command = if ($bundleRecord) { $bundleRecord.recommended_guide_command } else { $null }
    artifact_bundle_next_artifact_to_open = if ($bundleRecord) { $bundleRecord.next_artifact_to_open } else { $null }
    artifact_bundle_next_focus = if ($bundleRecord) { $bundleRecord.next_focus } else { $null }
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_focus = $nextFocus
    reason = $reason
    next_artifact_to_open = $nextArtifactToOpen
    handoff_matches_summary = [bool]$handoffMatchesSummary
    handoff_pointer_trusted = [bool]$handoffPointerTrusted
    artifact_chain_coherent = [bool]$artifactChainCoherent
    pointer_repair_needed = [bool]$pointerRepairNeeded
    preferred_start_helper = $preferredStartHelper
    manual_fixture_replay_command = if ($guideRecord) { $guideRecord.manual_fixture_replay_command } else { $null }
    manual_asset_closure_command = if ($guideRecord) { $guideRecord.manual_asset_closure_command } else { $null }
    manual_attached_html_flow_command = if ($guideRecord) { $guideRecord.manual_attached_html_flow_command } else { $null }
    manual_attached_html_runner_command = if ($guideRecord) { $guideRecord.manual_attached_html_runner_command } else { $null }
    manual_saved_page_flow_command = if ($guideRecord) { $guideRecord.manual_saved_page_flow_command } else { $null }
    reminder = if ($refreshNeeded) {
        'Read the current refresh artifact first. Refresh or regenerate stale helper-chain state before trusting the narrower replay commands.'
    } elseif ($bundleNeedsRepair) {
        'Read the current summary and the artifact-bundle audit first. Refresh stale or missing helper artifacts before trusting the narrower replay commands.'
    } elseif ($refreshPointerUsesManifest) {
        'The summary omitted its refresh pointer, but the manifest still records the matching refresh artifact. Keep that manifest-backed path aligned until the summary catches up.'
    } elseif ($handoffPointerUsesManifest) {
        'The summary omitted its handoff pointer, but the manifest still records the matching handoff artifact. Keep that manifest-backed checkpoint aligned until the summary catches up.'
    } elseif ($refreshPointerUsesFallback) {
        'Neither the current summary nor the saved manifest records the refresh artifact path yet, so this helper is using the fallback refresh location while keeping the runner and helper chain aligned.'
    } elseif ($handoffPointerUsesFallback) {
        'Neither the current summary nor the saved manifest records the handoff artifact path yet, so this helper is trusting the matching saved handoff artifact at the default location until pointer repair catches up.'
    } else {
        'The helper chain is coherent enough to stay on the current narrow replay path. Inspect the suggested artifact before widening back out to the full issue #3 runner.'
    }
}

$handoff | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $handoff | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host 'Google issue #3 validation handoff'
Write-Host ''
Write-Host ("Summary:   {0}" -f $handoff.summary_path)
Write-Host ("Manifest:  {0}" -f $handoff.manifest_artifact_path)
Write-Host ("Handoff:   {0}" -f $handoff.handoff_artifact_path)
Write-Host ("Generated: {0}" -f $handoff.summary_generated_at_utc)
Write-Host ("Completed: {0}" -f $handoff.completed)
Write-Host ("Surface:   {0}" -f $handoff.surface_check_status)
Write-Host ("First fail:{0}" -f $(if ($handoff.first_failed_phase) { ' ' + $handoff.first_failed_phase } else { ' none' }))
Write-Host ("Manifest exists: {0}" -f $handoff.manifest_artifact_exists)
if ($handoff.manifest_artifact_error) {
    Write-Host ("Manifest error: {0}" -f $handoff.manifest_artifact_error)
}
Write-Host ("Refresh cmd: {0}" -f $handoff.refresh_status_command)
Write-Host ("Refresh:   {0}" -f $handoff.refresh_artifact_path)
Write-Host ("Refresh exists: {0}" -f $handoff.refresh_artifact_exists)
Write-Host ("Refresh status: {0}" -f $handoff.refresh_status)
Write-Host ("Refresh matches summary: {0}" -f $handoff.refresh_matches_summary)
Write-Host ("Refresh pointer trusted: {0}" -f $handoff.refresh_pointer_trusted)
if ($handoff.refresh_summary_path) {
    Write-Host ("Refresh summary path: {0}" -f $handoff.refresh_summary_path)
}
Write-Host ("Summary refresh path recorded: {0}" -f $handoff.summary_records_refresh_artifact_path)
Write-Host ("Manifest refresh path recorded: {0}" -f $handoff.manifest_records_refresh_artifact_path)
if ($handoff.summary_refresh_artifact_path) {
    Write-Host ("Summary refresh path: {0}" -f $handoff.summary_refresh_artifact_path)
}
if ($handoff.manifest_refresh_artifact_path) {
    Write-Host ("Manifest refresh path: {0}" -f $handoff.manifest_refresh_artifact_path)
}
if ($handoff.refresh_pointer_uses_manifest) {
    Write-Host 'Refresh pointer source: Manifest'
}
if ($handoff.refresh_pointer_uses_fallback) {
    Write-Host 'Refresh pointer fallback: True'
}
Write-Host ("Bundle cmd: {0}" -f $handoff.bundle_guide_command)
Write-Host ("Bundle:    {0}" -f $handoff.artifact_bundle_path)
Write-Host ("Bundle exists: {0}" -f $handoff.artifact_bundle_exists)
Write-Host ("Bundle status: {0}" -f $handoff.artifact_bundle_status)
Write-Host ("Handoff exists: {0}" -f $handoff.handoff_artifact_exists)
Write-Host ("Handoff matches summary: {0}" -f $handoff.handoff_matches_summary)
Write-Host ("Handoff pointer trusted: {0}" -f $handoff.handoff_pointer_trusted)
Write-Host ("Artifact chain coherent: {0}" -f $handoff.artifact_chain_coherent)
Write-Host ("Pointer repair needed: {0}" -f $handoff.pointer_repair_needed)
Write-Host ("Preferred helper: {0}" -f $handoff.preferred_start_helper)
Write-Host ("Summary handoff path recorded: {0}" -f $handoff.summary_records_handoff_artifact_path)
Write-Host ("Manifest handoff path recorded: {0}" -f $handoff.manifest_records_handoff_artifact_path)
if ($handoff.summary_handoff_artifact_path) {
    Write-Host ("Summary handoff path: {0}" -f $handoff.summary_handoff_artifact_path)
}
if ($handoff.manifest_handoff_artifact_path) {
    Write-Host ("Manifest handoff path: {0}" -f $handoff.manifest_handoff_artifact_path)
}
if ($handoff.handoff_pointer_uses_manifest) {
    Write-Host 'Handoff pointer source: Manifest'
}
if ($handoff.handoff_pointer_uses_fallback) {
    Write-Host 'Handoff pointer fallback: True'
}
if ($handoff.refresh_error) {
    Write-Host ("Refresh error: {0}" -f $handoff.refresh_error)
}
if ($handoff.refresh_reason) {
    Write-Host ("Refresh reason: {0}" -f $handoff.refresh_reason)
}
if ($null -ne $handoff.refresh_failed_step_count -and $handoff.refresh_failed_step_count -gt 0) {
    Write-Host ("Refresh failed steps: {0}" -f ($handoff.refresh_failed_step_names -join ', '))
}
if ($handoff.artifact_bundle_error) {
    Write-Host ("Bundle error: {0}" -f $handoff.artifact_bundle_error)
}
if ($handoff.guide_artifact_error) {
    Write-Host ("Guide error: {0}" -f $handoff.guide_artifact_error)
}
if ($handoff.boundary_artifact_error) {
    Write-Host ("Boundary error: {0}" -f $handoff.boundary_artifact_error)
}
Write-Host ''
Write-Host ("Reason: {0}" -f $handoff.reason)
Write-Host ("Focus:  {0}" -f $handoff.next_focus)
Write-Host ("Open:   {0}" -f $handoff.next_artifact_to_open)
if ($handoff.recommended_command) {
    Write-Host ("Run:    {0}" -f $handoff.recommended_command)
}
if ($handoff.recommended_guide_command) {
    Write-Host ("Guide:  {0}" -f $handoff.recommended_guide_command)
}
Write-Host ("Summary guide:  {0}" -f $handoff.summary_guide_command)
Write-Host ("Manifest guide: {0}" -f $handoff.manifest_guide_command)
Write-Host ("Boundary guide: {0}" -f $handoff.boundary_guide_command)
Write-Host ("Refresh runner: {0}" -f $handoff.refresh_chain_command)
Write-Host ("Broader runner: {0}" -f $handoff.broader_runner_command)
if ($handoff.manual_fixture_replay_command) {
    Write-Host ("Manual replay: {0}" -f $handoff.manual_fixture_replay_command)
}
if ($handoff.manual_asset_closure_command) {
    Write-Host ("Asset check: {0}" -f $handoff.manual_asset_closure_command)
}
if ($handoff.manual_attached_html_flow_command) {
    Write-Host ("Manual flow: {0}" -f $handoff.manual_attached_html_flow_command)
}
if ($handoff.manual_attached_html_runner_command) {
    Write-Host ("Manual runner: {0}" -f $handoff.manual_attached_html_runner_command)
}
if ($handoff.manual_saved_page_flow_command) {
    Write-Host ("Saved-page flow: {0}" -f $handoff.manual_saved_page_flow_command)
}
Write-Host ''
Write-Host ("Reminder: {0}" -f $handoff.reminder)
