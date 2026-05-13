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

$repoRoot = if ($RepoRoot) {
    $RepoRoot
} else {
    Resolve-RepoRoot $PSScriptRoot
}
$artifactPathExplicit = -not [string]::IsNullOrWhiteSpace($ArtifactPath)
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json'
}
$defaultArtifactRoot = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe'
if (-not $artifactPathExplicit) {
    $ArtifactPath = Join-Path $defaultArtifactRoot 'google-issue3-validation-safe-route-runner-patch-wrapper.json'
}

$validationSafeRouteScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_safe_route.ps1'
$runnerPatchSafeRouteScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_patch_targets_safe_route.ps1'
$validationSafeRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_safe_route.ps1'
$runnerPatchSafeRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe_route.ps1'
$broaderRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    $status = 'summary-missing-broader-replay-first'
    $reason = 'The top-level issue #3 wrapper did not find a saved recommended-validation summary yet, so it cannot safely reopen the narrower safe-route helpers.'
    $nextFocus = 'Run the broader issue #3 recommended validation runner first so it regenerates the summary and manifest, then reopen this wrapper to preserve the narrower runner patch guidance in one artifact.'
    $report = [ordered]@{
        issue = 'Google issue #3 validation safe route runner patch wrapper'
        purpose = 'Run the top-level issue #3 validation safe route first and preserve the exact runner patch-target details from the narrower safe patch route in one combined artifact.'
        generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        repo_root = $repoRoot
        browser_exe = $BrowserExe
        summary_path = $SummaryPath
        artifact_path = $ArtifactPath
        validation_safe_route_command = $validationSafeRouteCommand
        runner_output_patch_targets_safe_route_command = $runnerPatchSafeRouteCommand
        broader_runner_command = $broaderRunnerCommand
        runner_patch_route_ran = $false
        runner_already_wired_needs_regeneration = $false
        already_direct_from_raw_patch_targets = $false
        recommended_command = $broaderRunnerCommand
        recommended_guide_command = $validationSafeRouteCommand
        recommended_patch_target = $null
        recommended_regeneration_command = $broaderRunnerCommand
        recommended_verification_command = $null
        recommended_repair_command = $null
        runner_patch_still_required = $false
        missing_runner_fields = @()
        summary_patch_snippet_lines = @()
        manifest_patch_snippet_lines = @()
        next_focus = $nextFocus
        next_artifact_to_open = $SummaryPath
        status = $status
        reason = $reason
        steps = @()
    }

    $report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

    if ($Json) {
        $report | ConvertTo-Json -Depth 8
        exit 0
    }

    Write-Host 'Google issue #3 validation safe route runner patch wrapper'
    Write-Host ''
    Write-Host ("Summary:   {0}" -f $report.summary_path)
    Write-Host ("Artifact:  {0}" -f $report.artifact_path)
    Write-Host ("Status:    {0}" -f $report.status)
    Write-Host ("Runner patch route ran: {0}" -f $report.runner_patch_route_ran)
    Write-Host ''
    Write-Host ("Reason: {0}" -f $report.reason)
    Write-Host ("Focus:  {0}" -f $report.next_focus)
    Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
    Write-Host ("Run:    {0}" -f $report.recommended_command)
    Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
    exit 0
}

$summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json
$artifactRoot = Get-OptionalPropertyValue -Object $summary -Name 'artifact_root'
if ([string]::IsNullOrWhiteSpace($artifactRoot)) {
    $artifactRoot = Split-Path -Parent $SummaryPath
}
if (-not $artifactPathExplicit) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-validation-safe-route-runner-patch-wrapper.json'
}

foreach ($helperPath in @($validationSafeRouteScript, $runnerPatchSafeRouteScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$steps = [System.Collections.Generic.List[object]]::new()
$validationStep = Invoke-JsonHelper -Name 'validation-safe-route' -ScriptPath $validationSafeRouteScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
$steps.Add($validationStep) | Out-Null

$validationSummaryCompleted = [bool](Get-OptionalPropertyValue -Object $validationStep.record -Name 'summary_completed')
$validationSummaryNeedsRepair = [bool](Get-OptionalPropertyValue -Object $validationStep.record -Name 'summary_needs_repair')
$validationSummaryNeedsBroaderReplay = [bool](Get-OptionalPropertyValue -Object $validationStep.record -Name 'summary_needs_broader_replay')
$validationHandoffSafeRouteRan = [bool](Get-OptionalPropertyValue -Object $validationStep.record -Name 'handoff_safe_route_ran')
$shouldRunRunnerPatchRoute = [bool](
    $validationStep.success -and
    $validationHandoffSafeRouteRan -and
    -not $validationSummaryNeedsRepair -and
    -not $validationSummaryNeedsBroaderReplay -and
    -not $validationSummaryCompleted
)
$runnerPatchStep = $null
if ($shouldRunRunnerPatchRoute) {
    $runnerPatchStep = Invoke-JsonHelper -Name 'runner-output-patch-targets-safe-route' -ScriptPath $runnerPatchSafeRouteScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
} else {
    $runnerPatchStep = New-SkippedHelperStep -Name 'runner-output-patch-targets-safe-route' -ScriptPath $runnerPatchSafeRouteScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -RecommendedCommand $(Get-FirstNonEmptyValue -Values @($validationStep.recommended_command, $validationSafeRouteCommand)) -RecommendedGuideCommand $(Get-FirstNonEmptyValue -Values @($validationStep.recommended_guide_command, $validationSafeRouteCommand)) -NextFocus $(Get-FirstNonEmptyValue -Values @($validationStep.next_focus, 'Reopen the validation-safe route first; the runner patch wrapper only adds value once that top-level route narrows to the handoff-safe branch.')) -NextArtifactToOpen $(Get-FirstNonEmptyValue -Values @($validationStep.next_artifact_to_open, $SummaryPath)) -Reason 'The validation-safe route either did not finish cleanly or kept the next replay on broader repair or replay guidance, so the wrapper preserved that upstream route and skipped the narrower runner patch helper.'
}
$steps.Add($runnerPatchStep) | Out-Null

$runnerPatchStillRequired = [bool](Get-OptionalPropertyValue -Object $runnerPatchStep.record -Name 'runner_patch_still_required')
$runnerAlreadyWiredNeedsRegeneration = if ($runnerPatchStep.record -and $runnerPatchStep.record.PSObject.Properties['runner_already_wired_needs_regeneration']) {
    [bool]$runnerPatchStep.record.runner_already_wired_needs_regeneration
} else {
    [bool]($runnerPatchStep.status -eq 'runner-already-wired-regenerate-outputs')
}
$alreadyDirectFromRawPatchTargets = if ($runnerPatchStep.record -and $runnerPatchStep.record.PSObject.Properties['already_direct_from_raw_patch_targets']) {
    [bool]$runnerPatchStep.record.already_direct_from_raw_patch_targets
} else {
    [bool]($runnerPatchStep.status -eq 'already-direct')
}
$recommendedPatchTarget = Get-OptionalPropertyValue -Object $runnerPatchStep.record -Name 'recommended_patch_target'
$recommendedRegenerationCommand = Get-OptionalPropertyValue -Object $runnerPatchStep.record -Name 'recommended_regeneration_command'
$recommendedVerificationCommand = Get-OptionalPropertyValue -Object $runnerPatchStep.record -Name 'recommended_verification_command'
$recommendedRepairCommand = Get-OptionalPropertyValue -Object $runnerPatchStep.record -Name 'recommended_repair_command'
$missingRunnerFields = @(Get-ArrayValue -Object $runnerPatchStep.record -Name 'missing_runner_fields')
$summaryPatchSnippetLines = @(Get-ArrayValue -Object $runnerPatchStep.record -Name 'summary_patch_snippet_lines')
$manifestPatchSnippetLines = @(Get-ArrayValue -Object $runnerPatchStep.record -Name 'manifest_patch_snippet_lines')

$status = $null
$reason = $null
if (-not $validationStep.success) {
    $status = 'validation-safe-route-failed'
    $reason = 'The top-level validation-safe route did not finish cleanly, so the wrapper stayed on that broader checkpoint before attempting narrower runner patch guidance.'
} elseif ($shouldRunRunnerPatchRoute -and -not $runnerPatchStep.success) {
    $status = 'runner-patch-safe-route-failed'
    $reason = 'The validation-safe route completed, but the narrower runner patch safe route did not finish cleanly, so the next replay should reopen that bounded patch route directly.'
} elseif ($runnerPatchStillRequired) {
    $status = 'ready-for-runner-patch'
    $reason = 'The validation-safe route completed and the runner patch route surfaced the exact direct runner-output fields that still need to land in the recommended validation runner.'
} elseif ($runnerAlreadyWiredNeedsRegeneration) {
    $status = 'runner-already-wired-regenerate-outputs'
    $reason = 'The validation-safe route completed and the runner patch route confirmed the live runner source is already wired, so the next job is to regenerate or repair stale saved outputs.'
} elseif ($alreadyDirectFromRawPatchTargets) {
    $status = 'already-direct'
    $reason = 'The validation-safe route completed and the runner patch route confirmed the saved outputs already expose the direct runner-output contract.'
} else {
    $status = Get-FirstNonEmptyValue -Values @($runnerPatchStep.status, $validationStep.status, 'validation-safe-route-follow-up-ready')
    $reason = Get-FirstNonEmptyValue -Values @(
        $runnerPatchStep.reason,
        $validationStep.reason,
        'The validation-safe route completed and this wrapper preserved the narrower runner patch guidance alongside the top-level route artifact.'
    )
}

$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextFocus = $null
$nextArtifactToOpen = $null
if ($status -eq 'ready-for-runner-patch') {
    $recommendedCommand = Get-FirstNonEmptyValue -Values @($runnerPatchStep.recommended_command, $runnerPatchSafeRouteCommand)
    $recommendedGuideCommand = Get-FirstNonEmptyValue -Values @($runnerPatchStep.recommended_guide_command, $validationStep.recommended_guide_command, $validationSafeRouteCommand)
    $nextFocus = 'Inspect the preserved summary and manifest patch snippets in this combined wrapper artifact, land the direct runner-output fields in the recommended validation runner, then rerun the safe wiring audit.'
    $nextArtifactToOpen = $ArtifactPath
} else {
    $recommendedCommand = Get-FirstNonEmptyValue -Values @($runnerPatchStep.recommended_command, $validationStep.recommended_command, $runnerPatchSafeRouteCommand, $validationSafeRouteCommand)
    $recommendedGuideCommand = Get-FirstNonEmptyValue -Values @($runnerPatchStep.recommended_guide_command, $validationStep.recommended_guide_command, $validationSafeRouteCommand)
    $nextFocus = Get-FirstNonEmptyValue -Values @(
        $runnerPatchStep.next_focus,
        $validationStep.next_focus,
        'Use the preserved top-level validation-safe route guidance before widening back out to broader issue #3 replay loops.'
    )
    $nextArtifactToOpen = Get-FirstNonEmptyValue -Values @($runnerPatchStep.next_artifact_to_open, $validationStep.next_artifact_to_open, $SummaryPath)
}

$report = [ordered]@{
    issue = 'Google issue #3 validation safe route runner patch wrapper'
    purpose = 'Run the top-level issue #3 validation safe route first and preserve the exact runner patch-target details from the narrower safe patch route in one combined artifact.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repo_root = $repoRoot
    browser_exe = $BrowserExe
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    validation_safe_route_command = $validationSafeRouteCommand
    runner_output_patch_targets_safe_route_command = $runnerPatchSafeRouteCommand
    broader_runner_command = $broaderRunnerCommand
    runner_patch_route_ran = [bool]$shouldRunRunnerPatchRoute
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
    if (@('validation-safe-route-failed', 'runner-patch-safe-route-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 validation safe route runner patch wrapper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
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

if (@('validation-safe-route-failed', 'runner-patch-safe-route-failed') -contains $status) {
    exit 1
}
