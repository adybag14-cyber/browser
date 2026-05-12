[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$SummaryPath,
    [string]$RepairArtifactPath,
    [string]$ArtifactPath,
    [switch]$Json,
    [Parameter(ValueFromRemainingArguments = $true)]
    [object[]]$RunnerArguments
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

function Convert-CommandOutputToText {
    param([object[]]$Output)

    return ($Output | ForEach-Object { "${_}" }) -join [Environment]::NewLine
}

$wrapperCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_with_contract_repair.ps1'
$runnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$repairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1'
$wiringStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$patchTargetsCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'

if (-not $RepoRoot) {
    $RepoRoot = Resolve-RepoRoot $PSScriptRoot
}

$artifactRoot = Join-Path $RepoRoot "tmp-browser-smoke\headed-probe"
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-summary.json'
}
if (-not $RepairArtifactPath) {
    $RepairArtifactPath = Join-Path $artifactRoot 'google-issue3-runner-output-contract-repair.json'
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-with-contract-repair.json'
}

$runnerScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation.ps1'
$repairScript = Join-Path $PSScriptRoot 'repair_google_issue3_runner_output_contract.ps1'
$wiringStatusScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_wiring_status.ps1'
foreach ($scriptPath in @($runnerScript, $repairScript, $wiringStatusScript)) {
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        throw "Issue #3 validation wrapper dependency not found: $scriptPath"
    }
}

$runnerInvocationArgs = New-Object System.Collections.Generic.List[object]
$runnerInvocationArgs.Add('-RepoRoot') | Out-Null
$runnerInvocationArgs.Add($RepoRoot) | Out-Null
if (-not [string]::IsNullOrWhiteSpace($BrowserExe)) {
    $runnerInvocationArgs.Add('-BrowserExe') | Out-Null
    $runnerInvocationArgs.Add($BrowserExe) | Out-Null
}
if (-not [string]::IsNullOrWhiteSpace($SummaryPath)) {
    $runnerInvocationArgs.Add('-SummaryPath') | Out-Null
    $runnerInvocationArgs.Add($SummaryPath) | Out-Null
}
foreach ($argument in @($RunnerArguments)) {
    $runnerInvocationArgs.Add($argument) | Out-Null
}

$runnerStatus = 'passed'
$runnerError = $null
try {
    & $runnerScript @runnerInvocationArgs
} catch {
    $runnerStatus = 'failed'
    $runnerError = $_.Exception.Message
}

$summaryExists = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$repairStatus = 'skipped'
$repairError = $null
$repairRecord = $null
$wiringStatus = 'skipped'
$wiringError = $null
$wiringRecord = $null

if ($summaryExists) {
    try {
        $repairOutput = @(
            & $repairScript -SummaryPath $SummaryPath -ArtifactPath $RepairArtifactPath -Json 2>&1
        )
        $repairText = Convert-CommandOutputToText -Output $repairOutput
        if ([string]::IsNullOrWhiteSpace($repairText)) {
            throw 'Issue #3 runner contract repair helper produced no JSON output.'
        }

        $repairRecord = $repairText | ConvertFrom-Json
        $repairStatus = 'completed'
    } catch {
        $repairStatus = 'failed'
        $repairError = $_.Exception.Message
    }

    try {
        $wiringOutput = @(
            & $wiringStatusScript -SummaryPath $SummaryPath -Json 2>&1
        )
        $wiringText = Convert-CommandOutputToText -Output $wiringOutput
        if ([string]::IsNullOrWhiteSpace($wiringText)) {
            throw 'Issue #3 runner wiring helper produced no JSON output.'
        }

        $wiringRecord = $wiringText | ConvertFrom-Json
        $wiringStatus = 'completed'
    } catch {
        $wiringStatus = 'failed'
        $wiringError = $_.Exception.Message
    }
}

$reason = $null
$nextFocus = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
if (-not $summaryExists) {
    $reason = 'The recommended validation runner did not leave a summary artifact, so the contract repair and post-run wiring audit could not continue.'
    $nextFocus = 'Inspect the runner failure first, then rerun the wrapper once the bounded validation ladder can emit its saved summary.'
    $recommendedCommand = $runnerCommand
    $recommendedGuideCommand = $null
} elseif ($repairStatus -eq 'failed') {
    $reason = 'The broader recommended runner completed far enough to write a summary, but the contract repair helper failed before the wrapper could normalize the saved runner-output fields.'
    $nextFocus = 'Inspect the repair helper failure and reopen the runner-output patch-target guidance before trusting later handoff helpers.'
    $recommendedCommand = $patchTargetsCommand
    $recommendedGuideCommand = $repairCommand
} elseif ($wiringStatus -eq 'failed') {
    $reason = 'The broader recommended runner and the contract repair helper completed, but the wrapper could not reopen the saved wiring audit for the current summary.'
    $nextFocus = 'Inspect the wiring helper failure and rerun the audit before widening back out to later handoff or refresh helpers.'
    $recommendedCommand = $wiringStatusCommand
    $recommendedGuideCommand = $repairCommand
} elseif ($wiringRecord) {
    $reason = if ($wiringRecord.reason) { $wiringRecord.reason } else { 'The wrapper reran the broader validation flow and reopened the runner-output wiring audit for the current summary.' }
    $nextFocus = if ($wiringRecord.next_focus) { $wiringRecord.next_focus } else { 'Use the saved wiring audit to decide whether the next replay should stay on runner-output contract work or move on to the narrower refresh or handoff helpers.' }
    $recommendedCommand = if ($wiringRecord.recommended_command) { $wiringRecord.recommended_command } else { $wiringStatusCommand }
    $recommendedGuideCommand = if ($wiringRecord.recommended_guide_command) { $wiringRecord.recommended_guide_command } else { $repairCommand }
} else {
    $reason = 'The wrapper completed without reopening a wiring audit record, so the safest next step is to inspect the saved summary and rerun the audit directly.'
    $nextFocus = 'Open the saved summary and rerun the runner-output wiring helper before trusting narrower issue #3 guidance.'
    $recommendedCommand = $wiringStatusCommand
    $recommendedGuideCommand = $repairCommand
}

$report = [ordered]@{
    issue = 'Google issue #3 recommended validation with contract repair'
    purpose = 'Run the bounded recommended-validation ladder, then normalize and audit the saved runner-output contract before the next narrowed issue #3 replay.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repo_root = $RepoRoot
    browser_exe = $BrowserExe
    summary_path = $SummaryPath
    summary_exists = [bool]$summaryExists
    repair_artifact_path = $RepairArtifactPath
    artifact_path = $ArtifactPath
    wrapper_command = $wrapperCommand
    broader_runner_command = $runnerCommand
    repair_command = $repairCommand
    wiring_status_command = $wiringStatusCommand
    patch_targets_command = $patchTargetsCommand
    runner_status = $runnerStatus
    runner_error = $runnerError
    repair_status = $repairStatus
    repair_error = $repairError
    repair_report_status = if ($repairRecord) { $repairRecord.status } else { $null }
    repair_report_reason = if ($repairRecord) { $repairRecord.reason } else { $null }
    repair_report_path = if ($repairRecord) { $repairRecord.artifact_path } else { $RepairArtifactPath }
    wiring_status = $wiringStatus
    wiring_error = $wiringError
    wiring_audit_status = if ($wiringRecord) { $wiringRecord.status } else { $null }
    missing_runner_fields = if ($wiringRecord) { @($wiringRecord.missing_runner_fields) } else { @() }
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    reason = $reason
    next_focus = $nextFocus
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host 'Google issue #3 recommended validation with contract repair'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Summary exists: {0}" -f $report.summary_exists)
Write-Host ("Report:    {0}" -f $report.artifact_path)
Write-Host ("Repair:    {0}" -f $report.repair_artifact_path)
Write-Host ("Runner status: {0}" -f $report.runner_status)
if ($report.runner_error) {
    Write-Host ("Runner error: {0}" -f $report.runner_error)
}
Write-Host ("Repair status: {0}" -f $report.repair_status)
if ($report.repair_error) {
    Write-Host ("Repair error: {0}" -f $report.repair_error)
}
Write-Host ("Wiring status: {0}" -f $report.wiring_status)
if ($report.wiring_error) {
    Write-Host ("Wiring error: {0}" -f $report.wiring_error)
}
if ($report.wiring_audit_status) {
    Write-Host ("Wiring audit: {0}" -f $report.wiring_audit_status)
}
if ($report.missing_runner_fields.Count -gt 0) {
    Write-Host 'Missing runner fields:'
    foreach ($fieldName in $report.missing_runner_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Run:    {0}" -f $report.recommended_command)
if ($report.recommended_guide_command) {
    Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
}

if ($runnerStatus -eq 'failed') {
    throw ("Google issue #3 recommended validation failed before the wrapper could finish cleanly. Summary: {0}. Wrapper report: {1}. Repair report: {2}." -f $SummaryPath, $ArtifactPath, $RepairArtifactPath)
}
if ($repairStatus -eq 'failed') {
    throw ("Google issue #3 runner-output contract repair failed after the broader validation run. Summary: {0}. Wrapper report: {1}. Repair report: {2}." -f $SummaryPath, $ArtifactPath, $RepairArtifactPath)
}
if ($wiringStatus -eq 'failed') {
    throw ("Google issue #3 runner-output wiring audit failed after the broader validation and repair chain. Summary: {0}. Wrapper report: {1}." -f $SummaryPath, $ArtifactPath)
}
