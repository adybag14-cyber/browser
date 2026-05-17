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

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$entrypoint = [ordered]@{
    issue = 'Google issue #3 suite-router next-steps surface-check entrypoint'
    purpose = 'Keep the suite-router next-step matrix honest by surfacing the fail-fast checker beside the matrix, its wider suite-router handoff, and its shorter shortcut-first bridge before operators trust the printed next helper set after branch moves or checkout changes.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    helper_commands = [ordered]@{
        surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_suite_router_next_steps_validation_surface.ps1' -RepoRootOverride $RepoRoot
        next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        suite_router_handoff = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleArguments
        suite_router_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $bundleArguments
        replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
    }
    note_paths = [ordered]@{
        suite_router_bridge = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
        replay_route_shortcut = 'docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md'
        windows_replay_quickstart = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    }
    notes = @(
        'Run surface_check first whenever the suite-router next-step matrix is being reused after helper churn, a branch move, or a checkout switch.',
        'If surface_check passes, reopen next_steps to pick the smallest correct follow-up helper from the same RepoRoot, SummaryPath, and InputPath context.',
        'Use suite_router_handoff when the route is still broader than the matrix and you want the higher-level suite-router bridge reprinted before narrowing again.',
        'Use suite_router_shortcut when the route is already clearly inside issue #3 and you want the shorter compact bridge before replay shortcuts or replay-route narrowing takes over.',
        'Use replay_route_shortcut when the route already widened into replay-route follow-up and you want the smaller replay-side bridge kept visible beside the matrix.',
        'Use attached_bundle_first when explicit InputPath values are already pinned and the replay should stay on the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
    )
    recommended_next_key = 'surface_check'
    recommended_next_reason = 'The checker fails fast on missing notes, helper scripts, and downstream attached-page surfaces, so it is the safest first step before trusting the suite-router next-step matrix from a resumed validation run.'
}

$entrypoint.recommended_next_command = $entrypoint.helper_commands[$entrypoint.recommended_next_key]

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 suite-router next-steps surface-check entrypoint'
Write-Host ''
if ($entrypoint.repo_root) {
    Write-Host (("Repo root:    {0}") -f $entrypoint.repo_root)
}
if ($entrypoint.summary_path) {
    Write-Host (("Summary path: {0}") -f $entrypoint.summary_path)
}
if ($entrypoint.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths:  {0}") -f $entrypoint.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $entrypoint.recommended_next_command)
Write-Host (("Why:                    {0}") -f $entrypoint.recommended_next_reason)
Write-Host ''
Write-Host 'Helper commands:'
Write-Host (("  Surface check:        {0}") -f $entrypoint.helper_commands.surface_check)
Write-Host (("  Next-step matrix:     {0}") -f $entrypoint.helper_commands.next_steps)
Write-Host (("  Suite-router handoff: {0}") -f $entrypoint.helper_commands.suite_router_handoff)
Write-Host (("  Shortcut-first bridge:{0}") -f " $($entrypoint.helper_commands.suite_router_shortcut)" )
Write-Host (("  Replay-route helper:  {0}") -f $entrypoint.helper_commands.replay_route_shortcut)
Write-Host (("  Bundle-first helper:  {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host ''
Write-Host 'Companion notes:'
Write-Host (("  Suite-router bridge:  {0}") -f $entrypoint.note_paths.suite_router_bridge)
Write-Host (("  Replay-route bridge:  {0}") -f $entrypoint.note_paths.replay_route_shortcut)
Write-Host (("  Replay quickstart:    {0}") -f $entrypoint.note_paths.windows_replay_quickstart)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}
