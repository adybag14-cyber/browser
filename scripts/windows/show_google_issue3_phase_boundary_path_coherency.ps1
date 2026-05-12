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

function PathsMatch([string]$Left, [string]$Right) {
    if ([string]::IsNullOrWhiteSpace($Left) -or [string]::IsNullOrWhiteSpace($Right)) {
        return $false
    }

    return ([System.IO.Path]::GetFullPath($Left)).Equals([System.IO.Path]::GetFullPath($Right), [System.StringComparison]::OrdinalIgnoreCase)
}

$boundaryCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_phase_boundary.ps1'
$selfCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_phase_boundary_path_coherency.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json'
}

if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    $report = [ordered]@{
        issue = 'Google issue #3 phase-boundary path coherency'
        purpose = 'Tell the next Windows replay whether the raw phase-boundary helper can safely reuse the current boundary artifact path.'
        generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        summary_path = $SummaryPath
        summary_exists = $false
        status = 'summary-missing'
        recommended_command = $recommendedRunnerCommand
        recommended_guide_command = $summaryGuideCommand
        broader_runner_command = $recommendedRunnerCommand
        boundary_command = $boundaryCommand
        next_artifact_to_open = $SummaryPath
        reason = 'No saved issue #3 recommended-validation summary exists yet, so there is no current boundary target to audit.'
        next_focus = 'Run the broader issue #3 validation runner first, then reopen this helper before trusting the raw boundary helper.'
    }

    if ($Json) {
        $report | ConvertTo-Json -Depth 6
        exit 0
    }

    Write-Host 'Google issue #3 phase-boundary path coherency'
    Write-Host ''
    Write-Host ("Summary:  {0}" -f $report.summary_path)
    Write-Host ("Exists:   {0}" -f $report.summary_exists)
    Write-Host ("Status:   {0}" -f $report.status)
    Write-Host ("Reason:   {0}" -f $report.reason)
    Write-Host ("Focus:    {0}" -f $report.next_focus)
    Write-Host ("Run:      {0}" -f $report.recommended_command)
    Write-Host ("Guide:    {0}" -f $report.recommended_guide_command)
    exit 0
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$artifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
if ([string]::IsNullOrWhiteSpace($artifactRoot)) {
    $artifactRoot = Split-Path -Parent $SummaryPath
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-phase-boundary-path-coherency.json'
}

$configuredBoundaryPath = Get-OptionalPropertyValue -Object $summary -Name 'boundary_artifact_path'
$fallbackBoundaryPath = Join-Path $artifactRoot 'google-issue3-phase-boundary.json'
$resolvedBoundaryPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredBoundaryPath -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-phase-boundary.json'
$usesConfiguredBoundaryPath = -not [string]::IsNullOrWhiteSpace($configuredBoundaryPath)
$usesNonDefaultBoundaryPath = $usesConfiguredBoundaryPath -and (-not (PathsMatch $resolvedBoundaryPath $fallbackBoundaryPath))
$explicitBoundaryCommand = if ($usesNonDefaultBoundaryPath) {
    "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_phase_boundary.ps1 -ArtifactPath `"$resolvedBoundaryPath`""
} else {
    $boundaryCommand
}

$boundaryExists = Test-Path -LiteralPath $resolvedBoundaryPath -PathType Leaf
$boundaryRecord = $null
$boundaryError = $null
if ($boundaryExists) {
    try {
        $boundaryRecord = Read-ArtifactJson $resolvedBoundaryPath
    } catch {
        $boundaryError = $_.Exception.Message
    }
}

$boundarySummaryPath = Get-OptionalPropertyValue -Object $boundaryRecord -Name 'summary_path'
$boundaryMatchesSummary = PathsMatch $SummaryPath $boundarySummaryPath

$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $selfCommand
$nextArtifactToOpen = $null

if ($boundaryError) {
    $status = 'boundary-unreadable'
    $reason = 'The resolved issue #3 phase-boundary artifact exists but could not be read cleanly, so regenerate it from the current summary before trusting older boundary output.'
    $nextFocus = 'Rerun the raw phase-boundary helper against the current boundary target so the saved boundary artifact is rebuilt from the current summary.'
    $recommendedCommand = $explicitBoundaryCommand
    $nextArtifactToOpen = $resolvedBoundaryPath
} elseif ($boundaryExists -and -not $boundaryMatchesSummary) {
    $status = 'boundary-needs-refresh'
    $reason = 'The resolved issue #3 phase-boundary artifact still points at a different summary path than the current summary, so it should be refreshed before the next narrowed replay trusts it.'
    $nextFocus = 'Regenerate the phase-boundary artifact from the current summary, keeping the write target aligned with the current preferred boundary path.'
    $recommendedCommand = $explicitBoundaryCommand
    $nextArtifactToOpen = $resolvedBoundaryPath
} elseif ($usesNonDefaultBoundaryPath) {
    $status = 'explicit-artifact-path-required'
    $reason = 'The current summary records a non-default boundary artifact path. The raw phase-boundary helper still defaults its write target to the fallback boundary file when no -ArtifactPath is provided, so the next replay should pass the configured path explicitly.'
    $nextFocus = 'Use the raw phase-boundary helper with the configured boundary path so the next replay keeps reads and writes on the same artifact.'
    $recommendedCommand = $explicitBoundaryCommand
    $nextArtifactToOpen = if ($boundaryExists) { $resolvedBoundaryPath } else { $SummaryPath }
} else {
    $status = 'coherent'
    $reason = 'The current summary either uses the default boundary artifact path or does not need a special override, so the raw phase-boundary helper can stay on its normal default target.'
    $nextFocus = 'Use the raw phase-boundary helper for the next narrowed replay, or reopen this helper first if the saved summary path changes again.'
    $recommendedCommand = $boundaryCommand
    $recommendedGuideCommand = $summaryGuideCommand
    $nextArtifactToOpen = if ($boundaryExists) { $resolvedBoundaryPath } else { $SummaryPath }
}

$report = [ordered]@{
    issue = 'Google issue #3 phase-boundary path coherency'
    purpose = 'Tell the next Windows replay whether the raw phase-boundary helper can safely reuse the current boundary artifact path.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    summary_exists = $true
    summary_generated_at_utc = Get-OptionalPropertyValue -Object $summary -Name 'generated_at_utc'
    artifact_root = $artifactRoot
    report_artifact_path = $ArtifactPath
    summary_records_boundary_artifact_path = [bool]$usesConfiguredBoundaryPath
    summary_boundary_artifact_path = $configuredBoundaryPath
    fallback_boundary_artifact_path = $fallbackBoundaryPath
    resolved_boundary_artifact_path = $resolvedBoundaryPath
    uses_nondefault_boundary_path = [bool]$usesNonDefaultBoundaryPath
    boundary_artifact_exists = [bool]$boundaryExists
    boundary_artifact_error = $boundaryError
    boundary_summary_path = $boundarySummaryPath
    boundary_matches_summary = [bool]$boundaryMatchesSummary
    status = $status
    reason = $reason
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    boundary_command = $boundaryCommand
    explicit_boundary_command = $explicitBoundaryCommand
    summary_guide_command = $summaryGuideCommand
    refresh_chain_command = $refreshChainCommand
    broader_runner_command = $recommendedRunnerCommand
}

$report | ConvertTo-Json -Depth 6 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 phase-boundary path coherency'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Report:    {0}" -f $report.report_artifact_path)
Write-Host ("Boundary:  {0}" -f $report.resolved_boundary_artifact_path)
Write-Host ("Fallback:  {0}" -f $report.fallback_boundary_artifact_path)
Write-Host ("Configured boundary path recorded: {0}" -f $report.summary_records_boundary_artifact_path)
Write-Host ("Uses non-default boundary path: {0}" -f $report.uses_nondefault_boundary_path)
Write-Host ("Boundary exists: {0}" -f $report.boundary_artifact_exists)
Write-Host ("Boundary matches summary: {0}" -f $report.boundary_matches_summary)
if ($report.boundary_artifact_error) {
    Write-Host ("Boundary error: {0}" -f $report.boundary_artifact_error)
}
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Open:      {0}" -f $report.next_artifact_to_open)
Write-Host ''
Write-Host ("Reason:    {0}" -f $report.reason)
Write-Host ("Focus:     {0}" -f $report.next_focus)
Write-Host ("Run:       {0}" -f $report.recommended_command)
Write-Host ("Guide:     {0}" -f $report.recommended_guide_command)
