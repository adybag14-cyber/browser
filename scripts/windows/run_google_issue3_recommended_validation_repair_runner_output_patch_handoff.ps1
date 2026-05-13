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
$artifactRoot = Join-Path $repoRoot 'tmp-browser-smoke/headed-probe'
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-summary.json'
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-runner-output-patch-handoff.json'
}

$patchTargetsWrapperScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation_repair_runner_output_patch_targets.ps1'
$patchHandoffScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_patch_handoff.ps1'
$patchTargetsWrapperCommand = 'powershell -ExecutionPolicy Bypass -File ./scripts/windows/run_google_issue3_recommended_validation_repair_runner_output_patch_targets.ps1'
$patchHandoffCommand = 'powershell -ExecutionPolicy Bypass -File ./scripts/windows/show_google_issue3_runner_output_patch_handoff.ps1'
$runnerOutputWiringSafeCommand = 'powershell -ExecutionPolicy Bypass -File ./scripts/windows/show_google_issue3_runner_output_wiring_status_safe.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File ./scripts/windows/show_google_issue3_validation_summary_guide_safe.ps1'

foreach ($helperPath in @($patchTargetsWrapperScript, $patchHandoffScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$patchTargetsArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-runner-output-patch-targets.json'
$patchTargetsWrapperArguments = @('-SummaryPath', $SummaryPath, '-Json')
if ($RunnerArgument) {
    $patchTargetsWrapperArguments += '-RunnerArgument'
    $patchTargetsWrapperArguments += $RunnerArgument
}
$patchHandoffArguments = @('-SourceArtifactPath', $patchTargetsArtifactPath, '-Json')

$steps = [System.Collections.Generic.List[object]]::new()
$patchTargetsWrapperStep = Invoke-ScriptStep -Name 'patch-targets-wrapper' -ScriptPath $patchTargetsWrapperScript -Arguments $patchTargetsWrapperArguments -ExpectJson
$steps.Add($patchTargetsWrapperStep) | Out-Null

$patchTargetsArtifactExists = Test-Path -LiteralPath $patchTargetsArtifactPath -PathType Leaf
$patchHandoffStep = $null
if ($patchTargetsArtifactExists) {
    $patchHandoffStep = Invoke-ScriptStep -Name 'patch-handoff' -ScriptPath $patchHandoffScript -Arguments $patchHandoffArguments -ExpectJson
} else {
    $patchHandoffStep = New-SkippedStep -Name 'patch-handoff' -ScriptPath $patchHandoffScript -Arguments $patchHandoffArguments -Reason 'The patch-target wrapper did not leave a current patch-target artifact, so the direct runner-patch handoff could not narrow the next step.' -RecommendedCommand $(Get-FirstNonEmptyValue -Values @($patchTargetsWrapperStep.recommended_command, $patchTargetsWrapperCommand)) -RecommendedGuideCommand $(Get-FirstNonEmptyValue -Values @($patchTargetsWrapperStep.recommended_guide_command, $runnerOutputWiringSafeCommand, $summaryGuideCommand)) -NextFocus $(Get-FirstNonEmptyValue -Values @($patchTargetsWrapperStep.next_focus, 'Get the patch-target wrapper back to a current artifact before asking for a direct runner patch handoff.')) -NextArtifactToOpen $(Get-FirstNonEmptyValue -Values @($patchTargetsWrapperStep.next_artifact_to_open, $SummaryPath, $ArtifactPath))
}
$steps.Add($patchHandoffStep) | Out-Null

$recommendedPatchTarget = if ($patchHandoffStep.record) {
    Get-OptionalPropertyValue -Object $patchHandoffStep.record -Name 'recommended_patch_target'
} else {
    $null
}
$runnerPatchStillRequired = if ($patchHandoffStep.record -and $patchHandoffStep.record.PSObject.Properties['runner_patch_still_required']) {
    [bool]$patchHandoffStep.record.runner_patch_still_required
} elseif ($patchTargetsWrapperStep.record -and $patchTargetsWrapperStep.record.PSObject.Properties['runner_patch_still_required']) {
    [bool]$patchTargetsWrapperStep.record.runner_patch_still_required
} else {
    $false
}
$readyForRunnerPatchHandoff = [bool](
    $patchHandoffStep.success -and
    (
        (-not [string]::IsNullOrWhiteSpace($recommendedPatchTarget)) -or
        $runnerPatchStillRequired -or
        $patchHandoffStep.status -eq 'ready-for-runner-patch-handoff'
    )
)
$recommendedPostPatchCommand = Get-FirstNonEmptyValue -Values @(
    if ($patchHandoffStep.record) { Get-OptionalPropertyValue -Object $patchHandoffStep.record -Name 'recommended_post_patch_command' },
    if ($patchHandoffStep.record) { Get-OptionalPropertyValue -Object $patchHandoffStep.record -Name 'recommended_verification_command' },
    $patchHandoffStep.recommended_guide_command
)
$missingRunnerFields = if ($patchHandoffStep.record) {
    @(Get-ArrayValue -Object $patchHandoffStep.record -Name 'missing_runner_fields')
} elseif ($patchTargetsWrapperStep.record) {
    @(Get-ArrayValue -Object $patchTargetsWrapperStep.record -Name 'missing_runner_fields')
} else {
    @()
}
$summaryPatchSnippetLines = if ($patchHandoffStep.record) {
    @(Get-ArrayValue -Object $patchHandoffStep.record -Name 'summary_patch_snippet_lines')
} elseif ($patchTargetsWrapperStep.record) {
    @(Get-ArrayValue -Object $patchTargetsWrapperStep.record -Name 'summary_patch_snippet_lines')
} else {
    @()
}
$manifestPatchSnippetLines = if ($patchHandoffStep.record) {
    @(Get-ArrayValue -Object $patchHandoffStep.record -Name 'manifest_patch_snippet_lines')
} elseif ($patchTargetsWrapperStep.record) {
    @(Get-ArrayValue -Object $patchTargetsWrapperStep.record -Name 'manifest_patch_snippet_lines')
} else {
    @()
}

$status = $null
$reason = $null
if (-not $patchTargetsArtifactExists) {
    $status = 'patch-target-wrapper-no-artifact'
    $reason = 'The patch-target wrapper did not leave a current artifact, so the direct runner-patch handoff could not inspect the narrowed issue #3 route.'
} elseif (-not $patchHandoffStep.success) {
    $status = 'patch-handoff-failed'
    $reason = 'The patch-target wrapper left a current artifact, but the direct patch handoff helper did not finish cleanly.'
} elseif ($readyForRunnerPatchHandoff) {
    $status = 'ready-for-runner-patch-handoff'
    $reason = 'The issue #3 patch-target chain now narrows cleanly to a direct runner patch handoff with the target file, missing fields, snippet lines, and post-patch audit command preserved together.'
} elseif (-not $patchTargetsWrapperStep.success) {
    $status = 'patch-target-wrapper-failed'
    $reason = 'The patch-target wrapper did not finish cleanly, and the direct patch handoff still needs the wrapper follow-up state before it can promote a runner patch target.'
} else {
    $status = 'follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        $patchHandoffStep.reason,
        $patchTargetsWrapperStep.reason,
        'The issue #3 patch-target wrapper and handoff helper completed, but the next Windows replay still needs the narrower follow-up they reported.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($readyForRunnerPatchHandoff) { $recommendedPatchTarget },
    $patchHandoffStep.recommended_command,
    $patchTargetsWrapperStep.recommended_command,
    $patchTargetsWrapperCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($readyForRunnerPatchHandoff) { $recommendedPostPatchCommand },
    $patchHandoffStep.recommended_guide_command,
    $patchTargetsWrapperStep.recommended_guide_command,
    $runnerOutputWiringSafeCommand,
    $summaryGuideCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($readyForRunnerPatchHandoff) { 'Patch the recommended validation runner with the preserved summary and manifest snippet lines, rerun the broader issue #3 validation flow, then reopen the safe runner-output wiring audit before trusting the raw wiring helper again.' },
    $patchHandoffStep.next_focus,
    $patchTargetsWrapperStep.next_focus,
    if (-not $patchTargetsArtifactExists) { 'Regenerate the issue #3 patch-target artifact before asking for a direct runner patch handoff.' }
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    $patchHandoffStep.next_artifact_to_open,
    $patchTargetsWrapperStep.next_artifact_to_open,
    if ($patchTargetsArtifactExists) { $patchTargetsArtifactPath },
    $ArtifactPath
)

$report = [ordered]@{
    issue = 'Google issue #3 runner output patch handoff wrapper'
    purpose = 'Run the issue #3 patch-target wrapper, then immediately convert its narrowed artifact into a direct runner-patch handoff with the target file, missing fields, patch snippets, and post-patch audit command preserved together.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    runner_argument_passthrough = @($RunnerArgument)
    patch_targets_artifact_path = $patchTargetsArtifactPath
    patch_targets_artifact_exists = [bool]$patchTargetsArtifactExists
    ready_for_runner_patch_handoff = [bool]$readyForRunnerPatchHandoff
    runner_patch_still_required = [bool]$runnerPatchStillRequired
    recommended_patch_target = $recommendedPatchTarget
    recommended_post_patch_command = $recommendedPostPatchCommand
    missing_runner_fields = @($missingRunnerFields)
    summary_patch_snippet_lines = @($summaryPatchSnippetLines)
    manifest_patch_snippet_lines = @($manifestPatchSnippetLines)
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    patch_targets_wrapper_command = $patchTargetsWrapperCommand
    patch_handoff_command = $patchHandoffCommand
    runner_output_wiring_safe_command = $runnerOutputWiringSafeCommand
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
            recommended_patch_target = if ($_.record) { Get-OptionalPropertyValue -Object $_.record -Name 'recommended_patch_target' } else { $null }
            recommended_post_patch_command = if ($_.record) { Get-FirstNonEmptyValue -Values @((Get-OptionalPropertyValue -Object $_.record -Name 'recommended_post_patch_command'), (Get-OptionalPropertyValue -Object $_.record -Name 'recommended_verification_command'), $_.recommended_guide_command) } else { $null }
            runner_patch_still_required = if ($_.record -and $_.record.PSObject.Properties['runner_patch_still_required']) { [bool]$_.record.runner_patch_still_required } else { $false }
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
    if (@('patch-target-wrapper-no-artifact', 'patch-target-wrapper-failed', 'patch-handoff-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 runner output patch handoff wrapper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Patch targets: {0}" -f $report.patch_targets_artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Patch-target artifact exists: {0}" -f $report.patch_targets_artifact_exists)
Write-Host ("Ready for runner patch handoff: {0}" -f $report.ready_for_runner_patch_handoff)
Write-Host ("Runner patch still required: {0}" -f $report.runner_patch_still_required)
if ($report.recommended_patch_target) {
    Write-Host ("Patch target: {0}" -f $report.recommended_patch_target)
}
if ($report.recommended_post_patch_command) {
    Write-Host ("Post-patch audit: {0}" -f $report.recommended_post_patch_command)
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
if ($report.manifestPatchSnippetLines.Count -gt 0) {
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
    if ($step.recommended_post_patch_command) {
        Write-Host ("  Post-patch audit: {0}" -f $step.recommended_post_patch_command)
    }
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)

if (@('patch-target-wrapper-no-artifact', 'patch-target-wrapper-failed', 'patch-handoff-failed') -contains $status) {
    exit 1
}
