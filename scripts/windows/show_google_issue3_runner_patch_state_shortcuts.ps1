[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
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

function Format-StateCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$State,
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$SharedArguments
    )

    $arguments = [System.Collections.Generic.List[string]]::new()
    foreach ($argument in $SharedArguments) {
        $arguments.Add($argument)
    }
    Add-SharedArgument -Arguments $arguments -Name State -Value $State
    return Format-HelperCommand -ScriptName 'show_google_issue3_runner_patch_next_step.ps1' -Arguments $arguments
}

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath

$stateCommands = [ordered]@{
    'ready-for-runner-patch' = Format-StateCommand -State 'ready-for-runner-patch' -SharedArguments $sharedArguments
    'already-direct' = Format-StateCommand -State 'already-direct' -SharedArguments $sharedArguments
    'runner-already-wired-regenerate-outputs' = Format-StateCommand -State 'runner-already-wired-regenerate-outputs' -SharedArguments $sharedArguments
}

$report = [ordered]@{
    issue = 'Google issue #3 runner patch state shortcuts'
    purpose = 'Print the three runner-patch next-step state commands with the current repo-root and saved-summary context preserved, so alternate-checkout replays can jump straight from the safe-route wrapper artifact into the exact next helper.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    decision_table_note_path = 'docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md'
    replay_shortcuts_command = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $sharedArguments
    safe_route_entrypoints_command = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
    state_commands = $stateCommands
    notes = @(
        'Use this helper when a safe-route wrapper or handoff artifact already named one of the three runner patch states and you want the exact state helper command with the same repo-root and summary-path context preserved.',
        'Use replay_shortcuts_command or safe_route_entrypoints_command first when the replay context is stale or when you need to reopen the broader issue #3 bundle versus safe-route decision before acting on a specific state.',
        'Keep decision_table_note_path nearby when the state helper confirms ready-for-runner-patch and you need the longer direct-runner field checklist.'
    )
}

if ($Json) {
    $report | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 runner patch state shortcuts'
Write-Host ''
if ($report.repo_root) {
    Write-Host ("Repo root:   {0}" -f $report.repo_root)
}
if ($report.summary_path) {
    Write-Host ("Summary path:{0}" -f " $($report.summary_path)")
}
if ($report.repo_root -or $report.summary_path) {
    Write-Host ''
}
Write-Host ("Purpose: {0}" -f $report.purpose)
Write-Host ("Quickstart note:       {0}" -f $report.quickstart_note_path)
Write-Host ("Validation chain note: {0}" -f $report.validation_chain_note_path)
Write-Host ("Decision table:        {0}" -f $report.decision_table_note_path)
Write-Host ''
Write-Host ("Replay shortcuts:      {0}" -f $report.replay_shortcuts_command)
Write-Host ("Safe-route entrypoints:{0}" -f (' ' + $report.safe_route_entrypoints_command))
Write-Host ''
Write-Host 'Runner patch states:'
foreach ($entry in $report.state_commands.GetEnumerator()) {
    Write-Host ("- {0}: {1}" -f $entry.Key, $entry.Value)
}
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $report.notes) {
    Write-Host ("- {0}" -f $note)
}
