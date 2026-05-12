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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-runner-output-contract-safe.json'
}

$recommendedRunnerScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation.ps1'
$runnerOutputContractRepairScript = Join-Path $PSScriptRoot 'repair_google_issue3_runner_output_contract.ps1'
$runnerOutputWiringSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_wiring_status_safe.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$runnerOutputContractRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1'
$runnerOutputWiringSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$runnerOutputWiringCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$runnerOutputPatchTargetsSafeRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe_route.ps1'
$runnerOutputPatchTargetsSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe.ps1'
$runnerOutputPatchTargetsCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
$refreshStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'

foreach ($helperPath in @($recommendedRunnerScript, $runnerOutputContractRepairScript, $runnerOutputWiringSafeScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$runnerArguments = @('-SummaryPath', $SummaryPath)
if ($RunnerArgument) {
    $runnerArguments += $RunnerArgument
}
$runnerOutputContractRepairArguments = @('-SummaryPath', $SummaryPath, '-Json')
$runnerOutputWiringSafeArguments = @('-SummaryPath', $SummaryPath, '-Json')

$steps = [System.Collections.Generic.List[object]]::new()
$runnerStep = Invoke-ScriptStep -Name 'recommended-validation-runner' -ScriptPath $recommendedRunnerScript -Arguments $runnerArguments
$steps.Add($runnerStep) | Out-Null

$summaryExistsAfterRunner = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$runnerOutputContractRepairStep = $null
if ($summaryExistsAfterRunner) {
    $runnerOutputContractRepairStep = Invoke-ScriptStep -Name 'runner-output-contract-repair' -ScriptPath $runnerOutputContractRepairScript -Arguments $runnerOutputContractRepairArguments -ExpectJson
    $steps.Add($runnerOutputContractRepairStep) | Out-Null
} else {
    $runnerOutputContractRepairStep = New-SkippedStep -Name 'runner-output-contract-repair' -ScriptPath $runnerOutputContractRepairScript -Arguments $runnerOutputContractRepairArguments -Reason 'The broader recommended runner did not leave a summary artifact, so the runner-output contract repair step had no current saved state to normalize.' -RecommendedCommand $recommendedRunnerCommand -RecommendedGuideCommand $summaryGuideCommand -NextFocus 'Get the broader issue #3 recommended runner to produce a fresh summary artifact before asking the runner-output contract repair helper to narrow the next replay.' -NextArtifactToOpen $ArtifactPath
    $steps.Add($runnerOutputContractRepairStep) | Out-Null
}

$summaryExistsAfterRunnerOutputRepair = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$runnerOutputWiringSafeStep = $null
if ($summaryExistsAfterRunnerOutputRepair) {
    $runnerOutputWiringSafeStep = Invoke-ScriptStep -Name 'runner-output-wiring-safe' -ScriptPath $runnerOutputWiringSafeScript -Arguments $runnerOutputWiringSafeArguments -ExpectJson
    $steps.Add($runnerOutputWiringSafeStep) | Out-Null
} else {
    $runnerOutputWiringSafeStep = New-SkippedStep -Name 'runner-output-wiring-safe' -ScriptPath $runnerOutputWiringSafeScript -Arguments $runnerOutputWiringSafeArguments -Reason 'The runner-output contract repair step did not leave a current summary artifact, so the safe wiring check had no replay state to inspect.' -RecommendedCommand $runnerOutputContractRepairCommand -RecommendedGuideCommand $summaryGuideCommand -NextFocus 'Get the saved issue #3 outputs back to a current summary artifact before checking the safe runner-output wiring gate.' -NextArtifactToOpen $ArtifactPath
    $steps.Add($runnerOutputWiringSafeStep) | Out-Null
}

$status = $null
$reason = $null
if (-not $summaryExistsAfterRunner) {
    $status = 'runner-failed-no-summary'
    $reason = 'The broader issue #3 recommended runner did not leave a summary artifact, so the follow-up runner-output contract repair could not continue from the current replay.'
} elseif (-not $runnerOutputContractRepairStep.success) {
    $status = 'runner-output-contract-repair-failed'
    $reason = 'The broader runner produced saved outputs, but the follow-up runner-output contract repair did not finish cleanly, so the next replay still needs direct runner-output contract attention.'
} elseif (-not $runnerOutputWiringSafeStep.success) {
    $status = 'runner-output-wiring-safe-check-failed'
    $reason = 'The runner-output contract repair step completed, but the safe wiring helper did not finish cleanly, so the next replay should stay on the saved repair artifact first.'
} elseif ($runnerOutputWiringSafeStep.status -eq 'safe-to-run-existing-helper') {
    $status = 'ready-for-runner-output-wiring'
    $reason = 'The broader runner completed, the runner-output contract repair normalized the saved summary and manifest, and the safe wiring helper says the stricter runner-output wiring audit is ready for the next Windows replay.'
} elseif (-not $runnerStep.success) {
    $status = 'runner-failed-follow-up-ready'
    $reason = 'The broader runner still failed, but it left enough saved state for the runner-output contract repair and safe wiring check to narrow the next issue #3 follow-up step.'
} else {
    $status = 'follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        if ($runnerOutputWiringSafeStep) { $runnerOutputWiringSafeStep.reason },
        if ($runnerOutputContractRepairStep) { $runnerOutputContractRepairStep.reason },
        'The broader runner, runner-output contract repair, and safe wiring check completed, but the next issue #3 replay still needs the follow-up command reported by the saved artifacts.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($runnerOutputWiringSafeStep) { $runnerOutputWiringSafeStep.recommended_command },
    if ($runnerOutputContractRepairStep) { $runnerOutputContractRepairStep.recommended_command },
    if (-not $runnerStep.success) { $recommendedRunnerCommand },
    $runnerOutputContractRepairCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($runnerOutputWiringSafeStep -and $runnerOutputWiringSafeStep.status -eq 'safe-to-run-existing-helper') { $runnerOutputWiringCommand },
    if ($runnerOutputWiringSafeStep) { $runnerOutputWiringSafeStep.recommended_guide_command },
    if ($runnerOutputContractRepairStep) { $runnerOutputContractRepairStep.recommended_guide_command },
    $runnerOutputPatchTargetsSafeRouteCommand,
    $runnerOutputPatchTargetsSafeCommand,
    $runnerOutputPatchTargetsCommand,
    $refreshStatusSafeCommand,
    $summaryGuideCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($runnerOutputWiringSafeStep) { $runnerOutputWiringSafeStep.next_focus },
    if ($runnerOutputContractRepairStep) { $runnerOutputContractRepairStep.next_focus },
    if (-not $summaryExistsAfterRunner) { 'Regenerate the issue #3 recommended validation summary before asking the runner-output contract repair helper to narrow the replay.' },
    if (-not $runnerStep.success) { 'Inspect the broader runner output first, then use the repair and safe wiring results to stay on the narrowest next replay.' }
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($runnerOutputWiringSafeStep) { $runnerOutputWiringSafeStep.next_artifact_to_open },
    if ($runnerOutputContractRepairStep) { $runnerOutputContractRepairStep.next_artifact_to_open },
    if ($summaryExistsAfterRunner) { $SummaryPath },
    $ArtifactPath
)

$report = [ordered]@{
    issue = 'Google issue #3 recommended validation plus runner-output contract repair and safe wiring check'
    purpose = 'Run the broader issue #3 recommended validation replay, repair the saved runner-output contract, then immediately confirm whether the safe runner-output wiring checkpoint is clear enough for the next Windows replay to trust the stricter wiring audit.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    runner_argument_passthrough = @($RunnerArgument)
    summary_exists_after_runner = [bool]$summaryExistsAfterRunner
    summary_exists_after_runner_output_repair = [bool]$summaryExistsAfterRunnerOutputRepair
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    broader_runner_command = $recommendedRunnerCommand
    runner_output_contract_repair_command = $runnerOutputContractRepairCommand
    runner_output_wiring_safe_command = $runnerOutputWiringSafeCommand
    runner_output_wiring_command = $runnerOutputWiringCommand
    runner_output_patch_targets_safe_route_command = $runnerOutputPatchTargetsSafeRouteCommand
    runner_output_patch_targets_safe_command = $runnerOutputPatchTargetsSafeCommand
    runner_output_patch_targets_command = $runnerOutputPatchTargetsCommand
    refresh_status_safe_command = $refreshStatusSafeCommand
    summary_guide_command = $summaryGuideCommand
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
    if (@('runner-failed-no-summary', 'runner-output-contract-repair-failed', 'runner-output-wiring-safe-check-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 recommended validation plus runner-output contract repair and safe wiring check'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary exists after runner: {0}" -f $report.summary_exists_after_runner)
Write-Host ("Summary exists after runner-output repair: {0}" -f $report.summary_exists_after_runner_output_repair)
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

if (@('runner-failed-no-summary', 'runner-output-contract-repair-failed', 'runner-output-wiring-safe-check-failed') -contains $status) {
    exit 1
}
