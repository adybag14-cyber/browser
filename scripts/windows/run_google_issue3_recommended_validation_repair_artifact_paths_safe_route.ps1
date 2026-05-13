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

function Invoke-JsonHelper {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

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

    $status = if ($record) {
        Get-OptionalPropertyValue -Object $record -Name 'status'
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

$repoRoot = Resolve-RepoRoot $PSScriptRoot
$artifactRoot = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe'
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-summary.json'
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-artifact-paths-safe-route.json'
}

$artifactPathRepairScript = Join-Path $PSScriptRoot 'repair_google_issue3_validation_artifact_paths.ps1'
$summaryContractSafeRouteScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation_repair_summary_contract_safe_route.ps1'
$artifactPathRepairCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\repair_google_issue3_validation_artifact_paths.ps1'
$summaryContractSafeRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_summary_contract_safe_route.ps1'
$summaryGuideSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'

foreach ($helperPath in @($artifactPathRepairScript, $summaryContractSafeRouteScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$artifactPathRepairStep = Invoke-JsonHelper -Name 'artifact-path-repair' -ScriptPath $artifactPathRepairScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
$summaryContractSafeRouteStep = $null
if ($artifactPathRepairStep.success) {
    $summaryContractSafeRouteStep = Invoke-JsonHelper -Name 'summary-contract-safe-route' -ScriptPath $summaryContractSafeRouteScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
}

$status = $null
$reason = $null
if (-not $artifactPathRepairStep.success) {
    $status = 'artifact-path-repair-failed'
    $reason = 'The artifact-path repair helper did not finish cleanly, so this wrapper stopped before reopening the narrower summary-contract safe route.'
} elseif (-not $summaryContractSafeRouteStep.success) {
    $status = 'summary-contract-safe-route-failed'
    $reason = 'The artifact-path repair helper finished, but the chained summary-contract safe route did not, so the next Windows replay should reopen that narrower safe route directly.'
} else {
    $status = Get-FirstNonEmptyValue -Values @($summaryContractSafeRouteStep.status, 'artifact-path-safe-route-ready')
    $reason = Get-FirstNonEmptyValue -Values @(
        $summaryContractSafeRouteStep.reason,
        'The artifact-path repair helper finished and this wrapper carried the replay directly into the existing summary-contract safe route.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($summaryContractSafeRouteStep) { $summaryContractSafeRouteStep.recommended_command },
    $artifactPathRepairStep.recommended_command,
    if ($summaryContractSafeRouteStep) { $summaryContractSafeRouteCommand },
    $artifactPathRepairCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($summaryContractSafeRouteStep) { $summaryContractSafeRouteStep.recommended_guide_command },
    $artifactPathRepairStep.recommended_guide_command,
    $summaryGuideSafeCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($summaryContractSafeRouteStep) { $summaryContractSafeRouteStep.next_focus },
    $artifactPathRepairStep.next_focus,
    'Repair the issue #3 artifact-path contract before widening back out to broader replay helpers.'
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($summaryContractSafeRouteStep) { $summaryContractSafeRouteStep.next_artifact_to_open },
    $artifactPathRepairStep.next_artifact_to_open,
    $ArtifactPath,
    $SummaryPath
)

$report = [ordered]@{
    issue = 'Google issue #3 recommended validation plus artifact-path repair and safe route'
    purpose = 'Run the bounded issue #3 artifact-path repair first, then immediately reopen the existing summary-contract safe route so older saved outputs rejoin the current safe replay chain in one step.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    artifact_path_repair_command = $artifactPathRepairCommand
    summary_contract_safe_route_command = $summaryContractSafeRouteCommand
    artifact_path_repair_status = $artifactPathRepairStep.status
    summary_contract_safe_route_status = if ($summaryContractSafeRouteStep) { $summaryContractSafeRouteStep.status } else { 'skipped' }
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    status = $status
    reason = $reason
    steps = @(
        [ordered]@{
            name = $artifactPathRepairStep.name
            status = $artifactPathRepairStep.status
            success = [bool]$artifactPathRepairStep.success
            exit_code = $artifactPathRepairStep.exit_code
            parse_error = $artifactPathRepairStep.parse_error
            error = $artifactPathRepairStep.error
            recommended_command = $artifactPathRepairStep.recommended_command
            recommended_guide_command = $artifactPathRepairStep.recommended_guide_command
            next_focus = $artifactPathRepairStep.next_focus
            next_artifact_to_open = $artifactPathRepairStep.next_artifact_to_open
            reason = $artifactPathRepairStep.reason
            output_preview = @($artifactPathRepairStep.output_preview)
        }
        [ordered]@{
            name = 'summary-contract-safe-route'
            status = if ($summaryContractSafeRouteStep) { $summaryContractSafeRouteStep.status } else { 'skipped' }
            success = if ($summaryContractSafeRouteStep) { [bool]$summaryContractSafeRouteStep.success } else { $false }
            exit_code = if ($summaryContractSafeRouteStep) { $summaryContractSafeRouteStep.exit_code } else { 0 }
            parse_error = if ($summaryContractSafeRouteStep) { $summaryContractSafeRouteStep.parse_error } else { $null }
            error = if ($summaryContractSafeRouteStep) { $summaryContractSafeRouteStep.error } else { $null }
            recommended_command = if ($summaryContractSafeRouteStep) { $summaryContractSafeRouteStep.recommended_command } else { $null }
            recommended_guide_command = if ($summaryContractSafeRouteStep) { $summaryContractSafeRouteStep.recommended_guide_command } else { $null }
            next_focus = if ($summaryContractSafeRouteStep) { $summaryContractSafeRouteStep.next_focus } else { $null }
            next_artifact_to_open = if ($summaryContractSafeRouteStep) { $summaryContractSafeRouteStep.next_artifact_to_open } else { $null }
            reason = if ($summaryContractSafeRouteStep) { $summaryContractSafeRouteStep.reason } else { 'Skipped because artifact-path repair did not finish cleanly.' }
            output_preview = if ($summaryContractSafeRouteStep) { @($summaryContractSafeRouteStep.output_preview) } else { @() }
        }
    )
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    if (@('artifact-path-repair-failed', 'summary-contract-safe-route-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 recommended validation plus artifact-path repair and safe route'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Run:       {0}" -f $report.recommended_command)
Write-Host ("Guide:     {0}" -f $report.recommended_guide_command)
Write-Host ("Focus:     {0}" -f $report.next_focus)
Write-Host ("Open:      {0}" -f $report.next_artifact_to_open)

if (@('artifact-path-repair-failed', 'summary-contract-safe-route-failed') -contains $status) {
    exit 1
}
