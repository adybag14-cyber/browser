[CmdletBinding()]
param(
    [string]$SummaryPath,
    [string]$ArtifactPath,
    [string[]]$RunnerArgument,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

function Get-OptionalPropertyValue {
    param(
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($Object -and $Object.PSObject.Properties[$Name]) {
        return $Object.$Name
    }

    return $null
}

function Get-FirstNonEmptyValue {
    param([object[]]$Values)

    foreach ($value in $Values) {
        if ($null -eq $value) {
            continue
        }

        if ($value -is [string]) {
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                return $value
            }
            continue
        }

        return $value
    }

    return $null
}

function Invoke-ScriptStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [switch]$ExpectJson
    )

    $startedAt = (Get-Date).ToUniversalTime().ToString('o')
    $output = @()
    $exitCode = 0
    $errorMessage = $null
    $parseError = $null
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
    $outputText = ($outputLines -join [Environment]::NewLine).Trim()
    if ($ExpectJson -and -not [string]::IsNullOrWhiteSpace($outputText)) {
        try {
            $record = $outputText | ConvertFrom-Json
        } catch {
            $parseError = $_.Exception.Message
        }
    }

    $success = if ($ExpectJson) {
        [bool]($exitCode -eq 0 -and $null -ne $record)
    } else {
        [bool]($exitCode -eq 0)
    }

    $status = if ($record) {
        Get-OptionalPropertyValue -Object $record -Name 'status'
    } elseif ($parseError) {
        'non-json-output'
    } elseif ($success) {
        'completed'
    } else {
        'failed'
    }

    return [pscustomobject]@{
        name = $Name
        script_path = $ScriptPath
        arguments = @($Arguments)
        started_at_utc = $startedAt
        completed_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        exit_code = $exitCode
        success = [bool]$success
        status = $status
        parse_error = $parseError
        error = $errorMessage
        output_preview = @($outputLines | Select-Object -First 16)
        recommended_command = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'recommended_command' } else { $null }
        recommended_guide_command = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'recommended_guide_command' } else { $null }
        next_focus = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'next_focus' } else { $null }
        next_artifact_to_open = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'next_artifact_to_open' } else { $null }
        reason = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'reason' } else { $null }
        record = $record
    }
}

function New-SkippedStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [string]$Reason,
        [string]$RecommendedCommand,
        [string]$RecommendedGuideCommand,
        [string]$NextFocus,
        [string]$NextArtifactToOpen
    )

    $timestamp = (Get-Date).ToUniversalTime().ToString('o')
    return [pscustomobject]@{
        name = $Name
        script_path = $ScriptPath
        arguments = @($Arguments)
        started_at_utc = $timestamp
        completed_at_utc = $timestamp
        exit_code = 0
        success = $true
        status = 'skipped'
        parse_error = $null
        error = $null
        output_preview = @()
        recommended_command = $RecommendedCommand
        recommended_guide_command = $RecommendedGuideCommand
        next_focus = $NextFocus
        next_artifact_to_open = $NextArtifactToOpen
        reason = $Reason
        record = $null
    }
}

$repoRoot = Resolve-RepoRoot $PSScriptRoot
$artifactRoot = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe'
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-summary.json'
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-runner-output-contract-wiring-safe.json'
}

$broaderRunnerScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation.ps1'
$contractRepairScript = Join-Path $PSScriptRoot 'repair_google_issue3_runner_output_contract.ps1'
$runnerWiringSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_wiring_status_safe.ps1'
$runnerWiringScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_wiring_status.ps1'
$broaderRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$contractRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1'
$runnerWiringSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$runnerWiringCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$runnerPatchTargetsCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
$refreshStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'

foreach ($helperPath in @($broaderRunnerScript, $contractRepairScript, $runnerWiringSafeScript, $runnerWiringScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$broaderRunnerArguments = @('-SummaryPath', $SummaryPath)
if ($RunnerArgument) {
    $broaderRunnerArguments += $RunnerArgument
}
$contractRepairArguments = @('-SummaryPath', $SummaryPath, '-Json')
$runnerWiringSafeArguments = @('-SummaryPath', $SummaryPath, '-Json')
$runnerWiringArguments = @('-SummaryPath', $SummaryPath, '-Json')

$steps = [System.Collections.Generic.List[object]]::new()
$broaderRunnerStep = Invoke-ScriptStep -Name 'recommended-validation' -ScriptPath $broaderRunnerScript -Arguments $broaderRunnerArguments
$steps.Add($broaderRunnerStep) | Out-Null

$summaryExistsAfterRunner = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$contractRepairStep = $null
if ($summaryExistsAfterRunner) {
    $contractRepairStep = Invoke-ScriptStep -Name 'runner-output-contract-repair' -ScriptPath $contractRepairScript -Arguments $contractRepairArguments -ExpectJson
    $steps.Add($contractRepairStep) | Out-Null
} else {
    $contractRepairStep = New-SkippedStep -Name 'runner-output-contract-repair' -ScriptPath $contractRepairScript -Arguments $contractRepairArguments -Reason 'The broader recommended validation runner did not leave a current summary artifact, so the contract repair step had no saved replay state to normalize.' -RecommendedCommand $broaderRunnerCommand -RecommendedGuideCommand $summaryGuideCommand -NextFocus 'Get the broader issue #3 recommended validation runner to leave a fresh summary artifact before repairing the saved runner-output contract.' -NextArtifactToOpen $ArtifactPath
    $steps.Add($contractRepairStep) | Out-Null
}

$summaryExistsAfterContractRepair = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$runnerWiringSafeStep = $null
if ($summaryExistsAfterContractRepair) {
    $runnerWiringSafeStep = Invoke-ScriptStep -Name 'runner-output-wiring-safe' -ScriptPath $runnerWiringSafeScript -Arguments $runnerWiringSafeArguments -ExpectJson
    $steps.Add($runnerWiringSafeStep) | Out-Null
} else {
    $runnerWiringSafeStep = New-SkippedStep -Name 'runner-output-wiring-safe' -ScriptPath $runnerWiringSafeScript -Arguments $runnerWiringSafeArguments -Reason 'The runner-output contract repair step did not leave a current summary artifact, so the safe runner-output wiring check had no replay state to inspect.' -RecommendedCommand $contractRepairCommand -RecommendedGuideCommand $summaryGuideCommand -NextFocus 'Get the saved issue #3 outputs back to a current summary artifact before checking the runner-output wiring safety gate.' -NextArtifactToOpen $ArtifactPath
    $steps.Add($runnerWiringSafeStep) | Out-Null
}

$runnerWiringStep = $null
if ($summaryExistsAfterContractRepair -and $runnerWiringSafeStep.success -and $runnerWiringSafeStep.status -eq 'safe-to-run-existing-helper') {
    $runnerWiringStep = Invoke-ScriptStep -Name 'runner-output-wiring' -ScriptPath $runnerWiringScript -Arguments $runnerWiringArguments -ExpectJson
    $steps.Add($runnerWiringStep) | Out-Null
} else {
    $runnerWiringStep = New-SkippedStep -Name 'runner-output-wiring' -ScriptPath $runnerWiringScript -Arguments $runnerWiringArguments -Reason 'The safe runner-output wiring checkpoint has not cleared the replay for the raw wiring helper yet.' -RecommendedCommand $(if ($runnerWiringSafeStep) { $runnerWiringSafeStep.recommended_command } else { $contractRepairCommand }) -RecommendedGuideCommand $(if ($runnerWiringSafeStep) { $runnerWiringSafeStep.recommended_guide_command } else { $summaryGuideCommand }) -NextFocus $(if ($runnerWiringSafeStep) { $runnerWiringSafeStep.next_focus } else { 'Get the issue #3 runner-output contract repaired and clear the safe wiring checkpoint before asking the raw wiring helper for a narrower verdict.' }) -NextArtifactToOpen $(if ($runnerWiringSafeStep) { $runnerWiringSafeStep.next_artifact_to_open } else { $ArtifactPath })
    $steps.Add($runnerWiringStep) | Out-Null
}

$status = $null
$reason = $null
$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextFocus = $null
$nextArtifactToOpen = $null

if (-not $summaryExistsAfterRunner) {
    $status = 'broader-runner-no-summary'
    $reason = 'The broader issue #3 recommended validation runner did not leave a summary artifact, so the contract repair and wiring helpers could not continue.'
    $recommendedCommand = $broaderRunnerCommand
    $recommendedGuideCommand = $summaryGuideCommand
    $nextFocus = 'Get the broader recommended validation runner to leave a fresh summary artifact before narrowing back down to runner-output contract work.'
    $nextArtifactToOpen = $ArtifactPath
} elseif (-not $contractRepairStep.success) {
    $status = 'contract-repair-failed'
    $reason = 'The broader runner left a summary artifact, but the runner-output contract repair step did not finish cleanly, so the next replay still needs direct contract repair attention.'
} elseif (-not $runnerWiringSafeStep.success) {
    $status = 'runner-output-wiring-safe-failed'
    $reason = 'The contract repair step completed, but the safe runner-output wiring helper did not finish cleanly, so the next replay should stay on the saved safe-wiring artifact first.'
} elseif ($runnerWiringSafeStep.status -ne 'safe-to-run-existing-helper') {
    $status = 'follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        if ($runnerWiringSafeStep) { $runnerWiringSafeStep.reason },
        if ($contractRepairStep) { $contractRepairStep.reason },
        'The broader runner and runner-output contract repair completed, but the safe wiring helper still reports follow-up work before the raw wiring helper should run.'
    )
} elseif (-not $runnerWiringStep.success) {
    $status = 'runner-output-wiring-check-failed'
    $reason = 'The safe runner-output wiring checkpoint cleared, but the raw wiring helper did not finish cleanly, so the next replay should stay on the saved wiring artifact first.'
} elseif (@('fully-wired', 'already-direct', 'saved-artifacts-stale-runner-already-wired') -contains $runnerWiringStep.status) {
    $status = 'ready-for-refresh-status'
    $reason = 'The broader runner, contract repair helper, and runner-output wiring checks all completed, so the next Windows replay can move forward to the refresh-status safe checkpoint.'
    $recommendedCommand = $refreshStatusSafeCommand
    $recommendedGuideCommand = $refreshStatusSafeCommand
    $nextFocus = 'Use the refresh-status safe helper to confirm the helper chain is ready for the narrower issue #3 replay path.'
    $nextArtifactToOpen = $SummaryPath
} else {
    $status = 'follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        if ($runnerWiringStep) { $runnerWiringStep.reason },
        if ($runnerWiringSafeStep) { $runnerWiringSafeStep.reason },
        if ($contractRepairStep) { $contractRepairStep.reason },
        'The broader runner, contract repair helper, and raw wiring helper all ran, but the saved wiring artifact still reports a narrower follow-up step before the refresh-status chain should run.'
    )
}

if (-not $recommendedCommand) {
    $recommendedCommand = Get-FirstNonEmptyValue -Values @(
        if ($runnerWiringStep) { $runnerWiringStep.recommended_command },
        if ($runnerWiringSafeStep) { $runnerWiringSafeStep.recommended_command },
        if ($contractRepairStep) { $contractRepairStep.recommended_command },
        $contractRepairCommand
    )
}
if (-not $recommendedGuideCommand) {
    $recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
        if ($runnerWiringStep) { $runnerWiringStep.recommended_guide_command },
        if ($runnerWiringSafeStep) { $runnerWiringSafeStep.recommended_guide_command },
        if ($contractRepairStep) { $contractRepairStep.recommended_guide_command },
        $summaryGuideCommand
    )
}
if (-not $nextFocus) {
    $nextFocus = Get-FirstNonEmptyValue -Values @(
        if ($runnerWiringStep) { $runnerWiringStep.next_focus },
        if ($runnerWiringSafeStep) { $runnerWiringSafeStep.next_focus },
        if ($contractRepairStep) { $contractRepairStep.next_focus },
        if ($summaryExistsAfterContractRepair) { 'Use the saved runner-output wiring artifacts to decide whether the next issue #3 replay stays on contract cleanup or moves on to refresh status.' }
    )
}
if (-not $nextArtifactToOpen) {
    $nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
        if ($runnerWiringStep) { $runnerWiringStep.next_artifact_to_open },
        if ($runnerWiringSafeStep) { $runnerWiringSafeStep.next_artifact_to_open },
        if ($contractRepairStep) { $contractRepairStep.next_artifact_to_open },
        if ($summaryExistsAfterContractRepair) { $SummaryPath },
        $ArtifactPath
    )
}

$report = [ordered]@{
    issue = 'Google issue #3 broader runner plus contract repair and wiring-safe chain'
    purpose = 'Run the broader issue #3 recommended validation runner, normalize the saved runner-output contract, and then confirm whether the raw wiring helper is safe and useful for the next Windows replay.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    runner_argument_passthrough = @($RunnerArgument)
    summary_exists_after_runner = [bool]$summaryExistsAfterRunner
    summary_exists_after_contract_repair = [bool]$summaryExistsAfterContractRepair
    broader_runner_status = $broaderRunnerStep.status
    contract_repair_status = $contractRepairStep.status
    runner_output_wiring_safe_status = $runnerWiringSafeStep.status
    runner_output_wiring_status = $runnerWiringStep.status
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    broader_runner_command = $broaderRunnerCommand
    contract_repair_command = $contractRepairCommand
    runner_wiring_safe_command = $runnerWiringSafeCommand
    runner_wiring_command = $runnerWiringCommand
    runner_patch_targets_command = $runnerPatchTargetsCommand
    refresh_status_safe_command = $refreshStatusSafeCommand
    summary_guide_command = $summaryGuideCommand
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    status = $status
    reason = $reason
    steps = @($steps | ForEach-Object {
        [ordered]@{
            name = $_.name
            status = $_.status
            success = [bool]$_.success
            exit_code = $_.exit_code
            error = $_.error
            parse_error = $_.parse_error
            recommended_command = $_.recommended_command
            recommended_guide_command = $_.recommended_guide_command
            next_focus = $_.next_focus
            next_artifact_to_open = $_.next_artifact_to_open
            reason = $_.reason
            output_preview = @($_.output_preview)
        }
    })
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    if (@('broader-runner-no-summary', 'contract-repair-failed', 'runner-output-wiring-safe-failed', 'runner-output-wiring-check-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 broader runner plus contract repair and wiring-safe chain'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary exists after runner: {0}" -f $report.summary_exists_after_runner)
Write-Host ("Summary exists after contract repair: {0}" -f $report.summary_exists_after_contract_repair)
Write-Host ("Broader runner: {0}" -f $report.broader_runner_status)
Write-Host ("Contract repair: {0}" -f $report.contract_repair_status)
Write-Host ("Wiring safe: {0}" -f $report.runner_output_wiring_safe_status)
Write-Host ("Raw wiring:  {0}" -f $report.runner_output_wiring_status)
Write-Host ''
foreach ($step in $report.steps) {
    $marker = if ($step.success) { 'PASS' } else { 'FAIL' }
    Write-Host ("[{0}] {1} -> {2}" -f $marker, $step.name, $step.status)
    if ($step.error) {
        Write-Host ("  Error: {0}" -f $step.error)
    }
    if ($step.parse_error) {
        Write-Host ("  Parse error: {0}" -f $step.parse_error)
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)

if (@('broader-runner-no-summary', 'contract-repair-failed', 'runner-output-wiring-safe-failed', 'runner-output-wiring-check-failed') -contains $status) {
    exit 1
}
