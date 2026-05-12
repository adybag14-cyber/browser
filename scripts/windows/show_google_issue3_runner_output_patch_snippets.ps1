[CmdletBinding()]
param(
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
$artifactRoot = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe'
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-summary.json'
}
if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    throw "Issue #3 recommended validation summary not found: $SummaryPath"
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-runner-output-patch-snippets.json'
}

$safeRouteScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_patch_targets_safe_route.ps1'
$rawPatchTargetsScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_patch_targets.ps1'
$safeRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets_safe_route.ps1'
$rawPatchTargetsCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_patch_targets.ps1'
$runnerOutputWiringSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$recommendedRunnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'

foreach ($helperPath in @($safeRouteScript, $rawPatchTargetsScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$steps = [System.Collections.Generic.List[object]]::new()
$safeRouteStep = Invoke-JsonHelper -Name 'patch-targets-safe-route' -ScriptPath $safeRouteScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
$steps.Add($safeRouteStep) | Out-Null

$rawPatchTargetsRan = [bool]($safeRouteStep.record -and (Get-OptionalPropertyValue -Object $safeRouteStep.record -Name 'raw_patch_targets_ran'))
$rawPatchTargetsStep = $null
if ($safeRouteStep.success -and $rawPatchTargetsRan) {
    $rawPatchTargetsStep = Invoke-JsonHelper -Name 'patch-targets' -ScriptPath $rawPatchTargetsScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
} else {
    $rawPatchTargetsStep = New-SkippedHelperStep -Name 'patch-targets' -ScriptPath $rawPatchTargetsScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -RecommendedCommand $(Get-FirstNonEmptyValue -Values @($safeRouteStep.recommended_command, $safeRouteCommand)) -RecommendedGuideCommand $(Get-FirstNonEmptyValue -Values @($safeRouteStep.recommended_guide_command, $runnerOutputWiringSafeCommand)) -NextFocus $(Get-FirstNonEmptyValue -Values @($safeRouteStep.next_focus, 'Use the current safe route guidance before reopening the raw patch-target helper.')) -NextArtifactToOpen $(Get-FirstNonEmptyValue -Values @($safeRouteStep.next_artifact_to_open, $SummaryPath)) -Reason 'The safe route did not report that the raw patch-target helper had already run, so this helper stayed on the bounded safe-route checkpoint.'
}
$steps.Add($rawPatchTargetsStep) | Out-Null

$rawPatchTargetsStatus = if ($rawPatchTargetsStep.record) {
    Get-OptionalPropertyValue -Object $rawPatchTargetsStep.record -Name 'status'
} else {
    $rawPatchTargetsStep.status
}
$recommendedPatchTarget = $null
$recommendedRegenerationCommand = $null
$recommendedVerificationCommand = $null
$recommendedRepairCommand = $null
$missingRunnerFields = @()
$summaryPatchSnippetLines = @()
$manifestPatchSnippetLines = @()
if ($rawPatchTargetsStep.record) {
    $recommendedPatchTarget = Get-OptionalPropertyValue -Object $rawPatchTargetsStep.record -Name 'recommended_patch_target'
    $recommendedRegenerationCommand = Get-OptionalPropertyValue -Object $rawPatchTargetsStep.record -Name 'recommended_regeneration_command'
    $recommendedVerificationCommand = Get-OptionalPropertyValue -Object $rawPatchTargetsStep.record -Name 'recommended_verification_command'
    $recommendedRepairCommand = Get-OptionalPropertyValue -Object $rawPatchTargetsStep.record -Name 'recommended_repair_command'
    $missingRunnerFields = @($(Get-OptionalPropertyValue -Object $rawPatchTargetsStep.record -Name 'missing_runner_fields') | Where-Object { $null -ne $_ })
    $summaryPatchSnippetLines = @($(Get-OptionalPropertyValue -Object $rawPatchTargetsStep.record -Name 'summary_patch_snippet_lines') | Where-Object { $null -ne $_ })
    $manifestPatchSnippetLines = @($(Get-OptionalPropertyValue -Object $rawPatchTargetsStep.record -Name 'manifest_patch_snippet_lines') | Where-Object { $null -ne $_ })
}

$status = $null
$reason = $null
if (-not $safeRouteStep.success) {
    $status = 'safe-route-failed'
    $reason = 'The issue #3 patch-target safe route did not finish cleanly, so the next replay should stay on that bounded routing helper before trusting raw patch snippets.'
} elseif ($rawPatchTargetsRan -and -not $rawPatchTargetsStep.success) {
    $status = 'raw-patch-targets-failed'
    $reason = 'The safe route said the saved outputs were ready for raw patch-target guidance, but the raw helper did not finish cleanly.'
} elseif ($rawPatchTargetsRan -and $recommendedPatchTarget -and (($summaryPatchSnippetLines.Count -gt 0) -or ($manifestPatchSnippetLines.Count -gt 0))) {
    $status = 'patch-snippets-ready'
    $reason = 'The safe route completed and the raw patch-target helper surfaced the exact summary and manifest snippet lines needed for the remaining direct runner-output contract edit.'
} elseif ($rawPatchTargetsRan -and $rawPatchTargetsStatus -eq 'runner-already-wired-regenerate-outputs') {
    $status = 'runner-already-wired-regenerate-outputs'
    $reason = 'The live runner source already carries the direct contract fields, so the next Windows replay should regenerate or repair the saved outputs instead of reopening the patch edit.'
} elseif ($rawPatchTargetsRan -and $rawPatchTargetsStatus -eq 'fully-wired') {
    $status = 'already-direct'
    $reason = 'The safe route and raw helper agree that the saved summary and manifest already carry the direct runner-output contract.'
} else {
    $status = 'follow-safe-route'
    $reason = Get-FirstNonEmptyValue -Values @(
        $safeRouteStep.reason,
        'The safe route still owns the next step, so this helper is surfacing that bounded guidance instead of raw patch snippets.'
    )
}

$recommendedCommand = $null
$recommendedGuideCommand = $null
$nextFocus = $null
$nextArtifactToOpen = $null
if ($status -eq 'patch-snippets-ready') {
    $recommendedCommand = $rawPatchTargetsCommand
    $recommendedGuideCommand = Get-FirstNonEmptyValue -Values @($recommendedVerificationCommand, $runnerOutputWiringSafeCommand)
    $nextFocus = 'Apply the emitted summary and manifest snippet lines to scripts/windows/run_google_issue3_recommended_validation.ps1, rerun the recommended validation runner, and then reopen the safe runner-output wiring audit.'
    $nextArtifactToOpen = $ArtifactPath
} elseif ($status -eq 'runner-already-wired-regenerate-outputs') {
    $recommendedCommand = Get-FirstNonEmptyValue -Values @($recommendedRepairCommand, $recommendedRegenerationCommand, $recommendedRunnerCommand)
    $recommendedGuideCommand = Get-FirstNonEmptyValue -Values @($recommendedVerificationCommand, $runnerOutputWiringSafeCommand)
    $nextFocus = 'Regenerate or repair the saved outputs now that the live runner source already appears to be wired.'
    $nextArtifactToOpen = $ArtifactPath
} else {
    $recommendedCommand = Get-FirstNonEmptyValue -Values @($safeRouteStep.recommended_command, $safeRouteCommand)
    $recommendedGuideCommand = Get-FirstNonEmptyValue -Values @($safeRouteStep.recommended_guide_command, $runnerOutputWiringSafeCommand)
    $nextFocus = Get-FirstNonEmptyValue -Values @($safeRouteStep.next_focus, 'Use the current safe route guidance before reopening the raw patch-target helper.')
    $nextArtifactToOpen = Get-FirstNonEmptyValue -Values @($safeRouteStep.next_artifact_to_open, $SummaryPath)
}

$report = [ordered]@{
    issue = 'Google issue #3 runner output patch snippets'
    purpose = 'Run the safe patch-target route first and, when it reaches a patch-ready state, capture the exact summary and manifest snippet lines needed for the remaining direct runner-output contract edit.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    safe_route_command = $safeRouteCommand
    raw_patch_targets_command = $rawPatchTargetsCommand
    recommended_runner_command = $recommendedRunnerCommand
    runner_output_wiring_safe_command = $runnerOutputWiringSafeCommand
    safe_route_status = $safeRouteStep.status
    raw_patch_targets_ran = [bool]$rawPatchTargetsRan
    raw_patch_targets_status = $rawPatchTargetsStatus
    recommended_patch_target = $recommendedPatchTarget
    recommended_regeneration_command = $recommendedRegenerationCommand
    recommended_verification_command = $recommendedVerificationCommand
    recommended_repair_command = $recommendedRepairCommand
    missing_runner_fields = @($missingRunnerFields)
    summary_patch_snippet_lines = @($summaryPatchSnippetLines)
    manifest_patch_snippet_lines = @($manifestPatchSnippetLines)
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
    if (@('safe-route-failed', 'raw-patch-targets-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 runner output patch snippets'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Safe route status: {0}" -f $report.safe_route_status)
Write-Host ("Raw patch-targets ran: {0}" -f $report.raw_patch_targets_ran)
Write-Host ("Raw patch-targets status: {0}" -f $report.raw_patch_targets_status)
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
    Write-Host 'Missing fields:'
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
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)

if (@('safe-route-failed', 'raw-patch-targets-failed') -contains $status) {
    exit 1
}
