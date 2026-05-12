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

$refreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($summary.refresh_chain_artifact_path) { $summary.refresh_chain_artifact_path } elseif ($manifestRecord) { $manifestRecord.refresh_chain_artifact_path } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $(if ($summary.handoff_artifact_path) { $summary.handoff_artifact_path } elseif ($manifestRecord) { $manifestRecord.handoff_artifact_path } else { $null }) -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
$repairReportPath = Join-Path $artifactRoot 'google-issue3-summary-pointer-repair.json'

$refreshExists = Test-Path -LiteralPath $refreshPath -PathType Leaf
$handoffExists = Test-Path -LiteralPath $handoffPath -PathType Leaf
$repairReportExists = Test-Path -LiteralPath $repairReportPath -PathType Leaf
$repairReport = Read-ArtifactJson $repairReportPath
$refreshRecord = Read-ArtifactJson $refreshPath
$handoffRecord = Read-ArtifactJson $handoffPath

$refreshMatchesSummary = $false
if ($refreshRecord -and -not [string]::IsNullOrWhiteSpace($refreshRecord.summary_path)) {
    $refreshMatchesSummary = ([System.IO.Path]::GetFullPath($refreshRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}

$handoffMatchesSummary = $false
if ($handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffRecord.summary_path)) {
    $handoffMatchesSummary = ([System.IO.Path]::GetFullPath($handoffRecord.summary_path)).Equals([System.IO.Path]::GetFullPath($SummaryPath), [System.StringComparison]::OrdinalIgnoreCase)
}

$summaryRecordsRefreshArtifactPath = -not [string]::IsNullOrWhiteSpace($summary.refresh_chain_artifact_path)
$summaryRecordsHandoffArtifactPath = -not [string]::IsNullOrWhiteSpace($summary.handoff_artifact_path)
$summaryRecordsRefreshArtifactError = -not [string]::IsNullOrWhiteSpace($summary.refresh_chain_artifact_error)
$summaryRecordsHandoffArtifactError = -not [string]::IsNullOrWhiteSpace($summary.handoff_artifact_error)

$configuredManifestRefreshPath = if ($manifestRecord) { $manifestRecord.refresh_chain_artifact_path } else { $null }
$configuredManifestHandoffPath = if ($manifestRecord) { $manifestRecord.handoff_artifact_path } else { $null }
$manifestRecordsRefreshArtifactPath = -not [string]::IsNullOrWhiteSpace($configuredManifestRefreshPath)
$manifestRecordsHandoffArtifactPath = -not [string]::IsNullOrWhiteSpace($configuredManifestHandoffPath)
$manifestRecordsRefreshArtifactError = [bool]($manifestRecord -and -not [string]::IsNullOrWhiteSpace($manifestRecord.refresh_chain_artifact_error))
$manifestRecordsHandoffArtifactError = [bool]($manifestRecord -and -not [string]::IsNullOrWhiteSpace($manifestRecord.handoff_artifact_error))

$runnerRefreshPathFullyWired = [bool]($summaryRecordsRefreshArtifactPath -and $manifestRecordsRefreshArtifactPath)
$runnerHandoffPathFullyWired = [bool]($summaryRecordsHandoffArtifactPath -and $manifestRecordsHandoffArtifactPath)
$runnerHasExplicitTopLevelPointers = [bool]($summaryRecordsRefreshArtifactPath -and $summaryRecordsHandoffArtifactPath)
$refreshPointerRecoverable = [bool]($manifestRecordsRefreshArtifactPath -or ($refreshExists -and $refreshMatchesSummary))
$handoffPointerRecoverable = [bool]($manifestRecordsHandoffArtifactPath -or ($handoffExists -and $handoffMatchesSummary))
$repairCouldPromotePointers = [bool](((-not $summaryRecordsRefreshArtifactPath) -and $refreshPointerRecoverable) -or ((-not $summaryRecordsHandoffArtifactPath) -and $handoffPointerRecoverable))
$implicitPointerChainUsable = [bool]($repairCouldPromotePointers -and (($summaryRecordsRefreshArtifactPath -or $refreshPointerRecoverable) -and ($summaryRecordsHandoffArtifactPath -or $handoffPointerRecoverable) -and (($refreshExists -and $refreshMatchesSummary) -or ($handoffExists -and $handoffMatchesSummary))))
$pointerRepairAlreadyRan = [bool]($repairReportExists -and $repairReport -and $repairReport.status -eq 'updated')
$refreshPointerMissing = -not $summaryRecordsRefreshArtifactPath
$handoffPointerMissing = -not $summaryRecordsHandoffArtifactPath

$repairSummaryPointersCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_summary_pointers.ps1'
$repairRefreshPointerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_refresh_pointer.ps1'
$repairHandoffPointerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_handoff_pointer.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$pointerSourceCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_pointer_sources.ps1'

$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null
$reason = $null
$nextFocus = $null
$status = $null

if ($runnerHasExplicitTopLevelPointers) {
    $status = 'runner-pointers-explicit'
    $recommendedCommand = $handoffGuideCommand
    $recommendedGuideCommand = $refreshStatusCommand
    $nextArtifactToOpen = $handoffPath
    $reason = 'The saved summary already records both refresh and handoff artifact paths directly, so later helpers do not need to recover those links from the manifest or fallback discovery.'
    $nextFocus = 'Use the handoff and refresh-status helpers for the current replay instead of spending another run on pointer repair.'
} elseif ($repairCouldPromotePointers) {
    if ($pointerRepairAlreadyRan) {
        $status = 'summary-repair-landed'
        $recommendedCommand = $handoffGuideCommand
        $recommendedGuideCommand = $pointerSourceCommand
        if ($repairReportExists) {
            $nextArtifactToOpen = $repairReportPath
        } elseif ($handoffExists -and $handoffMatchesSummary) {
            $nextArtifactToOpen = $handoffPath
        } elseif ($refreshExists -and $refreshMatchesSummary) {
            $nextArtifactToOpen = $refreshPath
        } elseif ($manifestExists) {
            $nextArtifactToOpen = $manifestPath
        } else {
            $nextArtifactToOpen = $SummaryPath
        }
        $reason = 'The summary-pointer repair helper already promoted at least one missing top-level helper pointer, so the next replay should validate the refreshed handoff path instead of rerunning the same repair immediately.'
        $nextFocus = 'Reopen the pointer-source or handoff helper and confirm the saved summary now advertises the refresh and handoff artifacts directly.'
    } elseif ($implicitPointerChainUsable) {
        $status = 'runner-pointers-implicit-but-chain-usable'
        $recommendedCommand = $handoffGuideCommand
        $recommendedGuideCommand = $pointerSourceCommand
        if ($handoffExists -and $handoffMatchesSummary) {
            $nextArtifactToOpen = $handoffPath
        } elseif ($refreshExists -and $refreshMatchesSummary) {
            $nextArtifactToOpen = $refreshPath
        } elseif ($manifestExists) {
            $nextArtifactToOpen = $manifestPath
        } else {
            $nextArtifactToOpen = $SummaryPath
        }
        $reason = 'The runner summary still omits at least one top-level helper pointer, but the current manifest-backed or matching saved artifacts already keep the helper chain coherent for this summary.'
        $nextFocus = 'Continue from the current handoff or refresh helper now, and leave summary-pointer repair as follow-up cleanup instead of gating the next replay.'
    } elseif ($refreshPointerMissing -and -not $handoffPointerMissing) {
        $status = 'refresh-pointer-repair-recommended'
        $recommendedCommand = $repairRefreshPointerCommand
        $recommendedGuideCommand = $refreshStatusCommand
        if ($refreshExists -and $refreshMatchesSummary) {
            $nextArtifactToOpen = $refreshPath
        } elseif ($manifestExists) {
            $nextArtifactToOpen = $manifestPath
        } elseif ($handoffExists -and $handoffMatchesSummary) {
            $nextArtifactToOpen = $handoffPath
        } else {
            $nextArtifactToOpen = $SummaryPath
        }
        $reason = 'The runner summary still omits refresh_chain_artifact_path, but the current manifest or matching refresh artifact already provides enough state to promote that pointer with the dedicated refresh repair helper.'
        $nextFocus = 'Run the refresh-pointer repair helper, then reopen the refresh-status helper to confirm the saved summary now advertises the refresh artifact directly.'
    } elseif ($handoffPointerMissing -and -not $refreshPointerMissing) {
        $status = 'handoff-pointer-repair-recommended'
        $recommendedCommand = $repairHandoffPointerCommand
        $recommendedGuideCommand = $handoffGuideCommand
        if ($handoffExists -and $handoffMatchesSummary) {
            $nextArtifactToOpen = $handoffPath
        } elseif ($manifestExists) {
            $nextArtifactToOpen = $manifestPath
        } elseif ($refreshExists -and $refreshMatchesSummary) {
            $nextArtifactToOpen = $refreshPath
        } else {
            $nextArtifactToOpen = $SummaryPath
        }
        $reason = 'The runner summary still omits handoff_artifact_path, but the current manifest or matching handoff artifact already provides enough state to promote that pointer with the dedicated handoff repair helper.'
        $nextFocus = 'Run the handoff-pointer repair helper, then reopen the handoff helper to confirm the saved summary now advertises the handoff artifact directly.'
    } else {
        $status = 'summary-repair-recommended'
        $recommendedCommand = $repairSummaryPointersCommand
        $recommendedGuideCommand = $pointerSourceCommand
        if ($manifestExists) {
            $nextArtifactToOpen = $manifestPath
        } elseif ($refreshExists -and $refreshMatchesSummary) {
            $nextArtifactToOpen = $refreshPath
        } elseif ($handoffExists -and $handoffMatchesSummary) {
            $nextArtifactToOpen = $handoffPath
        } else {
            $nextArtifactToOpen = $SummaryPath
        }
        $reason = 'The runner output still leaves both top-level summary pointers implicit, but the manifest or matching saved helper artifacts already provide enough information to promote those links into the saved summary.'
        $nextFocus = 'Run the combined summary-pointer repair helper, then reopen the pointer-source or handoff helper to confirm the summary now advertises the refresh and handoff artifacts directly.'
    }
} else {
    $status = 'runner-rerun-needed'
    $recommendedCommand = $recommendedRunnerCommand
    $recommendedGuideCommand = $refreshStatusCommand
    $nextArtifactToOpen = $SummaryPath
    $reason = 'The saved summary is still missing top-level helper pointers and there is not enough manifest-backed or current-summary artifact state to repair them cleanly after the fact.'
    $nextFocus = 'Rerun the recommended validator so the helper chain is regenerated before trusting narrower issue #3 replay guidance.'
}

$report = [ordered]@{
    issue = 'Google issue #3 runner refresh wiring status'
    purpose = 'Audit whether the recommended runner wrote its refresh and handoff helper pointers directly into the saved summary and manifest, or whether later helper repair is still carrying that wiring.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    manifest_artifact_path = $manifestPath
    manifest_artifact_exists = [bool]$manifestExists
    refresh_artifact_path = $refreshPath
    refresh_artifact_exists = [bool]$refreshExists
    refresh_matches_summary = [bool]$refreshMatchesSummary
    handoff_artifact_path = $handoffPath
    handoff_artifact_exists = [bool]$handoffExists
    handoff_matches_summary = [bool]$handoffMatchesSummary
    repair_report_path = $repairReportPath
    repair_report_exists = [bool]$repairReportExists
    repair_report_status = if ($repairReport) { $repairReport.status } else { $null }
    summary_records_refresh_artifact_path = [bool]$summaryRecordsRefreshArtifactPath
    summary_records_handoff_artifact_path = [bool]$summaryRecordsHandoffArtifactPath
    summary_records_refresh_artifact_error = [bool]$summaryRecordsRefreshArtifactError
    summary_records_handoff_artifact_error = [bool]$summaryRecordsHandoffArtifactError
    manifest_records_refresh_artifact_path = [bool]$manifestRecordsRefreshArtifactPath
    manifest_records_handoff_artifact_path = [bool]$manifestRecordsHandoffArtifactPath
    manifest_records_refresh_artifact_error = [bool]$manifestRecordsRefreshArtifactError
    manifest_records_handoff_artifact_error = [bool]$manifestRecordsHandoffArtifactError
    runner_refresh_path_fully_wired = [bool]$runnerRefreshPathFullyWired
    runner_handoff_path_fully_wired = [bool]$runnerHandoffPathFullyWired
    runner_has_explicit_top_level_pointers = [bool]$runnerHasExplicitTopLevelPointers
    refresh_pointer_recoverable = [bool]$refreshPointerRecoverable
    handoff_pointer_recoverable = [bool]$handoffPointerRecoverable
    repair_could_promote_pointers = [bool]$repairCouldPromotePointers
    implicit_pointer_chain_usable = [bool]$implicitPointerChainUsable
    pointer_repair_already_ran = [bool]$pointerRepairAlreadyRan
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    refresh_status_command = $refreshStatusCommand
    handoff_guide_command = $handoffGuideCommand
    pointer_source_command = $pointerSourceCommand
    repair_summary_pointers_command = $repairSummaryPointersCommand
    repair_refresh_pointer_command = $repairRefreshPointerCommand
    repair_handoff_pointer_command = $repairHandoffPointerCommand
    broader_runner_command = $recommendedRunnerCommand
    next_artifact_to_open = $nextArtifactToOpen
    status = $status
    reason = $reason
    next_focus = $nextFocus
}

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 runner refresh wiring status'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Manifest exists: {0}" -f $report.manifest_artifact_exists)
Write-Host ("Refresh:   {0}" -f $report.refresh_artifact_path)
Write-Host ("Refresh exists: {0}" -f $report.refresh_artifact_exists)
Write-Host ("Refresh matches summary: {0}" -f $report.refresh_matches_summary)
Write-Host ("Handoff:   {0}" -f $report.handoff_artifact_path)
Write-Host ("Handoff exists: {0}" -f $report.handoff_artifact_exists)
Write-Host ("Handoff matches summary: {0}" -f $report.handoff_matches_summary)
Write-Host ("Repair report: {0}" -f $report.repair_report_path)
Write-Host ("Repair exists: {0}" -f $report.repair_report_exists)
if ($report.repair_report_status) {
    Write-Host ("Repair status: {0}" -f $report.repair_report_status)
}
Write-Host ("Summary refresh path recorded: {0}" -f $report.summary_records_refresh_artifact_path)
Write-Host ("Summary handoff path recorded: {0}" -f $report.summary_records_handoff_artifact_path)
Write-Host ("Manifest refresh path recorded: {0}" -f $report.manifest_records_refresh_artifact_path)
Write-Host ("Manifest handoff path recorded: {0}" -f $report.manifest_records_handoff_artifact_path)
Write-Host ("Runner refresh path fully wired: {0}" -f $report.runner_refresh_path_fully_wired)
Write-Host ("Runner handoff path fully wired: {0}" -f $report.runner_handoff_path_fully_wired)
Write-Host ("Explicit top-level pointers: {0}" -f $report.runner_has_explicit_top_level_pointers)
Write-Host ("Refresh pointer recoverable: {0}" -f $report.refresh_pointer_recoverable)
Write-Host ("Handoff pointer recoverable: {0}" -f $report.handoff_pointer_recoverable)
Write-Host ("Repair can promote pointers: {0}" -f $report.repair_could_promote_pointers)
Write-Host ("Implicit chain usable: {0}" -f $report.implicit_pointer_chain_usable)
Write-Host ("Pointer repair already ran: {0}" -f $report.pointer_repair_already_ran)
Write-Host ''
Write-Host ("Status: {0}" -f $report.status)
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
Write-Host ("Refresh repair: {0}" -f $report.repair_refresh_pointer_command)
Write-Host ("Handoff repair: {0}" -f $report.repair_handoff_pointer_command)
