[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
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

function Add-SharedPathArrayArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string[]]$Values
    )

    if (-not $Values -or $Values.Count -eq 0) {
        return
    }

    $Arguments.Add("-$Name")
    foreach ($value in $Values) {
        $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $value))
    }
}

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [System.Collections.Generic.List[string]]$Arguments,
        [string[]]$Switches = @()
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\$ScriptName"
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

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$handoff = [ordered]@{
    issue = 'Google issue #3 suite router handoff'
    purpose = 'Keep the higher-level suite-router entrypoints, the compact next-step matrix, and the current issue #3 replay helpers on one command surface before the replay narrows further.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    replay_discovery_note_path = 'docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md'
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_router_commands = [ordered]@{
        google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        google_input_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        google_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $RepoRoot
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $sharedArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Start with google_recommended when you want the broader localhost-first issue #3 runner surfaced from the suite catalog before choosing a narrower branch.',
        'Use google_input_change_area when the next replay may need the title, homepage-fixture, submit-path, shared Enter-order, live-trace, or attached-page slices instead of the full recommended runner.',
        'Use suite_router_next_steps when you want the one-command next-step matrix that keeps the current suite-router start points, replay-route branch, attached-bundle branch, and runner-state helper choices together before you pick one route.',
        'Use the read-first bridge when you want the exact route from the higher-level suite router into the next-step matrix, replay-route helper, and replay-shortcuts helper printed in one place before reopening any longer notes.',
        'Keep replay_discovery_note_path nearby when you want the shortest written bridge from the top-level Windows validation catalog into this suite-router handoff, the next-step matrix, the replay-route helper, and the bundle-first branch without reopening the longer validation-chain notes first.',
        'Use attached_bundle_change_area when the current saved or attached inputs are the known three-page compatibility bundle and you want the suite router itself to reopen on that pinned branch first.',
        'Use replay_route when the next route is already clear after the handoff or next-step matrix and you still want the compact helper that keeps the attached-bundle branch, the replay-shortcuts helper, the safe-route map, and the repo-root-aware runner-next-step helper together before narrowing further.',
        'Use replay_shortcuts when you want the narrower shortcut map for the attached-bundle-first route and the wrapper-heavy safe-route branches after the replay-route helper has already confirmed the broader issue #3 context.',
        'Keep suite_router_bridge_note_path nearby when you want the shortest written bridge from the higher-level suite router into suite_router_next_steps, replay_route, or replay_shortcuts without reopening the longer Windows runbook or validation-chain notes first.',
        'Use attached_bundle_first when the replay should stay pinned to the known three-page compatibility bundle before widening back into the broader Google-only issue #3 chain.',
        'Use safe_route_entrypoints only after the higher-level suite router, next-step matrix, replay-route helper, or replay-shortcuts helper has already narrowed the replay into the current wrapper-heavy issue #3 path.'
    )
}

$handoff.bridge_sequence = [ordered]@{
    google_recommended = $handoff.suite_router_commands.google_recommended
    google_input_change_area = $handoff.suite_router_commands.google_input_change_area
    google_flow = $handoff.helper_commands.google_flow
    suite_router_next_steps = $handoff.helper_commands.suite_router_next_steps
    replay_route = $handoff.helper_commands.replay_route
    replay_shortcuts = $handoff.helper_commands.replay_shortcuts
}

$recommendedNextHelperKey = 'suite_router_next_steps'
$recommendedNextHelperReason = 'The higher-level suite-router commands are already visible, so reopen the compact next-step matrix next to keep the current start points, replay-route branch, attached-bundle branch, and runner-state helper choices together before the replay narrows further.'
if ($handoff.explicit_input_path_count -gt 0) {
    $recommendedNextHelperKey = 'attached_bundle_first'
    $recommendedNextHelperReason = 'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle first before widening back into the broader Google-only issue #3 helper chain.'
} elseif (-not [string]::IsNullOrWhiteSpace($SummaryPath)) {
    $recommendedNextHelperKey = 'replay_route'
    $recommendedNextHelperReason = 'A saved SummaryPath is already in play, so reopen the replay-route helper with that same context before deciding whether to stay on the bundle-first path, narrow into replay-shortcuts, or reopen the wrapper-heavy safe-route helpers.'
}

$handoff.recommended_next_helper_key = $recommendedNextHelperKey
$handoff.recommended_next_helper_reason = $recommendedNextHelperReason
$handoff.recommended_next_helper_command = $handoff.helper_commands[$recommendedNextHelperKey]

if ($Json) {
    $handoff | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 suite router handoff'
Write-Host ''
if ($handoff.repo_root) {
    Write-Host ("Repo root:   {0}" -f $handoff.repo_root)
}
if ($handoff.summary_path) {
    Write-Host ("Summary path:{0}" -f " $($handoff.summary_path)")
}
if ($handoff.explicit_input_path_count -gt 0) {
    Write-Host ("Input paths: {0}" -f $handoff.explicit_input_path_count)
}
Write-Host ''
Write-Host ("Recommended next helper: {0}" -f $handoff.recommended_next_helper_command)
Write-Host ("Why:                    {0}" -f $handoff.recommended_next_helper_reason)
Write-Host ''
Write-Host 'Read-first bridge:'
Write-Host ("  1. Google recommended: {0}" -f $handoff.bridge_sequence.google_recommended)
Write-Host ("  2. Google input:       {0}" -f $handoff.bridge_sequence.google_input_change_area)
Write-Host ("  3. Google flow:        {0}" -f $handoff.bridge_sequence.google_flow)
Write-Host ("  4. Next-step matrix:   {0}" -f $handoff.bridge_sequence.suite_router_next_steps)
Write-Host ("  5. Replay route:       {0}" -f $handoff.bridge_sequence.replay_route)
Write-Host ("  6. Replay shortcuts:   {0}" -f $handoff.bridge_sequence.replay_shortcuts)
if ($handoff.explicit_input_path_count -gt 0) {
    Write-Host ("  Bundle-first branch:   {0}" -f $handoff.suite_router_commands.attached_bundle_change_area)
}
Write-Host ''
Write-Host 'Suite-router entrypoints:'
Write-Host ("  Google recommended: {0}" -f $handoff.suite_router_commands.google_recommended)
Write-Host ("  Google input:       {0}" -f $handoff.suite_router_commands.google_input_change_area)
Write-Host ("  Attached bundle:    {0}" -f $handoff.suite_router_commands.attached_bundle_change_area)
Write-Host ''
Write-Host 'Shortcut helpers:'
Write-Host ("  Next-step matrix:  {0}" -f $handoff.helper_commands.suite_router_next_steps)
Write-Host ("  Google flow:       {0}" -f $handoff.helper_commands.google_flow)
Write-Host ("  Replay route:      {0}" -f $handoff.helper_commands.replay_route)
Write-Host ("  Replay shortcuts:  {0}" -f $handoff.helper_commands.replay_shortcuts)
Write-Host ("  Bundle first:      {0}" -f $handoff.helper_commands.attached_bundle_first)
Write-Host ("  Safe route map:    {0}" -f $handoff.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host ("Quickstart note:      {0}" -f $handoff.quickstart_note_path)
Write-Host ("Replay discovery:     {0}" -f $handoff.replay_discovery_note_path)
Write-Host ("Windows runbook:      {0}" -f $handoff.windows_runbook_note_path)
Write-Host ("Validation chain:     {0}" -f $handoff.validation_chain_note_path)
Write-Host ("Suite-router bridge:  {0}" -f $handoff.suite_router_bridge_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $handoff.notes) {
    Write-Host ("- {0}" -f $note)
}
