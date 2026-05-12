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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-manifest-contract-handoff-safe-refresh-route.json'
}

$manifestContractSafeScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation_repair_manifest_contract_safe.ps1'
$handoffSafeRefreshRouteScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_handoff_safe_refresh_route.ps1'
$manifestContractSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_manifest_contract_safe.ps1'
$handoffSafeRefreshRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe_refresh_route.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'

foreach ($helperPath in @($manifestContractSafeScript, $handoffSafeRefreshRouteScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$manifestContractSafeArguments = @('-SummaryPath', $SummaryPath, '-Json')
if ($RunnerArgument) {
    $manifestContractSafeArguments += '-RunnerArgument'
    $manifestContractSafeArguments += $RunnerArgument
}
$handoffSafeRefreshRouteArguments = @('-SummaryPath', $SummaryPath, '-Json')

$steps = [System.Collections.Generic.List[object]]::new()
$manifestContractSafeStep = Invoke-ScriptStep -Name 'recommended-validation-manifest-contract-safe' -ScriptPath $manifestContractSafeScript -Arguments $manifestContractSafeArguments -ExpectJson
$steps.Add($manifestContractSafeStep) | Out-Null

$summaryExistsAfterManifestContractSafe = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$shouldRunHandoffSafeRefreshRoute = [bool]($summaryExistsAfterManifestContractSafe -and $manifestContractSafeStep.success -and $manifestContractSafeStep.status -eq 'ready-for-handoff-safe-refresh-route')

$handoffSafeRefreshRouteStep = $null
if ($shouldRunHandoffSafeRefreshRoute) {
    $handoffSafeRefreshRouteStep = Invoke-ScriptStep -Name 'handoff-safe-refresh-route' -ScriptPath $handoffSafeRefreshRouteScript -Arguments $handoffSafeRefreshRouteArguments -ExpectJson
} else {
    $handoffSafeRefreshRouteStep = New-SkippedStep -Name 'handoff-safe-refresh-route' -ScriptPath $handoffSafeRefreshRouteScript -Arguments $handoffSafeRefreshRouteArguments -Reason 'The manifest-contract-safe wrapper did not report ready-for-handoff-safe-refresh-route, so this bounded route preserved its safer follow-up guidance without reopening the narrower helper yet.' -RecommendedCommand $(Get-FirstNonEmptyValue -Values @($manifestContractSafeStep.recommended_command, $manifestContractSafeCommand)) -RecommendedGuideCommand $(Get-FirstNonEmptyValue -Values @($manifestContractSafeStep.recommended_guide_command, $summaryGuideCommand)) -NextFocus $(Get-FirstNonEmptyValue -Values @($manifestContractSafeStep.next_focus, 'Use the current manifest-contract-safe guidance; the handoff-safe refresh route should only reopen once that checkpoint says the saved summary is ready.')) -NextArtifactToOpen $(Get-FirstNonEmptyValue -Values @($manifestContractSafeStep.next_artifact_to_open, $SummaryPath, $ArtifactPath))
    $steps.Add($handoffSafeRefreshRouteStep) | Out-Null
}
if ($shouldRunHandoffSafeRefreshRoute) {
    $steps.Add($handoffSafeRefreshRouteStep) | Out-Null
}

$status = $null
$reason = $null
if (-not $summaryExistsAfterManifestContractSafe) {
    $status = 'manifest-contract-safe-no-summary'
    $reason = 'The manifest-contract-safe issue #3 replay did not leave a summary artifact, so the follow-up handoff-safe refresh route could not continue.'
} elseif (-not $manifestContractSafeStep.success) {
    $status = 'manifest-contract-safe-failed'
    $reason = 'The manifest-contract-safe issue #3 replay did not finish cleanly, so the next Windows replay still needs direct manifest-contract-safe attention before the narrower handoff-safe refresh route is trusted.'
} elseif ($shouldRunHandoffSafeRefreshRoute -and -not $handoffSafeRefreshRouteStep.success) {
    $status = 'handoff-safe-refresh-route-failed'
    $reason = 'The manifest-contract-safe replay cleared the current summary for the handoff-safe refresh route, but that narrower helper did not finish cleanly.'
} elseif ($shouldRunHandoffSafeRefreshRoute) {
    $status = Get-FirstNonEmptyValue -Values @($handoffSafeRefreshRouteStep.status, 'handoff-safe-refresh-route-follow-up-ready')
    $reason = Get-FirstNonEmptyValue -Values @(
        $handoffSafeRefreshRouteStep.reason,
        'The manifest-contract-safe replay completed, and this wrapper immediately reopened the handoff-safe refresh route so the next Windows replay can continue from the current handoff or refresh-safe guidance without a manual extra step.'
    )
} else {
    $status = 'manifest-contract-safe-follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        $manifestContractSafeStep.reason,
        'The manifest-contract-safe replay completed, but the next issue #3 replay still needs the follow-up command reported by that safer checkpoint.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunHandoffSafeRefreshRoute) { $handoffSafeRefreshRouteStep.recommended_command },
    $manifestContractSafeStep.recommended_command,
    if ($shouldRunHandoffSafeRefreshRoute) { $handoffSafeRefreshRouteCommand },
    $manifestContractSafeCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunHandoffSafeRefreshRoute) { $handoffSafeRefreshRouteStep.recommended_guide_command },
    $manifestContractSafeStep.recommended_guide_command,
    if ($shouldRunHandoffSafeRefreshRoute) { $handoffSafeRefreshRouteCommand },
    $summaryGuideCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunHandoffSafeRefreshRoute) { $handoffSafeRefreshRouteStep.next_focus },
    $manifestContractSafeStep.next_focus,
    if (-not $summaryExistsAfterManifestContractSafe) { 'Regenerate the issue #3 recommended validation summary before asking the handoff-safe refresh route to narrow the next replay.' },
    if ($shouldRunHandoffSafeRefreshRoute) { 'Use the narrowed handoff-safe refresh guidance produced in this run before widening back out to broader issue #3 validation loops.' }
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunHandoffSafeRefreshRoute) { $handoffSafeRefreshRouteStep.next_artifact_to_open },
    $manifestContractSafeStep.next_artifact_to_open,
    if ($summaryExistsAfterManifestContractSafe) { $SummaryPath },
    $ArtifactPath
)

$report = [ordered]@{
    issue = 'Google issue #3 manifest-contract-safe replay plus handoff-safe refresh route'
    purpose = 'Run the bounded issue #3 manifest-contract-safe replay, then immediately reopen the handoff-safe refresh route when the saved summary is ready so the next Windows replay can keep moving along the narrowed helper chain without a manual extra branch.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    runner_argument_passthrough = @($RunnerArgument)
    summary_exists_after_manifest_contract_safe = [bool]$summaryExistsAfterManifestContractSafe
    manifest_contract_safe_status = $manifestContractSafeStep.status
    handoff_safe_refresh_route_status = $handoffSafeRefreshRouteStep.status
    handoff_safe_refresh_route_ran = [bool]$shouldRunHandoffSafeRefreshRoute
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    manifest_contract_safe_command = $manifestContractSafeCommand
    handoff_safe_refresh_route_command = $handoffSafeRefreshRouteCommand
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
    if (@('manifest-contract-safe-no-summary', 'manifest-contract-safe-failed', 'handoff-safe-refresh-route-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 manifest-contract-safe replay plus handoff-safe refresh route'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary exists after manifest-contract-safe replay: {0}" -f $report.summary_exists_after_manifest_contract_safe)
Write-Host ("Manifest contract safe: {0}" -f $report.manifest_contract_safe_status)
Write-Host ("Handoff-safe refresh route: {0}" -f $report.handoff_safe_refresh_route_status)
Write-Host ("Handoff-safe refresh route ran: {0}" -f $report.handoff_safe_refresh_route_ran)
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

if (@('manifest-contract-safe-no-summary', 'manifest-contract-safe-failed', 'handoff-safe-refresh-route-failed') -contains $status) {
    exit 1
}
