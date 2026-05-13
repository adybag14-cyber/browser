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

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [hashtable]$Arguments = @{}
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\$ScriptName"
    foreach ($entry in $Arguments.GetEnumerator()) {
        $value = $entry.Value
        if ($null -eq $value) {
            continue
        }

        if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        $escapedValue = ("$value") -replace "'", "''"
        $command += (" -{0} '{1}'" -f $entry.Key, $escapedValue)
    }

    return $command
}

function Format-HelperCommandWithRepoRootEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [hashtable]$Arguments = @{},
        [string]$RepoRootOverride
    )

    if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        return Format-HelperCommand -ScriptName $ScriptName -Arguments $Arguments
    }

    $command = "& '.\scripts\windows\$ScriptName'"
    foreach ($entry in $Arguments.GetEnumerator()) {
        $value = $entry.Value
        if ($null -eq $value) {
            continue
        }

        if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        $escapedValue = ("$value") -replace "'", "''"
        $command += (" -{0} '{1}'" -f $entry.Key, $escapedValue)
    }

    $escapedRepoRoot = ("$RepoRootOverride") -replace "'", "''"
    return "powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$env:LIGHTPANDA_REPO_ROOT = '$escapedRepoRoot'; $command`""
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

    $status = if ($record -and (Test-HasProperty -Object $record -Name 'status')) {
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
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json'
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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-validation-safe-route.json'
}
$recommendedRepoRoot = if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $env:LIGHTPANDA_REPO_ROOT
} else {
    $null
}
$recommendedSummaryPath = if ($PSBoundParameters.ContainsKey('SummaryPath')) {
    $SummaryPath
} else {
    $null
}

$summarySafeScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_summary_guide_safe.ps1'
$handoffSafeRefreshRouteScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_handoff_safe_refresh_route.ps1'
$summarySafeCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_summary_guide_safe.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$handoffSafeRefreshRouteCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_handoff_safe_refresh_route.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$artifactPathRepairCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'repair_google_issue3_validation_artifact_paths.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$summaryContractRepairCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'repair_google_issue3_validation_summary_contract.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$broaderRunnerCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'run_google_issue3_recommended_validation.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot

foreach ($helperPath in @($summarySafeScript, $handoffSafeRefreshRouteScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$steps = [System.Collections.Generic.List[object]]::new()
$summaryStep = Invoke-JsonHelper -Name 'summary-safe' -ScriptPath $summarySafeScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
$steps.Add($summaryStep) | Out-Null

$summaryCompleted = [bool](
    $summaryStep.record -and
    (Test-HasProperty -Object $summaryStep.record -Name 'completed') -and
    $summaryStep.record.completed
)
$summaryNeedsRepair = [bool](
    $summaryStep.success -and (
        $summaryStep.recommended_command -eq $artifactPathRepairCommand -or
        $summaryStep.recommended_command -eq $summaryContractRepairCommand
    )
)
$summaryNeedsBroaderReplay = [bool](
    $summaryStep.success -and
    $summaryStep.recommended_command -eq $broaderRunnerCommand -and
    -not $summaryCompleted
)
$shouldRunHandoffSafeRoute = [bool](
    $summaryStep.success -and
    -not $summaryNeedsRepair -and
    -not $summaryNeedsBroaderReplay -and
    -not $summaryCompleted
)

$handoffStep = $null
if ($shouldRunHandoffSafeRoute) {
    $handoffStep = Invoke-JsonHelper -Name 'handoff-safe-refresh-route' -ScriptPath $handoffSafeRefreshRouteScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
} else {
    $handoffStep = New-SkippedHelperStep -Name 'handoff-safe-refresh-route' -ScriptPath $handoffSafeRefreshRouteScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -RecommendedCommand $(Get-FirstNonEmptyValue -Values @($summaryStep.recommended_command, $summarySafeCommand)) -RecommendedGuideCommand $(Get-FirstNonEmptyValue -Values @($summaryStep.recommended_guide_command, $summarySafeCommand)) -NextFocus $(Get-FirstNonEmptyValue -Values @($summaryStep.next_focus, 'Use the summary-safe guidance first; the handoff-safe route is only needed once the summary contract is already safe to trust.')) -NextArtifactToOpen $(Get-FirstNonEmptyValue -Values @($summaryStep.next_artifact_to_open, $SummaryPath)) -Reason 'The summary-safe checkpoint already chose the next bounded action, so the handoff-safe refresh route did not need to run in the same pass.'
}
$steps.Add($handoffStep) | Out-Null

$status = $null
$reason = $null
if (-not $summaryStep.success) {
    $status = 'summary-safe-failed'
    $reason = 'The summary-safe helper did not finish cleanly, so the next Windows replay should begin from that safer summary checkpoint before any narrower handoff routing.'
} elseif ($summaryNeedsRepair) {
    $status = 'summary-repair-first'
    $reason = 'The summary-safe helper detected a saved summary or artifact-path contract gap, so repair should happen before any narrower handoff routing.'
} elseif ($summaryNeedsBroaderReplay) {
    $status = 'broader-replay-first'
    $reason = 'The summary-safe helper says the saved issue #3 summary needs a fresh broader replay before narrower handoff routing is worth trusting.'
} elseif ($summaryCompleted) {
    $status = 'summary-complete'
    $reason = 'The summary-safe helper says the bounded localhost ladder already completed, so the next replay can widen from the saved summary without extra handoff-safe routing.'
} elseif (-not $handoffStep.success) {
    $status = 'handoff-safe-route-failed'
    $reason = 'The summary-safe checkpoint cleared the saved summary, but the handoff-safe refresh route did not finish cleanly, so the next replay should reopen that safer handoff route directly.'
} else {
    $status = 'handoff-safe-route-ready'
    $reason = 'The summary-safe checkpoint was healthy enough to continue, and this helper immediately reopened the handoff-safe refresh route so the next Windows replay can start from the narrowest safe checkpoint.'
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunHandoffSafeRoute) { $handoffStep.recommended_command },
    $summaryStep.recommended_command,
    if ($shouldRunHandoffSafeRoute) { $handoffSafeRefreshRouteCommand },
    $summarySafeCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunHandoffSafeRoute) { $handoffStep.recommended_guide_command },
    $summaryStep.recommended_guide_command,
    if ($shouldRunHandoffSafeRoute) { $handoffSafeRefreshRouteCommand },
    $summarySafeCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunHandoffSafeRoute) { $handoffStep.next_focus },
    $summaryStep.next_focus,
    if ($shouldRunHandoffSafeRoute) { 'Use the handoff-safe refresh guidance from this run before widening back out to broader issue #3 replay loops.' },
    'Start from the safest summary checkpoint before widening back out to broader issue #3 replay loops.'
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunHandoffSafeRoute) { $handoffStep.next_artifact_to_open },
    $summaryStep.next_artifact_to_open,
    $SummaryPath
)

$report = [ordered]@{
    issue = 'Google issue #3 validation safe route'
    purpose = 'Provide one strict-mode-safe entrypoint for saved issue #3 validation artifacts by running the summary-safe checkpoint first and then, when appropriate, immediately reopening the handoff-safe refresh route.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    summary_safe_command = $summarySafeCommand
    handoff_safe_refresh_route_command = $handoffSafeRefreshRouteCommand
    artifact_path_repair_command = $artifactPathRepairCommand
    summary_contract_repair_command = $summaryContractRepairCommand
    broader_runner_command = $broaderRunnerCommand
    summary_completed = [bool]$summaryCompleted
    summary_needs_repair = [bool]$summaryNeedsRepair
    summary_needs_broader_replay = [bool]$summaryNeedsBroaderReplay
    handoff_safe_route_ran = [bool]$shouldRunHandoffSafeRoute
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
    if (@('summary-safe-failed', 'handoff-safe-route-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 validation safe route'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary completed: {0}" -f $report.summary_completed)
Write-Host ("Summary needs repair: {0}" -f $report.summary_needs_repair)
Write-Host ("Broader replay first: {0}" -f $report.summary_needs_broader_replay)
Write-Host ("Handoff route ran: {0}" -f $report.handoff_safe_route_ran)
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

if (@('summary-safe-failed', 'handoff-safe-route-failed') -contains $status) {
    exit 1
}