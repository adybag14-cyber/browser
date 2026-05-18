[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
    [string]$BrowserExe,
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

function Format-AttachedPagesSidecarAuditCommand {
    param(
        [string]$RepoRoot,
        [string[]]$InputPath
    )

    $command = 'python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --audit-sidecars'
    if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
        $command += ' --repo-root ' + (ConvertTo-PowerShellSingleQuotedLiteral -Value $RepoRoot)
    }
    if ($InputPath -and $InputPath.Count -gt 0) {
        foreach ($value in $InputPath) {
            if ([string]::IsNullOrWhiteSpace($value)) {
                continue
            }

            $command += ' --input ' + (ConvertTo-PowerShellSingleQuotedLiteral -Value $value)
        }
        return $command
    }

    return $command + " --input '<attached-html-root>'"
}

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $sharedArguments -Name BrowserExe -Value $BrowserExe
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $InputPath

$googleAttachedHtmlFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $googleAttachedHtmlFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $googleAttachedHtmlFlowArguments -Name BrowserExe -Value $BrowserExe
Add-SharedPathArrayArgument -Arguments $googleAttachedHtmlFlowArguments -Name InputPath -Values $InputPath

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$attachedPagesSidecarAuditCommand = Format-AttachedPagesSidecarAuditCommand -RepoRoot $RepoRoot -InputPath $InputPath
$googleAttachedHtmlSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot
$googleIssue3AttachedHtmlSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1' -RepoRootOverride $RepoRoot
$topLevelAttachedHtmlSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_top_level_attached_html_quickstart_validation_surface.ps1' -RepoRootOverride $RepoRoot

$helper = [ordered]@{
    issue = 'Google issue #3 top-level attached HTML quickstart'
    purpose = 'Print the shortest top-level attached-page-first bridge into the suite-router attached-page helper chain while also surfacing the broader attached-html change-area quickstart, attached-page flow helper, the dedicated Google-style attached-page surface check, the issue-specific Google attached-page surface check, the dedicated Google-style attached-page flow helper, the compact attached bundle suite surface helper, the attached bundle proof entrypoint, the matching top-level shortcut-first helper surface, the top-level attached-page catalog quickstart, the dedicated suite-catalog guide, and the suite-catalog-to-top-level attached-page catalog quickstart when that wider localhost route still matters.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    browser_exe = $BrowserExe
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    attached_html_change_area_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    validation_router_attached_html_quickstart_note_path = 'docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    google_attached_html_entrypoint_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'
    attached_bundle_reference_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
    attached_bundle_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md'
    attached_bundle_checklist_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md'
    attached_bundle_suite_surface_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md'
    attached_bundle_proof_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_catalog_top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_catalog_entrypoints_note_path = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
    top_level_attached_html_companion_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md'
    top_level_shortcut_first_entrypoint_note_path = 'docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md'
    top_level_shortcut_bridge_note_path = 'docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
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
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $sharedArguments
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $sharedArguments
        top_level_attached_html_surface_check = $topLevelAttachedHtmlSurfaceCheckCommand
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        attached_pages_sidecar_audit = $attachedPagesSidecarAuditCommand
        google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand
        google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand
        google_attached_html_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments
        attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedArguments
        attached_bundle_proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $sharedArguments
        validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $sharedArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        top_level_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $sharedArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        suite_catalog_top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $sharedArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $sharedArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $sharedArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $sharedArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $sharedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Start with attached_html_change_area when the top-level headed validation router is already narrowed to the generic attached localhost compatibility route and you want the broader attached-page flow helper kept visible before this top-level quickstart narrows the route again.',
        'Use top_level_attached_html_surface_check before trusting the compact attached-page helper map when you want the exact quickstart surface to fail fast on missing notes, bridge helpers, or pinned-bundle companion commands.',
        'Use attached_html_change_area_quickstart when the replay is already reopening from show_headed_validation_suites.ps1 -ChangeArea attached-html and you want the broader attached-page flow helper, the dedicated Google-style attached-page surface check, the issue-specific Google attached-page surface check, and the compact top-level attached-page route surfaced together before dropping deeper into issue #3 helper surfaces.',
        'Use attached_html_flow when the replay still needs the broader attached-page localhost helper visible from that same change-area branch before narrowing into the issue-specific quickstarts or shortcut helpers.',
        'Use google_attached_html_surface_check when the replay is already narrowed to the Google-shaped attached-page lane and you want the broader dedicated surface checker reprinted before the issue-specific Google checker, the broader Google-style attached-page helper, or its runner handoff.',
        'Use google_issue3_attached_html_surface_check when the replay has already narrowed from the broader Google-shaped attached-page lane into the issue-specific Google attached-page bridge and you want the entrypoint-specific fail-fast checker reprinted before the narrower helper chain.',
        'Use google_attached_html_flow when the replay is already narrowed to the Google-shaped attached-page lane and you want the current attached HTML set, its asset-closure audit, and the saved-page Google runner handoff printed directly from the same compact top-level surface after the broader and issue-specific surface checks have already been reprinted.',
        'Use attached_bundle_suite_surface when the current replay is already pinned to the known three-page compatibility bundle and you want the compact suite-level bundle surface reprinted before the route narrows into the bundle-first helper or the delegated bundle runner.',
        'Use attached_bundle_proof_entrypoint when the pinned three-page compatibility bundle is already green and you want the fixed-list screenshot-and-title proof reprinted before the route widens back into the broader attached-page or Google-shaped follow-up helpers.',
        'Use validation_router_attached_html_quickstart when the replay is re-entering from the broader headed validation router and you want the shorter bridge into this compact top-level attached-page route kept visible before the helper chain narrows again.',
        'Use google_attached_html_change_area when the replay still needs the broader Google-shaped attached-page route visible before narrowing again.',
        'Use windows_full_use_attached_html_route when the next replay started from docs/WINDOWS_FULL_USE.md and you want the broader Windows full-use attached-page route helper reprinted before dropping back into the compact top-level attached-page quickstart.',
        'Use top_level_attached_html_entrypoint as the default next helper when no pinned bundle inputs or saved summary need to take precedence, because it keeps the broader top-level attached-page bridge visible immediately after the compact quickstart before the route narrows again.',
        'Use top_level_shortcut_entrypoint when the route is already about to narrow from the broader top-level attached-page chain into the shorter attached-page shortcut, replay-route shortcut, replay shortcuts, the next-step matrix, or the safe-route map.',
        'Use top_level_attached_html_catalog_quickstart when you want the compact top-level attached-page quickstart and the suite-catalog-side bridge kept visible together before the route narrows again.',
        'Use suite_catalog_top_level_attached_html_catalog_quickstart when you want the replay-side attached-page ladder, the compact top-level attached-page catalog quickstart, and the suite-catalog-side bridge kept visible together before the route narrows into the shorter attached-page helpers.',
        'Use suite_catalog_entrypoints when the wider suite-catalog route should stay visible beside the compact top-level attached-page quickstart before the helper chain narrows into the suite-catalog attached-page bridge, the shorter suite-router attached-page bridge, or the tighter replay helpers.',
        'Keep top_level_attached_html_companion_note_path nearby when the broader top-level attached-page helper is already open and you want the shortest written map of which nearby notes should stay visible beside that helper.',
        'Keep top_level_shortcut_first_entrypoint_note_path and top_level_shortcut_bridge_note_path nearby when the route is about to narrow into the shorter shortcut-first helper family and you want the written shortcut companions beside the live helper output.',
        'Use suite_router_attached_html_quickstart after the top-level attached-page bridge when you want the shorter suite-router attached-page bridge visible before you choose between the catalog bridge, the broader Google-shaped attached-page surface check, the issue-specific Google attached-page surface check, the broader Google-shaped attached-page helper, the attached-page shortcut, replay shortcuts, the next-step matrix, or the bundle-first route.',
        'Use suite_catalog_attached_html_entrypoint when the suite-catalog-side attached-page bridge should stay visible before the replay narrows again.',
        'Use google_attached_html_entrypoint when the replay still needs the broader issue-specific attached-page flow helper kept visible before you drop to the shorter attached-page shortcut.',
        'Use attached_html_shortcut when the route is already clearly inside attached-page follow-up and you want the shortest bridge before widening into replay shortcuts, the next-step matrix, or the safe-route map.',
        'Use contextual_flow when RepoRoot, SummaryPath, BrowserExe, or pinned bundle inputs already matter and the next helper surface should keep that replay context aligned before narrowing again.',
        'Use attached_bundle_change_area, then attached_bundle_suite_surface, then attached_bundle_proof_entrypoint, and only then attached_bundle_first when the current replay should stay pinned to the known three-page compatibility bundle before widening back into the broader Google-only helper chain.',
        'Use safe_route_entrypoints only after the route has already narrowed enough that the wrapper-heavy issue #3 command surface is the next useful layer.',
        'Pass -BrowserExe when the shorter issue #3 attached-page ladder should stay pinned to a non-default Windows headed build through the broader Google-shaped flow helper, the bundle-suite surface, the bundle-first bridge, and the delegated bundle route instead of drifting back to .\\zig-out\\bin\\lightpanda.exe.',
        'Keep the Windows full-use attached-html route note, the attached-html change-area quickstart note, the validation-router attached-page quickstart note, the top-level attached-page quickstart note, the top-level attached-page bridge note, the Google-style attached HTML flow note, the Google-style attached HTML entrypoint note, the attached bundle reference note, the attached bundle quickstart note, the attached bundle checklist note, the attached bundle suite-surface note, the attached bundle proof note, the top-level shortcut-first note, the top-level shortcut bridge note, the top-level attached-page catalog quickstart note, the suite-catalog-to-top-level attached-page catalog quickstart note, the suite-catalog guide note, the top-level attached-page companion note, the suite-router attached-page quickstart note, the Windows replay quickstart note, and the validation-chain note nearby when you want the written route beside these commands.'
    )
}

$helper.recommended_next_key = if ($helper.explicit_input_path_count -gt 0) {
    'attached_bundle_suite_surface'
} elseif (-not [string]::IsNullOrWhiteSpace($helper.summary_path)) {
    'contextual_flow'
} else {
    'top_level_attached_html_entrypoint'
}
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.recommended_next_key -eq 'attached_bundle_suite_surface') {
    'Explicit input paths are already in play, so keep the replay pinned to the known three-page compatibility bundle by reopening the compact suite-level bundle surface before narrowing into the bundle-first helper or the delegated bundle runner.'
} elseif ($helper.recommended_next_key -eq 'contextual_flow') {
    'A saved summary is already in play, so keep that replay context aligned before choosing between the broader attached-page flow helper, the top-level attached-page surface check, the broader Google-shaped attached-page surface check, the issue-specific Google attached-page surface check, the broader Google-shaped attached-page flow helper, the attached-html change-area quickstart, the compact bundle suite surface, the attached bundle proof entrypoint, the validation-router attached-page quickstart, the compact attached-page quickstart, the broader top-level attached-page bridge, the matching shortcut-first bridge, top-level catalog quickstart, the dedicated suite-catalog guide, and the suite-catalog-to-top-level attached-page catalog quickstart, the attached-page bridges, replay shortcuts, the next-step matrix, contextual flow, the bundle-first route, or the safe-route helper.'
} else {
    'No pinned bundle inputs or saved summary are in play yet, so jump straight from the compact top-level attached-page quickstart into the broader top-level attached-page bridge while still keeping the attached-html change-area quickstart, the top-level attached-page surface check, the broader attached-page flow helper, the broader Google-shaped attached-page surface check, the issue-specific Google attached-page surface check, the broader Google-shaped attached-page flow helper, the compact bundle suite surface, the attached bundle proof entrypoint, the validation-router quickstart, the matching shortcut-first bridge, top-level catalog quickstart, the dedicated suite-catalog guide, and the suite-catalog-to-top-level catalog quickstart visible for the same route.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 top-level attached HTML quickstart'
Write-Host ''
if ($helper.repo_root) {
    Write-Host (("Repo root:   {0}") -f $helper.repo_root)
}
if ($helper.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($helper.summary_path)"))
}
if ($helper.browser_exe) {
    Write-Host (("Browser exe: {0}") -f $helper.browser_exe)
}
if ($helper.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $helper.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $helper.recommended_next_command)
Write-Host (("Why:                    {0}") -f $helper.recommended_next_reason)
Write-Host ''
Write-Host 'Windows runbook bridge:'
Write-Host (("  Windows full-use route: {0}") -f $helper.commands.windows_full_use_attached_html_route)
Write-Host ''
Write-Host 'Top-level attached-page entrypoints:'
Write-Host (("  Attached HTML:             {0}") -f $helper.commands.attached_html_change_area)
Write-Host (("  Google attached HTML:      {0}") -f $helper.commands.google_attached_html_change_area)
Write-Host (("  Attached bundle:           {0}") -f $helper.commands.attached_bundle_change_area)
Write-Host (("  Change-area quickstart:    {0}") -f $helper.commands.attached_html_change_area_quickstart)
Write-Host (("  Top-level surface check:   {0}") -f $helper.commands.top_level_attached_html_surface_check)
Write-Host (("  Attached flow helper:      {0}") -f $helper.commands.attached_html_flow)
Write-Host (("  Attached pages audit:      {0}") -f $helper.commands.attached_pages_sidecar_audit)
Write-Host (("  Google surface check:      {0}") -f $helper.commands.google_attached_html_surface_check)
Write-Host (("  Issue-specific Google:     {0}") -f $helper.commands.google_issue3_attached_html_surface_check)
Write-Host (("  Google flow helper:        {0}") -f $helper.commands.google_attached_html_flow)
Write-Host (("  Bundle suite surface:      {0}") -f $helper.commands.attached_bundle_suite_surface)
Write-Host (("  Bundle proof helper:       {0}") -f $helper.commands.attached_bundle_proof_entrypoint)
Write-Host (("  Validation-router quick:   {0}") -f $helper.commands.validation_router_attached_html_quickstart)
Write-Host (("  Attached quickstart:       {0}") -f $helper.commands.top_level_attached_html_quickstart)
Write-Host (("  Attached bridge:           {0}") -f $helper.commands.top_level_attached_html_entrypoint)
Write-Host (("  Shortcut-first bridge:     {0}") -f $helper.commands.top_level_shortcut_entrypoint)
Write-Host (("  Catalog quickstart:        {0}") -f $helper.commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  Catalog-side quickstart:   {0}") -f $helper.commands.suite_catalog_top_level_attached_html_catalog_quickstart)
Write-Host ''
Write-Host 'Compact follow-up helpers:'
Write-Host (("  Top-level surface check:   {0}") -f $helper.commands.top_level_attached_html_surface_check)
Write-Host (("  Attached pages audit:      {0}") -f $helper.commands.attached_pages_sidecar_audit)
Write-Host (("  Google surface check:      {0}") -f $helper.commands.google_attached_html_surface_check)
Write-Host (("  Issue-specific Google:     {0}") -f $helper.commands.google_issue3_attached_html_surface_check)
Write-Host (("  Suite-catalog guide:       {0}") -f $helper.commands.suite_catalog_entrypoints)
Write-Host (("  Suite-router quickstart:   {0}") -f $helper.commands.suite_router_attached_html_quickstart)
Write-Host (("  Catalog attached bridge:   {0}") -f $helper.commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  Google attached bridge:    {0}") -f $helper.commands.google_attached_html_entrypoint)
Write-Host (("  Attached shortcut:         {0}") -f $helper.commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:          {0}") -f $helper.commands.replay_shortcuts)
Write-Host (("  Next-step matrix:          {0}") -f $helper.commands.suite_router_next_steps)
Write-Host (("  Contextual flow:           {0}") -f $helper.commands.contextual_flow)
Write-Host (("  Bundle suite surface:      {0}") -f $helper.commands.attached_bundle_suite_surface)
Write-Host (("  Bundle proof helper:       {0}") -f $helper.commands.attached_bundle_proof_entrypoint)
Write-Host (("  Bundle-first helper:       {0}") -f $helper.commands.attached_bundle_first)
Write-Host (("  Safe-route map:            {0}") -f $helper.commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Windows full-use route:     {0}") -f (' ' + $helper.windows_full_use_attached_html_route_note_path))
Write-Host (("Change-area quickstart:     {0}") -f (' ' + $helper.attached_html_change_area_quickstart_note_path))
Write-Host (("Validation-router quick:    {0}") -f (' ' + $helper.validation_router_attached_html_quickstart_note_path))
Write-Host (("Top-level quickstart:       {0}") -f (' ' + $helper.top_level_attached_html_quickstart_note_path))
Write-Host (("Top-level bridge note:      {0}") -f (' ' + $helper.top_level_attached_html_bridge_note_path))
Write-Host (("Google flow note:           {0}") -f (' ' + $helper.google_attached_html_validation_flow_note_path))
Write-Host (("Google attached note:       {0}") -f (' ' + $helper.google_attached_html_entrypoint_note_path))
Write-Host (("Bundle reference note:      {0}") -f (' ' + $helper.attached_bundle_reference_note_path))
Write-Host (("Bundle quickstart note:     {0}") -f (' ' + $helper.attached_bundle_quickstart_note_path))
Write-Host (("Bundle checklist note:      {0}") -f (' ' + $helper.attached_bundle_checklist_note_path))
Write-Host (("Bundle suite note:          {0}") -f (' ' + $helper.attached_bundle_suite_surface_note_path))
Write-Host (("Bundle proof note:          {0}") -f (' ' + $helper.attached_bundle_proof_note_path))
Write-Host (("Shortcut-first note:        {0}") -f (' ' + $helper.top_level_shortcut_first_entrypoint_note_path))
Write-Host (("Shortcut bridge note:       {0}") -f (' ' + $helper.top_level_shortcut_bridge_note_path))
Write-Host (("Catalog quickstart note:    {0}") -f (' ' + $helper.top_level_attached_html_catalog_quickstart_note_path))
Write-Host (("Catalog-side quick note:    {0}") -f (' ' + $helper.suite_catalog_top_level_attached_html_catalog_quickstart_note_path))
Write-Host (("Suite-catalog guide:        {0}") -f (' ' + $helper.suite_catalog_entrypoints_note_path))
Write-Host (("Companion notes:            {0}") -f (' ' + $helper.top_level_attached_html_companion_note_path))
Write-Host (("Suite-router quickstart:    {0}") -f (' ' + $helper.suite_router_attached_html_quickstart_note_path))
Write-Host (("Windows replay note:        {0}") -f (' ' + $helper.windows_replay_quickstart_note_path))
Write-Host (("Validation chain note:      {0}") -f (' ' + $helper.validation_chain_note_path))
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}