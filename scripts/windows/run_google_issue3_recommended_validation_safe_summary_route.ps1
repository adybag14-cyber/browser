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
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-safe-summary-route.json'
}

$runnerScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation.ps1'
$safeGuideScript = Join-Path $PSScriptRoot 'show_google_issue3_validation_summary_guide_safe.ps1'
$runnerCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation.ps1'
$safeGuideCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_validation_summary_guide_safe.ps1'

foreach ($scriptPath in @($runnerScript, $safeGuideScript)) {
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $scriptPath"
    }
}

$runnerSucceeded = $false
$runnerError = $null
$runnerParameters = @{
    RepoRoot = $resolvedRepoRoot
    SummaryPath = $SummaryPath
}
if ($BrowserExe) {
    $runnerParameters.BrowserExe = $BrowserExe
}

try {
    & $runnerScript @runnerParameters
    $runnerSucceeded = $true
} catch {
    $runnerError = $_.Exception.Message
}

$summaryExists = Test-Path -LiteralPath $SummaryPath -PathType Leaf
$guideRecord = $null
$guideError = $null
if ($summaryExists) {
    try {
        $guideOutput = @(
            & powershell -NoProfile -ExecutionPolicy Bypass -File $safeGuideScript -SummaryPath $SummaryPath -Json 2>&1
        )
        $guideText = ($guideOutput | ForEach-Object { "${_}" }) -join [Environment]::NewLine
        if ([string]::IsNullOrWhiteSpace($guideText)) {
            throw 'Google issue #3 validation summary guide safe helper produced no JSON output.'
        }

        $guideRecord = $guideText | ConvertFrom-Json
    } catch {
        $guideError = $_.Exception.Message
    }
} else {
    $guideError = "Issue #3 recommended validation summary not found after runner execution: $SummaryPath"
}

$status = if ($runnerSucceeded -and $guideRecord) {
    'runner-complete-safe-guide-ready'
} elseif (-not $runnerSucceeded -and $guideRecord) {
    'runner-failed-safe-guide-ready'
} elseif ($runnerSucceeded) {
    'runner-complete-safe-guide-missing'
} else {
    'runner-failed-safe-guide-missing'
}

$recommendedCommand = if ($guideRecord) {
    Get-OptionalPropertyValue -Object $guideRecord -Name 'recommended_command'
} else {
    $runnerCommand
}
$recommendedGuideCommand = if ($guideRecord) {
    Get-OptionalPropertyValue -Object $guideRecord -Name 'recommended_guide_command'
} else {
    $safeGuideCommand
}
$nextFocus = if ($guideRecord) {
    Get-OptionalPropertyValue -Object $guideRecord -Name 'next_focus'
} else {
    'Regenerate the issue #3 validation summary first, then reopen the strict-mode-safe summary guide before using narrower helpers.'
}
$reason = if ($guideRecord) {
    if ($runnerSucceeded) {
        'The broader issue #3 validation ladder completed far enough to regenerate the saved summary, and this wrapper immediately reopened the strict-mode-safe summary guide for the next Windows replay.'
    } else {
        'The broader issue #3 validation ladder stopped early, but it still left a summary artifact that the strict-mode-safe summary guide could reopen for the next Windows replay.'
    }
} elseif ($runnerSucceeded) {
    'The broader issue #3 validation ladder ran, but the strict-mode-safe summary guide could not reopen the resulting summary artifact cleanly.'
} else {
    'The broader issue #3 validation ladder did not complete cleanly and no safe summary guidance could be produced from the current saved outputs.'
}

$report = [ordered]@{
    issue = 'Google issue #3 recommended validation safe summary route'
    purpose = 'Run the broader issue #3 recommended validation ladder and immediately reopen the strict-mode-safe summary guide so the next Windows replay keeps current guidance in one artifact.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    repo_root = $resolvedRepoRoot
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    runner_script = $runnerScript
    runner_command = $runnerCommand
    runner_status = if ($runnerSucceeded) { 'passed' } else { 'failed' }
    runner_error = $runnerError
    summary_exists = [bool]$summaryExists
    safe_summary_guide_script = $safeGuideScript
    safe_summary_guide_command = $safeGuideCommand
    safe_summary_guide_error = $guideError
    safe_summary_guide_artifact_path = if ($guideRecord) { Get-OptionalPropertyValue -Object $guideRecord -Name 'artifact_path' } else { $null }
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_focus = $nextFocus
    reason = $reason
    status = $status
}

$report | ConvertTo-Json -Depth 6 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    if ($guideRecord) {
        exit 0
    }
    exit 1
}

Write-Host 'Google issue #3 recommended validation safe summary route'
Write-Host ''
Write-Host ("Summary: {0}" -f $report.summary_path)
Write-Host ("Artifact: {0}" -f $report.artifact_path)
Write-Host ("Runner status: {0}" -f $report.runner_status)
Write-Host ("Status: {0}" -f $report.status)
if ($report.runner_error) {
    Write-Host ("Runner error: {0}" -f $report.runner_error)
}
if ($report.safe_summary_guide_error) {
    Write-Host ("Safe guide error: {0}" -f $report.safe_summary_guide_error)
}
if ($report.safe_summary_guide_artifact_path) {
    Write-Host ("Safe guide artifact: {0}" -f $report.safe_summary_guide_artifact_path)
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus: {0}" -f $report.next_focus)
Write-Host ("Run next: {0}" -f $report.recommended_command)
if ($report.recommended_guide_command) {
    Write-Host ("Guide: {0}" -f $report.recommended_guide_command)
}

if (-not $guideRecord) {
    exit 1
}
