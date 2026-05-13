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
            Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $entry.Value
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

$bridge = [ordered]@{
    issue = 'Google issue #3 top-level router bridge'
    purpose = 'Print the exact top-level headed validation suite commands for issue #3 and the shortest current replay helpers that follow them, while preserving repo-root, saved-summary, and pinned bundle inputs when that context already exists.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    top_level_commands = [ordered]@{
        suite_name_google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        change_area_google_input = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        change_area_attached_bundle = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        google_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
    }
    note_paths = [ordered]@{
        quickstart = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
        replay_discovery = 'docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md'
        suite_router_bridge = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
        validation_chain = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    }
    notes = @(
        'Use this helper when you are re-entering issue #3 from the top-level headed validation suite and want the exact suite commands plus the shorter replay helpers on one surface.',
        'Start with suite_name_google_recommended when you want the broader issue #3 runner surfaced first, then keep change_area_google_input and google_flow nearby when the route may need to narrow into title, fixture, submit-path, live-trace, or attached-page slices.',
        'Use suite_catalog_entrypoints as the default next helper when you want the exact top-level suite commands and the current issue #3 replay helpers printed together before choosing the next-step matrix, replay route, replay shortcuts, bundle-first branch, or safe-route map.',
        'Use suite_router_next_steps when the route is already clearly issue #3 and you want the fastest compact next-step matrix after the top-level suite commands.',
        'Use replay_route when a saved summary path is already in play and you want the broader helper that preserves bundle routing and the current safe-route bridge beside the top-level suite entrypoints.',
        'Use attached_bundle_first when explicit bundle inputs are already pinned and the next replay should stay on the known three-page compatibility route before widening back into the broader Google-only helpers.',
        'Use safe_route_entrypoints only after the top-level suite router has already narrowed the replay into the wrapper-heavy issue #3 path.'
    )
}

$bridge.recommended_helper_key = if ($bridge.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($SummaryPath)) {
    'replay_route'
} else {
    'suite_catalog_entrypoints'
}

$bridge.recommended_helper_command = switch ($bridge.recommended_helper_key) {
    'attached_bundle_first' { $bridge.helper_commands.attached_bundle_first }
    'replay_route' { $bridge.helper_commands.replay_route }
    default { $bridge.helper_commands.suite_catalog_entrypoints }
}

$bridge.recommended_helper_reason = if ($bridge.recommended_helper_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so stay on the known three-page compatibility bundle route before widening back into the broader issue #3 helper chain.'
} elseif ($bridge.recommended_helper_key -eq 'replay_route') {
    'A saved summary path is already in play, so reopen the replay-route helper next to preserve that current context while keeping the top-level suite commands and safe-route bridge aligned.'
} else {
    'No pinned bundle inputs or saved summary are in play yet, so start with the suite-catalog entrypoints helper to keep the top-level headed validation commands and the current issue #3 replay helpers together before choosing the next narrower branch.'
}

if ($Json) {
    $bridge | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 top-level router bridge'
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
Write-Host (("Recommended next helper: {0}") -f $bridge.recommended_helper_command)
Write-Host (("Why:                    {0}") -f $bridge.recommended_helper_reason)
Write-Host ''
Write-Host 'Top-level suite commands:'
Write-Host (("  Google recommended: {0}") -f $bridge.top_level_commands.suite_name_google_recommended)
Write-Host (("  Google input:       {0}") -f $bridge.top_level_commands.change_area_google_input)
Write-Host (("  Attached bundle:    {0}") -f $bridge.top_level_commands.change_area_attached_bundle)
Write-Host (("  Google flow:        {0}") -f $bridge.top_level_commands.google_flow)
Write-Host ''
Write-Host 'Current issue #3 helpers:'
Write-Host (("  Suite catalog:      {0}") -f $bridge.helper_commands.suite_catalog_entrypoints)
Write-Host (("  Next-step matrix:   {0}") -f $bridge.helper_commands.suite_router_next_steps)
Write-Host (("  Replay route:       {0}") -f $bridge.helper_commands.replay_route)
Write-Host (("  Replay shortcuts:   {0}") -f $bridge.helper_commands.replay_shortcuts)
Write-Host (("  Bundle first:       {0}") -f $bridge.helper_commands.attached_bundle_first)
Write-Host (("  Safe-route map:     {0}") -f $bridge.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Quickstart note:      {0}") -f $bridge.note_paths.quickstart)
Write-Host (("Replay discovery:     {0}") -f $bridge.note_paths.replay_discovery)
Write-Host (("Suite-router bridge:  {0}") -f $bridge.note_paths.suite_router_bridge)
Write-Host (("Validation chain:     {0}") -f $bridge.note_paths.validation_chain)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $bridge.notes) {
    Write-Host (("- {0}") -f $note)
}
