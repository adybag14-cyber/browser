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

function Format-PowerShellFileCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [System.Collections.Generic.List[string]]$Arguments,
        [string[]]$Switches = @()
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\$RelativePath"
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
        if ($value -is [System.Array]) {
            $valueList = @($value | Where-Object { -not [string]::IsNullOrWhiteSpace("$_") })
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
        $command += " -$($entry.Key) '$escapedValue'"
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
Add-SharedArgument -Arguments $bundleArguments -Name BrowserExe -Value $BrowserExe
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$bundleSurfaceArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleSurfaceArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleSurfaceArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $bundleSurfaceArguments -Name BrowserExe -Value $BrowserExe
Add-SharedPathArrayArgument -Arguments $bundleSurfaceArguments -Name InputPath -Values $InputPath

$bundleFirstArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleFirstArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleFirstArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $bundleFirstArguments -Name BrowserExe -Value $BrowserExe
Add-SharedPathArrayArgument -Arguments $bundleFirstArguments -Name InputPath -Values $InputPath

$reentryArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $reentryArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $reentryArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $reentryArguments -Name InputPath -Values $InputPath

$fixtureSurfaceArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $fixtureSurfaceArguments -Name RepoRoot -Value $RepoRoot

$fixtureProbeArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $fixtureProbeArguments -Name RepoRoot -Value $RepoRoot
if ($InputPath -and $InputPath.Count -gt 0) {
    Add-SharedPathArrayArgument -Arguments $fixtureProbeArguments -Name FixturePaths -Values $InputPath
} else {
    $fixtureProbeArguments.Add('-FixturePaths')
    $fixtureProbeArguments.Add("'<bundle-html-or-folder>'")
}

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath -and $InputPath.Count -gt 0) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$googleAttachedHtmlFlowArguments = [ordered]@{}
if ($InputPath -and $InputPath.Count -gt 0) {
    $googleAttachedHtmlFlowArguments['InputPath'] = @($InputPath)
}
if ($BrowserExe) {
    $googleAttachedHtmlFlowArguments['BrowserExe'] = $BrowserExe
}

$attachedHtmlSuiteArguments = [ordered]@{
    ChangeArea = 'attached-html'
}
if ($InputPath -and $InputPath.Count -gt 0) {
    $attachedHtmlSuiteArguments['InputPath'] = @($InputPath)
}
if ($BrowserExe) {
    $attachedHtmlSuiteArguments['BrowserExe'] = $BrowserExe
}

$googleAttachedHtmlSuiteArguments = [ordered]@{
    ChangeArea = 'google-attached-html'
}
if ($InputPath -and $InputPath.Count -gt 0) {
    $googleAttachedHtmlSuiteArguments['InputPath'] = @($InputPath)
}
if ($BrowserExe) {
    $googleAttachedHtmlSuiteArguments['BrowserExe'] = $BrowserExe
}

$attachedBundleSuiteArguments = [ordered]@{
    ChangeArea = 'attached-html-target-bundle'
}
if ($InputPath -and $InputPath.Count -gt 0) {
    $attachedBundleSuiteArguments['InputPath'] = @($InputPath)
}
if ($BrowserExe) {
    $attachedBundleSuiteArguments['BrowserExe'] = $BrowserExe
}

$bridge = [ordered]@{
    issue = 'Google issue #3 replay-route bundle-first bridge'
    purpose = 'Print the shortest replay-route-to-bundle bridge for the known three-page attached HTML compatibility set while keeping the broader attached-page and Google-shaped attached-page follow-up surfaces visible beside the pinned bundle lane.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    browser_exe = $BrowserExe
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    top_level_commands = [ordered]@{
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $reentryArguments
        replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $reentryArguments
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $attachedHtmlSuiteArguments -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $googleAttachedHtmlSuiteArguments -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $attachedBundleSuiteArguments -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $bundleSurfaceArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleFirstArguments
        attached_bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleArguments
        attached_bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleArguments -Switches @('Wait')
        local_fixture_surface_check = Format-HelperCommand -ScriptName 'check_local_html_fixture_validation_surface.ps1' -Arguments $fixtureSurfaceArguments
        local_fixture_probe = Format-PowerShellFileCommand -RelativePath 'tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1' -Arguments $fixtureProbeArguments
    }
    note_paths = [ordered]@{
        replay_route_shortcut_bridge = 'docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md'
        attached_html_target_bundle_reference = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
        attached_html_target_bundle_suite_surface = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md'
        attached_html_target_bundle_quickstart = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md'
        attached_html_target_bundle_checklist = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md'
        google_attached_html_validation_flow = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
        top_level_attached_html_bridge = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
        windows_replay_attached_html_quickstart = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
        windows_full_use_attached_html_route = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
        suite_catalog_entrypoints = 'docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md'
        validation_chain = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    }
    notes = @(
        'Use this helper when issue #3 replay is already near show_google_issue3_replay_route.ps1 and the next run should stay pinned to the known three-page attached HTML compatibility bundle before widening back into the broader safe-route helpers.',
        'Start with replay_route when you still want the current issue #3 command surface printed before the bundle route narrows.',
        'Use replay_route_shortcut when the replay-route helper is already open and you want the shorter printed bridge kept visible before the compact bundle-suite surface or the narrower bundle-first helper takes over.',
        'Keep attached_html_flow visible when the broader attached-page localhost lane still matters before the bundle decision.',
        'Keep google_attached_html_flow visible when the current attached inputs are already Google-shaped and you want that narrower attached-page flow helper reprinted before the bundle branch.',
        'Use attached_bundle_suite_surface when you want the compact bundle-suite surface reprinted before the bundle-first helper so the pinned bundle lane stays visible beside the broader attached-page and Google-shaped attached-page fallbacks.',
        'Use attached_bundle_first when the replay should stay on the pinned three-page compatibility set before reopening the broader helper chain.',
        'Use attached_bundle_flow when you want the exact bundle checker and delegated runner printed before execution.',
        'Use attached_bundle_runner when the next useful decision depends on the pinned bundle replay outcome instead of a wider wrapper pass.',
        'Pass -BrowserExe when the replay should keep a non-default Windows headed build pinned through the suite router handoff, the compact bundle-suite surface, the bundle-first helper, and the delegated bundle runner instead of drifting back to .\\zig-out\\bin\\lightpanda.exe.',
        'After the bundle runner turns green, reopen local_fixture_surface_check and local_fixture_probe so the same pinned bundle can pass through the reusable screenshot-and-title proof path before the route widens again.'
    )
}

$bridge.recommended_next_helper_key = if ($bridge.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} else {
    'attached_bundle_suite_surface'
}
$bridge.recommended_next_helper_command = $bridge.helper_commands[$bridge.recommended_next_helper_key]
$bridge.recommended_next_helper_reason = if ($bridge.recommended_next_helper_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so keep that same bundle context on the narrower bundle-first helper before you delegate into the bundle flow and runner.'
} else {
    'No explicit bundle inputs are pinned yet, so reopen the compact bundle-suite surface first while the broader attached-page and Google-shaped attached-page fallbacks remain visible.'
}

if ($Json) {
    $bridge | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 replay-route bundle-first bridge'
Write-Host ''
if ($bridge.repo_root) {
    Write-Host (("Repo root:   {0}") -f $bridge.repo_root)
}
if ($bridge.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($bridge.summary_path)"))
}
if ($bridge.browser_exe) {
    Write-Host (("Browser exe: {0}") -f $bridge.browser_exe)
}
if ($bridge.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $bridge.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $bridge.recommended_next_helper_command)
Write-Host (("Why:                    {0}") -f $bridge.recommended_next_helper_reason)
Write-Host ''
Write-Host 'Replay-route bridge:'
Write-Host (("  1. Replay route:        {0}") -f $bridge.top_level_commands.replay_route)
Write-Host (("  2. Replay shortcut:     {0}") -f $bridge.top_level_commands.replay_route_shortcut)
Write-Host (("  3. Attached HTML:       {0}") -f $bridge.top_level_commands.attached_html_change_area)
Write-Host (("  4. Google attached:     {0}") -f $bridge.top_level_commands.google_attached_html_change_area)
Write-Host (("  5. Bundle change area:  {0}") -f $bridge.top_level_commands.attached_bundle_change_area)
Write-Host ''
Write-Host 'Pinned bundle follow-up:'
Write-Host (("  Attached flow:          {0}") -f $bridge.helper_commands.attached_html_flow)
Write-Host (("  Google attached flow:   {0}") -f $bridge.helper_commands.google_attached_html_flow)
Write-Host (("  Bundle suite surface:   {0}") -f $bridge.helper_commands.attached_bundle_suite_surface)
Write-Host (("  Bundle first:           {0}") -f $bridge.helper_commands.attached_bundle_first)
Write-Host (("  Bundle flow:            {0}") -f $bridge.helper_commands.attached_bundle_flow)
Write-Host (("  Bundle runner:          {0}") -f $bridge.helper_commands.attached_bundle_runner)
Write-Host ''
Write-Host 'Proof after bundle replay:'
Write-Host (("  Fixture surface check:  {0}") -f $bridge.helper_commands.local_fixture_surface_check)
Write-Host (("  Fixture probe:          {0}") -f $bridge.helper_commands.local_fixture_probe)
Write-Host ''
Write-Host 'Notes:'
Write-Host (("  Replay shortcut note:   {0}") -f $bridge.note_paths.replay_route_shortcut_bridge)
Write-Host (("  Bundle reference note:  {0}") -f $bridge.note_paths.attached_html_target_bundle_reference)
Write-Host (("  Bundle suite note:      {0}") -f $bridge.note_paths.attached_html_target_bundle_suite_surface)
Write-Host (("  Bundle quickstart note: {0}") -f $bridge.note_paths.attached_html_target_bundle_quickstart)
Write-Host (("  Bundle checklist note:  {0}") -f $bridge.note_paths.attached_html_target_bundle_checklist)
Write-Host (("  Google flow note:       {0}") -f $bridge.note_paths.google_attached_html_validation_flow)
Write-Host (("  Top-level bridge note:  {0}") -f $bridge.note_paths.top_level_attached_html_bridge)
Write-Host (("  Replay quickstart note: {0}") -f $bridge.note_paths.windows_replay_attached_html_quickstart)
Write-Host (("  Windows route note:     {0}") -f $bridge.note_paths.windows_full_use_attached_html_route)
Write-Host (("  Suite-catalog note:     {0}") -f $bridge.note_paths.suite_catalog_entrypoints)
Write-Host (("  Validation chain note:  {0}") -f $bridge.note_paths.validation_chain)
Write-Host ''
Write-Host 'Guidance:'
foreach ($note in $bridge.notes) {
    Write-Host (("- {0}") -f $note)
}
