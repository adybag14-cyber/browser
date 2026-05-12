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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-runner-output-contract-repair-safe.json'
}

$repairScript = Join-Path $PSScriptRoot 'repair_google_issue3_runner_output_contract.ps1'
$wiringSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_wiring_status_safe.ps1'
$repairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1'
$wiringSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$wiringCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$patchTargetsCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
$broaderRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'

foreach ($helperPath in @($repairScript, $wiringSafeScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$repairArguments = @('-SummaryPath', $SummaryPath, '-Json')
$wiringSafeArguments = @('-SummaryPath', $SummaryPath, '-Json')

$steps = [System.Collections.Generic.List[object]]::new()
$repairStep = Invoke-ScriptStep -Name 'runner-output-contract-repair' -ScriptPath $repairScript -Arguments $repairArguments -ExpectJson
$steps.Add($repairStep) | Out-Null

$summaryExistsAfterRepair = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$wiringSafeStep = $null
if ($summaryExistsAfterRepair) {
    $wiringSafeStep = Invoke-ScriptStep -Name 'runner-output-wiring-safe' -ScriptPath $wiringSafeScript -Arguments $wiringSafeArguments -ExpectJson
    $steps.Add($wiringSafeStep) | Out-Null
} else {
    $wiringSafeStep = New-SkippedStep -Name 'runner-output-wiring-safe' -ScriptPath $wiringSafeScript -Arguments $wiringSafeArguments -Reason 'The runner-output contract repair helper did not leave a current summary artifact, so the safe wiring check had no saved replay state to inspect.' -RecommendedCommand $broaderRunnerCommand -RecommendedGuideCommand $summaryGuideCommand -NextFocus 'Regenerate the issue #3 recommended validation summary before asking the safe runner-output wiring helper to narrow the next replay.' -NextArtifactToOpen $ArtifactPath
    $steps.Add($wiringSafeStep) | Out-Null
}

$status = $null
$reason = $null
if (-not $summaryExistsAfterRepair) {
    $status = 'repair-no-summary'
    $reason = 'The runner-output contract repair helper did not leave a summary artifact, so the follow-up safe wiring check could not continue.'
} elseif (-not $repairStep.success) {
    $status = 'repair-helper-failed'
    $reason = 'The runner-output contract repair helper did not finish cleanly, so the next replay still needs direct repair attention before the wiring state is trusted.'
} elseif (-not $wiringSafeStep.success) {
    $status = 'safe-wiring-check-failed'
    $reason = 'The contract repair helper completed, but the safe runner-output wiring helper did not finish cleanly, so the next replay should stay on the saved repair artifact first.'
} elseif ($wiringSafeStep.status -eq 'safe-to-run-existing-helper') {
    $status = 'ready-for-existing-helper'
    $reason = 'The runner-output contract repair completed, and the safe runner-output wiring helper says the raw wiring helper is ready for the next Windows replay.'
} else {
    $status = 'follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        if ($wiringSafeStep) { $wiringSafeStep.reason },
        if ($repairStep) { $repairStep.reason },
        'The runner-output contract repair and safe wiring check completed, but the next issue #3 replay still needs the follow-up command reported by the saved artifacts.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($wiringSafeStep) { $wiringSafeStep.recommended_command },
    if ($repairStep) { $repairStep.recommended_command },
    $repairCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($wiringSafeStep) { $wiringSafeStep.recommended_guide_command },
    if ($repairStep) { $repairStep.recommended_guide_command },
    $summaryGuideCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($wiringSafeStep) { $wiringSafeStep.next_focus },
    if ($repairStep) { $repairStep.next_focus },
    if (-not $summaryExistsAfterRepair) { 'Regenerate the issue #3 recommended validation summary before asking the safe runner-output wiring helper to narrow the next replay.' }
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($wiringSafeStep) { $wiringSafeStep.next_artifact_to_open },
    if ($repairStep) { $repairStep.next_artifact_to_open },
    if ($summaryExistsAfterRepair) { $SummaryPath },
    $ArtifactPath
)

$report = [ordered]@{
    issue = 'Google issue #3 runner output contract repair plus safe wiring gate'
    purpose = 'Repair the saved issue #3 runner-output contract, then immediately confirm whether the safe runner-output wiring checkpoint is clear enough for the next Windows replay to trust the raw wiring helper.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    summary_exists_after_repair = [bool]$summaryExistsAfterRepair
    repair_status = $repairStep.status
    runner_output_wiring_safe_status = $wiringSafeStep.status
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    repair_command = $repairCommand
    runner_output_wiring_safe_command = $wiringSafeCommand
    runner_output_wiring_command = $wiringCommand
    runner_output_patch_targets_command = $patchTargetsCommand
    broader_runner_command = $broaderRunnerCommand
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
    if (@('repair-no-summary', 'repair-helper-failed', 'safe-wiring-check-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 runner output contract repair plus safe wiring gate'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary exists after repair: {0}" -f $report.summary_exists_after_repair)
Write-Host ("Repair:    {0}" -f $report.repair_status)
Write-Host ("Wiring safe: {0}" -f $report.runner_output_wiring_safe_status)
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

if (@('repair-no-summary', 'repair-helper-failed', 'safe-wiring-check-failed') -contains $status) {
    exit 1
}
