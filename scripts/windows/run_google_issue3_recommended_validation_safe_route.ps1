[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$SummaryPath,
    [string]$ArtifactPath,
    [switch]$Json,
    [switch]$LeaveOpen,
    [switch]$SkipAutoAttachedHtml
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

function Invoke-RunnerStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string]$SummaryPath,
        [string]$RepoRoot,
        [string]$BrowserExe,
        [switch]$LeaveOpen,
        [switch]$SkipAutoAttachedHtml
    )

    $arguments = @('-SummaryPath', $SummaryPath)
    if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
        $arguments += @('-RepoRoot', $RepoRoot)
    }
    if (-not [string]::IsNullOrWhiteSpace($BrowserExe)) {
        $arguments += @('-BrowserExe', $BrowserExe)
    }
    if ($LeaveOpen) {
        $arguments += '-LeaveOpen'
    }
    if ($SkipAutoAttachedHtml) {
        $arguments += '-SkipAutoAttachedHtml'
    }

    $startedAt = (Get-Date).ToUniversalTime().ToString('o')
    $output = @()
    $exitCode = 0
    $errorMessage = $null

    try {
        $output = @(
            & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @arguments 2>&1
        )
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            $errorMessage = "Runner exited with code $exitCode."
        }
    } catch {
        $exitCode = 1
        $errorMessage = $_.Exception.Message
    }

    return [pscustomobject]@{
        name = 'recommended-validation-runner'
        script_path = $ScriptPath
        arguments = @($arguments)
        started_at_utc = $startedAt
        completed_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        exit_code = $exitCode
        success = [bool]($exitCode -eq 0)
        status = if ($exitCode -eq 0) { 'completed' } else { 'failed' }
        parse_error = $null
        error = $errorMessage
        output_preview = @($output | ForEach-Object { "${_}" } | Select-Object -First 20)
        recommended_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
        recommended_guide_command = $null
        next_focus = if ($exitCode -eq 0) {
            'The recommended validation runner completed; use the safer helper chain below to decide the next bounded Windows replay step.'
        } else {
            'The recommended validation runner failed before the safer helper chain could confirm the next checkpoint.'
        }
        next_artifact_to_open = $SummaryPath
        reason = if ($exitCode -eq 0) {
            'The wrapper ran the broader issue #3 recommended validation first so the safe helper chain can reason over the latest saved summary and artifact family.'
        } else {
            'The broader issue #3 recommended validation did not complete cleanly, so the wrapper will only continue if a summary artifact is still available to inspect safely.'
        }
        record = $null
    }
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

$resolvedRepoRoot = if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot
} else {
    Resolve-RepoRoot $PSScriptRoot
}
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $resolvedRepoRoot 'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json'
}
$artifactRoot = Split-Path -Parent $SummaryPath
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-safe-route.json'
}

$runnerScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation.ps1'
$summaryGuideSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_summary_guide_safe.ps1'
$artifactBundleSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_artifact_bundle_safe.ps1'
$handoffSafeRefreshRouteScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_handoff_safe_refresh_route.ps1'

foreach ($helperPath in @($runnerScript, $summaryGuideSafeScript, $artifactBundleSafeScript, $handoffSafeRefreshRouteScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$runnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$summaryGuideSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'
$artifactBundleSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_artifact_bundle_safe.ps1'
$handoffSafeRefreshRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe_refresh_route.ps1'

$steps = [System.Collections.Generic.List[object]]::new()
$runnerStep = Invoke-RunnerStep -ScriptPath $runnerScript -SummaryPath $SummaryPath -RepoRoot $resolvedRepoRoot -BrowserExe $BrowserExe -LeaveOpen:$LeaveOpen -SkipAutoAttachedHtml:$SkipAutoAttachedHtml
$steps.Add($runnerStep) | Out-Null

$summaryExists = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$summaryGuideStep = $null
if ($summaryExists) {
    $summaryGuideStep = Invoke-JsonHelper -Name 'summary-guide-safe' -ScriptPath $summaryGuideSafeScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
} else {
    $summaryGuideStep = New-SkippedHelperStep -Name 'summary-guide-safe' -ScriptPath $summaryGuideSafeScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -RecommendedCommand $runnerCommand -RecommendedGuideCommand $null -NextFocus 'The recommended validation runner did not leave a summary artifact, so the safe helper chain has no saved state to inspect yet.' -NextArtifactToOpen $SummaryPath -Reason 'Skipped because the expected issue #3 recommended-validation summary does not exist.'
}
$steps.Add($summaryGuideStep) | Out-Null

$artifactBundleSafeStep = $null
if ($summaryGuideStep.success) {
    $artifactBundleSafeStep = Invoke-JsonHelper -Name 'artifact-bundle-safe' -ScriptPath $artifactBundleSafeScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
} else {
    $artifactBundleSafeStep = New-SkippedHelperStep -Name 'artifact-bundle-safe' -ScriptPath $artifactBundleSafeScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -RecommendedCommand $(Get-FirstNonEmptyValue -Values @($summaryGuideStep.recommended_command, $runnerCommand)) -RecommendedGuideCommand $(Get-FirstNonEmptyValue -Values @($summaryGuideStep.recommended_guide_command, $summaryGuideSafeCommand)) -NextFocus $(Get-FirstNonEmptyValue -Values @($summaryGuideStep.next_focus, 'The safe summary checkpoint needs attention before the bundle-safe wrapper can make a narrower handoff decision.')) -NextArtifactToOpen $(Get-FirstNonEmptyValue -Values @($summaryGuideStep.next_artifact_to_open, $SummaryPath)) -Reason 'Skipped because the safe summary guide did not complete cleanly.'
}
$steps.Add($artifactBundleSafeStep) | Out-Null

$shouldRunHandoffSafeRefreshRoute = [bool]($artifactBundleSafeStep.success -and $artifactBundleSafeStep.status -eq 'safe-to-run-existing-helper')
$handoffSafeRefreshRouteStep = $null
if ($shouldRunHandoffSafeRefreshRoute) {
    $handoffSafeRefreshRouteStep = Invoke-JsonHelper -Name 'handoff-safe-refresh-route' -ScriptPath $handoffSafeRefreshRouteScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
} else {
    $handoffSafeRefreshRouteStep = New-SkippedHelperStep -Name 'handoff-safe-refresh-route' -ScriptPath $handoffSafeRefreshRouteScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -RecommendedCommand $(Get-FirstNonEmptyValue -Values @($artifactBundleSafeStep.recommended_command, $summaryGuideStep.recommended_command, $runnerCommand)) -RecommendedGuideCommand $(Get-FirstNonEmptyValue -Values @($artifactBundleSafeStep.recommended_guide_command, $summaryGuideStep.recommended_guide_command, $artifactBundleSafeCommand)) -NextFocus $(Get-FirstNonEmptyValue -Values @($artifactBundleSafeStep.next_focus, $summaryGuideStep.next_focus, 'The bundle-safe checkpoint still needs follow-up before the narrower handoff-safe refresh route can run.')) -NextArtifactToOpen $(Get-FirstNonEmptyValue -Values @($artifactBundleSafeStep.next_artifact_to_open, $summaryGuideStep.next_artifact_to_open, $SummaryPath)) -Reason 'Skipped because the bundle-safe checkpoint did not yet declare the raw helper chain safe enough for the handoff-safe refresh route.'
}
$steps.Add($handoffSafeRefreshRouteStep) | Out-Null

$status = $null
$reason = $null
if (-not $runnerStep.success -and -not $summaryExists) {
    $status = 'runner-failed-no-summary'
    $reason = 'The broader issue #3 recommended validation did not finish cleanly and did not leave a summary artifact for the safer helper chain to inspect.'
} elseif (-not $summaryGuideStep.success) {
    $status = 'summary-guide-safe-failed'
    $reason = 'The safe summary guide did not complete cleanly, so the wrapper cannot make a trustworthy narrower recommendation yet.'
} elseif (-not $artifactBundleSafeStep.success) {
    $status = 'artifact-bundle-safe-failed'
    $reason = 'The safe artifact-bundle checkpoint did not complete cleanly, so the wrapper stopped before the narrower handoff-safe route.'
} elseif ($shouldRunHandoffSafeRefreshRoute -and -not $handoffSafeRefreshRouteStep.success) {
    $status = 'handoff-safe-refresh-route-failed'
    $reason = 'The wrapper reached the handoff-safe refresh route, but that narrowed checkpoint did not complete cleanly.'
} elseif ($shouldRunHandoffSafeRefreshRoute) {
    $status = 'handoff-safe-refresh-route-ready'
    $reason = 'The wrapper ran the broader issue #3 recommended validation and then chained straight into the safe handoff refresh route, so the next Windows replay can continue from the narrowed safe guidance.'
} elseif ($artifactBundleSafeStep.status -eq 'safe-to-run-existing-helper') {
    $status = 'bundle-safe-ready-for-handoff-route'
    $reason = 'The safe artifact-bundle checkpoint says the raw helper chain is coherent for the current summary, so the next replay can move on to the handoff-safe refresh route.'
} else {
    $status = 'safe-follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        $artifactBundleSafeStep.reason,
        $summaryGuideStep.reason,
        'The broader validation completed, but the safe helper chain still wants a bounded follow-up before the narrower handoff route is trusted.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunHandoffSafeRefreshRoute) { $handoffSafeRefreshRouteStep.recommended_command },
    $artifactBundleSafeStep.recommended_command,
    $summaryGuideStep.recommended_command,
    $runnerStep.recommended_command,
    $runnerCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunHandoffSafeRefreshRoute) { $handoffSafeRefreshRouteStep.recommended_guide_command },
    $artifactBundleSafeStep.recommended_guide_command,
    $summaryGuideStep.recommended_guide_command,
    $artifactBundleSafeCommand,
    $summaryGuideSafeCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunHandoffSafeRefreshRoute) { $handoffSafeRefreshRouteStep.next_focus },
    $artifactBundleSafeStep.next_focus,
    $summaryGuideStep.next_focus,
    $runnerStep.next_focus,
    'Run the broader issue #3 recommended validation first, then use the safe helper chain to choose the narrowest next checkpoint.'
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunHandoffSafeRefreshRoute) { $handoffSafeRefreshRouteStep.next_artifact_to_open },
    $artifactBundleSafeStep.next_artifact_to_open,
    $summaryGuideStep.next_artifact_to_open,
    $runnerStep.next_artifact_to_open,
    $SummaryPath
)

$report = [ordered]@{
    issue = 'Google issue #3 recommended validation safe route wrapper'
    purpose = 'Run the broader issue #3 recommended validation first and then continue through the safe summary, bundle, and handoff-refresh checkpoints so the next Windows replay can follow the safest narrowed route without manual step selection.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repo_root = $resolvedRepoRoot
    browser_exe = $BrowserExe
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    summary_available = [bool]$summaryExists
    runner_command = $runnerCommand
    summary_guide_safe_command = $summaryGuideSafeCommand
    artifact_bundle_safe_command = $artifactBundleSafeCommand
    handoff_safe_refresh_route_command = $handoffSafeRefreshRouteCommand
    leave_open = [bool]$LeaveOpen
    skip_auto_attached_html = [bool]$SkipAutoAttachedHtml
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
    if (@('runner-failed-no-summary', 'summary-guide-safe-failed', 'artifact-bundle-safe-failed', 'handoff-safe-refresh-route-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 recommended validation safe route wrapper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary available: {0}" -f $report.summary_available)
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

if (@('runner-failed-no-summary', 'summary-guide-safe-failed', 'artifact-bundle-safe-failed', 'handoff-safe-refresh-route-failed') -contains $status) {
    exit 1
}
