[CmdletBinding()]
param(
    [string]$SummaryPath,
    [string]$ArtifactPath,
    [string[]]$RunnerArgument,
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
$artifactRoot = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe'
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-summary.json'
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-handoff-coherency.json'
}

$repairChainScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation_repair_chain.ps1'
$handoffPathScript = Join-Path $PSScriptRoot 'show_google_issue3_handoff_path_coherency.ps1'
$repairChainCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_chain.ps1'
$handoffGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_handoff.ps1'
$handoffPathCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_handoff_path_coherency.ps1'
$summaryGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'

foreach ($helperPath in @($repairChainScript, $handoffPathScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$repairChainArguments = @('-SummaryPath', $SummaryPath, '-Json')
if ($RunnerArgument) {
    $repairChainArguments += '-RunnerArgument'
    $repairChainArguments += $RunnerArgument
}
$handoffPathArguments = @('-SummaryPath', $SummaryPath, '-Json')

$steps = [System.Collections.Generic.List[object]]::new()
$repairChainStep = Invoke-ScriptStep -Name 'recommended-validation-repair-chain' -ScriptPath $repairChainScript -Arguments $repairChainArguments -ExpectJson
$steps.Add($repairChainStep) | Out-Null

$summaryExistsAfterRepairChain = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$handoffPathStep = $null
if ($summaryExistsAfterRepairChain) {
    $handoffPathStep = Invoke-ScriptStep -Name 'handoff-path-coherency' -ScriptPath $handoffPathScript -Arguments $handoffPathArguments -ExpectJson
    $steps.Add($handoffPathStep) | Out-Null
} else {
    $handoffPathStep = New-SkippedStep -Name 'handoff-path-coherency' -ScriptPath $handoffPathScript -Arguments $handoffPathArguments -Reason 'The combined repair chain did not leave a current summary artifact, so the handoff path check had no replay state to inspect.' -RecommendedCommand $repairChainCommand -RecommendedGuideCommand $summaryGuideCommand -NextFocus 'Get the broader issue #3 validation chain to leave a fresh summary artifact before checking handoff path coherency.' -NextArtifactToOpen $ArtifactPath
    $steps.Add($handoffPathStep) | Out-Null
}

$explicitArtifactPathRequired = [bool](
    $handoffPathStep.record -and
    (Get-OptionalPropertyValue -Object $handoffPathStep.record -Name 'explicit_artifact_path_required')
)
$pathCoherent = [bool](
    $handoffPathStep.record -and
    (Get-OptionalPropertyValue -Object $handoffPathStep.record -Name 'path_coherent')
)

$status = $null
$reason = $null
if (-not $summaryExistsAfterRepairChain) {
    $status = 'repair-chain-no-summary'
    $reason = 'The broader issue #3 validation repair chain did not leave a summary artifact, so the follow-up handoff path check could not continue.'
} elseif (-not $repairChainStep.success) {
    $status = 'repair-chain-failed'
    $reason = 'The broader issue #3 validation repair chain did not finish cleanly, so the next replay still needs direct repair-chain attention before the handoff path is trusted.'
} elseif (-not $handoffPathStep.success) {
    $status = 'handoff-path-check-failed'
    $reason = 'The validation repair chain completed, but the handoff path coherency helper did not finish cleanly, so the next replay should stay on the saved repair artifact first.'
} elseif ($explicitArtifactPathRequired) {
    $status = 'ready-with-explicit-handoff-path'
    $reason = if ($handoffPathStep.reason) {
        $handoffPathStep.reason
    } else {
        'The saved issue #3 handoff path differs from the fallback default, so the next replay should use the explicit safe handoff command reported by the path-coherency helper.'
    }
} elseif ($repairChainStep.status -eq 'ready-for-handoff' -and $pathCoherent) {
    $status = 'ready-for-handoff'
    $reason = 'The broader validation repair chain says the issue #3 handoff path is ready, and the handoff path helper confirms the current handoff artifact location is coherent.'
} else {
    $status = 'follow-up-needed'
    $reason = Get-FirstNonEmptyValue -Values @(
        $handoffPathStep.reason,
        $repairChainStep.reason,
        'The broader validation repair chain and handoff path check completed, but the next issue #3 replay still needs the follow-up command reported by the saved artifacts.'
    )
}

$recommendedCommand = Get-FirstNonEmptyValue -Values @(
    if ($handoffPathStep) { $handoffPathStep.recommended_command },
    if ($repairChainStep) { $repairChainStep.recommended_command },
    $repairChainCommand
)
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
    if ($handoffPathStep) { $handoffPathStep.recommended_guide_command },
    if ($repairChainStep) { $repairChainStep.recommended_guide_command },
    $summaryGuideCommand
)
$nextFocus = Get-FirstNonEmptyValue -Values @(
    if ($handoffPathStep) { $handoffPathStep.next_focus },
    if ($repairChainStep) { $repairChainStep.next_focus },
    if (-not $summaryExistsAfterRepairChain) { 'Regenerate the issue #3 recommended validation summary before asking the handoff path helper to narrow the next replay.' }
)
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
    if ($handoffPathStep) { $handoffPathStep.next_artifact_to_open },
    if ($repairChainStep) { $repairChainStep.next_artifact_to_open },
    if ($summaryExistsAfterRepairChain) { $SummaryPath },
    $ArtifactPath
)

$report = [ordered]@{
    issue = 'Google issue #3 recommended validation repair plus handoff coherency'
    purpose = 'Run the broader issue #3 validation repair chain, then immediately confirm whether the saved handoff path is coherent enough for the next Windows replay to trust the handoff helper directly.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    runner_argument_passthrough = @($RunnerArgument)
    summary_exists_after_repair_chain = [bool]$summaryExistsAfterRepairChain
    repair_chain_status = $repairChainStep.status
    handoff_path_status = $handoffPathStep.status
    handoff_path_coherent = [bool]$pathCoherent
    explicit_artifact_path_required = [bool]$explicitArtifactPathRequired
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    repair_chain_command = $repairChainCommand
    handoff_path_command = $handoffPathCommand
    handoff_guide_command = $handoffGuideCommand
    summary_guide_command = $summaryGuideCommand
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
            error = $_.error
            parse_error = $_.parse_error
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
    if (@('repair-chain-no-summary', 'repair-chain-failed', 'handoff-path-check-failed') -contains $status) {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 recommended validation repair plus handoff coherency'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Summary exists after repair chain: {0}" -f $report.summary_exists_after_repair_chain)
Write-Host ("Repair chain: {0}" -f $report.repair_chain_status)
Write-Host ("Handoff path: {0}" -f $report.handoff_path_status)
Write-Host ("Path coherent: {0}" -f $report.handoff_path_coherent)
Write-Host ("Explicit path required: {0}" -f $report.explicit_artifact_path_required)
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

if (@('repair-chain-no-summary', 'repair-chain-failed', 'handoff-path-check-failed') -contains $status) {
    exit 1
}
