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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-runner-output-contract-handoff-safe.json'
}

$contractRepairScript = Join-Path $PSScriptRoot 'repair_google_issue3_runner_output_contract.ps1'
$handoffSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_handoff_safe.ps1'
$contractRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1'
$handoffSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$runnerWiringStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$patchTargetsCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'

foreach ($helperPath in @($contractRepairScript, $handoffSafeScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$contractRepairArguments = @('-SummaryPath', $SummaryPath, '-Json')
$handoffSafeArguments = @('-SummaryPath', $SummaryPath, '-Json')

$steps = [System.Collections.Generic.List[object]]::new()
$contractRepairStep = Invoke-ScriptStep -Name 'runner-output-contract-repair' -ScriptPath $contractRepairScript -Arguments $contractRepairArguments -ExpectJson
$steps.Add($contractRepairStep) | Out-Null

$summaryExistsAfterContractRepair = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$handoffSafeStep = $null
if ($summaryExistsAfterContractRepair) {
    $handoffSafeStep = Invoke-ScriptStep -Name 'handoff-safe-status' -ScriptPath $handoffSafeScript -Arguments $handoffSafeArguments -ExpectJson
    $steps.Add($handoffSafeStep) | Out-Null
} else {
    $handoffSafeStep = New-SkippedStep -Name 'handoff-safe-status' -ScriptPath $handoffSafeScript -Arguments $handoffSafeArguments -Reason 'The runner-output contract repair step did not leave a current summary artifact, so the safe handoff check had no replay state to inspect.' -RecommendedCommand $contractRepairCommand -RecommendedGuideCommand $summaryGuideCommand -NextFocus 'Get the saved issue #3 outputs back to a current summary artifact before checking the safe handoff gate.' -NextArtifactToOpen $ArtifactPath
    $steps.Add($handoffSafeStep) | Out-Null
}

$status = $null
$reason = $null
if (-not $summaryExistsAfterContractRepair) {
    $status = 'contract-repair-no-summary'
    $reason = 'The runner-output contract repair step did not leave a summary artifact, so the follow-up safe handoff check could not continue.'
} elseif (-not $contractRepairStep.success) {
    $status = 'contract-repair-failed'
    $reason = 'The runner-output contract repair step did not finish cleanly, so the next replay still needs direct contract repair attention before the handoff path is trusted.'
} elseif (-not $handoffSafeStep.success) {
    $status = 'handoff-safe-check-failed'
    $reason = 'The runner-output contract repair step completed, but the safe handoff helper did not finish cleanly, so the next replay should stay on the saved repair artifact first.'
} elseif ($handoffSafeStep.status -eq 'safe-to-run-handoff') {
    $status = 'ready-for-handoff'
    $reason = 'The saved runner-output contract is normalized, and the safe handoff helper says the narrower issue #3 handoff path is ready for the next Windows replay.'
} else {
    $status = 'follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        if ($handoffSafeStep) { $handoffSafeStep.reason },
        if ($contractRepairStep) { $contractRepairStep.reason },
        'The runner-output contract repair and safe handoff check completed, but the next issue #3 replay still needs the follow-up command reported by the saved artifacts.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($handoffSafeStep) { $handoffSafeStep.recommended_command },
    if ($contractRepairStep) { $contractRepairStep.recommended_command },
    $contractRepairCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($handoffSafeStep) { $handoffSafeStep.recommended_guide_command },
    if ($contractRepairStep) { $contractRepairStep.recommended_guide_command },
    $summaryGuideCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($handoffSafeStep) { $handoffSafeStep.next_focus },
    if ($contractRepairStep) { $contractRepairStep.next_focus },
    if (-not $summaryExistsAfterContractRepair) { 'Regenerate the issue #3 recommended validation summary before asking the safe handoff helper to narrow the next replay.' }
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($handoffSafeStep) { $handoffSafeStep.next_artifact_to_open },
    if ($contractRepairStep) { $contractRepairStep.next_artifact_to_open },
    if ($summaryExistsAfterContractRepair) { $SummaryPath },
    $ArtifactPath
)

$report = [ordered]@{
    issue = 'Google issue #3 runner-output contract repair plus safe handoff'
    purpose = 'Repair the saved issue #3 runner-output contract, then immediately confirm whether the safe handoff checkpoint is clear enough for the next Windows replay to trust the narrower handoff helper.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    summary_exists_after_contract_repair = [bool]$summaryExistsAfterContractRepair
    contract_repair_status = $contractRepairStep.status
    handoff_safe_status = $handoffSafeStep.status
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    contract_repair_command = $contractRepairCommand
    handoff_safe_command = $handoffSafeCommand
    handoff_guide_command = $handoffGuideCommand
    runner_wiring_status_command = $runnerWiringStatusCommand
    patch_targets_command = $patchTargetsCommand
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
    if (@('contract-repair-no-summary', 'contract-repair-failed', 'handoff-safe-check-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 runner-output contract repair plus safe handoff'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary exists after contract repair: {0}" -f $report.summary_exists_after_contract_repair)
Write-Host ("Contract repair: {0}" -f $report.contract_repair_status)
Write-Host ("Handoff safe: {0}" -f $report.handoff_safe_status)
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

if (@('contract-repair-no-summary', 'contract-repair-failed', 'handoff-safe-check-failed') -contains $status) {
    exit 1
}
