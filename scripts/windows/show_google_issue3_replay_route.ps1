[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
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

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [hashtable]$Arguments = @{}
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\$ScriptName"
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

    $command = "& '.\scripts\windows\$ScriptName'"
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

$resolvedRepoRoot = if ($RepoRoot) {
    $RepoRoot
} else {
    Resolve-RepoRoot $PSScriptRoot
}
$shouldPreserveRepoRoot = $PSBoundParameters.ContainsKey('RepoRoot') -or -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)
$recommendedRepoRoot = if ($shouldPreserveRepoRoot) {
    $resolvedRepoRoot
} else {
    $null
}
$recommendedSummaryPath = if ($PSBoundParameters.ContainsKey('SummaryPath')) {
    $SummaryPath
} else {
    $null
}

$route = [ordered]@{
    issue = 'Google issue #3 replay route'
    purpose = 'Bridge the high-level headed validation catalog, the bounded Google flow helper, and the current safe-route replay wrappers in one place.'
    repo_root = $resolvedRepoRoot
    summary_path = $recommendedSummaryPath
    read_first_suite_command = '.\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended'
    read_first_change_area_command = '.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input'
    read_first_google_flow_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1'
    safe_route_entrypoints_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    fresh_replay_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    reuse_current_outputs_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    runner_patch_next_step_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_runner_patch_next_step.ps1 -State <ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>'
    notes = @(
        'Start with read_first_suite_command when you want the broadest current issue #3 runner surfaced first.'
        'Use read_first_change_area_command when the next replay may branch into a narrower title, homepage-fixture, submit-path, shared Enter-order, attached-page, or live-trace slice.'
        'Use read_first_google_flow_command when you want the full bounded localhost-first ladder printed before you choose a narrower replay.'
        'Open safe_route_entrypoints_command when you are ready to choose between the fresh replay, reuse-current-outputs, refresh-status, handoff, summary-guide, and runner-wiring helpers.'
        'Use fresh_replay_command when issue #3 outputs may be stale or missing.'
        'Use reuse_current_outputs_command only when the current issue #3 outputs are already present and trusted.'
        'If the wrapper reports ready-for-runner-patch, already-direct, or runner-already-wired-regenerate-outputs, rerun runner_patch_next_step_command with that exact state.'
    )
}

if ($Json) {
    $route | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 replay route'
Write-Host ''
Write-Host ("Repo root:   {0}" -f $route.repo_root)
Write-Host ("Summary path:{0}" -f $(if ($route.summary_path) { " $($route.summary_path)" } else { ' <default>' }))
Write-Host ''
Write-Host 'Read-first:'
Write-Host ("  Suite router:        {0}" -f $route.read_first_suite_command)
Write-Host ("  Change-area view:    {0}" -f $route.read_first_change_area_command)
Write-Host ("  Google flow helper:  {0}" -f $route.read_first_google_flow_command)
Write-Host ''
Write-Host 'Safe-route bridge:'
Write-Host ("  Entrypoints helper:  {0}" -f $route.safe_route_entrypoints_command)
Write-Host ("  Fresh replay:        {0}" -f $route.fresh_replay_command)
Write-Host ("  Reuse outputs:       {0}" -f $route.reuse_current_outputs_command)
Write-Host ("  Runner next step:    {0}" -f $route.runner_patch_next_step_command)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $route.notes) {
    Write-Host ("- {0}" -f $note)
}
