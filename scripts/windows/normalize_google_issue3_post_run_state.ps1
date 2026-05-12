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
        if (Test-Path (Join-Path $cursor 'build.zig')) {
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

function Invoke-Issue3Helper {
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
    $record = $null

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
    if ($exitCode -eq 0) {
        if ([string]::IsNullOrWhiteSpace($outputText)) {
            $exitCode = 1
            $errorMessage = 'Helper produced no JSON output.'
        } else {
            try {
                $record = $outputText | ConvertFrom-Json
            } catch {
                $exitCode = 1
                $errorMessage = 'Helper returned non-JSON output.'
            }
        }
    }

    return [pscustomobject]@{
        name = $Name
        script_path = $ScriptPath
        arguments = @($Arguments)
        started_at_utc = $startedAt
        completed_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        exit_code = $exitCode
        success = ($exitCode -eq 0 -and $record -ne $null)
        artifact_path = $ArtifactPath
        artifact_exists = if ($ArtifactPath) { Test-Path -LiteralPath $ArtifactPath -PathType Leaf } else { $false }
        output_preview = @($outputLines | Select-Object -First 12)
        error = $errorMessage
        record = $record
    }
}

$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json'
}

if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    $report = [ordered]@{
        issue = 'Google issue #3 post-run state normalization'
        purpose = 'Normalize the saved issue #3 runner outputs and helper-chain state after a bounded Windows replay so the next replay can trust the narrowed follow-up guidance.'
        generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        summary_path = $SummaryPath
        summary_exists = $false
        status = 'summary-missing'
        recommended_command = $recommendedRunnerCommand
        recommended_guide_command = $summaryGuideCommand
        next_artifact_to_open = $SummaryPath
        reason = 'No saved issue #3 recommended-validation summary exists yet, so there is no post-run state to normalize.'
        next_focus = 'Run the bounded issue #3 validation runner first, then rerun this normalizer to repair the saved runner contract and helper chain.'
        steps = @()
    }

    if (-not $ArtifactPath) {
        $ArtifactPath = Join-Path (Split-Path -Parent $SummaryPath) 'google-issue3-post-run-state-normalization.json'
    }
    $report.artifact_path = $ArtifactPath
    $report | ConvertTo-Json -Depth 7 | Set-Content -Path $ArtifactPath -Encoding Ascii

    if ($Json) {
        $report | ConvertTo-Json -Depth 7
        exit 1
    }

    Write-Host 'Google issue #3 post-run state normalization'
    Write-Host ''
    Write-Host ("Summary: {0}" -f $report.summary_path)
    Write-Host ("Status:  {0}" -f $report.status)
    Write-Host ("Reason:  {0}" -f $report.reason)
    Write-Host ("Focus:   {0}" -f $report.next_focus)
    Write-Host ("Run:     {0}" -f $report.recommended_command)
    Write-Host ("Guide:   {0}" -f $report.recommended_guide_command)
    exit 1
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$artifactRoot = if (-not [string]::IsNullOrWhiteSpace($summary.artifact_root)) {
    $summary.artifact_root
} else {
    Split-Path -Parent $SummaryPath
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-post-run-state-normalization.json'
}

$repairContractScript = Join-Path $PSScriptRoot 'repair_google_issue3_runner_output_contract.ps1'
$wiringStatusScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_wiring_status.ps1'
$refreshChainScript = Join-Path $PSScriptRoot 'refresh_google_issue3_validation_handoff_chain.ps1'
$refreshStatusScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_refresh_status.ps1'
$handoffCoherencyScript = Join-Path $PSScriptRoot 'show_google_issue3_handoff_path_coherency.ps1'
$handoffScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_handoff.ps1'

$requiredHelpers = @(
    $repairContractScript,
    $wiringStatusScript,
    $refreshChainScript,
    $refreshStatusScript,
    $handoffCoherencyScript,
    $handoffScript
)
foreach ($helperPath in $requiredHelpers) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$steps = [System.Collections.Generic.List[object]]::new()
$repairReportPath = Resolve-ArtifactCandidatePath -ConfiguredPath $null -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-runner-output-contract-repair.json'
$repairStep = Invoke-Issue3Helper -Name 'repair-runner-output-contract' -ScriptPath $repairContractScript -Arguments @('-SummaryPath', $SummaryPath, '-ArtifactPath', $repairReportPath, '-Json') -ArtifactPath $repairReportPath
$steps.Add($repairStep) | Out-Null

$repairRecord = $repairStep.record
$refreshArtifactPath = if ($repairRecord -and -not [string]::IsNullOrWhiteSpace($repairRecord.resolved_refresh_artifact_path)) {
    $repairRecord.resolved_refresh_artifact_path
} else {
    Resolve-ArtifactCandidatePath -ConfiguredPath $summary.refresh_chain_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff-chain-refresh.json'
}
$handoffArtifactPath = if ($repairRecord -and -not [string]::IsNullOrWhiteSpace($repairRecord.resolved_handoff_artifact_path)) {
    $repairRecord.resolved_handoff_artifact_path
} else {
    Resolve-ArtifactCandidatePath -ConfiguredPath $summary.handoff_artifact_path -ArtifactRoot $artifactRoot -FallbackName 'google-issue3-validation-handoff.json'
}

$wiringStep = Invoke-Issue3Helper -Name 'runner-output-wiring-status' -ScriptPath $wiringStatusScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -ArtifactPath $SummaryPath
$steps.Add($wiringStep) | Out-Null

$refreshChainStep = Invoke-Issue3Helper -Name 'refresh-handoff-chain' -ScriptPath $refreshChainScript -Arguments @('-SummaryPath', $SummaryPath, '-ArtifactPath', $refreshArtifactPath, '-Json') -ArtifactPath $refreshArtifactPath
$steps.Add($refreshChainStep) | Out-Null

$refreshStatusStep = Invoke-Issue3Helper -Name 'validation-refresh-status' -ScriptPath $refreshStatusScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -ArtifactPath $refreshArtifactPath
$steps.Add($refreshStatusStep) | Out-Null

$coherencyStep = Invoke-Issue3Helper -Name 'handoff-path-coherency' -ScriptPath $handoffCoherencyScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -ArtifactPath $handoffArtifactPath
$steps.Add($coherencyStep) | Out-Null

$coherencyRecord = $coherencyStep.record
if ($coherencyRecord -and -not [string]::IsNullOrWhiteSpace($coherencyRecord.resolved_handoff_artifact_path)) {
    $handoffArtifactPath = $coherencyRecord.resolved_handoff_artifact_path
}

$handoffStep = Invoke-Issue3Helper -Name 'validation-handoff' -ScriptPath $handoffScript -Arguments @('-SummaryPath', $SummaryPath, '-ArtifactPath', $handoffArtifactPath, '-Json') -ArtifactPath $handoffArtifactPath
$steps.Add($handoffStep) | Out-Null

$wiringRecord = $wiringStep.record
$refreshStatusRecord = $refreshStatusStep.record
$handoffRecord = $handoffStep.record

$failedSteps = @($steps | Where-Object { -not $_.success })
$runnerContractReady = [bool]($wiringRecord -and $wiringRecord.runner_outputs_fully_wired)
$refreshReady = [bool]($refreshStatusRecord -and $refreshStatusRecord.status -eq 'ready')
$handoffPathCoherent = [bool]($coherencyRecord -and $coherencyRecord.path_coherent)
$handoffReady = [bool]($handoffRecord -and $handoffRecord.artifact_chain_coherent -and -not [string]::IsNullOrWhiteSpace($handoffRecord.next_artifact_to_open))

$status = if ($failedSteps.Count -eq 0 -and $runnerContractReady -and $refreshReady -and $handoffPathCoherent -and $handoffReady) {
    'normalized'
} else {
    'needs-followup'
}

$reason = if ($failedSteps.Count -gt 0) {
    'One or more saved issue #3 post-run normalization helpers failed, so the runner outputs or helper chain still need direct follow-up.'
} elseif (-not $runnerContractReady) {
    'The recommended runner outputs still do not expose the full direct refresh and handoff contract in both the saved summary and manifest.'
} elseif (-not $refreshReady) {
    'The saved helper chain still recommends another refresh pass before trusting the narrower handoff guidance.'
} elseif (-not $handoffPathCoherent) {
    'The saved handoff path is still not coherent enough to trust as the single write target for the next narrowed replay.'
} elseif (-not $handoffReady) {
    'The saved handoff artifact still does not expose a stable next_artifact_to_open pointer for the next narrowed replay.'
} else {
    'The saved issue #3 runner contract, helper-chain refresh state, and handoff path all look coherent enough for the next narrowed Windows replay.'
}

$recommendedCommand = if ($handoffRecord -and $handoffRecord.recommended_command) {
    $handoffRecord.recommended_command
} elseif ($refreshStatusRecord -and $refreshStatusRecord.recommended_command) {
    $refreshStatusRecord.recommended_command
} elseif ($wiringRecord -and $wiringRecord.recommended_command) {
    $wiringRecord.recommended_command
} else {
    $recommendedRunnerCommand
}
$recommendedGuideCommand = if ($handoffRecord -and $handoffRecord.recommended_guide_command) {
    $handoffRecord.recommended_guide_command
} elseif ($refreshStatusRecord -and $refreshStatusRecord.recommended_guide_command) {
    $refreshStatusRecord.recommended_guide_command
} elseif ($coherencyRecord -and $coherencyRecord.recommended_guide_command) {
    $coherencyRecord.recommended_guide_command
} else {
    'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
}
$nextArtifactToOpen = if ($handoffRecord -and $handoffRecord.next_artifact_to_open) {
    $handoffRecord.next_artifact_to_open
} elseif ($refreshStatusRecord -and $refreshStatusRecord.next_artifact_to_open) {
    $refreshStatusRecord.next_artifact_to_open
} elseif ($coherencyRecord -and $coherencyRecord.next_artifact_to_open) {
    $coherencyRecord.next_artifact_to_open
} else {
    $SummaryPath
}
$nextFocus = if ($handoffRecord -and $handoffRecord.next_focus) {
    $handoffRecord.next_focus
} elseif ($refreshStatusRecord -and $refreshStatusRecord.next_focus) {
    $refreshStatusRecord.next_focus
} elseif ($wiringRecord -and $wiringRecord.next_focus) {
    $wiringRecord.next_focus
} else {
    'Keep the next Windows replay on the saved issue #3 handoff artifact instead of reopening the broader runner unless the normalized state regresses.'
}

$report = [ordered]@{
    issue = 'Google issue #3 post-run state normalization'
    purpose = 'Normalize the saved issue #3 runner outputs and helper-chain state after a bounded Windows replay so the next replay can trust the narrowed follow-up guidance.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repo_root = $repoRoot
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    repair_report_path = $repairReportPath
    refresh_artifact_path = $refreshArtifactPath
    handoff_artifact_path = $handoffArtifactPath
    status = $status
    failed_step_count = $failedSteps.Count
    failed_step_names = @($failedSteps | ForEach-Object { $_.name })
    runner_contract_ready = [bool]$runnerContractReady
    refresh_ready = [bool]$refreshReady
    handoff_path_coherent = [bool]$handoffPathCoherent
    handoff_ready = [bool]$handoffReady
    runner_output_status = if ($wiringRecord) { $wiringRecord.status } else { $null }
    refresh_status = if ($refreshStatusRecord) { $refreshStatusRecord.status } else { $null }
    handoff_status = if ($handoffRecord) { if ($handoffRecord.artifact_chain_coherent) { 'coherent' } else { 'needs-followup' } } else { $null }
    explicit_handoff_artifact_path_required = if ($coherencyRecord) { [bool]$coherencyRecord.explicit_artifact_path_required } else { $null }
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    next_artifact_to_open = $nextArtifactToOpen
    reason = $reason
    next_focus = $nextFocus
    steps = @($steps | ForEach-Object {
        [pscustomobject]@{
            name = $_.name
            success = $_.success
            exit_code = $_.exit_code
            artifact_path = $_.artifact_path
            artifact_exists = $_.artifact_exists
            error = $_.error
            output_preview = @($_.output_preview)
        }
    })
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    if ($status -ne 'normalized') {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 post-run state normalization'
Write-Host ''
Write-Host ("Summary:  {0}" -f $report.summary_path)
Write-Host ("Report:   {0}" -f $report.artifact_path)
Write-Host ("Repair:   {0}" -f $report.repair_report_path)
Write-Host ("Refresh:  {0}" -f $report.refresh_artifact_path)
Write-Host ("Handoff:  {0}" -f $report.handoff_artifact_path)
Write-Host ("Status:   {0}" -f $report.status)
Write-Host ("Contract: {0}" -f $report.runner_contract_ready)
Write-Host ("Refresh ready: {0}" -f $report.refresh_ready)
Write-Host ("Handoff coherent: {0}" -f $report.handoff_path_coherent)
Write-Host ("Handoff ready: {0}" -f $report.handoff_ready)
if ($report.failed_step_count -gt 0) {
    Write-Host ("Failed steps: {0}" -f ($report.failed_step_names -join ', '))
}
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
Write-Host ("Broader: {0}" -f $report.broader_runner_command)

if ($report.status -ne 'normalized') {
    exit 1
}
