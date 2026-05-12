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

function Invoke-RefreshStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [string]$ArtifactPath
    )

    $startedAt = (Get-Date).ToUniversalTime().ToString('o')
    $output = @()
    $exitCode = 0
    $errorMessage = $null

    try {
        $output = @(
            & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1
        )
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            $errorMessage = "Helper exited with code $exitCode."
        }
    } catch {
        $exitCode = 1
        $errorMessage = $_.Exception.Message
    }

    $outputLines = @($output | ForEach-Object { "${_}" })
    [pscustomobject]@{
        name = $Name
        script_path = $ScriptPath
        arguments = @($Arguments)
        started_at_utc = $startedAt
        completed_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        exit_code = $exitCode
        success = ($exitCode -eq 0)
        artifact_path = $ArtifactPath
        artifact_exists = if ($ArtifactPath) { Test-Path -LiteralPath $ArtifactPath -PathType Leaf } else { $false }
        output_preview = @($outputLines | Select-Object -First 12)
        error = $errorMessage
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

$guidePath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.guide_artifact_path -ArtifactRoot $artifactRoot -FallbackName "google-issue3-recommended-validation-guide.json"
$boundaryPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.boundary_artifact_path -ArtifactRoot $artifactRoot -FallbackName "google-issue3-phase-boundary.json"
$bundlePath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.artifact_bundle_path -ArtifactRoot $artifactRoot -FallbackName "google-issue3-validation-artifact-bundle.json"
$manifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.manifest_artifact_path -ArtifactRoot $artifactRoot -FallbackName "google-issue3-recommended-validation-manifest.json"
$manifestRecord = $null
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    try {
        $manifestRecord = Read-ArtifactJson $manifestPath
    } catch {
        $manifestRecord = $null
    }
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
$handoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredHandoffPath -ArtifactRoot $artifactRoot -FallbackName "google-issue3-validation-handoff.json"
if (-not $ArtifactPath) {
    $configuredSummaryRefreshPath = $summary.refresh_chain_artifact_path
    $configuredManifestRefreshPath = if ($manifestRecord) { $manifestRecord.refresh_chain_artifact_path } else { $null }
    $configuredRefreshPath = if (-not [string]::IsNullOrWhiteSpace($configuredSummaryRefreshPath)) {
        $configuredSummaryRefreshPath
    } elseif (-not [string]::IsNullOrWhiteSpace($configuredManifestRefreshPath)) {
        $configuredManifestRefreshPath
    } else {
        $null
    }
    $ArtifactPath = Resolve-ArtifactCandidatePath -ConfiguredPath $configuredRefreshPath -ArtifactRoot $artifactRoot -FallbackName "google-issue3-validation-handoff-chain-refresh.json"
}

$summaryGuideScript = Join-Path $PSScriptRoot "show_google_issue3_validation_summary_guide.ps1"
$boundaryScript = Join-Path $PSScriptRoot "show_google_issue3_phase_boundary.ps1"
$bundleScript = Join-Path $PSScriptRoot "show_google_issue3_validation_artifact_bundle.ps1"
$handoffScript = Join-Path $PSScriptRoot "show_google_issue3_validation_handoff.ps1"
$manifestScript = Join-Path $PSScriptRoot "show_google_issue3_validation_manifest.ps1"
$repairRefreshPointerScript = Join-Path $PSScriptRoot "repair_google_issue3_validation_refresh_pointer.ps1"
$repairHandoffPointerScript = Join-Path $PSScriptRoot "repair_google_issue3_validation_handoff_pointer.ps1"
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$repairPointerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_refresh_pointer.ps1'
$repairHandoffPointerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_handoff_pointer.ps1'

$requiredHelpers = @($summaryGuideScript, $boundaryScript, $bundleScript, $handoffScript, $manifestScript, $repairRefreshPointerScript, $repairHandoffPointerScript)
foreach ($helperPath in $requiredHelpers) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$steps = [System.Collections.Generic.List[object]]::new()
$steps.Add((Invoke-RefreshStep -Name 'summary-guide' -ScriptPath $summaryGuideScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -ArtifactPath $guidePath)) | Out-Null
$steps.Add((Invoke-RefreshStep -Name 'phase-boundary' -ScriptPath $boundaryScript -Arguments @('-SummaryPath', $SummaryPath, '-ArtifactPath', $boundaryPath, '-Json') -ArtifactPath $boundaryPath)) | Out-Null
$steps.Add((Invoke-RefreshStep -Name 'manifest' -ScriptPath $manifestScript -Arguments @('-ManifestPath', $manifestPath, '-Json') -ArtifactPath $manifestPath)) | Out-Null
$steps.Add((Invoke-RefreshStep -Name 'artifact-bundle' -ScriptPath $bundleScript -Arguments @('-SummaryPath', $SummaryPath, '-ArtifactPath', $bundlePath, '-Json') -ArtifactPath $bundlePath)) | Out-Null
$steps.Add((Invoke-RefreshStep -Name 'handoff' -ScriptPath $handoffScript -Arguments @('-SummaryPath', $SummaryPath, '-ArtifactPath', $handoffPath, '-Json') -ArtifactPath $handoffPath)) | Out-Null
$steps.Add((Invoke-RefreshStep -Name 'summary-guide-final' -ScriptPath $summaryGuideScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -ArtifactPath $guidePath)) | Out-Null
$steps.Add((Invoke-RefreshStep -Name 'phase-boundary-final' -ScriptPath $boundaryScript -Arguments @('-SummaryPath', $SummaryPath, '-ArtifactPath', $boundaryPath, '-Json') -ArtifactPath $boundaryPath)) | Out-Null
$steps.Add((Invoke-RefreshStep -Name 'manifest-final' -ScriptPath $manifestScript -Arguments @('-ManifestPath', $manifestPath, '-Json') -ArtifactPath $manifestPath)) | Out-Null
$steps.Add((Invoke-RefreshStep -Name 'artifact-bundle-final' -ScriptPath $bundleScript -Arguments @('-SummaryPath', $SummaryPath, '-ArtifactPath', $bundlePath, '-Json') -ArtifactPath $bundlePath)) | Out-Null
$steps.Add((Invoke-RefreshStep -Name 'handoff-final' -ScriptPath $handoffScript -Arguments @('-SummaryPath', $SummaryPath, '-ArtifactPath', $handoffPath, '-Json') -ArtifactPath $handoffPath)) | Out-Null

$guideRecord = Read-ArtifactJson $guidePath
$boundaryRecord = Read-ArtifactJson $boundaryPath
$bundleRecord = Read-ArtifactJson $bundlePath
$handoffRecord = Read-ArtifactJson $handoffPath
$manifestExists = Test-Path -LiteralPath $manifestPath -PathType Leaf
$failedSteps = @($steps | Where-Object { -not $_.success })
$bundleStatus = if ($bundleRecord -and $bundleRecord.status) { $bundleRecord.status } else { $null }
$handoffReady = $handoffRecord -and -not [string]::IsNullOrWhiteSpace($handoffRecord.next_artifact_to_open)

$status = if ($failedSteps.Count -gt 0) {
    'helper-failures'
} elseif (-not $manifestExists) {
    'manifest-missing'
} elseif ($bundleStatus -and $bundleStatus -ne 'complete') {
    'bundle-incomplete'
} elseif (-not $handoffReady) {
    'handoff-incomplete'
} else {
    'refreshed'
}

$recommendedCommand = if ($handoffRecord -and $handoffRecord.recommended_command) {
    $handoffRecord.recommended_command
} elseif ($bundleRecord -and $bundleRecord.recommended_command) {
    $bundleRecord.recommended_command
} else {
    $recommendedRunnerCommand
}
$recommendedGuideCommand = if ($handoffRecord -and $handoffRecord.recommended_guide_command) {
    $handoffRecord.recommended_guide_command
} elseif ($bundleRecord -and $bundleRecord.recommended_guide_command) {
    $bundleRecord.recommended_guide_command
} else {
    'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'
}
$nextArtifactToOpen = if ($handoffRecord -and $handoffRecord.next_artifact_to_open) {
    $handoffRecord.next_artifact_to_open
} elseif ($bundleRecord -and $bundleRecord.next_artifact_to_open) {
    $bundleRecord.next_artifact_to_open
} elseif ($boundaryRecord -and $boundaryRecord.next_artifact_to_open) {
    $boundaryRecord.next_artifact_to_open
} elseif ($guideRecord -and $guideRecord.first_failed_phase_primary_json_artifact_path) {
    $guideRecord.first_failed_phase_primary_json_artifact_path
} else {
    $SummaryPath
}
$nextFocus = if ($handoffRecord -and $handoffRecord.next_focus) {
    $handoffRecord.next_focus
} elseif ($bundleRecord -and $bundleRecord.next_focus) {
    $bundleRecord.next_focus
} else {
    'Refresh the saved issue #3 helper chain from the current summary before widening back out to larger replay loops.'
}
$reason = if ($failedSteps.Count -gt 0) {
    'One or more summary-derived helpers failed to refresh from the current issue #3 summary.'
} elseif (-not $manifestExists) {
    'The saved summary-derived helpers were refreshed, but the manifest is still missing and requires a rerun of the recommended validation runner.'
} elseif ($bundleStatus -and $bundleStatus -ne 'complete') {
    "The saved helper chain was refreshed twice, but the artifact-bundle audit still reports '$bundleStatus'."
} elseif (-not $handoffReady) {
    'The saved helper chain was refreshed twice, but the handoff artifact still lacks a next-artifact pointer.'
} else {
    'The saved summary-derived guide, boundary, bundle, and handoff artifacts were refreshed to a stable final state from the current issue #3 summary.'
}

$preRepairReport = [ordered]@{
    issue = 'Google issue #3 validation handoff-chain refresh'
    purpose = 'Refresh the saved summary-derived issue #3 helper artifacts until the guide, boundary, bundle, and handoff outputs reach a stable final state for the next Windows headed replay.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repo_root = $repoRoot
    summary_path = $SummaryPath
    refresh_artifact_path = $ArtifactPath
    manifest_artifact_path = $manifestPath
    manifest_exists = [bool]$manifestExists
    guide_artifact_path = $guidePath
    boundary_artifact_path = $boundaryPath
    artifact_bundle_path = $bundlePath
    handoff_artifact_path = $handoffPath
    status = $status
    surface_check_status = $summary.surface_check_status
    first_failed_phase = $summary.first_failed_phase
    failed_step_count = $failedSteps.Count
    failed_step_names = @($failedSteps | ForEach-Object { $_.name })
    bundle_status = $bundleStatus
    handoff_ready = [bool]$handoffReady
    next_artifact_to_open = $nextArtifactToOpen
    next_focus = $nextFocus
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    repair_pointer_command = $repairPointerCommand
    repair_handoff_pointer_command = $repairHandoffPointerCommand
    reason = $reason
    steps = @($steps)
}

$preRepairReport | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

$repairStep = Invoke-RefreshStep -Name 'repair-refresh-pointer' -ScriptPath $repairRefreshPointerScript -Arguments @('-SummaryPath', $SummaryPath, '-ManifestPath', $manifestPath, '-RefreshPath', $ArtifactPath, '-Json') -ArtifactPath $SummaryPath
$steps.Add($repairStep) | Out-Null
$repairHandoffStep = Invoke-RefreshStep -Name 'repair-handoff-pointer' -ScriptPath $repairHandoffPointerScript -Arguments @('-SummaryPath', $SummaryPath, '-ManifestPath', $manifestPath, '-HandoffPath', $handoffPath, '-Json') -ArtifactPath $SummaryPath
$steps.Add($repairHandoffStep) | Out-Null

$updatedSummary = Read-ArtifactJson $SummaryPath
$updatedManifest = Read-ArtifactJson $manifestPath
$summaryRefreshArtifactPath = if ($updatedSummary) { $updatedSummary.refresh_chain_artifact_path } else { $null }
$manifestRefreshArtifactPath = if ($updatedManifest) { $updatedManifest.refresh_chain_artifact_path } else { $null }
$summaryRefreshPointerRecorded = -not [string]::IsNullOrWhiteSpace($summaryRefreshArtifactPath)
$manifestRefreshPointerRecorded = -not [string]::IsNullOrWhiteSpace($manifestRefreshArtifactPath)
$summaryRefreshPointerMatches = $false
if ($summaryRefreshPointerRecorded) {
    $summaryRefreshPointerMatches = ([System.IO.Path]::GetFullPath($summaryRefreshArtifactPath)).Equals([System.IO.Path]::GetFullPath($ArtifactPath), [System.StringComparison]::OrdinalIgnoreCase)
}
$manifestRefreshPointerMatches = $false
if ($manifestRefreshPointerRecorded) {
    $manifestRefreshPointerMatches = ([System.IO.Path]::GetFullPath($manifestRefreshArtifactPath)).Equals([System.IO.Path]::GetFullPath($ArtifactPath), [System.StringComparison]::OrdinalIgnoreCase)
}
$summaryHandoffArtifactPath = if ($updatedSummary) { $updatedSummary.handoff_artifact_path } else { $null }
$manifestHandoffArtifactPath = if ($updatedManifest) { $updatedManifest.handoff_artifact_path } else { $null }
$summaryHandoffPointerRecorded = -not [string]::IsNullOrWhiteSpace($summaryHandoffArtifactPath)
$manifestHandoffPointerRecorded = -not [string]::IsNullOrWhiteSpace($manifestHandoffArtifactPath)
$summaryHandoffPointerMatches = $false
if ($summaryHandoffPointerRecorded) {
    $summaryHandoffPointerMatches = ([System.IO.Path]::GetFullPath($summaryHandoffArtifactPath)).Equals([System.IO.Path]::GetFullPath($handoffPath), [System.StringComparison]::OrdinalIgnoreCase)
}
$manifestHandoffPointerMatches = $false
if ($manifestHandoffPointerRecorded) {
    $manifestHandoffPointerMatches = ([System.IO.Path]::GetFullPath($manifestHandoffArtifactPath)).Equals([System.IO.Path]::GetFullPath($handoffPath), [System.StringComparison]::OrdinalIgnoreCase)
}
if (-not $repairStep.success) {
    $status = 'refresh-pointer-repair-failed'
    $reason = 'The helper chain report was written, but the follow-up refresh-pointer repair step failed, so later helpers may still depend on fallback refresh-location guesses.'
    $recommendedCommand = $repairPointerCommand
    $recommendedGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
    $nextArtifactToOpen = $SummaryPath
    $nextFocus = 'Repair the saved summary and manifest refresh-pointer fields before trusting downstream helper-chain guidance for the next Windows replay.'
} elseif (-not $repairHandoffStep.success) {
    $status = 'handoff-pointer-repair-failed'
    $reason = 'The helper chain report was written, but the follow-up handoff-pointer repair step failed, so later helpers may still depend on the fallback handoff location.'
    $recommendedCommand = $repairHandoffPointerCommand
    $recommendedGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
    $nextArtifactToOpen = $SummaryPath
    $nextFocus = 'Repair the saved summary and manifest handoff-pointer fields before trusting downstream handoff guidance for the next Windows replay.'
}

$report = [ordered]@{
    issue = 'Google issue #3 validation handoff-chain refresh'
    purpose = 'Refresh the saved summary-derived issue #3 helper artifacts until the guide, boundary, bundle, and handoff outputs reach a stable final state for the next Windows headed replay.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repo_root = $repoRoot
    summary_path = $SummaryPath
    refresh_artifact_path = $ArtifactPath
    manifest_artifact_path = $manifestPath
    manifest_exists = [bool]$manifestExists
    guide_artifact_path = $guidePath
    boundary_artifact_path = $boundaryPath
    artifact_bundle_path = $bundlePath
    handoff_artifact_path = $handoffPath
    status = $status
    surface_check_status = $summary.surface_check_status
    first_failed_phase = $summary.first_failed_phase
    failed_step_count = @($steps | Where-Object { -not $_.success }).Count
    failed_step_names = @($steps | Where-Object { -not $_.success } | ForEach-Object { $_.name })
    bundle_status = $bundleStatus
    handoff_ready = [bool]$handoffReady
    next_artifact_to_open = $nextArtifactToOpen
    next_focus = $nextFocus
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    repair_pointer_command = $repairPointerCommand
    repair_pointer_status = if ($repairStep.success) { 'repaired' } else { 'failed' }
    repair_pointer_exit_code = $repairStep.exit_code
    repair_pointer_error = $repairStep.error
    repair_pointer_output_preview = @($repairStep.output_preview)
    summary_records_refresh_artifact_path = [bool]$summaryRefreshPointerRecorded
    summary_refresh_artifact_path = $summaryRefreshArtifactPath
    summary_refresh_artifact_matches = [bool]$summaryRefreshPointerMatches
    manifest_records_refresh_artifact_path = [bool]$manifestRefreshPointerRecorded
    manifest_refresh_artifact_path = $manifestRefreshArtifactPath
    manifest_refresh_artifact_matches = [bool]$manifestRefreshPointerMatches
    repair_handoff_pointer_command = $repairHandoffPointerCommand
    repair_handoff_pointer_status = if ($repairHandoffStep.success) { 'repaired' } else { 'failed' }
    repair_handoff_pointer_exit_code = $repairHandoffStep.exit_code
    repair_handoff_pointer_error = $repairHandoffStep.error
    repair_handoff_pointer_output_preview = @($repairHandoffStep.output_preview)
    summary_records_handoff_artifact_path = [bool]$summaryHandoffPointerRecorded
    summary_handoff_artifact_path = $summaryHandoffArtifactPath
    summary_handoff_artifact_matches = [bool]$summaryHandoffPointerMatches
    manifest_records_handoff_artifact_path = [bool]$manifestHandoffPointerRecorded
    manifest_handoff_artifact_path = $manifestHandoffArtifactPath
    manifest_handoff_artifact_matches = [bool]$manifestHandoffPointerMatches
    reason = $reason
    steps = @($steps)
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    if ($status -ne 'refreshed') {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 validation handoff-chain refresh'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Refresh:   {0}" -f $report.refresh_artifact_path)
Write-Host ("Manifest:  {0}" -f $report.manifest_artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Surface:   {0}" -f $report.surface_check_status)
Write-Host ("First fail:{0}" -f $(if ($report.first_failed_phase) { ' ' + $report.first_failed_phase } else { ' none' }))
Write-Host ("Bundle:    {0}" -f $report.bundle_status)
Write-Host ("Handoff:   {0}" -f $report.handoff_ready)
Write-Host ("Repair:    {0}" -f $report.repair_pointer_status)
Write-Host ("Handoff repair: {0}" -f $report.repair_handoff_pointer_status)
Write-Host ("Summary refresh recorded: {0}" -f $report.summary_records_refresh_artifact_path)
Write-Host ("Manifest refresh recorded: {0}" -f $report.manifest_records_refresh_artifact_path)
Write-Host ("Summary handoff recorded: {0}" -f $report.summary_records_handoff_artifact_path)
Write-Host ("Manifest handoff recorded: {0}" -f $report.manifest_records_handoff_artifact_path)
Write-Host ''
foreach ($step in $report.steps) {
    $marker = if ($step.success) { 'PASS' } else { 'FAIL' }
    Write-Host ("[{0}] {1}" -f $marker, $step.name)
    if ($step.artifact_path) {
        Write-Host ("  Artifact: {0}" -f $step.artifact_path)
    }
    if ($step.error) {
        Write-Host ("  Error: {0}" -f $step.error)
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
Write-Host ("Repair:  {0}" -f $report.repair_pointer_command)
Write-Host ("Handoff repair: {0}" -f $report.repair_handoff_pointer_command)
Write-Host ("Broader: {0}" -f $report.broader_runner_command)

if ($report.status -ne 'refreshed') {
    exit 1
}
