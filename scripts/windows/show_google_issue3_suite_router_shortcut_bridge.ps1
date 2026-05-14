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

$bridgeArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bridgeArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bridgeArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bridgeArguments -Name InputPath -Values $InputPath

$bridge = [ordered]@{
    issue = 'Google issue #3 suite-router shortcut bridge'
    purpose = 'Keep the top-level headed validation suite-router entrypoints, the direct replay-shortcuts helper, the current safe-route entrypoints map, and the pinned bundle-first branch on one compact helper before the replay widens back into the broader issue #3 chain.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    shortcut_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    suite_router_commands = [ordered]@{
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
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bridgeArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bridgeArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bridgeArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bridgeArguments
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $bridgeArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bridgeArguments
    }
    read_first_bridge = [ordered]@{
        google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        google_input_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bridgeArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bridgeArguments
    }
    notes = @(
        'Start with google_recommended when you want the broader localhost-first issue #3 runner surfaced from the top-level suite router before narrowing to the shortcut map.',
        'Use google_input_change_area when the current replay still might need the broader issue #3 suite chooser, but the next helper should still default to replay_shortcuts instead of reopening the longer validation-chain notes first.',
        'Use replay_shortcuts as the default next helper after the top-level suite router when the route is already clearly inside issue #3 and you want the narrowest current command surface before deciding whether to stay on the bundle-first branch or drop into the wrapper-heavy safe-route map.',
        'Use safe_route_entrypoints immediately after replay_shortcuts when the current route is ready to move from the compact helper surface into the wrapper-heavy issue #3 commands, notes, and runner-state follow-ups.',
        'Use attached_bundle_change_area and attached_bundle_first when explicit InputPath values are already pinned to the current three-page compatibility bundle and the replay should stay on that locked branch before widening back into the broader Google-only path.',
        'Use suite_router_next_steps when you want the wider matrix reprinted again before choosing between replay_shortcuts, replay_route, the pinned bundle-first helper, or the context-preserving branches.',
        'Use suite_catalog_entrypoints when you want the exact top-level router entrypoints, the Google flow, the wider helper order, and the recommended next command all reprinted together before narrowing again.',
        'Use replay_route after replay_shortcuts or safe_route_entrypoints when you want the slightly broader bridge that keeps the attached-bundle branch and the runner-state choices visible beside the narrower shortcut map.',
        'Keep the quickstart, shortcut-bridge, suite-entrypoint, and validation-chain notes nearby when you want the written route beside these commands without reopening the broader Windows runbook first.'
    )
}

$bridge.recommended_next_key = if ($bridge.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} else {
    'replay_shortcuts'
}
$bridge.recommended_next_command = $bridge.helper_commands[$bridge.recommended_next_key]
$bridge.recommended_next_reason = if ($bridge.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so stay on the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} else {
    'The top-level suite router has already narrowed the route to issue #3, so jump straight to the compact replay-shortcuts surface before deciding whether to widen back into the matrix or the wrapper-heavy safe-route helpers.'
}
$bridge.recommended_follow_up_command = if ($bridge.recommended_next_key -eq 'attached_bundle_first') {
    $bridge.helper_commands.safe_route_entrypoints
} else {
    $bridge.helper_commands.safe_route_entrypoints
}
$bridge.recommended_follow_up_reason = 'After the compact shortcut surface or pinned bundle-first branch has confirmed the current path, reopen the safe-route entrypoints map to move into the wrapper-heavy runner flow without losing repo-root, summary, or explicit input context.'

if ($Json) {
    $bridge | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 suite-router shortcut bridge'
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
Write-Host (("Follow-up helper:       {0}") -f $bridge.recommended_follow_up_command)
Write-Host (("Why:                    {0}") -f $bridge.recommended_follow_up_reason)
Write-Host ''
Write-Host 'Shortcut-first bridge:'
Write-Host (("  1. Google recommended: {0}") -f $bridge.read_first_bridge.google_recommended)
Write-Host (("  2. Google input:       {0}") -f $bridge.read_first_bridge.google_input_change_area)
Write-Host (("  3. Replay shortcuts:   {0}") -f $bridge.read_first_bridge.replay_shortcuts)
Write-Host (("  4. Safe-route map:     {0}") -f $bridge.read_first_bridge.safe_route_entrypoints)
if ($bridge.explicit_input_path_count -gt 0) {
    Write-Host (("  Bundle-first branch:   {0}") -f $bridge.helper_commands.attached_bundle_first)
}
Write-Host ''
Write-Host 'Top-level suite-router entrypoints:'
Write-Host (("  Google recommended: {0}") -f $bridge.suite_router_commands.google_recommended)
Write-Host (("  Google input:       {0}") -f $bridge.suite_router_commands.google_input_change_area)
Write-Host (("  Attached bundle:    {0}") -f $bridge.suite_router_commands.attached_bundle_change_area)
Write-Host ''
Write-Host 'Companion helpers:'
Write-Host (("  Replay shortcuts:     {0}") -f $bridge.helper_commands.replay_shortcuts)
Write-Host (("  Safe-route map:       {0}") -f $bridge.helper_commands.safe_route_entrypoints)
Write-Host (("  Bundle-first helper:  {0}") -f $bridge.helper_commands.attached_bundle_first)
Write-Host (("  Next-step matrix:     {0}") -f $bridge.helper_commands.suite_router_next_steps)
Write-Host (("  Suite-catalog bridge: {0}") -f $bridge.helper_commands.suite_catalog_entrypoints)
Write-Host (("  Replay route:         {0}") -f $bridge.helper_commands.replay_route)
Write-Host ''
Write-Host 'Notes:'
Write-Host (("  Shortcut bridge note: {0}") -f $bridge.shortcut_bridge_note_path)
Write-Host (("  Suite entrypoints:    {0}") -f $bridge.suite_catalog_entrypoint_note_path)
Write-Host (("  Quickstart:           {0}") -f $bridge.quickstart_note_path)
Write-Host (("  Validation chain:     {0}") -f $bridge.validation_chain_note_path)
Write-Host ''
foreach ($note in $bridge.notes) {
    Write-Host (("- {0}") -f $note)
}
