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

$bundleOnlyArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleOnlyArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleOnlyArguments -Name InputPath -Values $InputPath

$attachedHtmlChangeAreaArguments = [ordered]@{
    ChangeArea = 'attached-html'
}
if ($SummaryPath) {
    $attachedHtmlChangeAreaArguments['SummaryPath'] = $SummaryPath
}
if ($InputPath) {
    $attachedHtmlChangeAreaArguments['InputPath'] = @($InputPath)
}

$googleAttachedHtmlChangeAreaArguments = [ordered]@{
    ChangeArea = 'google-attached-html'
}
if ($SummaryPath) {
    $googleAttachedHtmlChangeAreaArguments['SummaryPath'] = $SummaryPath
}
if ($InputPath) {
    $googleAttachedHtmlChangeAreaArguments['InputPath'] = @($InputPath)
}

$attachedBundleChangeAreaArguments = [ordered]@{
    ChangeArea = 'attached-html-target-bundle'
}
if ($SummaryPath) {
    $attachedBundleChangeAreaArguments['SummaryPath'] = $SummaryPath
}
if ($InputPath) {
    $attachedBundleChangeAreaArguments['InputPath'] = @($InputPath)
}

$recommendedKey = if ($InputPath -and @($InputPath).Count -gt 0) {
    'bundle_suite_surface'
} else {
    'windows_full_use_route'
}
$recommendedReason = if ($recommendedKey -eq 'bundle_suite_surface') {
    'Explicit bundle input paths are already pinned, so keep that same context on the compact bundle-suite surface before narrowing into the bundle-first helper.'
} else {
    'No explicit bundle inputs are pinned yet, so reopen the Windows-first attached-page route and its bridge before committing to the pinned three-page bundle branch.'
}

$bridge = [ordered]@{
    issue = 'Google issue #3 Windows full-use attached bundle bridge'
    purpose = 'Keep the Windows-first attached-page route, the validation-router bridge, the Windows replay quickstart, the compact attached-bundle suite surface, the replay-route bundle bridge, the narrower bundle-first helper, and the delegated bundle runner on one read-first helper surface.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    note_paths = [ordered]@{
        windows_full_use = 'docs/WINDOWS_FULL_USE.md'
        bridge = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md'
        windows_route = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
        windows_validation_bridge = 'docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md'
        windows_replay = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
        bundle_reference = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
        bundle_suite_surface = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md'
        replay_route_bundle_first = 'docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md'
    }
    commands = [ordered]@{
        windows_full_use_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $sharedArguments
        windows_validation_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $sharedArguments
        windows_replay_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $sharedArguments
        broader_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $attachedHtmlChangeAreaArguments -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $googleAttachedHtmlChangeAreaArguments -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments $attachedBundleChangeAreaArguments -RepoRootOverride $RepoRoot
        broader_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments ([ordered]@{ InputPath = @($InputPath) }) -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments ([ordered]@{ InputPath = @($InputPath) }) -RepoRootOverride $RepoRoot
        bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedArguments
        replay_route_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_bundle_first_bridge.ps1' -Arguments $sharedArguments
        bundle_first_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
        bundle_surface_check = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $sharedArguments
        bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleOnlyArguments
        bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleOnlyArguments -Switches @('Wait')
    }
    notes = @(
        'Use windows_full_use_route first when docs/WINDOWS_FULL_USE.md or the broader Windows-first attached-page route was the last surface you reopened and no explicit bundle inputs are pinned yet.',
        'Use bundle_suite_surface first when the current attached pages are already the known three-page compatibility bundle and you want the compact suite-level bundle surface before the narrower bundle-first helper.',
        'Keep windows_validation_bridge and windows_replay_quickstart nearby when the route should stay on the Windows-first ladder before it narrows again.',
        'Reopen broader_attached_html_change_area, google_attached_html_change_area, broader_attached_html_flow, and google_attached_html_flow only when the replay no longer obviously belongs on the pinned three-page bundle branch.',
        'Use replay_route_bundle_first when the replay is already inside the replay-route helper family and you want the pinned bundle route plus the broader return path printed together before choosing the next narrower helper.',
        'Use bundle_first_entrypoint after bundle_suite_surface once the current inputs are confirmed to stay on the exact three-page bundle.',
        'Run bundle_surface_check before the delegated bundle runner after branch moves or helper renames so the pinned bundle path fails fast.',
        'Use bundle_flow and then bundle_runner when the bundle checks are green and the pinned three-page route should execute directly.'
    )
}

if ($bridge.explicit_input_path_count -gt 0) {
    $bridge.notes += 'The printed attached-html, google-attached-html, and attached-html-target-bundle router commands preserve the explicit InputPath values through the top-level validation router so the same pinned bundle stays visible after the Windows full-use handoff.'
}
if ($bridge.summary_path) {
    $bridge.notes += 'The printed router commands preserve -SummaryPath through the top-level validation router so saved replay context can be reopened without manual re-entry.'
}

$bridge.recommended_next_key = $recommendedKey
$bridge.recommended_next_command = $bridge.commands[$recommendedKey]
$bridge.recommended_next_reason = $recommendedReason

if ($Json) {
    $bridge | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 Windows full-use attached bundle bridge'
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
Write-Host 'Read-first route:'
Write-Host (("  Windows route:        {0}") -f $bridge.commands.windows_full_use_route)
Write-Host (("  Validation bridge:    {0}") -f $bridge.commands.windows_validation_bridge)
Write-Host (("  Windows replay:       {0}") -f $bridge.commands.windows_replay_quickstart)
Write-Host (("  Attached route:       {0}") -f $bridge.commands.broader_attached_html_change_area)
Write-Host (("  Google attached route:{0}") -f (' ' + $bridge.commands.google_attached_html_change_area))
Write-Host (("  Bundle route:         {0}") -f $bridge.commands.attached_bundle_change_area)
Write-Host (("  Attached flow:        {0}") -f $bridge.commands.broader_attached_html_flow)
Write-Host (("  Google attached flow: {0}") -f $bridge.commands.google_attached_html_flow)
Write-Host (("  Bundle-suite helper:  {0}") -f $bridge.commands.bundle_suite_surface)
Write-Host (("  Replay bundle bridge: {0}") -f $bridge.commands.replay_route_bundle_first)
Write-Host (("  Bundle-first helper:  {0}") -f $bridge.commands.bundle_first_entrypoint)
Write-Host (("  Bundle surface check: {0}") -f $bridge.commands.bundle_surface_check)
Write-Host (("  Bundle flow:          {0}") -f $bridge.commands.bundle_flow)
Write-Host (("  Bundle runner:        {0}") -f $bridge.commands.bundle_runner)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $bridge.notes) {
    Write-Host (("- {0}") -f $note)
}
Write-Host ''
Write-Host 'Companion notes:'
Write-Host (("  Windows runbook:      {0}") -f $bridge.note_paths.windows_full_use)
Write-Host (("  Bundle bridge note:   {0}") -f $bridge.note_paths.bridge)
Write-Host (("  Windows route note:   {0}") -f $bridge.note_paths.windows_route)
Write-Host (("  Validation note:      {0}") -f $bridge.note_paths.windows_validation_bridge)
Write-Host (("  Windows replay note:  {0}") -f $bridge.note_paths.windows_replay)
Write-Host (("  Bundle reference:     {0}") -f $bridge.note_paths.bundle_reference)
Write-Host (("  Bundle-suite note:    {0}") -f $bridge.note_paths.bundle_suite_surface)
Write-Host (("  Replay bundle note:   {0}") -f $bridge.note_paths.replay_route_bundle_first)