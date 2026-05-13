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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-runner-output-contract-refresh-status-safe.json'
}

$repairScript = Join-Path $PSScriptRoot 'repair_google_issue3_runner_output_contract.ps1'
$refreshStatusSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_refresh_status_safe.ps1'
$repairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_runner_output_contract.ps1'
$refreshStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe.ps1'
$refreshStatusCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status.ps1'
$runnerOutputWiringSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'

foreach ($helperPath in @($repairScript, $refreshStatusSafeScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$repairArguments = @('-SummaryPath', $SummaryPath, '-Json')
$refreshStatusSafeArguments = @('-SummaryPath', $SummaryPath, '-Json')

$steps = [System.Collections.Generic.List[object]]::new()
$repairStep = Invoke-ScriptStep -Name 'runner-output-contract-repair' -ScriptPath $repairScript -Arguments $repairArguments -ExpectJson
$steps.Add($repairStep) | Out-Null

$summaryExistsAfterRepair = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$refreshStatusSafeStep = $null
if ($summaryExistsAfterRepair) {
    $refreshStatusSafeStep = Invoke-ScriptStep -Name 'refresh-status-safe' -ScriptPath $refreshStatusSafeScript -Arguments $refreshStatusSafeArguments -ExpectJson
} else {
    $refreshStatusSafeStep = New-SkippedStep -Name 'refresh-status-safe' -ScriptPath $refreshStatusSafeScript -Arguments $refreshStatusSafeArguments -Reason 'The runner-output contract repair step did not leave a current summary artifact, so the refresh-status safe gate had no saved validation state to inspect.' -RecommendedCommand $(Get-FirstNonEmptyValue -Values @($repairStep.recommended_command, $repairCommand)) -RecommendedGuideCommand $(Get-FirstNonEmptyValue -Values @($repairStep.recommended_guide_command, $runnerOutputWiringSafeCommand, $summaryGuideCommand)) -NextFocus $(Get-FirstNonEmptyValue -Values @($repairStep.next_focus, 'Regenerate the issue #3 recommended validation summary before reopening the refresh-status safe gate.')) -NextArtifactToOpen $(Get-FirstNonEmptyValue -Values @($repairStep.next_artifact_to_open, $ArtifactPath))
}
$steps.Add($refreshStatusSafeStep) | Out-Null

$repairStatus = if ($repairStep.record) {
    Get-OptionalPropertyValue -Object $repairStep.record -Name 'status'
} else {
    $repairStep.status
}
$refreshStatusSafeStatus = if ($refreshStatusSafeStep.record) {
    Get-OptionalPropertyValue -Object $refreshStatusSafeStep.record -Name 'status'
} else {
    $refreshStatusSafeStep.status
}
$runnerContractMissing = if ($refreshStatusSafeStep.record -and $refreshStatusSafeStep.record.PSObject.Properties['runner_contract_missing']) {
    [bool]$refreshStatusSafeStep.record.runner_contract_missing
} else {
    $false
}
$summaryUpdatedFields = if ($repairStep.record) {
    @(Get-ArrayValue -Object $repairStep.record -Name 'summary_updated_fields')
} else {
    @()
}
$manifestUpdatedFields = if ($repairStep.record) {
    @(Get-ArrayValue -Object $repairStep.record -Name 'manifest_updated_fields')
} else {
    @()
}
$refreshSafeFieldsMissing = if ($refreshStatusSafeStep.record) {
    @(Get-ArrayValue -Object $refreshStatusSafeStep.record -Name 'refresh_safe_fields_missing')
} else {
    @()
}
$bundleSafeFieldsMissing = if ($refreshStatusSafeStep.record) {
    @(Get-ArrayValue -Object $refreshStatusSafeStep.record -Name 'bundle_safe_fields_missing')
} else {
    @()
}
$handoffSafeFieldsMissing = if ($refreshStatusSafeStep.record) {
    @(Get-ArrayValue -Object $refreshStatusSafeStep.record -Name 'handoff_safe_fields_missing')
} else {
    @()
}

$status = $null
$reason = $null
if (-not $summaryExistsAfterRepair) {
    $status = 'repair-no-summary'
    $reason = 'The runner-output contract repair step did not leave a current recommended-validation summary, so the refresh-status safe gate could not continue from saved state.'
} elseif (-not $repairStep.success) {
    $status = 'runner-output-contract-repair-failed'
    $reason = 'The runner-output contract repair step did not finish cleanly, so the next Windows replay should stay on that repair checkpoint before trusting the refresh-status gate.'
} elseif (-not $refreshStatusSafeStep.success) {
    $status = 'refresh-status-safe-failed'
    $reason = 'The runner-output contract repair step completed, but the refresh-status safe gate did not finish cleanly for the current saved summary.'
} else {
    $status = $refreshStatusSafeStatus
    $reason = Get-FirstNonEmptyValue -Values @(
        $refreshStatusSafeStep.reason,
        $repairStep.reason,
        'The runner-output contract repair and refresh-status safe gate completed; use the preserved recommendation for the next narrowed issue #3 replay.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($refreshStatusSafeStep.success) { $refreshStatusSafeStep.recommended_command },
    $repairStep.recommended_command,
    $refreshStatusSafeCommand,
    $repairCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($refreshStatusSafeStep.success) { $refreshStatusSafeStep.recommended_guide_command },
    $repairStep.recommended_guide_command,
    $runnerOutputWiringSafeCommand,
    $summaryGuideCommand,
    $refreshStatusCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($refreshStatusSafeStep.success) { $refreshStatusSafeStep.next_focus },
    $repairStep.next_focus,
    if (-not $summaryExistsAfterRepair) { 'Regenerate the issue #3 recommended validation summary before reopening the refresh-status safe gate.' }
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($refreshStatusSafeStep.success) { $refreshStatusSafeStep.next_artifact_to_open },
    $repairStep.next_artifact_to_open,
    if ($summaryExistsAfterRepair) { $SummaryPath },
    $ArtifactPath
)

$report = [ordered]@{
    issue = 'Google issue #3 runner output contract repair plus refresh status safe'
    purpose = 'Run the issue #3 runner-output contract repair first, then immediately reopen the refresh-status safe gate so the next Windows replay can keep moving on the normalized saved validation artifacts.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    summary_exists_after_repair = [bool]$summaryExistsAfterRepair
    runner_output_contract_repair_status = $repairStatus
    refresh_status_safe_status = $refreshStatusSafeStatus
    runner_contract_missing = [bool]$runnerContractMissing
    summary_updated_fields = @($summaryUpdatedFields)
    manifest_updated_fields = @($manifestUpdatedFields)
    refresh_safe_fields_missing = @($refreshSafeFieldsMissing)
    bundle_safe_fields_missing = @($bundleSafeFieldsMissing)
    handoff_safe_fields_missing = @($handoffSafeFieldsMissing)
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    repair_command = $repairCommand
    refresh_status_safe_command = $refreshStatusSafeCommand
    refresh_status_command = $refreshStatusCommand
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
            summary_updated_fields = if ($_.record) { @(Get-ArrayValue -Object $_.record -Name 'summary_updated_fields') } else { @() }
            manifest_updated_fields = if ($_.record) { @(Get-ArrayValue -Object $_.record -Name 'manifest_updated_fields') } else { @() }
            runner_contract_missing = if ($_.record -and $_.record.PSObject.Properties['runner_contract_missing']) { [bool]$_.record.runner_contract_missing } else { $false }
            refresh_safe_fields_missing = if ($_.record) { @(Get-ArrayValue -Object $_.record -Name 'refresh_safe_fields_missing') } else { @() }
            bundle_safe_fields_missing = if ($_.record) { @(Get-ArrayValue -Object $_.record -Name 'bundle_safe_fields_missing') } else { @() }
            handoff_safe_fields_missing = if ($_.record) { @(Get-ArrayValue -Object $_.record -Name 'handoff_safe_fields_missing') } else { @() }
            output_preview = @($_.output_preview)
        }
    })
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    if (@('repair-no-summary', 'runner-output-contract-repair-failed', 'refresh-status-safe-failed') -contains $status) {
        exit 1
    }

    exit 0
}

Write-Host 'Google issue #3 runner output contract repair plus refresh status safe'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary exists after repair: {0}" -f $report.summary_exists_after_repair)
Write-Host ("Repair status: {0}" -f $report.runner_output_contract_repair_status)
Write-Host ("Refresh safe status: {0}" -f $report.refresh_status_safe_status)
Write-Host ("Runner contract missing: {0}" -f $report.runner_contract_missing)
if ($report.summary_updated_fields.Count -gt 0) {
    Write-Host ("Summary fields repaired: {0}" -f ($report.summary_updated_fields -join ', '))
}
if ($report.manifest_updated_fields.Count -gt 0) {
    Write-Host ("Manifest fields repaired: {0}" -f ($report.manifest_updated_fields -join ', '))
}
if ($report.refresh_safe_fields_missing.Count -gt 0) {
    Write-Host ("Refresh safe fields missing: {0}" -f ($report.refresh_safe_fields_missing -join ', '))
}
if ($report.bundle_safe_fields_missing.Count -gt 0) {
    Write-Host ("Bundle safe fields missing: {0}" -f ($report.bundle_safe_fields_missing -join ', '))
}
if ($report.handoff_safe_fields_missing.Count -gt 0) {
    Write-Host ("Handoff safe fields missing: {0}" -f ($report.handoff_safe_fields_missing -join ', '))
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

if (@('repair-no-summary', 'runner-output-contract-repair-failed', 'refresh-status-safe-failed') -contains $status) {
    exit 1
}
