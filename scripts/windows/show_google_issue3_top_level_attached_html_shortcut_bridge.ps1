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

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$bridge = [ordered]@{
    issue = 'Google issue #3 top-level attached HTML shortcut bridge'
    purpose = 'Keep the shortest top-level attached-page bridge and the newer issue #3 attached-page quickstarts visible on one compact helper surface before the replay widens back into the larger router or safe-route chain.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    top_level_commands = [ordered]@{
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
        fresh_safe_route_replay = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments $sharedArguments
        reuse_current_outputs = Format-HelperCommand -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments $sharedArguments
    }
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    notes = @(
        'Start with attached_html_change_area when the top-level headed validation router is already narrowed to the generic attached localhost compatibility route and you want that surface reprinted before dropping into the compact issue #3 helpers.',
        'Use google_attached_html_change_area when the replay still needs the Google-shaped attached-page route visible before narrowing again.',
        'Use top_level_attached_html_quickstart when you want the shortest top-level attached-page bridge before you decide between the suite-router quickstart, the broader top-level attached-page bridge, the attached-page shortcut, replay shortcuts, the next-step matrix, or the bundle-first branch.',
        'Use suite_router_attached_html_quickstart as the default next helper when no bundle inputs are pinned and no saved summary or repo-root override needs to take precedence, because it keeps the shorter issue #3 attached-page bridge visible before you widen back out.',
        'Use top_level_attached_html_entrypoint when you want the broader top-level attached-page bridge re-opened before the replay narrows back into the shortcut surfaces.',
        'Use attached_html_shortcut when the route is already clearly inside attached-page follow-up and you want the shortest issue-specific bridge before widening into replay shortcuts, the next-step matrix, or the safe-route map.',
        'Use attached_bundle_change_area or attached_bundle_first when the current pages are still the known three-page compatibility bundle and that pinned branch should stay visible before widening back into the broader Google-only helper chain.',
        'Use contextual_flow when RepoRoot or SummaryPath is already in play and the next helper surface should keep that replay context aligned while you choose between the compact attached-page quickstarts, replay shortcuts, the next-step matrix, or the safe-route helpers.',
        'Use fresh_safe_route_replay when current outputs may be stale or missing. Use reuse_current_outputs only when a saved SummaryPath already exists and those outputs are still trusted.',
        'Keep the Windows full-use attached-html route note, the top-level attached-page quickstart note, the suite-router attached-page quickstart note, the top-level attached-page bridge note, the Windows replay quickstart note, and the validation-chain note nearby when you want the written route beside these commands.'
    )
}

$bridge.recommended_next_key = if ($bridge.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($bridge.repo_root) -or -not [string]::IsNullOrWhiteSpace($bridge.summary_path)) {
    'contextual_flow'
} else {
    'suite_router_attached_html_quickstart'
}
$bridge.recommended_next_command = $bridge.helper_commands[$bridge.recommended_next_key]
$bridge.recommended_next_reason = if ($bridge.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($bridge.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing between the compact attached-page quickstarts, replay shortcuts, the next-step matrix, the bundle-first branch, or the safe-route helpers.'
} else {
    'No pinned bundle inputs, saved summary, or non-default repo root are in play yet, so jump straight from the top-level attached-page route into the suite-router attached-page quickstart.'
}

if ($Json) {
    $bridge | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 top-level attached HTML shortcut bridge'
Write-Host ''
if ($bridge.repo_root) {
    Write-Host (("Repo root:   {0}") -f $bridge.repo_root)
}
if ($bridge.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($bridge.summary_path)"))
}
if ($bridge.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $bridge.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $bridge.recommended_next_command)
Write-Host (("Why:                    {0}") -f $bridge.recommended_next_reason)
Write-Host ''
Write-Host 'Top-level attached-page routes:'
Write-Host (("  Attached HTML:        {0}") -f $bridge.top_level_commands.attached_html_change_area)
Write-Host (("  Google attached HTML: {0}") -f $bridge.top_level_commands.google_attached_html_change_area)
Write-Host (("  Attached bundle:      {0}") -f $bridge.top_level_commands.attached_bundle_change_area)
Write-Host ''
Write-Host 'Compact bridge helpers:'
Write-Host (("  Top-level quickstart:   {0}") -f $bridge.helper_commands.top_level_attached_html_quickstart)
Write-Host (("  Router quickstart:      {0}") -f $bridge.helper_commands.suite_router_attached_html_quickstart)
Write-Host (("  Top-level bridge:       {0}") -f $bridge.helper_commands.top_level_attached_html_entrypoint)
Write-Host (("  Attached shortcut:      {0}") -f $bridge.helper_commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:       {0}") -f $bridge.helper_commands.replay_shortcuts)
Write-Host (("  Next-step matrix:       {0}") -f $bridge.helper_commands.suite_router_next_steps)
Write-Host (("  Contextual flow:        {0}") -f $bridge.helper_commands.contextual_flow)
Write-Host (("  Bundle-first helper:    {0}") -f $bridge.helper_commands.attached_bundle_first)
Write-Host (("  Safe-route map:         {0}") -f $bridge.helper_commands.safe_route_entrypoints)
Write-Host (("  Fresh safe replay:      {0}") -f $bridge.helper_commands.fresh_safe_route_replay)
Write-Host (("  Reuse current outputs:  {0}") -f $bridge.helper_commands.reuse_current_outputs)
Write-Host ''
Write-Host (("Windows full-use route:   {0}") -f $bridge.windows_full_use_attached_html_route_note_path)
Write-Host (("Top-level quickstart:     {0}") -f $bridge.top_level_attached_html_quickstart_note_path)
Write-Host (("Suite-router quickstart:  {0}") -f $bridge.suite_router_attached_html_quickstart_note_path)
Write-Host (("Top-level bridge note:    {0}") -f $bridge.top_level_attached_html_bridge_note_path)
Write-Host (("Windows replay note:      {0}") -f $bridge.windows_replay_quickstart_note_path)
Write-Host (("Validation chain note:    {0}") -f $bridge.validation_chain_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $bridge.notes) {
    Write-Host (("- {0}") -f $note)
}
