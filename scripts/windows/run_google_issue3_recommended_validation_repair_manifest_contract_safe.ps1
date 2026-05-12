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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-manifest-contract-safe.json'
}

$recommendedRunnerScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation.ps1'
$manifestContractRepairScript = Join-Path $PSScriptRoot 'repair_google_issue3_validation_manifest_contract.ps1'
$manifestSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_manifest_safe.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$manifestContractRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_manifest_contract.ps1'
$manifestSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest_safe.ps1'
$manifestGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_manifest.ps1'
$runnerWiringStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$handoffSafeRefreshRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe_refresh_route.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'

foreach ($helperPath in @($recommendedRunnerScript, $manifestContractRepairScript, $manifestSafeScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$runnerArguments = @('-SummaryPath', $SummaryPath)
if ($RunnerArgument) {
    $runnerArguments += $RunnerArgument
}
$manifestContractRepairArguments = @('-SummaryPath', $SummaryPath, '-Json')
$manifestSafeArguments = @('-SummaryPath', $SummaryPath, '-Json')

$steps = [System.Collections.Generic.List[object]]::new()
$runnerStep = Invoke-ScriptStep -Name 'recommended-validation-runner' -ScriptPath $recommendedRunnerScript -Arguments $runnerArguments
$steps.Add($runnerStep) | Out-Null

$summaryExistsAfterRunner = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$manifestContractRepairStep = $null
if ($summaryExistsAfterRunner) {
    $manifestContractRepairStep = Invoke-ScriptStep -Name 'manifest-contract-repair' -ScriptPath $manifestContractRepairScript -Arguments $manifestContractRepairArguments -ExpectJson
    $steps.Add($manifestContractRepairStep) | Out-Null
} else {
    $manifestContractRepairStep = New-SkippedStep -Name 'manifest-contract-repair' -ScriptPath $manifestContractRepairScript -Arguments $manifestContractRepairArguments -Reason 'The broader recommended runner did not leave a summary artifact, so the manifest-contract repair step had no current saved state to normalize.' -RecommendedCommand $recommendedRunnerCommand -RecommendedGuideCommand $runnerWiringStatusSafeCommand -NextFocus 'Get the broader issue #3 recommended runner to produce a fresh summary artifact before asking the manifest-contract repair helper to narrow the next replay.' -NextArtifactToOpen $ArtifactPath
    $steps.Add($manifestContractRepairStep) | Out-Null
}

$summaryExistsAfterManifestRepair = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$manifestSafeStep = $null
if ($summaryExistsAfterManifestRepair) {
    $manifestSafeStep = Invoke-ScriptStep -Name 'manifest-safe-status' -ScriptPath $manifestSafeScript -Arguments $manifestSafeArguments -ExpectJson
    $steps.Add($manifestSafeStep) | Out-Null
} else {
    $manifestSafeStep = New-SkippedStep -Name 'manifest-safe-status' -ScriptPath $manifestSafeScript -Arguments $manifestSafeArguments -Reason 'The manifest-contract repair step did not leave a current summary artifact, so the safe manifest check had no replay state to inspect.' -RecommendedCommand $manifestContractRepairCommand -RecommendedGuideCommand $summaryGuideCommand -NextFocus 'Get the saved issue #3 outputs back to a current summary artifact before checking the safe manifest gate.' -NextArtifactToOpen $ArtifactPath
    $steps.Add($manifestSafeStep) | Out-Null
}

$status = $null
$reason = $null
if (-not $summaryExistsAfterRunner) {
    $status = 'runner-failed-no-summary'
    $reason = 'The broader issue #3 recommended runner did not leave a summary artifact, so the follow-up manifest contract repair could not continue from the current replay.'
} elseif (-not $manifestContractRepairStep.success) {
    $status = 'manifest-contract-repair-failed'
    $reason = 'The broader runner produced saved outputs, but the follow-up manifest-contract repair did not finish cleanly, so the next replay still needs direct manifest-contract attention.'
} elseif (-not $manifestSafeStep.success) {
    $status = 'manifest-safe-check-failed'
    $reason = 'The manifest-contract repair step completed, but the safe manifest helper did not finish cleanly, so the next replay should stay on the saved repair artifact first.'
} elseif ($manifestSafeStep.status -eq 'safe-to-run-manifest-guide') {
    $status = 'ready-for-handoff-safe-refresh-route'
    $reason = 'The broader runner completed, the manifest-contract repair normalized the saved manifest metadata, and the safe manifest helper says the next Windows replay should continue through the newer handoff-safe refresh route.'
} elseif (-not $runnerStep.success) {
    $status = 'runner-failed-follow-up-ready'
    $reason = 'The broader runner still failed, but it left enough saved state for the manifest-contract repair and safe manifest check to narrow the next issue #3 follow-up step.'
} else {
    $status = 'follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        if ($manifestSafeStep) { $manifestSafeStep.reason },
        if ($manifestContractRepairStep) { $manifestContractRepairStep.reason },
        'The broader runner, manifest-contract repair, and safe manifest check completed, but the next issue #3 replay still needs the follow-up command reported by the saved artifacts.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($status -eq 'ready-for-handoff-safe-refresh-route') { $handoffSafeRefreshRouteCommand },
    if ($manifestSafeStep) { $manifestSafeStep.recommended_command },
    if ($manifestContractRepairStep) { $manifestContractRepairStep.recommended_command },
    if (-not $runnerStep.success) { $recommendedRunnerCommand },
    $manifestContractRepairCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($status -eq 'ready-for-handoff-safe-refresh-route') { $handoffSafeRefreshRouteCommand },
    if ($manifestSafeStep) { $manifestSafeStep.recommended_guide_command },
    if ($manifestContractRepairStep) { $manifestContractRepairStep.recommended_guide_command },
    if ($manifestSafeStep -and $manifestSafeStep.status -eq 'safe-to-run-manifest-guide') { $manifestGuideCommand },
    $runnerWiringStatusSafeCommand,
    $summaryGuideCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($manifestSafeStep) { $manifestSafeStep.next_focus },
    if ($manifestContractRepairStep) { $manifestContractRepairStep.next_focus },
    if (-not $summaryExistsAfterRunner) { 'Regenerate the issue #3 recommended validation summary before asking the manifest-contract repair helper to narrow the replay.' },
    if (-not $runnerStep.success) { 'Inspect the broader runner output first, then use the manifest repair and safe-check results to stay on the narrowest next replay.' }
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($manifestSafeStep) { $manifestSafeStep.next_artifact_to_open },
    if ($manifestContractRepairStep) { $manifestContractRepairStep.next_artifact_to_open },
    if ($summaryExistsAfterRunner) { $SummaryPath },
    $ArtifactPath
)

$report = [ordered]@{
    issue = 'Google issue #3 recommended validation plus manifest-contract repair and safe manifest check'
    purpose = 'Run the broader issue #3 recommended validation replay, repair the saved manifest contract, then immediately confirm whether the safe manifest checkpoint is clear enough for the next Windows replay to trust the narrower manifest guide.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    runner_argument_passthrough = @($RunnerArgument)
    summary_exists_after_runner = [bool]$summaryExistsAfterRunner
    summary_exists_after_manifest_repair = [bool]$summaryExistsAfterManifestRepair
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    broader_runner_command = $recommendedRunnerCommand
    manifest_contract_repair_command = $manifestContractRepairCommand
    manifest_safe_command = $manifestSafeCommand
    manifest_guide_command = $manifestGuideCommand
    runner_wiring_status_safe_command = $runnerWiringStatusSafeCommand
    handoff_safe_refresh_route_command = $handoffSafeRefreshRouteCommand
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
    if (@('runner-failed-no-summary', 'manifest-contract-repair-failed', 'manifest-safe-check-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 recommended validation plus manifest-contract repair and safe manifest check'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary exists after runner: {0}" -f $report.summary_exists_after_runner)
Write-Host ("Summary exists after manifest repair: {0}" -f $report.summary_exists_after_manifest_repair)
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

if (@('runner-failed-no-summary', 'manifest-contract-repair-failed', 'manifest-safe-check-failed') -contains $status) {
    exit 1
}
