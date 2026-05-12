[CmdletBinding()]
param(
    [string]$SummaryPath,
    [string]$ArtifactPath,
    [string[]]$RunnerArgument,
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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-runner-output-safe.json'
}

$repairChainScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation_repair_chain.ps1'
$runnerContractRepairScript = Join-Path $PSScriptRoot 'repair_google_issue3_runner_output_contract.ps1'
$runnerWiringSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_wiring_status_safe.ps1'
$repairChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_chain.ps1'
$runnerContractRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1'
$runnerWiringSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$runnerWiringCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$runnerPatchTargetsCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
$refreshStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'
$runnerContractRepairArtifactPath = Join-Path $artifactRoot 'google-issue3-runner-output-contract-repair.json'

foreach ($helperPath in @($repairChainScript, $runnerContractRepairScript, $runnerWiringSafeScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$repairChainArguments = @('-SummaryPath', $SummaryPath, '-Json')
if ($RunnerArgument) {
    $repairChainArguments += '-RunnerArgument'
    $repairChainArguments += $RunnerArgument
}
$runnerContractRepairArguments = @('-SummaryPath', $SummaryPath, '-ArtifactPath', $runnerContractRepairArtifactPath, '-Json')
$runnerWiringSafeArguments = @('-SummaryPath', $SummaryPath, '-Json')

$steps = [System.Collections.Generic.List[object]]::new()
$repairChainStep = Invoke-ScriptStep -Name 'recommended-validation-repair-chain' -ScriptPath $repairChainScript -Arguments $repairChainArguments -ExpectJson
$steps.Add($repairChainStep) | Out-Null

$summaryExistsAfterRepairChain = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$runnerContractRepairStep = $null
if ($summaryExistsAfterRepairChain) {
    $runnerContractRepairStep = Invoke-ScriptStep -Name 'runner-output-contract-repair' -ScriptPath $runnerContractRepairScript -Arguments $runnerContractRepairArguments -ExpectJson
    $steps.Add($runnerContractRepairStep) | Out-Null
} else {
    $runnerContractRepairStep = New-SkippedStep -Name 'runner-output-contract-repair' -ScriptPath $runnerContractRepairScript -Arguments $runnerContractRepairArguments -Reason 'The combined repair chain did not leave a current summary artifact, so the runner-output contract repair helper had no replay state to normalize.' -RecommendedCommand $repairChainCommand -RecommendedGuideCommand $summaryGuideCommand -NextFocus 'Get the broader issue #3 validation chain to leave a fresh summary artifact before repairing the saved runner-output contract.' -NextArtifactToOpen $ArtifactPath
    $steps.Add($runnerContractRepairStep) | Out-Null
}

$summaryExistsAfterContractRepair = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$runnerWiringSafeStep = $null
if ($summaryExistsAfterContractRepair) {
    $runnerWiringSafeStep = Invoke-ScriptStep -Name 'runner-output-wiring-safe' -ScriptPath $runnerWiringSafeScript -Arguments $runnerWiringSafeArguments -ExpectJson
    $steps.Add($runnerWiringSafeStep) | Out-Null
} else {
    $runnerWiringSafeStep = New-SkippedStep -Name 'runner-output-wiring-safe' -ScriptPath $runnerWiringSafeScript -Arguments $runnerWiringSafeArguments -Reason 'The summary artifact was not available after the runner-output contract repair step, so the safe wiring-status helper had no replay state to inspect.' -RecommendedCommand $repairChainCommand -RecommendedGuideCommand $summaryGuideCommand -NextFocus 'Regenerate the issue #3 recommended validation summary before asking the runner-output wiring-safe helper to narrow the next replay.' -NextArtifactToOpen $ArtifactPath
    $steps.Add($runnerWiringSafeStep) | Out-Null
}

$status = $null
$reason = $null
if (-not $summaryExistsAfterRepairChain) {
    $status = 'repair-chain-no-summary'
    $reason = 'The broader issue #3 validation repair chain did not leave a summary artifact, so the runner-output contract repair and safe wiring gate could not continue.'
} elseif (-not $repairChainStep.success) {
    $status = 'repair-chain-failed'
    $reason = 'The broader issue #3 validation repair chain did not finish cleanly, so the next replay still needs repair-chain attention before the saved runner-output contract is trusted.'
} elseif (-not $runnerContractRepairStep.success) {
    $status = 'contract-repair-failed'
    $reason = 'The broader repair chain completed, but the runner-output contract repair helper did not finish cleanly, so the saved summary and manifest may still be missing direct refresh or handoff fields.'
} elseif (-not $runnerWiringSafeStep.success) {
    $status = 'wiring-safe-check-failed'
    $reason = 'The repair chain and runner-output contract repair completed, but the safe wiring-status helper did not finish cleanly, so the next replay should reopen the saved artifacts directly.'
} elseif ($runnerWiringSafeStep.status -eq 'safe-to-run-existing-helper') {
    $status = 'ready-for-runner-wiring'
    $reason = 'The broader repair chain completed, the saved runner-output contract was normalized, and the safe wiring-status helper says the raw runner-output wiring helper is ready for the next Windows replay.'
} elseif ($runnerWiringSafeStep.status -eq 'runner-contract-missing') {
    $status = 'runner-contract-still-missing'
    $reason = 'The broader repair chain completed, but the safe wiring-status helper still sees a missing direct runner-output field after the repair step, so the next replay should inspect the saved contract artifacts before trusting the raw wiring helper.'
} else {
    $status = 'follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        if ($runnerWiringSafeStep) { $runnerWiringSafeStep.reason },
        if ($runnerContractRepairStep) { $runnerContractRepairStep.reason },
        if ($repairChainStep) { $repairChainStep.reason },
        'The broader repair chain, runner-output contract repair, and safe wiring-status check completed, but the next issue #3 replay still needs the follow-up command reported by the saved artifacts.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($runnerWiringSafeStep) { $runnerWiringSafeStep.recommended_command },
    if ($runnerContractRepairStep) { $runnerContractRepairStep.recommended_command },
    if ($repairChainStep) { $repairChainStep.recommended_command },
    $repairChainCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($runnerWiringSafeStep) { $runnerWiringSafeStep.recommended_guide_command },
    if ($runnerContractRepairStep) { $runnerContractRepairStep.recommended_guide_command },
    if ($repairChainStep) { $repairChainStep.recommended_guide_command },
    $summaryGuideCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($runnerWiringSafeStep) { $runnerWiringSafeStep.next_focus },
    if ($runnerContractRepairStep) { $runnerContractRepairStep.next_focus },
    if ($repairChainStep) { $repairChainStep.next_focus },
    if (-not $summaryExistsAfterRepairChain) { 'Regenerate the issue #3 recommended validation summary before asking the runner-output contract helpers to narrow the next replay.' }
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($runnerWiringSafeStep) { $runnerWiringSafeStep.next_artifact_to_open },
    if ($summaryExistsAfterContractRepair) { $SummaryPath },
    if (Test-Path -LiteralPath $runnerContractRepairArtifactPath -PathType Leaf) { $runnerContractRepairArtifactPath },
    $ArtifactPath
)

$report = [ordered]@{
    issue = 'Google issue #3 recommended validation repair plus runner-output-safe gate'
    purpose = 'Run the broader issue #3 validation repair chain, normalize the saved runner-output contract, and then confirm whether the raw runner-output wiring helper is ready for the next Windows replay.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    runner_argument_passthrough = @($RunnerArgument)
    summary_exists_after_repair_chain = [bool]$summaryExistsAfterRepairChain
    summary_exists_after_contract_repair = [bool]$summaryExistsAfterContractRepair
    repair_chain_status = $repairChainStep.status
    runner_contract_repair_status = $runnerContractRepairStep.status
    runner_wiring_safe_status = $runnerWiringSafeStep.status
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    repair_chain_command = $repairChainCommand
    runner_contract_repair_command = $runnerContractRepairCommand
    runner_contract_repair_artifact_path = $runnerContractRepairArtifactPath
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
    if (@('repair-chain-no-summary', 'repair-chain-failed', 'contract-repair-failed', 'wiring-safe-check-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 recommended validation repair plus runner-output-safe gate'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary exists after repair chain: {0}" -f $report.summary_exists_after_repair_chain)
Write-Host ("Summary exists after contract repair: {0}" -f $report.summary_exists_after_contract_repair)
Write-Host ("Repair chain: {0}" -f $report.repair_chain_status)
Write-Host ("Contract repair: {0}" -f $report.runner_contract_repair_status)
Write-Host ("Wiring safe: {0}" -f $report.runner_wiring_safe_status)
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

if (@('repair-chain-no-summary', 'repair-chain-failed', 'contract-repair-failed', 'wiring-safe-check-failed') -contains $status) {
    exit 1
}
