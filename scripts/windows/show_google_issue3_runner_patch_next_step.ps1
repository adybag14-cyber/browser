[CmdletBinding(DefaultParameterSetName = 'Guide')]
param(
    [Parameter(ParameterSetName = 'State')]
    [ValidateSet('ready-for-runner-patch', 'already-direct', 'runner-already-wired-regenerate-outputs')]
    [string]$State,

    [string]$RepoRoot,
    [string]$SummaryPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-PowerShellSingleQuotedLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Add-SharedArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        $Value
    )

    if ($null -eq $Value) {
        return
    }
    if ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    $Arguments.Add("-$Name")
    if ($Value -is [string]) {
        $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $Value))
    } else {
        $Arguments.Add([string]$Value)
    }
}

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [System.Collections.Generic.List[string]]$Arguments,
        [string[]]$Switches = @()
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\$ScriptName"
    if ($Arguments -and $Arguments.Count -gt 0) {
        $command += " " + ($Arguments -join ' ')
    }
    foreach ($switchName in $Switches) {
        if ([string]::IsNullOrWhiteSpace($switchName)) {
            continue
        }

        $command += " -$switchName"
    }

    return $command
}

function Format-HelperCommandWithRepoRootEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [hashtable]$Arguments = @{},
        [string[]]$Switches = @(),
        [string]$RepoRootOverride
    )

    if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        $fallbackArguments = [System.Collections.Generic.List[string]]::new()
        foreach ($entry in $Arguments.GetEnumerator()) {
            Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $entry.Value
        }
        return Format-HelperCommand -ScriptName $ScriptName -Arguments $fallbackArguments -Switches $Switches
    }

    $command = "& '.\\scripts\\windows\\$ScriptName'"
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

    foreach ($switchName in $Switches) {
        if ([string]::IsNullOrWhiteSpace($switchName)) {
            continue
        }

        $command += " -$switchName"
    }

    $escapedRepoRoot = ("$RepoRootOverride") -replace "'", "''"
    return "powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$env:LIGHTPANDA_REPO_ROOT = '$escapedRepoRoot'; $command`""
}

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$decisionTablePath = 'docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md'
$quickstartNotePath = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath

$safeRouteEntrypointsCommand = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
$replayShortcutsCommand = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $sharedArguments
$suiteRouterCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
    SuiteName = 'google-recommended'
}) -RepoRootOverride $RepoRoot
$changeAreaCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
    ChangeArea = 'google-input'
}) -RepoRootOverride $RepoRoot
$wrapperArtifactPaths = @(
    'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-safe-route-runner-patch-handoff.json',
    'tmp-browser-smoke\headed-probe\google-issue3-runner-output-patch-handoff.json',
    'tmp-browser-smoke\headed-probe\google-issue3-runner-output-patch-targets-safe-route.json',
    'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-repair-runner-output-patch-targets.json'
)

$stateCatalog = [ordered]@{
    'ready-for-runner-patch' = [ordered]@{
        meaning = 'The current replay still needs a direct source edit in scripts/windows/run_google_issue3_recommended_validation.ps1.'
        next_goal = 'Patch the runner output contract in both saved output writers before reopening the safe wiring audit.'
        artifact_paths = $wrapperArtifactPaths
        commands = @(
            'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation.ps1',
            'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_wiring_status_safe.ps1',
            'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_wiring_status.ps1'
        )
        notes = @(
            'Patch both saved output writers: Write-RecommendedSummaryArtifact and Write-RecommendedManifestArtifact.',
            'Keep refresh_chain_artifact_path, refresh_chain_artifact_error, handoff_artifact_path, and handoff_artifact_error in both objects.',
            'Preserve nullable error fields exactly as emitted. If the wrapper says $null, keep $null.',
            'If you need to restart from the top-level issue #3 discovery path before patching, reopen the repo-root-aware safe-route entrypoints helper or replay shortcuts helper first.'
        )
    }
    'already-direct' = [ordered]@{
        meaning = 'The runner source already carries the direct contract fields that the safe-route wrapper expected.'
        next_goal = 'Skip another direct source patch and reopen the safe wiring audit immediately.'
        artifact_paths = @(
            'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-safe-route-runner-patch-handoff.json'
        )
        commands = @(
            'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_wiring_status_safe.ps1'
        )
        notes = @(
            'Do not patch scripts/windows/run_google_issue3_recommended_validation.ps1 again for this state.',
            'Only reopen the raw wiring helper after the safe audit routes there.',
            'If the saved handoff artifact is stale or missing, reopen the repo-root-aware safe-route entrypoints helper or replay shortcuts helper before widening back out to the broader validation chain.'
        )
    }
    'runner-already-wired-regenerate-outputs' = [ordered]@{
        meaning = 'The source is already wired, but the saved outputs are stale or still missing the repaired contract.'
        next_goal = 'Treat this as an output-regeneration problem, not another direct source edit.'
        artifact_paths = @(
            'tmp-browser-smoke\headed-probe\google-issue3-recommended-validation-safe-route-runner-patch-handoff.json'
        )
        commands = @(
            'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_repair_runner_output_contract_safe_route.ps1',
            'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_output_wiring_status_safe.ps1'
        )
        notes = @(
            'Prefer the emitted repair or regeneration command from the wrapper artifact when one is present.',
            'Return to the safe wiring audit after regeneration before widening back out to refresh-status or attached HTML follow-up.',
            'If the replay context is no longer clear, reopen the repo-root-aware safe-route entrypoints helper or replay shortcuts helper so the current fresh-replay and reuse-current-outputs routes are printed together again.'
        )
    }
}

if ($PSCmdlet.ParameterSetName -eq 'State') {
    $selected = [ordered]@{
        state = $State
        repo_root = $RepoRoot
        summary_path = $SummaryPath
        decision_table_path = $decisionTablePath
        quickstart_note_path = $quickstartNotePath
        safe_route_entrypoints_command = $safeRouteEntrypointsCommand
        replay_shortcuts_command = $replayShortcutsCommand
        suite_router_command = $suiteRouterCommand
        change_area_command = $changeAreaCommand
        meaning = $stateCatalog[$State].meaning
        next_goal = $stateCatalog[$State].next_goal
        artifact_paths = $stateCatalog[$State].artifact_paths
        commands = $stateCatalog[$State].commands
        notes = $stateCatalog[$State].notes
    }

    if ($Json) {
        $selected | ConvertTo-Json -Depth 6
        exit 0
    }

    Write-Host ('Issue #3 runner patch next step: {0}' -f $selected.state)
    Write-Host ''
    if ($selected.repo_root) {
        Write-Host ('Repo root: {0}' -f $selected.repo_root)
    }
    if ($selected.summary_path) {
        Write-Host ('Summary path:{0}' -f (' ' + $selected.summary_path))
    }
    if ($selected.repo_root -or $selected.summary_path) {
        Write-Host ''
    }
    Write-Host ('Meaning: {0}' -f $selected.meaning)
    Write-Host ('Next goal: {0}' -f $selected.next_goal)
    Write-Host ('Decision table: {0}' -f $selected.decision_table_path)
    Write-Host ('Quickstart note: {0}' -f $selected.quickstart_note_path)
    Write-Host ''
    Write-Host 'Read-first recovery:'
    Write-Host ('- Safe-route entrypoints: {0}' -f $selected.safe_route_entrypoints_command)
    Write-Host ('- Replay shortcuts: {0}' -f $selected.replay_shortcuts_command)
    Write-Host ('- Suite router: {0}' -f $selected.suite_router_command)
    Write-Host ('- Change-area view: {0}' -f $selected.change_area_command)
    Write-Host ''
    Write-Host 'Read these artifacts first:'
    foreach ($artifactPath in $selected.artifact_paths) {
        Write-Host ('- {0}' -f $artifactPath)
    }
    Write-Host ''
    Write-Host 'Commands:'
    foreach ($command in $selected.commands) {
        Write-Host ('- {0}' -f $command)
    }
    Write-Host ''
    Write-Host 'Notes:'
    foreach ($note in $selected.notes) {
        Write-Host ('- {0}' -f $note)
    }
    exit 0
}

$guide = [ordered]@{
    purpose = 'Translate the issue #3 safe-route runner-patch handoff state into the exact next move without reopening the longer decision-table note first.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    decision_table_path = $decisionTablePath
    quickstart_note_path = $quickstartNotePath
    safe_route_entrypoints_command = $safeRouteEntrypointsCommand
    replay_shortcuts_command = $replayShortcutsCommand
    suite_router_command = $suiteRouterCommand
    change_area_command = $changeAreaCommand
    wrapper_state_values = @(
        'ready-for-runner-patch',
        'already-direct',
        'runner-already-wired-regenerate-outputs'
    )
    example_commands = @(
        'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_patch_next_step.ps1 -State ready-for-runner-patch',
        'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_patch_next_step.ps1 -State already-direct',
        'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_runner_patch_next_step.ps1 -State runner-already-wired-regenerate-outputs'
    )
    notes = @(
        'Use this helper after the safe-route runner-patch handoff wrapper or the reuse-current-outputs wrapper tells you which state you landed on.',
        'Keep docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md nearby when you need the longer artifact order, field list, or guardrails.',
        'Prefer the newest wrapper artifact over older raw helper output when the states disagree.',
        'If you need to regain the broader replay context before acting on a state, reopen the repo-root-aware safe-route entrypoints helper or replay shortcuts helper first.'
    )
}

if ($Json) {
    $guide | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Issue #3 runner patch next-step helper'
Write-Host ''
if ($guide.repo_root) {
    Write-Host ('Repo root: {0}' -f $guide.repo_root)
}
if ($guide.summary_path) {
    Write-Host ('Summary path:{0}' -f (' ' + $guide.summary_path))
}
if ($guide.repo_root -or $guide.summary_path) {
    Write-Host ''
}
Write-Host ('Purpose: {0}' -f $guide.purpose)
Write-Host ('Decision table: {0}' -f $guide.decision_table_path)
Write-Host ('Quickstart note: {0}' -f $guide.quickstart_note_path)
Write-Host ''
Write-Host 'Read-first recovery:'
Write-Host ('- Safe-route entrypoints: {0}' -f $guide.safe_route_entrypoints_command)
Write-Host ('- Replay shortcuts: {0}' -f $guide.replay_shortcuts_command)
Write-Host ('- Suite router: {0}' -f $guide.suite_router_command)
Write-Host ('- Change-area view: {0}' -f $guide.change_area_command)
Write-Host ''
Write-Host 'Wrapper state values:'
foreach ($stateValue in $guide.wrapper_state_values) {
    Write-Host ('- {0}' -f $stateValue)
}
Write-Host ''
Write-Host 'Examples:'
foreach ($exampleCommand in $guide.example_commands) {
    Write-Host ('- {0}' -f $exampleCommand)
}
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $guide.notes) {
    Write-Host ('- {0}' -f $note)
}
