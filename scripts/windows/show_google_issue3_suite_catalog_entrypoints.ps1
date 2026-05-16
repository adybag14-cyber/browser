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
        [string[]]$Switches = @(),
        [System.Collections.Generic.List[string]]$Arguments
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
            if ($entry.Value -is [System.Array]) {
                Add-SharedPathArrayArgument -Arguments $fallbackArguments -Name $entry.Key -Values $entry.Value
            } else {
                Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $entry.Value
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

$emptyArguments = [System.Collections.Generic.List[string]]::new()

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$googleAttachedHtmlFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $googleAttachedHtmlFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $googleAttachedHtmlFlowArguments -Name InputPath -Values $InputPath

$googleFlowCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $RepoRoot
$contextualFlowCommand = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
$suiteCatalogSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1' -RepoRootOverride $RepoRoot
$windowsReplayAttachedHtmlSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -RepoRootOverride $RepoRoot
$windowsFullUseAttachedHtmlRouteSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -RepoRootOverride $RepoRoot
$windowsReplayAttachedHtmlQuickstartCommand = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments
$windowsFullUseAttachedHtmlRouteCommand = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $bundleArguments
$windowsFullUseValidationRouterAttachedHtmlBridgeCommand = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $bundleArguments

$entrypoints = [ordered]@{
    issue = 'Google issue #3 suite catalog entrypoints'
    purpose = 'Keep the exact top-level show_headed_validation_suites entrypoints, the suite-catalog surface check, the broader Windows full-use attached-page route, its route-level surface check, the Windows-to-validation-router bridge, the Windows full-use attached-page catalog quickstart, the Windows replay attached-html surface check, the Windows replay attached-html quickstart, the broader attached-page flow helper, the dedicated Google attached-page flow helper, the validation-router attached-page quickstart, the attached-page change-area quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, the suite-router quickstarts, the top-level shortcut and top-level attached-page bridges, the current Google flow helper, the issue-specific attached-page helpers, the compact next-step matrix, the context-preserving issue #3 replay flow, the compact attached-bundle suite surface, and the current safe-route replay helpers on one compact command surface before the route narrows into replay-route, bundle-first, or the wrapper-heavy safe-route helpers.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    windows_full_use_validation_router_attached_html_bridge_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md'
    windows_full_use_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    validation_router_attached_html_quickstart_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    attached_html_change_area_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    suite_catalog_top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    attached_html_target_bundle_suite_surface_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    suite_catalog_commands = [ordered]@{
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
        suite_catalog_surface_check = $suiteCatalogSurfaceCheckCommand
        windows_full_use_attached_html_route = $windowsFullUseAttachedHtmlRouteCommand
        windows_full_use_attached_html_route_surface_check = $windowsFullUseAttachedHtmlRouteSurfaceCheckCommand
        windows_full_use_validation_router_attached_html_bridge = $windowsFullUseValidationRouterAttachedHtmlBridgeCommand
        windows_full_use_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        windows_replay_attached_html_surface_check = $windowsReplayAttachedHtmlSurfaceCheckCommand
        windows_replay_attached_html_quickstart = $windowsReplayAttachedHtmlQuickstartCommand
        validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $bundleArguments
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_validation_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments
        suite_catalog_top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_quickstart.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        top_level_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        google_flow = $googleFlowCommand
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = $contextualFlowCommand
        suite_router_handoff = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
        fresh_safe_route_replay = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments $sharedArguments
        reuse_current_outputs = Format-HelperCommand -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments $sharedArguments
    }
    bridge_sequence = [ordered]@{
        suite_catalog_surface_check = $suiteCatalogSurfaceCheckCommand
        google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        google_input_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $bundleArguments
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html_validation_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments
        windows_replay_attached_html_surface_check = $windowsReplayAttachedHtmlSurfaceCheckCommand
        windows_full_use_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        windows_replay_attached_html_quickstart = $windowsReplayAttachedHtmlQuickstartCommand
        validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        suite_catalog_top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_quickstart.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        top_level_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        google_flow = $googleFlowCommand
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        suite_router_handoff = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
    }
    notes = @(
        'Start with google_recommended when you want the broader localhost-first issue #3 runner surfaced from the suite catalog before choosing a narrower branch.',
        'Use suite_catalog_surface_check right after the suite-catalog guide when helper names, delegated scripts, or note paths may have drifted and you want the route to fail fast before the narrower replay-side chain opens.',
        'Use windows_full_use_attached_html_route, its route-level surface check, and windows_full_use_validation_router_attached_html_bridge when docs/WINDOWS_FULL_USE.md already made attached localhost follow-up the next obvious branch and you want that Windows-first route visible before the suite-catalog surface narrows again.',
        'Use attached_html_change_area_quickstart when the replay already came through the top-level attached-html change area and you want the compact issue #3 attached-page follow-up surface printed before you fall back to the validation-router quickstart, the Windows replay attached-html quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, or the suite-catalog attached-page bridge.',
        'Use attached_html_flow when the broader attached-page localhost helper still needs to stay visible from the same change-area branch before you commit to the dedicated Google attached-page flow helper, the validation-router attached-page quickstart, or the narrower suite-catalog ladders.',
        'Use google_attached_html_validation_flow when the broader Google-shaped attached-page surface checker, asset-closure route, and helper output should stay visible before the narrower validation-router quickstart, issue-specific attached-page bridge, or shortcut-first branch takes over.',
        'Use windows_replay_attached_html_quickstart as the default replay-side bridge when the next rerun already came through the Windows replay attached localhost branch and you want that narrower route reprinted before widening back into the Windows full-use attached-html catalog quickstart, the validation-router attached-page quickstart, or the suite-catalog ladders.',
        'Use suite_catalog_top_level_attached_html_catalog_quickstart when the suite-catalog surface is already open and you want the replay-side attached-html ladder plus the top-level attached-page catalog quickstart visible together before the route narrows into the suite-catalog attached-page bridge, the attached-page shortcut, or the replay-shortcut helpers.',
        'Use suite_router_attached_html_quickstart when the route is already narrowed to attached localhost follow-up from the top-level suite router and you want the shortest suite-router-side attached-page bridge before choosing between the broader top-level notes, the issue-specific attached-page bridge, replay shortcuts, or the bundle-first route.',
        'Use attached_bundle_suite_surface when the replay is already close to the known three-page compatibility bundle and you want the compact bundle-specific re-entry helper visible before the route narrows into the bundle-first branch or the delegated bundle runner.',
        'Use replay_shortcuts as the default next helper after the top-level suite catalog when no pinned bundle inputs, saved summary, or non-default repo root need to take precedence, because it keeps the newer shortcut-first issue #3 bridge visible before you decide whether to reopen the attached-page ladders, the compact attached-bundle suite surface, or the bundle-first branch.',
        'Use contextual_flow when RepoRoot, SummaryPath, or fixed InputPath values already matter and you want the next helper surface to keep that context aligned while you choose between the attached-page ladders, replay shortcuts, replay route, the compact attached-bundle suite surface, the bundle-first branch, or the safe-route helpers.',
        'Keep the Windows replay attached-html quickstart note, the Windows full-use attached-html route note, the validation-router attached-page quickstart note, the attached-page change-area quickstart note, the dedicated Google attached-page validation-flow note, the suite-catalog top-level attached-page catalog quickstart note, the suite-catalog guide, the top-level attached-page bridge, the attached-bundle suite-surface note, and the validation-chain notes nearby when you want the written route beside these commands.'
    )
}

$entrypoints.recommended_next_key = if ($entrypoints.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($entrypoints.repo_root) -or -not [string]::IsNullOrWhiteSpace($entrypoints.summary_path)) {
    'contextual_flow'
} else {
    'replay_shortcuts'
}
$entrypoints.recommended_next_command = switch ($entrypoints.recommended_next_key) {
    'attached_bundle_first' { $entrypoints.helper_commands.attached_bundle_first }
    'contextual_flow' { $entrypoints.helper_commands.contextual_flow }
    default { $entrypoints.helper_commands.replay_shortcuts }
}
$entrypoints.recommended_next_reason = if ($entrypoints.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle and keep the compact attached-bundle suite surface nearby before widening back into the broader issue #3 helper chain.'
} elseif ($entrypoints.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so open the context-preserving helper next and keep that replay state aligned before choosing between the Windows full-use attached-html route, the route-level surface check, the Windows-to-validation-router bridge, the Windows full-use attached-html catalog quickstart, the Windows replay attached-html quickstart, the attached-page change-area quickstart, the broader attached-page flow helper, the dedicated Google attached-page flow helper, the validation-router attached-page quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, the suite-router attached-page quickstart, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the top-level shortcut bridge, the top-level attached-page bridge, the issue-specific attached-page entrypoint, replay shortcuts, the next-step matrix, contextual flow, replay route, the compact attached-bundle suite surface, attached bundle, or the safe-route helpers.'
} else {
    'No pinned bundle inputs, non-default repo root, or saved summary are in play yet, so jump straight from the suite catalog into replay shortcuts before widening back into the Windows full-use attached-html route, the route-level surface check, the Windows-to-validation-router bridge, the Windows full-use attached-html catalog quickstart, the Windows replay attached-html quickstart, the attached-page change-area quickstart, the broader attached-page flow helper, the dedicated Google attached-page flow helper, the validation-router attached-page quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, the suite-router attached-page quickstart, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the top-level attached-page bridge, the issue-specific attached-page entrypoint, the next-step matrix, contextual flow, the compact attached-bundle suite surface, or the bundle-first branch.'
}

if ($Json) {
    $entrypoints | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 suite catalog entrypoints'
Write-Host ''
if ($entrypoints.repo_root) {
    Write-Host (("Repo root:   {0}") -f $entrypoints.repo_root)
}
if ($entrypoints.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($entrypoints.summary_path)"))
}
if ($entrypoints.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $entrypoints.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $entrypoints.recommended_next_command)
Write-Host (("Why:                    {0}") -f $entrypoints.recommended_next_reason)
Write-Host ''
Write-Host 'Read-first bridge:'
Write-Host (("  1. Suite-catalog surface check:      {0}") -f $entrypoints.bridge_sequence.suite_catalog_surface_check)
Write-Host (("  2. Google recommended:               {0}") -f $entrypoints.bridge_sequence.google_recommended)
Write-Host (("  3. Google input:                     {0}") -f $entrypoints.bridge_sequence.google_input_change_area)
Write-Host (("  4. Attached HTML:                    {0}") -f $entrypoints.bridge_sequence.attached_html_change_area)
Write-Host (("  5. Attached HTML quickstart:         {0}") -f $entrypoints.bridge_sequence.attached_html_change_area_quickstart)
Write-Host (("  6. Attached HTML flow:               {0}") -f $entrypoints.bridge_sequence.attached_html_flow)
Write-Host (("  7. Google attached HTML:             {0}") -f $entrypoints.bridge_sequence.google_attached_html_change_area)
Write-Host (("  8. Google attached flow:             {0}") -f $entrypoints.bridge_sequence.google_attached_html_validation_flow)
Write-Host (("  9. Replay surface check:             {0}") -f $entrypoints.bridge_sequence.windows_replay_attached_html_surface_check)
Write-Host ((" 10. Windows catalog quickstart:       {0}") -f $entrypoints.bridge_sequence.windows_full_use_attached_html_catalog_quickstart)
Write-Host ((" 11. Replay attached quickstart:       {0}") -f $entrypoints.bridge_sequence.windows_replay_attached_html_quickstart)
Write-Host ((" 12. Validation-router quick:          {0}") -f $entrypoints.bridge_sequence.validation_router_attached_html_quickstart)
Write-Host ((" 13. Catalog top-level quickstart:     {0}") -f $entrypoints.bridge_sequence.suite_catalog_top_level_attached_html_catalog_quickstart)
Write-Host ((" 14. Catalog attached bridge:          {0}") -f $entrypoints.bridge_sequence.suite_catalog_attached_html_entrypoint)
Write-Host ((" 15. Router quickstart:                {0}") -f $entrypoints.bridge_sequence.suite_router_quickstart)
Write-Host ((" 16. Router attached quickstart:       {0}") -f $entrypoints.bridge_sequence.suite_router_attached_html_quickstart)
Write-Host ((" 17. Top-level attached quickstart:    {0}") -f $entrypoints.bridge_sequence.top_level_attached_html_quickstart)
Write-Host ((" 18. Top-level catalog quickstart:     {0}") -f $entrypoints.bridge_sequence.top_level_attached_html_catalog_quickstart)
Write-Host ((" 19. Top-level shortcut:               {0}") -f $entrypoints.bridge_sequence.top_level_shortcut_entrypoint)
Write-Host ((" 20. Top-level attached bridge:        {0}") -f $entrypoints.bridge_sequence.top_level_attached_html_entrypoint)
Write-Host ((" 21. Google flow:                      {0}") -f $entrypoints.bridge_sequence.google_flow)
Write-Host ((" 22. Google attached bridge:           {0}") -f $entrypoints.bridge_sequence.google_attached_html_entrypoint)
Write-Host ((" 23. Attached shortcut:                {0}") -f $entrypoints.bridge_sequence.attached_html_shortcut)
Write-Host ((" 24. Replay shortcuts:                 {0}") -f $entrypoints.bridge_sequence.replay_shortcuts)
Write-Host ((" 25. Next-step matrix:                 {0}") -f $entrypoints.bridge_sequence.suite_router_next_steps)
Write-Host ((" 26. Contextual flow:                  {0}") -f $entrypoints.bridge_sequence.contextual_flow)
Write-Host ((" 27. Suite handoff:                    {0}") -f $entrypoints.bridge_sequence.suite_router_handoff)
Write-Host ((" 28. Replay route:                     {0}") -f $entrypoints.bridge_sequence.replay_route)
Write-Host ((" 29. Bundle suite surface:             {0}") -f $entrypoints.bridge_sequence.attached_bundle_suite_surface)
Write-Host ((" 30. Bundle-first route:               {0}") -f $entrypoints.bridge_sequence.attached_bundle_first)
Write-Host ''
Write-Host 'Windows-first re-entry:'
Write-Host (("  Windows route:             {0}") -f $entrypoints.helper_commands.windows_full_use_attached_html_route)
Write-Host (("  Route surface check:       {0}") -f $entrypoints.helper_commands.windows_full_use_attached_html_route_surface_check)
Write-Host (("  Validation bridge:         {0}") -f $entrypoints.helper_commands.windows_full_use_validation_router_attached_html_bridge)
Write-Host (("  Catalog quickstart:        {0}") -f $entrypoints.helper_commands.windows_full_use_attached_html_catalog_quickstart)
Write-Host ''
Write-Host 'Top-level suite catalog entrypoints:'
Write-Host (("  Google recommended:   {0}") -f $entrypoints.suite_catalog_commands.google_recommended)
Write-Host (("  Google input:         {0}") -f $entrypoints.suite_catalog_commands.google_input_change_area)
Write-Host (("  Attached HTML:        {0}") -f $entrypoints.suite_catalog_commands.attached_html_change_area)
Write-Host (("  Google attached HTML: {0}") -f $entrypoints.suite_catalog_commands.google_attached_html_change_area)
Write-Host (("  Attached bundle:      {0}") -f $entrypoints.suite_catalog_commands.attached_bundle_change_area)
Write-Host ''
Write-Host 'Issue #3 replay helpers:'
Write-Host (("  Suite-catalog surface:     {0}") -f $entrypoints.helper_commands.suite_catalog_surface_check)
Write-Host (("  Replay surface check:      {0}") -f $entrypoints.helper_commands.windows_replay_attached_html_surface_check)
Write-Host (("  Replay attached quick:     {0}") -f $entrypoints.helper_commands.windows_replay_attached_html_quickstart)
Write-Host (("  Validation-router quick:   {0}") -f $entrypoints.helper_commands.validation_router_attached_html_quickstart)
Write-Host (("  Attached HTML quick:       {0}") -f $entrypoints.helper_commands.attached_html_change_area_quickstart)
Write-Host (("  Attached HTML flow:        {0}") -f $entrypoints.helper_commands.attached_html_flow)
Write-Host (("  Google attached flow:      {0}") -f $entrypoints.helper_commands.google_attached_html_validation_flow)
Write-Host (("  Catalog top-level quick:   {0}") -f $entrypoints.helper_commands.suite_catalog_top_level_attached_html_catalog_quickstart)
Write-Host (("  Catalog attached bridge:   {0}") -f $entrypoints.helper_commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  Router quickstart:         {0}") -f $entrypoints.helper_commands.suite_router_quickstart)
Write-Host (("  Router attached quick:     {0}") -f $entrypoints.helper_commands.suite_router_attached_html_quickstart)
Write-Host (("  Top-level quickstart:      {0}") -f $entrypoints.helper_commands.top_level_attached_html_quickstart)
Write-Host (("  Top-level catalog quick:   {0}") -f $entrypoints.helper_commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  Top-level shortcut:        {0}") -f $entrypoints.helper_commands.top_level_shortcut_entrypoint)
Write-Host (("  Top-level attached:        {0}") -f $entrypoints.helper_commands.top_level_attached_html_entrypoint)
Write-Host (("  Google flow:               {0}") -f $entrypoints.helper_commands.google_flow)
Write-Host (("  Google attached bridge:    {0}") -f $entrypoints.helper_commands.google_attached_html_entrypoint)
Write-Host (("  Attached shortcut:         {0}") -f $entrypoints.helper_commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:          {0}") -f $entrypoints.helper_commands.replay_shortcuts)
Write-Host (("  Next-step matrix:          {0}") -f $entrypoints.helper_commands.suite_router_next_steps)
Write-Host (("  Contextual flow:           {0}") -f $entrypoints.helper_commands.contextual_flow)
Write-Host (("  Replay route:              {0}") -f $entrypoints.helper_commands.replay_route)
Write-Host (("  Bundle suite surface:      {0}") -f $entrypoints.helper_commands.attached_bundle_suite_surface)
Write-Host (("  Suite handoff:             {0}") -f $entrypoints.helper_commands.suite_router_handoff)
Write-Host (("  Bundle first:              {0}") -f $entrypoints.helper_commands.attached_bundle_first)
Write-Host (("  Safe-route map:            {0}") -f $entrypoints.helper_commands.safe_route_entrypoints)
Write-Host (("  Fresh safe replay:         {0}") -f $entrypoints.helper_commands.fresh_safe_route_replay)
Write-Host (("  Reuse current output:      {0}") -f $entrypoints.helper_commands.reuse_current_outputs)
Write-Host ''
Write-Host (("Windows replay attached note:        {0}") -f $entrypoints.windows_replay_attached_html_quickstart_note_path)
Write-Host (("Windows full-use route:             {0}") -f $entrypoints.windows_full_use_attached_html_route_note_path)
Write-Host (("Windows validation bridge note:     {0}") -f $entrypoints.windows_full_use_validation_router_attached_html_bridge_note_path)
Write-Host (("Windows full-use catalog note:      {0}") -f $entrypoints.windows_full_use_attached_html_catalog_quickstart_note_path)
Write-Host (("Top-level attached quick note:      {0}") -f $entrypoints.top_level_attached_html_quickstart_note_path)
Write-Host (("Top-level attached catalog note:    {0}") -f $entrypoints.top_level_attached_html_catalog_quickstart_note_path)
Write-Host (("Validation-router quick note:       {0}") -f $entrypoints.validation_router_attached_html_quickstart_note_path)
Write-Host (("Attached HTML quick note:           {0}") -f $entrypoints.attached_html_change_area_quickstart_note_path)
Write-Host (("Google attached flow note:         {0}") -f (' ' + $entrypoints.google_attached_html_validation_flow_note_path))
Write-Host (("Suite-catalog top-level note:       {0}") -f $entrypoints.suite_catalog_top_level_attached_html_catalog_quickstart_note_path)
Write-Host (("Quickstart note:                    {0}") -f $entrypoints.quickstart_note_path)
Write-Host (("Suite-router attached note:         {0}") -f $entrypoints.suite_router_attached_html_quickstart_note_path)
Write-Host (("Suite-router bridge:                {0}") -f $entrypoints.suite_router_bridge_note_path)
Write-Host (("Suite-catalog guide:                {0}") -f $entrypoints.suite_catalog_entrypoint_note_path)
Write-Host (("Top-level attached note:            {0}") -f $entrypoints.top_level_attached_html_bridge_note_path)
Write-Host (("Bundle suite-surface note:          {0}") -f $entrypoints.attached_html_target_bundle_suite_surface_note_path)
Write-Host (("Validation chain:                   {0}") -f $entrypoints.validation_chain_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoints.notes) {
    Write-Host (("- {0}") -f $note)
}