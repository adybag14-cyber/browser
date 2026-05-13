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

function Get-ArrayValue {
    param(
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $value = Get-OptionalPropertyValue -Object $Object -Name $Name
    if ($null -eq $value) {
        return @()
    }

    return @($value)
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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-runner-output-wiring-wrapper.json'
}

$contractSafeScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation_repair_runner_output_contract_safe.ps1'
$wiringStatusScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_wiring_status.ps1'
$contractSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_contract_safe.ps1'
$wiringStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$wiringStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$patchTargetsCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
$patchTargetsSafeRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe_route.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'

foreach ($helperPath in @($contractSafeScript, $wiringStatusScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$contractSafeArguments = @('-SummaryPath', $SummaryPath, '-Json')
if ($RunnerArgument) {
    $contractSafeArguments += '-RunnerArgument'
    $contractSafeArguments += $RunnerArgument
}
$wiringStatusArguments = @('-SummaryPath', $SummaryPath, '-Json')

$steps = [System.Collections.Generic.List[object]]::new()
$contractSafeStep = Invoke-ScriptStep -Name 'recommended-validation-contract-safe-wrapper' -ScriptPath $contractSafeScript -Arguments $contractSafeArguments -ExpectJson
$steps.Add($contractSafeStep) | Out-Null

$summaryExistsAfterContractSafe = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$wiringStatusStep = $null
if ($summaryExistsAfterContractSafe) {
    $wiringStatusStep = Invoke-ScriptStep -Name 'runner-output-wiring-status' -ScriptPath $wiringStatusScript -Arguments $wiringStatusArguments -ExpectJson
    $steps.Add($wiringStatusStep) | Out-Null
} else {
    $wiringStatusStep = New-SkippedStep -Name 'runner-output-wiring-status' -ScriptPath $wiringStatusScript -Arguments $wiringStatusArguments -Reason 'The contract-safe wrapper did not leave a current summary artifact, so the stricter runner-output wiring audit had no replay state to inspect.' -RecommendedCommand $contractSafeCommand -RecommendedGuideCommand $summaryGuideCommand -NextFocus 'Regenerate the issue #3 recommended validation summary before reopening the stricter runner-output wiring audit.' -NextArtifactToOpen $ArtifactPath
    $steps.Add($wiringStatusStep) | Out-Null
}

$wiringStatus = if ($wiringStatusStep.record) {
    Get-OptionalPropertyValue -Object $wiringStatusStep.record -Name 'status'
} else {
    $wiringStatusStep.status
}
$runnerOutputsFullyWired = if ($wiringStatusStep.record) {
    [bool](Get-OptionalPropertyValue -Object $wiringStatusStep.record -Name 'runner_outputs_fully_wired')
} else {
    $false
}
$runnerSourceIndicatesDirectFieldWiring = if ($wiringStatusStep.record) {
    [bool](Get-OptionalPropertyValue -Object $wiringStatusStep.record -Name 'runner_source_indicates_direct_field_wiring')
} else {
    $false
}
$runnerPatchStillRequired = if ($wiringStatusStep.record) {
    [bool](Get-OptionalPropertyValue -Object $wiringStatusStep.record -Name 'runner_patch_still_required')
} else {
    $false
}
$refreshContractIncomplete = if ($wiringStatusStep.record) {
    [bool](Get-OptionalPropertyValue -Object $wiringStatusStep.record -Name 'refresh_contract_incomplete')
} else {
    $false
}
$handoffContractIncomplete = if ($wiringStatusStep.record) {
    [bool](Get-OptionalPropertyValue -Object $wiringStatusStep.record -Name 'handoff_contract_incomplete')
} else {
    $false
}
$missingRunnerFields = if ($wiringStatusStep.record) {
    @(Get-ArrayValue -Object $wiringStatusStep.record -Name 'missing_runner_fields')
} else {
    @()
}

$status = $null
$reason = $null
if (-not $summaryExistsAfterContractSafe) {
    $status = 'contract-safe-no-summary'
    $reason = 'The issue #3 contract-safe wrapper did not leave a summary artifact, so the stricter runner-output wiring audit could not run.'
} elseif (-not $wiringStatusStep.success) {
    $status = 'wiring-audit-failed'
    $reason = 'The contract-safe wrapper completed with a current summary, but the stricter runner-output wiring audit did not finish cleanly.'
} elseif ($runnerOutputsFullyWired) {
    $status = 'fully-wired'
    $reason = 'The contract-safe wrapper completed and the stricter wiring audit confirms the recommended runner now exposes the direct refresh and handoff contract in both saved outputs.'
} elseif ($wiringStatus -eq 'saved-artifacts-stale-runner-already-wired') {
    $status = 'runner-already-wired-regenerate-outputs'
    $reason = 'The live runner source already carries the direct refresh and handoff fields, but the saved outputs still need regeneration or repair before the next narrower helper should be trusted.'
} elseif ($runnerPatchStillRequired) {
    $status = 'runner-patch-still-required'
    $reason = 'The stricter wiring audit still sees a direct runner-output contract gap, so the next Windows replay should stay focused on the exact refresh or handoff fields that remain missing.'
} elseif (-not $contractSafeStep.success) {
    $status = 'contract-safe-follow-up-ready'
    $reason = 'The contract-safe wrapper still reported a failure state, but it left enough saved output for the stricter wiring audit to narrow the next follow-up step.'
} else {
    $status = 'follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        if ($wiringStatusStep) { $wiringStatusStep.reason },
        if ($contractSafeStep) { $contractSafeStep.reason },
        'The contract-safe wrapper and stricter wiring audit completed, but the next issue #3 replay still needs the follow-up command reported by the current artifacts.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($wiringStatusStep) { $wiringStatusStep.recommended_command },
    if ($contractSafeStep) { $contractSafeStep.recommended_command },
    if ($runnerOutputsFullyWired) { $refreshStatusCommand },
    if ($runnerSourceIndicatesDirectFieldWiring) { $contractSafeCommand },
    if ($runnerPatchStillRequired) { $patchTargetsCommand },
    $wiringStatusCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($runnerOutputsFullyWired) { $handoffGuideCommand },
    if ($wiringStatusStep) { $wiringStatusStep.recommended_guide_command },
    if ($contractSafeStep) { $contractSafeStep.recommended_guide_command },
    if ($runnerPatchStillRequired) { $patchTargetsSafeRouteCommand },
    $wiringStatusSafeCommand,
    $summaryGuideCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($runnerOutputsFullyWired) { 'The direct runner-output contract is in place, so the next Windows replay can move on to the narrower refresh and handoff helpers instead of another runner patch loop.' },
    if ($runnerSourceIndicatesDirectFieldWiring -and -not $runnerOutputsFullyWired) { 'Regenerate or repair the current issue #3 outputs now that the live runner source already writes the direct fields, then rerun this wrapper before trusting another patch-target pass.' },
    if ($runnerPatchStillRequired) { 'Use the stricter wiring audit fields in this wrapper artifact to keep the next issue #3 patch focused on the exact refresh or handoff fields still missing from the recommended runner outputs.' },
    if ($wiringStatusStep) { $wiringStatusStep.next_focus },
    if ($contractSafeStep) { $contractSafeStep.next_focus }
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($wiringStatusStep) { $wiringStatusStep.next_artifact_to_open },
    if ($contractSafeStep) { $contractSafeStep.next_artifact_to_open },
    if ($summaryExistsAfterContractSafe) { $SummaryPath },
    $ArtifactPath
)

$report = [ordered]@{
    issue = 'Google issue #3 recommended validation contract-safe flow plus stricter runner-output wiring audit'
    purpose = 'Run the issue #3 contract-safe validation chain and immediately reopen the stricter runner-output wiring audit so the next Windows replay gets one combined readiness artifact for direct runner contract work.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    runner_argument_passthrough = @($RunnerArgument)
    summary_exists_after_contract_safe = [bool]$summaryExistsAfterContractSafe
    contract_safe_wrapper_status = $contractSafeStep.status
    wiring_status = $wiringStatus
    runner_outputs_fully_wired = [bool]$runnerOutputsFullyWired
    runner_source_indicates_direct_field_wiring = [bool]$runnerSourceIndicatesDirectFieldWiring
    runner_patch_still_required = [bool]$runnerPatchStillRequired
    refresh_contract_incomplete = [bool]$refreshContractIncomplete
    handoff_contract_incomplete = [bool]$handoffContractIncomplete
    missing_runner_fields = @($missingRunnerFields)
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    contract_safe_wrapper_command = $contractSafeCommand
    wiring_status_command = $wiringStatusCommand
    wiring_status_safe_command = $wiringStatusSafeCommand
    patch_targets_command = $patchTargetsCommand
    patch_targets_safe_route_command = $patchTargetsSafeRouteCommand
    refresh_status_command = $refreshStatusCommand
    handoff_guide_command = $handoffGuideCommand
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
            missing_runner_fields = if ($_.record) { @(Get-ArrayValue -Object $_.record -Name 'missing_runner_fields') } else { @() }
            refresh_contract_incomplete = if ($_.record) { [bool](Get-OptionalPropertyValue -Object $_.record -Name 'refresh_contract_incomplete') } else { $false }
            handoff_contract_incomplete = if ($_.record) { [bool](Get-OptionalPropertyValue -Object $_.record -Name 'handoff_contract_incomplete') } else { $false }
            runner_outputs_fully_wired = if ($_.record) { [bool](Get-OptionalPropertyValue -Object $_.record -Name 'runner_outputs_fully_wired') } else { $false }
            runner_source_indicates_direct_field_wiring = if ($_.record) { [bool](Get-OptionalPropertyValue -Object $_.record -Name 'runner_source_indicates_direct_field_wiring') } else { $false }
            runner_patch_still_required = if ($_.record) { [bool](Get-OptionalPropertyValue -Object $_.record -Name 'runner_patch_still_required') } else { $false }
            output_preview = @($_.output_preview)
        }
    })
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    if (@('contract-safe-no-summary', 'wiring-audit-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 contract-safe validation plus stricter wiring audit'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Contract-safe status: {0}" -f $report.contract_safe_wrapper_status)
Write-Host ("Wiring status: {0}" -f $report.wiring_status)
Write-Host ("Runner outputs fully wired: {0}" -f $report.runner_outputs_fully_wired)
Write-Host ("Runner source already wired: {0}" -f $report.runner_source_indicates_direct_field_wiring)
Write-Host ("Runner patch still required: {0}" -f $report.runner_patch_still_required)
Write-Host ("Refresh contract incomplete: {0}" -f $report.refresh_contract_incomplete)
Write-Host ("Handoff contract incomplete: {0}" -f $report.handoff_contract_incomplete)
if ($report.missing_runner_fields.Count -gt 0) {
    Write-Host 'Missing runner fields:'
    foreach ($fieldName in $report.missing_runner_fields) {
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

if (@('contract-safe-no-summary', 'wiring-audit-failed') -contains $status) {
    exit 1
}
