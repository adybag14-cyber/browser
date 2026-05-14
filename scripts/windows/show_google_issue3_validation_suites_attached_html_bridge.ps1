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

$helper = [ordered]@{
    issue = 'Google issue #3 validation-suites attached HTML bridge'
    purpose = 'Keep the attached-page route visible directly from the top-level headed validation suites before the replay narrows into the newer issue #3 attached-page helpers.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    suite_router_entrypoint_guide_note_path = 'docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    top_level_commands = [ordered]@{
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
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $bundleArguments
    }
    helper_commands = [ordered]@{
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
    }
    notes = @(
        'Start here when the next local Windows replay should reopen from the top-level headed validation suites but the route is already leaning toward attached localhost HTML follow-up.',
        'Use google_recommended or google_input_change_area when the broader issue #3 validation ladder still needs to stay visible before the attached-page branch is chosen.',
        'Use attached_html_change_area when the route is already narrowed to the attached localhost compatibility lane and you want the shortest bridge back into the newer issue #3 attached-page helper chain.',
        'Use google_attached_html_change_area when the replay still needs the broader Google-shaped attached-page surface checker and flow helper kept visible before it narrows again.',
        'Use windows_full_use_attached_html_route when the replay is being reopened from docs/WINDOWS_FULL_USE.md first and you want that broader Windows runbook entrypoint preserved beside the attached-page helper chain.',
        'Use top_level_attached_html_quickstart as the default next helper when no pinned bundle inputs, non-default repo root, or saved summary need to take precedence, because it keeps the shortest top-level attached-page bridge visible before the route narrows into the broader top-level attached-page entrypoint, the suite-router quickstart, or the suite-catalog attached-page bridge.',
        'Use suite_router_attached_html_quickstart after the top-level attached-page bridge when you want the suite-router-side attached-page bridge printed before choosing between the suite-catalog attached-page helper, the broader Google attached-page helper, the attached-page shortcut, replay shortcuts, the next-step matrix, or the bundle-first branch.',
        'Use suite_catalog_attached_html_entrypoint after the suite-router attached-page quickstart when the route should stay visibly attached-page-first from the suite-catalog side before it narrows again.',
        'Use google_attached_html_entrypoint when the replay still needs the broader issue-specific attached-page surface visible before dropping into the shorter attached-page shortcut.',
        'Use attached_html_shortcut when the route is already clearly inside attached-page follow-up and you want the shortest bridge before widening into replay shortcuts, the next-step matrix, or the safe-route map.',
        'Use contextual_flow when RepoRoot, SummaryPath, or pinned bundle inputs already matter and the next helper surface should keep that replay context aligned before narrowing again.',
        'Use attached_bundle_first when explicit InputPath values are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only helper chain.',
        'Keep the suite-router entrypoint guide, top-level attached-page quickstart note, top-level attached-page bridge note, suite-router attached-page quickstart note, suite-catalog attached-page bridge note, Windows replay quickstart note, Windows full-use attached-page route note, and validation-chain note nearby when you want the written route beside these commands.'
    )
}

$helper.recommended_next_key = if ($helper.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($helper.repo_root) -or -not [string]::IsNullOrWhiteSpace($helper.summary_path)) {
    'contextual_flow'
} else {
    'top_level_attached_html_quickstart'
}
$helper.recommended_next_command = $helper.helper_commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($helper.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing between the compact attached-page quickstart, the suite-router quickstart, the suite-catalog helper, replay shortcuts, the next-step matrix, the bundle-first route, or the safe-route map.'
} else {
    'No pinned bundle inputs, non-default repo root, or saved summary are in play yet, so jump straight from the top-level validation suites into the compact top-level attached-page quickstart before narrowing into the broader attached-page helper chain.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 validation-suites attached HTML bridge'
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
Write-Host 'Top-level validation suite surfaces:'
Write-Host (("  Google recommended:   {0}") -f $helper.top_level_commands.google_recommended)
Write-Host (("  Google input:         {0}") -f $helper.top_level_commands.google_input_change_area)
Write-Host (("  Attached HTML:        {0}") -f $helper.top_level_commands.attached_html_change_area)
Write-Host (("  Google attached HTML: {0}") -f $helper.top_level_commands.google_attached_html_change_area)
Write-Host (("  Attached bundle:      {0}") -f $helper.top_level_commands.attached_bundle_change_area)
Write-Host (("  Windows full-use:     {0}") -f $helper.top_level_commands.windows_full_use_attached_html_route)
Write-Host ''
Write-Host 'Attached-page bridge sequence:'
Write-Host (("  1. Top-level quickstart:   {0}") -f $helper.helper_commands.top_level_attached_html_quickstart)
Write-Host (("  2. Top-level bridge:       {0}") -f $helper.helper_commands.top_level_attached_html_entrypoint)
Write-Host (("  3. Router quickstart:      {0}") -f $helper.helper_commands.suite_router_attached_html_quickstart)
Write-Host (("  4. Catalog attached bridge:{0}") -f (' ' + $helper.helper_commands.suite_catalog_attached_html_entrypoint))
Write-Host (("  5. Google attached bridge: {0}") -f $helper.helper_commands.google_attached_html_entrypoint)
Write-Host (("  6. Attached shortcut:      {0}") -f $helper.helper_commands.attached_html_shortcut)
Write-Host (("  7. Replay shortcuts:       {0}") -f $helper.helper_commands.replay_shortcuts)
Write-Host (("  8. Next-step matrix:       {0}") -f $helper.helper_commands.suite_router_next_steps)
Write-Host (("  9. Contextual flow:        {0}") -f $helper.helper_commands.contextual_flow)
Write-Host ((" 10. Bundle first:           {0}") -f $helper.helper_commands.attached_bundle_first)
Write-Host ((" 11. Safe-route map:         {0}") -f $helper.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Suite-router guide:         {0}") -f $helper.suite_router_entrypoint_guide_note_path)
Write-Host (("Top-level quickstart note:  {0}") -f $helper.top_level_attached_html_quickstart_note_path)
Write-Host (("Top-level bridge note:      {0}") -f $helper.top_level_attached_html_bridge_note_path)
Write-Host (("Router quickstart note:     {0}") -f $helper.suite_router_attached_html_quickstart_note_path)
Write-Host (("Catalog bridge note:        {0}") -f $helper.suite_catalog_attached_html_bridge_note_path)
Write-Host (("Windows replay note:        {0}") -f $helper.windows_replay_quickstart_note_path)
Write-Host (("Windows full-use route note:{0}") -f (' ' + $helper.windows_full_use_attached_html_route_note_path))
Write-Host (("Validation chain note:      {0}") -f $helper.validation_chain_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
