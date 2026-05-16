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
            if ($entry.Value -is [System.Array]) {
                Add-SharedPathArrayArgument -Arguments $fallbackArguments -Name $entry.Key -Values $entry.Value
            } else {
                Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $entry.Value
            }
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
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$googleAttachedHtmlFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $googleAttachedHtmlFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $googleAttachedHtmlFlowArguments -Name InputPath -Values $InputPath

$entrypoint = [ordered]@{
    issue = 'Google issue #3 suite-catalog attached-html entrypoint'
    purpose = 'Keep the attached-page follow-up route visible directly from the issue #3 suite-catalog surface before it narrows through the fail-fast suite-catalog and replay-side validation checks, the current Windows replay attached-page quickstart, the broader attached-page flow helper, the top-level attached-page quickstarts, the shorter suite-router attached-page bridge, the Google attached-html validation flow, the compact bundle-suite surface helper, the issue-specific attached-page shortcut, the contextual-flow branch, the bundle-aware helpers, and the later safe-route map.'
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
    }
    helper_commands = [ordered]@{
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $bundleArguments
        suite_catalog_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1' -RepoRootOverride $RepoRoot
        top_level_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        windows_replay_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -RepoRootOverride $RepoRoot
        windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        google_attached_html_validation_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        attached_html_target_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
    }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    validation_router_attached_html_quickstart_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_catalog_top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    top_level_attached_html_companion_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
    attached_html_target_bundle_reference_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
    attached_html_target_bundle_suite_surface_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    notes = @(
        'Use this helper when the issue #3 suite-catalog surface already has your attention and the next replay needs the attached-page route kept visible before you drop into the narrower shortcut-first helper chain.',
        'Start with attached_html_change_area when the next replay should still come from the broader attached-page compatibility route before it narrows into issue-specific attached-page follow-up.',
        'Start with google_attached_html_change_area when the next replay is already narrowed to the issue-specific attached-page route but the broader suite-catalog commands still need to stay visible on the same surface.',
        'Use suite_catalog_surface_check right after suite_catalog_entrypoints when the suite-catalog guide, delegated helpers, or note paths may have drifted and you want the route to fail fast before it narrows into the attached-page ladder.',
        'Use validation_router_attached_html_quickstart when the replay is still re-entering from show_headed_validation_suites.ps1 -ChangeArea attached-html or the broader Windows full-use attached-page route and you want the shorter router-side bridge visible before the replay-side Windows attached-page quickstart.',
        'Use windows_replay_attached_html_surface_check after the validation-router attached-page quickstart when the replay-side quickstart or its linked helpers may have drifted and you want that narrower ladder to fail fast before it drops into the top-level attached-page helpers.',
        'Use windows_replay_attached_html_quickstart after the replay-side surface check when the route should still match the newer Windows replay attached-html ladder before it drops into the broader attached-page flow helper and the top-level attached-page helpers.',
        'Use attached_html_flow after the replay-side quickstart when the broader attached-page localhost helper should stay visible before the route narrows through the top-level attached-page helpers, the suite-router attached-page bridge, the compact bundle-suite helper, or the Google attached-page branch.',
        'Use top_level_attached_html_quickstart, top_level_attached_html_entrypoint, and top_level_attached_html_catalog_quickstart as the default middle of the ladder so the shorter top-level attached-page route stays visible before you drop into the suite-router attached-page bridge, the issue-specific attached-page shortcut, the compact bundle-suite helper, or the bundle-first branch.',
        'Use suite_router_attached_html_quickstart as the default next helper when explicit InputPath values are not already pinned and no saved replay context needs to take precedence first, because it keeps the shorter suite-router attached-page bridge visible after the suite-catalog surface check, the replay-side surface check, the Windows replay quickstart, the broader attached-page flow helper, and the top-level attached-page helpers.',
        'Use google_attached_html_entrypoint after the suite_router_attached_html_quickstart when the issue-specific attached-page bridge should stay visible before the replay narrows to the Google attached-html validation flow, the compact bundle-suite helper, the attached_html_shortcut, or widens back into replay_shortcuts and the next-step matrix.',
        'Use google_attached_html_validation_flow after the issue-specific attached-page entrypoint when the broader Google-style attached-page note and helper should stay visible before the route drops into attached_html_shortcut, replay_shortcuts, the next-step matrix, the compact bundle-suite helper, or the bundle-first branch.',
        'Use attached_html_shortcut after the Google attached-html validation flow when you want the shortest bridge into replay_shortcuts, the next-step matrix, the contextual-flow branch, the compact bundle-suite helper, or the bundle-first branch.',
        'Use attached_bundle_change_area, attached_html_target_bundle_suite_surface, or attached_bundle_first when the current saved or attached pages are already the known three-page compatibility bundle and that pinned branch should stay visible before widening back into the broader Google-only issue #3 helpers.',
        'Use top_level_shortcut_entrypoint when the broader top-level issue #3 bridge still needs to stay visible before you narrow into the attached-page helper chain.',
        'Use suite_router_shortcut_entrypoint after the attached-page helper chain when the route is already known to stay inside issue #3 and no extra suite-catalog explanation is needed first.',
        'Use contextual_flow instead when RepoRoot or SummaryPath is already in play and the next helper surface should keep that replay context aligned while you choose between the suite-router attached-page bridge, the issue-specific attached-page bridge, replay_shortcuts, the next-step matrix, the compact bundle-suite helper, the bundle-first branch, or the safe-route map.',
        'Use safe_route_entrypoints only after the attached-page route has already narrowed the current replay into the wrapper-heavy issue #3 branch, and keep the same SummaryPath and InputPath values attached when they are already pinned.',
        'Keep the quickstart note, the Windows replay attached-page quickstart note, the validation-router attached-page quickstart note, the top-level attached-page quickstart note, the top-level attached-page bridge note, the top-level attached-page catalog quickstart note, the suite-catalog-to-top-level attached-page catalog quickstart note, the top-level attached-page companion note, the suite-router attached-page quickstart note, the Google attached-html validation-flow note, the suite-router bridge note, the suite-catalog attached-page bridge note, the suite-catalog guide, the attached-bundle reference note, the attached-bundle suite-surface note, and the validation-chain note nearby when you want the written route beside these commands.'
    )
}

$entrypoint.recommended_next_key = if ($entrypoint.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($entrypoint.repo_root) -or -not [string]::IsNullOrWhiteSpace($entrypoint.summary_path)) {
    'contextual_flow'
} else {
    'suite_router_attached_html_quickstart'
}
$entrypoint.recommended_next_command = $entrypoint.helper_commands[$entrypoint.recommended_next_key]
$entrypoint.recommended_next_reason = if ($entrypoint.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so stay on the known three-page compatibility bundle before widening back into the broader Google-only issue #3 helper chain.'
} elseif ($entrypoint.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing between the suite-router attached-page bridge, the issue-specific attached-page bridge, replay shortcuts, the next-step matrix, the compact bundle-suite helper, the bundle-first branch, or the safe-route map.'
} else {
    'No explicit bundle inputs or saved replay context are pinned yet, so jump from the suite-catalog attached-page surface through the fail-fast suite-catalog and replay checks, then the replay-side and top-level attached-page helpers into the shorter suite-router attached-page quickstart.'
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 suite-catalog attached-html entrypoint'
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
Write-Host 'Suite-catalog attached-page bridge:'
Write-Host (("  1. Google recommended:     {0}") -f $entrypoint.top_level_commands.google_recommended)
Write-Host (("  2. Google input:           {0}") -f $entrypoint.top_level_commands.google_input_change_area)
Write-Host (("  3. Attached HTML:          {0}") -f $entrypoint.top_level_commands.attached_html_change_area)
Write-Host (("  4. Google attached HTML:   {0}") -f $entrypoint.top_level_commands.google_attached_html_change_area)
Write-Host (("  5. Attached bundle:        {0}") -f $entrypoint.top_level_commands.attached_bundle_change_area)
Write-Host (("  6. Suite-catalog:          {0}") -f $entrypoint.helper_commands.suite_catalog_entrypoints)
Write-Host (("  7. Suite-catalog check:    {0}") -f $entrypoint.helper_commands.suite_catalog_surface_check)
Write-Host (("  8. Top-level shortcut:     {0}") -f $entrypoint.helper_commands.top_level_shortcut_entrypoint)
Write-Host (("  9. Validation-router qk:   {0}") -f $entrypoint.helper_commands.validation_router_attached_html_quickstart)
Write-Host ((" 10. Replay surface check:   {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_surface_check)
Write-Host ((" 11. Windows replay qk:      {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)
Write-Host ((" 12. Attached flow:          {0}") -f $entrypoint.helper_commands.attached_html_flow)
Write-Host ((" 13. Top-level qk:           {0}") -f $entrypoint.helper_commands.top_level_attached_html_quickstart)
Write-Host ((" 14. Top-level bridge:       {0}") -f $entrypoint.helper_commands.top_level_attached_html_entrypoint)
Write-Host ((" 15. Top-level catalog qk:   {0}") -f $entrypoint.helper_commands.top_level_attached_html_catalog_quickstart)
Write-Host ((" 16. Router attached quick:  {0}") -f $entrypoint.helper_commands.suite_router_attached_html_quickstart)
Write-Host ((" 17. Google attached:        {0}") -f $entrypoint.helper_commands.google_attached_html_entrypoint)
Write-Host ((" 18. Google attached flow:   {0}") -f $entrypoint.helper_commands.google_attached_html_validation_flow)
Write-Host ((" 19. Bundle suite helper:    {0}") -f $entrypoint.helper_commands.attached_html_target_bundle_suite_surface)
Write-Host ((" 20. Attached shortcut:      {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host ((" 21. Router shortcut:        {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host ((" 22. Replay shortcuts:       {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host ((" 23. Next-step matrix:       {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host ((" 24. Contextual flow:        {0}") -f $entrypoint.helper_commands.contextual_flow)
Write-Host ((" 25. Bundle first:           {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host ((" 26. Safe-route map:         {0}") -f $entrypoint.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host 'Companion helpers:'
Write-Host (("  Suite-catalog:           {0}") -f $entrypoint.helper_commands.suite_catalog_entrypoints)
Write-Host (("  Suite-catalog check:     {0}") -f $entrypoint.helper_commands.suite_catalog_surface_check)
Write-Host (("  Top-level shortcut:      {0}") -f $entrypoint.helper_commands.top_level_shortcut_entrypoint)
Write-Host (("  Validation-router qk:    {0}") -f $entrypoint.helper_commands.validation_router_attached_html_quickstart)
Write-Host (("  Replay surface check:    {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_surface_check)
Write-Host (("  Windows replay qk:       {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)
Write-Host (("  Attached flow:           {0}") -f $entrypoint.helper_commands.attached_html_flow)
Write-Host (("  Top-level qk:            {0}") -f $entrypoint.helper_commands.top_level_attached_html_quickstart)
Write-Host (("  Top-level bridge:        {0}") -f $entrypoint.helper_commands.top_level_attached_html_entrypoint)
Write-Host (("  Top-level catalog qk:    {0}") -f $entrypoint.helper_commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  Router attached quick:   {0}") -f $entrypoint.helper_commands.suite_router_attached_html_quickstart)
Write-Host (("  Google attached:         {0}") -f $entrypoint.helper_commands.google_attached_html_entrypoint)
Write-Host (("  Google attached flow:    {0}") -f $entrypoint.helper_commands.google_attached_html_validation_flow)
Write-Host (("  Bundle suite helper:     {0}") -f $entrypoint.helper_commands.attached_html_target_bundle_suite_surface)
Write-Host (("  Attached shortcut:       {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host (("  Router shortcut:         {0}") -f $entrypoint.helper_commands.suite_router_shortcut_entrypoint)
Write-Host (("  Replay shortcuts:        {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host (("  Next-step matrix:        {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host (("  Contextual flow:         {0}") -f $entrypoint.helper_commands.contextual_flow)
Write-Host (("  Bundle first:            {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host (("  Safe-route map:          {0}") -f $entrypoint.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Quickstart note:              {0}") -f $entrypoint.quickstart_note_path)
Write-Host (("Windows replay quickstart:   {0}") -f (' ' + $entrypoint.windows_replay_attached_html_quickstart_note_path))
Write-Host (("Validation-router quick:     {0}") -f (' ' + $entrypoint.validation_router_attached_html_quickstart_note_path))
Write-Host (("Top-level quickstart:        {0}") -f (' ' + $entrypoint.top_level_attached_html_quickstart_note_path))
Write-Host (("Top-level bridge:            {0}") -f (' ' + $entrypoint.top_level_attached_html_bridge_note_path))
Write-Host (("Top-level catalog quick:     {0}") -f (' ' + $entrypoint.top_level_attached_html_catalog_quickstart_note_path))
Write-Host (("Catalog-to-top-level qk:     {0}") -f (' ' + $entrypoint.suite_catalog_top_level_attached_html_catalog_quickstart_note_path))
Write-Host (("Top-level companion:         {0}") -f (' ' + $entrypoint.top_level_attached_html_companion_note_path))
Write-Host (("Router attached quickstart:  {0}") -f (' ' + $entrypoint.suite_router_attached_html_quickstart_note_path))
Write-Host (("Google attached-html flow:   {0}") -f (' ' + $entrypoint.google_attached_html_validation_flow_note_path))
Write-Host (("Suite-router bridge:         {0}") -f $entrypoint.suite_router_bridge_note_path)
Write-Host (("Catalog attached bridge:     {0}") -f $entrypoint.suite_catalog_attached_html_bridge_note_path)
Write-Host (("Suite-catalog guide:         {0}") -f $entrypoint.suite_catalog_entrypoint_note_path)
Write-Host (("Attached bundle ref:         {0}") -f $entrypoint.attached_html_target_bundle_reference_note_path)
Write-Host (("Bundle suite note:           {0}") -f $entrypoint.attached_html_target_bundle_suite_surface_note_path)
Write-Host (("Validation chain:            {0}") -f $entrypoint.validation_chain_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}