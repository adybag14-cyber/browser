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

function Format-ArgumentList {
    param(
        [hashtable]$Arguments = @{}
    )

    $parts = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in $Arguments.GetEnumerator()) {
        $value = $entry.Value
        if ($null -eq $value) {
            continue
        }

        if ($value -is [System.Array]) {
            $items = @($value | Where-Object { -not [string]::IsNullOrWhiteSpace("$_") })
            if ($items.Count -eq 0) {
                continue
            }

            $parts.Add("-$($entry.Key)")
            foreach ($item in $items) {
                $parts.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value "$item"))
            }
            continue
        }

        if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        $parts.Add("-$($entry.Key)")
        $parts.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value "$value"))
    }

    return $parts
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

function Format-PowerShellFileCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [string[]]$Switches = @(),
        [System.Collections.Generic.List[string]]$Arguments
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\\$RelativePath"
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
        $fallbackArguments = Format-ArgumentList -Arguments $Arguments
        return Format-HelperCommand -ScriptName $ScriptName -Arguments $fallbackArguments -Switches $Switches
    }

    $command = "& '.\\scripts\\windows\\$ScriptName'"
    $parts = Format-ArgumentList -Arguments $Arguments
    if ($parts.Count -gt 0) {
        $command += " " + ($parts -join ' ')
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

$bundleSurfaceCheckArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleSurfaceCheckArguments -Name RepoRoot -Value $RepoRoot

$bundleCheckerArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleCheckerArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleCheckerArguments -Name InputPath -Values $InputPath

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$localHtmlFixtureSurfaceArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $localHtmlFixtureSurfaceArguments -Name RepoRoot -Value $RepoRoot

$localHtmlFixtureProbeArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $localHtmlFixtureProbeArguments -Name RepoRoot -Value $RepoRoot
if ($InputPath -and $InputPath.Count -gt 0) {
    Add-SharedPathArrayArgument -Arguments $localHtmlFixtureProbeArguments -Name FixturePaths -Values $InputPath
} else {
    $localHtmlFixtureProbeArguments.Add('-FixturePaths')
    $localHtmlFixtureProbeArguments.Add("'<bundle-html-or-folder>'")
}

$reentryArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $reentryArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $reentryArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $reentryArguments -Name InputPath -Values $InputPath

$safeRouteArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $safeRouteArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $safeRouteArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $safeRouteArguments -Name InputPath -Values $InputPath

$replayShortcutsArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $replayShortcutsArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $replayShortcutsArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $replayShortcutsArguments -Name InputPath -Values $InputPath

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$entrypoint = [ordered]@{
    issue = 'Google issue #3 attached bundle first entrypoint'
    purpose = 'Print the pinned three-page compatibility bundle route first while keeping the replay-side attached-html quickstart, the top-level attached-page quickstart, the issue-specific attached-page shortcut, the broader attached-page flow helper, the narrower Google-shaped attached-page flow guide, and the reusable fixed-list proof path visible as the narrow re-entry ladder immediately before and after the bundle-only branch.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    broader_attached_html_suite_router_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
        ChangeArea = 'attached-html'
    }) -RepoRootOverride $RepoRoot
    google_attached_html_suite_router_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
        ChangeArea = 'google-attached-html'
    }) -RepoRootOverride $RepoRoot
    windows_replay_attached_html_quickstart_command = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $reentryArguments
    top_level_attached_html_quickstart_command = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $reentryArguments
    attached_html_shortcut_command = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $reentryArguments
    attached_html_flow_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
    google_attached_html_flow_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
    bundle_surface_check_command = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $bundleSurfaceCheckArguments
    bundle_check_command = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle.ps1' -Arguments $bundleCheckerArguments
    suite_router_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
        ChangeArea = 'attached-html-target-bundle'
    }) -RepoRootOverride $RepoRoot
    bundle_flow_command = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleArguments
    bundle_runner_command = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleArguments -Switches @('Wait')
    local_html_fixture_surface_check_command = Format-HelperCommand -ScriptName 'check_local_html_fixture_validation_surface.ps1' -Arguments $localHtmlFixtureSurfaceArguments
    local_html_fixture_probe_command = Format-PowerShellFileCommand -RelativePath 'tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1' -Arguments $localHtmlFixtureProbeArguments
    replay_shortcuts_command = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $replayShortcutsArguments
    return_to_safe_route_command = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $safeRouteArguments
    windows_replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    windows_replay_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    attached_html_shortcut_note_path = 'docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    attached_html_target_bundle_reference_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
    attached_html_target_bundle_quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md'
    attached_html_target_bundle_checklist_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    notes = @(
        'Use this helper when the current saved or attached pages are still the known three-page compatibility bundle and you want the narrower replay-side attached-html quickstart, the top-level attached-page quickstart, the issue-specific attached-page shortcut, the broader attached-page flow helper, the narrower Google-shaped attached-page flow guide, and the reusable fixed-list proof path kept visible just long enough to confirm the replay should stay pinned to that bundle.',
        'Use broader_attached_html_suite_router_command first when the next replay is still being chosen from the wider attached-page router and you want the generic attached-page branch visible before the replay narrows back into the pinned bundle-only lane.',
        'Use google_attached_html_suite_router_command next when the current replay should keep the Google-shaped attached-page route visible beside the broader attached-page branch before the bundle-only branch takes over.',
        'Use windows_replay_attached_html_quickstart_command first when the replay reopened from the broader Windows replay route and you want the newer attached-html ladder visible before you commit to the bundle-only branch.',
        'Use top_level_attached_html_quickstart_command next when you want the compact top-level attached-page bridge kept visible before the replay drops from the replay-side attached-html ladder into the pinned bundle route.',
        'Use attached_html_shortcut_command next when the route is already clearly inside the shorter attached-page helper chain and you want explicit bundle inputs preserved before the replay narrows into the bundle-only branch.',
        'Use attached_html_flow_command when you want the broader attached-page localhost helper reprinted beside the replay-side and top-level quickstarts before the route narrows into the pinned bundle branch.',
        'Use google_attached_html_flow_command when the current bundle still includes a Google-like attached page and you want the dedicated Google-shaped attached-page guide reprinted beside the broader attached-page helper before the replay commits to the bundle-only branch.',
        'Start with bundle_surface_check_command so the pinned bundle reference note, bundle quickstart, pinned manual checklist, checker, helper, runner, and delegated attached-html surfaces fail fast before localhost replay.',
        'Run bundle_check_command next when you want the current saved-page set revalidated as the same three-page compatibility bundle before you trust the printed flow helper or runner.',
        'Use suite_router_command when you want the attached-html-target-bundle suite surface reprinted beside the broader attached-page suite routers, the broader attached-page flow helper, the dedicated Google-shaped attached-page guide, the bundle checker, and the bundle flow helper before the delegated localhost runner.',
        'After the bundle runner turns green, reopen local_html_fixture_surface_check_command and local_html_fixture_probe_command so the same pinned bundle can pass through the reusable screenshot-and-title proof path before the route widens back into the larger issue #3 helper chain.',
        'Pass -InputPath when you want to keep an explicit bundle path or fixed file list pinned through the bundle check, the broader attached-page flow helper, the Google-shaped attached-page flow guide, the flow, runner, local fixture proof command, replay-shortcuts helper, and safe-route return command instead of relying on auto-discovery.',
        'Pass -RepoRoot and -SummaryPath when the replay is running from a non-default checkout and you want the replay-side attached-html quickstart, the top-level quickstart, the attached-page shortcut, the broader attached-page suite routers, the broader attached-page flow helper, the dedicated Google-shaped attached-page guide, the replay-shortcuts helper, and the safe-route return commands to preserve that same context.',
        'Use replay_shortcuts_command after the bundle replay when you want the broader issue #3 discovery bridge, attached-bundle branch, and safe-route shortcuts printed together before choosing whether to stay broad or narrow next.',
        'Return to the broader issue #3 safe-route helper only after the bundle replay or the reusable fixed-list proof path makes the next Google-style input or submit failure state clear.',
        'Keep the Windows replay note, the replay-side attached-html quickstart note, the top-level attached-page quickstart note, the attached-page shortcut note, the Google attached-page flow note, the attached-html target-bundle reference note, the attached-html target-bundle quickstart note, the pinned manual checklist note, and the validation-chain note nearby when you want the written route beside these commands.'
    )
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 attached bundle first entrypoint'
Write-Host ''
if ($entrypoint.repo_root) {
    Write-Host ("Repo root:   {0}" -f $entrypoint.repo_root)
}
if ($entrypoint.summary_path) {
    Write-Host ("Summary path:{0}" -f " $($entrypoint.summary_path)")
}
if ($entrypoint.explicit_input_path_count -gt 0) {
    Write-Host ("Input paths: {0}" -f $entrypoint.explicit_input_path_count)
}
Write-Host ''
Write-Host 'Re-enter before bundle route:'
Write-Host ("  Broader suite router:      {0}" -f $entrypoint.broader_attached_html_suite_router_command)
Write-Host ("  Google suite router:       {0}" -f $entrypoint.google_attached_html_suite_router_command)
Write-Host ("  Windows replay quickstart: {0}" -f $entrypoint.windows_replay_attached_html_quickstart_command)
Write-Host ("  Top-level quickstart:      {0}" -f $entrypoint.top_level_attached_html_quickstart_command)
Write-Host ("  Attached shortcut:         {0}" -f $entrypoint.attached_html_shortcut_command)
Write-Host ("  Attached flow helper:      {0}" -f $entrypoint.attached_html_flow_command)
Write-Host ("  Google attached flow:      {0}" -f $entrypoint.google_attached_html_flow_command)
Write-Host ''
Write-Host 'Bundle-first route:'
Write-Host ("  Surface check: {0}" -f $entrypoint.bundle_surface_check_command)
Write-Host ("  Bundle check:  {0}" -f $entrypoint.bundle_check_command)
Write-Host ("  Suite router:  {0}" -f $entrypoint.suite_router_command)
Write-Host ("  Flow helper:   {0}" -f $entrypoint.bundle_flow_command)
Write-Host ("  Runner:        {0}" -f $entrypoint.bundle_runner_command)
Write-Host ''
Write-Host 'Proof after bundle replay:'
Write-Host ("  Local fixture surface: {0}" -f $entrypoint.local_html_fixture_surface_check_command)
Write-Host ("  Fixed-list proof:     {0}" -f $entrypoint.local_html_fixture_probe_command)
Write-Host ''
Write-Host 'Return after bundle replay:'
Write-Host ("  Replay shortcuts: {0}" -f $entrypoint.replay_shortcuts_command)
Write-Host ("  Safe route:       {0}" -f $entrypoint.return_to_safe_route_command)
Write-Host ''
Write-Host ("Windows replay note:          {0}" -f $entrypoint.windows_replay_quickstart_note_path)
Write-Host ("Replay attached-html note:    {0}" -f $entrypoint.windows_replay_attached_html_quickstart_note_path)
Write-Host ("Top-level quickstart note:    {0}" -f $entrypoint.top_level_attached_html_quickstart_note_path)
Write-Host ("Attached shortcut note:       {0}" -f $entrypoint.attached_html_shortcut_note_path)
Write-Host ("Google flow note:             {0}" -f $entrypoint.google_attached_html_validation_flow_note_path)
Write-Host ("Bundle reference note:        {0}" -f $entrypoint.attached_html_target_bundle_reference_note_path)
Write-Host ("Bundle quickstart note:       {0}" -f $entrypoint.attached_html_target_bundle_quickstart_note_path)
Write-Host ("Pinned checklist note:        {0}" -f $entrypoint.attached_html_target_bundle_checklist_note_path)
Write-Host ("Validation chain note:        {0}" -f $entrypoint.validation_chain_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host ("- {0}" -f $note)
}
