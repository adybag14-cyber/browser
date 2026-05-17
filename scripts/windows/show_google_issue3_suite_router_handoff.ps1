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
            $value = $entry.Value
            if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
                Add-SharedPathArrayArgument -Arguments $fallbackArguments -Name $entry.Key -Values @($value)
            } else {
                Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $value
            }
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
        if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
            $valueList = @($value | Where-Object {
                if ($_ -is [string]) {
                    -not [string]::IsNullOrWhiteSpace($_)
                } else {
                    $null -ne $_
                }
            })
            if ($valueList.Count -eq 0) {
                continue
            }

            $command += " -$($entry.Key)"
            foreach ($item in $valueList) {
                $escapedItem = ("$item") -replace "'", "''"
                $command += " '$escapedItem'"
            }
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

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath -and @($InputPath).Count -gt 0) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$replayRouteShortcutCommand = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $bundleArguments
$googleAttachedHtmlSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1' -RepoRootOverride $RepoRoot
$googleAttachedHtmlFlowCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot

$handoff = [ordered]@{
    issue = 'Google issue #3 suite router handoff'
    purpose = 'Keep the higher-level suite-router entrypoints, the attached-page route, the dedicated Google-shaped attached-page route, the dedicated Google attached-page surface check, the dedicated Google attached-page flow helper, the newer suite-router attached-page quickstart, the newer top-level attached-page quickstart, the newer top-level attached-page bridge, the issue-specific Google attached-page bridge, the new shortcut-first suite-router entrypoint, the shortcut-first replay helper, the compact next-step matrix, the suite-catalog bridge, the replay-route helper, the replay-route shortcut helper, and the current issue #3 replay helpers on one command surface before the replay narrows further, without dropping pinned bundle-input context.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    replay_discovery_note_path = 'docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md'
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    validation_router_attached_html_quickstart_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    replay_route_shortcut_bridge_note_path = 'docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md'
    google_attached_html_entrypoint_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    suite_router_commands = [ordered]@{
        google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        google_input_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $bundleArguments
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand
        google_attached_html_flow = $googleAttachedHtmlFlowCommand
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        replay_route_shortcut = $replayRouteShortcutCommand
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
        'Use attached_html_change_area when the next replay is already narrowed to the attached-page compatibility route and you want that top-level branch visible before deciding whether to jump into the suite-router attached-page quickstart, the dedicated Google attached-page bridge, the top-level attached-page quickstart, the top-level attached-page bridge, the shortcut-first helper, or stay pinned to the bundle-first path.',
        'Use google_attached_html_change_area when the next replay is already narrowed to the issue-specific Google-shaped attached-page route and you want that top-level branch kept visible before deciding whether to jump into the dedicated surface check, the dedicated Google attached-page flow helper, the issue-specific Google attached-page bridge, the suite-router attached-page quickstart, the top-level attached-page quickstart, the top-level attached-page bridge, replay_shortcuts, suite_router_next_steps, suite_catalog_entrypoints, replay_route, replay_route_shortcut, or the bundle-first branch.',
        'Use suite_router_attached_html_quickstart when the route is already narrowed to attached localhost follow-up from the higher-level suite router and you want the shortest suite-router-side attached-page bridge before deciding whether to reopen top_level_attached_html_quickstart, top_level_attached_html_entrypoint, google_attached_html_surface_check, google_attached_html_flow, google_attached_html_entrypoint, replay_shortcuts, suite_router_next_steps, suite_catalog_entrypoints, replay_route, replay_route_shortcut, or the bundle-first branch.',
        'Use google_attached_html_surface_check when the route is already narrowed to the issue-specific Google-shaped attached-page branch and you want the fail-fast checker surfaced immediately before the dedicated Google attached-page flow helper or the narrower issue-specific attached-page bridge.',
        'Use google_attached_html_flow when the route is already narrowed to the issue-specific Google-shaped attached-page branch and you want the dedicated flow helper surfaced before deciding whether to reopen the issue-specific attached-page bridge, the shortcut-first route, replay_shortcuts, suite_router_next_steps, suite_catalog_entrypoints, replay_route, replay_route_shortcut, contextual_flow, or the bundle-first branch.',
        'Use google_attached_html_entrypoint when the route is already narrowed to the issue-specific Google-shaped attached-page follow-up and you want the shortest issue-specific attached-page bridge before deciding whether to reopen suite_router_attached_html_quickstart, top_level_attached_html_quickstart, top_level_attached_html_entrypoint, google_attached_html_surface_check, google_attached_html_flow, replay_shortcuts, suite_router_next_steps, suite_catalog_entrypoints, replay_route, replay_route_shortcut, contextual_flow, or the bundle-first branch.',
        'Use top_level_attached_html_quickstart when the route is already clearly inside the top-level attached-page lane and you want the shortest top-level attached-page bridge kept visible before the broader top-level attached-page bridge, replay_shortcuts, suite_router_next_steps, suite_catalog_entrypoints, replay_route, replay_route_shortcut, or the safe-route map.',
        'Use top_level_attached_html_entrypoint when the route is already clearly inside the issue-specific attached-page branch and you want the shorter top-level attached-page bridge kept visible before replay_shortcuts, the next-step matrix, suite_catalog_entrypoints, replay_route, replay_route_shortcut, or the safe-route map.',
        'Use suite_router_shortcut_entrypoint when you want the shortest issue #3 top-level bridge from the current suite-router state into replay_shortcuts while still preserving SummaryPath and InputPath context when those values are already pinned.',
        'Use suite_catalog_entrypoints when you want the exact top-level suite-router entrypoints, the attached-page route, the dedicated Google-shaped attached-page route, the dedicated Google attached-page surface check, the dedicated Google attached-page flow helper, the newer suite-router attached-page quickstart, the issue-specific Google attached-page bridge, the newer top-level attached-page quickstart, the newer top-level attached-page bridge, the shortcut-first suite-router entrypoint, the shortcut-first replay helper, the compact next-step matrix, the suite-catalog bridge, the broader Google flow helper, the replay-route helper, the replay-route shortcut helper, and the current replay helpers reprinted together before narrowing further, while keeping SummaryPath and InputPath context attached when they are already pinned.',
        'Use replay_shortcuts as the default follow-up after the higher-level suite router, the attached-page route, the dedicated Google-shaped attached-page route, the dedicated Google attached-page surface check, the dedicated Google attached-page flow helper, the suite-router attached-page quickstart, the issue-specific Google attached-page bridge, the top-level attached-page quickstart, the top-level attached-page bridge, the shortcut-first suite-router entrypoint, or the suite-catalog bridge when the route is already known to stay inside issue #3 and no pinned bundle inputs, saved summary, or repo-root override need to take precedence first.',
        'Use suite_router_next_steps when you still want the explicit start-point table after the attached-page bridges, the dedicated Google attached-page surface check, the dedicated Google attached-page flow helper, the issue-specific Google attached-page bridge, or the shortcut-first bridge, or when you want the helper recommendation reprinted before deciding whether to widen into replay_route, replay_route_shortcut, stay pinned to attached_bundle_first, or reopen the safe-route map.',
        'Use replay_route when you want the slightly broader bridge after replay_shortcuts, the dedicated Google-shaped attached-page route, the dedicated Google attached-page surface check, the dedicated Google attached-page flow helper, the suite-router attached-page quickstart, the issue-specific Google attached-page bridge, the top-level attached-page quickstart, the top-level attached-page bridge, or the next-step matrix so the attached-bundle branch, the replay-route shortcut, the safe-route map, and repo-root-aware runner-state choices stay together before narrowing again.',
        'Use replay_route_shortcut when replay-route follow-up is already open and you want the shorter printed bridge kept visible before the bundle-first branch or the wrapper-heavy safe-route map takes over.',
        'Use contextual_flow when RepoRoot, SummaryPath, or pinned InputPath values already matter and you want the broader recommended runner, replay shortcuts, attached bundle, live trace, later follow-up commands, replay route, and replay-route shortcut kept on one context-preserving surface before reopening the wrapper-heavy safe route.',
        'Use the read-first bridge when you want the exact route from the higher-level suite router into the attached-page route, the dedicated Google-shaped attached-page route, the dedicated Google attached-page surface check, the dedicated Google attached-page flow helper, the suite-router attached-page quickstart, the issue-specific Google attached-page bridge, the top-level attached-page quickstart, the top-level attached-page bridge, the shortcut-first suite-router entrypoint, the shortcut-first replay helper, the next-step matrix, the suite-catalog bridge, the broader Google flow helper, the replay-route helper, the replay-route shortcut helper, and the companion bundle-first branch printed in one place before reopening any longer notes.',
        'Keep replay_discovery_note_path nearby when you want the shortest written bridge from the top-level Windows validation catalog into this suite-router handoff, the attached-page route, the dedicated Google-shaped attached-page route, the dedicated Google attached-page surface check, the dedicated Google attached-page flow helper, the suite-router attached-page quickstart, the issue-specific Google attached-page bridge, the top-level attached-page quickstart, the top-level attached-page bridge, the shortcut-first suite-router entrypoint, the shortcut-first replay helper, the next-step matrix, the suite-catalog bridge, the broader Google flow helper, the replay-route helper, the replay-route shortcut helper, and the bundle-first branch without reopening the longer validation-chain notes first.',
        'Use attached_bundle_change_area when the current saved or attached inputs are the known three-page compatibility bundle and you want the suite router itself to reopen on that pinned branch first.',
        'Keep suite_router_bridge_note_path nearby when you want the shortest written bridge from the higher-level suite router into suite_router_shortcut_entrypoint, replay_shortcuts, suite_router_next_steps, suite_catalog_entrypoints, replay_route, replay_route_shortcut, contextual_flow, google_attached_html_surface_check, google_attached_html_flow, google_attached_html_entrypoint, or the attached-page route without reopening the longer Windows runbook or validation-chain notes first.',
        'Keep suite_router_attached_html_quickstart_note_path nearby when you want the written suite-router-side attached-page bridge beside the helper output before reopening the top-level attached-page helpers, the dedicated Google attached-page surface check, the dedicated Google attached-page flow helper, the issue-specific Google attached-page bridge, or the wider replay-route notes.',
        'Keep suite_catalog_entrypoint_note_path nearby when you want the shortest written bridge from the higher-level suite router into the newer suite-catalog helper order before reopening replay_shortcuts, suite_router_next_steps, replay_route, replay_route_shortcut, google_attached_html_surface_check, google_attached_html_flow, google_attached_html_entrypoint, or contextual_flow.',
        'Keep top_level_attached_html_quickstart_note_path, top_level_attached_html_bridge_note_path, and top_level_attached_html_catalog_quickstart_note_path nearby when you want the compact, broader, and catalog-flavored top-level attached-page bridges surfaced together beside this handoff.',
        'Keep windows_replay_attached_html_quickstart_note_path, validation_router_attached_html_quickstart_note_path, suite_catalog_attached_html_bridge_note_path, replay_route_shortcut_bridge_note_path, google_attached_html_entrypoint_note_path, and google_attached_html_validation_flow_note_path nearby when you want the replay-side, validation-router, suite-catalog, replay-route, and Google-shaped attached-page companion notes surfaced alongside this helper without reopening the longer validation-chain notes first.',
        'Use attached_bundle_first when the replay should stay pinned to the known three-page compatibility bundle before widening back into the broader Google-only issue #3 chain.',
        'Use safe_route_entrypoints only after the higher-level suite router, the attached-page route, the dedicated Google-shaped attached-page route, the dedicated Google attached-page surface check, the dedicated Google attached-page flow helper, the suite-router attached-page quickstart, the issue-specific Google attached-page bridge, the top-level attached-page quickstart, the top-level attached-page bridge, the shortcut-first suite-router entrypoint, the shortcut-first replay helper, next-step matrix, suite-catalog bridge, replay-route helper, replay-route shortcut helper, contextual_flow surface, or attached bundle-first helper has already narrowed the replay into the current wrapper-heavy issue #3 path, and keep the same InputPath values attached when the bundle is already pinned.'
    )
}

$handoff.bridge_sequence = [ordered]@{
    google_recommended = $handoff.suite_router_commands.google_recommended
    google_input_change_area = $handoff.suite_router_commands.google_input_change_area
    attached_html_change_area = $handoff.suite_router_commands.attached_html_change_area
    google_attached_html_change_area = $handoff.suite_router_commands.google_attached_html_change_area
    google_attached_html_surface_check = $handoff.helper_commands.google_attached_html_surface_check
    google_attached_html_flow = $handoff.helper_commands.google_attached_html_flow
    suite_router_attached_html_quickstart = $handoff.helper_commands.suite_router_attached_html_quickstart
    google_attached_html_entrypoint = $handoff.helper_commands.google_attached_html_entrypoint
    top_level_attached_html_quickstart = $handoff.helper_commands.top_level_attached_html_quickstart
    top_level_attached_html_entrypoint = $handoff.helper_commands.top_level_attached_html_entrypoint
    suite_router_shortcut_entrypoint = $handoff.helper_commands.suite_router_shortcut_entrypoint
    replay_shortcuts = $handoff.helper_commands.replay_shortcuts
    suite_router_next_steps = $handoff.helper_commands.suite_router_next_steps
    suite_catalog_entrypoints = $handoff.helper_commands.suite_catalog_entrypoints
    google_flow = $handoff.helper_commands.google_flow
    replay_route = $handoff.helper_commands.replay_route
    replay_route_shortcut = $handoff.helper_commands.replay_route_shortcut
    attached_bundle_change_area = $handoff.suite_router_commands.attached_bundle_change_area
}

$recommendedNextHelperKey = 'suite_router_shortcut_entrypoint'
$recommendedNextHelperReason = 'No explicit input paths, saved summary, or repo-root override are in play yet, so reopen the shortcut-first entrypoint next and keep the shorter issue #3 bridge visible before widening into replay shortcuts, the attached-page quickstarts, the dedicated Google attached-page surface check, the dedicated Google attached-page flow helper, the dedicated Google attached-page bridge, the next-step matrix, the suite-catalog bridge, replay route, the replay-route shortcut, or the safe-route map.'
if ($handoff.explicit_input_path_count -gt 0) {
    $recommendedNextHelperKey = 'attached_bundle_first'
    $recommendedNextHelperReason = 'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle first before widening back into the broader Google-only issue #3 helper chain.'
} elseif (-not [string]::IsNullOrWhiteSpace($SummaryPath) -or -not [string]::IsNullOrWhiteSpace($RepoRoot)) {
    $recommendedNextHelperKey = 'contextual_flow'
    $recommendedNextHelperReason = 'A non-default RepoRoot or saved SummaryPath is already in play, so reopen the context-preserving flow next and keep that replay state aligned while you choose between the suite-router attached-page quickstart, the dedicated Google attached-page surface check, the dedicated Google attached-page flow helper, the dedicated Google attached-page bridge, the top-level attached-page quickstart, the top-level attached-page bridge, the shortcut-first entrypoint, replay shortcuts, next-step matrix, suite-catalog bridge, attached bundle, replay route, replay-route shortcut, safe-route map, the broader recommended runner, or the later trace and follow-up helpers.'
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
Write-Host ("  1. Google recommended:            {0}" -f $handoff.bridge_sequence.google_recommended)
Write-Host ("  2. Google input:                  {0}" -f $handoff.bridge_sequence.google_input_change_area)
Write-Host ("  3. Attached HTML:                 {0}" -f $handoff.bridge_sequence.attached_html_change_area)
Write-Host ("  4. Google attached HTML:          {0}" -f $handoff.bridge_sequence.google_attached_html_change_area)
Write-Host ("  5. Google attached surface check: {0}" -f $handoff.bridge_sequence.google_attached_html_surface_check)
Write-Host ("  6. Google attached flow:          {0}" -f $handoff.bridge_sequence.google_attached_html_flow)
Write-Host ("  7. Suite-router attached quickstart: {0}" -f $handoff.bridge_sequence.suite_router_attached_html_quickstart)
Write-Host ("  8. Google attached bridge:        {0}" -f $handoff.bridge_sequence.google_attached_html_entrypoint)
Write-Host ("  9. Top-level attached quickstart: {0}" -f $handoff.bridge_sequence.top_level_attached_html_quickstart)
Write-Host (" 10. Top-level attached bridge:     {0}" -f $handoff.bridge_sequence.top_level_attached_html_entrypoint)
Write-Host (" 11. Shortcut entry:                {0}" -f $handoff.bridge_sequence.suite_router_shortcut_entrypoint)
Write-Host (" 12. Replay shortcuts:              {0}" -f $handoff.bridge_sequence.replay_shortcuts)
Write-Host (" 13. Next-step matrix:              {0}" -f $handoff.bridge_sequence.suite_router_next_steps)
Write-Host (" 14. Suite-catalog:                 {0}" -f $handoff.bridge_sequence.suite_catalog_entrypoints)
Write-Host (" 15. Google flow:                   {0}" -f $handoff.bridge_sequence.google_flow)
Write-Host (" 16. Replay route:                  {0}" -f $handoff.bridge_sequence.replay_route)
Write-Host (" 17. Replay-route shortcut:         {0}" -f $handoff.bridge_sequence.replay_route_shortcut)
Write-Host (" 18. Bundle-first branch:           {0}" -f $handoff.bridge_sequence.attached_bundle_change_area)
Write-Host ''
Write-Host 'Suite-router entrypoints:'
Write-Host ("  Google recommended: {0}" -f $handoff.suite_router_commands.google_recommended)
Write-Host ("  Google input:       {0}" -f $handoff.suite_router_commands.google_input_change_area)
Write-Host ("  Attached HTML:      {0}" -f $handoff.suite_router_commands.attached_html_change_area)
Write-Host ("  Google attached:    {0}" -f $handoff.suite_router_commands.google_attached_html_change_area)
Write-Host ("  Attached bundle:    {0}" -f $handoff.suite_router_commands.attached_bundle_change_area)
Write-Host ''
Write-Host 'Shortcut helpers:'
Write-Host ("  Suite-router shortcut:          {0}" -f $handoff.helper_commands.suite_router_shortcut_entrypoint)
Write-Host ("  Suite-router attached bridge:   {0}" -f $handoff.helper_commands.suite_router_attached_html_quickstart)
Write-Host ("  Google attached surface check:  {0}" -f $handoff.helper_commands.google_attached_html_surface_check)
Write-Host ("  Google attached flow:           {0}" -f $handoff.helper_commands.google_attached_html_flow)
Write-Host ("  Google attached bridge:         {0}" -f $handoff.helper_commands.google_attached_html_entrypoint)
Write-Host ("  Top-level attached quickstart:  {0}" -f $handoff.helper_commands.top_level_attached_html_quickstart)
Write-Host ("  Top-level attached bridge:      {0}" -f $handoff.helper_commands.top_level_attached_html_entrypoint)
Write-Host ("  Replay shortcuts:               {0}" -f $handoff.helper_commands.replay_shortcuts)
Write-Host ("  Next-step matrix:               {0}" -f $handoff.helper_commands.suite_router_next_steps)
Write-Host ("  Suite-catalog bridge:           {0}" -f $handoff.helper_commands.suite_catalog_entrypoints)
Write-Host ("  Replay route:                   {0}" -f $handoff.helper_commands.replay_route)
Write-Host ("  Replay-route shortcut:          {0}" -f $handoff.helper_commands.replay_route_shortcut)
Write-Host ("  Contextual flow:                {0}" -f $handoff.helper_commands.contextual_flow)
Write-Host ("  Google flow:                    {0}" -f $handoff.helper_commands.google_flow)
Write-Host ("  Bundle first:                   {0}" -f $handoff.helper_commands.attached_bundle_first)
Write-Host ("  Safe route map:                 {0}" -f $handoff.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host ("Quickstart note:                  {0}" -f $handoff.quickstart_note_path)
Write-Host ("Replay discovery:                 {0}" -f $handoff.replay_discovery_note_path)
Write-Host ("Windows runbook:                  {0}" -f $handoff.windows_runbook_note_path)
Write-Host ("Validation chain:                 {0}" -f $handoff.validation_chain_note_path)
Write-Host ("Suite-router bridge:              {0}" -f $handoff.suite_router_bridge_note_path)
Write-Host ("Suite-router attached quickstart: {0}" -f $handoff.suite_router_attached_html_quickstart_note_path)
Write-Host ("Suite-catalog guide:              {0}" -f $handoff.suite_catalog_entrypoint_note_path)
Write-Host ("Suite-catalog attached bridge:    {0}" -f $handoff.suite_catalog_attached_html_bridge_note_path)
Write-Host ("Top-level attached quickstart:    {0}" -f $handoff.top_level_attached_html_quickstart_note_path)
Write-Host ("Top-level attached bridge:        {0}" -f $handoff.top_level_attached_html_bridge_note_path)
Write-Host ("Top-level attached catalog:       {0}" -f $handoff.top_level_attached_html_catalog_quickstart_note_path)
Write-Host ("Windows replay note:              {0}" -f $handoff.windows_replay_attached_html_quickstart_note_path)
Write-Host ("Validation-router note:           {0}" -f $handoff.validation_router_attached_html_quickstart_note_path)
Write-Host ("Replay-route shortcut note:       {0}" -f $handoff.replay_route_shortcut_bridge_note_path)
Write-Host ("Google attached entrypoint:       {0}" -f $handoff.google_attached_html_entrypoint_note_path)
Write-Host ("Google attached flow note:        {0}" -f $handoff.google_attached_html_validation_flow_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $handoff.notes) {
    Write-Host ("- {0}" -f $note)
}
