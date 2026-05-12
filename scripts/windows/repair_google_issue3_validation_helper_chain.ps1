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
        output_preview = @($outputLines | Select-Object -First 12)
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
        status = 'skipped-by-safe-gate'
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
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json"
}
if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    throw "Issue #3 recommended validation summary not found: $SummaryPath"
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$artifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
if ([string]::IsNullOrWhiteSpace($artifactRoot)) {
    $artifactRoot = Split-Path -Parent $SummaryPath
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-validation-helper-chain-repair.json'
}

$artifactPathRepairScript = Join-Path $PSScriptRoot 'repair_google_issue3_validation_artifact_paths.ps1'
$runnerContractRepairScript = Join-Path $PSScriptRoot 'repair_google_issue3_runner_output_contract.ps1'
$refreshChainScript = Join-Path $PSScriptRoot 'refresh_google_issue3_validation_handoff_chain.ps1'
$wiringStatusSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_wiring_status_safe.ps1'
$wiringStatusScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_wiring_status.ps1'
$handoffSafeRefreshRouteScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_handoff_safe_refresh_route.ps1'

$requiredHelpers = @(
    $artifactPathRepairScript,
    $runnerContractRepairScript,
    $refreshChainScript,
    $wiringStatusSafeScript,
    $wiringStatusScript,
    $handoffSafeRefreshRouteScript
)
foreach ($helperPath in $requiredHelpers) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$steps = [System.Collections.Generic.List[object]]::new()
$steps.Add((Invoke-JsonHelper -Name 'artifact-path-repair' -ScriptPath $artifactPathRepairScript -Arguments @('-SummaryPath', $SummaryPath, '-Json'))) | Out-Null
$steps.Add((Invoke-JsonHelper -Name 'runner-output-contract-repair' -ScriptPath $runnerContractRepairScript -Arguments @('-SummaryPath', $SummaryPath, '-Json'))) | Out-Null
$steps.Add((Invoke-JsonHelper -Name 'handoff-chain-refresh' -ScriptPath $refreshChainScript -Arguments @('-SummaryPath', $SummaryPath, '-Json'))) | Out-Null

$wiringSafeStep = Invoke-JsonHelper -Name 'runner-output-wiring-safe-status' -ScriptPath $wiringStatusSafeScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
$steps.Add($wiringSafeStep) | Out-Null

$runRawWiringStatus = [bool](
    $wiringSafeStep.success -and
    $wiringSafeStep.status -eq 'safe-to-run-existing-helper'
)
if ($runRawWiringStatus) {
    $steps.Add((Invoke-JsonHelper -Name 'runner-output-wiring-status' -ScriptPath $wiringStatusScript -Arguments @('-SummaryPath', $SummaryPath, '-Json'))) | Out-Null
} else {
    $steps.Add((New-SkippedHelperStep -Name 'runner-output-wiring-status' -ScriptPath $wiringStatusScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -RecommendedCommand $wiringSafeStep.recommended_command -RecommendedGuideCommand $wiringSafeStep.recommended_guide_command -NextFocus $wiringSafeStep.next_focus -NextArtifactToOpen $wiringSafeStep.next_artifact_to_open -Reason 'The safe wiring helper said the raw runner-output wiring helper was not the safest next checkpoint yet.')) | Out-Null
}

$steps.Add((Invoke-JsonHelper -Name 'handoff-safe-refresh-route' -ScriptPath $handoffSafeRefreshRouteScript -Arguments @('-SummaryPath', $SummaryPath, '-Json'))) | Out-Null

$failedSteps = @($steps | Where-Object { -not $_.success })
$wiringSafeStep = @($steps | Where-Object { $_.name -eq 'runner-output-wiring-safe-status' } | Select-Object -First 1)[0]
$wiringStep = @($steps | Where-Object { $_.name -eq 'runner-output-wiring-status' } | Select-Object -First 1)[0]
$handoffSafeRefreshRouteStep = @($steps | Where-Object { $_.name -eq 'handoff-safe-refresh-route' } | Select-Object -First 1)[0]
$repairStep = @($steps | Where-Object { $_.name -eq 'runner-output-contract-repair' } | Select-Object -First 1)[0]
$pathRepairStep = @($steps | Where-Object { $_.name -eq 'artifact-path-repair' } | Select-Object -First 1)[0]
$refreshChainStep = @($steps | Where-Object { $_.name -eq 'handoff-chain-refresh' } | Select-Object -First 1)[0]

$wiringSafeNeedsFollowUp = [bool](
    $wiringSafeStep -and
    $wiringSafeStep.success -and
    @('summary-artifact-root-missing', 'summary-manifest-path-missing', 'manifest-missing', 'manifest-unreadable') -contains $wiringSafeStep.status
)
$wiringFullyWired = [bool]($wiringStep -and $wiringStep.status -eq 'fully-wired')
$handoffReady = [bool]($handoffSafeRefreshRouteStep -and $handoffSafeRefreshRouteStep.status -eq 'ready-for-handoff')
$refreshFollowUpReady = [bool]($handoffSafeRefreshRouteStep -and $handoffSafeRefreshRouteStep.status -eq 'refresh-status-safe-follow-up-ready')

$status = $null
$reason = $null
if ($failedSteps.Count -gt 0) {
    $status = 'helper-failure'
    $reason = 'One or more issue #3 repair or audit helpers did not finish cleanly, so the helper chain still needs direct attention before the next Windows replay can trust the bounded handoff refresh route.'
} elseif ($handoffReady) {
    $status = 'ready-for-handoff'
    $reason = 'The saved issue #3 outputs were normalized, the safe wiring gate cleared the raw audit path, and the handoff safe refresh-route helper says the narrower handoff path is ready to use.'
} elseif ($wiringSafeNeedsFollowUp) {
    $status = 'wiring-safe-follow-up-needed'
    $reason = if ($wiringSafeStep.reason) {
        $wiringSafeStep.reason
    } else {
        'The safe runner-output wiring gate says the raw wiring audit is not the safest next checkpoint yet for the current saved outputs.'
    }
} elseif (-not $wiringFullyWired) {
    $status = 'runner-contract-still-open'
    $reason = 'The helper chain repairs ran, but the runner-output wiring audit still reports that the direct refresh and handoff contract is incomplete for the current saved outputs.'
} elseif ($refreshFollowUpReady) {
    $status = 'refresh-follow-up-ready'
    $reason = 'The helper chain repairs ran, the runner contract looks wired, and the handoff safe refresh-route helper already reopened the narrower refresh-safe checkpoint for the next replay.'
} else {
    $status = 'repair-follow-up-needed'
    $reason = 'The helper chain repairs completed, but the final handoff safe refresh-route checkpoint still does not recommend the narrow handoff path yet.'
}

$commandSources = @(
    if ($handoffSafeRefreshRouteStep) { $handoffSafeRefreshRouteStep.recommended_command },
    if ($wiringSafeStep) { $wiringSafeStep.recommended_command },
    if ($wiringStep) { $wiringStep.recommended_command },
    if ($refreshChainStep) { $refreshChainStep.recommended_command },
    if ($repairStep) { $repairStep.recommended_command },
    if ($pathRepairStep) { $pathRepairStep.recommended_command },
    'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
)
$guideSources = @(
    if ($handoffSafeRefreshRouteStep) { $handoffSafeRefreshRouteStep.recommended_guide_command },
    if ($wiringSafeStep) { $wiringSafeStep.recommended_guide_command },
    if ($wiringStep) { $wiringStep.recommended_guide_command },
    if ($refreshChainStep) { $refreshChainStep.recommended_guide_command },
    if ($repairStep) { $repairStep.recommended_guide_command },
    if ($pathRepairStep) { $pathRepairStep.recommended_guide_command },
    'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'
)
$focusSources = @(
    if ($handoffSafeRefreshRouteStep) { $handoffSafeRefreshRouteStep.next_focus },
    if ($wiringSafeStep) { $wiringSafeStep.next_focus },
    if ($wiringStep) { $wiringStep.next_focus },
    if ($refreshChainStep) { $refreshChainStep.next_focus },
    if ($repairStep) { $repairStep.next_focus },
    if ($pathRepairStep) { $pathRepairStep.next_focus }
)
$artifactSources = @(
    if ($handoffSafeRefreshRouteStep) { $handoffSafeRefreshRouteStep.next_artifact_to_open },
    if ($wiringSafeStep) { $wiringSafeStep.next_artifact_to_open },
    if ($wiringStep) { $wiringStep.next_artifact_to_open },
    if ($refreshChainStep) { $refreshChainStep.next_artifact_to_open },
    if ($repairStep) { $repairStep.next_artifact_to_open },
    if ($pathRepairStep) { $pathRepairStep.next_artifact_to_open },
    $SummaryPath
)

$recommendedCommand = Get-FirstNonEmptyValue -Values $commandSources
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values $guideSources
$nextFocus = Get-FirstNonEmptyValue -Values $focusSources
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values $artifactSources

$report = [ordered]@{
    issue = 'Google issue #3 validation helper-chain repair'
    purpose = 'Run the bounded issue #3 repair helpers in order, then route through the newer handoff safe refresh-route checkpoint and leave one final readiness verdict plus the best next command for the next Windows headed replay.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    status = $status
    reason = $reason
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    runner_output_wiring_safe_status = if ($wiringSafeStep) { $wiringSafeStep.status } else { $null }
    runner_output_wiring_status = if ($wiringStep) { $wiringStep.status } else { $null }
    handoff_safe_refresh_route_status = if ($handoffSafeRefreshRouteStep) { $handoffSafeRefreshRouteStep.status } else { $null }
    failed_step_count = $failedSteps.Count
    failed_step_names = @($failedSteps | ForEach-Object { $_.name })
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
    if ($status -eq 'helper-failure') {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 validation helper-chain repair'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Wiring safe: {0}" -f $report.runner_output_wiring_safe_status)
Write-Host ("Wiring raw:  {0}" -f $report.runner_output_wiring_status)
Write-Host ("Handoff route: {0}" -f $report.handoff_safe_refresh_route_status)
Write-Host ("Failed steps: {0}" -f $report.failed_step_count)
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

if ($status -eq 'helper-failure') {
    exit 1
}
