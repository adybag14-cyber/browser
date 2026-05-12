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

$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$repairArtifactPathsCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_artifact_paths.ps1'
$handoffPathCoherencyCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_handoff_path_coherency.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'
$summaryGuideSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json'
}

$summaryExists = Test-Path -LiteralPath $SummaryPath -PathType Leaf
if (-not $summaryExists) {
    $fallbackArtifactRoot = Split-Path -Parent $SummaryPath
    if (-not $ArtifactPath) {
        $ArtifactPath = Join-Path $fallbackArtifactRoot 'google-issue3-handoff-path-coherency-safe.json'
    }

    $report = [ordered]@{
        issue = 'Google issue #3 handoff path coherency safe helper'
        purpose = 'Check whether the existing handoff path coherency helper is safe to trust under strict mode for the current issue #3 summary.'
        generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        summary_path = $SummaryPath
        artifact_path = $ArtifactPath
        summary_exists = $false
        recommended_command = $recommendedRunnerCommand
        recommended_guide_command = $summaryGuideSafeCommand
        broader_runner_command = $recommendedRunnerCommand
        repair_artifact_paths_command = $repairArtifactPathsCommand
        handoff_path_coherency_command = $handoffPathCoherencyCommand
        handoff_guide_command = $handoffGuideCommand
        next_artifact_to_open = $SummaryPath
        status = 'summary-missing'
        reason = 'No saved issue #3 recommended-validation summary exists yet, so the handoff path coherency helper cannot be trusted for the current replay.'
        next_focus = 'Run the bounded issue #3 recommended validation first, then reopen this safe helper before trusting the raw handoff path coherency step.'
        summary_guide_command = $summaryGuideCommand
        summary_guide_safe_command = $summaryGuideSafeCommand
    }

    $report | ConvertTo-Json -Depth 6 | Set-Content -Path $ArtifactPath -Encoding Ascii
    if ($Json) {
        $report | ConvertTo-Json -Depth 6
        exit 0
    }

    Write-Host 'Google issue #3 handoff path coherency safe helper'
    Write-Host ''
    Write-Host ("Summary:  {0}" -f $report.summary_path)
    Write-Host ("Artifact: {0}" -f $report.artifact_path)
    Write-Host ("Status:   {0}" -f $report.status)
    Write-Host ("Reason:   {0}" -f $report.reason)
    Write-Host ("Focus:    {0}" -f $report.next_focus)
    Write-Host ("Run:      {0}" -f $report.recommended_command)
    Write-Host ("Guide:    {0}" -f $report.recommended_guide_command)
    exit 0
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$summaryHasArtifactRootField = Test-HasProperty -Object $summary -Name 'artifact_root'
$configuredArtifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
$artifactRoot = if (-not [string]::IsNullOrWhiteSpace($configuredArtifactRoot)) {
    $configuredArtifactRoot
} else {
    Split-Path -Parent $SummaryPath
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-handoff-path-coherency-safe.json'
}

$summaryHasManifestArtifactPathField = Test-HasProperty -Object $summary -Name 'manifest_artifact_path'
$configuredManifestPath = Get-OptionalPropertyValue -Object $summary -Name 'manifest_artifact_path'
$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredManifestPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
$manifestRecord = $null
$manifestReadable = $false
$manifestError = $null
if ($manifestExists) {
    $manifestRecord = Read-ArtifactJson $manifestPath
    $manifestReadable = [bool]$manifestRecord
    if (-not $manifestReadable) {
        $manifestError = 'Manifest exists but could not be parsed cleanly.'
    }
}

$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null

if (-not $summaryHasArtifactRootField) {
    $status = 'summary-artifact-root-missing'
    $reason = 'The saved issue #3 summary omits artifact_root, so the raw handoff path coherency helper can still fail under strict mode before it reaches its fallback path logic.'
    $nextFocus = 'Regenerate the broader recommended-validation summary before trusting the raw handoff path coherency helper.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $summaryGuideSafeCommand
    $nextArtifactToOpen = $SummaryPath
} elseif (-not $summaryHasManifestArtifactPathField) {
    $status = 'summary-manifest-path-missing'
    $reason = 'The saved issue #3 summary omits manifest_artifact_path, so the raw handoff path coherency helper can still fail under strict mode before it reaches the manifest fallback path.'
    $nextFocus = 'Repair the saved validation artifact paths first, then reopen the raw handoff path coherency helper.'
    $recommendedCommand = $repairArtifactPathsCommand
    $recommendedGuideCommand = $handoffPathCoherencyCommand
    $nextArtifactToOpen = $SummaryPath
} elseif (-not $manifestExists) {
    $status = 'manifest-missing'
    $reason = 'The saved issue #3 summary points at a manifest path, but the manifest file is missing for the current replay.'
    $nextFocus = 'Regenerate the broader recommended-validation outputs so the manifest exists before trusting the raw handoff path coherency helper.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $summaryGuideSafeCommand
    $nextArtifactToOpen = $manifestPath
} elseif (-not $manifestReadable) {
    $status = 'manifest-unreadable'
    $reason = 'The saved issue #3 manifest exists but could not be parsed cleanly, so the raw handoff path coherency helper is not the safest next checkpoint yet.'
    $nextFocus = 'Regenerate the broader recommended-validation outputs, then reopen the raw handoff path coherency helper once the manifest is readable.'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $summaryGuideSafeCommand
    $nextArtifactToOpen = $manifestPath
} else {
    $status = 'safe-to-run-existing-helper'
    $reason = 'The saved issue #3 summary and manifest expose the prerequisite fields the raw handoff path coherency helper expects under strict mode.'
    $nextFocus = 'Run the raw handoff path coherency helper, then continue into the handoff helper if the saved paths are coherent.'
    $recommendedCommand = $handoffPathCoherencyCommand
    $recommendedGuideCommand = $handoffGuideCommand
    $nextArtifactToOpen = $SummaryPath
}

$report = [ordered]@{
    issue = 'Google issue #3 handoff path coherency safe helper'
    purpose = 'Check whether the existing handoff path coherency helper is safe to trust under strict mode for the current issue #3 summary.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    summary_exists = $true
    summary_generated_at_utc = Get-OptionalPropertyValue -Object $summary -Name 'generated_at_utc'
    summary_has_artifact_root_field = [bool]$summaryHasArtifactRootField
    summary_artifact_root = if ($summaryHasArtifactRootField) { $configuredArtifactRoot } else { $null }
    summary_has_manifest_artifact_path_field = [bool]$summaryHasManifestArtifactPathField
    summary_manifest_artifact_path = if ($summaryHasManifestArtifactPathField) { $configuredManifestPath } else { $null }
    artifact_root = $artifactRoot
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    manifest_artifact_readable = [bool]$manifestReadable
    manifest_artifact_error = $manifestError
    broader_runner_command = $recommendedRunnerCommand
    repair_artifact_paths_command = $repairArtifactPathsCommand
    handoff_path_coherency_command = $handoffPathCoherencyCommand
    handoff_guide_command = $handoffGuideCommand
    summary_guide_command = $summaryGuideCommand
    summary_guide_safe_command = $summaryGuideSafeCommand
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_artifact_to_open = $nextArtifactToOpen
    status = $status
    reason = $reason
    next_focus = $nextFocus
}

$report | ConvertTo-Json -Depth 6 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 handoff path coherency safe helper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
Write-Host ("Manifest readable: {0}" -f $report.manifest_artifact_readable)
if ($report.manifest_artifact_error) {
    Write-Host ("Manifest error: {0}" -f $report.manifest_artifact_error)
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
