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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-runner-output-patch-followup-safe-route.json'
}

$wiringSafeRouteScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation_repair_runner_output_wiring_safe_route.ps1'
$patchTargetsSafeRouteScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_patch_targets_safe_route.ps1'
$wiringSafeRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_wiring_safe_route.ps1'
$patchTargetsSafeRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe_route.ps1'
$runnerOutputWiringSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$broaderRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

foreach ($helperPath in @($wiringSafeRouteScript, $patchTargetsSafeRouteScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$wiringSafeRouteArguments = @('-SummaryPath', $SummaryPath, '-Json')
if ($RunnerArgument) {
    foreach ($argument in $RunnerArgument) {
        $wiringSafeRouteArguments += @('-RunnerArgument', $argument)
    }
}
$patchTargetsSafeRouteArguments = @('-SummaryPath', $SummaryPath, '-Json')

$steps = [System.Collections.Generic.List[object]]::new()
$wiringSafeRouteStep = Invoke-ScriptStep -Name 'runner-output-wiring-safe-route' -ScriptPath $wiringSafeRouteScript -Arguments $wiringSafeRouteArguments -ExpectJson
$steps.Add($wiringSafeRouteStep) | Out-Null

$summaryExistsAfterWiringRoute = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$requestedPatchTargetRoute = [bool](
    $summaryExistsAfterWiringRoute -and
    $wiringSafeRouteStep.success -and
    (
        $wiringSafeRouteStep.recommended_command -eq $patchTargetsSafeRouteCommand -or
        $wiringSafeRouteStep.recommended_guide_command -eq $patchTargetsSafeRouteCommand
    )
)

$patchTargetsSafeRouteStep = $null
if ($requestedPatchTargetRoute) {
    $patchTargetsSafeRouteStep = Invoke-ScriptStep -Name 'runner-output-patch-target-safe-route' -ScriptPath $patchTargetsSafeRouteScript -Arguments $patchTargetsSafeRouteArguments -ExpectJson
} else {
    $patchTargetsSafeRouteStep = New-SkippedStep -Name 'runner-output-patch-target-safe-route' -ScriptPath $patchTargetsSafeRouteScript -Arguments $patchTargetsSafeRouteArguments -Reason 'Skipped because the safe runner-output wiring route did not hand off to the patch-target safe route for the current summary.' -RecommendedCommand $(Get-FirstNonEmptyValue -Values @($wiringSafeRouteStep.recommended_command, $wiringSafeRouteCommand)) -RecommendedGuideCommand $(Get-FirstNonEmptyValue -Values @($wiringSafeRouteStep.recommended_guide_command, $runnerOutputWiringSafeCommand)) -NextFocus $(Get-FirstNonEmptyValue -Values @($wiringSafeRouteStep.next_focus, 'Follow the current safe runner-output wiring guidance before reopening the patch-target route.')) -NextArtifactToOpen $(Get-FirstNonEmptyValue -Values @($wiringSafeRouteStep.next_artifact_to_open, $SummaryPath, $ArtifactPath))
}
$steps.Add($patchTargetsSafeRouteStep) | Out-Null

$recommendedPatchTarget = $null
$recommendedRegenerationCommand = $null
$recommendedVerificationCommand = $null
$recommendedRepairCommand = $null
$runnerPatchStillRequired = $false
$missingRunnerFields = @()
$summaryPatchSnippetLines = @()
$manifestPatchSnippetLines = @()
if ($patchTargetsSafeRouteStep.record) {
    $recommendedPatchTarget = Get-OptionalPropertyValue -Object $patchTargetsSafeRouteStep.record -Name 'recommended_patch_target'
    $recommendedRegenerationCommand = Get-OptionalPropertyValue -Object $patchTargetsSafeRouteStep.record -Name 'recommended_regeneration_command'
    $recommendedVerificationCommand = Get-OptionalPropertyValue -Object $patchTargetsSafeRouteStep.record -Name 'recommended_verification_command'
    $recommendedRepairCommand = Get-OptionalPropertyValue -Object $patchTargetsSafeRouteStep.record -Name 'recommended_repair_command'
    $runnerPatchStillRequired = [bool](Get-OptionalPropertyValue -Object $patchTargetsSafeRouteStep.record -Name 'runner_patch_still_required')
    $missingRunnerFields = @(Get-ArrayValue -Object $patchTargetsSafeRouteStep.record -Name 'missing_runner_fields')
    $summaryPatchSnippetLines = @(Get-ArrayValue -Object $patchTargetsSafeRouteStep.record -Name 'summary_patch_snippet_lines')
    $manifestPatchSnippetLines = @(Get-ArrayValue -Object $patchTargetsSafeRouteStep.record -Name 'manifest_patch_snippet_lines')
}

$status = $null
$reason = $null
if (-not $summaryExistsAfterWiringRoute) {
    $status = 'wiring-safe-route-no-summary'
    $reason = 'The safe runner-output wiring route did not leave a current summary artifact, so the patch-target safe route could not be reopened.'
} elseif (-not $wiringSafeRouteStep.success) {
    $status = 'wiring-safe-route-failed'
    $reason = 'The safe runner-output wiring route did not finish cleanly, so the next replay should stay on that bounded helper chain before widening into patch-target follow-up.'
} elseif ($requestedPatchTargetRoute -and -not $patchTargetsSafeRouteStep.success) {
    $status = 'patch-target-safe-route-failed'
    $reason = 'The safe runner-output wiring route handed off to the patch-target safe route, but that narrower follow-up helper did not finish cleanly.'
} elseif ($requestedPatchTargetRoute -and $patchTargetsSafeRouteStep.status -eq 'ready-for-runner-patch') {
    $status = 'ready-for-runner-patch'
    $reason = 'The safe runner-output wiring route completed and the patch-target safe route surfaced the direct runner patch guidance needed for the recommended validation runner.'
} elseif ($requestedPatchTargetRoute -and $patchTargetsSafeRouteStep.status -eq 'runner-already-wired-regenerate-outputs') {
    $status = 'runner-already-wired-regenerate-outputs'
    $reason = 'The helper chain reached patch-target follow-up, but the saved outputs are now stale relative to a runner source that already carries the direct contract fields.'
} elseif ($requestedPatchTargetRoute -and $patchTargetsSafeRouteStep.status -eq 'already-direct') {
    $status = 'already-direct'
    $reason = 'The helper chain reached patch-target follow-up and confirmed the saved summary and manifest already expose the direct runner-output contract.'
} elseif ($requestedPatchTargetRoute) {
    $status = 'patch-target-follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        $patchTargetsSafeRouteStep.reason
        'The patch-target safe route ran, but the next replay still needs the narrower follow-up it reported.'
    )
} elseif ($wiringSafeRouteStep.status -eq 'runner-output-fully-wired') {
    $status = 'runner-output-fully-wired'
    $reason = 'The safe runner-output wiring route already reports a fully wired summary and manifest, so patch-target follow-up is unnecessary.'
} else {
    $status = 'wiring-safe-route-follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        $wiringSafeRouteStep.reason
        'The safe runner-output wiring route completed, but the next replay still needs the bounded follow-up it reported before patch-target guidance becomes relevant.'
    )
}

$patchTargetsRouteRecommendedCommand = if ($requestedPatchTargetRoute) { $patchTargetsSafeRouteStep.recommended_command } else { $null }
$patchTargetsRouteRecommendedGuideCommand = if ($requestedPatchTargetRoute) { $patchTargetsSafeRouteStep.recommended_guide_command } else { $null }
$patchTargetsRouteNextFocus = if ($requestedPatchTargetRoute) { $patchTargetsSafeRouteStep.next_focus } else { $null }
$patchTargetsRouteNextArtifact = if ($requestedPatchTargetRoute) { $patchTargetsSafeRouteStep.next_artifact_to_open } else { $null }
$patchTargetsRouteFallbackCommand = if ($requestedPatchTargetRoute) { $patchTargetsSafeRouteCommand } else { $null }
$patchTargetsRouteFallbackGuide = if ($requestedPatchTargetRoute) { $runnerOutputWiringSafeCommand } else { $null }
$patchTargetsRouteFallbackFocus = if ($requestedPatchTargetRoute) { 'Use the preserved patch-target artifact from this run to land the runner-contract fix before widening back out.' } else { $null }
$summaryFallbackArtifact = if ($summaryExistsAfterWiringRoute) { $SummaryPath } else { $null }

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    $patchTargetsRouteRecommendedCommand
    $wiringSafeRouteStep.recommended_command
    $patchTargetsRouteFallbackCommand
    $wiringSafeRouteCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    $patchTargetsRouteRecommendedGuideCommand
    $wiringSafeRouteStep.recommended_guide_command
    $patchTargetsRouteFallbackGuide
    $patchTargetsSafeRouteCommand
    $runnerOutputWiringSafeCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    $patchTargetsRouteNextFocus
    $wiringSafeRouteStep.next_focus
    $patchTargetsRouteFallbackFocus
    'Keep the next replay on the safe runner-output wiring chain until it is ready to surface patch-target guidance.'
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    $patchTargetsRouteNextArtifact
    $wiringSafeRouteStep.next_artifact_to_open
    $summaryFallbackArtifact
    $ArtifactPath
)

$report = [ordered]@{
    issue = 'Google issue #3 runner output patch follow-up safe route'
    purpose = 'Run the safe runner-output wiring route first and, when that route says the next narrow step is patch-target follow-up, immediately reopen the patch-target safe route so the next Windows replay can move from repair routing to runner patch guidance without a manual extra step.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    runner_argument_passthrough = @($RunnerArgument)
    summary_exists_after_wiring_route = [bool]$summaryExistsAfterWiringRoute
    requested_patch_target_route = [bool]$requestedPatchTargetRoute
    wiring_safe_route_command = $wiringSafeRouteCommand
    patch_targets_safe_route_command = $patchTargetsSafeRouteCommand
    runner_output_wiring_safe_command = $runnerOutputWiringSafeCommand
    broader_runner_command = $broaderRunnerCommand
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    recommended_patch_target = $recommendedPatchTarget
    recommended_regeneration_command = $recommendedRegenerationCommand
    recommended_verification_command = $recommendedVerificationCommand
    recommended_repair_command = $recommendedRepairCommand
    runner_patch_still_required = [bool]$runnerPatchStillRequired
    missing_runner_fields = @($missingRunnerFields)
    summary_patch_snippet_lines = @($summaryPatchSnippetLines)
    manifest_patch_snippet_lines = @($manifestPatchSnippetLines)
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
            runner_patch_still_required = if ($_.record) { [bool](Get-OptionalPropertyValue -Object $_.record -Name 'runner_patch_still_required') } else { $false }
            missing_runner_fields = if ($_.record) { @(Get-ArrayValue -Object $_.record -Name 'missing_runner_fields') } else { @() }
        }
    })
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    if (@('wiring-safe-route-no-summary', 'wiring-safe-route-failed', 'patch-target-safe-route-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 runner output patch follow-up safe route'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary exists after wiring route: {0}" -f $report.summary_exists_after_wiring_route)
Write-Host ("Patch-target route requested: {0}" -f $report.requested_patch_target_route)
if ($report.recommended_patch_target) {
    Write-Host ("Patch target: {0}" -f $report.recommended_patch_target)
}
if ($report.recommended_regeneration_command) {
    Write-Host ("Rerun:       {0}" -f $report.recommended_regeneration_command)
}
if ($report.recommended_verification_command) {
    Write-Host ("Verify:      {0}" -f $report.recommended_verification_command)
}
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

if (@('wiring-safe-route-no-summary', 'wiring-safe-route-failed', 'patch-target-safe-route-failed') -contains $status) {
    exit 1
}
