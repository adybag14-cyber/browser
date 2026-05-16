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

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $attachedHtmlFlowArguments["InputPath"] = @($InputPath)
}

$googleAttachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $googleAttachedHtmlFlowArguments["InputPath"] = @($InputPath)
}

$entrypoint = [ordered]@{
    issue = 'Google issue #3 top-level shortcut-first entrypoint'
    purpose = 'Print the shortest top-level route from the headed validation suite catalog into the newer issue #3 suite-router shortcut entrypoint, the broader attached-page flow helper, the dedicated Google-shaped attached-page flow helper, the replay-side attached-page quickstart, the newer top-level attached-page quickstart, the newer top-level attached-page catalog quickstart, the newer suite-catalog-to-top-level attached-page catalog quickstart, and the newer suite-router attached-page quickstart, while also surfacing the attached-page compatibility branch, the suite-catalog attached-page bridge, and preserving repo-root, saved-summary, and pinned bundle-input context when it is already in play.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
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
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        suite_catalog_top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $bundleArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_handoff = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
    }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    replay_discovery_note_path = 'docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md'
    top_level_shortcut_first_entrypoint_note_path = 'docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md'
    top_level_shortcut_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_catalog_top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    attached_html_target_bundle_reference_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    notes = @(
        'Use this helper when the top-level headed validation suite catalog has already narrowed the route to issue #3 and you want the shortcut-first path printed without reopening the broader suite-catalog or replay-route surfaces first.',
        'Start with google_recommended when you want the broader localhost-first issue #3 runner named before the route narrows into the shortcut-first entrypoint.',
        'Start with google_input_change_area when the next replay is already known to stay inside issue #3 and you want the same top-level helper family reprinted before dropping into the suite-router shortcut entrypoint.',
        'Start with attached_html_change_area when the next replay should still come from the generic attached-page compatibility route before you jump into the broader attached-page flow helper, the replay-side attached-page quickstart, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, the suite-router attached-page quickstart, or the shortcut-first issue #3 bridge.',
        'Use attached_html_flow when you want the broader attached-page helper surface printed directly from this top-level shortcut-first bridge before narrowing into the replay-side attached-page quickstart, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, the suite-router attached-page quickstart, or the shortcut-first issue #3 bridge.',
        'Start with google_attached_html_change_area when the next replay should still come from the Google-shaped attached-page route before you jump into the shorter issue #3 helper chain.',
        'Use google_attached_html_flow when the replay still needs the broader Google-shaped attached-page surface checker and helper flow printed directly from this top-level shortcut-first bridge before it narrows into the replay-side attached-page quickstart, the top-level attached-page quickstart, the suite-router attached-page quickstart, the suite-catalog attached-page bridge, or the shorter issue #3 helpers.',
        'Use suite_catalog_attached_html_entrypoint when the replay is already entering issue #3 from the attached-page route and you want the dedicated suite-catalog attached-page bridge printed after the replay-side attached-page quickstart, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, or the suite-router attached-page quickstart before you narrow into the issue-specific attached-page or shortcut-first helpers.',
        'Start with attached_bundle_change_area when the current saved or attached pages are still the known three-page compatibility bundle and you want that pinned branch reprinted from the top-level suite router first.',
        'Use suite_router_shortcut_entrypoint as the default next helper whenever no pinned bundle inputs need to take precedence, because it keeps the shortest bridge from the top-level suite catalog into the broader attached-page flow helper, the dedicated Google-shaped attached-page flow helper, the replay-side attached-page quickstart, the newer top-level attached-page quickstart, the newer catalog quickstarts, replay_shortcuts, attached_html_shortcut, contextual_flow, the next-step matrix, and the broader compact helpers.',
        'Use windows_replay_attached_html_quickstart when the route is already narrowing into attached localhost follow-up and you want the replay-side attached-page quickstart visible before the broader attached-page flow helper, the dedicated Google-shaped attached-page flow helper, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, or the suite-router attached-page quickstart.',
        'Use top_level_attached_html_quickstart when the route is already narrowing from the top-level suite router into attached localhost follow-up and you want that shorter attached-page bridge visible before the broader attached-page flow helper, the dedicated Google-shaped attached-page flow helper, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, the suite-router attached-page quickstart, the suite-catalog attached-page bridge, or the broader shortcut-first helper.',
        'Use top_level_attached_html_catalog_quickstart when you want the compact top-level attached-page bridge and the suite-catalog attached-page bridge kept visible together before the route narrows into the suite-catalog-to-top-level attached-page catalog quickstart, the issue-specific attached-page bridge, attached_html_shortcut, replay_shortcuts, the next-step matrix, or the safe-route map.',
        'Use suite_catalog_top_level_attached_html_catalog_quickstart when the suite-catalog surface should stay visible beside the replay-side attached-html ladder, the dedicated Google-shaped attached-page flow helper, and the top-level catalog quickstart before the route drops into the suite-catalog attached-page bridge or the narrower attached-page helpers.',
        'Use suite_router_attached_html_quickstart when the route is already inside attached localhost follow-up and you want the suite-router-side attached-page bridge reprinted before dropping into the broader attached-page flow helper, the dedicated Google-shaped attached-page flow helper, the suite-catalog attached-page bridge, attached_html_shortcut, replay_shortcuts, or the next-step matrix.',
        'Use attached_html_shortcut when the replay is already narrowed to attached-page follow-up and you want the broader attached-page compatibility branch kept visible before you widen back into replay_shortcuts, the next-step matrix, or the safe-route map.',
        'Use attached_bundle_first instead when explicit InputPath values are already pinned and the replay should stay on the known three-page compatibility set before widening back into the broader Google-only helpers.',
        'Use replay_shortcuts after the suite-router shortcut entrypoint, the replay-side attached-page quickstart, the top-level attached-page quickstart, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, or the suite-router attached-page quickstart when the route is already known to stay inside issue #3 and no saved summary, repo-root override, or pinned bundle inputs need to stay visible first.',
        'Keep the quickstart note, the replay-side attached-page quickstart note, the replay-discovery note, the top-level shortcut-first entrypoint note, the top-level shortcut bridge note, the top-level attached-page quickstart note, the top-level attached-page catalog quickstart note, the suite-catalog-to-top-level attached-page catalog quickstart note, the suite-router attached-page quickstart note, the suite-router bridge, the suite-catalog guide, the suite-catalog attached-html bridge, the dedicated Google-shaped attached-page flow note, the attached-html target bundle reference note, and the validation-chain notes nearby when you want the written route beside these commands.'
    )
}

$entrypoint.recommended_next_key = if ($entrypoint.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} else {
    'suite_router_shortcut_entrypoint'
}
$entrypoint.recommended_next_command = $entrypoint.helper_commands[$entrypoint.recommended_next_key]
$entrypoint.recommended_next_reason = if ($entrypoint.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader Google-only issue #3 path.'
} else {
    'No pinned bundle inputs are in play yet, so jump straight from the top-level suite router into the newer suite-router shortcut entrypoint while keeping the broader attached-page flow helper, the dedicated Google-shaped attached-page flow helper, the replay-side attached-page quickstart, the newer top-level attached-page quickstart, the newer catalog quickstarts, and the attached-page quickstarts nearby when the replay narrows into attached localhost follow-up.'
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 top-level shortcut-first entrypoint'
Write-Host ''
if ($entrypoint.repo_root) {
    Write-Host (("Repo root:   {0}") -f $entrypoint.repo_root)
}
if ($entrypoint.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($entrypoint.summary_path)"))
}
if ($entrypoint.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $entrypoint.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $entrypoint.recommended_next_command)
Write-Host (("Why:                    {0}") -f $entrypoint.recommended_next_reason)
Write-Host ''
Write-Host 'Top-level suite-router bridge:'
Write-Host (("  1. Google recommended:        {0}") -f $entrypoint.top_level_commands.google_recommended)
Write-Host (("  2. Google input:              {0}") -f $entrypoint.top_level_commands.google_input_change_area)
Write-Host (("  3. Attached HTML:             {0}") -f $entrypoint.top_level_commands.attached_html_change_area)
Write-Host (("  4. Google attached HTML:      {0}") -f $entrypoint.top_level_commands.google_attached_html_change_area)
Write-Host (("  5. Attached bundle:           {0}") -f $entrypoint.top_level_commands.attached_bundle_change_area)
Write-Host (("  6. Attached flow:             {0}") -f $entrypoint.top_level_commands.attached_html_flow)
Write-Host (("  7. Google attached flow:      {0}") -f $entrypoint.top_level_commands.google_attached_html_flow)
Write-Host (("  8. Google flow:               {0}") -f $entrypoint.top_level_commands.google_flow)
Write-Host (("  9. Shortcut entry:            {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host ((" 10. Windows replay quick:      {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)
Write-Host ((" 11. Top-level attached quick:  {0}") -f $entrypoint.helper_commands.top_level_attached_html_quickstart)
Write-Host ((" 12. Top-level catalog quick:   {0}") -f $entrypoint.helper_commands.top_level_attached_html_catalog_quickstart)
Write-Host ((" 13. Catalog-to-top-level qk:   {0}") -f $entrypoint.helper_commands.suite_catalog_top_level_attached_html_catalog_quickstart)
Write-Host ((" 14. Router attached quick:     {0}") -f $entrypoint.helper_commands.suite_router_attached_html_quickstart)
Write-Host ((" 15. Attached shortcut:         {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host ((" 16. Replay shortcuts:          {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host ((" 17. Next-step matrix:          {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host ((" 18. Suite-catalog:             {0}") -f $entrypoint.helper_commands.suite_catalog_entrypoints)
Write-Host ((" 19. Catalog attached:          {0}") -f $entrypoint.helper_commands.suite_catalog_attached_html_entrypoint)
Write-Host ''
Write-Host 'Companion helpers:'
Write-Host (("  Shortcut entrypoint:    {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host (("  Attached flow helper:   {0}") -f $entrypoint.top_level_commands.attached_html_flow)
Write-Host (("  Google attached flow:   {0}") -f $entrypoint.top_level_commands.google_attached_html_flow)
Write-Host (("  Windows replay quick:   {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)
Write-Host (("  Top-level attached:     {0}") -f $entrypoint.helper_commands.top_level_attached_html_quickstart)
Write-Host (("  Top-level catalog qk:   {0}") -f $entrypoint.helper_commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  Catalog-to-top-level qk:{0}") -f (' ' + $entrypoint.helper_commands.suite_catalog_top_level_attached_html_catalog_quickstart))
Write-Host (("  Router attached:        {0}") -f $entrypoint.helper_commands.suite_router_attached_html_quickstart)
Write-Host (("  Attached shortcut:      {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:       {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host (("  Contextual flow:        {0}") -f $entrypoint.helper_commands.contextual_flow)
Write-Host (("  Next-step matrix:       {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host (("  Suite-catalog:          {0}") -f $entrypoint.helper_commands.suite_catalog_entrypoints)
Write-Host (("  Catalog attached:       {0}") -f $entrypoint.helper_commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  Suite-router handoff:   {0}") -f $entrypoint.helper_commands.suite_router_handoff)
Write-Host (("  Replay route:           {0}") -f $entrypoint.helper_commands.replay_route)
Write-Host (("  Bundle first:           {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host (("  Safe-route map:         {0}") -f $entrypoint.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Quickstart note:                {0}") -f $entrypoint.quickstart_note_path)
Write-Host (("Windows replay attached note:   {0}") -f (' ' + $entrypoint.windows_replay_attached_html_quickstart_note_path))
Write-Host (("Replay discovery:               {0}") -f $entrypoint.replay_discovery_note_path)
Write-Host (("Shortcut-first entry note:      {0}") -f (' ' + $entrypoint.top_level_shortcut_first_entrypoint_note_path))
Write-Host (("Shortcut bridge note:           {0}") -f (' ' + $entrypoint.top_level_shortcut_bridge_note_path))
Write-Host (("Top-level attached note:        {0}") -f (' ' + $entrypoint.top_level_attached_html_quickstart_note_path))
Write-Host (("Top-level catalog quickstart:   {0}") -f (' ' + $entrypoint.top_level_attached_html_catalog_quickstart_note_path))
Write-Host (("Catalog-to-top-level qk note:   {0}") -f (' ' + $entrypoint.suite_catalog_top_level_attached_html_catalog_quickstart_note_path))
Write-Host (("Router attached note:           {0}") -f (' ' + $entrypoint.suite_router_attached_html_quickstart_note_path))
Write-Host (("Suite-router bridge:            {0}") -f $entrypoint.suite_router_bridge_note_path)
Write-Host (("Suite-catalog guide:            {0}") -f $entrypoint.suite_catalog_entrypoint_note_path)
Write-Host (("Catalog-attached note:          {0}") -f (' ' + $entrypoint.suite_catalog_attached_html_bridge_note_path))
Write-Host (("Google attached flow note:      {0}") -f (' ' + $entrypoint.google_attached_html_validation_flow_note_path))
Write-Host (("Bundle reference note:          {0}") -f (' ' + $entrypoint.attached_html_target_bundle_reference_note_path))
Write-Host (("Validation chain:               {0}") -f $entrypoint.validation_chain_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}
