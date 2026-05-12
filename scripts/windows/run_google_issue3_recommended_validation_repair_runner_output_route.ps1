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

function Invoke-JsonHelper {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $output = @(
        & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1
    )
    $exitCode = $LASTEXITCODE
    $outputText = ($output | ForEach-Object { "${_}" }) -join [Environment]::NewLine
    if ($exitCode -ne 0) {
        throw "$Name failed with exit code $exitCode."
    }
    if ([string]::IsNullOrWhiteSpace($outputText)) {
        throw "$Name produced no JSON output."
    }

    try {
        return ($outputText | ConvertFrom-Json)
    } catch {
        throw "$Name returned non-JSON output."
    }
}

$repoRoot = Resolve-RepoRoot $PSScriptRoot
$artifactRoot = Join-Path $repoRoot 'tmp-browser-smoke\headed-probe'
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-summary.json'
}
if (-not $ArtifactPath) {
    $ArtifactPath = Join-Path $artifactRoot 'google-issue3-recommended-validation-repair-runner-output-route.json'
}

$patchTargetRouteScript = Join-Path $PSScriptRoot 'run_google_issue3_recommended_validation_repair_runner_output_patch_targets.ps1'
$runnerOutputWiringSafeScript = Join-Path $PSScriptRoot 'show_google_issue3_runner_output_wiring_status_safe.ps1'
$patchTargetRouteCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_recommended_validation_repair_runner_output_patch_targets.ps1'
$runnerOutputWiringSafeCommand = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_output_wiring_status_safe.ps1'

foreach ($helperPath in @($patchTargetRouteScript, $runnerOutputWiringSafeScript)) {
    if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
        throw "Issue #3 helper not found: $helperPath"
    }
}

$patchTargetRouteArgs = @('-SummaryPath', $SummaryPath, '-Json')
if ($RunnerArgument) {
    $patchTargetRouteArgs += '-RunnerArgument'
    $patchTargetRouteArgs += $RunnerArgument
}
$patchTargetRouteRecord = Invoke-JsonHelper -ScriptPath $patchTargetRouteScript -Arguments $patchTargetRouteArgs -Name 'runner-output patch-target route'
$runnerOutputWiringSafeRecord = $null
$status = $patchTargetRouteRecord.status
$reason = $patchTargetRouteRecord.reason
$recommendedCommand = Get-OptionalPropertyValue -Object $patchTargetRouteRecord -Name 'recommended_command'
$recommendedGuideCommand = Get-OptionalPropertyValue -Object $patchTargetRouteRecord -Name 'recommended_guide_command'
$nextFocus = Get-OptionalPropertyValue -Object $patchTargetRouteRecord -Name 'next_focus'
$nextArtifactToOpen = Get-OptionalPropertyValue -Object $patchTargetRouteRecord -Name 'next_artifact_to_open'

if ($patchTargetRouteRecord.status -eq 'ready-for-runner-output-wiring') {
    $runnerOutputWiringSafeRecord = Invoke-JsonHelper -ScriptPath $runnerOutputWiringSafeScript -Arguments @('-SummaryPath', $SummaryPath, '-Json') -Name 'runner-output wiring safe'
    $status = if ($runnerOutputWiringSafeRecord.status -eq 'safe-to-run-existing-helper') {
        'runner-output-wiring-ready'
    } else {
        'runner-output-wiring-follow-up'
    }
    $reason = Get-FirstNonEmptyValue -Values @(
        $runnerOutputWiringSafeRecord.reason,
        'The runner output route reached the safe wiring audit and preserved its narrower follow-up guidance.'
    )
    $recommendedCommand = Get-FirstNonEmptyValue -Values @(
        $runnerOutputWiringSafeRecord.recommended_command,
        $recommendedCommand,
        $runnerOutputWiringSafeCommand
    )
    $recommendedGuideCommand = Get-FirstNonEmptyValue -Values @(
        $runnerOutputWiringSafeRecord.recommended_guide_command,
        $recommendedGuideCommand,
        $runnerOutputWiringSafeCommand
    )
    $nextFocus = Get-FirstNonEmptyValue -Values @(
        $runnerOutputWiringSafeRecord.next_focus,
        $nextFocus
    )
    $nextArtifactToOpen = Get-FirstNonEmptyValue -Values @(
        $runnerOutputWiringSafeRecord.next_artifact_to_open,
        $nextArtifactToOpen,
        $SummaryPath
    )
}

$report = [ordered]@{
    issue = 'Google issue #3 recommended validation runner output route'
    purpose = 'Run the saved runner-output patch-target route and automatically reopen the safe runner-output wiring audit when the branch is already ready for that narrower next step.'
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    summary_path = $SummaryPath
    artifact_path = $ArtifactPath
    runner_argument_passthrough = @($RunnerArgument)
    patch_target_route_command = $patchTargetRouteCommand
    runner_output_wiring_safe_command = $runnerOutputWiringSafeCommand
    patch_target_route_status = $patchTargetRouteRecord.status
    runner_output_wiring_safe_status = if ($runnerOutputWiringSafeRecord) { $runnerOutputWiringSafeRecord.status } else { $null }
    recommended_patch_target = Get-OptionalPropertyValue -Object $patchTargetRouteRecord -Name 'recommended_patch_target'
    runner_patch_still_required = [bool](Get-OptionalPropertyValue -Object $patchTargetRouteRecord -Name 'runner_patch_still_required')
    recommended_command = $recommendedCommand
    recommended_guide_command = $recommendedGuideCommand
    next_focus = $nextFocus
    next_artifact_to_open = $nextArtifactToOpen
    status = $status
    reason = $reason
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ArtifactPath -Encoding Ascii

if ($Json) {
    $report | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host 'Google issue #3 recommended validation runner output route'
Write-Host ''
Write-Host ("Summary:   {0}" -f $report.summary_path)
Write-Host ("Artifact:  {0}" -f $report.artifact_path)
Write-Host ("Status:    {0}" -f $report.status)
Write-Host ("Patch route: {0}" -f $report.patch_target_route_status)
if ($report.runner_output_wiring_safe_status) {
    Write-Host ("Wiring safe: {0}" -f $report.runner_output_wiring_safe_status)
}
if ($report.recommended_patch_target) {
    Write-Host ("Patch target: {0}" -f $report.recommended_patch_target)
}
Write-Host ''
Write-Host ("Reason: {0}" -f $report.reason)
Write-Host ("Focus:  {0}" -f $report.next_focus)
Write-Host ("Open:   {0}" -f $report.next_artifact_to_open)
Write-Host ("Run:    {0}" -f $report.recommended_command)
Write-Host ("Guide:  {0}" -f $report.recommended_guide_command)
