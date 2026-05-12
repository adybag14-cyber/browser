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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-summary-contract.json'
}

$recommendedRunnerScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation.ps1'
$summaryContractRepairScript = Join-Path $PSScriptRoot 'repair_google_issue3_validation_summary_contract.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$summaryContractRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_summary_contract.ps1'
$runnerWiringStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$refreshStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'

foreach ($helperPath in @($recommendedRunnerScript, $summaryContractRepairScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$runnerArguments = @('-SummaryPath', $SummaryPath)
if ($RunnerArgument) {
    $runnerArguments += $RunnerArgument
}
$summaryContractRepairArguments = @('-SummaryPath', $SummaryPath, '-Json')

$steps = [System.Collections.Generic.List[object]]::new()
$runnerStep = Invoke-ScriptStep -Name 'recommended-validation-runner' -ScriptPath $recommendedRunnerScript -Arguments $runnerArguments
$steps.Add($runnerStep) | Out-Null

$summaryExistsAfterRunner = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$summaryContractRepairStep = $null
if ($summaryExistsAfterRunner) {
    $summaryContractRepairStep = Invoke-ScriptStep -Name 'summary-contract-repair' -ScriptPath $summaryContractRepairScript -Arguments $summaryContractRepairArguments -ExpectJson
    $steps.Add($summaryContractRepairStep) | Out-Null
} else {
    $summaryContractRepairStep = New-SkippedStep -Name 'summary-contract-repair' -ScriptPath $summaryContractRepairScript -Arguments $summaryContractRepairArguments -Reason 'The broader recommended runner did not leave a summary artifact, so the summary-contract repair step had no current saved state to normalize.' -RecommendedCommand $recommendedRunnerCommand -RecommendedGuideCommand $runnerWiringStatusSafeCommand -NextFocus 'Get the broader issue #3 recommended runner to produce a fresh summary artifact before asking the summary-contract repair helper to narrow the next replay.' -NextArtifactToOpen $ArtifactPath
    $steps.Add($summaryContractRepairStep) | Out-Null
}

$status = $null
$reason = $null
if (-not $summaryExistsAfterRunner) {
    $status = 'runner-failed-no-summary'
    $reason = 'The broader issue #3 recommended runner did not leave a summary artifact, so the follow-up summary-contract repair could not continue from the current replay.'
} elseif (-not $summaryContractRepairStep.success) {
    $status = 'summary-contract-repair-failed'
    $reason = 'The broader runner produced saved outputs, but the follow-up summary-contract repair did not finish cleanly, so the next replay still needs direct summary-contract attention.'
} elseif (@('fully-wired', 'safe-gate-cleared') -contains $summaryContractRepairStep.status) {
    $status = 'ready-for-refresh-status'
    $reason = 'The broader runner completed and the summary-contract repair says the saved issue #3 outputs are ready to move on to the refresh-status safe checkpoint.'
} elseif (-not $runnerStep.success) {
    $status = 'runner-failed-follow-up-ready'
    $reason = 'The broader runner still failed, but it left enough saved state for the summary-contract repair to narrow the next issue #3 follow-up step.'
} else {
    $status = 'follow-up-needed'
    $reason = if ($summaryContractRepairStep.reason) {
        $summaryContractRepairStep.reason
    } else {
        'The broader runner and summary-contract repair completed, but the next issue #3 replay still needs the follow-up command reported by the saved repair artifact.'
    }
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($summaryContractRepairStep) { $summaryContractRepairStep.recommended_command },
    if (-not $runnerStep.success) { $recommendedRunnerCommand },
    $summaryContractRepairCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($summaryContractRepairStep) { $summaryContractRepairStep.recommended_guide_command },
    if (@('fully-wired', 'safe-gate-cleared') -contains $summaryContractRepairStep.status) { $refreshStatusSafeCommand },
    $runnerWiringStatusSafeCommand,
    $summaryGuideCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($summaryContractRepairStep) { $summaryContractRepairStep.next_focus },
    if (-not $summaryExistsAfterRunner) { 'Regenerate the issue #3 recommended validation summary before asking the summary-contract repair helper to narrow the replay.' },
    if (-not $runnerStep.success) { 'Inspect the broader runner output first, then use the summary-contract repair result to stay on the narrowest next replay.' }
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($summaryContractRepairStep) { $summaryContractRepairStep.next_artifact_to_open },
    if ($summaryExistsAfterRunner) { $SummaryPath },
    $ArtifactPath
)

$report = [ordered]@{
    issue = 'Google issue #3 recommended validation plus summary-contract repair'
    purpose = 'Run the broader issue #3 recommended validation replay, then immediately normalize the saved summary contract and report the tightest next follow-up command.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    runner_argument_passthrough = @($RunnerArgument)
    summary_exists_after_runner = [bool]$summaryExistsAfterRunner
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    broader_runner_command = $recommendedRunnerCommand
    summary_contract_repair_command = $summaryContractRepairCommand
    runner_wiring_status_safe_command = $runnerWiringStatusSafeCommand
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
    if (@('runner-failed-no-summary', 'summary-contract-repair-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 recommended validation plus summary-contract repair'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary exists after runner: {0}" -f $report.summary_exists_after_runner)
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

if (@('runner-failed-no-summary', 'summary-contract-repair-failed') -contains $status) {
    exit 1
}
