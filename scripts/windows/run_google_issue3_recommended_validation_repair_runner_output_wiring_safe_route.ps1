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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-runner-output-wiring-safe-route.json'
}

$runnerOutputContractSafeScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation_repair_runner_output_contract_safe.ps1'
$runnerOutputWiringScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_wiring_status.ps1'
$runnerOutputContractSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_contract_safe.ps1'
$runnerOutputWiringCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$runnerOutputWiringSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$runnerOutputPatchTargetsSafeRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe_route.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'

foreach ($helperPath in @($runnerOutputContractSafeScript, $runnerOutputWiringScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$runnerOutputContractSafeArguments = @('-SummaryPath', $SummaryPath, '-Json')
if ($RunnerArgument) {
    foreach ($argument in $RunnerArgument) {
        $runnerOutputContractSafeArguments += @('-RunnerArgument', $argument)
    }
}
$runnerOutputWiringArguments = @('-SummaryPath', $SummaryPath, '-Json')

$steps = [System.Collections.Generic.List[object]]::new()
$runnerOutputContractSafeStep = Invoke-ScriptStep -Name 'runner-output-contract-safe-wrapper' -ScriptPath $runnerOutputContractSafeScript -Arguments $runnerOutputContractSafeArguments -ExpectJson
$steps.Add($runnerOutputContractSafeStep) | Out-Null

$summaryExistsAfterSafeWrapper = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$readyForRunnerOutputWiring = [bool](
    $summaryExistsAfterSafeWrapper -and
    $runnerOutputContractSafeStep.success -and
    $runnerOutputContractSafeStep.status -eq 'ready-for-runner-output-wiring'
)

$runnerOutputWiringStep = $null
if ($readyForRunnerOutputWiring) {
    $runnerOutputWiringStep = Invoke-ScriptStep -Name 'runner-output-wiring' -ScriptPath $runnerOutputWiringScript -Arguments $runnerOutputWiringArguments -ExpectJson
} else {
    $runnerOutputWiringStep = New-SkippedStep -Name 'runner-output-wiring' -ScriptPath $runnerOutputWiringScript -Arguments $runnerOutputWiringArguments -Reason 'Skipped because the runner-output contract safe wrapper did not yet clear the raw wiring audit for the current saved summary.' -RecommendedCommand $(Get-FirstNonEmptyValue -Values @($runnerOutputContractSafeStep.recommended_command, $runnerOutputContractSafeCommand)) -RecommendedGuideCommand $(Get-FirstNonEmptyValue -Values @($runnerOutputContractSafeStep.recommended_guide_command, $runnerOutputPatchTargetsSafeRouteCommand, $summaryGuideCommand)) -NextFocus $(Get-FirstNonEmptyValue -Values @($runnerOutputContractSafeStep.next_focus, 'Finish the bounded runner-output contract follow-up before reopening the raw wiring audit.')) -NextArtifactToOpen $(Get-FirstNonEmptyValue -Values @($runnerOutputContractSafeStep.next_artifact_to_open, $SummaryPath, $ArtifactPath))
}
$steps.Add($runnerOutputWiringStep) | Out-Null

$status = $null
$reason = $null
if (-not $summaryExistsAfterSafeWrapper) {
    $status = 'safe-wrapper-no-summary'
    $reason = 'The runner-output contract safe wrapper did not leave a current summary artifact, so the raw wiring audit could not be reopened for this replay.'
} elseif (-not $runnerOutputContractSafeStep.success) {
    $status = 'runner-output-contract-safe-wrapper-failed'
    $reason = 'The bounded runner-output contract wrapper did not finish cleanly, so the next replay should stay on that stricter repair-and-safe-wiring checkpoint.'
} elseif (-not $readyForRunnerOutputWiring) {
    $status = 'safe-wrapper-follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        $runnerOutputContractSafeStep.reason,
        'The bounded runner-output contract wrapper completed, but it still wants another safe follow-up before the raw wiring audit is reopened.'
    )
} elseif (-not $runnerOutputWiringStep.success) {
    $status = 'runner-output-wiring-failed'
    $reason = 'The wrapper cleared the safe gate and reopened the raw runner-output wiring audit, but that stricter checkpoint did not finish cleanly.'
} elseif ($runnerOutputWiringStep.status -eq 'fully-wired') {
    $status = 'runner-output-fully-wired'
    $reason = 'The bounded runner-output contract wrapper cleared the safe gate, and the reopened raw wiring audit reports that the summary and manifest are now fully wired.'
} else {
    $status = 'runner-output-wiring-follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        $runnerOutputWiringStep.reason,
        'The raw runner-output wiring audit ran, but the next replay still needs the narrower follow-up command it reported.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($readyForRunnerOutputWiring) { $runnerOutputWiringStep.recommended_command },
    $runnerOutputContractSafeStep.recommended_command,
    if ($readyForRunnerOutputWiring) { $runnerOutputWiringCommand },
    $runnerOutputContractSafeCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($readyForRunnerOutputWiring) { $runnerOutputWiringStep.recommended_guide_command },
    $runnerOutputContractSafeStep.recommended_guide_command,
    if (-not $readyForRunnerOutputWiring) { $runnerOutputPatchTargetsSafeRouteCommand },
    $runnerOutputWiringSafeCommand,
    $summaryGuideCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($readyForRunnerOutputWiring) { $runnerOutputWiringStep.next_focus },
    $runnerOutputContractSafeStep.next_focus,
    if ($readyForRunnerOutputWiring) { 'Use the reopened raw wiring audit result from this run before widening back out to broader issue #3 replay loops.' },
    'Keep the next replay on the bounded runner-output contract wrapper until the raw wiring audit is cleared.'
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($readyForRunnerOutputWiring) { $runnerOutputWiringStep.next_artifact_to_open },
    $runnerOutputContractSafeStep.next_artifact_to_open,
    if ($summaryExistsAfterSafeWrapper) { $SummaryPath },
    $ArtifactPath
)

$report = [ordered]@{
    issue = 'Google issue #3 runner output wiring safe-route wrapper'
    purpose = 'Run the bounded issue #3 runner-output contract wrapper first, then immediately reopen the raw runner-output wiring audit once the safe gate says the saved summary is ready.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    runner_argument_passthrough = @($RunnerArgument)
    summary_exists_after_safe_wrapper = [bool]$summaryExistsAfterSafeWrapper
    ready_for_runner_output_wiring = [bool]$readyForRunnerOutputWiring
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    runner_output_contract_safe_command = $runnerOutputContractSafeCommand
    runner_output_wiring_command = $runnerOutputWiringCommand
    runner_output_wiring_safe_command = $runnerOutputWiringSafeCommand
    runner_output_patch_targets_safe_route_command = $runnerOutputPatchTargetsSafeRouteCommand
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
    if (@('safe-wrapper-no-summary', 'runner-output-contract-safe-wrapper-failed', 'runner-output-wiring-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 runner output wiring safe-route wrapper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary exists after safe wrapper: {0}" -f $report.summary_exists_after_safe_wrapper)
Write-Host ("Ready for raw wiring audit: {0}" -f $report.ready_for_runner_output_wiring)
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

if (@('safe-wrapper-no-summary', 'runner-output-contract-safe-wrapper-failed', 'runner-output-wiring-failed') -contains $status) {
    exit 1
}
