[CmdletBinding()]
param(
    [string]$SummaryPath,
    [string]$ArtifactPath,
    [string]$GuideArtifactPath,
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
        $recordStatus = Get-OptionalPropertyValue -Object $record -Name 'status'
        if (-not [string]::IsNullOrWhiteSpace($recordStatus)) {
            $recordStatus
        } else {
            'completed'
        }
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
        [Parameter(Mandatory = $true)]
        [string]$Reason,
        [string]$RecommendedCommand,
        [string]$RecommendedGuideCommand,
        [string]$NextFocus
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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-safe-summary-guide.json'
}
if (-not $GuideArtifactPath) {
    $GuideArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-guide-safe.json'
}

$runnerScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation.ps1'
$safeGuideScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_summary_guide_safe.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$safeGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'
$summaryContractRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_summary_contract.ps1'
$rawGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'

foreach ($helperPath in @($runnerScript, $safeGuideScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$runnerArguments = @('-SummaryPath', $SummaryPath)
if ($RunnerArgument) {
    $runnerArguments += $RunnerArgument
}
$safeGuideArguments = @('-SummaryPath', $SummaryPath, '-ArtifactPath', $GuideArtifactPath, '-Json')

$steps = [System.Collections.Generic.List[object]]::new()
$runnerStep = Invoke-ScriptStep -Name 'recommended-validation' -ScriptPath $runnerScript -Arguments $runnerArguments
$steps.Add($runnerStep) | Out-Null

$summaryExistsAfterRunner = Test-Path -LiteralPath $SummaryPath -PathType Leaf
if ($summaryExistsAfterRunner) {
    $safeGuideStep = Invoke-ScriptStep -Name 'safe-summary-guide' -ScriptPath $safeGuideScript -Arguments $safeGuideArguments -ExpectJson
} else {
    $safeGuideStep = New-SkippedStep -Name 'safe-summary-guide' -ScriptPath $safeGuideScript -Arguments $safeGuideArguments -Reason 'The recommended validation runner did not leave a current summary artifact, so the strict-mode-safe guide could not refresh against current output.' -RecommendedCommand $recommendedRunnerCommand -RecommendedGuideCommand $safeGuideCommand -NextFocus 'Regenerate a current issue #3 recommended-validation summary first, then rerun the safe summary guide wrapper.'
}
$steps.Add($safeGuideStep) | Out-Null

$safeGuideRecord = $safeGuideStep.record
$missingSummaryContractFields = if ($safeGuideRecord) {
    @((Get-OptionalPropertyValue -Object $safeGuideRecord -Name 'missing_summary_contract_fields'))
} else {
    @()
}

$status = $null
$reason = $null
if (-not $summaryExistsAfterRunner) {
    $status = 'runner-no-summary'
    $reason = 'The recommended validation runner did not leave a summary artifact, so the safe summary guide could not refresh.'
} elseif (-not $safeGuideStep.success) {
    $status = 'safe-guide-failed'
    $reason = 'The recommended validation runner left a summary artifact, but the strict-mode-safe summary guide did not finish cleanly.'
} elseif ($runnerStep.success) {
    $status = 'completed-with-safe-guide'
    $reason = 'The recommended validation runner completed and the strict-mode-safe summary guide artifact was refreshed from the current summary output.'
} else {
    $status = 'runner-stopped-safe-guide-refreshed'
    $reason = 'The recommended validation runner stopped at its current bounded failure point, but it still left a current summary and the strict-mode-safe summary guide was refreshed from that output.'
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($safeGuideRecord) { Get-OptionalPropertyValue -Object $safeGuideRecord -Name 'recommended_command' },
    $safeGuideStep.recommended_command,
    $recommendedRunnerCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($safeGuideRecord) { Get-OptionalPropertyValue -Object $safeGuideRecord -Name 'recommended_guide_command' },
    $safeGuideStep.recommended_guide_command,
    if ($summaryExistsAfterRunner) { $summaryContractRepairCommand },
    $safeGuideCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($safeGuideRecord) { Get-OptionalPropertyValue -Object $safeGuideRecord -Name 'next_focus' },
    $safeGuideStep.next_focus,
    if ($summaryExistsAfterRunner) { 'Keep the next Windows replay on the earliest failing checkpoint from the refreshed safe guide before widening back out to the broader runner again.' },
    'Regenerate a current issue #3 recommended-validation summary first, then rerun the safe summary guide wrapper.'
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($safeGuideRecord) { Get-OptionalPropertyValue -Object $safeGuideRecord -Name 'first_failed_phase_primary_json_artifact_path' },
    if ($safeGuideRecord) { Get-OptionalPropertyValue -Object $safeGuideRecord -Name 'boundary_artifact_path' },
    if ($safeGuideRecord) { Get-OptionalPropertyValue -Object $safeGuideRecord -Name 'guide_artifact_path' },
    if ($summaryExistsAfterRunner) { $SummaryPath },
    $ArtifactPath
)

$report = [ordered]@{
    issue = 'Google issue #3 recommended validation safe summary guide wrapper'
    purpose = 'Run the bounded issue #3 recommended validation runner, then immediately refresh the strict-mode-safe summary guide from the current summary output.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    safe_guide_artifact_path = $GuideArtifactPath
    runner_argument_passthrough = @($RunnerArgument)
    summary_exists_after_runner = [bool]$summaryExistsAfterRunner
    runner_exit_code = $runnerStep.exit_code
    runner_success = [bool]$runnerStep.success
    safe_guide_success = [bool]$safeGuideStep.success
    safe_guide_status = $safeGuideStep.status
    safe_guide_missing_summary_contract_fields = @($missingSummaryContractFields)
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    safe_summary_guide_command = $safeGuideCommand
    raw_summary_guide_command = $rawGuideCommand
    broader_runner_command = $recommendedRunnerCommand
    summary_contract_repair_command = $summaryContractRepairCommand
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
            reason = $_.reason
            output_preview = @($_.output_preview)
        }
    })
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    if (@('runner-no-summary', 'safe-guide-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 recommended validation safe summary guide wrapper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Safe guide: {0}" -f $report.safe_guide_artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary exists after runner: {0}" -f $report.summary_exists_after_runner)
Write-Host ("Runner success: {0}" -f $report.runner_success)
Write-Host ("Safe guide success: {0}" -f $report.safe_guide_success)
if ($report.safe_guide_missing_summary_contract_fields.Count -gt 0) {
    Write-Host 'Missing summary contract fields:'
    foreach ($fieldName in $report.safe_guide_missing_summary_contract_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
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
Write-Host ("Safe guide cmd: {0}" -f $report.safe_summary_guide_command)
Write-Host ("Raw guide cmd:  {0}" -f $report.raw_summary_guide_command)

if (@('runner-no-summary', 'safe-guide-failed') -contains $status) {
    exit 1
}
