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

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$helper = [ordered]@{
    issue = 'Google issue #3 suite-router quickstart'
    purpose = 'Print the shortest bridge from the top-level headed validation suite router into the current issue #3 validation-router attached HTML quickstart, top-level shortcut-first entrypoint, top-level attached HTML bridge, suite-router attached HTML quickstart, top-level attached HTML quickstart, top-level attached HTML catalog quickstart, suite-catalog attached HTML, issue-specific attached HTML suite entrypoint, attached-HTML shortcut, replay-shortcuts, attached-bundle, and safe-route helpers, while preserving repo-root, saved-summary, and pinned attached-bundle context when it already exists.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    replay_quickstart_shortcut_bridge_note_path = 'docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md'
    suite_router_entrypoint_note_path = 'docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    validation_router_attached_html_quickstart_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    safe_route_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    commands = [ordered]@{
        google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        google_input = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        attached_html_suite = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html_suite = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_suite = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_shortcut_first = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        top_level_attached_html = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        suite_catalog_attached_html = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
    }
    notes = @(
        'Start with google_recommended or google_input when you are re-entering issue #3 from the top-level headed validation suite catalog and want the same router commands that the higher-level catalog prints.',
        'Use attached_html_suite when the next replay is already narrowed to attached-page compatibility follow-up and you want that top-level route reprinted before dropping into the validation-router attached-page quickstart or the shorter issue-specific helper chain.',
        'Use google_attached_html_suite when the next replay is already narrowed to the issue-specific attached-page follow-up route and you want that dedicated suite-router entrypoint visible before choosing between the validation-router attached-page quickstart, the top-level attached-page bridge, the suite-router attached-page quickstart, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, the attached-page shortcut, replay shortcuts, the next-step matrix, or the bundle-first route.',
        'Use validation_router_attached_html_quickstart when the replay is already entering from the broader validation-router attached-page route and you want that bridge kept visible before narrowing into the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, the attached-page shortcut, replay shortcuts, the next-step matrix, or the bundle-first route.',
        'Use top_level_shortcut_first when the top-level suite router already made issue #3 obvious and you want the shorter top-level shortcut bridge kept visible beside the attached localhost quickstarts before the route narrows further.',
        'Use top_level_attached_html when the replay is already narrowed to attached-page follow-up and you want the broader top-level attached-page bridge kept visible before choosing between the validation-router attached-page quickstart, the suite-router attached-page quickstart, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, the attached-page shortcut, replay shortcuts, the next-step matrix, the bundle-first route, or the safe-route helper.',
        'Use suite_router_attached_html_quickstart as the default next helper when no pinned bundle inputs, non-default repo root, or saved summary need to take precedence, because it keeps the shortest suite-router-side attached-page bridge visible before narrowing into the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, the attached-page shortcut, replay shortcuts, the next-step matrix, or the safe-route helper.',
        'Use top_level_attached_html_quickstart when the replay is already narrowed to attached-page follow-up from the top-level suite router and you want the shorter top-level attached-page quickstart kept visible before reopening the top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, the attached-page shortcut, replay shortcuts, the next-step matrix, the bundle-first route, or the safe-route helper.',
        'Use top_level_attached_html_catalog_quickstart when you want the shorter top-level attached-page quickstart and the suite-catalog attached-page bridge kept visible together before the replay narrows into the attached-page shortcut, replay shortcuts, the next-step matrix, the bundle-first route, or the safe-route helper.',
        'Use suite_catalog_attached_html when the replay is already narrowed to attached-page follow-up but you want the suite-catalog-side attached-page bridge kept visible before reopening the shorter attached-page shortcut, replay shortcuts, next-step matrix, bundle-first route, or safe-route helper.',
        'Use attached_html_shortcut immediately after the top-level commands, the validation-router attached-page quickstart, the suite-router attached-page quickstart, the top-level attached-page bridge, the top-level attached-page quickstart, or the top-level attached-page catalog quickstart when the route is already clearly inside issue #3 and no pinned bundle inputs, saved summary, or non-default repo root need to take precedence first.',
        'Use suite_router_next_steps when the route still needs the compact matrix before you choose between replay shortcuts, the validation-router attached-page quickstart, the top-level attached-page bridge, the suite-router attached-page quickstart, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, the attached-page shortcut, contextual flow, attached bundle, or the wrapper-heavy safe path.',
        'Use contextual_flow when RepoRoot, SummaryPath, or fixed InputPath values already matter and you want the next helper surface to keep that context aligned before narrowing further.',
        'Use attached_bundle_suite when the current replay should stay pinned to the known three-page compatibility bundle from the top-level suite router itself.',
        'Use attached_bundle_first when explicit input paths are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only issue #3 helpers.',
        'Use safe_route_entrypoints after the shortcut-first bridge, validation-router attached-page quickstart, top-level attached-page bridge, suite-router attached-page quickstart, top-level attached-page quickstart, top-level attached-page catalog quickstart, suite-catalog attached-page bridge, next-step matrix, attached-page shortcut, or contextual flow helper when you want the current wrapper-heavy issue #3 commands and state helpers surfaced in one place.',
        'Keep the quickstart, replay quickstart shortcut bridge, suite-router entrypoint guide, suite-router shortcut bridge, validation-router attached HTML quickstart note, suite-router attached HTML quickstart, suite-catalog attached HTML bridge, top-level attached HTML bridge, top-level attached HTML quickstart, top-level attached HTML catalog quickstart, and safe-route note nearby when you want the written route beside these commands.'
    )
}

$helper.recommended_next_key = if ($helper.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($helper.repo_root) -or -not [string]::IsNullOrWhiteSpace($helper.summary_path)) {
    'contextual_flow'
} else {
    'suite_router_attached_html_quickstart'
}
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($helper.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so open the context-preserving helper next and keep that replay state aligned before choosing between replay shortcuts, the validation-router attached-page quickstart, the top-level attached-page bridge, the suite-router attached-page quickstart, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog attached-page bridge, the attached-page shortcut, the next-step matrix, the bundle-first route, or the safe-route helper.'
} else {
    'No pinned bundle inputs, non-default repo root, or saved summary are in play yet, so jump straight from the suite router into the attached-page quickstart and keep the shorter attached-page bridge visible before widening back out.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 suite-router quickstart'
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
Write-Host 'Top-level entrypoints:'
Write-Host (("  Google recommended:   {0}") -f $helper.commands.google_recommended)
Write-Host (("  Google input:         {0}") -f $helper.commands.google_input)
Write-Host (("  Attached HTML:        {0}") -f $helper.commands.attached_html_suite)
Write-Host (("  Google attached HTML: {0}") -f $helper.commands.google_attached_html_suite)
Write-Host (("  Attached bundle:      {0}") -f $helper.commands.attached_bundle_suite)
Write-Host ''
Write-Host 'Follow-up helpers:'
Write-Host (("  Validation-router:    {0}") -f $helper.commands.validation_router_attached_html_quickstart)
Write-Host (("  Top-level shortcut:    {0}") -f $helper.commands.top_level_shortcut_first)
Write-Host (("  Top-level attached:    {0}") -f $helper.commands.top_level_attached_html)
Write-Host (("  Router attached quick: {0}") -f $helper.commands.suite_router_attached_html_quickstart)
Write-Host (("  Top-level quickstart:  {0}") -f $helper.commands.top_level_attached_html_quickstart)
Write-Host (("  Catalog quickstart:    {0}") -f $helper.commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  Catalog attached:      {0}") -f $helper.commands.suite_catalog_attached_html)
Write-Host (("  Attached shortcut:     {0}") -f $helper.commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:      {0}") -f $helper.commands.replay_shortcuts)
Write-Host (("  Next-step matrix:      {0}") -f $helper.commands.suite_router_next_steps)
Write-Host (("  Contextual flow:       {0}") -f $helper.commands.contextual_flow)
Write-Host (("  Safe-route helper:     {0}") -f $helper.commands.safe_route_entrypoints)
Write-Host (("  Bundle-first helper:   {0}") -f $helper.commands.attached_bundle_first)
Write-Host ''
Write-Host (("Quickstart note:       {0}") -f $helper.quickstart_note_path)
Write-Host (("Replay-shortcut note:  {0}") -f $helper.replay_quickstart_shortcut_bridge_note_path)
Write-Host (("Entrypoint guide:      {0}") -f $helper.suite_router_entrypoint_note_path)
Write-Host (("Shortcut bridge note:  {0}") -f $helper.suite_router_bridge_note_path)
Write-Host (("Validation-router:     {0}") -f $helper.validation_router_attached_html_quickstart_note_path)
Write-Host (("Router-attached note:  {0}") -f $helper.suite_router_attached_html_quickstart_note_path)
Write-Host (("Catalog-attached note: {0}") -f $helper.suite_catalog_attached_html_bridge_note_path)
Write-Host (("Top-level-attached:    {0}") -f $helper.top_level_attached_html_bridge_note_path)
Write-Host (("Top-level-quickstart:  {0}") -f $helper.top_level_attached_html_quickstart_note_path)
Write-Host (("Catalog-quickstart:    {0}") -f $helper.top_level_attached_html_catalog_quickstart_note_path)
Write-Host (("Safe-route note:       {0}") -f $helper.safe_route_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
