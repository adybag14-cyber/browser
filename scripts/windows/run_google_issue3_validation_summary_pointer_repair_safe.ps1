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

function Invoke-JsonStep {
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
    $outputText = $null
    $record = $null
    $exitCode = 0
    $errorMessage = $null

    try {
        $output = @(
            & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1
        )
        $exitCode = $LASTEXITCODE
    } catch {
        $exitCode = 1
        $errorMessage = $_.Exception.Message
    }

    $outputText = ($output | ForEach-Object { "${_}" }) -join [Environment]::NewLine
    if (-not [string]::IsNullOrWhiteSpace($outputText)) {
        try {
            $record = $outputText | ConvertFrom-Json
        } catch {
            if (-not $errorMessage) {
                $errorMessage = 'Helper returned non-JSON output.'
            }
        }
    }

    if (-not $errorMessage -and $exitCode -ne 0) {
        if ($record) {
            $recordReason = Get-OptionalPropertyValue -Object $record -Name 'reason'
            if (-not [string]::IsNullOrWhiteSpace([string]$recordReason)) {
                $errorMessage = $recordReason
            }
        }
        if (-not $errorMessage) {
            $errorMessage = "Helper exited with code $exitCode."
        }
    }

    return [pscustomobject]@{
        name = $Name
        script_path = $ScriptPath
        arguments = @($Arguments)
        started_at_utc = $startedAt
        completed_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        exit_code = $exitCode
        success = [bool]($exitCode -eq 0 -and $record)
        expected_artifact_path = $ExpectedArtifactPath
        expected_artifact_exists = if ($ExpectedArtifactPath) { Test-Path -LiteralPath $ExpectedArtifactPath -PathType Leaf } else { $false }
        output_preview = @(($output | ForEach-Object { "${_}" }) | Select-Object -First 12)
        error = $errorMessage
        record_status = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'status' } else { $null }
        record_reason = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'reason' } else { $null }
        record_next_focus = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'next_focus' } else { $null }
        record_recommended_command = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'recommended_command' } else { $null }
        record_recommended_guide_command = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'recommended_guide_command' } else { $null }
        record_next_artifact_to_open = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'next_artifact_to_open' } else { $null }
    }
}

$repoRoot = Resolve-RepoRoot $PSScriptRoot
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json'
}
if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    throw "Issue #3 recommended validation summary not found: $SummaryPath"
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$artifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
if ([string]::IsNullOrWhiteSpace($artifactRoot)) {
    $artifactRoot = Split-Path -Parent $SummaryPath
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-summary-pointer-repair-safe.json'
}

$repairScript = Join-Path $PSScriptRoot 'repair_google_issue3_validation_summary_pointers.ps1'
$refreshSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_refresh_status_safe.ps1'
$handoffSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_handoff_safe.ps1'
$repairReportPath = Join-Path $artifactRoot 'google-issue3-summary-pointer-repair.json'

$repairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_summary_pointers.ps1'
$refreshSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe.ps1'
$handoffSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe.ps1'

foreach ($requiredPath in @($repairScript, $refreshSafeScript, $handoffSafeScript)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Issue #3 safe repair helper not found: $requiredPath"
    }
}

$steps = [System.Collections.Generic.List[object]]::new()
$repairStep = Invoke-JsonStep -Name 'repair-summary-pointers' -ScriptPath $repairScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -ExpectedArtifactPath $repairReportPath
$steps.Add($repairStep) | Out-Null

$refreshSafeStep = Invoke-JsonStep -Name 'refresh-status-safe' -ScriptPath $refreshSafeScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -ExpectedArtifactPath $null
$steps.Add($refreshSafeStep) | Out-Null

$handoffSafeStep = $null
$runHandoffSafe = [bool]($refreshSafeStep.success -and $refreshSafeStep.record_status -eq 'safe-to-run-existing-helper')
if ($runHandoffSafe) {
    $handoffSafeStep = Invoke-JsonStep -Name 'handoff-safe' -ScriptPath $handoffSafeScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -ExpectedArtifactPath $null
    $steps.Add($handoffSafeStep) | Out-Null
}

$status = $null
$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextArtifactToOpen = $null

if (-not $repairStep.success) {
    $status = 'repair-summary-pointers-failed'
    $reason = if ($repairStep.record_reason) { $repairStep.record_reason } else { 'The issue #3 summary-pointer repair step failed before the safe validation checkpoints could take over.' }
    $nextFocus = if ($repairStep.record_next_focus) { $repairStep.record_next_focus } else { 'Repair the saved summary pointers first, then reopen the safe refresh checkpoint before trusting narrower helpers.' }
    $recommendedCommand = if ($repairStep.record_recommended_command) { $repairStep.record_recommended_command } else { $repairCommand }
    $recommendedGuideCommand = if ($repairStep.record_recommended_guide_command) { $repairStep.record_recommended_guide_command } else { $refreshSafeCommand }
    $nextArtifactToOpen = if ($repairStep.record_next_artifact_to_open) { $repairStep.record_next_artifact_to_open } else { $SummaryPath }
} elseif (-not $refreshSafeStep.success) {
    $status = 'refresh-status-safe-failed'
    $reason = if ($refreshSafeStep.record_reason) { $refreshSafeStep.record_reason } else { 'The safe refresh-status checkpoint failed after summary-pointer repair.' }
    $nextFocus = if ($refreshSafeStep.record_next_focus) { $refreshSafeStep.record_next_focus } else { 'Keep the issue #3 repair flow on the safe refresh checkpoint until it reports that the narrower helper chain is ready.' }
    $recommendedCommand = if ($refreshSafeStep.record_recommended_command) { $refreshSafeStep.record_recommended_command } else { $refreshSafeCommand }
    $recommendedGuideCommand = if ($refreshSafeStep.record_recommended_guide_command) { $refreshSafeStep.record_recommended_guide_command } else { $handoffSafeCommand }
    $nextArtifactToOpen = if ($refreshSafeStep.record_next_artifact_to_open) { $refreshSafeStep.record_next_artifact_to_open } else { $SummaryPath }
} elseif (-not $runHandoffSafe) {
    $status = 'refresh-status-safe-needs-rebuild'
    $reason = if ($refreshSafeStep.record_reason) { $refreshSafeStep.record_reason } else { 'The safe refresh-status checkpoint says the helper chain still needs rebuild work before the safe handoff step should run.' }
    $nextFocus = if ($refreshSafeStep.record_next_focus) { $refreshSafeStep.record_next_focus } else { 'Follow the safe refresh guidance first instead of reopening the stricter issue #3 handoff flow.' }
    $recommendedCommand = if ($refreshSafeStep.record_recommended_command) { $refreshSafeStep.record_recommended_command } else { $refreshSafeCommand }
    $recommendedGuideCommand = if ($refreshSafeStep.record_recommended_guide_command) { $refreshSafeStep.record_recommended_guide_command } else { $handoffSafeCommand }
    $nextArtifactToOpen = if ($refreshSafeStep.record_next_artifact_to_open) { $refreshSafeStep.record_next_artifact_to_open } else { $SummaryPath }
} elseif (-not $handoffSafeStep.success) {
    $status = 'handoff-safe-failed'
    $reason = if ($handoffSafeStep.record_reason) { $handoffSafeStep.record_reason } else { 'The safe handoff checkpoint failed after the safe refresh checkpoint reported the narrower helper chain was ready.' }
    $nextFocus = if ($handoffSafeStep.record_next_focus) { $handoffSafeStep.record_next_focus } else { 'Stay on the safe handoff checkpoint until it produces a stable next-step recommendation.' }
    $recommendedCommand = if ($handoffSafeStep.record_recommended_command) { $handoffSafeStep.record_recommended_command } else { $handoffSafeCommand }
    $recommendedGuideCommand = if ($handoffSafeStep.record_recommended_guide_command) { $handoffSafeStep.record_recommended_guide_command } else { $refreshSafeCommand }
    $nextArtifactToOpen = if ($handoffSafeStep.record_next_artifact_to_open) { $handoffSafeStep.record_next_artifact_to_open } else { $SummaryPath }
} else {
    $status = 'safe-checkpoints-passed'
    $reason = 'The issue #3 summary-pointer repair completed and the safe refresh plus safe handoff checkpoints both produced current guidance for the same saved summary.'
    $nextFocus = if ($handoffSafeStep.record_next_focus) { $handoffSafeStep.record_next_focus } else { 'Use the safe handoff guidance for the next bounded Windows replay step.' }
    $recommendedCommand = if ($handoffSafeStep.record_recommended_command) { $handoffSafeStep.record_recommended_command } else { $handoffSafeCommand }
    $recommendedGuideCommand = if ($handoffSafeStep.record_recommended_guide_command) { $handoffSafeStep.record_recommended_guide_command } else { $refreshSafeCommand }
    $nextArtifactToOpen = if ($handoffSafeStep.record_next_artifact_to_open) {
        $handoffSafeStep.record_next_artifact_to_open
    } elseif ($refreshSafeStep.record_next_artifact_to_open) {
        $refreshSafeStep.record_next_artifact_to_open
    } else {
        $SummaryPath
    }
}

$report = [ordered]@{
    issue = 'Google issue #3 summary pointer repair safe wrapper'
    purpose = 'Run the summary-pointer repair and then hold the next issue #3 validation steps on the safe refresh and safe handoff checkpoints before reopening narrower helpers.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    repair_command = $repairCommand
    refresh_status_safe_command = $refreshSafeCommand
    handoff_safe_command = $handoffSafeCommand
    repair_step_success = [bool]$repairStep.success
    repair_step_status = $repairStep.record_status
    refresh_status_safe_success = [bool]$refreshSafeStep.success
    refresh_status_safe_status = $refreshSafeStep.record_status
    handoff_safe_ran = [bool]$runHandoffSafe
    handoff_safe_success = if ($handoffSafeStep) { [bool]$handoffSafeStep.success } else { $false }
    handoff_safe_status = if ($handoffSafeStep) { $handoffSafeStep.record_status } else { $null }
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_artifact_to_open = $nextArtifactToOpen
    status = $status
    reason = $reason
    next_focus = $nextFocus
    steps = @($steps)
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    if ($status -ne 'safe-checkpoints-passed') {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 summary pointer repair safe wrapper'
Write-Host ''
Write-Host ("Summary:  {0}" -f $report.summary_path)
Write-Host ("Artifact: {0}" -f $report.artifact_path)
Write-Host ("Status:   {0}" -f $report.status)
Write-Host ("Repair step: {0}" -f $report.repair_step_status)
Write-Host ("Refresh safe: {0}" -f $report.refresh_status_safe_status)
Write-Host ("Handoff safe ran: {0}" -f $report.handoff_safe_ran)
if ($report.handoff_safe_ran) {
    Write-Host ("Handoff safe: {0}" -f $report.handoff_safe_status)
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

if ($report.status -ne 'safe-checkpoints-passed') {
    exit 1
}
