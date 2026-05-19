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
            if ($entry.Value -is [System.Collections.IEnumerable] -and -not ($entry.Value -is [string])) {
                Add-SharedPathArrayArgument -Arguments $fallbackArguments -Name $entry.Key -Values @($entry.Value)
                continue
            }

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

$googleAttachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $googleAttachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$routeSurfaceArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $routeSurfaceArguments -Name RepoRoot -Value $RepoRoot

$attachedPagesLauncherArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $attachedPagesLauncherArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $attachedPagesLauncherArguments -Name InputPath -Values $InputPath

$attachedPagesSidecarAuditCommand = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $attachedPagesLauncherArguments -Switches @('AuditSidecars')
$attachedPagesGoogleSidecarAuditCommand = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $attachedPagesLauncherArguments -Switches @('GoogleStyle', 'AuditSidecars')
$attachedPagesAssetAuditCommand = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $attachedPagesLauncherArguments -Switches @('AuditAssets')
$attachedPagesManifestPrintCommand = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $attachedPagesLauncherArguments -Switches @('PrintManifest')
$attachedPagesStrictLaunchCommand = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $attachedPagesLauncherArguments -Switches @('RequireCompleteSidecars')
$attachedPagesLauncherCompanionSurfaceCheckCommand = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $routeSurfaceArguments
$attachedPagesLauncherCompanionCommand = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $attachedPagesLauncherArguments

$windowsFullUseAttachedHtmlRouteSurfaceCheckCommand = Format-HelperCommand -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -Arguments $routeSurfaceArguments
$windowsFullUseAttachedHtmlCatalogSurfaceCheckCommand = Format-HelperCommand -ScriptName 'check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1' -Arguments $routeSurfaceArguments
$windowsReplayAttachedHtmlQuickstartCommand = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments
$googleAttachedHtmlSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot

$entrypoint = [ordered]@{
    issue = 'Google issue #3 Windows full-use attached HTML catalog quickstart'
    purpose = 'Keep the broader Windows full-use attached-page route, the route-level and catalog-level fail-fast surface checks, the broader attached-page flow helper, the launcher-backed attached-pages preflight ladder (sidecar audit, Google-style sidecar audit, asset audit, manifest print, strict sidecar-gated launch, and the launcher companion surface), the dedicated Google-shaped attached-page fail-fast surface check, the dedicated Google-shaped attached-page flow helper, the newer top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, the newer top-level shortcut bridge, the replay-route shortcut bridge, and the compact attached-bundle suite surface visible on one compact helper before the replay narrows into the suite-catalog attached-page bridge, the shorter attached-page shortcut, the pinned bundle-first path, or the wrapper-heavy safe-route map.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    top_level_commands = [ordered]@{
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $bundleArguments
        windows_full_use_attached_html_route_surface_check = $windowsFullUseAttachedHtmlRouteSurfaceCheckCommand
        windows_full_use_validation_router_attached_html_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $bundleArguments
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
        catalog_quickstart_surface_check = $windowsFullUseAttachedHtmlCatalogSurfaceCheckCommand
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $bundleArguments
        attached_html_validation_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        attached_pages_sidecar_audit = $attachedPagesSidecarAuditCommand
        attached_pages_asset_audit = $attachedPagesAssetAuditCommand
        attached_pages_print_manifest = $attachedPagesManifestPrintCommand
        attached_pages_strict_launch = $attachedPagesStrictLaunchCommand
        attached_pages_launcher_companion_surface_check = $attachedPagesLauncherCompanionSurfaceCheckCommand
        attached_pages_launcher_companion = $attachedPagesLauncherCompanionCommand
        windows_replay_attached_html_quickstart = $windowsReplayAttachedHtmlQuickstartCommand
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        suite_catalog_top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        top_level_shortcut_first_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        replay_route_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        attached_pages_google_sidecar_audit = $attachedPagesGoogleSidecarAuditCommand
        google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand
        google_attached_html_validation_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $bundleArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
    }
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    windows_full_use_validation_router_attached_html_bridge_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md'
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    top_level_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_catalog_top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_catalog_attached_html_bridge_note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    replay_route_shortcut_bridge_note_path = 'docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md'
    attached_html_target_bundle_suite_surface_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md'
    attached_pages_launcher_readme_path = 'tmp-browser-smoke/attached-pages/README.md'
    attached_pages_launcher_wrapper_path = 'scripts/windows/start_attached_pages_catalog.ps1'
    attached_pages_launcher_entrypoint_path = 'tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py'
    attached_pages_launcher_companion_surface_check_path = 'scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1'
    attached_pages_launcher_companion_path = 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1'
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    notes = @(
        'Use this helper when docs/WINDOWS_FULL_USE.md has already narrowed the next replay to attached localhost follow-up and you want the route-level surface check, the catalog-level surface check, the Windows-to-validation-router bridge, the broader attached-page flow helper, the launcher-backed attached-pages preflight ladder, the launcher companion guard and helper, and the replay-side attached-page quickstart reprinted beside the newer top-level attached-page catalog quickstart.',
        'Run catalog_quickstart_surface_check after branch moves or before trusting this narrower catalog ladder from another checkout, because it fails fast on missing route notes, helper scripts, top-level shortcut bridges, replay-route shortcut bridges, bundle-suite surfaces, and downstream attached-page helpers before the replay narrows again.',
        'Use attached_html_change_area_quickstart after the broader Windows full-use route and the validation-router bridge when the broader attached-page router surface should stay visible before the compact replay-side and top-level quickstarts narrow the route again.',
        'Use attached_html_validation_flow after the change-area quickstart when the replay still needs the broader attached-page localhost helper visible, and keep pinned InputPath values attached to that helper before the route drops into the launcher-backed preflight ladder, the replay-side attached-page quickstart, or the dedicated Google-shaped follow-up lane.',
        'Use attached_pages_sidecar_audit right after the broader attached-page flow when you want the cheapest honest preflight for the current saved export. It rules out a missing sibling _files bundle before the replay widens into the asset audit, manifest print, strict launch, the dedicated Google-shaped flow, the replay-side attached-page quickstart, or the shorter issue #3 helper chain.',
        'Use attached_pages_asset_audit after the sidecar audit when the sibling bundle exists but you still need the exact missing local asset references before the manifest print or localhost launch.',
        'Use attached_pages_print_manifest after the sidecar and asset audits when you want the exact selected page order and localhost routes without starting the server yet.',
        'Use attached_pages_strict_launch after the rest of the preflight ladder when you want the live catalog launch to fail fast on incomplete sidecars instead of serving a known-bad export bundle.',
        'Use attached_pages_launcher_companion_surface_check before the launcher companion helper when you want a fail-fast check for the smaller attached-pages launcher companion surface itself, including its stricter sidecar, asset, and proof-follow-up pointers.',
        'Use attached_pages_launcher_companion after the sidecar audit, asset audit, manifest print, or strict launch when you want the smaller attached-pages launcher ladder reprinted with the stricter sidecar, asset, Google-style, and proof-follow-up commands kept together before the replay narrows again.',
        'Use windows_replay_attached_html_quickstart after the preflight ladder when the current export looks intact enough to keep the replay-side attached-page quickstart visible before the route narrows into the top-level attached-page quickstart, the broader top-level attached-page bridge, the top-level attached-page catalog quickstart, the suite-catalog-to-top-level attached-page catalog quickstart, the newer top-level shortcut bridge, the replay-route shortcut bridge, the compact attached-bundle suite surface, the suite-router attached-page quickstart, the suite-catalog attached-page bridge, the shorter attached-page shortcut, replay shortcuts, or the safe-route map.',
        'Use top_level_attached_html_catalog_quickstart when you want the compact top-level attached-page quickstart and the suite-catalog-side attached-page bridge kept visible together before the route narrows into the shorter attached-page shortcut, replay shortcuts, contextual flow, or the safe-route map.',
        'Use suite_catalog_top_level_attached_html_catalog_quickstart after the top-level catalog quickstart when you want the suite-catalog-to-top-level catalog ladder kept visible before the route narrows into the suite-catalog attached-page bridge or the shorter attached-page shortcut surface.',
        'Use top_level_shortcut_first_entrypoint when you want the newer top-level shortcut bridge reprinted beside the catalog quickstart before the route collapses into the shorter attached-page shortcut surface.',
        'Use replay_route_shortcut_entrypoint when you want the replay-route shortcut bridge reprinted beside the catalog quickstart before the route widens back into replay shortcuts, the next-step matrix, contextual flow, the bundle-first branch, or the safe-route map.',
        'Use suite_catalog_attached_html_entrypoint after the top-level catalog quickstart when the suite-catalog-side attached-page bridge should stay visible before the replay narrows again.',
        'Use attached_pages_google_sidecar_audit when the current attached inputs are already Google-shaped and you want the same cheaper wrapper-backed sibling _files preflight to run before the dedicated Google surface check or the dedicated Google flow helper takes over.',
        'Use google_attached_html_validation_flow when the current attached inputs are already Google-shaped and you want the dedicated attached-page flow helper visible beside the broader Windows and top-level attached-page ladders before the route narrows back into the shorter issue #3 helper chain.',
        'Use attached_bundle_suite_surface when the current attached or saved pages are still close to the known three-page compatibility bundle and you want that compact suite surface visible before the route commits to the bundle-first branch.',
        'Use attached_bundle_first when explicit InputPath values are already pinned to the known three-page compatibility bundle and that bundle-first branch should stay visible before widening back into the broader issue #3 helper chain.',
        'Use contextual_flow when RepoRoot or SummaryPath is already in play and the next helper surface should keep that replay context aligned while you choose between the suite-catalog attached-page bridge, replay shortcuts, the next-step matrix, the bundle-first branch, or the safe-route map.',
        'Keep the Windows runbook, the Windows full-use attached-page route note, the Windows validation-router attached-page bridge note, the Windows replay attached-page quickstart note, the top-level attached-page catalog quickstart note, the suite-catalog-to-top-level attached-page catalog quickstart note, the suite-catalog attached-page bridge note, the Google attached-page validation-flow note, the replay-route shortcut bridge note, the bundle-suite surface note, the attached-pages launcher README, the Windows launcher wrapper, the lower-level attached-pages launcher entrypoint, the launcher companion checker, the launcher companion helper, and the Windows replay quickstart nearby when you want the written route beside these commands.'
    )
}

$entrypoint.recommended_next_key = 'attached_pages_sidecar_audit'
$entrypoint.recommended_next_command = $entrypoint.helper_commands[$entrypoint.recommended_next_key]
$entrypoint.recommended_next_reason = 'The launcher-backed sidecar audit is the cheapest honest preflight: it rules out a missing sibling _files bundle before the replay widens into the deeper attached-page and Google-shaped helper chain.'

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 Windows full-use attached HTML catalog quickstart'
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
Write-Host 'Windows full-use catalog bridge:'
Write-Host (("  1. Windows route:         {0}") -f $entrypoint.top_level_commands.windows_full_use_attached_html_route)
Write-Host (("  2. Route check:           {0}") -f $entrypoint.top_level_commands.windows_full_use_attached_html_route_surface_check)
Write-Host (("  3. Validation bridge:     {0}") -f $entrypoint.top_level_commands.windows_full_use_validation_router_attached_html_bridge)
Write-Host (("  4. Attached HTML:         {0}") -f $entrypoint.top_level_commands.attached_html_change_area)
Write-Host (("  5. Google attached HTML:  {0}") -f $entrypoint.top_level_commands.google_attached_html_change_area)
Write-Host (("  6. Attached bundle:       {0}") -f $entrypoint.top_level_commands.attached_bundle_change_area)
Write-Host (("  7. Catalog check:         {0}") -f $entrypoint.helper_commands.catalog_quickstart_surface_check)
Write-Host (("  8. Change-area bridge:    {0}") -f $entrypoint.helper_commands.attached_html_change_area_quickstart)
Write-Host (("  9. Attached flow:         {0}") -f $entrypoint.helper_commands.attached_html_validation_flow)
Write-Host ((" 10. Sidecar audit:         {0}") -f $entrypoint.helper_commands.attached_pages_sidecar_audit)
Write-Host ((" 11. Asset audit:           {0}") -f $entrypoint.helper_commands.attached_pages_asset_audit)
Write-Host ((" 12. Print manifest:        {0}") -f $entrypoint.helper_commands.attached_pages_print_manifest)
Write-Host ((" 13. Strict launch:         {0}") -f $entrypoint.helper_commands.attached_pages_strict_launch)
Write-Host ((" 14. Companion check:       {0}") -f $entrypoint.helper_commands.attached_pages_launcher_companion_surface_check)
Write-Host ((" 15. Companion helper:      {0}") -f $entrypoint.helper_commands.attached_pages_launcher_companion)
Write-Host ((" 16. Replay quickstart:     {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)
Write-Host ((" 17. Top-level quickstart:  {0}") -f $entrypoint.helper_commands.top_level_attached_html_quickstart)
Write-Host ((" 18. Top-level bridge:      {0}") -f $entrypoint.helper_commands.top_level_attached_html_entrypoint)
Write-Host ((" 19. Catalog quickstart:    {0}") -f $entrypoint.helper_commands.top_level_attached_html_catalog_quickstart)
Write-Host ((" 20. Catalog-to-top-level:  {0}") -f $entrypoint.helper_commands.suite_catalog_top_level_attached_html_catalog_quickstart)
Write-Host ((" 21. Top-level shortcut:    {0}") -f $entrypoint.helper_commands.top_level_shortcut_first_entrypoint)
Write-Host ((" 22. Replay-route shortcut: {0}") -f $entrypoint.helper_commands.replay_route_shortcut_entrypoint)
Write-Host ((" 23. Router quickstart:     {0}") -f $entrypoint.helper_commands.suite_router_attached_html_quickstart)
Write-Host ((" 24. Catalog bridge:        {0}") -f $entrypoint.helper_commands.suite_catalog_attached_html_entrypoint)
Write-Host ((" 25. Google attached:       {0}") -f $entrypoint.helper_commands.google_attached_html_entrypoint)
Write-Host ((" 26. Google sidecars:       {0}") -f $entrypoint.helper_commands.attached_pages_google_sidecar_audit)
Write-Host ((" 27. Google surface check:  {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)
Write-Host ((" 28. Google attached flow:  {0}") -f $entrypoint.helper_commands.google_attached_html_validation_flow)
Write-Host ((" 29. Bundle suite surface:  {0}") -f $entrypoint.helper_commands.attached_bundle_suite_surface)
Write-Host ((" 30. Attached shortcut:     {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host ((" 31. Replay shortcuts:      {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host ((" 32. Next-step matrix:      {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host ((" 33. Contextual flow:       {0}") -f $entrypoint.helper_commands.contextual_flow)
Write-Host ((" 34. Bundle first:          {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host ((" 35. Safe-route map:        {0}") -f $entrypoint.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Windows runbook:            {0}") -f $entrypoint.windows_runbook_note_path)
Write-Host (("Windows attached route:     {0}") -f $entrypoint.windows_full_use_attached_html_route_note_path)
Write-Host (("Windows validation bridge:  {0}") -f $entrypoint.windows_full_use_validation_router_attached_html_bridge_note_path)
Write-Host (("Windows replay attached:    {0}") -f $entrypoint.windows_replay_attached_html_quickstart_note_path)
Write-Host (("Catalog quickstart note:    {0}") -f $entrypoint.top_level_catalog_quickstart_note_path)
Write-Host (("Catalog-to-top-level note:  {0}") -f $entrypoint.suite_catalog_top_level_attached_html_catalog_quickstart_note_path)
Write-Host (("Catalog bridge note:        {0}") -f $entrypoint.suite_catalog_attached_html_bridge_note_path)
Write-Host (("Google attached flow note:  {0}") -f $entrypoint.google_attached_html_validation_flow_note_path)
Write-Host (("Replay-route shortcut note: {0}") -f $entrypoint.replay_route_shortcut_bridge_note_path)
Write-Host (("Bundle suite note:          {0}") -f $entrypoint.attached_html_target_bundle_suite_surface_note_path)
Write-Host (("Attached-pages guide:       {0}") -f $entrypoint.attached_pages_launcher_readme_path)
Write-Host (("Attached-pages wrapper:     {0}") -f $entrypoint.attached_pages_launcher_wrapper_path)
Write-Host (("Attached-pages launcher:    {0}") -f $entrypoint.attached_pages_launcher_entrypoint_path)
Write-Host (("Launcher companion check:   {0}") -f $entrypoint.attached_pages_launcher_companion_surface_check_path)
Write-Host (("Launcher companion helper:  {0}") -f $entrypoint.attached_pages_launcher_companion_path)
Write-Host (("Replay quickstart note:     {0}") -f $entrypoint.windows_replay_quickstart_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}