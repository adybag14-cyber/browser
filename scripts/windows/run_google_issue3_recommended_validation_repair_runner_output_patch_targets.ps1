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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-runner-output-patch-targets.json'
}

$runnerOutputSafeScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation_repair_runner_output_contract_safe.ps1'
$patchTargetsSafeRouteScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_patch_targets_safe_route.ps1'
$runnerOutputSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_contract_safe.ps1'
$patchTargetsSafeRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe_route.ps1'
$runnerOutputWiringCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$runnerOutputWiringSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

foreach ($helperPath in @($runnerOutputSafeScript, $patchTargetsSafeRouteScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$runnerOutputSafeArguments = @('-SummaryPath', $SummaryPath, '-Json')
if ($RunnerArgument) {
    $runnerOutputSafeArguments += '-RunnerArgument'
    $runnerOutputSafeArguments += $RunnerArgument
}
$patchTargetsSafeRouteArguments = @('-SummaryPath', $SummaryPath, '-Json')

$steps = [System.Collections.Generic.List[object]]::new()
$runnerOutputSafeStep = Invoke-ScriptStep -Name 'runner-output-contract-safe' -ScriptPath $runnerOutputSafeScript -Arguments $runnerOutputSafeArguments -ExpectJson
$steps.Add($runnerOutputSafeStep) | Out-Null

$summaryExistsAfterRunnerOutputSafe = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$patchTargetsStep = $null
if ($summaryExistsAfterRunnerOutputSafe) {
    $patchTargetsStep = Invoke-ScriptStep -Name 'runner-output-patch-targets-safe-route' -ScriptPath $patchTargetsSafeRouteScript -Arguments $patchTargetsSafeRouteArguments -ExpectJson
    $steps.Add($patchTargetsStep) | Out-Null
} else {
    $patchTargetsStep = New-SkippedStep -Name 'runner-output-patch-targets-safe-route' -ScriptPath $patchTargetsSafeRouteScript -Arguments $patchTargetsSafeRouteArguments -Reason 'The runner-output contract safe wrapper did not leave a current summary artifact, so the safe patch-target route had no current saved state to inspect.' -RecommendedCommand $runnerOutputSafeCommand -RecommendedGuideCommand $summaryGuideCommand -NextFocus 'Get the broader issue #3 runner-output repair flow to leave a fresh summary artifact before asking for exact runner patch targets.' -NextArtifactToOpen $ArtifactPath
    $steps.Add($patchTargetsStep) | Out-Null
}

$patchTargetsStatus = if ($patchTargetsStep.record) {
    Get-OptionalPropertyValue -Object $patchTargetsStep.record -Name 'status'
} else {
    $patchTargetsStep.status
}
$runnerPatchStillRequired = [bool]($patchTargetsStatus -eq 'ready-for-runner-patch')
$recommendedPatchTarget = if ($patchTargetsStep.record) {
    Get-OptionalPropertyValue -Object $patchTargetsStep.record -Name 'recommended_patch_target'
} else {
    $null
}
$patchTargetsVerificationCommand = if ($patchTargetsStep.record) {
    Get-OptionalPropertyValue -Object $patchTargetsStep.record -Name 'recommended_verification_command'
} else {
    $null
}
$patchTargetsRepairCommand = if ($patchTargetsStep.record) {
    Get-OptionalPropertyValue -Object $patchTargetsStep.record -Name 'recommended_repair_command'
} else {
    $null
}
$patchTargetsRegenerationCommand = if ($patchTargetsStep.record) {
    Get-OptionalPropertyValue -Object $patchTargetsStep.record -Name 'recommended_regeneration_command'
} else {
    $null
}
$missingRunnerFields = if ($patchTargetsStep.record) {
    @(Get-ArrayValue -Object $patchTargetsStep.record -Name 'missing_runner_fields')
} else {
    @()
}
$summaryPatchSnippetLines = if ($patchTargetsStep.record) {
    @(Get-ArrayValue -Object $patchTargetsStep.record -Name 'summary_patch_snippet_lines')
} else {
    @()
}
$manifestPatchSnippetLines = if ($patchTargetsStep.record) {
    @(Get-ArrayValue -Object $patchTargetsStep.record -Name 'manifest_patch_snippet_lines')
} else {
    @()
}

$status = $null
$reason = $null
if (-not $summaryExistsAfterRunnerOutputSafe) {
    $status = 'runner-output-safe-no-summary'
    $reason = 'The issue #3 runner-output contract safe wrapper did not leave a summary artifact, so the patch-target route could not narrow the next runner-side edit.'
} elseif (-not $runnerOutputSafeStep.success) {
    $status = 'runner-output-safe-failed'
    $reason = 'The issue #3 runner-output contract safe wrapper did not finish cleanly, so the next replay should stay on that bounded repair flow before trusting patch-target guidance.'
} elseif (-not $patchTargetsStep.success) {
    $status = 'patch-target-route-failed'
    $reason = 'The runner-output repair flow completed, but the safe patch-target route did not finish cleanly, so the next replay should reopen that bounded route first.'
} elseif ($runnerPatchStillRequired) {
    $status = 'patch-targets-ready'
    $reason = 'The runner-output repair flow completed and the safe patch-target route narrowed the remaining direct runner-output contract gap to exact fields in the recommended validation runner.'
} elseif ($patchTargetsStatus -eq 'already-direct') {
    $status = 'ready-for-runner-output-wiring'
    $reason = 'The safe patch-target route says the saved outputs already carry the direct runner-output contract, so the next Windows replay can reopen runner-output wiring guidance instead of another patch-target pass.'
} elseif ($patchTargetsStatus -eq 'runner-already-wired-regenerate-outputs') {
    $status = 'runner-already-wired-regenerate-outputs'
    $reason = 'The safe patch-target route says the live runner source is already wired and the saved outputs just need regeneration, so the next replay should regenerate the artifacts before trusting another patch-target pass.'
} else {
    $status = 'follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        if ($patchTargetsStep) { $patchTargetsStep.reason },
        if ($runnerOutputSafeStep) { $runnerOutputSafeStep.reason },
        'The runner-output repair flow and safe patch-target route completed, but the next replay still needs the follow-up command reported by the saved artifacts.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($status -eq 'ready-for-runner-output-wiring') { $runnerOutputWiringSafeCommand },
    if ($patchTargetsStep) { $patchTargetsStep.recommended_command },
    if ($runnerOutputSafeStep) { $runnerOutputSafeStep.recommended_command },
    $patchTargetsSafeRouteCommand,
    $patchTargetsRegenerationCommand,
    $recommendedRunnerCommand,
    $runnerOutputSafeCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($status -eq 'ready-for-runner-output-wiring') { $runnerOutputWiringCommand },
    if ($patchTargetsStep) { $patchTargetsStep.recommended_guide_command },
    if ($runnerOutputSafeStep) { $runnerOutputSafeStep.recommended_guide_command },
    if ($status -eq 'ready-for-runner-output-wiring') { $patchTargetsVerificationCommand },
    $runnerOutputWiringSafeCommand,
    $summaryGuideCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($runnerPatchStillRequired) { 'Use the emitted safe-route artifact to wire the remaining direct refresh and handoff fields into scripts/windows/run_google_issue3_recommended_validation.ps1, then rerun the narrower runner-output wiring audit.' },
    if ($status -eq 'ready-for-runner-output-wiring') { 'The direct runner-output contract looks wired, so reopen the safe runner-output wiring helper first and use the raw wiring audit as the stricter follow-up instead of reopening the patch-target route.' },
    if ($status -eq 'runner-already-wired-regenerate-outputs') { 'Regenerate or repair the saved issue #3 outputs on Windows now that the live runner source already carries the direct contract fields.' },
    if ($patchTargetsStep) { $patchTargetsStep.next_focus },
    if ($runnerOutputSafeStep) { $runnerOutputSafeStep.next_focus },
    if (-not $summaryExistsAfterRunnerOutputSafe) { 'Regenerate the issue #3 recommended validation summary before asking for exact runner patch targets.' }
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($patchTargetsStep) { $patchTargetsStep.next_artifact_to_open },
    if ($runnerOutputSafeStep) { $runnerOutputSafeStep.next_artifact_to_open },
    if ($summaryExistsAfterRunnerOutputSafe) { $SummaryPath },
    $ArtifactPath
)

$report = [ordered]@{
    issue = 'Google issue #3 recommended validation repair plus runner output patch targets'
    purpose = 'Run the issue #3 runner-output contract safe flow, then immediately reopen the safe patch-target route so the next Windows replay stays on strict-mode-safe guidance before any raw patch-target step is trusted.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    runner_argument_passthrough = @($RunnerArgument)
    summary_exists_after_runner_output_safe = [bool]$summaryExistsAfterRunnerOutputSafe
    runner_output_safe_status = $runnerOutputSafeStep.status
    patch_targets_status = $patchTargetsStatus
    runner_patch_still_required = [bool]$runnerPatchStillRequired
    recommended_patch_target = $recommendedPatchTarget
    recommended_verification_command = $patchTargetsVerificationCommand
    recommended_repair_command = $patchTargetsRepairCommand
    recommended_regeneration_command = $patchTargetsRegenerationCommand
    missing_runner_fields = @($missingRunnerFields)
    summary_patch_snippet_lines = @($summaryPatchSnippetLines)
    manifest_patch_snippet_lines = @($manifestPatchSnippetLines)
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    runner_output_safe_command = $runnerOutputSafeCommand
    patch_targets_safe_route_command = $patchTargetsSafeRouteCommand
    patch_targets_repair_command = $patchTargetsRepairCommand
    patch_targets_regeneration_command = $patchTargetsRegenerationCommand
    runner_output_wiring_command = $runnerOutputWiringCommand
    runner_output_wiring_safe_command = $runnerOutputWiringSafeCommand
    recommended_runner_command = $recommendedRunnerCommand
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
            summary_patch_snippet_lines = if ($_.record) { @(Get-ArrayValue -Object $_.record -Name 'summary_patch_snippet_lines') } else { @() }
            manifest_patch_snippet_lines = if ($_.record) { @(Get-ArrayValue -Object $_.record -Name 'manifest_patch_snippet_lines') } else { @() }
            output_preview = @($_.output_preview)
        }
    })
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    if (@('runner-output-safe-no-summary', 'runner-output-safe-failed', 'patch-target-route-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 recommended validation repair plus runner output patch targets'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary exists after runner-output safe flow: {0}" -f $report.summary_exists_after_runner_output_safe)
Write-Host ("Runner-output safe status: {0}" -f $report.runner_output_safe_status)
Write-Host ("Patch-target route status: {0}" -f $report.patch_targets_status)
Write-Host ("Runner patch still required: {0}" -f $report.runner_patch_still_required)
if ($report.recommended_patch_target) {
    Write-Host ("Patch target: {0}" -f $report.recommended_patch_target)
}
if ($report.recommended_verification_command) {
    Write-Host ("Verify:      {0}" -f $report.recommended_verification_command)
}
if ($report.recommended_repair_command) {
    Write-Host ("Repair:      {0}" -f $report.recommended_repair_command)
}
if ($report.recommended_regeneration_command) {
    Write-Host ("Rerun:       {0}" -f $report.recommended_regeneration_command)
}
if ($report.missing_runner_fields.Count -gt 0) {
    Write-Host 'Missing runner fields:'
    foreach ($fieldName in $report.missing_runner_fields) {
        Write-Host ("- {0}" -f $fieldName)
    }
}
if ($report.summary_patch_snippet_lines.Count -gt 0) {
    Write-Host ''
    Write-Host 'Summary patch snippet:'
    foreach ($line in $report.summary_patch_snippet_lines) {
        Write-Host $line
    }
}
if ($report.manifest_patch_snippet_lines.Count -gt 0) {
    Write-Host ''
    Write-Host 'Manifest patch snippet:'
    foreach ($line in $report.manifest_patch_snippet_lines) {
        Write-Host $line
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
    if ($step.missing_runner_fields.Count -gt 0) {
        Write-Host ("  Missing fields: {0}" -f ($step.missing_runner_fields -join ', '))
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)

if (@('runner-output-safe-no-summary', 'runner-output-safe-failed', 'patch-target-route-failed') -contains $status) {
    exit 1
}
