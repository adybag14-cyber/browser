[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
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

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [hashtable]$Arguments = @{}
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\$ScriptName"
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

$resolvedRepoRoot = if ($RepoRoot) {
    $RepoRoot
} else {
    Resolve-RepoRoot $PSScriptRoot
}
$artifactRoot = Join-Path $resolvedRepoRoot 'tmp-browser-smoke\headed-probe'
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-summary.json'
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-safe-route-runner-patch-wrapper.json'
}

$safeSummaryRouteScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation_safe_summary_route.ps1'
$safeRouteRunnerPatchWrapperScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1'
$recommendedRepoRoot = if ($PSBoundParameters.ContainsKey('RepoRoot')) {
    $resolvedRepoRoot
} else {
    $null
}
$recommendedBrowserExe = if ($PSBoundParameters.ContainsKey('BrowserExe')) {
    $BrowserExe
} else {
    $null
}
$safeSummaryRouteCommand = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation_safe_summary_route.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    BrowserExe = $recommendedBrowserExe
    SummaryPath = $SummaryPath
})
$safeRouteRunnerPatchWrapperCommand = Format-HelperCommand -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    BrowserExe = $recommendedBrowserExe
    SummaryPath = $SummaryPath
})
$broaderRunnerCommand = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    BrowserExe = $recommendedBrowserExe
    SummaryPath = $SummaryPath
})

foreach ($helperPath in @($safeSummaryRouteScript, $safeRouteRunnerPatchWrapperScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$steps = [System.Collections.Generic.List[object]]::new()
$safeSummaryRouteArguments = @('-SummaryPath', $SummaryPath, '-Json')
if ($RepoRoot) {
    $safeSummaryRouteArguments += @('-RepoRoot', $resolvedRepoRoot)
}
if ($BrowserExe) {
    $safeSummaryRouteArguments += @('-BrowserExe', $BrowserExe)
}

$safeSummaryRouteStep = Invoke-JsonHelper -Name 'recommended-validation-safe-summary-route' -ScriptPath $safeSummaryRouteScript -Arguments $safeSummaryRouteArguments
$steps.Add($safeSummaryRouteStep) | Out-Null

$summaryExistsAfterSafeSummaryRoute = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$safeRouteRunnerPatchStep = $null
$safeRouteRunnerPatchArguments = @('-SummaryPath', $SummaryPath, '-Json')
if ($RepoRoot) {
    $safeRouteRunnerPatchArguments += @('-RepoRoot', $resolvedRepoRoot)
}
if ($BrowserExe) {
    $safeRouteRunnerPatchArguments += @('-BrowserExe', $BrowserExe)
}

if ($summaryExistsAfterSafeSummaryRoute) {
    $safeRouteRunnerPatchStep = Invoke-JsonHelper -Name 'validation-safe-route-runner-patch-wrapper' -ScriptPath $safeRouteRunnerPatchWrapperScript -Arguments $safeRouteRunnerPatchArguments
} else {
    $timestamp = (Get-Date).ToUniversalTime().ToString('o')
    $safeRouteRunnerPatchStep = [pscustomobject]@{
        name = 'validation-safe-route-runner-patch-wrapper'
        script_path = $safeRouteRunnerPatchWrapperScript
        arguments = @($safeRouteRunnerPatchArguments)
        started_at_utc = $timestamp
        completed_at_utc = $timestamp
        exit_code = 0
        success = $true
        status = 'skipped-summary-missing'
        parse_error = $null
        error = $null
        output_preview = @()
        recommended_command = Get-FirstNonEmptyValue -Values @($safeSummaryRouteStep.recommended_command, $broaderRunnerCommand, $safeSummaryRouteCommand)
        recommended_guide_command = Get-FirstNonEmptyValue -Values @($safeSummaryRouteStep.recommended_guide_command, $safeSummaryRouteCommand)
        next_focus = 'Regenerate the issue #3 recommended-validation summary first, then reopen the combined safe-route runner-patch wrapper so it can preserve the narrower patch guidance in one artifact.'
        next_artifact_to_open = $SummaryPath
        reason = 'The broader safe-summary route did not leave a current summary artifact, so the narrower safe-route runner-patch wrapper had no current state to inspect.'
        record = $null
    }
}
$steps.Add($safeRouteRunnerPatchStep) | Out-Null

$runnerPatchRouteRan = if ($safeRouteRunnerPatchStep.record) {
    [bool](Get-OptionalPropertyValue -Object $safeRouteRunnerPatchStep.record -Name 'runner_patch_route_ran')
} else {
    $false
}
$runnerPatchStillRequired = if ($safeRouteRunnerPatchStep.record) {
    [bool](Get-OptionalPropertyValue -Object $safeRouteRunnerPatchStep.record -Name 'runner_patch_still_required')
} else {
    $false
}
$runnerAlreadyWiredNeedsRegeneration = if ($safeRouteRunnerPatchStep.record -and $safeRouteRunnerPatchStep.record.PSObject.Properties['runner_already_wired_needs_regeneration']) {
    [bool]$safeRouteRunnerPatchStep.record.runner_already_wired_needs_regeneration
} else {
    $false
}
$alreadyDirectFromRawPatchTargets = if ($safeRouteRunnerPatchStep.record -and $safeRouteRunnerPatchStep.record.PSObject.Properties['already_direct_from_raw_patch_targets']) {
    [bool]$safeRouteRunnerPatchStep.record.already_direct_from_raw_patch_targets
} else {
    $false
}
$recommendedPatchTarget = if ($safeRouteRunnerPatchStep.record) {
    Get-OptionalPropertyValue -Object $safeRouteRunnerPatchStep.record -Name 'recommended_patch_target'
} else {
    $null
}
$recommendedRegenerationCommand = if ($safeRouteRunnerPatchStep.record) {
    Get-OptionalPropertyValue -Object $safeRouteRunnerPatchStep.record -Name 'recommended_regeneration_command'
} else {
    $null
}
$recommendedVerificationCommand = if ($safeRouteRunnerPatchStep.record) {
    Get-OptionalPropertyValue -Object $safeRouteRunnerPatchStep.record -Name 'recommended_verification_command'
} else {
    $null
}
$recommendedRepairCommand = if ($safeRouteRunnerPatchStep.record) {
    Get-OptionalPropertyValue -Object $safeRouteRunnerPatchStep.record -Name 'recommended_repair_command'
} else {
    $null
}
$missingRunnerFields = if ($safeRouteRunnerPatchStep.record) {
    @(Get-ArrayValue -Object $safeRouteRunnerPatchStep.record -Name 'missing_runner_fields')
} else {
    @()
}
$summaryPatchSnippetLines = if ($safeRouteRunnerPatchStep.record) {
    @(Get-ArrayValue -Object $safeRouteRunnerPatchStep.record -Name 'summary_patch_snippet_lines')
} else {
    @()
}
$manifestPatchSnippetLines = if ($safeRouteRunnerPatchStep.record) {
    @(Get-ArrayValue -Object $safeRouteRunnerPatchStep.record -Name 'manifest_patch_snippet_lines')
} else {
    @()
}

$status = $null
$reason = $null
if (-not $summaryExistsAfterSafeSummaryRoute) {
    $status = 'summary-missing-after-safe-summary-route'
    $reason = 'The broader safe-summary route did not leave a current summary artifact, so the combined wrapper could not preserve narrower runner-patch guidance yet.'
} elseif (-not $safeSummaryRouteStep.success) {
    $status = 'safe-summary-route-failed'
    $reason = 'The broader safe-summary route did not finish cleanly, but the combined wrapper still preserved the immediate follow-up from that checkpoint.'
} elseif (-not $safeRouteRunnerPatchStep.success) {
    $status = 'safe-route-runner-patch-wrapper-failed'
    $reason = 'The broader safe-summary route completed, but the narrower safe-route runner-patch wrapper did not finish cleanly.'
} elseif ($runnerPatchStillRequired) {
    $status = 'ready-for-runner-patch'
    $reason = 'The broader safe-summary route completed and the narrower safe-route wrapper surfaced the exact remaining runner-output contract patch guidance.'
} elseif ($runnerAlreadyWiredNeedsRegeneration) {
    $status = 'runner-already-wired-regenerate-outputs'
    $reason = 'The combined wrapper confirmed the live runner source is already wired, so the next replay should regenerate or repair stale saved outputs instead of reopening a code patch.'
} elseif ($alreadyDirectFromRawPatchTargets) {
    $status = 'already-direct'
    $reason = 'The combined wrapper confirmed the saved outputs already expose the direct runner-output contract.'
} else {
    $status = Get-FirstNonEmptyValue -Values @($safeRouteRunnerPatchStep.status, $safeSummaryRouteStep.status, 'follow-up-ready')
    $reason = Get-FirstNonEmptyValue -Values @(
        $safeRouteRunnerPatchStep.reason,
        $safeSummaryRouteStep.reason,
        'The broader safe-summary route completed and this combined wrapper preserved the current narrower runner-patch guidance in one artifact.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    $safeRouteRunnerPatchStep.recommended_command,
    $safeSummaryRouteStep.recommended_command,
    $safeRouteRunnerPatchWrapperCommand,
    $safeSummaryRouteCommand,
    $broaderRunnerCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    $safeRouteRunnerPatchStep.recommended_guide_command,
    $safeSummaryRouteStep.recommended_guide_command,
    $safeRouteRunnerPatchWrapperCommand,
    $safeSummaryRouteCommand
)
$nextFocus = if ($status -eq 'ready-for-runner-patch') {
    'Open this combined wrapper artifact, use the preserved summary and manifest patch snippets to land the direct runner-output fields, then rerun the safe wiring audit.'
} else {
    Get-FirstNonEmptyValue -Values @(
        $safeRouteRunnerPatchStep.next_focus,
        $safeSummaryRouteStep.next_focus,
        'Use the preserved safe-summary and safe-route guidance before widening back out to broader issue #3 replay loops.'
    )
}
$nextArtifactToOpen = if ($status -eq 'ready-for-runner-patch') {
    $ArtifactPath
} else {
    Get-FirstNonEmptyValue -Values @(
        $safeRouteRunnerPatchStep.next_artifact_to_open,
        $safeSummaryRouteStep.next_artifact_to_open,
        $SummaryPath
    )
}

$report = [ordered]@{
    issue = 'Google issue #3 recommended validation safe route runner patch wrapper'
    purpose = 'Run the broader issue #3 recommended validation safe-summary route first, then immediately preserve the narrower safe-route runner-patch guidance in one artifact.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repo_root = $resolvedRepoRoot
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    safe_summary_route_command = $safeSummaryRouteCommand
    safe_route_runner_patch_wrapper_command = $safeRouteRunnerPatchWrapperCommand
    broader_runner_command = $broaderRunnerCommand
    summary_exists_after_safe_summary_route = [bool]$summaryExistsAfterSafeSummaryRoute
    runner_patch_route_ran = [bool]$runnerPatchRouteRan
    runner_already_wired_needs_regeneration = [bool]$runnerAlreadyWiredNeedsRegeneration
    already_direct_from_raw_patch_targets = [bool]$alreadyDirectFromRawPatchTargets
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
            parse_error = $_.parse_error
            error = $_.error
            recommended_command = $_.recommended_command
            recommended_guide_command = $_.recommended_guide_command
            next_focus = $_.next_focus
            next_artifact_to_open = $_.next_artifact_to_open
            reason = $_.reason
            recommended_patch_target = if ($_.record) { Get-OptionalPropertyValue -Object $_.record -Name 'recommended_patch_target' } else { $null }
            recommended_regeneration_command = if ($_.record) { Get-OptionalPropertyValue -Object $_.record -Name 'recommended_regeneration_command' } else { $null }
            recommended_verification_command = if ($_.record) { Get-OptionalPropertyValue -Object $_.record -Name 'recommended_verification_command' } else { $null }
            recommended_repair_command = if ($_.record) { Get-OptionalPropertyValue -Object $_.record -Name 'recommended_repair_command' } else { $null }
            runner_patch_still_required = if ($_.record) { [bool](Get-OptionalPropertyValue -Object $_.record -Name 'runner_patch_still_required') } else { $false }
            runner_already_wired_needs_regeneration = if ($_.record) { [bool](Get-OptionalPropertyValue -Object $_.record -Name 'runner_already_wired_needs_regeneration') } else { $false }
            already_direct_from_raw_patch_targets = if ($_.record) { [bool](Get-OptionalPropertyValue -Object $_.record -Name 'already_direct_from_raw_patch_targets') } else { $false }
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
    if (@('safe-summary-route-failed', 'safe-route-runner-patch-wrapper-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 recommended validation safe route runner patch wrapper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary exists after safe-summary route: {0}" -f $report.summary_exists_after_safe_summary_route)
Write-Host ("Runner patch route ran: {0}" -f $report.runner_patch_route_ran)
Write-Host ("Runner already wired needs regeneration: {0}" -f $report.runner_already_wired_needs_regeneration)
Write-Host ("Already direct from raw patch-targets: {0}" -f $report.already_direct_from_raw_patch_targets)
if ($report.recommended_patch_target) {
    Write-Host ("Patch target: {0}" -f $report.recommended_patch_target)
}
if ($report.recommended_regeneration_command) {
    Write-Host ("Rerun:       {0}" -f $report.recommended_regeneration_command)
}
if ($report.recommended_verification_command) {
    Write-Host ("Verify:      {0}" -f $report.recommended_verification_command)
}
if ($report.recommended_repair_command) {
    Write-Host ("Repair:      {0}" -f $report.recommended_repair_command)
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

if (@('safe-summary-route-failed', 'safe-route-runner-patch-wrapper-failed') -contains $status) {
    exit 1
}
