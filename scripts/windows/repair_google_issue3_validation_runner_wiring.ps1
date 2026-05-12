[CmdletBinding()]
param(
    [string]$SummaryPath,
    [string]$ManifestPath,
    [string]$RefreshPath,
    [string]$HandoffPath,
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

function Invoke-HelperJsonStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [string]$ExpectedArtifactPath
    )

    $startedAt = (Get-Date).ToUniversalTime().ToString('o')
    $output = @()
    $exitCode = 0
    $errorMessage = $null
    $jsonRecord = $null

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
    $outputText = $outputLines -join [Environment]::NewLine
    if (-not [string]::IsNullOrWhiteSpace($outputText)) {
        try {
            $jsonRecord = $outputText | ConvertFrom-Json
        } catch {
            if (-not $errorMessage) {
                $errorMessage = 'Helper returned non-JSON output.'
            }
        }
    } elseif (-not $errorMessage) {
        $errorMessage = 'Helper produced no output.'
    }

    [pscustomobject]@{
        name = $Name
        script_path = $ScriptPath
        arguments = @($Arguments)
        started_at_utc = $startedAt
        completed_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        exit_code = $exitCode
        success = ($exitCode -eq 0)
        expected_artifact_path = $ExpectedArtifactPath
        expected_artifact_exists = if ($ExpectedArtifactPath) { Test-Path -LiteralPath $ExpectedArtifactPath -PathType Leaf } else { $false }
        error = $errorMessage
        output_preview = @($outputLines | Select-Object -First 12)
        json_record = $jsonRecord
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
if (-not $ManifestPath) {
    $ManifestPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.manifest_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-recommended-validation-manifest.json'
}
if (-not $RefreshPath) {
    $RefreshPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.refresh_chain_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
}
if (-not $HandoffPath) {
    $HandoffPath = Resolve-ArtifactCandidatePath -ConfiguredPath $summary.handoff_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-validation-runner-wiring-repair.json'
}

$summaryPointerRepairScript = Join-Path $PSScriptRoot 'repair_google_issue3_validation_summary_pointers.ps1'
$refreshPointerRepairScript = Join-Path $PSScriptRoot 'repair_google_issue3_validation_refresh_pointer.ps1'
$handoffPointerRepairScript = Join-Path $PSScriptRoot 'repair_google_issue3_validation_handoff_pointer.ps1'
$repairDependencyScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_repair_dependency.ps1'
foreach ($helperPath in @($summaryPointerRepairScript, $refreshPointerRepairScript, $handoffPointerRepairScript, $repairDependencyScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$summaryPointerRepairArtifactPath = Join-Path $artifactRoot 'google-issue3-summary-pointer-repair.json'
$steps = [System.Collections.Generic.List[object]]::new()
$steps.Add((Invoke-HelperJsonStep -Name 'summary-pointer-repair' -ScriptPath $summaryPointerRepairScript -Arguments @('-SummaryPath', $SummaryPath, '-ArtifactPath', $summaryPointerRepairArtifactPath, '-Json') -ExpectedArtifactPath $summaryPointerRepairArtifactPath)) | Out-Null
$steps.Add((Invoke-HelperJsonStep -Name 'refresh-pointer-repair' -ScriptPath $refreshPointerRepairScript -Arguments @('-SummaryPath', $SummaryPath, '-ManifestPath', $ManifestPath, '-RefreshPath', $RefreshPath, '-Json') -ExpectedArtifactPath $SummaryPath)) | Out-Null
$steps.Add((Invoke-HelperJsonStep -Name 'handoff-pointer-repair' -ScriptPath $handoffPointerRepairScript -Arguments @('-SummaryPath', $SummaryPath, '-ManifestPath', $ManifestPath, '-HandoffPath', $HandoffPath, '-Json') -ExpectedArtifactPath $SummaryPath)) | Out-Null
$steps.Add((Invoke-HelperJsonStep -Name 'runner-repair-dependency' -ScriptPath $repairDependencyScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -ExpectedArtifactPath $null)) | Out-Null

$failedSteps = @($steps | Where-Object { -not $_.success })
$dependencyStep = @($steps | Where-Object { $_.name -eq 'runner-repair-dependency' } | Select-Object -First 1)
$dependencyReport = if ($dependencyStep.Count -gt 0) { $dependencyStep[0].json_record } else { $null }

$status = if ($dependencyReport -and $dependencyReport.state) {
    $dependencyReport.state
} elseif ($failedSteps.Count -gt 0) {
    'repair-failed'
} else {
    'repair-completed'
}
$reason = if ($failedSteps.Count -gt 0) {
    'One or more runner-wiring repair helpers failed, so inspect the saved step previews before trusting the narrower issue #3 replay handoff.'
} elseif ($dependencyReport -and $dependencyReport.reason) {
    $dependencyReport.reason
} else {
    'The issue #3 runner-wiring repair chain completed without helper failures.'
}
$nextFocus = if ($failedSteps.Count -gt 0) {
    'Inspect the failed repair step output first, then rerun this helper once the missing summary, refresh, or handoff artifact is available again.'
} elseif ($dependencyReport -and $dependencyReport.next_focus) {
    $dependencyReport.next_focus
} else {
    'Open the repaired issue #3 handoff or refresh helper and continue with the next bounded replay step.'
}
$recommendedCommand = if ($failedSteps.Count -gt 0) {
    'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
} elseif ($dependencyReport -and $dependencyReport.recommended_command) {
    $dependencyReport.recommended_command
} else {
    'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
}
$recommendedGuideCommand = if ($failedSteps.Count -gt 0) {
    'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle.ps1'
} elseif ($dependencyReport -and $dependencyReport.recommended_guide_command) {
    $dependencyReport.recommended_guide_command
} else {
    'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
}
$nextArtifactToOpen = if ($failedSteps.Count -gt 0) {
    if ($failedSteps[0].expected_artifact_path) {
        $failedSteps[0].expected_artifact_path
    } else {
        $SummaryPath
    }
} elseif ($dependencyReport -and $dependencyReport.next_artifact_to_open) {
    $dependencyReport.next_artifact_to_open
} else {
    $SummaryPath
}

$report = [ordered]@{
    issue = 'Google issue #3 runner wiring repair'
    purpose = 'Run the saved summary-pointer, refresh-pointer, and handoff-pointer repairs in one pass, then report whether the current issue #3 helper chain is now self-contained or still repair-dependent.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    manifest_path = $ManifestPath
    refresh_artifact_path = $RefreshPath
    handoff_artifact_path = $HandoffPath
    artifact_path = $ArtifactPath
    status = $status
    failed_step_count = $failedSteps.Count
    failed_step_names = @($failedSteps | ForEach-Object { $_.name })
    runner_repair_dependency_state = if ($dependencyReport) { $dependencyReport.state } else { $null }
    runner_self_contained = if ($dependencyReport) { [bool]$dependencyReport.runner_self_contained } else { $false }
    repair_dependent = if ($dependencyReport) { [bool]$dependencyReport.repair_dependent } else { $false }
    repair_needed = if ($dependencyReport) { [bool]$dependencyReport.repair_needed } else { $false }
    wiring_gap_count = if ($dependencyReport -and $null -ne $dependencyReport.wiring_gap_count) { [int]$dependencyReport.wiring_gap_count } else { $null }
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_artifact_to_open = $nextArtifactToOpen
    reason = $reason
    next_focus = $nextFocus
    steps = @($steps)
}

$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    if ($failedSteps.Count -gt 0 -or $status -eq 'repair-needed') {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 runner wiring repair'
Write-Host ''
Write-Host ("Summary:  {0}" -f $report.summary_path)
Write-Host ("Manifest: {0}" -f $report.manifest_path)
Write-Host ("Refresh:  {0}" -f $report.refresh_artifact_path)
Write-Host ("Handoff:  {0}" -f $report.handoff_artifact_path)
Write-Host ("Report:   {0}" -f $report.artifact_path)
Write-Host ("Status:   {0}" -f $report.status)
Write-Host ("Runner self-contained: {0}" -f $report.runner_self_contained)
Write-Host ("Repair-dependent: {0}" -f $report.repair_dependent)
Write-Host ("Repair needed: {0}" -f $report.repair_needed)
Write-Host ("Wiring gap count: {0}" -f $(if ($null -ne $report.wiring_gap_count) { $report.wiring_gap_count } else { 'n/a' }))
if ($report.failed_step_count -gt 0) {
    Write-Host ("Failed steps: {0}" -f ($report.failed_step_names -join ', '))
}
Write-Host ''
foreach ($step in $report.steps) {
    $marker = if ($step.success) { 'PASS' } else { 'FAIL' }
    Write-Host ("[{0}] {1}" -f $marker, $step.name)
    if ($step.expected_artifact_path) {
        Write-Host ("  Artifact: {0}" -f $step.expected_artifact_path)
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

if ($report.failed_step_count -gt 0 -or $report.status -eq 'repair-needed') {
    exit 1
}
