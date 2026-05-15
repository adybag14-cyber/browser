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

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$emptyArguments = [System.Collections.Generic.List[string]]::new()

$helper = [ordered]@{
    issue = 'Google issue #3 suite-router attached HTML quickstart'
    purpose = 'Print the shortest attached-page-first bridge from the top-level headed validation suite router into the issue #3 attached-page helper chain, while preserving repo-root, saved-summary, and pinned bundle-input context when it already exists, surfacing the newer top-level attached-page quickstarts before the longer replay helper chain when possible, and keeping the broader attached-page flow helper one step earlier in the suite-router handoff.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    validation_router_attached_html_quickstart_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    attached_html_change_area_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    top_level_attached_html_companion_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    commands = [ordered]@{
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $bundleArguments
        attached_html_flow = Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $emptyArguments
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $bundleArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
    }
    notes = @(
        'Start with attached_html_change_area when the top-level headed validation router is already narrowed to the attached localhost compatibility path and you want that route reprinted before dropping into the issue-specific helper chain.',
        'Use google_attached_html_change_area when the replay still needs the broader Google-shaped attached-page route visible before narrowing again.',
        'Use validation_router_attached_html_quickstart when the replay is still one step higher in the broader validation router and you want that written bridge visible before this suite-router attached-page helper narrows the route again.',
        'Use attached_html_change_area_quickstart when the replay is already centered on show_headed_validation_suites.ps1 -ChangeArea attached-html and you want the generic attached-page flow helper plus the narrower issue #3 route visible together before falling back to the shorter helper chain.',
        'Use attached_html_flow when you want the broader attached-page localhost helper reprinted directly from this suite-router quickstart before the route narrows into the compact top-level quickstarts, the issue-specific attached-page bridge, or the attached-page shortcut companion.',
        'Use suite_catalog_entrypoints when you want the wider suite-catalog command map reprinted before the attached-page route narrows into the suite-catalog-side bridge, the top-level attached-page helpers, the attached-page shortcut, replay shortcuts, the next-step matrix, contextual flow, the bundle-first branch, or the safe-route helper.',
        'Use top_level_attached_html_quickstart as the default next helper when no pinned bundle inputs, non-default repo root, or saved summary need to take precedence, because it keeps the shorter top-level attached-page bridge visible before reopening the catalog bridge, the catalog quickstart, the attached-page shortcut, replay shortcuts, or the next-step matrix.',
        'Use top_level_attached_html_catalog_quickstart when you want the shorter top-level attached-page quickstart plus the suite-catalog attached-page bridge kept visible together before the replay narrows into the attached-page shortcut, replay shortcuts, next-step matrix, bundle-first route, or safe-route helper.',
        'Use suite_catalog_attached_html_entrypoint when the replay is already narrowed to attached-page follow-up but you want the suite-catalog-side attached-page bridge kept visible before reopening the shorter attached-page shortcut, replay shortcuts, next-step matrix, bundle-first route, or safe-route helper.',
        'Use top_level_attached_html_entrypoint when the route is already clearly inside the issue-specific attached-page branch and you want the broader top-level attached-page bridge before the newer top-level quickstarts, replay shortcuts, or the next-step matrix.',
        'Use google_attached_html_entrypoint when you still want the issue-specific Google-shaped attached-page bridge kept visible before the smaller attached-page shortcut helper.',
        'Use attached_html_shortcut when you want the shortest attached-page bridge before widening back into replay_shortcuts, the next-step matrix, or the safe-route helper.',
        'Use contextual_flow when RepoRoot, SummaryPath, or fixed InputPath values already matter and you want the next helper surface to keep that replay context aligned before choosing between the attached-page bridges, replay shortcuts, the next-step matrix, the bundle-first route, or the safe-route helper.',
        'Use attached_bundle_change_area and attached_bundle_first when the current replay should stay pinned to the known three-page compatibility bundle before widening back into the broader Google-only helper chain.',
        'Use safe_route_entrypoints only after the attached-page route has already narrowed the replay enough that the wrapper-heavy issue #3 command surface is the next useful layer.',
        'Keep the validation-router attached-html quickstart note nearby when the replay is still one step higher in the broader validation router and you want that written bridge visible before the suite-router-side attached-page helper chain narrows the route again.',
        'Keep the attached-html change-area quickstart note nearby when the replay is already centered on show_headed_validation_suites.ps1 -ChangeArea attached-html and you still want the generic attached-page flow helper plus the narrower issue #3 route visible together.',
        'Keep the Windows full-use attached-html route note nearby when the replay started from docs/WINDOWS_FULL_USE.md and you want the broader runbook bridge preserved beside the suite-router attached-page quickstart.',
        'Keep the Windows full-use attached-html route note, the attached HTML quickstart note, the Windows replay quickstart note, the top-level attached-page quickstart note, the top-level attached-page catalog quickstart note, the top-level attached-page bridge note, the top-level companion note, the suite-catalog guide note, the suite-catalog attached-page bridge note, and the validation-chain note nearby when you want the written route beside these commands.'
    )
}

$helper.recommended_next_key = if ($helper.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($helper.repo_root) -or -not [string]::IsNullOrWhiteSpace($helper.summary_path)) {
    'contextual_flow'
} else {
    'top_level_attached_html_quickstart'
}
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader issue #3 attached-page helper chain.'
} elseif ($helper.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing between the attached-page bridges, replay shortcuts, the next-step matrix, the bundle-first route, or the safe-route helper.'
} else {
    'No pinned bundle inputs, non-default repo root, or saved summary are in play yet, so jump straight from the suite router into the shorter top-level attached-page quickstart and keep the attached localhost route compact before widening back out.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 suite-router attached HTML quickstart'
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
Write-Host 'Top-level suite-router entrypoints:'
Write-Host (("  Attached HTML:        {0}") -f $helper.commands.attached_html_change_area)
Write-Host (("  Google attached HTML: {0}") -f $helper.commands.google_attached_html_change_area)
Write-Host (("  Attached bundle:      {0}") -f $helper.commands.attached_bundle_change_area)
Write-Host ''
Write-Host 'Broader attached-page handoffs:'
Write-Host (("  Validation-router note:      {0}") -f $helper.commands.validation_router_attached_html_quickstart)
Write-Host (("  Change-area quickstart:      {0}") -f $helper.commands.attached_html_change_area_quickstart)
Write-Host (("  Attached-page flow helper:   {0}") -f $helper.commands.attached_html_flow)
Write-Host ''
Write-Host 'Attached-page follow-up helpers:'
Write-Host (("  Catalog entrypoints guide:    {0}") -f $helper.commands.suite_catalog_entrypoints)
Write-Host (("  Top-level quickstart:         {0}") -f $helper.commands.top_level_attached_html_quickstart)
Write-Host (("  Top-level catalog quickstart: {0}") -f $helper.commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  Catalog attached bridge:      {0}") -f $helper.commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  Top-level attached:           {0}") -f $helper.commands.top_level_attached_html_entrypoint)
Write-Host (("  Google attached bridge:       {0}") -f $helper.commands.google_attached_html_entrypoint)
Write-Host (("  Attached shortcut:            {0}") -f $helper.commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:             {0}") -f $helper.commands.replay_shortcuts)
Write-Host (("  Next-step matrix:             {0}") -f $helper.commands.suite_router_next_steps)
Write-Host (("  Contextual flow:              {0}") -f $helper.commands.contextual_flow)
Write-Host (("  Bundle-first helper:          {0}") -f $helper.commands.attached_bundle_first)
Write-Host (("  Safe-route map:               {0}") -f $helper.commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Validation-router note:   {0}") -f (' ' + $helper.validation_router_attached_html_quickstart_note_path))
Write-Host (("Change-area quickstart:   {0}") -f (' ' + $helper.attached_html_change_area_quickstart_note_path))
Write-Host (("Windows full-use route:   {0}") -f (' ' + $helper.windows_full_use_attached_html_route_note_path))
Write-Host (("Attached HTML note:       {0}") -f (' ' + $helper.attached_html_quickstart_note_path))
Write-Host (("Windows replay note:      {0}") -f (' ' + $helper.windows_replay_quickstart_note_path))
Write-Host (("Top-level quickstart:     {0}") -f (' ' + $helper.top_level_attached_html_quickstart_note_path))
Write-Host (("Top-level catalog note:   {0}") -f (' ' + $helper.top_level_attached_html_catalog_quickstart_note_path))
Write-Host (("Top-level attached note:  {0}") -f (' ' + $helper.top_level_attached_html_bridge_note_path))
Write-Host (("Top-level companion note: {0}") -f (' ' + $helper.top_level_attached_html_companion_note_path))
Write-Host (("Catalog guide note:       {0}") -f (' ' + $helper.suite_catalog_entrypoint_note_path))
Write-Host (("Catalog attached note:    {0}") -f (' ' + $helper.suite_catalog_attached_html_bridge_note_path))
Write-Host (("Validation chain note:    {0}") -f (' ' + $helper.validation_chain_note_path))
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
