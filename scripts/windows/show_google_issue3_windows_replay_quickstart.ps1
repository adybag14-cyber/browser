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

$routeSurfaceArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $routeSurfaceArguments -Name RepoRoot -Value $RepoRoot

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$helper = [ordered]@{
    issue = 'Google issue #3 Windows replay quickstart'
    purpose = 'Print the main read-first replay entrypoint for issue #3, keeping the suite-catalog bridge, the suite-router quickstart, the validation-router attached-html fail-fast checker, the validation-router attached-html helper, the replay-attached-html fail-fast checker, the replay-side attached-html helper, its written companion note, the attached-pages launcher companion checker and helper, the broader attached-page flow helper, the dedicated Google-shaped attached-page flow helper, the compact bundle-suite surface helper, the top-level attached-html ladder, the shortcut bridges, and the safe-route helpers visible from one compact surface.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    replay_attached_html_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    replay_quickstart_shortcut_bridge_note_path = 'docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md'
    replay_route_shortcut_bridge_note_path = 'docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md'
    top_level_shortcut_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md'
    suite_router_shortcut_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    validation_router_attached_html_quickstart_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    google_attached_html_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_catalog_top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    attached_html_target_bundle_suite_surface_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
    safe_route_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    commands = [ordered]@{
        google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        google_input = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_html_target_bundle = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $sharedArguments
        suite_router_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_quickstart.ps1' -Arguments $sharedArguments
        validation_router_attached_html_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -Arguments $routeSurfaceArguments
        validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        windows_replay_attached_html_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -Arguments $routeSurfaceArguments
        windows_full_use_attached_html_route_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -Arguments $routeSurfaceArguments
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $sharedArguments
        windows_full_use_validation_router_attached_html_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $sharedArguments
        windows_full_use_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $sharedArguments
        attached_pages_launcher_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $routeSurfaceArguments
        attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        top_level_shortcut_first = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $sharedArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $sharedArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        suite_catalog_top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        attached_html_target_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $sharedArguments
        suite_router_shortcut_first = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $sharedArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $sharedArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $sharedArguments
        replay_route_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $sharedArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $sharedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Start with suite_catalog_entrypoints when you want the broadest read-first bridge that still stays inside the issue #3 replay family.',
        'Use suite_router_quickstart when the top-level validation catalog already made issue #3 obvious and you want the shortest router-side bridge before the route narrows again.',
        'Use validation_router_attached_html_surface_check immediately before validation_router_attached_html_quickstart when attached localhost replay is already the next obvious branch and you want that narrower bridge to fail fast on drifted quickstart notes, missing helper scripts, or renamed attached-page follow-up before the replay narrows further.',
        'Use windows_replay_attached_html_surface_check before trusting the narrower replay-side attached-html ladder from another checkout, because it fails fast on missing replay-note, helper-script, or downstream attached-page surfaces before the route narrows again.',
        'Use windows_full_use_attached_html_route_surface_check before trusting the attached-page ladder from another checkout, because it fails fast on missing route notes, helper scripts, or downstream attached-page surfaces.',
        'Use windows_replay_attached_html_quickstart when the main replay note already narrowed the next step to the attached localhost branch and you want the shorter replay-side attached-page ladder printed directly.',
        'Treat replay_attached_html_note_path as the read-first written companion to windows_replay_attached_html_quickstart once the main replay quickstart narrows into the attached localhost branch, so the helper command and note stay paired on the same surface.',
        'Use attached_pages_launcher_surface_check and attached_pages_launcher_companion when the replay has already narrowed into attached localhost follow-up and you want the wrapper-backed sidecar, asset, manifest, and strict-launch ladder printed on one smaller surface before reopening the broader Google-shaped, top-level, or bundle-first branches.',
        'Use attached_html_flow when you want the broader attached-page localhost helper reprinted directly from the main replay quickstart before you commit to the narrower shortcut ladder or the bundle-first branch.',
        'Use google_attached_html_flow when the current attached inputs are already Google-shaped and you still want that narrower attached-page flow visible before the route narrows back into the shorter issue #3 helper chain.',
        'Use attached_html_target_bundle_suite_surface when the replay is already close to the known three-page compatibility bundle and you want the compact suite-level bundle surface visible before the bundle-first helper takes over.',
        'Use top_level_shortcut_first when the replay is already clearly inside issue #3 and you want the shorter top-level shortcut bridge kept visible before reopening the wider attached-page helpers.',
        'Use suite_router_shortcut_first after attached_html_shortcut when you want the narrower suite-router shortcut bridge reprinted before the route collapses into replay_shortcuts.',
        'Use replay_route and replay_route_shortcut_entrypoint when you want the broader issue #3 route or the narrower replay-route follow-up printed beside the shortcut helpers.',
        'Use contextual_flow when RepoRoot, SummaryPath, or pinned InputPath values already matter and the next helper surface should preserve that replay context.',
        'Use attached_bundle_first when explicit InputPath values are already pinned to the known three-page compatibility bundle.',
        'Keep the Windows replay quickstart note, the replay-side attached-html note, the Windows full-use attached-html route note, the validation-router attached-html note, the dedicated Google attached-page flow note, the top-level attached-html notes, the compact bundle-suite note, the top-level and suite-router shortcut-bridge notes, the suite-catalog entrypoint guide, the suite-catalog attached-html bridge, the suite-router attached-html quickstart, the replay shortcut bridges, and the safe-route note nearby when you want the written route beside these commands.'
    )
}

$helper.recommended_next_key = if ($helper.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($helper.repo_root) -or -not [string]::IsNullOrWhiteSpace($helper.summary_path)) {
    'contextual_flow'
} else {
    'suite_catalog_entrypoints'
}
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so stay on the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($helper.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing between the narrower attached-page helpers, replay shortcuts, or the safe-route map.'
} else {
    'No pinned bundle inputs, non-default repo root, or saved summary are in play yet, so start from the suite-catalog bridge and keep the broader replay ladder visible before the route narrows again. When the route reaches the replay-side attached HTML quickstart, keep the written replay attached note open beside it.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 Windows replay quickstart'
Write-Host ''
if ($helper.repo_root) {
    Write-Host (("Repo root:   {0}") -f $helper.repo_root)
}
if ($helper.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($helper.summary_path)"))
}
if ($helper.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $helper.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $helper.recommended_next_command)
Write-Host (("Why:                    {0}") -f $helper.recommended_next_reason)
Write-Host ''
Write-Host 'Top-level replay entrypoints:'
Write-Host (("  Google recommended:        {0}") -f $helper.commands.google_recommended)
Write-Host (("  Google input:              {0}") -f $helper.commands.google_input)
Write-Host (("  Attached HTML:             {0}") -f $helper.commands.attached_html)
Write-Host (("  Google attached HTML:      {0}") -f $helper.commands.google_attached_html)
Write-Host (("  Attached bundle:           {0}") -f $helper.commands.attached_html_target_bundle)
Write-Host ''
Write-Host 'Read-first issue #3 bridge:'
Write-Host (("  Suite catalog:             {0}") -f $helper.commands.suite_catalog_entrypoints)
Write-Host (("  Suite router quickstart:   {0}") -f $helper.commands.suite_router_quickstart)
Write-Host (("  Validation-router check:   {0}") -f $helper.commands.validation_router_attached_html_surface_check)
Write-Host (("  Validation-router quick:   {0}") -f $helper.commands.validation_router_attached_html_quickstart)
Write-Host ''
Write-Host 'Attached-page ladder:'
Write-Host (("  Replay attached check:     {0}") -f $helper.commands.windows_replay_attached_html_surface_check)
Write-Host (("  Route surface check:       {0}") -f $helper.commands.windows_full_use_attached_html_route_surface_check)
Write-Host (("  Windows full-use route:    {0}") -f $helper.commands.windows_full_use_attached_html_route)
Write-Host (("  Windows validation bridge: {0}") -f $helper.commands.windows_full_use_validation_router_attached_html_bridge)
Write-Host (("  Windows catalog quick:     {0}") -f $helper.commands.windows_full_use_attached_html_catalog_quickstart)
Write-Host (("  Replay attached quick:     {0}") -f $helper.commands.windows_replay_attached_html_quickstart)
Write-Host (("  Replay attached note:      {0}") -f $helper.replay_attached_html_note_path)
Write-Host (("  Launcher surface check:    {0}") -f $helper.commands.attached_pages_launcher_surface_check)
Write-Host (("  Launcher companion:        {0}") -f $helper.commands.attached_pages_launcher_companion)
Write-Host (("  Attached-page flow:        {0}") -f $helper.commands.attached_html_flow)
Write-Host (("  Google attached flow:      {0}") -f $helper.commands.google_attached_html_flow)
Write-Host (("  Top-level shortcut:        {0}") -f $helper.commands.top_level_shortcut_first)
Write-Host (("  Top-level quickstart:      {0}") -f $helper.commands.top_level_attached_html_quickstart)
Write-Host (("  Top-level bridge:          {0}") -f $helper.commands.top_level_attached_html_entrypoint)
Write-Host (("  Top-level catalog quick:   {0}") -f $helper.commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  Catalog bridge quick:      {0}") -f $helper.commands.suite_catalog_top_level_attached_html_catalog_quickstart)
Write-Host (("  Suite-catalog bridge:      {0}") -f $helper.commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  Router attached quick:     {0}") -f $helper.commands.suite_router_attached_html_quickstart)
Write-Host (("  Bundle suite surface:      {0}") -f $helper.commands.attached_html_target_bundle_suite_surface)
Write-Host (("  Attached shortcut:         {0}") -f $helper.commands.attached_html_shortcut)
Write-Host (("  Router shortcut:           {0}") -f $helper.commands.suite_router_shortcut_first)
Write-Host (("  Replay shortcuts:          {0}") -f $helper.commands.replay_shortcuts)
Write-Host ''
Write-Host 'Replay follow-ups:'
Write-Host (("  Replay route:              {0}") -f $helper.commands.replay_route)
Write-Host (("  Route shortcut:            {0}") -f $helper.commands.replay_route_shortcut_entrypoint)
Write-Host (("  Contextual flow:           {0}") -f $helper.commands.contextual_flow)
Write-Host (("  Bundle-first helper:       {0}") -f $helper.commands.attached_bundle_first)
Write-Host (("  Safe-route map:            {0}") -f $helper.commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Quickstart note:             {0}") -f $helper.quickstart_note_path)
Write-Host (("Replay attached note:        {0}") -f $helper.replay_attached_html_note_path)
Write-Host (("Replay shortcut note:        {0}") -f $helper.replay_quickstart_shortcut_bridge_note_path)
Write-Host (("Replay-route shortcut note:  {0}") -f $helper.replay_route_shortcut_bridge_note_path)
Write-Host (("Top-level shortcut note:     {0}") -f $helper.top_level_shortcut_bridge_note_path)
Write-Host (("Suite-router shortcut note:  {0}") -f $helper.suite_router_shortcut_bridge_note_path)
Write-Host (("Windows route note:          {0}") -f $helper.windows_full_use_attached_html_route_note_path)
Write-Host (("Validation-router note:      {0}") -f $helper.validation_router_attached_html_quickstart_note_path)
Write-Host (("Google attached note:        {0}") -f $helper.google_attached_html_flow_note_path)
Write-Host (("Top-level quickstart note:   {0}") -f $helper.top_level_attached_html_quickstart_note_path)
Write-Host (("Top-level bridge note:       {0}") -f $helper.top_level_attached_html_bridge_note_path)
Write-Host (("Top-level catalog note:      {0}") -f $helper.top_level_attached_html_catalog_quickstart_note_path)
Write-Host (("Catalog bridge note:         {0}") -f $helper.suite_catalog_top_level_attached_html_catalog_quickstart_note_path)
Write-Host (("Suite-catalog note:          {0}") -f $helper.suite_catalog_attached_html_bridge_note_path)
Write-Host (("Suite-router note:           {0}") -f $helper.suite_router_attached_html_quickstart_note_path)
Write-Host (("Bundle suite note:           {0}") -f $helper.attached_html_target_bundle_suite_surface_note_path)
Write-Host (("Suite-catalog guide:         {0}") -f $helper.suite_catalog_entrypoint_note_path)
Write-Host (("Safe-route note:             {0}") -f $helper.safe_route_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
