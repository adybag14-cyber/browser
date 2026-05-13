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

$entrypoints = [ordered]@{
    issue = 'Google issue #3 suite catalog entrypoints'
    purpose = 'Keep the exact top-level show_headed_validation_suites entrypoints and the current issue #3 replay helpers on one compact command surface before the replay narrows into the shortcut or safe-route wrappers.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    suite_catalog_commands = [ordered]@{
        google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        google_input_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        suite_router_handoff = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Start with google_recommended when you want the broader localhost-first issue #3 runner surfaced from the suite catalog before choosing a narrower branch.',
        'Use google_input_change_area when the next replay may need the title, homepage-fixture, submit-path, shared Enter-order, live-trace, saved-page, or attached-page slices instead of the full recommended runner.',
        'Use attached_bundle_change_area when the current saved or attached inputs are the known three-page compatibility bundle and you want the suite catalog itself to reopen on that pinned branch first.',
        'Use suite_router_handoff when you want the shortest compact bridge back into the higher-level suite-router route before reopening replay-route, replay-shortcuts, attached-bundle-first, or safe-route helpers with the same current context.',
        'Use replay_route when you want the smallest read-first helper that keeps the suite catalog entrypoints, attached-bundle branch, replay-shortcuts helper, and safe-route bridge on one surface before narrowing further.',
        'Use replay_shortcuts after replay_route when you want the narrower shortcut map for the attached-bundle-first route and the wrapper-heavy safe-route branches.',
        'Use attached_bundle_first when explicit input paths are already pinned or when the replay should stay on the known three-page compatibility bundle before widening back into the broader Google-only issue #3 path.',
        'Use safe_route_entrypoints only after the suite catalog, suite-router handoff, replay-route helper, or replay-shortcuts helper has already narrowed the replay into the current wrapper-heavy issue #3 path.',
        'Keep the quickstart, suite-router bridge, and validation-chain notes nearby when you want the written route beside these commands without reopening the broader Windows runbook first.'
    )
}

$entrypoints.recommended_next_key = if ($entrypoints.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($SummaryPath)) {
    'replay_route'
} else {
    'suite_router_handoff'
}
$entrypoints.recommended_next_command = $entrypoints.helper_commands[$entrypoints.recommended_next_key]
$entrypoints.recommended_next_reason = if ($entrypoints.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($entrypoints.recommended_next_key -eq 'replay_route') {
    'A saved SummaryPath is already in play, so reopen the replay-route helper next to preserve that current replay context while keeping the suite catalog and safe-route bridge visible.'
} else {
    'No pinned bundle inputs or current summary are in play yet, so start with the compact suite-router handoff helper before narrowing into replay-route, replay-shortcuts, or the wrapper-heavy safe-route commands.'
}

if ($Json) {
    $entrypoints | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 suite catalog entrypoints'
Write-Host ''
if ($entrypoints.repo_root) {
    Write-Host ("Repo root:   {0}" -f $entrypoints.repo_root)
}
if ($entrypoints.summary_path) {
    Write-Host ("Summary path:{0}" -f " $($entrypoints.summary_path)")
}
if ($entrypoints.explicit_input_path_count -gt 0) {
    Write-Host ("Input paths: {0}" -f $entrypoints.explicit_input_path_count)
}
Write-Host ''
Write-Host ("Recommended next helper: {0}" -f $entrypoints.recommended_next_command)
Write-Host ("Why:                    {0}" -f $entrypoints.recommended_next_reason)
Write-Host ''
Write-Host 'Top-level suite catalog entrypoints:'
Write-Host ("  Google recommended: {0}" -f $entrypoints.suite_catalog_commands.google_recommended)
Write-Host ("  Google input:       {0}" -f $entrypoints.suite_catalog_commands.google_input_change_area)
Write-Host ("  Attached bundle:    {0}" -f $entrypoints.suite_catalog_commands.attached_bundle_change_area)
Write-Host ''
Write-Host 'Issue #3 replay helpers:'
Write-Host ("  Suite handoff:      {0}" -f $entrypoints.helper_commands.suite_router_handoff)
Write-Host ("  Replay route:       {0}" -f $entrypoints.helper_commands.replay_route)
Write-Host ("  Replay shortcuts:   {0}" -f $entrypoints.helper_commands.replay_shortcuts)
Write-Host ("  Bundle first:       {0}" -f $entrypoints.helper_commands.attached_bundle_first)
Write-Host ("  Safe route map:     {0}" -f $entrypoints.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host ("Quickstart note:      {0}" -f $entrypoints.quickstart_note_path)
Write-Host ("Suite-router bridge:  {0}" -f $entrypoints.suite_router_bridge_note_path)
Write-Host ("Validation chain:     {0}" -f $entrypoints.validation_chain_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoints.notes) {
    Write-Host ("- {0}" -f $note)
}
