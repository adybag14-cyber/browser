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

function Get-NormalizedPathValue {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    try {
        return [System.IO.Path]::GetFullPath($Path)
    } catch {
        return $Path
    }
}

function Test-PathsEqual {
    param(
        [string]$Left,
        [string]$Right
    )

    if ([string]::IsNullOrWhiteSpace($Left) -or [string]::IsNullOrWhiteSpace($Right)) {
        return $false
    }

    $leftValue = Get-NormalizedPathValue $Left
    $rightValue = Get-NormalizedPathValue $Right
    return $leftValue.Equals($rightValue, [System.StringComparison]::OrdinalIgnoreCase)
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

$summaryHasRefreshPathField = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_path'
$summaryHasRefreshErrorField = Test-HasProperty -Object $summary -Name 'refresh_chain_artifact_error'
$summaryHasHandoffPathField = Test-HasProperty -Object $summary -Name 'handoff_artifact_path'
$summaryHasHandoffErrorField = Test-HasProperty -Object $summary -Name 'handoff_artifact_error'

$manifestHasRefreshPathField = Test-HasProperty -Object $manifestRecord -Name 'refresh_chain_artifact_path'
$manifestHasRefreshErrorField = Test-HasProperty -Object $manifestRecord -Name 'refresh_chain_artifact_error'
$manifestHasHandoffPathField = Test-HasProperty -Object $manifestRecord -Name 'handoff_artifact_path'
$manifestHasHandoffErrorField = Test-HasProperty -Object $manifestRecord -Name 'handoff_artifact_error'

$summaryRefreshPath = if ($summaryHasRefreshPathField) { $summary.refresh_chain_artifact_path } else { $null }
$summaryRefreshError = if ($summaryHasRefreshErrorField) { $summary.refresh_chain_artifact_error } else { $null }
$summaryHandoffPath = if ($summaryHasHandoffPathField) { $summary.handoff_artifact_path } else { $null }
$summaryHandoffError = if ($summaryHasHandoffErrorField) { $summary.handoff_artifact_error } else { $null }

$manifestRefreshPath = if ($manifestHasRefreshPathField) { $manifestRecord.refresh_chain_artifact_path } else { $null }
$manifestRefreshError = if ($manifestHasRefreshErrorField) { $manifestRecord.refresh_chain_artifact_error } else { $null }
$manifestHandoffPath = if ($manifestHasHandoffPathField) { $manifestRecord.handoff_artifact_path } else { $null }
$manifestHandoffError = if ($manifestHasHandoffErrorField) { $manifestRecord.handoff_artifact_error } else { $null }

$configuredRefreshPath = if (-not [string]::IsNullOrWhiteSpace($summaryRefreshPath)) {
    $summaryRefreshPath
} elseif (-not [string]::IsNullOrWhiteSpace($manifestRefreshPath)) {
    $manifestRefreshPath
} else {
    $null
}
$configuredHandoffPath = if (-not [string]::IsNullOrWhiteSpace($summaryHandoffPath)) {
    $summaryHandoffPath
} elseif (-not [string]::IsNullOrWhiteSpace($manifestHandoffPath)) {
    $manifestHandoffPath
} else {
    $null
}

$resolvedRefreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredRefreshPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$resolvedHandoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredHandoffPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'

$summaryRefreshMatchesManifest = Test-PathsEqual -Left $summaryRefreshPath -Right $manifestRefreshPath
$summaryHandoffMatchesManifest = Test-PathsEqual -Left $summaryHandoffPath -Right $manifestHandoffPath
$summaryRefreshMatchesResolved = Test-PathsEqual -Left $summaryRefreshPath -Right $resolvedRefreshPath
$summaryHandoffMatchesResolved = Test-PathsEqual -Left $summaryHandoffPath -Right $resolvedHandoffPath
$manifestRefreshMatchesResolved = Test-PathsEqual -Left $manifestRefreshPath -Right $resolvedRefreshPath
$manifestHandoffMatchesResolved = Test-PathsEqual -Left $manifestHandoffPath -Right $resolvedHandoffPath
$refreshErrorMatches = $summaryHasRefreshErrorField -and $manifestHasRefreshErrorField -and ($summaryRefreshError -eq $manifestRefreshError)
$handoffErrorMatches = $summaryHasHandoffErrorField -and $manifestHasHandoffErrorField -and ($summaryHandoffError -eq $manifestHandoffError)

$summaryHasAllRunnerFields = [bool]($summaryHasRefreshPathField -and $summaryHasRefreshErrorField -and $summaryHasHandoffPathField -and $summaryHasHandoffErrorField)
$manifestHasAllRunnerFields = [bool]($manifestHasRefreshPathField -and $manifestHasRefreshErrorField -and $manifestHasHandoffPathField -and $manifestHasHandoffErrorField)
$pathsCoherent = [bool]($summaryRefreshMatchesManifest -and $summaryHandoffMatchesManifest -and $summaryRefreshMatchesResolved -and $summaryHandoffMatchesResolved -and $manifestRefreshMatchesResolved -and $manifestHandoffMatchesResolved)
$errorsCoherent = [bool]($refreshErrorMatches -and $handoffErrorMatches)

$runnerOutputWiringCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$pointerSourcesCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_pointer_sources.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null

if (-not $manifestExists) {
    $status = 'manifest-missing'
    $reason = 'The summary exists, but the saved manifest is missing, so value coherency cannot yet be checked across the runner outputs.'
    $nextFocus = 'Regenerate the recommended runner outputs before trusting narrower helper guidance.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $runnerOutputWiringCommand
    $nextArtifactToOpen = $SummaryPath
} elseif (-not $manifestReadable) {
    $status = 'manifest-unreadable'
    $reason = 'The manifest exists but could not be parsed cleanly, so the saved runner output values cannot be compared safely.'
    $nextFocus = 'Repair or regenerate the manifest before using the narrower refresh or handoff helpers.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $runnerOutputWiringCommand
    $nextArtifactToOpen = $manifestPath
} elseif (-not ($summaryHasAllRunnerFields -and $manifestHasAllRunnerFields)) {
    $status = 'runner-fields-missing'
    $reason = 'At least one top-level refresh or handoff path/error field is still missing from the summary or manifest, so value coherency is blocked behind the field-wiring gap.'
    $nextFocus = 'Keep the next issue #3 slice on runner output wiring until both summary and manifest carry the full refresh and handoff contract directly.'
    $recommendedCommand = $runnerOutputWiringCommand
    $recommendedGuideCommand = $pointerSourcesCommand
    $nextArtifactToOpen = if (-not $summaryHasAllRunnerFields) { $SummaryPath } else { $manifestPath }
} elseif (-not $pathsCoherent) {
    $status = 'runner-path-values-diverged'
    $reason = 'The summary and manifest both expose the runner fields, but at least one saved refresh or handoff path disagrees with the matching output or the resolved artifact location.'
    $nextFocus = 'Repair the top-level runner path values before trusting narrower refresh or handoff guidance from the saved artifacts.'
    $recommendedCommand = $pointerSourcesCommand
    $recommendedGuideCommand = $runnerOutputWiringCommand
    $nextArtifactToOpen = if (-not $summaryRefreshMatchesManifest -or -not $summaryRefreshMatchesResolved) { $resolvedRefreshPath } else { $resolvedHandoffPath }
} elseif (-not $errorsCoherent) {
    $status = 'runner-error-values-diverged'
    $reason = 'The summary and manifest both expose the runner fields, but at least one saved refresh or handoff error value no longer agrees across the top-level outputs.'
    $nextFocus = 'Regenerate or repair the top-level runner error fields before narrowing back down to the refresh or handoff helpers.'
    $recommendedCommand = $runnerOutputWiringCommand
    $recommendedGuideCommand = $pointerSourcesCommand
    $nextArtifactToOpen = $manifestPath
} else {
    $status = 'runner-output-coherent'
    $reason = 'The summary and manifest expose matching refresh and handoff path/error values, and those saved paths still resolve to the current expected artifact locations.'
    $nextFocus = 'Use the narrower refresh or handoff helpers now that the top-level runner outputs agree on the saved contract values.'
    $recommendedCommand = $refreshStatusCommand
    $recommendedGuideCommand = $handoffGuideCommand
    $nextArtifactToOpen = $resolvedRefreshPath
}

$report = [ordered]@{
    issue = 'Google issue #3 runner output coherency'
    purpose = 'Check whether the recommended validation runner summary and manifest agree on refresh and handoff path/error values.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_readable = [bool]$manifestReadable
    resolved_refresh_artifact_path = $resolvedRefreshPath
    resolved_handoff_artifact_path = $resolvedHandoffPath
    summary_has_all_runner_fields = [bool]$summaryHasAllRunnerFields
    manifest_has_all_runner_fields = [bool]$manifestHasAllRunnerFields
    summary_refresh_artifact_path = $summaryRefreshPath
    summary_refresh_artifact_error = $summaryRefreshError
    summary_handoff_artifact_path = $summaryHandoffPath
    summary_handoff_artifact_error = $summaryHandoffError
    manifest_refresh_artifact_path = $manifestRefreshPath
    manifest_refresh_artifact_error = $manifestRefreshError
    manifest_handoff_artifact_path = $manifestHandoffPath
    manifest_handoff_artifact_error = $manifestHandoffError
    summary_refresh_matches_manifest = [bool]$summaryRefreshMatchesManifest
    summary_handoff_matches_manifest = [bool]$summaryHandoffMatchesManifest
    summary_refresh_matches_resolved = [bool]$summaryRefreshMatchesResolved
    summary_handoff_matches_resolved = [bool]$summaryHandoffMatchesResolved
    manifest_refresh_matches_resolved = [bool]$manifestRefreshMatchesResolved
    manifest_handoff_matches_resolved = [bool]$manifestHandoffMatchesResolved
    refresh_error_matches = [bool]$refreshErrorMatches
    handoff_error_matches = [bool]$handoffErrorMatches
    paths_coherent = [bool]$pathsCoherent
    errors_coherent = [bool]$errorsCoherent
    next_artifact_to_open = $nextArtifactToOpen
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    runner_output_wiring_command = $runnerOutputWiringCommand
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

Write-Host 'Google issue #3 runner output coherency'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
Write-Host ("Manifest readable: {0}" -f $report.manifest_artifact_readable)
Write-Host ("Refresh path: {0}" -f $report.resolved_refresh_artifact_path)
Write-Host ("Handoff path: {0}" -f $report.resolved_handoff_artifact_path)
Write-Host ("Summary has all fields: {0}" -f $report.summary_has_all_runner_fields)
Write-Host ("Manifest has all fields: {0}" -f $report.manifest_has_all_runner_fields)
Write-Host ("Paths coherent: {0}" -f $report.paths_coherent)
Write-Host ("Errors coherent: {0}" -f $report.errors_coherent)
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
