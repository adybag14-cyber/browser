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
    purpose = 'Keep the higher-level suite-router entrypoints, the new shortcut-first suite-router entrypoint, the shortcut-first replay helper, the compact next-step matrix, the suite-catalog bridge, and the current issue #3 replay helpers on one command surface before the replay narrows further, without dropping pinned bundle-input context.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    replay_discovery_note_path = 'docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md'
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md'
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
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $bundleArguments
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        google_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $RepoRoot
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
    }
    notes = @(
        'Start with google_recommended when you want the broader localhost-first issue #3 runner surfaced from the suite catalog before choosing a narrower branch.',
        'Use google_input_change_area when the next replay may need the title, homepage-fixture, submit-path, shared Enter-order, live-trace, or attached-page slices instead of the broader recommended runner.',
        'Use suite_router_shortcut_entrypoint when you want the shortest issue #3 top-level bridge from the current suite-router state into replay_shortcuts while still preserving SummaryPath and InputPath context when those values are already pinned.',
        'Use suite_catalog_entrypoints when you want the exact top-level suite-router entrypoints, the newer shortcut-first suite-router entrypoint, the shortcut-first replay helper, the compact next-step matrix, the broader Google flow helper, and the current replay helpers reprinted together before narrowing further, while keeping SummaryPath and InputPath context attached when they are already pinned.',
        'Use replay_shortcuts as the default follow-up after the higher-level suite router, the shortcut-first suite-router entrypoint, or the suite-catalog bridge when the route is already known to stay inside issue #3 and no pinned bundle inputs, saved summary, or repo-root override need to take precedence first.',
        'Use suite_router_next_steps when you still want the explicit start-point table after the shortcut-first bridge, or when you want the helper recommendation reprinted before deciding whether to widen into replay_route, stay pinned to attached_bundle_first, or reopen the safe-route map.',
        'Use replay_route when you want the slightly broader bridge after replay_shortcuts or the next-step matrix so the attached-bundle branch, safe-route map, and repo-root-aware runner-state choices stay together before narrowing again.',
        'Use contextual_flow when RepoRoot, SummaryPath, or pinned InputPath values already matter and you want the broader recommended runner, replay shortcuts, attached bundle, live trace, and later follow-up commands kept on one context-preserving surface before reopening the wrapper-heavy safe route.',
        'Use the read-first bridge when you want the exact route from the higher-level suite router into the shortcut-first suite-router entrypoint, the shortcut-first replay helper, the next-step matrix, the suite-catalog bridge, the broader Google flow helper, the replay-route helper, and the companion bundle-first branch printed in one place before reopening any longer notes.',
        'Keep replay_discovery_note_path nearby when you want the shortest written bridge from the top-level Windows validation catalog into this suite-router handoff, the shortcut-first suite-router entrypoint, the shortcut-first replay helper, the next-step matrix, the suite-catalog bridge, the broader Google flow helper, the replay-route helper, and the bundle-first branch without reopening the longer validation-chain notes first.',
        'Use attached_bundle_change_area when the current saved or attached inputs are the known three-page compatibility bundle and you want the suite router itself to reopen on that pinned branch first.',
        'Keep suite_router_bridge_note_path nearby when you want the shortest written bridge from the higher-level suite router into suite_router_shortcut_entrypoint, replay_shortcuts, suite_router_next_steps, suite_catalog_entrypoints, replay_route, or contextual_flow without reopening the longer Windows runbook or validation-chain notes first.',
        'Keep suite_catalog_entrypoint_note_path nearby when you want the shortest written bridge from the higher-level suite router into the newer suite-catalog helper order before reopening replay_shortcuts, suite_router_next_steps, replay_route, or contextual_flow.',
        'Use attached_bundle_first when the replay should stay pinned to the known three-page compatibility bundle before widening back into the broader Google-only issue #3 chain.',
        'Use safe_route_entrypoints only after the higher-level suite router, the shortcut-first suite-router entrypoint, the shortcut-first replay helper, next-step matrix, suite-catalog bridge, replay-route helper, contextual_flow surface, or attached bundle-first helper has already narrowed the replay into the current wrapper-heavy issue #3 path, and keep the same InputPath values attached when the bundle is already pinned.'
    )
}

$handoff.bridge_sequence = [ordered]@{
    google_recommended = $handoff.suite_router_commands.google_recommended
    google_input_change_area = $handoff.suite_router_commands.google_input_change_area
    suite_router_shortcut_entrypoint = $handoff.helper_commands.suite_router_shortcut_entrypoint
    replay_shortcuts = $handoff.helper_commands.replay_shortcuts
    suite_router_next_steps = $handoff.helper_commands.suite_router_next_steps
    suite_catalog_entrypoints = $handoff.helper_commands.suite_catalog_entrypoints
    google_flow = $handoff.helper_commands.google_flow
    replay_route = $handoff.helper_commands.replay_route
}

$recommendedNextHelperKey = 'replay_shortcuts'
$recommendedNextHelperReason = 'No explicit input paths, saved summary, or repo-root override are in play yet, so reopen the shortcut-first replay helper next and keep the narrower issue #3 route visible before widening back out into the next-step matrix, suite-catalog bridge, replay route, or safe-route map.'
if ($handoff.explicit_input_path_count -gt 0) {
    $recommendedNextHelperKey = 'attached_bundle_first'
    $recommendedNextHelperReason = 'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle first before widening back into the broader Google-only issue #3 helper chain.'
} elseif (-not [string]::IsNullOrWhiteSpace($SummaryPath) -or -not [string]::IsNullOrWhiteSpace($RepoRoot)) {
    $recommendedNextHelperKey = 'contextual_flow'
    $recommendedNextHelperReason = 'A non-default RepoRoot or saved SummaryPath is already in play, so reopen the context-preserving flow next and keep that replay state aligned while you choose between the shortcut-first entrypoint, replay shortcuts, next-step matrix, suite-catalog bridge, attached bundle, safe-route map, the broader recommended runner, or the later trace and follow-up helpers.'
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
Write-Host ("  3. Shortcut entry:     {0}" -f $handoff.bridge_sequence.suite_router_shortcut_entrypoint)
Write-Host ("  4. Replay shortcuts:   {0}" -f $handoff.bridge_sequence.replay_shortcuts)
Write-Host ("  5. Next-step matrix:   {0}" -f $handoff.bridge_sequence.suite_router_next_steps)
Write-Host ("  6. Suite-catalog:      {0}" -f $handoff.bridge_sequence.suite_catalog_entrypoints)
Write-Host ("  7. Google flow:        {0}" -f $handoff.bridge_sequence.google_flow)
Write-Host ("  8. Replay route:       {0}" -f $handoff.bridge_sequence.replay_route)
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
Write-Host ("  Suite-router shortcut: {0}" -f $handoff.helper_commands.suite_router_shortcut_entrypoint)
Write-Host ("  Replay shortcuts:      {0}" -f $handoff.helper_commands.replay_shortcuts)
Write-Host ("  Next-step matrix:      {0}" -f $handoff.helper_commands.suite_router_next_steps)
Write-Host ("  Suite-catalog bridge:  {0}" -f $handoff.helper_commands.suite_catalog_entrypoints)
Write-Host ("  Replay route:          {0}" -f $handoff.helper_commands.replay_route)
Write-Host ("  Contextual flow:       {0}" -f $handoff.helper_commands.contextual_flow)
Write-Host ("  Google flow:           {0}" -f $handoff.helper_commands.google_flow)
Write-Host ("  Bundle first:          {0}" -f $handoff.helper_commands.attached_bundle_first)
Write-Host ("  Safe route map:        {0}" -f $handoff.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host ("Quickstart note:        {0}" -f $handoff.quickstart_note_path)
Write-Host ("Replay discovery:       {0}" -f $handoff.replay_discovery_note_path)
Write-Host ("Windows runbook:        {0}" -f $handoff.windows_runbook_note_path)
Write-Host ("Validation chain:       {0}" -f $handoff.validation_chain_note_path)
Write-Host ("Suite-router bridge:    {0}" -f $handoff.suite_router_bridge_note_path)
Write-Host ("Suite-catalog guide:    {0}" -f $handoff.suite_catalog_entrypoint_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $handoff.notes) {
    Write-Host ("- {0}" -f $note)
}