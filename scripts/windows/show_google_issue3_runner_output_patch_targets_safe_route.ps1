[CmdletBinding()]
param(
    [string]$RepoRoot,
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

    $command = "& '.\\scripts\\windows\\$ScriptName'"
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
        [string[]]$Arguments,
        [string]$RepoRootOverride
    )

    $startedAt = (Get-Date).ToUniversalTime().ToString('o')
    $output = @()
    $exitCode = 0
    $errorMessage = $null
    $parseError = $null
    $record = $null

    try {
        if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
            $output = @(
                & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1
            )
        } else {
            $escapedScriptPath = ("$ScriptPath") -replace "'", "''"
            $escapedRepoRoot = ("$RepoRootOverride") -replace "'", "''"
            $argumentLiteral = if ($Arguments.Count -gt 0) {
                "@(" + (($Arguments | ForEach-Object { "'" + ("$_" -replace "'", "''") + "'" }) -join ', ') + ")"
            } else {
                '@()'
            }
            $commandText = "`$env:LIGHTPANDA_REPO_ROOT = '$escapedRepoRoot'; `$codexArgs = $argumentLiteral; & '$escapedScriptPath' @codexArgs"
            $output = @(
                & powershell -NoProfile -ExecutionPolicy Bypass -Command $commandText 2>&1
            )
        }
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
        repo_root_override = $RepoRootOverride
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
        [string]$RepoRootOverride,
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
        repo_root_override = $RepoRootOverride
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

$repoRoot = if ($RepoRoot) {
    $RepoRoot
} else {
    Resolve-RepoRoot $PSScriptRoot
}
$artifactPathExplicit = -not [string]::IsNullOrWhiteSpace($ArtifactPath)
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json"
}
$defaultArtifactRoot = Join-Path $repoRoot "tmp-browser-smoke\headed-probe"
if (-not $artifactPathExplicit) {
    $ArtifactPath = Join-Path $defaultArtifactRoot 'google-issue3-runner-output-patch-targets-safe-route.json'
}
$recommendedRepoRoot = if ($PSBoundParameters.ContainsKey('RepoRoot')) {
    $repoRoot
} else {
    $null
}
$recommendedSummaryPath = if ($PSBoundParameters.ContainsKey('SummaryPath')) {
    $SummaryPath
} else {
    $null
}
$recommendedSourceArtifactPath = if ($artifactPathExplicit) {
    $ArtifactPath
} else {
    $null
}

if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    throw "Issue #3 recommended validation summary not found: $SummaryPath"
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$artifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
if ([string]::IsNullOrWhiteSpace($artifactRoot)) {
    $artifactRoot = Split-Path -Parent $SummaryPath
}
if (-not $artifactPathExplicit) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-runner-output-patch-targets-safe-route.json'
}

$patchTargetsSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_patch_targets_safe.ps1'
$patchTargetsScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_patch_targets.ps1'
$patchTargetsSafeCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_output_patch_targets_safe.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$patchTargetsCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_output_patch_targets.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$patchHandoffCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_output_patch_handoff.ps1' -Arguments ([ordered]@{
    SourceArtifactPath = $recommendedSourceArtifactPath
}) -RepoRootOverride $recommendedRepoRoot
$runnerOutputWiringSafeCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_output_wiring_status_safe.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
}) -RepoRootOverride $recommendedRepoRoot
$broaderRunnerCommand = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation.ps1' -Arguments ([ordered]@{
    RepoRoot = $recommendedRepoRoot
    SummaryPath = $recommendedSummaryPath
})
$repairRunnerOutputContractCommand = Format-HelperCommand -ScriptName 'repair_google_issue3_runner_output_contract.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
})
$repairArtifactPathsCommand = Format-HelperCommand -ScriptName 'repair_google_issue3_validation_artifact_paths.ps1' -Arguments ([ordered]@{
    SummaryPath = $recommendedSummaryPath
})
$patchTargetsSafeStepArguments = @('-SummaryPath', $SummaryPath, '-Json')
$patchTargetsStepArguments = @('-SummaryPath', $SummaryPath, '-Json')

foreach ($helperPath in @($patchTargetsSafeScript, $patchTargetsScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$steps = [System.Collections.Generic.List[object]]::new()
$patchTargetsSafeStep = Invoke-JsonHelper -Name 'patch-targets-safe' -ScriptPath $patchTargetsSafeScript -Arguments $patchTargetsSafeStepArguments -RepoRootOverride $recommendedRepoRoot
$steps.Add($patchTargetsSafeStep) | Out-Null

$shouldRunRawPatchTargets = [bool](
    $patchTargetsSafeStep.success -and
    $patchTargetsSafeStep.recommended_command -eq $patchTargetsCommand
)

$patchTargetsStep = $null
if ($shouldRunRawPatchTargets) {
    $patchTargetsStep = Invoke-JsonHelper -Name 'patch-targets' -ScriptPath $patchTargetsScript -Arguments $patchTargetsStepArguments -RepoRootOverride $recommendedRepoRoot
} else {
    $patchTargetsStep = New-SkippedHelperStep -Name 'patch-targets' -ScriptPath $patchTargetsScript -Arguments $patchTargetsStepArguments -RepoRootOverride $recommendedRepoRoot -RecommendedCommand $(Get-FirstNonEmptyValue -Values @($patchTargetsSafeStep.recommended_command, $patchTargetsSafeCommand)) -RecommendedGuideCommand $(Get-FirstNonEmptyValue -Values @($patchTargetsSafeStep.recommended_guide_command, $runnerOutputWiringSafeCommand)) -NextFocus $(Get-FirstNonEmptyValue -Values @($patchTargetsSafeStep.next_focus, 'Use the current safe patch-target guidance; the raw patch-target helper is only needed when the saved outputs are already strict-mode-safe.')) -NextArtifactToOpen $(Get-FirstNonEmptyValue -Values @($patchTargetsSafeStep.next_artifact_to_open, $SummaryPath)) -Reason 'The safe patch-target gate did not route the next replay to the raw patch-target helper, so the wrapper stayed on the safer routing helper.'
}
$steps.Add($patchTargetsStep) | Out-Null

$recommendedPatchTarget = $null
$recommendedRegenerationCommand = $null
$recommendedVerificationCommand = $null
$recommendedRepairCommand = $null
$runnerPatchStillRequired = $false
$missingRunnerFields = @()
$summaryPatchSnippetLines = @()
$manifestPatchSnippetLines = @()
if ($patchTargetsStep.record) {
    $recommendedPatchTarget = Get-OptionalPropertyValue -Object $patchTargetsStep.record -Name 'recommended_patch_target'
    $recommendedRegenerationCommand = Get-OptionalPropertyValue -Object $patchTargetsStep.record -Name 'recommended_regeneration_command'
    $recommendedVerificationCommand = Get-OptionalPropertyValue -Object $patchTargetsStep.record -Name 'recommended_verification_command'
    $recommendedRepairCommand = Get-OptionalPropertyValue -Object $patchTargetsStep.record -Name 'recommended_repair_command'
    $runnerPatchStillRequired = [bool](-not [string]::IsNullOrWhiteSpace($recommendedPatchTarget))
    $missingRunnerFields = @(Get-ArrayValue -Object $patchTargetsStep.record -Name 'missing_runner_fields')
    $summaryPatchSnippetLines = @(Get-ArrayValue -Object $patchTargetsStep.record -Name 'summary_patch_snippet_lines')
    $manifestPatchSnippetLines = @(Get-ArrayValue -Object $patchTargetsStep.record -Name 'manifest_patch_snippet_lines')
}

$rawPatchTargetsGuidesSafeWiring = [bool](
    $shouldRunRawPatchTargets -and
    $patchTargetsStep.recommended_guide_command -eq $runnerOutputWiringSafeCommand
)
$rawPatchTargetsSuggestsRegeneration = [bool](
    $rawPatchTargetsGuidesSafeWiring -and
    @(
        $recommendedRepairCommand,
        $repairRunnerOutputContractCommand,
        $recommendedRegenerationCommand,
        $broaderRunnerCommand
    ) -contains $patchTargetsStep.recommended_command
)
$runnerAlreadyWiredNeedsRegeneration = [bool](
    $shouldRunRawPatchTargets -and
    -not $runnerPatchStillRequired -and
    (
        $patchTargetsStep.status -eq 'saved-artifacts-stale-runner-already-wired' -or
        $rawPatchTargetsSuggestsRegeneration
    )
)
$alreadyDirectFromRawPatchTargets = [bool](
    $shouldRunRawPatchTargets -and
    -not $runnerPatchStillRequired -and
    (
        $patchTargetsStep.status -eq 'fully-wired' -or
        (
            $rawPatchTargetsGuidesSafeWiring -and
            -not $runnerAlreadyWiredNeedsRegeneration
        )
    )
)

$status = $null
$reason = $null
if (-not $patchTargetsSafeStep.success) {
    $status = 'patch-target-safe-failed'
    $reason = 'The safe patch-target helper did not finish cleanly, so the next replay should stay on that strict-mode-safe gate before reopening the raw patch-target helper.'
} elseif ($shouldRunRawPatchTargets -and -not $patchTargetsStep.success) {
    $status = 'patch-target-helper-failed'
    $reason = 'The safe helper routed the next replay to the raw patch-target guidance, but the raw patch-target helper did not finish cleanly.'
} elseif ($shouldRunRawPatchTargets -and $patchTargetsStep.record -and $runnerPatchStillRequired) {
    $status = 'ready-for-runner-patch'
    $reason = 'The safe gate routed the next replay to the raw patch-target helper and that helper surfaced the direct runner-output fields that still need to land in the recommended validation runner.'
} elseif ($runnerAlreadyWiredNeedsRegeneration) {
    $status = 'runner-already-wired-regenerate-outputs'
    $reason = 'The safe gate routed the next replay through the raw patch-target helper, and that helper now points back to regeneration or repair because the live runner source is already wired and the saved outputs are stale.'
} elseif ($alreadyDirectFromRawPatchTargets) {
    $status = 'already-direct'
    $reason = 'The safe gate routed the next replay through the raw patch-target helper, and that helper now points straight to the safe wiring audit because the saved summary and manifest already carry the direct runner-output contract.'
} elseif ($patchTargetsSafeStep.status -eq 'already-direct') {
    $status = 'already-direct'
    $reason = 'The safe patch-target gate says the saved outputs already expose the direct runner-output contract, so no raw patch-target follow-up is needed.'
} elseif ($shouldRunRawPatchTargets) {
    $status = 'patch-target-follow-up-ready'
    $reason = Get-FirstNonEmptyValue -Values @(
        $patchTargetsStep.reason,
        'The safe gate routed the next replay through the raw patch-target helper and that helper produced the next bounded runner-contract guidance.'
    )
} else {
    $status = 'patch-target-safe-follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        $patchTargetsSafeStep.reason,
        'The safe patch-target gate completed, but the next replay still needs the follow-up command reported by that safer checkpoint.'
    )
}

$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextFocus = $null
$nextArtifactToOpen = $null
if ($status -eq 'ready-for-runner-patch') {
    $recommendedCommand = $patchHandoffCommand
    $recommendedGuideCommand = $runnerOutputWiringSafeCommand
    $nextFocus = 'Run the explicit patch handoff helper now, then use its preserved snippet lines to wire the direct refresh and handoff fields into scripts/windows/run_google_issue3_recommended_validation.ps1 before rerunning the safe wiring audit and only later reopening the stricter raw verification command.'
    $nextArtifactToOpen = $ArtifactPath
} elseif ($status -eq 'already-direct') {
    $recommendedCommand = $runnerOutputWiringSafeCommand
    $recommendedGuideCommand = $runnerOutputWiringSafeCommand
    $nextFocus = 'Reopen the safe runner-output wiring audit now that the saved summary and manifest already expose the direct contract, and only widen back out if that audit reports a fresh gap.'
    $nextArtifactToOpen = $SummaryPath
} elseif ($status -eq 'runner-already-wired-regenerate-outputs') {
    $recommendedCommand = Get-FirstNonEmptyValue -Values @($patchTargetsStep.recommended_command, $recommendedRepairCommand, $repairRunnerOutputContractCommand, $recommendedRegenerationCommand, $broaderRunnerCommand)
    $recommendedGuideCommand = $runnerOutputWiringSafeCommand
    $nextFocus = 'Regenerate or repair the saved issue #3 outputs now that the live runner source already carries the direct contract fields, then reopen the safe wiring audit before trusting the stricter raw verification command again.'
    $nextArtifactToOpen = $ArtifactPath
} else {
    $recommendedCommand = Get-FirstNonEmptyValue -Values @(
        if ($patchTargetsStep) { $patchTargetsStep.recommended_command },
        $patchTargetsSafeStep.recommended_command,
        $patchTargetsSafeCommand
    )
    $recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
        if ($patchTargetsStep) { $patchTargetsStep.recommended_guide_command },
        $patchTargetsSafeStep.recommended_guide_command,
        $runnerOutputWiringSafeCommand
    )
    $nextFocus = Get-FirstNonEmptyValue -Values @(
        if ($patchTargetsStep) { $patchTargetsStep.next_focus },
        $patchTargetsSafeStep.next_focus,
        'Use the current patch-target routing guidance before widening back out to the broader issue #3 validation runner.'
    )
    $nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
        if ($patchTargetsStep) { $patchTargetsStep.next_artifact_to_open },
        $patchTargetsSafeStep.next_artifact_to_open,
        $SummaryPath
    )
}

$report = [ordered]@{
    issue = 'Google issue #3 runner output patch-target safe route'
    purpose = 'Run the safe patch-target gate first and, when it routes the next replay to the raw patch-target helper, immediately reopen that raw helper so the next Windows replay can move from routing to runner patch guidance without a manual extra step.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repo_root = $repoRoot
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    patch_targets_safe_command = $patchTargetsSafeCommand
    patch_targets_command = $patchTargetsCommand
    patch_handoff_command = $patchHandoffCommand
    broader_runner_command = $broaderRunnerCommand
    repair_runner_output_contract_command = $repairRunnerOutputContractCommand
    repair_artifact_paths_command = $repairArtifactPathsCommand
    runner_output_wiring_safe_command = $runnerOutputWiringSafeCommand
    raw_patch_targets_ran = [bool]$shouldRunRawPatchTargets
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
            repo_root_override = $_.repo_root_override
            recommended_command = $_.recommended_command
            recommended_guide_command = $_.recommended_guide_command
            next_focus = $_.next_focus
            next_artifact_to_open = $_.next_artifact_to_open
            reason = $_.reason
            runner_patch_still_required = if ($_.record) { [bool](-not [string]::IsNullOrWhiteSpace((Get-OptionalPropertyValue -Object $_.record -Name 'recommended_patch_target'))) } else { $false }
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
    if (@('patch-target-safe-failed', 'patch-target-helper-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 runner output patch-target safe route'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Raw patch-targets ran: {0}" -f $report.raw_patch_targets_ran)
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
    if ($step.repo_root_override) {
        Write-Host ("  Repo root: {0}" -f $step.repo_root_override)
    }
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

if (@('patch-target-safe-failed', 'patch-target-helper-failed') -contains $status) {
    exit 1
}
