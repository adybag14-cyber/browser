[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
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

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $InputPath

$preferredInitialPageSharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $preferredInitialPageSharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $preferredInitialPageSharedArguments -Name InputPath -Values $InputPath
Add-SharedArgument -Arguments $preferredInitialPageSharedArguments -Name PreferredInitialPage -Value $PreferredInitialPage

$preferredInitialPageBundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $preferredInitialPageBundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $preferredInitialPageBundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $preferredInitialPageBundleArguments -Name PreferredInitialPage -Value $PreferredInitialPage
Add-SharedPathArrayArgument -Arguments $preferredInitialPageBundleArguments -Name InputPath -Values $InputPath

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $attachedHtmlFlowArguments["InputPath"] = @($InputPath)
}
if ($PreferredInitialPage) {
    $attachedHtmlFlowArguments["PreferredInitialPage"] = $PreferredInitialPage
}

$googleAttachedHtmlFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $googleAttachedHtmlFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $googleAttachedHtmlFlowArguments -Name InputPath -Values $InputPath
Add-SharedArgument -Arguments $googleAttachedHtmlFlowArguments -Name PreferredInitialPage -Value $PreferredInitialPage

$helper = [ordered]@{
    issue = 'Google issue #3 attached-html change-area quickstart'
    purpose = 'Print the shortest follow-up from show_headed_validation_suites.ps1 -ChangeArea attached-html into the newer attached-page helper chain while also surfacing the launcher-companion preflight lane, the broader attached-page flow helper, the dedicated Google attached-page flow guide, the dedicated attached-html context surface, the validation-router attached-page quickstart, the Windows-first and replay-side attached-html quickstarts, the dedicated change-area surface checker, the suite-catalog-to-top-level attached-page catalog quickstart, the dedicated suite-catalog guide, and preserving repo-root, saved-summary, preferred-first-page, and pinned bundle-input context.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    preferred_initial_page = $PreferredInitialPage
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    attached_html_change_area_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    attached_html_context_surface_note_path = 'docs/ISSUE3_ATTACHED_HTML_CONTEXT_SURFACE.md'
    attached_pages_launcher_readme_path = 'tmp-browser-smoke/attached-pages/README.md'
    attached_pages_launcher_companion_helper_path = 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1'
    attached_pages_launcher_companion_surface_check_path = 'scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    windows_full_use_validation_router_attached_html_bridge_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md'
    windows_full_use_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    validation_router_attached_html_quickstart_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    top_level_attached_html_companion_notes_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    suite_catalog_top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    attached_html_target_bundle_reference_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
    attached_html_target_bundle_suite_surface_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    commands = [ordered]@{
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
            PreferredInitialPage = $PreferredInitialPage
        }) -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
            PreferredInitialPage = $PreferredInitialPage
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
            PreferredInitialPage = $PreferredInitialPage
        }) -RepoRootOverride $RepoRoot
        validation_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_attached_html_change_area_quickstart_validation_surface.ps1' -RepoRootOverride $RepoRoot
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        attached_pages_launcher_companion_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -RepoRootOverride $RepoRoot
        attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $preferredInitialPageSharedArguments
        google_attached_html_validation_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments
        attached_html_context_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_context_surface.ps1' -Arguments $sharedArguments
        windows_full_use_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $preferredInitialPageBundleArguments
        validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $sharedArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        suite_catalog_top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        top_level_shortcut_first_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $sharedArguments
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $sharedArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $sharedArguments
        attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $sharedArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $sharedArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $sharedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Start with attached_html_change_area when the top-level headed validation router already narrowed the replay to the generic attached localhost compatibility route and you want that route reprinted before you choose a smaller issue #3 helper.',
        'Run validation_surface_check before the attached-html change-area quickstart when you want the note, helper, and follow-up attached-page chain to fail fast after branch moves.',
        'Use attached_html_flow when you want the broader attached-page localhost flow helper visible from that same change-area entry before dropping into the issue-specific quickstarts or the shortcut companion.',
        'Run attached_pages_launcher_companion_surface_check and then attached_pages_launcher_companion when the next honest question is whether missing sidecars, missing local assets, or a stale launcher path is the real blocker before the replay dives into the deeper Google-shaped checks.',
        'Use google_attached_html_validation_flow when the current attached pages are already Google-shaped and you want the asset-closure audit plus the preferred-first-page handoff surfaced after the launcher companion has already ruled out the lighter sidecar and wrapper-path failure modes.',
        'Use attached_html_context_surface when replay context already matters and you want the broader attached-page lane, the Google-shaped attached-page lane, and the pinned bundle lane printed together with the same RepoRoot, SummaryPath, and InputPath values before you choose a narrower helper.',
        'Use windows_full_use_attached_html_catalog_quickstart when the replay is re-entering from the broader Windows full-use route and you want the Windows-first catalog step plus the replay-side attached-page quickstart kept visible before the route narrows into the smaller top-level helpers.',
        'Use windows_replay_attached_html_quickstart when docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md already narrowed replay to the attached localhost lane and you want that replay-side ladder kept visible before the validation-router quickstart or the top-level attached-page helpers take over.',
        'Use validation_router_attached_html_quickstart when the replay is still re-entering from the broader validation router and you want the validation-router attached-page bridge visible before the route narrows into the compact top-level quickstarts, the catalog-side helpers, or the shorter attached-page shortcut surfaces.',
        'Use google_attached_html_change_area when the replay still needs the broader Google-shaped attached-page route visible before you narrow again.',
        'Use top_level_attached_html_quickstart as the default next helper when no pinned bundle inputs, non-default repo root, or saved summary need to take precedence, because it keeps the compact top-level attached-page route visible before you drop into the narrower bridge and shortcut helpers.',
        'Use top_level_attached_html_catalog_quickstart when you want the compact top-level attached-page route and the suite-catalog-side bridge kept visible together before the route narrows again.',
        'Use suite_catalog_top_level_attached_html_catalog_quickstart when you want the narrower suite-catalog-to-top-level catalog handoff printed before the dedicated suite-catalog guide or the suite-catalog attached-page bridge takes over.',
        'Use suite_router_attached_html_quickstart when the next replay should stay closer to the suite-router-side attached-page branch before widening back into the broader helper chain.',
        'Use top_level_attached_html_entrypoint when the route is already clearly inside the issue-specific attached-page branch and you want the broader top-level attached-page bridge reprinted before the shorter quickstart or shortcut helpers.',
        'Use top_level_shortcut_first_entrypoint when the replay is already narrowed enough that the shortest top-level shortcut bridge is the most useful follow-up.',
        'Use suite_catalog_entrypoints when you want the dedicated suite-catalog guide reprinted before the narrower suite-catalog attached-page bridge so the broader catalog-side route map stays visible beside the compact top-level attached-page helpers.',
        'Use suite_catalog_attached_html_entrypoint when the suite-catalog-side attached-page bridge should stay visible before you narrow again.',
        'Use attached_html_shortcut when the route is already clearly inside attached-page follow-up and you want the shortest bridge before widening back into replay_shortcuts, the next-step matrix, contextual_flow, or the safe-route map.',
        'Use replay_shortcuts when the route is already narrow enough that the compact issue #3 replay surface is the next best layer.',
        'Use attached_bundle_change_area when the replay should reopen the top-level router on the pinned three-page compatibility bundle before the helper chain narrows again.',
        'Use attached_bundle_suite_surface when the current replay is already close to the known three-page compatibility bundle and you want the compact bundle-specific suite surface printed before the narrower bundle-first helper or delegated bundle flow takes over.',
        'Use attached_bundle_first only after the compact bundle-suite surface or the pinned bundle change-area route is already visible and the replay should stay locked to the known three-page compatibility set before widening back into the broader helper chain.',
        'Use contextual_flow when RepoRoot, SummaryPath, or fixed InputPath values already matter and you want the next helper surface to keep that replay context aligned before you choose between the quickstarts, the broader attached-page flow helper, the launcher companion preflight lane, the dedicated Google attached-page flow guide, the validation-router attached-page bridge, the Windows-first and replay-side attached-html quickstarts, the suite-catalog-to-top-level catalog handoff, the dedicated suite-catalog guide, the compact bundle-suite surface, shortcuts, next-step matrix, or safe-route wrapper.',
        'Pass -PreferredInitialPage when the same saved page should stay first through the broader attached-html re-entry commands, launcher companion, attached-page flow helper, dedicated Google-style flow helper, and replay-side quickstart instead of falling back to auto-selection.'
    )
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 attached-html change-area quickstart'
Write-Host ''
if ($helper.repo_root) {
    Write-Host (("Repo root:   {0}") -f $helper.repo_root)
}
if ($helper.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($helper.summary_path)"))
}
if ($helper.preferred_initial_page) {
    Write-Host (("Preferred first page: {0}") -f $helper.preferred_initial_page)
}
if ($helper.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $helper.explicit_input_path_count)
}
Write-Host ''
Write-Host 'Commands:'
foreach ($entry in $helper.commands.GetEnumerator()) {
    Write-Host (("  {0}: {1}") -f $entry.Key, $entry.Value)
}
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
Write-Host ''
Write-Host 'Reference notes:'
Write-Host (("  Attached-html quickstart: {0}") -f $helper.attached_html_change_area_quickstart_note_path)
Write-Host (("  Attached-html context:    {0}") -f $helper.attached_html_context_surface_note_path)
Write-Host (("  Google flow:              {0}") -f $helper.google_attached_html_validation_flow_note_path)
Write-Host (("  Validation router:        {0}") -f $helper.validation_router_attached_html_quickstart_note_path)
Write-Host (("  Windows replay:           {0}") -f $helper.windows_replay_attached_html_quickstart_note_path)
Write-Host (("  Top-level quickstart:     {0}") -f $helper.top_level_attached_html_quickstart_note_path)
Write-Host (("  Bundle reference:         {0}") -f $helper.attached_html_target_bundle_reference_note_path)
