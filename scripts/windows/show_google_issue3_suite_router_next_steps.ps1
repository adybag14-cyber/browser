[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
    [string]$BrowserExe,
    [string]$Host = '127.0.0.1',
    [string]$SubmitTimingInputText = 'QZ',
    [string]$SharedInputText = 'Q',
    [string]$TraceInputText = 'lightpanda',
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
            $value = $entry.Value
            if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
                Add-SharedPathArrayArgument -Arguments $fallbackArguments -Name $entry.Key -Values @($value)
            } else {
                Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $value
            }
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

$safeRouteArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $safeRouteArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $safeRouteArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $safeRouteArguments -Name InputPath -Values $InputPath

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$bundleFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleFlowArguments -Name InputPath -Values $InputPath

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath -and @($InputPath).Count -gt 0) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$googleAttachedHtmlSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot
$suiteRouterSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_suite_router_next_steps_validation_surface.ps1' -RepoRootOverride $RepoRoot

$submitTimingFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $submitTimingFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $submitTimingFlowArguments -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $submitTimingFlowArguments -Name Host -Value $Host
Add-SharedArgument -Arguments $submitTimingFlowArguments -Name InputText -Value $SubmitTimingInputText

$sharedEnterOrderFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedEnterOrderFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedEnterOrderFlowArguments -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $sharedEnterOrderFlowArguments -Name Host -Value $Host
Add-SharedArgument -Arguments $sharedEnterOrderFlowArguments -Name SharedInputText -Value $SharedInputText

$liveTraceFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $liveTraceFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $liveTraceFlowArguments -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $liveTraceFlowArguments -Name Host -Value $Host
Add-SharedArgument -Arguments $liveTraceFlowArguments -Name InputText -Value $TraceInputText

$runnerPatchStatePlaceholder = '<ready-for-runner-patch|already-direct|runner-already-wired-regenerate-outputs>'
$recommendedHelperKey = 'suite_router_shortcut_entrypoint'
$recommendedHelperReason = 'No pinned bundle inputs, saved summary, or non-default repo root are in play yet, so reopen the shortcut-first entrypoint first and keep the shorter issue #3 bridge visible before widening into replay shortcuts, the next-step matrix, replay route, or the safe-route helper.'
if ($InputPath -and @($InputPath).Count -gt 0) {
    $recommendedHelperKey = 'attached_bundle_first'
    $recommendedHelperReason = 'Explicit input paths are already pinned, so the fastest correct next step is the attached bundle-first helper before reopening the broader Google-only wrappers.'
} elseif (-not [string]::IsNullOrWhiteSpace($SummaryPath)) {
    $recommendedHelperKey = 'contextual_flow'
    $recommendedHelperReason = 'A saved SummaryPath is already available, so open the context-preserving helper next and keep the current replay state aligned while you choose between replay shortcuts, replay route, safe-route wrappers, or the later trace and attached-page branches.'
} elseif (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
    $recommendedHelperKey = 'contextual_flow'
    $recommendedHelperReason = 'A non-default RepoRoot is already in play, so open the context-preserving helper next and keep that checkout aligned while you choose between replay shortcuts, replay route, safe-route wrappers, or the later trace and attached-page branches.'
}

$matrix = @(
    [ordered]@{
        start_point = 'show_headed_validation_suites.ps1 -SuiteName google-recommended'
        default_next_helper = 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        use_when = 'Start from the top-level suite catalog and want the shorter shortcut-first bridge back into issue #3 before deciding whether to widen into the suite-catalog bridge, next-step matrix, replay-route, or safe-route branches.'
    }
    [ordered]@{
        start_point = 'show_headed_validation_suites.ps1 -ChangeArea google-input'
        default_next_helper = 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        use_when = 'You already know the work stays inside issue #3 and want the shorter top-level bridge before deciding whether to widen back into the suite-catalog bridge, next-step matrix, replay-route, bundle-first, or safe-route branches.'
    }
    [ordered]@{
        start_point = 'show_headed_validation_suites.ps1 -ChangeArea attached-html'
        default_next_helper = 'show_google_issue3_suite_router_attached_html_quickstart.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        use_when = 'The next replay is already narrowed to attached-page compatibility follow-up, and you want the shorter suite-router attached-page quickstart visible immediately before deciding whether to widen into the broader attached-page flow helper, the top-level attached-page quickstart, the top-level attached-page bridge, replay shortcuts, the next-step matrix, the pinned bundle-first path, or the safe-route helper chain.'
    }
    [ordered]@{
        start_point = 'show_headed_validation_suites.ps1 -ChangeArea google-attached-html'
        default_next_helper = 'show_google_issue3_google_attached_html_entrypoint.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        use_when = 'The replay is already narrowed to the issue-specific Google-shaped attached-page route and you want the dedicated surface check plus Google attached-html flow helper visible before deciding whether to narrow into the shortcut-first bridge, replay shortcuts, the next-step matrix, the pinned bundle-first path, or the safe-route helper chain.'
    }
    [ordered]@{
        start_point = 'show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle'
        default_next_helper = 'show_google_issue3_attached_bundle_first_entrypoint.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        use_when = 'The current saved or attached inputs are still the pinned three-page compatibility bundle and you want the one-command bundle-first helper to keep that locked route plus the safe-route return visible before the broader Google-only wrappers.'
    }
    [ordered]@{
        start_point = 'show_google_issue3_suite_router_handoff.ps1'
        default_next_helper = 'show_google_issue3_replay_shortcuts.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        use_when = 'The higher-level issue #3 router state is already confirmed and you want the narrower shortcut map next before deciding whether to widen back into replay_route, stay pinned to attached_bundle_first, or reopen the safe-route helper.'
    }
    [ordered]@{
        start_point = 'show_google_issue3_replay_route.ps1'
        default_next_helper = 'show_google_issue3_replay_route_shortcut_entrypoint.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        use_when = 'You want the smaller replay-route bridge first so the attached-page shortcut, replay-to-Windows bridge, next-step matrix, contextual flow, bundle-first branch, and safe-route entrypoints stay visible before widening again.'
    }
    [ordered]@{
        start_point = 'saved summary or current pinned context already in play'
        default_next_helper = 'show_google_issue3_contextual_flow.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        use_when = 'RepoRoot, SummaryPath, or fixed InputPath values already matter and you want the next helper surface to keep that context aligned before choosing between the recommended runner, replay shortcuts, live trace, attached bundle, or later-stage follow-up commands.'
    }
    [ordered]@{
        start_point = 'context-preserving late-stage handoff'
        default_next_helper = 'show_google_submit_timing_validation_flow.ps1'
        command = Format-HelperCommand -ScriptName 'show_google_submit_timing_validation_flow.ps1' -Arguments $submitTimingFlowArguments
        use_when = 'The higher-level replay route is already settled and you want to jump straight into the bounded submit-timing slice with the same repo root, browser path, host, and issue #3 input context carried through.'
    }
    [ordered]@{
        start_point = 'wrapper-emitted runner state'
        default_next_helper = 'show_google_issue3_runner_patch_next_step.ps1'
        command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_patch_next_step.ps1' -Arguments ([ordered]@{
            SummaryPath = $SummaryPath
            State = $runnerPatchStatePlaceholder
        }) -RepoRootOverride $RepoRoot
        use_when = 'The current replay already has a saved summary path plus one of the three runner-patch states and you want the shortest exact next-step map.'
    }
)

$helper = [ordered]@{
    issue = 'Google issue #3 suite-router next steps'
    purpose = 'Print the fastest correct issue #3 helper after the top-level headed validation router, while preserving repo-root, saved-summary, attached-bundle, and later-stage flow context when it already exists, and keeping the broader attached-page route plus the narrower Google-shaped attached-page route visible when the replay has already moved into attached localhost follow-up.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    browser_exe = $BrowserExe
    host = $Host
    submit_timing_input_text = $SubmitTimingInputText
    shared_input_text = $SharedInputText
    trace_input_text = $TraceInputText
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    recommended_helper_key = $recommendedHelperKey
    recommended_helper_reason = $recommendedHelperReason
    recommended_helper_command = switch ($recommendedHelperKey) {
        'attached_bundle_first' { Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments }
        'contextual_flow' { Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments }
        'replay_shortcuts' { Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments }
        'replay_route' { Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments }
        'suite_router_shortcut_entrypoint' { Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments }
        default { Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleArguments }
    }
    suite_router_commands = [ordered]@{
        suite_name_google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        change_area_google_input = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        change_area_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        change_area_google_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        change_area_attached_bundle = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        suite_router_surface_check = $suiteRouterSurfaceCheckCommand
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand
        google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        suite_router_surface_check = $suiteRouterSurfaceCheckCommand
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_handoff = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        attached_bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleFlowArguments
        attached_bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleFlowArguments -Switches @('Wait')
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $safeRouteArguments
        fresh_safe_route_replay = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments $sharedArguments
        reuse_current_outputs = Format-HelperCommand -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments $sharedArguments
        runner_patch_next_step = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_patch_next_step.ps1' -Arguments ([ordered]@{
            SummaryPath = $SummaryPath
            State = $runnerPatchStatePlaceholder
        }) -RepoRootOverride $RepoRoot
    }
    later_stage_flow_commands = [ordered]@{
        submit_timing = Format-HelperCommand -ScriptName 'show_google_submit_timing_validation_flow.ps1' -Arguments $submitTimingFlowArguments
        shared_enter_order = Format-HelperCommand -ScriptName 'show_google_shared_enter_order_validation_flow.ps1' -Arguments $sharedEnterOrderFlowArguments
        live_trace = Format-HelperCommand -ScriptName 'show_google_trace_validation_flow.ps1' -Arguments $liveTraceFlowArguments
    }
    suite_router_matrix = $matrix
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    discovery_handoff_note_path = 'docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    replay_route_shortcut_bridge_note_path = 'docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    validation_router_attached_html_quickstart_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    google_attached_html_entrypoint_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    decision_table_note_path = 'docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md'
    windows_runbook_path = 'docs/WINDOWS_FULL_USE.md'
    notes = @(
        'Use this helper when issue #3 work starts from the higher-level Windows validation router and you want the next helper chosen quickly without reopening the longer chain notes first.',
        'When RepoRoot is supplied, the top-level suite-router, attached-html flow, and Google attached-html flow commands preserve that same LIGHTPANDA_REPO_ROOT context instead of falling back to the default checkout path.',
        'When SummaryPath is supplied, the replay-route, replay-shortcuts, contextual-flow, safe-route entrypoints, fresh safe-route replay, reuse-current-outputs, and runner next-step helpers keep that same saved summary context attached.',
        'When InputPath is supplied, the suite-router handoff, replay-route, replay-shortcuts, contextual-flow, attached-bundle-first, safe-route entrypoints, attached-html flow, and Google attached-html flow helpers keep the current fixed bundle inputs pinned instead of relying on auto-discovery.',
        'Use suite_router_surface_check before trusting the printed matrix when you want the helper surface to fail fast on missing route notes, checker scripts, or attached-page companion helpers.',
        'Use suite_router_shortcut_entrypoint as the default next helper after the higher-level suite router when you want the shorter issue #3 bridge to decide between replay_shortcuts, contextual_flow, or attached_bundle_first without reopening the wider compact helpers first.',
        'Use replay_shortcuts after the shortcut-first entrypoint, suite_router_handoff, or replay_route_shortcut when the route is already known to be issue #3 and no saved summary, repo-root override, or pinned bundle inputs need to stay visible first.',
        'Use contextual_flow as the default next helper whenever RepoRoot or SummaryPath is already in play and no pinned bundle inputs take precedence, so the next surface keeps that context aligned while you choose between the recommended runner, replay shortcuts, live trace, attached bundle, or later-stage follow-up commands.',
        'Use replay_route when you want the slightly broader attached-bundle branch, safe-route bridge, and runner-state helper printed together after the shortcut map is already visible or when you deliberately want to widen back out from suite_router_handoff.',
        'Use attached_bundle_first when the saved or attached pages are still the known three-page compatibility set and you want that route exercised before reopening the broader Google-only safe-route ladder.',
        'Use suite_router_handoff only when you explicitly want the wider compact bridge that keeps the top-level suite-router entrypoints beside the current replay helpers before narrowing further.',
        'Use safe_route_entrypoints after the suite-router work is already out of the way and you want the current wrapper-heavy issue #3 commands, notes, and next-state helper surfaced in one place.',
        'Use the later_stage_flow_commands block when the higher-level replay route is already chosen and the next Windows run should jump straight into the bounded submit-timing, shared Enter-order, or live-trace helpers without reconstructing repo-root, browser, host, or issue #3 input context by hand.',
        'Use change_area_attached_html when the next replay is already narrowed to the attached HTML compatibility path and you want that top-level route printed beside the dedicated attached-page bridge before you decide whether to stay pinned to the bundle-first branch or widen back into the broader Google-only guidance.',
        'Use change_area_google_attached_html when the next replay is already narrowed to the issue-specific Google-shaped attached-page route and you want that top-level branch printed beside the dedicated surface check, flow helper, and Google attached-html entrypoint before deciding between the shortcut-first bridge, replay shortcuts, the next-step matrix, the pinned bundle-first branch, or the safe-route helper chain.',
        'Use attached_html_flow when the top-level attached HTML route is already visible but you want the broader attached-page helper surface printed before narrowing into the shorter attached quickstart, the top-level attached-page bridge, replay shortcuts, or the pinned bundle-first branch.',
        'Use google_attached_html_surface_check when the replay is already inside the issue-specific Google-shaped attached-page route and you want the fail-fast surface reprinted before the dedicated flow helper or the Google attached-html entrypoint.',
        'Use google_attached_html_flow when the current attached-page set already includes a Google-like page and you want the dedicated Google-shaped attached-page helper surface printed before narrowing into the Google attached-html entrypoint, the shortcut-first bridge, replay shortcuts, or the pinned bundle-first branch.',
        'Use suite_router_attached_html_quickstart as the default next helper after change_area_attached_html when the replay is already narrowed to attached-page compatibility follow-up and no pinned bundle inputs, saved summary, or repo-root override need to take precedence first, because it keeps the shorter attached-page bridge visible before you decide whether to widen into the top-level attached-page quickstart, the top-level attached-page bridge, replay shortcuts, the next-step matrix, the pinned bundle-first branch, or the safe-route helper chain.',
        'Use google_attached_html_entrypoint as the default next helper after change_area_google_attached_html when the replay is already narrowed to the issue-specific Google-shaped attached-page route and no pinned bundle inputs, saved summary, or repo-root override need to take precedence first, because it keeps the issue-specific attached-page bridge visible before you decide whether to widen into the dedicated flow helper, the shortcut-first bridge, replay shortcuts, the next-step matrix, the pinned bundle-first branch, or the safe-route helper chain.',
        'Keep discovery_handoff_note_path open for the shortest prose bridge from the top-level suite catalog into the newer suite-router handoff and replay-route helpers, quickstart_note_path for the shortest replay note, suite_router_attached_html_quickstart_note_path for the shorter suite-router attached-page bridge, top_level_attached_html_quickstart_note_path, top_level_attached_html_bridge_note_path, and top_level_attached_html_catalog_quickstart_note_path for the compact, broader, and catalog-flavored top-level attached-page companion notes, validation_router_attached_html_quickstart_note_path, suite_catalog_attached_html_bridge_note_path, and windows_replay_attached_html_quickstart_note_path when the replay needs the wider validation-router, suite-catalog, or Windows replay attached-page companions, suite_router_bridge_note_path for the narrower prose bridge, replay_route_shortcut_bridge_note_path for the shorter replay-route companion note, google_attached_html_entrypoint_note_path and google_attached_html_validation_flow_note_path for the narrower Google-shaped attached-page route, validation_chain_note_path for wrapper precedence and context-preserving lane handoffs, decision_table_note_path when the replay lands on ready-for-runner-patch, already-direct, or runner-already-wired-regenerate-outputs, and windows_runbook_path when the next replay should widen back into the broader attached or saved localhost HTML follow-up.'
    )
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 suite-router next steps'
Write-Host ''
if ($helper.repo_root) {
    Write-Host (("Repo root:   {0}") -f $helper.repo_root)
}
if ($helper.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($helper.summary_path)"))
}
if ($helper.browser_exe) {
    Write-Host (("Browser exe: {0}") -f $helper.browser_exe)
}
Write-Host (("Host:        {0}") -f $helper.host)
Write-Host (("Submit text: {0}") -f $helper.submit_timing_input_text)
Write-Host (("Shared text: {0}") -f $helper.shared_input_text)
Write-Host (("Trace text:  {0}") -f $helper.trace_input_text)
if ($helper.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $helper.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended helper: {0}") -f $helper.recommended_helper_command)
Write-Host (("Why:                {0}") -f $helper.recommended_helper_reason)
Write-Host ''
Write-Host 'Read-first suite-router commands:'
Write-Host (("  Suite name:               {0}") -f $helper.suite_router_commands.suite_name_google_recommended)
Write-Host (("  Change area:              {0}") -f $helper.suite_router_commands.change_area_google_input)
Write-Host (("  Attached HTML:            {0}") -f $helper.suite_router_commands.change_area_attached_html)
Write-Host (("  Google attached HTML:     {0}") -f $helper.suite_router_commands.change_area_google_attached_html)
Write-Host (("  Bundle change area:       {0}") -f $helper.suite_router_commands.change_area_attached_bundle)
Write-Host (("  Suite-router surface:     {0}") -f $helper.suite_router_commands.suite_router_surface_check)
Write-Host (("  Attached flow helper:     {0}") -f $helper.suite_router_commands.attached_html_flow)
Write-Host (("  Google attached surface:  {0}") -f $helper.suite_router_commands.google_attached_html_surface_check)
Write-Host (("  Google attached flow:     {0}") -f $helper.suite_router_commands.google_attached_html_flow)
Write-Host (("  Google flow helper:       {0}") -f $helper.suite_router_commands.google_flow)
Write-Host ''
Write-Host 'Next-step matrix:'
foreach ($entry in $helper.suite_router_matrix) {
    Write-Host (("- Start: {0}") -f $entry.start_point)
    Write-Host (("  Next helper: {0}") -f $entry.default_next_helper)
    Write-Host (("  Command:     {0}") -f $entry.command)
    Write-Host (("  Use when:    {0}") -f $entry.use_when)
    Write-Host ''
}
Write-Host 'Key helper commands:'
Write-Host (("  Surface check:          {0}") -f $helper.helper_commands.suite_router_surface_check)
Write-Host (("  Shortcut entrypoint:    {0}") -f $helper.helper_commands.suite_router_shortcut_entrypoint)
Write-Host (("  Attached quickstart:    {0}") -f $helper.helper_commands.suite_router_attached_html_quickstart)
Write-Host (("  Google attached entry:  {0}") -f $helper.helper_commands.google_attached_html_entrypoint)
Write-Host (("  Suite-router handoff:   {0}") -f $helper.helper_commands.suite_router_handoff)
Write-Host (("  Replay route:           {0}") -f $helper.helper_commands.replay_route)
Write-Host (("  Replay-route shortcut:  {0}") -f $helper.helper_commands.replay_route_shortcut)
Write-Host (("  Replay shortcuts:       {0}") -f $helper.helper_commands.replay_shortcuts)
Write-Host (("  Contextual flow:        {0}") -f $helper.helper_commands.contextual_flow)
Write-Host (("  Bundle-first helper:    {0}") -f $helper.helper_commands.attached_bundle_first)
Write-Host (("  Bundle flow helper:     {0}") -f $helper.helper_commands.attached_bundle_flow)
Write-Host (("  Bundle runner:          {0}") -f $helper.helper_commands.attached_bundle_runner)
Write-Host (("  Safe route entrypoints: {0}") -f $helper.helper_commands.safe_route_entrypoints)
Write-Host (("  Fresh safe replay:      {0}") -f $helper.helper_commands.fresh_safe_route_replay)
Write-Host (("  Reuse current outputs:  {0}") -f $helper.helper_commands.reuse_current_outputs)
Write-Host (("  Runner next-step helper:{0}") -f (' ' + $helper.helper_commands.runner_patch_next_step))
Write-Host ''
Write-Host 'Context-preserving later-stage flows:'
Write-Host (("  Submit timing:      {0}") -f $helper.later_stage_flow_commands.submit_timing)
Write-Host (("  Shared enter order: {0}") -f $helper.later_stage_flow_commands.shared_enter_order)
Write-Host (("  Live trace:         {0}") -f $helper.later_stage_flow_commands.live_trace)
Write-Host ''
Write-Host (("Quickstart note:              {0}") -f $helper.quickstart_note_path)
Write-Host (("Replay-discovery note:       {0}") -f $helper.discovery_handoff_note_path)
Write-Host (("Suite-router bridge note:    {0}") -f $helper.suite_router_bridge_note_path)
Write-Host (("Replay-route shortcut note:  {0}") -f $helper.replay_route_shortcut_bridge_note_path)
Write-Host (("Suite-router attached note:  {0}") -f $helper.suite_router_attached_html_quickstart_note_path)
Write-Host (("Top-level attached quick:    {0}") -f $helper.top_level_attached_html_quickstart_note_path)
Write-Host (("Top-level attached note:     {0}") -f $helper.top_level_attached_html_bridge_note_path)
Write-Host (("Top-level attached catalog:  {0}") -f $helper.top_level_attached_html_catalog_quickstart_note_path)
Write-Host (("Suite-catalog attached note: {0}") -f $helper.suite_catalog_attached_html_bridge_note_path)
Write-Host (("Windows replay attached:     {0}") -f $helper.windows_replay_attached_html_quickstart_note_path)
Write-Host (("Validation-router note:      {0}") -f $helper.validation_router_attached_html_quickstart_note_path)
Write-Host (("Google attached entrypoint:  {0}") -f $helper.google_attached_html_entrypoint_note_path)
Write-Host (("Google attached flow note:   {0}") -f $helper.google_attached_html_validation_flow_note_path)
Write-Host (("Validation chain note:       {0}") -f $helper.validation_chain_note_path)
Write-Host (("Decision table:              {0}") -f $helper.decision_table_note_path)
Write-Host (("Windows runbook:             {0}") -f $helper.windows_runbook_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}