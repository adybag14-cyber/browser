[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
    [string]$BrowserExe,
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
        $command += ((" -{0} '{1}'" -f $entry.Key, $escapedValue))
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

$browserAwareBundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $browserAwareBundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $browserAwareBundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $browserAwareBundleArguments -Name BrowserExe -Value $BrowserExe
Add-SharedPathArrayArgument -Arguments $browserAwareBundleArguments -Name InputPath -Values $InputPath

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}
if ($BrowserExe) {
    $attachedHtmlFlowArguments['BrowserExe'] = $BrowserExe
}

$googleAttachedHtmlFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $googleAttachedHtmlFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $googleAttachedHtmlFlowArguments -Name BrowserExe -Value $BrowserExe
Add-SharedPathArrayArgument -Arguments $googleAttachedHtmlFlowArguments -Name InputPath -Values $InputPath

$attachedHtmlChangeAreaArguments = [ordered]@{
    ChangeArea = 'attached-html'
}
if ($InputPath) {
    $attachedHtmlChangeAreaArguments['InputPath'] = @($InputPath)
}
if ($BrowserExe) {
    $attachedHtmlChangeAreaArguments['BrowserExe'] = $BrowserExe
}

$googleAttachedHtmlChangeAreaArguments = [ordered]@{
    ChangeArea = 'google-attached-html'
}
if ($InputPath) {
    $googleAttachedHtmlChangeAreaArguments['InputPath'] = @($InputPath)
}
if ($BrowserExe) {
    $googleAttachedHtmlChangeAreaArguments['BrowserExe'] = $BrowserExe
}

$attachedBundleChangeAreaArguments = [ordered]@{
    ChangeArea = 'attached-html-target-bundle'
}
if ($InputPath) {
    $attachedBundleChangeAreaArguments['InputPath'] = @($InputPath)
}
if ($BrowserExe) {
    $attachedBundleChangeAreaArguments['BrowserExe'] = $BrowserExe
}

$route = [ordered]@{
    issue = 'Google issue #3 Windows full-use attached HTML route'
    purpose = 'Print the shortest attached-localhost replay route that starts from the broader Windows headed runbook, surfaces the route-level fail-fast checker first, reopens the Windows-to-validation-router attached-html bridge, the Windows-first attached-html catalog fail-fast checker, the Windows-first attached-html catalog step, the replay-side attached-html quickstart, the broader attached-page flow helper, the dedicated Google attached-page flow helper, the validation-router attached-html quickstart, and then narrows through the attached-html change-area quickstart, the compact top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, the compact attached-bundle suite surface plus pinned bundle-reference note, the issue-specific attached-page bridge, and the newer attached-page shortcut chain.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    browser_exe = $BrowserExe
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    top_level_commands = [ordered]@{
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $attachedHtmlChangeAreaArguments -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $googleAttachedHtmlChangeAreaArguments -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $attachedBundleChangeAreaArguments -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        windows_full_use_attached_html_route_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -RepoRootOverride $RepoRoot
        windows_full_use_validation_router_attached_html_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $browserAwareBundleArguments
        windows_full_use_attached_html_catalog_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1' -RepoRootOverride $RepoRoot
        windows_full_use_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments
        suite_router_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_quickstart.ps1' -Arguments $bundleArguments
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $bundleArguments
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments
        validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        suite_catalog_top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $bundleArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
        attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $browserAwareBundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $browserAwareBundleArguments
    }
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    windows_full_use_validation_router_attached_html_bridge_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md'
    windows_full_use_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    attached_html_change_area_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    validation_router_attached_html_quickstart_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
    suite_catalog_attached_html_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    top_level_attached_html_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_catalog_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_catalog_top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    attached_html_target_bundle_suite_surface_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md'
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    notes = @(
        'Use this helper when the next replay starts from the broader Windows headed runbook and is already centered on the attached localhost compatibility pages for issue #3.',
        'Run windows_full_use_attached_html_route_surface_check after branch moves or before trusting this helper from a different checkout, because it fails fast on missing route notes, helper scripts, or downstream attached-page surfaces before the replay narrows again.',
        'Run windows_full_use_attached_html_catalog_surface_check right after the broader Windows-to-validation-router bridge when you want the narrower Windows-first catalog ladder verified before replay drops into it.',
        'Use windows_full_use_validation_router_attached_html_bridge when the broader Windows runbook already narrowed replay to attached localhost follow-up and you want the Windows-to-validation-router bridge reprinted before the route drops back into the shorter attached-page quickstarts.',
        'Use windows_full_use_attached_html_catalog_quickstart right after the Windows-first catalog surface check when you want the Windows-first catalog step kept visible before the replay-side attached-html quickstart and the narrower validation-router and top-level helpers take over.',
        'Use windows_replay_attached_html_quickstart after the Windows-first catalog step when you want the replay-side attached-html ladder visible before the route narrows into the change-area quickstart, the broader attached-page flow helper, the dedicated Google attached-page flow helper, the validation-router quickstart, or the top-level attached-page helpers.',
        'Start with attached_html_change_area when the next replay should stay on the generic attached-page route before choosing the narrower issue-specific helpers.',
        'Follow attached_html_change_area with attached_html_change_area_quickstart when the validation-router bridge already reopened the broader attached-page route and no pinned bundle inputs, saved summary, or repo-root override need to take precedence first.',
        'Use attached_html_flow when you want the broader attached-page localhost helper printed directly from this Windows-first route before choosing between the validation-router quickstart, the compact top-level quickstart, the broader top-level bridge, the suite-catalog-to-top-level catalog quickstart, or the attached-page shortcut chain. Preserve the current repo root here too so non-default checkout replay stays aligned, and keep the same attached-page set when explicit InputPath values are already pinned instead of reopening auto-discovery.',
        'Use google_attached_html_flow when the current replay should keep the narrower Google-shaped attached-page helper visible from this same Windows-first route before dropping into the validation-router quickstart, the compact top-level quickstart, the broader top-level bridge, or the shorter attached-page shortcut chain. Preserve RepoRoot and explicit InputPath context here, but do not reintroduce SummaryPath because show_google_attached_html_validation_flow.ps1 does not accept it.',
        'Start with google_attached_html_change_area when the next replay should still keep the Google-shaped attached-page route visible before narrowing again.',
        'Use suite_router_quickstart when the broader Windows runbook or the top-level validation router already narrowed the replay to issue #3, but not yet all the way to the attached-html branch, and you want the shortest bridge back into the current replay helper stack before deciding whether to widen into the attached-page chain, replay shortcuts, or the safe-route map.',
        'Use windows_full_use_validation_router_attached_html_bridge as the default next helper because it keeps the broader Windows full-use route, the Windows-first catalog surface check, the Windows-first catalog step, the replay-side attached-html quickstart, and the validation-router attached-html quickstart aligned before the route narrows back into the shorter change-area bridge or the compact top-level attached-page quickstarts.',
        'Use validation_router_attached_html_quickstart when you want the broader validation-router attached-html bridge reprinted after the Windows-first route and replay-side quickstart but before the top-level quickstarts take over.',
        'Use top_level_attached_html_quickstart when the route is already ready to stay on the compact top-level attached-page bridge after the validation-router bridge or the change-area quickstart.',
        'Use top_level_attached_html_entrypoint when the route is already clearly inside the issue-specific attached-page branch and you want the broader top-level bridge reprinted after the compact quickstart.',
        'Use top_level_attached_html_catalog_quickstart when you want the compact top-level attached-page quickstart and the suite-catalog-side attached-page bridge kept visible together before the route narrows into the shorter attached-page shortcut, replay shortcuts, contextual flow, or the safe-route map.',
        'Use suite_catalog_top_level_attached_html_catalog_quickstart when you want the replay-side attached-html ladder, the top-level attached-html catalog quickstart, and the suite-catalog-side bridge kept on the same surface before the route narrows again.',
        'Use suite_router_attached_html_quickstart when you want the shorter suite-router-side attached-page bridge after the validation-router bridge, the change-area quickstart, the top-level quickstart, the top-level attached-page bridge, or the top-level attached-page catalog quickstart.',
        'Use suite_catalog_entrypoints when you want the wider suite-catalog route map reprinted before the replay falls back into the narrower attached-page bridge.',
        'Use suite_catalog_attached_html_entrypoint when you want the dedicated suite-catalog attached-page bridge preserved before narrowing into the shorter attached-page shortcut or replay shortcuts surface.',
        'Use google_attached_html_entrypoint when the broader issue-specific attached-page flow helper should stay visible after the validation-router bridge, the change-area quickstart, the top-level quickstart, the top-level bridge, or the top-level attached-page catalog quickstart before you drop to the shorter attached-page shortcut.',
        'Use attached_html_shortcut when the route is already clearly inside attached-page follow-up and you want the shortest bridge before widening into replay shortcuts, the next-step matrix, contextual flow, or the safe-route map.',
        'Use attached_bundle_change_area, attached_bundle_suite_surface, plus attached_bundle_first when explicit InputPath values are already pinned to the known three-page compatibility bundle and that branch should stay visible first.',
        'Pass -BrowserExe when the Windows-first route should stay pinned to a non-default headed build through the validation-router bridge, the generic and Google-shaped attached-page routes, the broader attached-page flow helpers, the bundle suite surface, and the bundle-first follow-up.',
        'Use contextual_flow when repo root, summary, or explicit input-path context already matters and the next helper surface should keep that replay state aligned before narrowing again. Keep the compact attached-bundle suite surface nearby whenever those pinned inputs should stay visible from the same Windows-first route.',
        'Use safe_route_entrypoints only after the attached-page route has already narrowed enough that the wrapper-heavy issue #3 command surface is the next useful layer.',
        'Keep the broader Windows runbook, the Windows full-use attached-html route note, the Windows full-use validation-router attached-html bridge note, the Windows full-use attached-html catalog quickstart note, the replay-side attached-html quickstart note, the attached-html change-area quickstart note, the validation-router attached-html quickstart note, the Google attached-html validation-flow note, the top-level attached-html quickstart note, the top-level attached-html bridge note, the top-level attached-html catalog quickstart note, the suite-catalog-to-top-level attached-html catalog quickstart note, the suite-router attached-html quickstart note, the suite-catalog entrypoints guide, the suite-catalog attached-html bridge note, the attached-html target-bundle suite-surface note, and the Windows replay quickstart nearby when you want the written route beside these commands.'
    )
}

$route.recommended_next_key = if ($route.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($route.repo_root) -or -not [string]::IsNullOrWhiteSpace($route.summary_path)) {
    'contextual_flow'
} else {
    'windows_full_use_validation_router_attached_html_bridge'
}
$route.recommended_next_command = $route.helper_commands[$route.recommended_next_key]
$route.recommended_next_reason = if ($route.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so keep the compact attached-bundle suite surface visible and stay pinned to the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($route.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing whether to reopen the validation-router bridge, the Windows-first catalog surface check, the Windows-first catalog step, the replay-side attached-html quickstart, the broader attached-page flow helper, the dedicated Google attached-page flow helper, the compact top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, the compact attached-bundle suite surface, the suite-router attached-page quickstart, the suite-catalog guide, the suite-catalog attached-page bridge, the attached-page shortcut, replay shortcuts, the next-step matrix, or the safe-route map.'
} else {
    'No pinned bundle inputs are in play yet, so jump straight from the Windows full-use route into the Windows-to-validation-router attached-html bridge while keeping the Windows-first catalog surface check, the Windows-first catalog step, the replay-side attached-html quickstart, the broader attached-page flow helper, the dedicated Google attached-page flow helper, and the validation-router quickstart visible before the route narrows to the shorter change-area bridge or the compact top-level attached-page quickstarts.'
}

if ($Json) {
    $route | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 Windows full-use attached HTML route'
Write-Host ''
if ($route.repo_root) {
    Write-Host (("Repo root:   {0}") -f $route.repo_root)
}
if ($route.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($route.summary_path)"))
}
if ($route.browser_exe) {
    Write-Host (("Browser exe: {0}") -f $route.browser_exe)
}
if ($route.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $route.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $route.recommended_next_command)
Write-Host (("Why:                    {0}") -f $route.recommended_next_reason)
Write-Host ''
Write-Host 'Route guard:'
Write-Host (("  Surface checker:          {0}") -f $route.helper_commands.windows_full_use_attached_html_route_surface_check)
Write-Host (("  Catalog checker:          {0}") -f $route.helper_commands.windows_full_use_attached_html_catalog_surface_check)
Write-Host ''
Write-Host 'Windows full-use route:'
Write-Host (("  1. Surface checker:       {0}") -f $route.helper_commands.windows_full_use_attached_html_route_surface_check)
Write-Host (("  2. Validation bridge:     {0}") -f $route.helper_commands.windows_full_use_validation_router_attached_html_bridge)
Write-Host (("  3. Catalog checker:       {0}") -f $route.helper_commands.windows_full_use_attached_html_catalog_surface_check)
Write-Host (("  4. Windows catalog qk:    {0}") -f $route.helper_commands.windows_full_use_attached_html_catalog_quickstart)
Write-Host (("  5. Replay attached qk:    {0}") -f $route.helper_commands.windows_replay_attached_html_quickstart)
Write-Host (("  6. Attached HTML:         {0}") -f $route.top_level_commands.attached_html_change_area)
Write-Host (("  7. Change-area quick:     {0}") -f $route.helper_commands.attached_html_change_area_quickstart)
Write-Host (("  8. Attached flow:         {0}") -f $route.helper_commands.attached_html_flow)
Write-Host (("  9. Google attached:       {0}") -f $route.top_level_commands.google_attached_html_change_area)
Write-Host ((" 10. Google flow:           {0}") -f $route.helper_commands.google_attached_html_flow)
Write-Host ((" 11. Validation-router qk:  {0}") -f $route.helper_commands.validation_router_attached_html_quickstart)
Write-Host ((" 12. Attached bundle:       {0}") -f $route.top_level_commands.attached_bundle_change_area)
Write-Host ((" 13. Bundle suite surface:  {0}") -f $route.helper_commands.attached_bundle_suite_surface)
Write-Host ((" 14. Issue #3 quickstart:   {0}") -f $route.helper_commands.suite_router_quickstart)
Write-Host ((" 15. Top-level quick:       {0}") -f $route.helper_commands.top_level_attached_html_quickstart)
Write-Host ((" 16. Top-level bridge:      {0}") -f $route.helper_commands.top_level_attached_html_entrypoint)
Write-Host ((" 17. Catalog quickstart:    {0}") -f $route.helper_commands.top_level_attached_html_catalog_quickstart)
Write-Host ((" 18. Catalog-to-top-level:  {0}") -f $route.helper_commands.suite_catalog_top_level_attached_html_catalog_quickstart)
Write-Host ((" 19. Router quickstart:     {0}") -f $route.helper_commands.suite_router_attached_html_quickstart)
Write-Host ((" 20. Catalog guide:         {0}") -f $route.helper_commands.suite_catalog_entrypoints)
Write-Host ((" 21. Catalog bridge:        {0}") -f $route.helper_commands.suite_catalog_attached_html_entrypoint)
Write-Host ((" 22. Google bridge:         {0}") -f $route.helper_commands.google_attached_html_entrypoint)
Write-Host ((" 23. Attached shortcut:     {0}") -f $route.helper_commands.attached_html_shortcut)
Write-Host ((" 24. Replay shortcuts:      {0}") -f $route.helper_commands.replay_shortcuts)
Write-Host ((" 25. Next-step matrix:      {0}") -f $route.helper_commands.suite_router_next_steps)
Write-Host ((" 26. Contextual flow:       {0}") -f $route.helper_commands.contextual_flow)
Write-Host ((" 27. Safe-route map:        {0}") -f $route.helper_commands.safe_route_entrypoints)
Write-Host ((" 28. Bundle-first route:    {0}") -f $route.helper_commands.attached_bundle_first)
Write-Host ''
Write-Host (("Windows runbook:              {0}") -f $route.windows_runbook_note_path)
Write-Host (("Windows attached route note:  {0}") -f $route.windows_full_use_attached_html_route_note_path)
Write-Host (("Validation bridge note:       {0}") -f $route.windows_full_use_validation_router_attached_html_bridge_note_path)
Write-Host (("Windows catalog note:         {0}") -f $route.windows_full_use_attached_html_catalog_quickstart_note_path)
Write-Host (("Replay attached note:         {0}") -f $route.windows_replay_attached_html_quickstart_note_path)
Write-Host (("Change-area quickstart note:  {0}") -f $route.attached_html_change_area_quickstart_note_path)
Write-Host (("Validation-router note:       {0}") -f $route.validation_router_attached_html_quickstart_note_path)
Write-Host (("Google attached flow note:    {0}") -f $route.google_attached_html_validation_flow_note_path)
Write-Host (("Top-level quickstart note:    {0}") -f $route.top_level_attached_html_note_path)
Write-Host (("Top-level bridge note:        {0}") -f $route.top_level_attached_html_bridge_note_path)
Write-Host (("Catalog quickstart note:      {0}") -f $route.top_level_attached_html_catalog_note_path)
Write-Host (("Catalog-to-top-level note:    {0}") -f $route.suite_catalog_top_level_attached_html_catalog_quickstart_note_path)
Write-Host (("Suite-router note:            {0}") -f $route.suite_router_attached_html_quickstart_note_path)
Write-Host (("Suite-catalog guide:          {0}") -f $route.suite_catalog_entrypoint_note_path)
Write-Host (("Suite-catalog note:           {0}") -f $route.suite_catalog_attached_html_note_path)
Write-Host (("Bundle suite note:            {0}") -f $route.attached_html_target_bundle_suite_surface_note_path)
Write-Host (("Replay quickstart note:       {0}") -f $route.windows_replay_quickstart_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $route.notes) {
    Write-Host (("- {0}") -f $note)
}