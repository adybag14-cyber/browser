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

$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json'
}

$summaryExists = Test-Path -LiteralPath $SummaryPath -PathType Leaf
if (-not $summaryExists) {
    $report = [ordered]@{
        issue = 'Google issue #3 triage next artifact'
        purpose = 'Tell the next Windows replay which saved artifact to open first and which helper command should guide that checkpoint.'
        generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        summary_path = $SummaryPath
        summary_exists = $false
        preferred_start_helper = 'recommended-runner'
        recommended_command = $recommendedRunnerCommand
        recommended_guide_command = $summaryGuideCommand
        next_artifact_to_open = $SummaryPath
        reason = 'No saved issue #3 recommended-validation summary exists yet, so the bounded runner still needs to create the first summary and helper artifacts.'
        next_focus = 'Run the recommended issue #3 validation runner first, then reopen this helper to jump straight to the current narrowest saved checkpoint.'
    }

    if ($Json) {
        $report | ConvertTo-Json -Depth 6
        exit 0
    }

    Write-Host 'Google issue #3 triage next artifact'
    Write-Host ''
    Write-Host ("Summary: {0}" -f $report.summary_path)
    Write-Host ("Exists:  {0}" -f $report.summary_exists)
    Write-Host ("Reason:  {0}" -f $report.reason)
    Write-Host ("Focus:   {0}" -f $report.next_focus)
    Write-Host ("Open:    {0}" -f $report.next_artifact_to_open)
    Write-Host ("Run:     {0}" -f $report.recommended_command)
    Write-Host ("Guide:   {0}" -f $report.recommended_guide_command)
    exit 0
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$artifactRoot = if (-not [string]::IsNullOrWhiteSpace($summary.artifact_root)) {
    $summary.artifact_root
} else {
    Split-Path -Parent $SummaryPath
}

$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.manifest_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$manifestRecord = Read-ArtifactJson $manifestPath
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf

$configuredSummaryRefreshPath = $summary.refresh_chain_artifact_path
$configuredManifestRefreshPath = if ($manifestRecord) { $manifestRecord.refresh_chain_artifact_path } else { $null }
$configuredRefreshPath = if (-not [string]::IsNullOrWhiteSpace($configuredSummaryRefreshPath)) {
    $configuredSummaryRefreshPath
} elseif (-not [string]::IsNullOrWhiteSpace($configuredManifestRefreshPath)) {
    $configuredManifestRefreshPath
} else {
    $null
}
$refreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredRefreshPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$refreshExists = Test-Path -LiteralPath $refreshPath -PathType Leaf
$refreshRecord = Read-ArtifactJson $refreshPath
$refreshMatchesSummary = [bool]($refreshRecord -and -not [string]::IsNullOrWhiteSpace($refreshRecord.summary_path) -and ([System.IO.Path]::GetFullPath($refreshRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase))
$refreshStatus = if ($refreshRecord -and $refreshRecord.status) {
    $refreshRecord.status
} elseif ($summary.refresh_chain_artifact_error -or ($manifestRecord -and $manifestRecord.refresh_chain_artifact_error)) {
    'helper-error'
} elseif ($refreshExists) {
    'present-unreadable'
} else {
    'missing'
}

$configuredSummaryHandoffPath = $summary.handoff_artifact_path
$configuredManifestHandoffPath = if ($manifestRecord) { $manifestRecord.handoff_artifact_path } else { $null }
$configuredHandoffPath = if (-not [string]::IsNullOrWhiteSpace($configuredSummaryHandoffPath)) {
    $configuredSummaryHandoffPath
} elseif (-not [string]::IsNullOrWhiteSpace($configuredManifestHandoffPath)) {
    $configuredManifestHandoffPath
} else {
    $null
}
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredHandoffPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
$handoffExists = Test-Path -LiteralPath $handoffPath -PathType Leaf
$handoffRecord = Read-ArtifactJson $handoffPath
$handoffMatchesSummary = [bool]($handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffRecord.summary_path) -and ([System.IO.Path]::GetFullPath($handoffRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase))
$handoffReady = [bool]($handoffRecord -and $handoffMatchesSummary -and -not [string]::IsNullOrWhiteSpace($handoffRecord.next_artifact_to_open))

$bundlePath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.artifact_bundle_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-artifact-bundle.json'
$bundleExists = Test-Path -LiteralPath $bundlePath -PathType Leaf
$bundleRecord = Read-ArtifactJson $bundlePath
$bundleStatus = if ($bundleRecord -and $bundleRecord.status) {
    $bundleRecord.status
} elseif ($summary.artifact_bundle_error) {
    'helper-error'
} elseif ($bundleExists) {
    'present-unreadable'
} else {
    'missing'
}

$artifactChainCoherent = [bool]($bundleStatus -eq 'complete' -and $refreshStatus -eq 'refreshed' -and $refreshMatchesSummary -and $handoffMatchesSummary)
$preferredStartHelper = if ($artifactChainCoherent -and $handoffReady) {
    'handoff'
} elseif ($refreshStatus -eq 'missing' -and -not $refreshExists) {
    'recommended-runner'
} else {
    'refresh-status'
}

$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null
$reason = $null
$nextFocus = $null

if ($preferredStartHelper -eq 'handoff') {
    $recommendedCommand = if ($handoffRecord -and $handoffRecord.recommended_command) {
        $handoffRecord.recommended_command
    } else {
        $handoffGuideCommand
    }
    $recommendedGuideCommand = $handoffGuideCommand
    $nextArtifactToOpen = if ($handoffRecord -and $handoffRecord.next_artifact_to_open) {
        $handoffRecord.next_artifact_to_open
    } else {
        $handoffPath
    }
    $reason = 'The saved refresh, bundle, and handoff artifacts all align with the current summary, so the handoff helper already points at the narrowest trustworthy checkpoint.'
    $nextFocus = if ($handoffRecord -and $handoffRecord.next_focus) {
        $handoffRecord.next_focus
    } else {
        'Open the saved handoff helper output first, then follow its next-artifact pointer before widening back out.'
    }
} elseif ($preferredStartHelper -eq 'refresh-status') {
    $recommendedCommand = if ($refreshRecord -and $refreshRecord.recommended_command) {
        $refreshRecord.recommended_command
    } else {
        $refreshChainCommand
    }
    $recommendedGuideCommand = $refreshStatusCommand
    $nextArtifactToOpen = if ($refreshRecord -and $refreshRecord.next_artifact_to_open) {
        $refreshRecord.next_artifact_to_open
    } else {
        $refreshPath
    }
    $reason = if ($bundleStatus -ne 'complete') {
        "The saved artifact bundle reports '$bundleStatus', so the helper chain still needs a refresh-first repair pass before the narrower handoff can be trusted."
    } elseif (-not $refreshMatchesSummary) {
        'The saved refresh artifact does not match the current summary yet, so reopen refresh status and repair the helper chain first.'
    } elseif (-not $handoffExists) {
        'The saved handoff artifact is still missing, so refresh status is the safest starting point for rebuilding the helper chain.'
    } elseif (-not $handoffMatchesSummary) {
        'The saved handoff artifact does not match the current summary yet, so refresh status should repair the helper chain before the next narrow replay.'
    } elseif (-not $handoffReady) {
        'The saved handoff artifact still lacks a next-artifact pointer, so refresh status remains the safest starting point.'
    } else {
        'The helper chain still needs a refresh-first pass before the next narrower replay.'
    }
    $nextFocus = if ($refreshRecord -and $refreshRecord.next_focus) {
        $refreshRecord.next_focus
    } else {
        'Open refresh status first, then run the refresh-chain repair if the helper chain is still stale or incomplete.'
    }
} else {
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $summaryGuideCommand
    $nextArtifactToOpen = $SummaryPath
    $reason = 'No saved refresh artifact exists yet for the current summary, so rerun the bounded validator to rebuild the issue #3 helper chain from scratch.'
    $nextFocus = 'Rerun the recommended validation so the current summary, refresh, bundle, and handoff artifacts are recreated together.'
}

$report = [ordered]@{
    issue = 'Google issue #3 triage next artifact'
    purpose = 'Tell the next Windows replay which saved artifact to open first and which helper command should guide that checkpoint.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    refresh_artifact_path = $refreshPath
    refresh_artifact_exists = [bool]$refreshExists
    refresh_status = $refreshStatus
    refresh_matches_summary = [bool]$refreshMatchesSummary
    handoff_artifact_path = $handoffPath
    handoff_artifact_exists = [bool]$handoffExists
    handoff_matches_summary = [bool]$handoffMatchesSummary
    handoff_ready = [bool]$handoffReady
    artifact_bundle_path = $bundlePath
    artifact_bundle_exists = [bool]$bundleExists
    artifact_bundle_status = $bundleStatus
    artifact_chain_coherent = [bool]$artifactChainCoherent
    preferred_start_helper = $preferredStartHelper
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_artifact_to_open = $nextArtifactToOpen
    refresh_status_command = $refreshStatusCommand
    refresh_chain_command = $refreshChainCommand
    handoff_guide_command = $handoffGuideCommand
    summary_guide_command = $summaryGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    reason = $reason
    next_focus = $nextFocus
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 triage next artifact'
Write-Host ''
Write-Host ("Summary:  {0}" -f $report.summary_path)
Write-Host ("Manifest: {0}" -f $report.manifest_artifact_path)
Write-Host ("Refresh:  {0}" -f $report.refresh_artifact_path)
Write-Host ("Handoff:  {0}" -f $report.handoff_artifact_path)
Write-Host ("Bundle:   {0}" -f $report.artifact_bundle_path)
Write-Host ("Helper:   {0}" -f $report.preferred_start_helper)
Write-Host ("Open:     {0}" -f $report.next_artifact_to_open)
Write-Host ''
Write-Host ("Reason:   {0}" -f $report.reason)
Write-Host ("Focus:    {0}" -f $report.next_focus)
Write-Host ("Run:      {0}" -f $report.recommended_command)
Write-Host ("Guide:    {0}" -f $report.recommended_guide_command)
