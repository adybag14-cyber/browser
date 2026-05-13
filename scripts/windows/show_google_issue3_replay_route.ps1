[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
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

        if ($value -is [System.Array]) {
            $items = @($value | Where-Object { -not [string]::IsNullOrWhiteSpace("$($_)") })
            if ($items.Count -eq 0) {
                continue
            }

            $command += (" -{0}" -f $entry.Key)
            foreach ($item in $items) {
                $escapedItem = ("$item") -replace "'", "''"
                $command += (" '{0}'" -f $escapedItem)
            }
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

        if ($value -is [System.Array]) {
            $items = @($value | Where-Object { -not [string]::IsNullOrWhiteSpace("$($_)") })
            if ($items.Count -eq 0) {
                continue
            }

            $command += (" -{0}" -f $entry.Key)
            foreach ($item in $items) {
                $escapedItem = ("$item") -replace "'", "''"
                $command += (" '{0}'" -f $escapedItem)
            }
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
$recommendedInputPath = if ($PSBoundParameters.ContainsKey('InputPath')) {
    $InputPath
} else {
    @()
}
$runnerPatchStatePlaceholder = '<ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>'

$route = [ordered]@{
    issue = 'Google issue #3 replay route'
    purpose = 'Bridge the high-level headed validation catalog, the bounded Google flow helper, the attached three-page compatibility bundle branch, and the current safe-route replay wrappers in one place while preserving repo-root, summary-path, and pinned bundle-input context across the printed handoff commands.'
    repo_root = $resolvedRepoRoot
    summary_path = $recommendedSummaryPath
    input_paths = $recommendedInputPath
    explicit_input_path_count = if ($recommendedInputPath) { @($recommendedInputPath).Count } else { 0 }
    read_first_suite_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
        SuiteName = 'google-recommended'
    }) -RepoRootOverride $recommendedRepoRoot
    read_first_change_area_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
        ChangeArea = 'google-input'
    }) -RepoRootOverride $recommendedRepoRoot
    read_first_google_flow_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $recommendedRepoRoot
    attached_bundle_change_area_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
        ChangeArea = 'attached-html-target-bundle'
    }) -RepoRootOverride $recommendedRepoRoot
    attached_bundle_entrypoint_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    replay_shortcuts_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        InputPath = $recommendedInputPath
    }) -RepoRootOverride $recommendedRepoRoot
    safe_route_entrypoints_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    fresh_replay_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    reuse_current_outputs_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
    }) -RepoRootOverride $recommendedRepoRoot
    runner_patch_next_step_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_patch_next_step.ps1' -Arguments ([ordered]@{
        SummaryPath = $recommendedSummaryPath
        State = $runnerPatchStatePlaceholder
    }) -RepoRootOverride $recommendedRepoRoot
    notes = @(
        'Start with read_first_suite_command when you want the broadest current issue #3 runner surfaced first, while preserving RepoRoot for non-default checkouts when it is already in play.',
        'Use read_first_change_area_command when the next replay may branch into a narrower title, homepage-fixture, submit-path, shared Enter-order, attached-page, or live-trace slice, without dropping the current RepoRoot context.',
        'Use read_first_google_flow_command when you want the full bounded localhost-first ladder printed before you choose a narrower replay, while keeping the same RepoRoot context as the later safe-route helpers.',
        'If the current saved or attached pages are the known three-page compatibility bundle, use attached_bundle_change_area_command and attached_bundle_entrypoint_command before reopening the broader wrapper-heavy safe route.',
        'Use replay_shortcuts_command when you want the same route narrowed around the bundle-aware shortcut map, the replay helpers, and the current safe-route bridge without reopening the longer suite-router handoff first.',
        'Open safe_route_entrypoints_command when you are ready to choose between the fresh replay, reuse-current-outputs, refresh-status, handoff, summary-guide, and runner-wiring helpers.',
        'Use fresh_replay_command when issue #3 outputs may be stale or missing.',
        'Use reuse_current_outputs_command only when the current issue #3 outputs are already present and trusted.',
        'If the wrapper reports ready-for-runner-patch, already-direct, or runner-already-wired-regenerate-outputs, rerun runner_patch_next_step_command with that exact state while keeping the current repo-root and summary-path context attached.',
        'When LIGHTPANDA_REPO_ROOT, a saved SummaryPath, or pinned InputPath values are already guiding the replay, the emitted read-first, replay-shortcuts, attached-bundle, safe-route, and runner-next-step commands preserve that same context so the replay route stays aligned with the newer entrypoint helpers.'
    )
}

$route.recommended_next_command = if ($route.explicit_input_path_count -gt 0) {
    $route.attached_bundle_entrypoint_command
} else {
    $route.replay_shortcuts_command
}
$route.recommended_next_reason = if ($route.explicit_input_path_count -gt 0) {
    'Pinned input paths are already present, so stay on the attached three-page compatibility bundle branch first before widening back into the broader safe-route wrappers.'
} else {
    'No bundle inputs are pinned yet, so reopen the replay shortcuts next to keep the shortcut map, attached-bundle branch, and safe-route bridge together in one compact surface.'
}

if ($Json) {
    $route | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 replay route'
Write-Host ''
Write-Host ("Repo root:   {0}" -f $route.repo_root)
Write-Host ("Summary path:{0}" -f $(if ($route.summary_path) { " $($route.summary_path)" } else { ' <default>' }))
if ($route.explicit_input_path_count -gt 0) {
    Write-Host ("Input paths: {0}" -f $route.explicit_input_path_count)
}
Write-Host ''
Write-Host ("Recommended next:    {0}" -f $route.recommended_next_command)
Write-Host ("Why:                 {0}" -f $route.recommended_next_reason)
Write-Host ''
Write-Host 'Read-first:'
Write-Host ("  Suite router:        {0}" -f $route.read_first_suite_command)
Write-Host ("  Change-area view:    {0}" -f $route.read_first_change_area_command)
Write-Host ("  Google flow helper:  {0}" -f $route.read_first_google_flow_command)
Write-Host ''
Write-Host 'Attached-bundle branch:'
Write-Host ("  Bundle route:        {0}" -f $route.attached_bundle_change_area_command)
Write-Host ("  Bundle helper:       {0}" -f $route.attached_bundle_entrypoint_command)
Write-Host ("  Replay shortcuts:    {0}" -f $route.replay_shortcuts_command)
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
