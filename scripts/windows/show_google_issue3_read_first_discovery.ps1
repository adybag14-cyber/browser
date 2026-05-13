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
    return "powershell -NoProfile -ExecutionPolicy Bypass -Command ```"`$env:LIGHTPANDA_REPO_ROOT = '$escapedRepoRoot'; $command```""
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

$discovery = [ordered]@{
    issue = 'Google issue #3 read-first discovery'
    purpose = 'Surface the shortest current commands for re-entering issue #3 from the headed validation catalog before choosing the safe-route replay wrappers.'
    repo_root = $resolvedRepoRoot
    summary_path = $recommendedSummaryPath
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    suite_router_command = '.\scripts\windows\show_headed_validation_suites.ps1 -SuiteName google-recommended'
    change_area_command = '.\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-input'
    google_flow_command = 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1'
    safe_route_entrypoints_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    notes = @(
        'Start with suite_router_command when you want the top-level validation catalog to surface the broader recommended issue #3 runner first.'
        'Use change_area_command when the next replay may need a narrower Google title, homepage-fixture, submit-path, shared Enter-order, attached-page, or live-trace slice instead of the broader runner.'
        'Use google_flow_command when you want the full localhost-first issue #3 ladder printed before deciding whether to stay on the wrapper path or drop to a narrower stage.'
        'Use safe_route_entrypoints_command when you are ready to stay on the current issue #3 wrapper family and want the fresh replay, reuse-current-outputs, refresh route, handoff-safe, summary-guide-safe, and runner-wiring-safe commands printed together.'
        'Keep quickstart_note_path open for the shortest replay note and validation_chain_note_path open when wrapper precedence matters.'
        'When RepoRoot or LIGHTPANDA_REPO_ROOT is set, the emitted safe-route command preserves that same checkout context instead of falling back to the default repo location.'
    )
}

if ($Json) {
    $discovery | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 read-first discovery'
Write-Host ''
Write-Host ("Repo root:   {0}" -f $discovery.repo_root)
Write-Host ("Summary path:{0}" -f $(if ($discovery.summary_path) { " $($discovery.summary_path)" } else { ' <default>' }))
Write-Host ''
Write-Host 'Commands:'
Write-Host ("  Suite router:         {0}" -f $discovery.suite_router_command)
Write-Host ("  Change-area view:     {0}" -f $discovery.change_area_command)
Write-Host ("  Google flow helper:   {0}" -f $discovery.google_flow_command)
Write-Host ("  Safe-route commands:  {0}" -f $discovery.safe_route_entrypoints_command)
Write-Host ''
Write-Host ("Quickstart note:        {0}" -f $discovery.quickstart_note_path)
Write-Host ("Validation chain note:  {0}" -f $discovery.validation_chain_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $discovery.notes) {
    Write-Host ("- {0}" -f $note)
}
