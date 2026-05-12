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
        status = 'skipped-by-safe-route'
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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-validation-handoff-chain-safe.json'
}

$refreshStatusSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_refresh_status_safe.ps1'
$refreshChainScript = Join-Path $PSScriptRoot 'refresh_google_issue3_validation_handoff_chain.ps1'
$refreshStatusSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_refresh_status_safe.ps1'
$refreshChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\refresh_google_issue3_validation_handoff_chain.ps1'
$handoffSafeRefreshRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff_safe_refresh_route.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'

foreach ($helperPath in @($refreshStatusSafeScript, $refreshChainScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$steps = [System.Collections.Generic.List[object]]::new()
$refreshStatusSafeStep = Invoke-JsonHelper -Name 'refresh-status-safe' -ScriptPath $refreshStatusSafeScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
$steps.Add($refreshStatusSafeStep) | Out-Null

$shouldRunRefreshChain = [bool]($refreshStatusSafeStep.success -and $refreshStatusSafeStep.status -eq 'safe-to-run-existing-helper')
$refreshChainStep = $null
if ($shouldRunRefreshChain) {
    $refreshChainStep = Invoke-JsonHelper -Name 'refresh-chain' -ScriptPath $refreshChainScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
} else {
    $refreshChainStep = New-SkippedHelperStep -Name 'refresh-chain' -ScriptPath $refreshChainScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -RecommendedCommand $(Get-FirstNonEmptyValue -Values @($refreshStatusSafeStep.recommended_command, $handoffSafeRefreshRouteCommand)) -RecommendedGuideCommand $(Get-FirstNonEmptyValue -Values @($refreshStatusSafeStep.recommended_guide_command, $summaryGuideCommand)) -NextFocus $(Get-FirstNonEmptyValue -Values @($refreshStatusSafeStep.next_focus, 'Use the safe refresh-status guidance first; only enter the raw handoff-chain refresh helper once the saved runner contract and artifacts are safe under strict mode.')) -NextArtifactToOpen $(Get-FirstNonEmptyValue -Values @($refreshStatusSafeStep.next_artifact_to_open, $SummaryPath)) -Reason 'The safe refresh-status precheck did not report safe-to-run-existing-helper, so the raw handoff-chain refresh helper was not run directly.'
}
$steps.Add($refreshChainStep) | Out-Null

$status = $null
$reason = $null
if (-not $refreshStatusSafeStep.success) {
    $status = 'refresh-status-safe-failed'
    $reason = 'The safe refresh-status precheck did not finish cleanly, so the next Windows replay should restart from that safer checkpoint before entering the raw handoff-chain refresh helper.'
} elseif ($shouldRunRefreshChain -and -not $refreshChainStep.success) {
    $status = 'refresh-chain-failed'
    $reason = 'The safe refresh-status precheck passed, but the raw handoff-chain refresh helper did not finish cleanly, so the next Windows replay should reopen the raw refresh report it produced.'
} elseif ($shouldRunRefreshChain) {
    $status = 'refresh-chain-ran'
    $reason = 'The safe refresh-status precheck confirmed the saved runner contract and helper artifacts were safe enough, so this wrapper delegated straight to the raw handoff-chain refresh helper and preserved its next-step guidance.'
} else {
    $status = 'rerouted-before-refresh-chain'
    $reason = Get-FirstNonEmptyValue -Values @(
        $refreshStatusSafeStep.reason,
        'The safe refresh-status precheck found a safer next step than running the raw handoff-chain refresh helper directly.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunRefreshChain) { $refreshChainStep.recommended_command },
    $refreshStatusSafeStep.recommended_command,
    if ($shouldRunRefreshChain) { $refreshChainCommand },
    $refreshStatusSafeCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunRefreshChain) { $refreshChainStep.recommended_guide_command },
    $refreshStatusSafeStep.recommended_guide_command,
    if ($shouldRunRefreshChain) { $handoffSafeRefreshRouteCommand },
    $summaryGuideCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunRefreshChain) { $refreshChainStep.next_focus },
    $refreshStatusSafeStep.next_focus,
    if ($shouldRunRefreshChain) { 'Follow the raw handoff-chain refresh guidance produced in this run.' },
    'Use the safe refresh-status checkpoint to choose the next narrower replay step before entering the raw handoff-chain refresh helper.'
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($shouldRunRefreshChain) { $refreshChainStep.next_artifact_to_open },
    $refreshStatusSafeStep.next_artifact_to_open,
    $SummaryPath
)

$report = [ordered]@{
    issue = 'Google issue #3 handoff-chain safe refresh helper'
    purpose = 'Run the refresh-status safe precheck first and only delegate into the raw handoff-chain refresh helper when the saved runner contract and helper artifacts are safe enough under strict mode.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    refresh_status_safe_command = $refreshStatusSafeCommand
    refresh_chain_command = $refreshChainCommand
    handoff_safe_refresh_route_command = $handoffSafeRefreshRouteCommand
    summary_guide_command = $summaryGuideCommand
    refresh_chain_ran = [bool]$shouldRunRefreshChain
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
    if (@('refresh-status-safe-failed', 'refresh-chain-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 handoff-chain safe refresh helper'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Refresh chain ran: {0}" -f $report.refresh_chain_ran)
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

if (@('refresh-status-safe-failed', 'refresh-chain-failed') -contains $status) {
    exit 1
}
