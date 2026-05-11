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

function Test-JsonPropertyDefined {
    param(
        $Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($null -eq $Object) {
        return $false
    }

    return [bool]($Object.PSObject.Properties.Name -contains $Name)
}

function Test-PathMatches {
    param(
        [string]$RecordedPath,
        [string]$ExpectedPath
    )

    if ([string]::IsNullOrWhiteSpace($RecordedPath) -or [string]::IsNullOrWhiteSpace($ExpectedPath)) {
        return $false
    }

    return ([System.IO.Path]::GetFullPath($RecordedPath)).Equals(
        [System.IO.Path]::GetFullPath($ExpectedPath),
        [System.StringComparison]::OrdinalIgnoreCase
    )
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
$manifestRecord = Read-ArtifactJson $manifestPath

$refreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.refresh_chain_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.handoff_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
$repairSummaryPointersCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_summary_pointers.ps1'
$repairRefreshPointerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_refresh_pointer.ps1'
$repairHandoffPointerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_handoff_pointer.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$runnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

$summaryRefreshPathDefined = Test-JsonPropertyDefined -Object $summary -Name 'refresh_chain_artifact_path'
$summaryRefreshErrorDefined = Test-JsonPropertyDefined -Object $summary -Name 'refresh_chain_artifact_error'
$summaryHandoffPathDefined = Test-JsonPropertyDefined -Object $summary -Name 'handoff_artifact_path'
$summaryHandoffErrorDefined = Test-JsonPropertyDefined -Object $summary -Name 'handoff_artifact_error'

$manifestRefreshPathDefined = Test-JsonPropertyDefined -Object $manifestRecord -Name 'refresh_chain_artifact_path'
$manifestRefreshErrorDefined = Test-JsonPropertyDefined -Object $manifestRecord -Name 'refresh_chain_artifact_error'
$manifestHandoffPathDefined = Test-JsonPropertyDefined -Object $manifestRecord -Name 'handoff_artifact_path'
$manifestHandoffErrorDefined = Test-JsonPropertyDefined -Object $manifestRecord -Name 'handoff_artifact_error'

$summaryRefreshPathMatches = Test-PathMatches -RecordedPath $summary.refresh_chain_artifact_path -ExpectedPath $refreshPath
$summaryHandoffPathMatches = Test-PathMatches -RecordedPath $summary.handoff_artifact_path -ExpectedPath $handoffPath
$manifestRefreshPathMatches = Test-PathMatches -RecordedPath $(if ($manifestRecord) { $manifestRecord.refresh_chain_artifact_path } else { $null }) -ExpectedPath $refreshPath
$manifestHandoffPathMatches = Test-PathMatches -RecordedPath $(if ($manifestRecord) { $manifestRecord.handoff_artifact_path } else { $null }) -ExpectedPath $handoffPath

$refreshArtifactExists = Test-Path -LiteralPath $refreshPath -PathType Leaf
$handoffArtifactExists = Test-Path -LiteralPath $handoffPath -PathType Leaf
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf

$pathWiringMissing = [bool](
    -not $summaryRefreshPathDefined -or
    -not $summaryHandoffPathDefined -or
    -not $manifestRefreshPathDefined -or
    -not $manifestHandoffPathDefined
)
$errorWiringMissing = [bool](
    -not $summaryRefreshErrorDefined -or
    -not $summaryHandoffErrorDefined -or
    -not $manifestRefreshErrorDefined -or
    -not $manifestHandoffErrorDefined
)
$pointerMismatchDetected = [bool](
    ($summaryRefreshPathDefined -and -not $summaryRefreshPathMatches) -or
    ($summaryHandoffPathDefined -and -not $summaryHandoffPathMatches) -or
    ($manifestRefreshPathDefined -and -not $manifestRefreshPathMatches) -or
    ($manifestHandoffPathDefined -and -not $manifestHandoffPathMatches)
)
$runnerWiringComplete = [bool](-not $pathWiringMissing -and -not $errorWiringMissing)
$pointerRepairNeeded = [bool](
    ($refreshArtifactExists -and (-not $summaryRefreshPathMatches -or -not $manifestRefreshPathMatches)) -or
    ($handoffArtifactExists -and (-not $summaryHandoffPathMatches -or -not $manifestHandoffPathMatches))
)

$recommendedCommand = $handoffGuideCommand
$recommendedGuideCommand = $handoffGuideCommand
$nextArtifactToOpen = $handoffPath
$reason = 'The saved summary and manifest already expose the current refresh and handoff wiring, so the next replay can stay on the narrower helper-chain path.'
$nextFocus = 'Open the handoff helper and follow its next_artifact_to_open guidance.'

if (-not $manifestExists) {
    $recommendedCommand = $runnerCommand
    $recommendedGuideCommand = $refreshStatusCommand
    $nextArtifactToOpen = $SummaryPath
    $reason = 'The saved manifest is missing, so the recommended runner still needs to recreate the summary-derived helper chain before wiring can be trusted.'
    $nextFocus = 'Rerun the recommended validation so the manifest and downstream helper chain are recreated from the current summary.'
} elseif ($pointerMismatchDetected -and $refreshArtifactExists -and $handoffArtifactExists) {
    $recommendedCommand = $repairSummaryPointersCommand
    $recommendedGuideCommand = $refreshStatusCommand
    $nextArtifactToOpen = $SummaryPath
    $reason = 'The saved summary or manifest points at refresh or handoff artifacts that do not match the current expected paths, so pointer repair should run before trusting the handoff.'
    $nextFocus = 'Repair the saved summary and manifest pointers so both refresh and handoff helpers agree on the same current artifact paths.'
} elseif ($refreshArtifactExists -and -not $summaryRefreshPathMatches) {
    $recommendedCommand = $repairRefreshPointerCommand
    $recommendedGuideCommand = $refreshStatusCommand
    $nextArtifactToOpen = $refreshPath
    $reason = 'The refresh artifact exists, but the summary still does not point at it cleanly.'
    $nextFocus = 'Repair the summary and manifest refresh pointer fields before trusting downstream refresh-aware helpers.'
} elseif ($handoffArtifactExists -and -not $summaryHandoffPathMatches) {
    $recommendedCommand = $repairHandoffPointerCommand
    $recommendedGuideCommand = $handoffGuideCommand
    $nextArtifactToOpen = $handoffPath
    $reason = 'The handoff artifact exists, but the summary still does not point at it cleanly.'
    $nextFocus = 'Repair the summary and manifest handoff pointer fields before trusting downstream handoff guidance.'
} elseif (-not $runnerWiringComplete) {
    $recommendedCommand = $runnerCommand
    $recommendedGuideCommand = $refreshStatusCommand
    $nextArtifactToOpen = $SummaryPath
    $reason = 'The recommended runner artifacts still omit one or more refresh or handoff wiring fields, so the broader runner remains the safest way to regenerate a complete saved state.'
    $nextFocus = 'Rerun the recommended validation and confirm the saved summary and manifest now keep both path and error fields for refresh and handoff artifacts.'
}

$report = [ordered]@{
    issue = 'Google issue #3 runner wiring audit'
    purpose = 'Tell the next Windows headed replay whether the saved recommended-validation summary and manifest preserve the refresh and handoff wiring the newer helper chain depends on.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    refresh_artifact_path = $refreshPath
    refresh_artifact_exists = [bool]$refreshArtifactExists
    handoff_artifact_path = $handoffPath
    handoff_artifact_exists = [bool]$handoffArtifactExists
    summary_refresh_path_defined = [bool]$summaryRefreshPathDefined
    summary_refresh_error_defined = [bool]$summaryRefreshErrorDefined
    summary_handoff_path_defined = [bool]$summaryHandoffPathDefined
    summary_handoff_error_defined = [bool]$summaryHandoffErrorDefined
    manifest_refresh_path_defined = [bool]$manifestRefreshPathDefined
    manifest_refresh_error_defined = [bool]$manifestRefreshErrorDefined
    manifest_handoff_path_defined = [bool]$manifestHandoffPathDefined
    manifest_handoff_error_defined = [bool]$manifestHandoffErrorDefined
    summary_refresh_path_matches = [bool]$summaryRefreshPathMatches
    summary_handoff_path_matches = [bool]$summaryHandoffPathMatches
    manifest_refresh_path_matches = [bool]$manifestRefreshPathMatches
    manifest_handoff_path_matches = [bool]$manifestHandoffPathMatches
    path_wiring_missing = [bool]$pathWiringMissing
    error_wiring_missing = [bool]$errorWiringMissing
    pointer_mismatch_detected = [bool]$pointerMismatchDetected
    runner_wiring_complete = [bool]$runnerWiringComplete
    pointer_repair_needed = [bool]$pointerRepairNeeded
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    repair_summary_pointers_command = $repairSummaryPointersCommand
    repair_refresh_pointer_command = $repairRefreshPointerCommand
    repair_handoff_pointer_command = $repairHandoffPointerCommand
    refresh_status_command = $refreshStatusCommand
    handoff_guide_command = $handoffGuideCommand
    broader_runner_command = $runnerCommand
    next_artifact_to_open = $nextArtifactToOpen
    reason = $reason
    next_focus = $nextFocus
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 runner wiring audit'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Refresh:   {0}" -f $report.refresh_artifact_path)
Write-Host ("Handoff:   {0}" -f $report.handoff_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
Write-Host ("Refresh exists: {0}" -f $report.refresh_artifact_exists)
Write-Host ("Handoff exists: {0}" -f $report.handoff_artifact_exists)
Write-Host ("Summary refresh path defined: {0}" -f $report.summary_refresh_path_defined)
Write-Host ("Summary refresh error defined: {0}" -f $report.summary_refresh_error_defined)
Write-Host ("Summary handoff path defined: {0}" -f $report.summary_handoff_path_defined)
Write-Host ("Summary handoff error defined: {0}" -f $report.summary_handoff_error_defined)
Write-Host ("Manifest refresh path defined: {0}" -f $report.manifest_refresh_path_defined)
Write-Host ("Manifest refresh error defined: {0}" -f $report.manifest_refresh_error_defined)
Write-Host ("Manifest handoff path defined: {0}" -f $report.manifest_handoff_path_defined)
Write-Host ("Manifest handoff error defined: {0}" -f $report.manifest_handoff_error_defined)
Write-Host ("Summary refresh path matches: {0}" -f $report.summary_refresh_path_matches)
Write-Host ("Summary handoff path matches: {0}" -f $report.summary_handoff_path_matches)
Write-Host ("Manifest refresh path matches: {0}" -f $report.manifest_refresh_path_matches)
Write-Host ("Manifest handoff path matches: {0}" -f $report.manifest_handoff_path_matches)
Write-Host ("Path wiring missing: {0}" -f $report.path_wiring_missing)
Write-Host ("Error wiring missing: {0}" -f $report.error_wiring_missing)
Write-Host ("Pointer mismatch detected: {0}" -f $report.pointer_mismatch_detected)
Write-Host ("Runner wiring complete: {0}" -f $report.runner_wiring_complete)
Write-Host ("Pointer repair needed: {0}" -f $report.pointer_repair_needed)
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
