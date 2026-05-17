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
        $fallbackArguments = Format-ArgumentList -Arguments $Arguments
        return Format-HelperCommand -ScriptName $ScriptName -Arguments $fallbackArguments -Switches $Switches
    }

    $command = "& '.\scripts\windows\$ScriptName'"
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

$reentryArguments = [ordered]@{}
if ($RepoRoot) {
    $reentryArguments['RepoRoot'] = $RepoRoot
}
if ($SummaryPath) {
    $reentryArguments['SummaryPath'] = $SummaryPath
}
if ($InputPath -and $InputPath.Count -gt 0) {
    $reentryArguments['InputPath'] = @($InputPath)
}

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$bundleSurfaceCheckArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleSurfaceCheckArguments -Name RepoRoot -Value $RepoRoot

$googleAttachedArguments = [ordered]@{}
if ($RepoRoot) {
    $googleAttachedArguments['RepoRoot'] = $RepoRoot
}
if ($InputPath -and $InputPath.Count -gt 0) {
    $googleAttachedArguments['InputPath'] = @($InputPath)
}

$localFixtureArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $localFixtureArguments -Name RepoRoot -Value $RepoRoot
if ($InputPath -and $InputPath.Count -gt 0) {
    Add-SharedPathArrayArgument -Arguments $localFixtureArguments -Name FixturePaths -Values $InputPath
} else {
    $localFixtureArguments.Add('-FixturePaths')
    $localFixtureArguments.Add("'<bundle-html-or-folder>'")
}

$surface = [ordered]@{
    issue = 'Google issue #3 attached-html validation router surface'
    purpose = 'Print a structured attached-html router surface that keeps the broader attached-page lane, the Google-shaped attached-page lane, and the pinned three-page bundle lane together for automation-friendly replay selection.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    top_level_router_commands = [ordered]@{
        google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ SuiteName = 'google-recommended' }) -RepoRootOverride $RepoRoot
        attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'attached-html' }) -RepoRootOverride $RepoRoot
        google_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-attached-html' }) -RepoRootOverride $RepoRoot
        attached_html_target_bundle = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'attached-html-target-bundle' }) -RepoRootOverride $RepoRoot
    }
    issue3_reentry_commands = [ordered]@{
        top_level_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments (Format-ArgumentList -Arguments $reentryArguments)
        attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments (Format-ArgumentList -Arguments $reentryArguments)
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments (Format-ArgumentList -Arguments $reentryArguments)
        top_level_shortcut_first = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments (Format-ArgumentList -Arguments $reentryArguments)
        suite_catalog_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments (Format-ArgumentList -Arguments $reentryArguments)
        next_step_matrix = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments (Format-ArgumentList -Arguments $reentryArguments)
        bundle_first_helper = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments (Format-ArgumentList -Arguments $reentryArguments)
    }
    flow_commands = [ordered]@{
        broader_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $googleAttachedArguments -RepoRootOverride $RepoRoot
        google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -Arguments ([ordered]@{}) -RepoRootOverride $RepoRoot
        google_attached_html_asset_closure = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_attached_html_local_asset_closure.ps1' -Arguments $googleAttachedArguments -Switches @('GoogleStyle') -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedArguments -RepoRootOverride $RepoRoot
        google_attached_html_runner = Format-HelperCommandWithRepoRootEnv -ScriptName 'run_google_attached_html_validation.ps1' -Arguments $googleAttachedArguments -Switches @('Wait') -RepoRootOverride $RepoRoot
        bundle_surface_check = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $bundleSurfaceCheckArguments
        bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleArguments
        bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleArguments -Switches @('Wait')
        local_fixture_surface_check = Format-HelperCommand -ScriptName 'check_local_html_fixture_validation_surface.ps1' -Arguments $bundleSurfaceCheckArguments
        local_fixture_probe = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1 " + ($localFixtureArguments -join ' ')
    }
    notes = @(
        'Use the top-level router commands when you want the suite router to stay as the first read-first surface instead of jumping immediately into the narrower issue #3 helpers.',
        'Use the issue #3 re-entry commands when the replay is already narrowed to attached localhost work and you want the compact helper family printed before execution.',
        'Use the broader attached-page flow when the current pages do not match the known three-page compatibility bundle.',
        'Use the Google-shaped attached-page surface check, asset audit, flow, and runner when the current pages include a Google-like page and the issue #3 route should stay explicit.',
        'Use the bundle surface check, bundle flow, and bundle runner when the current workspace still holds the known three-page compatibility set.',
        'Use the local fixture surface check and probe after the bundle route is green and you want a smaller screenshot-and-title proof surface for the same locked inputs.'
    )
}

$surface.recommended_next_key = if ($surface.explicit_input_path_count -gt 0) {
    'bundle_first_helper'
} else {
    'attached_html'
}
$surface.recommended_next_command = if ($surface.explicit_input_path_count -gt 0) {
    $surface.issue3_reentry_commands.bundle_first_helper
} else {
    $surface.top_level_router_commands.attached_html
}
$surface.recommended_next_reason = if ($surface.explicit_input_path_count -gt 0) {
    'Explicit attached-page paths are already pinned, so keep that same context on the narrower issue #3 bridge before you delegate into the bundle-only flow or widen back to the broader attached-page lane.'
} else {
    'No explicit attached-page bundle paths are pinned yet, so reopen the broader attached-page route first and let the router decide whether the replay should stay broad, go Google-shaped, or lock onto the three-page bundle.'
}

if ($Json) {
    $surface | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 attached-html validation router surface'
Write-Host ''
if ($surface.repo_root) {
    Write-Host (("Repo root:   {0}") -f $surface.repo_root)
}
if ($surface.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($surface.summary_path)"))
}
if ($surface.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $surface.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $surface.recommended_next_command)
Write-Host (("Why:                    {0}") -f $surface.recommended_next_reason)
Write-Host ''
Write-Host 'Top-level router commands:'
Write-Host (("  Google recommended:    {0}") -f $surface.top_level_router_commands.google_recommended)
Write-Host (("  Attached HTML:        {0}") -f $surface.top_level_router_commands.attached_html)
Write-Host (("  Google attached HTML: {0}") -f $surface.top_level_router_commands.google_attached_html)
Write-Host (("  Bundle route:         {0}") -f $surface.top_level_router_commands.attached_html_target_bundle)
Write-Host ''
Write-Host 'Issue #3 re-entry commands:'
Write-Host (("  Top-level route:      {0}") -f $surface.issue3_reentry_commands.top_level_attached_html_route)
Write-Host (("  Quickstart:           {0}") -f $surface.issue3_reentry_commands.attached_html_quickstart)
Write-Host (("  Shortcut:             {0}") -f $surface.issue3_reentry_commands.attached_html_shortcut)
Write-Host (("  Shortcut-first:       {0}") -f $surface.issue3_reentry_commands.top_level_shortcut_first)
Write-Host (("  Suite-catalog bridge: {0}") -f $surface.issue3_reentry_commands.suite_catalog_bridge)
Write-Host (("  Next-step matrix:     {0}") -f $surface.issue3_reentry_commands.next_step_matrix)
Write-Host (("  Bundle-first helper:  {0}") -f $surface.issue3_reentry_commands.bundle_first_helper)
Write-Host ''
Write-Host 'Flow commands:'
Write-Host (("  Broader flow:         {0}") -f $surface.flow_commands.broader_attached_html_flow)
Write-Host (("  Google surface check: {0}") -f $surface.flow_commands.google_attached_html_surface_check)
Write-Host (("  Google asset audit:   {0}") -f $surface.flow_commands.google_attached_html_asset_closure)
Write-Host (("  Google flow:          {0}") -f $surface.flow_commands.google_attached_html_flow)
Write-Host (("  Google runner:        {0}") -f $surface.flow_commands.google_attached_html_runner)
Write-Host (("  Bundle surface check: {0}") -f $surface.flow_commands.bundle_surface_check)
Write-Host (("  Bundle flow:          {0}") -f $surface.flow_commands.bundle_flow)
Write-Host (("  Bundle runner:        {0}") -f $surface.flow_commands.bundle_runner)
Write-Host (("  Fixture surface:      {0}") -f $surface.flow_commands.local_fixture_surface_check)
Write-Host (("  Fixture probe:        {0}") -f $surface.flow_commands.local_fixture_probe)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $surface.notes) {
    Write-Host (("  - {0}") -f $note)
}
