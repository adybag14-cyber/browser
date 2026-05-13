[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$SummaryPath,
    [string]$ArtifactPath,
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
        artifact_path = if ($record) { Get-OptionalPropertyValue -Object $record -Name 'artifact_path' } else { $null }
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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-safe-route-runner-patch-handoff.json'
}

$safeRouteRunnerPatchWrapperScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation_safe_route_runner_patch_wrapper.ps1'
$patchHandoffScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_patch_handoff.ps1'
$safeRouteRunnerPatchWrapperCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_safe_route_runner_patch_wrapper.ps1'
$patchHandoffCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_handoff.ps1'
$broaderRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$runnerOutputWiringSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$defaultSourceArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-safe-route-runner-patch-wrapper.json'

foreach ($helperPath in @($safeRouteRunnerPatchWrapperScript, $patchHandoffScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$steps = [System.Collections.Generic.List[object]]::new()
$wrapperArguments = @('-SummaryPath', $SummaryPath, '-Json')
if ($RepoRoot) {
    $wrapperArguments += @('-RepoRoot', $resolvedRepoRoot)
}
if ($BrowserExe) {
    $wrapperArguments += @('-BrowserExe', $BrowserExe)
}

$safeRouteRunnerPatchWrapperStep = Invoke-JsonHelper -Name 'recommended-validation-safe-route-runner-patch-wrapper' -ScriptPath $safeRouteRunnerPatchWrapperScript -Arguments $wrapperArguments
$steps.Add($safeRouteRunnerPatchWrapperStep) | Out-Null

$sourceArtifactPath = Get-FirstNonEmptyValue -Values @(
    if ($safeRouteRunnerPatchWrapperStep.record) { Get-OptionalPropertyValue -Object $safeRouteRunnerPatchWrapperStep.record -Name 'artifact_path' },
    $defaultSourceArtifactPath
)
$sourceArtifactExists = [bool](-not [string]::IsNullOrWhiteSpace($sourceArtifactPath) -and (Test-Path -LiteralPath $sourceArtifactPath -PathType Leaf))

$patchHandoffArguments = @('-SourceArtifactPath', $sourceArtifactPath, '-ArtifactPath', $ArtifactPath, '-Json')
if ($RepoRoot) {
    $patchHandoffArguments += @('-RepoRoot', $resolvedRepoRoot)
}

$patchHandoffStep = $null
if ($sourceArtifactExists) {
    $patchHandoffStep = Invoke-JsonHelper -Name 'runner-output-patch-handoff' -ScriptPath $patchHandoffScript -Arguments $patchHandoffArguments
} else {
    $timestamp = (Get-Date).ToUniversalTime().ToString('o')
    $patchHandoffStep = [pscustomobject]@{
        name = 'runner-output-patch-handoff'
        script_path = $patchHandoffScript
        arguments = @($patchHandoffArguments)
        started_at_utc = $timestamp
        completed_at_utc = $timestamp
        exit_code = 0
        success = $true
        status = 'skipped-source-artifact-missing'
        parse_error = $null
        error = $null
        output_preview = @()
        recommended_command = Get-FirstNonEmptyValue -Values @($safeRouteRunnerPatchWrapperStep.recommended_command, $safeRouteRunnerPatchWrapperCommand, $broaderRunnerCommand)
        recommended_guide_command = Get-FirstNonEmptyValue -Values @($safeRouteRunnerPatchWrapperStep.recommended_guide_command, $safeRouteRunnerPatchWrapperCommand)
        next_focus = 'Regenerate the safe-route runner-patch artifact first, then reopen this handoff wrapper so it can preserve the final direct runner patch guidance in one artifact.'
        next_artifact_to_open = Get-FirstNonEmptyValue -Values @($safeRouteRunnerPatchWrapperStep.next_artifact_to_open, $SummaryPath)
        reason = 'The safe-route runner-patch wrapper did not leave a source artifact, so the final patch-handoff helper had no current state to translate.'
        artifact_path = $ArtifactPath
        record = $null
    }
}
$steps.Add($patchHandoffStep) | Out-Null

$sourceStatus = if ($patchHandoffStep.record) {
    Get-OptionalPropertyValue -Object $patchHandoffStep.record -Name 'source_status'
} else {
    Get-OptionalPropertyValue -Object $safeRouteRunnerPatchWrapperStep.record -Name 'status'
}
$recommendedPatchTarget = if ($patchHandoffStep.record) {
    Get-OptionalPropertyValue -Object $patchHandoffStep.record -Name 'recommended_patch_target'
} else {
    Get-OptionalPropertyValue -Object $safeRouteRunnerPatchWrapperStep.record -Name 'recommended_patch_target'
}
$recommendedPostPatchCommand = if ($patchHandoffStep.record) {
    Get-OptionalPropertyValue -Object $patchHandoffStep.record -Name 'recommended_post_patch_command'
} else {
    $runnerOutputWiringSafeCommand
}
$recommendedVerificationCommand = Get-FirstNonEmptyValue -Values @(
    if ($patchHandoffStep.record) { Get-OptionalPropertyValue -Object $patchHandoffStep.record -Name 'recommended_verification_command' },
    if ($safeRouteRunnerPatchWrapperStep.record) { Get-OptionalPropertyValue -Object $safeRouteRunnerPatchWrapperStep.record -Name 'recommended_verification_command' }
)
$recommendedRegenerationCommand = Get-FirstNonEmptyValue -Values @(
    if ($patchHandoffStep.record) { Get-OptionalPropertyValue -Object $patchHandoffStep.record -Name 'recommended_regeneration_command' },
    if ($safeRouteRunnerPatchWrapperStep.record) { Get-OptionalPropertyValue -Object $safeRouteRunnerPatchWrapperStep.record -Name 'recommended_regeneration_command' }
)
$recommendedRepairCommand = Get-FirstNonEmptyValue -Values @(
    if ($patchHandoffStep.record) { Get-OptionalPropertyValue -Object $patchHandoffStep.record -Name 'recommended_repair_command' },
    if ($safeRouteRunnerPatchWrapperStep.record) { Get-OptionalPropertyValue -Object $safeRouteRunnerPatchWrapperStep.record -Name 'recommended_repair_command' }
)
$runnerPatchStillRequired = if ($patchHandoffStep.record) {
    [bool](Get-OptionalPropertyValue -Object $patchHandoffStep.record -Name 'runner_patch_still_required')
} else {
    [bool](Get-OptionalPropertyValue -Object $safeRouteRunnerPatchWrapperStep.record -Name 'runner_patch_still_required')
}
$runnerAlreadyWiredNeedsRegeneration = if ($patchHandoffStep.record -and (Test-HasProperty -Object $patchHandoffStep.record -Name 'runner_already_wired_needs_regeneration')) {
    [bool]$patchHandoffStep.record.runner_already_wired_needs_regeneration
} elseif ($safeRouteRunnerPatchWrapperStep.record -and (Test-HasProperty -Object $safeRouteRunnerPatchWrapperStep.record -Name 'runner_already_wired_needs_regeneration')) {
    [bool]$safeRouteRunnerPatchWrapperStep.record.runner_already_wired_needs_regeneration
} else {
    $false
}
$alreadyDirectFromRawPatchTargets = if ($patchHandoffStep.record -and (Test-HasProperty -Object $patchHandoffStep.record -Name 'already_direct_from_raw_patch_targets')) {
    [bool]$patchHandoffStep.record.already_direct_from_raw_patch_targets
} elseif ($safeRouteRunnerPatchWrapperStep.record -and (Test-HasProperty -Object $safeRouteRunnerPatchWrapperStep.record -Name 'already_direct_from_raw_patch_targets')) {
    [bool]$safeRouteRunnerPatchWrapperStep.record.already_direct_from_raw_patch_targets
} else {
    $false
}
$missingRunnerFields = Get-FirstNonEmptyValue -Values @(
    if ($patchHandoffStep.record) { @(Get-ArrayValue -Object $patchHandoffStep.record -Name 'missing_runner_fields') },
    if ($safeRouteRunnerPatchWrapperStep.record) { @(Get-ArrayValue -Object $safeRouteRunnerPatchWrapperStep.record -Name 'missing_runner_fields') },
    @()
)
$summaryPatchSnippetLines = Get-FirstNonEmptyValue -Values @(
    if ($patchHandoffStep.record) { @(Get-ArrayValue -Object $patchHandoffStep.record -Name 'summary_patch_snippet_lines') },
    if ($safeRouteRunnerPatchWrapperStep.record) { @(Get-ArrayValue -Object $safeRouteRunnerPatchWrapperStep.record -Name 'summary_patch_snippet_lines') },
    @()
)
$manifestPatchSnippetLines = Get-FirstNonEmptyValue -Values @(
    if ($patchHandoffStep.record) { @(Get-ArrayValue -Object $patchHandoffStep.record -Name 'manifest_patch_snippet_lines') },
    if ($safeRouteRunnerPatchWrapperStep.record) { @(Get-ArrayValue -Object $safeRouteRunnerPatchWrapperStep.record -Name 'manifest_patch_snippet_lines') },
    @()
)

$status = $null
$reason = $null
if (-not $sourceArtifactExists) {
    $status = 'source-artifact-missing'
    $reason = 'The safe-route runner-patch wrapper did not leave a current source artifact, so this wrapper could not preserve the final patch handoff yet.'
} elseif (-not $patchHandoffStep.success) {
    $status = 'patch-handoff-failed'
    $reason = 'The safe-route runner-patch wrapper completed, but the final patch-handoff helper did not finish cleanly.'
} else {
    $status = Get-FirstNonEmptyValue -Values @($patchHandoffStep.status, $safeRouteRunnerPatchWrapperStep.status, 'follow-up-ready')
    $reason = Get-FirstNonEmptyValue -Values @(
        $patchHandoffStep.reason,
        $safeRouteRunnerPatchWrapperStep.reason,
        'The safe-route runner-patch wrapper completed and this bridge preserved the final patch handoff in one artifact.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    $patchHandoffStep.recommended_command,
    $safeRouteRunnerPatchWrapperStep.recommended_command,
    $patchHandoffCommand,
    $safeRouteRunnerPatchWrapperCommand,
    $broaderRunnerCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    $patchHandoffStep.recommended_guide_command,
    $safeRouteRunnerPatchWrapperStep.recommended_guide_command,
    $recommendedVerificationCommand,
    $runnerOutputWiringSafeCommand,
    $safeRouteRunnerPatchWrapperCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    $patchHandoffStep.next_focus,
    $safeRouteRunnerPatchWrapperStep.next_focus,
    'Use the preserved patch-handoff artifact before widening back out to broader issue #3 replay loops.'
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    $patchHandoffStep.next_artifact_to_open,
    $ArtifactPath,
    $sourceArtifactPath,
    $SummaryPath
)

$report = [ordered]@{
    issue = 'Google issue #3 recommended validation safe route runner patch handoff'
    purpose = 'Run the current safe-route runner-patch wrapper first, then immediately preserve the final runner patch handoff in one artifact for the next Windows replay.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repo_root = $resolvedRepoRoot
    summary_path = $SummaryPath
    source_artifact_path = $sourceArtifactPath
    source_artifact_exists = [bool]$sourceArtifactExists
    source_status = $sourceStatus
    artifact_path = $ArtifactPath
    safe_route_runner_patch_wrapper_command = $safeRouteRunnerPatchWrapperCommand
    patch_handoff_command = $patchHandoffCommand
    broader_runner_command = $broaderRunnerCommand
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    recommended_patch_target = $recommendedPatchTarget
    recommended_post_patch_command = $recommendedPostPatchCommand
    recommended_verification_command = $recommendedVerificationCommand
    recommended_regeneration_command = $recommendedRegenerationCommand
    recommended_repair_command = $recommendedRepairCommand
    runner_patch_still_required = [bool]$runnerPatchStillRequired
    runner_already_wired_needs_regeneration = [bool]$runnerAlreadyWiredNeedsRegeneration
    already_direct_from_raw_patch_targets = [bool]$alreadyDirectFromRawPatchTargets
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
            artifact_path = $_.artifact_path
            recommended_command = $_.recommended_command
            recommended_guide_command = $_.recommended_guide_command
            next_focus = $_.next_focus
            next_artifact_to_open = $_.next_artifact_to_open
            reason = $_.reason
            recommended_patch_target = if ($_.record) { Get-OptionalPropertyValue -Object $_.record -Name 'recommended_patch_target' } else { $null }
            recommended_post_patch_command = if ($_.record) { Get-OptionalPropertyValue -Object $_.record -Name 'recommended_post_patch_command' } else { $null }
            recommended_verification_command = if ($_.record) { Get-OptionalPropertyValue -Object $_.record -Name 'recommended_verification_command' } else { $null }
            recommended_regeneration_command = if ($_.record) { Get-OptionalPropertyValue -Object $_.record -Name 'recommended_regeneration_command' } else { $null }
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
    if (@('source-artifact-missing', 'patch-handoff-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 recommended validation safe route runner patch handoff'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Source:    {0}" -f $report.source_artifact_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Source status: {0}" -f $report.source_status)
Write-Host ("Source artifact exists: {0}" -f $report.source_artifact_exists)
Write-Host ("Runner patch still required: {0}" -f $report.runner_patch_still_required)
Write-Host ("Runner already wired needs regeneration: {0}" -f $report.runner_already_wired_needs_regeneration)
Write-Host ("Already direct from raw patch-targets: {0}" -f $report.already_direct_from_raw_patch_targets)
if ($report.recommended_patch_target) {
    Write-Host ("Patch target: {0}" -f $report.recommended_patch_target)
}
if ($report.recommended_post_patch_command) {
    Write-Host ("Post-patch:   {0}" -f $report.recommended_post_patch_command)
}
if ($report.recommended_verification_command) {
    Write-Host ("Verify:       {0}" -f $report.recommended_verification_command)
}
if ($report.recommended_regeneration_command) {
    Write-Host ("Rerun:        {0}" -f $report.recommended_regeneration_command)
}
if ($report.recommended_repair_command) {
    Write-Host ("Repair:       {0}" -f $report.recommended_repair_command)
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

if (@('source-artifact-missing', 'patch-handoff-failed') -contains $status) {
    exit 1
}
