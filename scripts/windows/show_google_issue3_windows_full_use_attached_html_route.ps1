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

$route = [ordered]@{
    issue = 'Google issue #3 Windows full-use attached HTML route'
    purpose = 'Print the shortest attached-localhost replay route that starts from the broader Windows headed runbook and narrows through either the shorter issue #3 replay quickstart or the top-level attached-page quickstart, then through the top-level attached-page catalog quickstart, the issue-specific attached-page bridge, and the newer attached-page shortcut chain.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    top_level_commands = [ordered]@{
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
        suite_router_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
    }
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    suite_catalog_attached_html_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    top_level_attached_html_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_catalog_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    notes = @(
        'Use this helper when the next replay starts from the broader Windows headed runbook and is already centered on the attached localhost compatibility pages for issue #3.',
        'Start with attached_html_change_area when the next replay should stay on the generic attached-page route before choosing the narrower issue-specific helpers.',
        'Start with google_attached_html_change_area when the next replay should still keep the Google-shaped attached-page route visible before narrowing again.',
        'Use suite_router_quickstart when the broader Windows runbook or the top-level validation router already narrowed the replay to issue #3, but not yet all the way to the attached-html branch, and you want the shortest bridge back into the current replay helper stack before deciding whether to widen into the attached-page chain, replay shortcuts, or the safe-route map.',
        'Use top_level_attached_html_quickstart as the default next helper because it keeps the compact top-level attached-page quickstart visible before the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-router attached-page quickstart, the attached-page shortcut, replay shortcuts, or the safe-route map.',
        'Use top_level_attached_html_entrypoint when the route is already clearly inside the issue-specific attached-page branch and you want the broader top-level bridge reprinted after the compact quickstart.',
        'Use top_level_attached_html_catalog_quickstart when you want the compact top-level attached-page quickstart and the suite-catalog-side attached-page bridge kept visible together before the route narrows into the shorter attached-page shortcut, replay shortcuts, contextual flow, or the safe-route map.',
        'Use suite_router_attached_html_quickstart when you want the shorter suite-router-side attached-page bridge after the top-level quickstart, the top-level attached-page bridge, or the top-level attached-page catalog quickstart.',
        'Use suite_catalog_attached_html_entrypoint when you want the dedicated suite-catalog attached-page bridge preserved before narrowing into the shorter attached-page shortcut or replay shortcuts surface.',
        'Use google_attached_html_entrypoint when the broader issue-specific attached-page flow helper should stay visible after the top-level quickstart, the top-level bridge, or the top-level attached-page catalog quickstart before you drop to the shorter attached-page shortcut.',
        'Use attached_html_shortcut when the route is already clearly inside attached-page follow-up and you want the shortest bridge before widening into replay shortcuts, the next-step matrix, contextual flow, or the safe-route map.',
        'Use attached_bundle_change_area plus attached_bundle_first when explicit InputPath values are already pinned to the known three-page compatibility bundle and that branch should stay visible first.',
        'Use contextual_flow when repo root, summary, or explicit input-path context already matters and the next helper surface should keep that replay state aligned before narrowing again.',
        'Use safe_route_entrypoints only after the attached-page route has already narrowed enough that the wrapper-heavy issue #3 command surface is the next useful layer.',
        'Keep the broader Windows runbook, the Windows full-use attached-html route note, the top-level attached-html quickstart note, the top-level attached-html bridge note, the top-level attached-html catalog quickstart note, the suite-router attached-html quickstart note, the suite-catalog attached-html bridge note, and the Windows replay quickstart nearby when you want the written route beside these commands.'
    )
}

$route.recommended_next_key = if ($route.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($route.repo_root) -or -not [string]::IsNullOrWhiteSpace($route.summary_path)) {
    'contextual_flow'
} else {
    'top_level_attached_html_quickstart'
}
$route.recommended_next_command = $route.helper_commands[$route.recommended_next_key]
$route.recommended_next_reason = if ($route.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($route.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing whether to reopen the compact top-level quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-router attached-page quickstart, the suite-catalog attached-page bridge, the attached-page shortcut, replay shortcuts, the next-step matrix, or the safe-route map.'
} else {
    'No pinned bundle inputs are in play yet, so jump straight from the Windows full-use route into the compact top-level attached-page quickstart before widening to the broader attached-page bridge.'
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
if ($route.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $route.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $route.recommended_next_command)
Write-Host (("Why:                    {0}") -f $route.recommended_next_reason)
Write-Host ''
Write-Host 'Windows full-use route:'
Write-Host (("  1. Attached HTML:        {0}") -f $route.top_level_commands.attached_html_change_area)
Write-Host (("  2. Google attached:      {0}") -f $route.top_level_commands.google_attached_html_change_area)
Write-Host (("  3. Attached bundle:      {0}") -f $route.top_level_commands.attached_bundle_change_area)
Write-Host (("  4. Replay quickstart:    {0}") -f $route.helper_commands.suite_router_quickstart)
Write-Host (("  5. Top-level quick:      {0}") -f $route.helper_commands.top_level_attached_html_quickstart)
Write-Host (("  6. Top-level bridge:     {0}") -f $route.helper_commands.top_level_attached_html_entrypoint)
Write-Host (("  7. Catalog quickstart:   {0}") -f $route.helper_commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  8. Router quickstart:    {0}") -f $route.helper_commands.suite_router_attached_html_quickstart)
Write-Host (("  9. Catalog bridge:       {0}") -f $route.helper_commands.suite_catalog_attached_html_entrypoint)
Write-Host ((" 10. Google attached:      {0}") -f $route.helper_commands.google_attached_html_entrypoint)
Write-Host ((" 11. Attached shortcut:    {0}") -f $route.helper_commands.attached_html_shortcut)
Write-Host ((" 12. Replay shortcuts:     {0}") -f $route.helper_commands.replay_shortcuts)
Write-Host ((" 13. Next-step matrix:     {0}") -f $route.helper_commands.suite_router_next_steps)
Write-Host ((" 14. Contextual flow:      {0}") -f $route.helper_commands.contextual_flow)
Write-Host ((" 15. Safe-route map:       {0}") -f $route.helper_commands.safe_route_entrypoints)
Write-Host ((" 16. Bundle-first route:   {0}") -f $route.helper_commands.attached_bundle_first)
Write-Host ''
Write-Host (("Windows runbook:             {0}") -f $route.windows_runbook_note_path)
Write-Host (("Windows attached route note: {0}") -f $route.windows_full_use_attached_html_route_note_path)
Write-Host (("Top-level quickstart note:   {0}") -f $route.top_level_attached_html_note_path)
Write-Host (("Top-level bridge note:       {0}") -f $route.top_level_attached_html_bridge_note_path)
Write-Host (("Catalog quickstart note:     {0}") -f $route.top_level_attached_html_catalog_note_path)
Write-Host (("Suite-router note:           {0}") -f $route.suite_router_attached_html_quickstart_note_path)
Write-Host (("Suite-catalog note:          {0}") -f $route.suite_catalog_attached_html_note_path)
Write-Host (("Replay quickstart note:      {0}") -f $route.windows_replay_quickstart_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $route.notes) {
    Write-Host (("- {0}") -f $note)
}
