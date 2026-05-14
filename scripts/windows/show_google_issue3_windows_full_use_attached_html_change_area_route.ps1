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
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $InputPath

$emptyArguments = [System.Collections.Generic.List[string]]::new()

$route = [ordered]@{
    issue = 'Google issue #3 Windows full-use attached-html change-area route'
    purpose = 'Print the shortest route from the Windows full-use attached-page helper into show_headed_validation_suites.ps1 -ChangeArea attached-html, then keep the broader attached-page flow helper, compact top-level quickstarts, shortcut companion, and safe-route follow-ups visible together.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    note_paths = [ordered]@{
        windows_runbook = 'docs/WINDOWS_FULL_USE.md'
        windows_full_use_attached_html_route = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
        attached_html_change_area_quickstart = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
        top_level_attached_html_quickstart = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
        suite_router_attached_html_quickstart = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
        top_level_attached_html_bridge = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
        suite_catalog_attached_html_bridge = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
        windows_replay_quickstart = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
        validation_chain = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    }
    commands = [ordered]@{
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $sharedArguments
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_html_target_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $sharedArguments
        attached_html_flow = Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $emptyArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $sharedArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $sharedArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $sharedArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $sharedArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $sharedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Use this helper when docs/WINDOWS_FULL_USE.md or the broader Windows attached-page route already made attached localhost follow-up the next obvious issue #3 branch.',
        'Start with windows_full_use_attached_html_route when you want the broader Windows-first helper printed before the attached-html change-area route is reopened.',
        'Start with attached_html_change_area when the next replay should stay on the generic attached-page route before choosing the narrower issue-specific helpers.',
        'Use attached_html_change_area_quickstart as the default next helper because it keeps the broader attached-page flow helper, the compact top-level attached-page quickstart, the suite-router attached-page quickstart, and the attached-page shortcut companion visible together.',
        'Use attached_html_flow when you want the broader attached-page localhost flow helper visible from that same change-area branch before narrowing into the issue-specific quickstarts or shortcuts.',
        'Use top_level_attached_html_quickstart when the route is already narrow enough that the compact top-level attached-page bridge is the next best helper.',
        'Use suite_router_attached_html_quickstart when the route should stay closer to the suite-router-side attached-page branch before widening again.',
        'Use top_level_attached_html_entrypoint and top_level_attached_html_catalog_quickstart when you still want the broader top-level bridge and the suite-catalog-side branch visible before dropping into the shorter attached-page shortcut.',
        'Use suite_catalog_attached_html_entrypoint when the suite-catalog-side attached-page bridge should stay visible before replay narrows again.',
        'Use attached_html_shortcut when the route is already clearly inside attached-page follow-up and you want the shortest bridge before widening into replay_shortcuts, the next-step matrix, contextual_flow, or the safe-route map.',
        'Use attached_html_target_bundle_change_area plus attached_bundle_first when explicit InputPath values are already pinned to the known three-page compatibility bundle.',
        'Use contextual_flow when RepoRoot, SummaryPath, or fixed InputPath values already matter and the next helper surface should keep that replay context aligned before narrowing again.',
        'Use safe_route_entrypoints only after the route has already narrowed enough that the wrapper-heavy issue #3 command surface is the next useful layer.'
    )
}

$route.recommended_next_key = if ($route.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($route.repo_root) -or -not [string]::IsNullOrWhiteSpace($route.summary_path)) {
    'contextual_flow'
} else {
    'attached_html_change_area_quickstart'
}
$route.recommended_next_command = $route.commands[$route.recommended_next_key]
$route.recommended_next_reason = if ($route.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader helper chain.'
} elseif ($route.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing between the broader attached-page flow helper, the quickstarts, the shortcut companion, replay shortcuts, or the safe-route map.'
} else {
    'No pinned bundle inputs, repo-root override, or saved summary are in play yet, so reopen the attached-html change-area quickstart first and keep the broader attached-page flow plus the shorter attached-page shortcut visible from the same branch.'
}

if ($Json) {
    $route | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 Windows full-use attached-html change-area route'
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
Write-Host 'Windows-to-change-area route:'
Write-Host (("  Windows full-use route:     {0}") -f $route.commands.windows_full_use_attached_html_route)
Write-Host (("  Attached-html change area:  {0}") -f $route.commands.attached_html_change_area)
Write-Host (("  Google attached change:     {0}") -f $route.commands.google_attached_html_change_area)
Write-Host (("  Attached bundle change:     {0}") -f $route.commands.attached_html_target_bundle_change_area)
Write-Host ''
Write-Host 'Attached-page follow-up helpers:'
Write-Host (("  Change-area quickstart:     {0}") -f $route.commands.attached_html_change_area_quickstart)
Write-Host (("  Attached flow helper:       {0}") -f $route.commands.attached_html_flow)
Write-Host (("  Top-level quickstart:       {0}") -f $route.commands.top_level_attached_html_quickstart)
Write-Host (("  Suite-router quickstart:    {0}") -f $route.commands.suite_router_attached_html_quickstart)
Write-Host (("  Top-level attached route:   {0}") -f $route.commands.top_level_attached_html_entrypoint)
Write-Host (("  Catalog quickstart:         {0}") -f $route.commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  Catalog attached bridge:    {0}") -f $route.commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  Attached shortcut:          {0}") -f $route.commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:           {0}") -f $route.commands.replay_shortcuts)
Write-Host (("  Next-step matrix:           {0}") -f $route.commands.suite_router_next_steps)
Write-Host (("  Contextual flow:            {0}") -f $route.commands.contextual_flow)
Write-Host (("  Bundle-first helper:        {0}") -f $route.commands.attached_bundle_first)
Write-Host (("  Safe-route map:             {0}") -f $route.commands.safe_route_entrypoints)
Write-Host ''
Write-Host 'Companion notes:'
foreach ($entry in $route.note_paths.GetEnumerator()) {
    Write-Host (("  {0}: {1}") -f $entry.Key, $entry.Value)
}
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $route.notes) {
    Write-Host (("- {0}") -f $note)
}
