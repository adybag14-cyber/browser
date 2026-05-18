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
            if ($value -is [System.Array]) {
                Add-SharedPathArrayArgument -Arguments $fallbackArguments -Name $entry.Key -Values @($value)
                continue
            }

            Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $value
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
        if ($value -is [System.Array]) {
            $filteredValues = @(
                $value | Where-Object {
                    $null -ne $_ -and (-not ($_ -is [string]) -or -not [string]::IsNullOrWhiteSpace($_))
                }
            )
            if ($filteredValues.Count -eq 0) {
                continue
            }

            $escapedValues = @(
                $filteredValues | ForEach-Object {
                    "'" + (("$_") -replace "'", "''") + "'"
                }
            )
            $command += (" -{0} {1}" -f $entry.Key, ($escapedValues -join ' '))
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
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $InputPath

$browserAwareSharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $browserAwareSharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $browserAwareSharedArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $browserAwareSharedArguments -Name BrowserExe -Value $BrowserExe
Add-SharedPathArrayArgument -Arguments $browserAwareSharedArguments -Name InputPath -Values $InputPath

$routeSurfaceArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $routeSurfaceArguments -Name RepoRoot -Value $RepoRoot

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}
if ($BrowserExe) {
    $attachedHtmlFlowArguments['BrowserExe'] = $BrowserExe
}

$attachedHtmlChangeAreaCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
    ChangeArea = 'attached-html'
}) -RepoRootOverride $RepoRoot
$googleAttachedHtmlChangeAreaCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
    ChangeArea = 'google-attached-html'
}) -RepoRootOverride $RepoRoot
$attachedBundleChangeAreaCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
    ChangeArea = 'attached-html-target-bundle'
}) -RepoRootOverride $RepoRoot

$helper = [ordered]@{
    issue = 'Google issue #3 Windows replay attached HTML quickstart'
    purpose = 'Print the narrow attached-localhost ladder that matches the current Windows replay route for issue #3, while keeping the replay-side fail-fast checker, the broader attached-page flow helper, the dedicated Google-shaped attached-page surface check, the top-level attached-html, Google-attached-html, and bundle-aware re-entry points, the Windows full-use route-level surface check, the Windows-to-validation-router bridge, the Windows-first attached-html catalog step, the broader top-level companion-note map, the wider suite-catalog guide, the suite-catalog-to-top-level attached-html catalog quickstart, the newer top-level shortcut bridge, the compact bundle-suite surface helper, and the replay-route shortcut bridge visible before the route narrows back into the compact attached-page helpers.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    browser_exe = $BrowserExe
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    validation_router_attached_html_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    attached_html_change_area_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    top_level_attached_html_companion_notes_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md'
    suite_catalog_top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    top_level_shortcut_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md'
    suite_catalog_entrypoints_note_path = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    suite_router_shortcut_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    replay_route_shortcut_bridge_note_path = 'docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md'
    attached_html_target_bundle_reference_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
    attached_html_target_bundle_suite_surface_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    windows_full_use_validation_router_attached_html_bridge_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md'
    windows_full_use_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    top_level_commands = [ordered]@{
        attached_html_change_area = $attachedHtmlChangeAreaCommand
        google_attached_html_change_area = $googleAttachedHtmlChangeAreaCommand
        attached_bundle_change_area = $attachedBundleChangeAreaCommand
    }
    commands = [ordered]@{
        windows_replay_attached_html_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -Arguments $routeSurfaceArguments
        windows_full_use_attached_html_route_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -Arguments $routeSurfaceArguments
        windows_full_use_validation_router_attached_html_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $browserAwareSharedArguments
        windows_full_use_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $browserAwareSharedArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $browserAwareSharedArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        suite_catalog_top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $sharedArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        attached_html_validation_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        attached_pages_launcher_companion_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $routeSurfaceArguments
        attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments
        google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot
        google_attached_html_validation_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        top_level_shortcut_first = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $sharedArguments
        replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $sharedArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $sharedArguments
        attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $sharedArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $sharedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Start here when docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md already narrowed the next replay to the attached localhost branch and you want the shortest helper ladder printed in one place with the replay-side surface check, the broader attached-page flow helper, the top-level attached-html re-entry points, the top-level shortcut bridge, the compact bundle-suite surface helper, and the replay-route shortcut bridge kept visible.',
        'Use the top-level attached-html, Google-attached-html, and attached-html-target-bundle re-entry points when you need to reopen the headed validation router on the generic attached route, the Google-shaped attached route, or the pinned three-page bundle route before dropping back into the narrower replay ladder.',
        'Use windows_replay_attached_html_surface_check first after branch moves or before trusting this route from another checkout, because it fails fast on missing replay-side notes, helper scripts, and downstream attached-page surfaces before the route narrows again.',
        'Use windows_full_use_attached_html_route_surface_check after the replay-side checker when you also want the broader Windows full-use attached-page route validated before the replay narrows further.',
        'Use windows_full_use_validation_router_attached_html_bridge first when the replay is re-entering from docs/WINDOWS_FULL_USE.md or the broader Windows full-use attached-page note and you want the route-level surface check plus the Windows-to-validation-router handoff kept visible before the route drops back into the compact attached-page helpers.',
        'Use windows_full_use_attached_html_catalog_quickstart right after the broader Windows bridge when you want the Windows-first catalog step kept visible before the validation-router quickstart and the smaller attached-page helpers take over.',
        'Use validation_router_attached_html_quickstart first when the replay already passed the broader Windows full-use guard rails and catalog step but you still want the wider validation-router attached-page bridge visible before the top-level attached-page quickstarts.',
        'Then prefer attached_html_change_area_quickstart, attached_html_validation_flow, google_attached_html_surface_check, top_level_attached_html_quickstart, and top_level_attached_html_entrypoint as the default middle of the ladder so the broader attached-page flow helper, the dedicated Google-shaped attached-page surface check, the compact top-level route, the broader top-level companion-note map, and the suite-catalog-to-top-level catalog quickstart stay visible before you drop into the suite-catalog bridge or the shorter attached-page shortcut.',
        'Use top_level_attached_html_catalog_quickstart when you want the compact top-level quickstart and the suite-catalog-to-top-level catalog quickstart reprinted together before the route narrows again.',
        'Use suite_catalog_top_level_attached_html_catalog_quickstart when you want the replay-side attached-html ladder, the top-level attached-html catalog quickstart, and the suite-catalog-side bridge kept on the same surface before the route narrows again.',
        'Use suite_catalog_entrypoints when you want the wider suite-catalog route map reprinted before the replay falls back into the narrower attached-page bridge.',
        'Use suite_catalog_attached_html_entrypoint when you want the suite-catalog-side attached-page bridge without reopening broader router helpers first.',
        'Use attached_html_validation_flow when the replay should keep the broader attached-page helper visible before the ladder narrows into the Google-shaped route or the shorter issue #3 helpers.',
        'Use google_attached_html_surface_check when branch state may have moved and the replay should fail fast on the dedicated Google-shaped attached-page lane before reopening the narrower Google helper from this same replay ladder.',
        'Use google_attached_html_validation_flow when the current attached inputs are already Google-shaped and you want the dedicated attached-page asset-closure and preferred-initial-page helper visible after the dedicated Google-shaped attached-page surface check and before the route narrows back into the suite-router sidecar or the shorter attached-page shortcut.',
        'Keep suite_router_attached_html_quickstart nearby as the sidecar helper when the route needs to widen back toward the suite-router surface instead of narrowing directly into the shorter attached-page bridge or the attached-page shortcut.',
        'Use top_level_shortcut_first after the suite-router sidecar or the broader top-level attached-page bridge when you want the newer top-level shortcut bridge reprinted before the route collapses into the shorter attached-page shortcut surface.',
        'Use replay_route_shortcut after the top-level shortcut bridge, the attached-page shortcut, or replay_shortcuts when you want the narrower replay-route companion surface reprinted before the route widens into the next-step matrix, bundle-first helper, or safe-route map.',
        'Use attached_html_shortcut only after the top-level attached-page quickstart, change-area quickstart, bridge, top-level shortcut bridge, or replay-route shortcut bridge is already in view and the replay is ready to stay inside the narrower issue #3 helper chain.',
        'Use attached_bundle_suite_surface when the replay is already close to the known three-page compatibility bundle but you still want the compact suite-level surface printed before the narrower bundle-first helper or the delegated bundle flow takes over.',
        'Use replay_shortcuts after the attached-page shortcut, the replay-route shortcut bridge, or the suite-catalog bridge when you want the tightest current helper surface before widening back out.',
        'Use contextual_flow when RepoRoot, SummaryPath, or pinned InputPath values already matter and the next helper should preserve that replay context before it narrows again.',
        'Use attached_bundle_first when explicit InputPath values are already pinned to the known three-page compatibility bundle and keep docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md plus docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md nearby so the locked inputs stay visible before the route widens again.',
        'Use windows_full_use_attached_html_route when the replay came from docs/WINDOWS_FULL_USE.md first and you want the broader Windows runbook attached-page route visible beside this shorter replay ladder.',
        'Keep the Windows replay quickstart note, the replay-side attached-html quickstart note, the Windows full-use attached-page route note, the Windows full-use validation-router attached-html bridge note, the Windows full-use attached-html catalog quickstart note, the validation-router attached-page note, the attached-html change-area quickstart note, the top-level attached-page quickstart note, the top-level attached-page bridge note, the top-level attached-page catalog quickstart note, the top-level attached-page companion-notes map, the suite-catalog-to-top-level attached-html catalog quickstart note, the top-level shortcut bridge note, the suite-catalog entrypoints guide, the suite-catalog attached-page bridge note, the Google attached-page validation-flow note, the suite-router attached-page quickstart note, the suite-router shortcut bridge note, the replay-route shortcut bridge note, the attached-html target bundle reference note, the attached-html target-bundle suite-surface note, and the validation-chain note nearby when you want the written route beside these commands.'
    )
}

$helper.recommended_next_key = if ($helper.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($helper.repo_root) -or -not [string]::IsNullOrWhiteSpace($helper.summary_path)) {
    'contextual_flow'
} else {
    'windows_full_use_validation_router_attached_html_bridge'
}
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so keep the replay on the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($helper.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing between the narrower attached-page helpers.'
} else {
    'No pinned bundle inputs, non-default repo root, or saved summary are in play yet, so reopen the Windows full-use validation-router attached-html bridge first and keep the replay-side checker, the route-level surface checker, and the Windows-first attached-html catalog quickstart nearby before dropping into the smaller attached-page quickstarts.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 Windows replay attached HTML quickstart'
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
if ($helper.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $helper.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $helper.recommended_next_command)
Write-Host (("Why:                    {0}") -f $helper.recommended_next_reason)
Write-Host ''
Write-Host 'Top-level re-entry points:'
Write-Host (("  Attached HTML:          {0}") -f $helper.top_level_commands.attached_html_change_area)
Write-Host (("  Google attached HTML:   {0}") -f $helper.top_level_commands.google_attached_html_change_area)
Write-Host (("  Attached bundle:        {0}") -f $helper.top_level_commands.attached_bundle_change_area)
Write-Host ''
Write-Host 'Route guard:'
Write-Host (("  Replay surface check:    {0}") -f $helper.commands.windows_replay_attached_html_surface_check)
Write-Host (("  Route surface check:     {0}") -f $helper.commands.windows_full_use_attached_html_route_surface_check)
Write-Host ''
Write-Host 'Broader Windows bridge:'
Write-Host (("  Windows full-use route:   {0}") -f $helper.commands.windows_full_use_attached_html_route)
Write-Host (("  Validation bridge:        {0}") -f $helper.commands.windows_full_use_validation_router_attached_html_bridge)
Write-Host (("  Catalog quickstart:       {0}") -f $helper.commands.windows_full_use_attached_html_catalog_quickstart)
Write-Host ''
Write-Host 'Attached-page ladder:'
Write-Host (("  Validation-router quick:  {0}") -f $helper.commands.validation_router_attached_html_quickstart)
Write-Host (("  Change-area quick:        {0}") -f $helper.commands.attached_html_change_area_quickstart)
Write-Host (("  Top-level quickstart:     {0}") -f $helper.commands.top_level_attached_html_quickstart)
Write-Host (("  Top-level bridge:         {0}") -f $helper.commands.top_level_attached_html_entrypoint)
Write-Host (("  Catalog quickstart:       {0}") -f $helper.commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  Catalog bridge quick:     {0}") -f $helper.commands.suite_catalog_top_level_attached_html_catalog_quickstart)
Write-Host (("  Suite-catalog guide:      {0}") -f $helper.commands.suite_catalog_entrypoints)
Write-Host (("  Suite-catalog bridge:     {0}") -f $helper.commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  Broader attached flow:    {0}") -f $helper.commands.attached_html_validation_flow)
Write-Host (("  Launcher surface check:   {0}") -f $helper.commands.attached_pages_launcher_companion_surface_check)
Write-Host (("  Launcher companion:       {0}") -f $helper.commands.attached_pages_launcher_companion)
Write-Host (("  Google attached check:    {0}") -f $helper.commands.google_attached_html_surface_check)
Write-Host (("  Google attached flow:     {0}") -f $helper.commands.google_attached_html_validation_flow)
Write-Host (("  Suite-router sidecar:     {0}") -f $helper.commands.suite_router_attached_html_quickstart)
Write-Host (("  Top-level shortcut:       {0}") -f $helper.commands.top_level_shortcut_first)
Write-Host (("  Replay-route shortcut:    {0}") -f $helper.commands.replay_route_shortcut)
Write-Host (("  Attached shortcut:        {0}") -f $helper.commands.attached_html_shortcut)
Write-Host (("  Bundle suite surface:     {0}") -f $helper.commands.attached_bundle_suite_surface)
Write-Host (("  Replay shortcuts:         {0}") -f $helper.commands.replay_shortcuts)
Write-Host (("  Contextual flow:          {0}") -f $helper.commands.contextual_flow)
Write-Host (("  Bundle-first helper:      {0}") -f $helper.commands.attached_bundle_first)
Write-Host (("  Safe-route map:           {0}") -f $helper.commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Windows replay note:         {0}") -f (' ' + $helper.windows_replay_quickstart_note_path))
Write-Host (("Replay attached note:        {0}") -f (' ' + $helper.windows_replay_attached_html_quickstart_note_path))
Write-Host (("Windows route note:          {0}") -f (' ' + $helper.windows_full_use_attached_html_route_note_path))
Write-Host (("Windows bridge note:         {0}") -f (' ' + $helper.windows_full_use_validation_router_attached_html_bridge_note_path))
Write-Host (("Windows catalog note:        {0}") -f (' ' + $helper.windows_full_use_attached_html_catalog_quickstart_note_path))
Write-Host (("Validation-router note:      {0}") -f (' ' + $helper.validation_router_attached_html_note_path))
Write-Host (("Change-area quickstart note: {0}") -f (' ' + $helper.attached_html_change_area_quickstart_note_path))
Write-Host (("Top-level quickstart note:   {0}") -f (' ' + $helper.top_level_attached_html_quickstart_note_path))
Write-Host (("Top-level bridge note:       {0}") -f (' ' + $helper.top_level_attached_html_bridge_note_path))
Write-Host (("Catalog quickstart note:     {0}") -f (' ' + $helper.top_level_attached_html_catalog_quickstart_note_path))
Write-Host (("Companion-notes map:        {0}") -f (' ' + $helper.top_level_attached_html_companion_notes_note_path))
Write-Host (("Catalog bridge note:         {0}") -f (' ' + $helper.suite_catalog_top_level_attached_html_catalog_quickstart_note_path))
Write-Host (("Top-level shortcut note:     {0}") -f (' ' + $helper.top_level_shortcut_bridge_note_path))
Write-Host (("Suite-catalog guide:         {0}") -f (' ' + $helper.suite_catalog_entrypoints_note_path))
Write-Host (("Suite-catalog note:          {0}") -f (' ' + $helper.suite_catalog_attached_html_bridge_note_path))
Write-Host (("Google attached flow note:  {0}") -f (' ' + $helper.google_attached_html_validation_flow_note_path))
Write-Host (("Suite-router note:           {0}") -f (' ' + $helper.suite_router_attached_html_quickstart_note_path))
Write-Host (("Suite-router shortcut note:  {0}") -f (' ' + $helper.suite_router_shortcut_bridge_note_path))
Write-Host (("Replay-route shortcut note:  {0}") -f (' ' + $helper.replay_route_shortcut_bridge_note_path))
Write-Host (("Bundle reference note:       {0}") -f (' ' + $helper.attached_html_target_bundle_reference_note_path))
Write-Host (("Bundle suite note:           {0}") -f (' ' + $helper.attached_html_target_bundle_suite_surface_note_path))
Write-Host (("Validation chain note:       {0}") -f (' ' + $helper.validation_chain_note_path))
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}