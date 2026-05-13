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
        [string]$RepoRootOverride
    )

    if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        $fallbackArguments = [System.Collections.Generic.List[string]]::new()
        foreach ($entry in $Arguments.GetEnumerator()) {
            Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $entry.Value
        }
        return Format-HelperCommand -ScriptName $ScriptName -Arguments $fallbackArguments
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

    $escapedRepoRoot = ("$RepoRootOverride") -replace "'", "''"
    return "powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$env:LIGHTPANDA_REPO_ROOT = '$escapedRepoRoot'; $command`""
}

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath

$contextArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $contextArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $contextArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $contextArguments -Name InputPath -Values $InputPath

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$returnRoute = [ordered]@{
    issue = 'Google issue #3 attached bundle return route'
    purpose = 'Keep the pinned three-page compatibility bundle replay, the broader issue #3 replay-route bridge, and the narrower safe-route entrypoints on one context-preserving command surface after the bundle pass finishes.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    bundle_suite_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
        ChangeArea = 'attached-html-target-bundle'
    }) -RepoRootOverride $RepoRoot
    bundle_flow_command = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleArguments
    bundle_runner_command = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleArguments -Switches @('Wait')
    replay_shortcuts_command = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $contextArguments
    replay_route_command = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $contextArguments
    suite_router_handoff_command = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $contextArguments
    safe_route_entrypoints_command = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    notes = @(
        'Use this helper after the attached bundle replay when you want to keep the same RepoRoot, SummaryPath, and pinned InputPath values attached to the next issue #3 commands instead of retyping them by hand.',
        'Use replay_shortcuts_command when you want the smallest compact map back into the broader issue #3 helpers after the bundle pass.',
        'Use replay_route_command when you want the same bundle context preserved while reopening the broader read-first bridge, bundle branch, and runner-next-step helper in one place.',
        'Use suite_router_handoff_command when you want to reopen the higher-level suite-router discovery surface before choosing whether to stay pinned to the bundle branch or widen into the broader safe route.',
        'Use safe_route_entrypoints_command only after the bundle replay makes the next Google-style input or submit failure state clear enough to narrow into the wrapper-driven recovery path.'
    )
}

if ($returnRoute.explicit_input_path_count -gt 0 -or -not [string]::IsNullOrWhiteSpace($returnRoute.summary_path)) {
    $returnRoute.recommended_next_command = $returnRoute.replay_route_command
    $returnRoute.recommended_next_reason = 'Pinned bundle inputs or a saved summary are already in play, so keep that context attached while reopening the broader replay route.'
} else {
    $returnRoute.recommended_next_command = $returnRoute.replay_shortcuts_command
    $returnRoute.recommended_next_reason = 'No pinned bundle inputs or saved summary are in play, so reopen the compact replay-shortcuts helper first.'
}

if ($Json) {
    $returnRoute | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 attached bundle return route'
Write-Host ''
if ($returnRoute.repo_root) {
    Write-Host ("Repo root:   {0}" -f $returnRoute.repo_root)
}
if ($returnRoute.summary_path) {
    Write-Host ("Summary path:{0}" -f (" $($returnRoute.summary_path)"))
}
if ($returnRoute.explicit_input_path_count -gt 0) {
    Write-Host ("Input paths: {0}" -f $returnRoute.explicit_input_path_count)
}
Write-Host ''
Write-Host ("Recommended next: {0}" -f $returnRoute.recommended_next_command)
Write-Host ("Why:             {0}" -f $returnRoute.recommended_next_reason)
Write-Host ''
Write-Host 'Bundle replay:'
Write-Host ("  Suite route:     {0}" -f $returnRoute.bundle_suite_command)
Write-Host ("  Flow helper:     {0}" -f $returnRoute.bundle_flow_command)
Write-Host ("  Runner:          {0}" -f $returnRoute.bundle_runner_command)
Write-Host ''
Write-Host 'Return after bundle replay:'
Write-Host ("  Replay shortcuts:   {0}" -f $returnRoute.replay_shortcuts_command)
Write-Host ("  Replay route:       {0}" -f $returnRoute.replay_route_command)
Write-Host ("  Suite handoff:      {0}" -f $returnRoute.suite_router_handoff_command)
Write-Host ("  Safe route:         {0}" -f $returnRoute.safe_route_entrypoints_command)
Write-Host ''
Write-Host ("Quickstart note:       {0}" -f $returnRoute.quickstart_note_path)
Write-Host ("Validation chain note: {0}" -f $returnRoute.validation_chain_note_path)
Write-Host ("Suite-router bridge:   {0}" -f $returnRoute.suite_router_bridge_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $returnRoute.notes) {
    Write-Host ("- {0}" -f $note)
}
