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
        output_preview = @($outputLines | Select-Object -First 12)
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
        status = 'skipped-by-safe-gate'
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
    $SummaryPath = Join-Path $repoRoot "tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-summary.json"
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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-validation-saved-output-contract-repair.json'
}

$artifactPathRepairScript = Join-Path $PSScriptRoot 'repair_google_issue3_validation_artifact_paths.ps1'
$runnerContractRepairScript = Join-Path $PSScriptRoot 'repair_google_issue3_runner_output_contract.ps1'
$wiringStatusSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_wiring_status_safe.ps1'
$wiringStatusScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_wiring_status.ps1'
$requiredHelpers = @(
    $artifactPathRepairScript,
    $runnerContractRepairScript,
    $wiringStatusSafeScript,
    $wiringStatusScript
)
foreach ($helperPath in $requiredHelpers) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$steps = [System.Collections.Generic.List[object]]::new()
$steps.Add((Invoke-JsonHelper -Name 'validation-artifact-path-repair' -ScriptPath $artifactPathRepairScript -Arguments @('-SummaryPath', $SummaryPath, '-Json'))) | Out-Null
$steps.Add((Invoke-JsonHelper -Name 'runner-output-contract-repair' -ScriptPath $runnerContractRepairScript -Arguments @('-SummaryPath', $SummaryPath, '-Json'))) | Out-Null

$wiringSafeStep = Invoke-JsonHelper -Name 'runner-output-wiring-safe-status' -ScriptPath $wiringStatusSafeScript -Arguments @('-SummaryPath', $SummaryPath, '-Json')
$steps.Add($wiringSafeStep) | Out-Null

$runRawWiringStatus = [bool](
    $wiringSafeStep.success -and
    @('runner-contract-missing', 'safe-to-run-existing-helper') -contains $wiringSafeStep.status
)
if ($runRawWiringStatus) {
    $steps.Add((Invoke-JsonHelper -Name 'runner-output-wiring-status' -ScriptPath $wiringStatusScript -Arguments @('-SummaryPath', $SummaryPath, '-Json'))) | Out-Null
} else {
    $steps.Add((New-SkippedHelperStep -Name 'runner-output-wiring-status' -ScriptPath $wiringStatusScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -RecommendedCommand $wiringSafeStep.recommended_command -RecommendedGuideCommand $wiringSafeStep.recommended_guide_command -NextFocus $wiringSafeStep.next_focus -NextArtifactToOpen $wiringSafeStep.next_artifact_to_open -Reason 'The safe runner-output wiring gate said the raw wiring helper was not the safest next checkpoint yet.')) | Out-Null
}

$failedSteps = @($steps | Where-Object { -not $_.success })
$pathRepairStep = @($steps | Where-Object { $_.name -eq 'validation-artifact-path-repair' } | Select-Object -First 1)[0]
$runnerContractRepairStep = @($steps | Where-Object { $_.name -eq 'runner-output-contract-repair' } | Select-Object -First 1)[0]
$wiringStep = @($steps | Where-Object { $_.name -eq 'runner-output-wiring-status' } | Select-Object -First 1)[0]

$status = $null
$reason = $null
if ($failedSteps.Count -gt 0) {
    $status = 'helper-failure'
    $reason = 'One or more saved-output repair helpers did not finish cleanly, so the current issue #3 summary and manifest still need direct attention before the next Windows replay trusts the narrower helper chain.'
} elseif ($wiringStep -and $wiringStep.status -eq 'fully-wired') {
    $status = 'fully-wired'
    $reason = 'The saved issue #3 artifact-path contract and direct runner-output contract are now both normalized, and the raw wiring audit reports the saved summary and manifest as fully wired.'
} elseif ($wiringStep -and $wiringStep.status -eq 'saved-artifacts-stale-runner-already-wired') {
    $status = 'saved-artifacts-stale-runner-already-wired'
    $reason = 'The live runner source already wires the direct fields, but the current saved issue #3 outputs still need a fresh Windows regeneration pass before later helpers can rely on that state.'
} elseif ($wiringStep -and @('refresh-fields-missing-only', 'handoff-fields-missing-only', 'summary-still-needs-direct-fields', 'manifest-still-needs-direct-fields', 'runner-contract-incomplete') -contains $wiringStep.status) {
    $status = 'runner-contract-still-open'
    $reason = 'The saved artifact-path repair ran, but the raw runner-output wiring audit still reports part of the direct refresh or handoff contract as incomplete.'
} elseif ($wiringSafeStep.status -eq 'safe-to-run-existing-helper') {
    $status = 'safe-gate-cleared'
    $reason = 'The saved artifact-path and runner-contract repairs ran cleanly, and the safe runner-output wiring gate now says the raw wiring helper is safe to trust again.'
} else {
    $status = 'safe-gate-follow-up-needed'
    $reason = if ($wiringSafeStep.reason) {
        $wiringSafeStep.reason
    } else {
        'The saved output repairs ran, but the safe runner-output wiring gate still recommends another bounded checkpoint before trusting the stricter helper path.'
    }
}

$commandSources = @(
    if ($wiringStep) { $wiringStep.recommended_command },
    if ($wiringSafeStep) { $wiringSafeStep.recommended_command },
    if ($runnerContractRepairStep) { $runnerContractRepairStep.recommended_command },
    if ($pathRepairStep) { $pathRepairStep.recommended_command },
    'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
)
$guideSources = @(
    if ($wiringStep) { $wiringStep.recommended_guide_command },
    if ($wiringSafeStep) { $wiringSafeStep.recommended_guide_command },
    if ($runnerContractRepairStep) { $runnerContractRepairStep.recommended_guide_command },
    if ($pathRepairStep) { $pathRepairStep.recommended_guide_command },
    'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide.ps1'
)
$focusSources = @(
    if ($wiringStep) { $wiringStep.next_focus },
    if ($wiringSafeStep) { $wiringSafeStep.next_focus },
    if ($runnerContractRepairStep) { $runnerContractRepairStep.next_focus },
    if ($pathRepairStep) { $pathRepairStep.next_focus }
)
$artifactSources = @(
    if ($wiringStep) { $wiringStep.next_artifact_to_open },
    if ($wiringSafeStep) { $wiringSafeStep.next_artifact_to_open },
    if ($runnerContractRepairStep) { $runnerContractRepairStep.next_artifact_to_open },
    $SummaryPath
)

$recommendedCommand = Get-FirstNonEmptyValue -Values $commandSources
$recommendedGuideCommand = Get-FirstNonEmptyValue -Values $guideSources
$nextFocus = Get-FirstNonEmptyValue -Values $focusSources
$nextArtifactToOpen = Get-FirstNonEmptyValue -Values $artifactSources

$report = [ordered]@{
    issue = 'Google issue #3 saved output contract repair'
    purpose = 'Run the bounded issue #3 artifact-path and direct runner-output repairs together, then audit whether the saved outputs are ready for the stricter runner wiring helpers again.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    status = $status
    reason = $reason
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    validation_artifact_path_repair_status = if ($pathRepairStep) { $pathRepairStep.status } else { $null }
    runner_output_contract_repair_status = if ($runnerContractRepairStep) { $runnerContractRepairStep.status } else { $null }
    runner_output_wiring_safe_status = if ($wiringSafeStep) { $wiringSafeStep.status } else { $null }
    runner_output_wiring_status = if ($wiringStep) { $wiringStep.status } else { $null }
    failed_step_count = $failedSteps.Count
    failed_step_names = @($failedSteps | ForEach-Object { $_.name })
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
    if ($status -eq 'helper-failure') {
        exit 1
    }
    exit 0
}

Write-Host 'Google issue #3 saved output contract repair'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Path repair: {0}" -f $report.validation_artifact_path_repair_status)
Write-Host ("Runner contract repair: {0}" -f $report.runner_output_contract_repair_status)
Write-Host ("Wiring safe: {0}" -f $report.runner_output_wiring_safe_status)
Write-Host ("Wiring raw:  {0}" -f $report.runner_output_wiring_status)
Write-Host ("Failed steps: {0}" -f $report.failed_step_count)
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

if ($status -eq 'helper-failure') {
    exit 1
}
