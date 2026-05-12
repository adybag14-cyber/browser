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

function Test-HasProperty {
    param(
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [bool]($Object -and $Object.PSObject.Properties[$Name])
}

function Get-OptionalPropertyValue {
    param(
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (Test-HasProperty -Object $Object -Name $Name) {
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

function Invoke-JsonHelper {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
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
    if (-not [string]::IsNullOrWhiteSpace($outputText)) {
        try {
            $record = $outputText | ConvertFrom-Json
        } catch {
            $parseError = $_.Exception.Message
        }
    }

    $stepStatus = if ($record -and (Test-HasProperty -Object $record -Name 'status')) {
        $record.status
    } elseif ($parseError) {
        'non-json-output'
    } elseif ($exitCode -eq 0) {
        'completed-no-json'
    } else {
        'helper-failed'
    }

    return [pscustomobject]@{
        name = $Name
        script_path = $ScriptPath
        arguments = @($Arguments)
        started_at_utc = $startedAt
        completed_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        exit_code = $exitCode
        success = [bool]($exitCode -eq 0 -and $null -ne $record)
        status = $stepStatus
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

function New-SkippedHelperStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [string]$RecommendedCommand,
        [string]$RecommendedGuideCommand,
        [string]$NextFocus,
        [string]$NextArtifactToOpen,
        [string]$Reason
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
        status = 'skipped-by-route'
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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-runner-output-contract-safe-route.json'
}

$runnerOutputContractRepairScript = Join-Path $PSScriptRoot 'repair_google_issue3_runner_output_contract.ps1'
$validationSafeRouteScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_safe_route.ps1'
$runnerOutputContractRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1'
$validationSafeRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_safe_route.ps1'
$runnerOutputWiringSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$runnerOutputWiringCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status.ps1'
$broaderRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

foreach ($helperPath in @($runnerOutputContractRepairScript, $validationSafeRouteScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$steps = [System.Collections.Generic.List[object]]::new()
$runnerOutputContractStep = Invoke-JsonHelper -Name 'runner-output-contract-repair' -ScriptPath $runnerOutputContractRepairScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
$steps.Add($runnerOutputContractStep) | Out-Null

$runnerOutputContractReadyForSafeRoute = [bool](
    $runnerOutputContractStep.success -and
    @('updated', 'noop') -contains $runnerOutputContractStep.status
)

$validationSafeRouteStep = $null
if ($runnerOutputContractReadyForSafeRoute) {
    $validationSafeRouteStep = Invoke-JsonHelper -Name 'validation-safe-route' -ScriptPath $validationSafeRouteScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
} else {
    $validationSafeRouteStep = New-SkippedHelperStep -Name 'validation-safe-route' -ScriptPath $validationSafeRouteScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -RecommendedCommand $(Get-FirstNonEmptyValue -Values @($runnerOutputContractStep.recommended_command, $runnerOutputContractRepairCommand)) -RecommendedGuideCommand $(Get-FirstNonEmptyValue -Values @($runnerOutputContractStep.recommended_guide_command, $runnerOutputWiringSafeCommand)) -NextFocus $(Get-FirstNonEmptyValue -Values @($runnerOutputContractStep.next_focus, 'Finish the bounded runner-output contract work before reopening the narrower validation safe route.')) -NextArtifactToOpen $(Get-FirstNonEmptyValue -Values @($runnerOutputContractStep.next_artifact_to_open, $SummaryPath)) -Reason 'The runner-output contract repair helper did not clear the saved outputs for the narrower validation safe route yet, so this wrapper kept the next replay on the repair-side guidance.'
}
$steps.Add($validationSafeRouteStep) | Out-Null

$status = $null
$reason = $null
if (-not $runnerOutputContractStep.success) {
    $status = 'runner-output-contract-repair-failed'
    $reason = 'The runner-output contract repair helper did not finish cleanly, so the next Windows replay should stay on that bounded repair checkpoint before reopening the narrower validation safe route.'
} elseif (-not $runnerOutputContractReadyForSafeRoute) {
    $status = 'runner-output-contract-follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        $runnerOutputContractStep.reason,
        'The runner-output contract repair helper completed, but it still recommends another bounded checkpoint before the narrower validation safe route is trusted again.'
    )
} elseif (-not $validationSafeRouteStep.success) {
    $status = 'validation-safe-route-failed'
    $reason = 'The runner-output contract repair helper cleared the saved outputs, but the narrower validation safe route did not finish cleanly, so the next replay should reopen that strict-mode-safe route directly.'
} else {
    $status = 'validation-safe-route-ready'
    $reason = 'The runner-output contract repair helper cleared the saved outputs enough to reopen the current strict-mode-safe validation route, and this wrapper carried the replay forward to that narrower checkpoint.'
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($runnerOutputContractReadyForSafeRoute) { $validationSafeRouteStep.recommended_command },
    $runnerOutputContractStep.recommended_command,
    if ($runnerOutputContractReadyForSafeRoute) { $validationSafeRouteCommand },
    $runnerOutputContractRepairCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($runnerOutputContractReadyForSafeRoute) { $validationSafeRouteStep.recommended_guide_command },
    $runnerOutputContractStep.recommended_guide_command,
    if ($runnerOutputContractReadyForSafeRoute) { $validationSafeRouteCommand },
    $runnerOutputWiringCommand,
    $runnerOutputWiringSafeCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($runnerOutputContractReadyForSafeRoute) { $validationSafeRouteStep.next_focus },
    $runnerOutputContractStep.next_focus,
    if ($runnerOutputContractReadyForSafeRoute) { 'Use the reopened validation safe route from this run before widening back out to broader issue #3 replay loops.' },
    'Keep the next replay on the bounded runner-output contract repair side until the validation safe route is ready again.'
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($runnerOutputContractReadyForSafeRoute) { $validationSafeRouteStep.next_artifact_to_open },
    $runnerOutputContractStep.next_artifact_to_open,
    $ArtifactPath,
    $SummaryPath
)

$report = [ordered]@{
    issue = 'Google issue #3 recommended validation plus runner-output contract repair and safe route'
    purpose = 'Run the bounded issue #3 runner-output contract repair first, then immediately reopen the current strict-mode-safe validation route when the saved summary and manifest are healthy enough.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    runner_output_contract_repair_command = $runnerOutputContractRepairCommand
    validation_safe_route_command = $validationSafeRouteCommand
    runner_output_wiring_safe_command = $runnerOutputWiringSafeCommand
    runner_output_wiring_command = $runnerOutputWiringCommand
    broader_runner_command = $broaderRunnerCommand
    runner_output_contract_ready_for_safe_route = [bool]$runnerOutputContractReadyForSafeRoute
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
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
            parse_error = $_.parse_error
            error = $_.error
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
    if (@('runner-output-contract-repair-failed', 'validation-safe-route-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 recommended validation plus runner-output contract repair and safe route'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Repair cleared safe route: {0}" -f $report.runner_output_contract_ready_for_safe_route)
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

if (@('runner-output-contract-repair-failed', 'validation-safe-route-failed') -contains $status) {
    exit 1
}
