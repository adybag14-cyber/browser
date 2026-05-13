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

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$recommendedReentryKey = 'refresh_status_safe_path_route'
$recommendedReentryReason = 'After the safe wiring audit is green, stay on the narrower refresh-status safe path route so the saved summary, refresh status, and handoff chain remain aligned.'
if ($InputPath -and @($InputPath).Count -gt 0) {
    $recommendedReentryKey = 'attached_bundle_first'
    $recommendedReentryReason = 'Explicit input paths are already pinned, so reopen the bundle-first compatibility route after the safe wiring audit instead of widening back into the broader Google-only helper chain first.'
}

$route = [ordered]@{
    issue = 'Google issue #3 post runner patch route'
    purpose = 'Keep the immediate safe wiring audit, the narrowed refresh-status safe route, and the pinned attached-bundle return commands on one command surface after the runner patch loop stops being the next question.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    runner_patch_decision_table_path = 'docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    windows_full_use_note_path = 'docs/WINDOWS_FULL_USE.md'
    commands = [ordered]@{
        safe_wiring_audit = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_output_wiring_status_safe.ps1' -Arguments ([ordered]@{
            SummaryPath = $SummaryPath
        }) -RepoRootOverride $RepoRoot
        raw_wiring_audit = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_runner_output_wiring_status.ps1' -Arguments ([ordered]@{
            SummaryPath = $SummaryPath
        }) -RepoRootOverride $RepoRoot
        refresh_status_safe_path_route = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_refresh_status_safe_path_route.ps1' -Arguments ([ordered]@{
            SummaryPath = $SummaryPath
        }) -RepoRootOverride $RepoRoot
        handoff_safe_refresh_route = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_validation_handoff_safe_refresh_route.ps1' -Arguments ([ordered]@{
            SummaryPath = $SummaryPath
        }) -RepoRootOverride $RepoRoot
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
    }
    recommended_first_command = $null
    recommended_first_reason = 'After the runner patch loop, confirm the saved outputs are wired before widening into refresh-status, handoff, or attached-bundle follow-up.'
    recommended_reentry_command = $null
    recommended_reentry_reason = $recommendedReentryReason
    notes = @(
        'Use this helper after the runner patch decision-table loop reaches ready-for-runner-patch, already-direct, or runner-already-wired-regenerate-outputs and the next question is where to resume once the patch loop has finished.',
        'Run the safe wiring audit first after rerunning scripts/windows/run_google_issue3_recommended_validation.ps1 or after the wrapper reports already-direct.',
        'If the safe wiring audit is green, prefer refresh_status_safe_path_route so the saved summary, refresh-status, and handoff chain stay on the bounded safe route.',
        'When the current saved or attached pages are the known three-page compatibility bundle, use attached_bundle_first before reopening the broader Google-only helper chain.',
        'Use handoff_safe_refresh_route when refresh-status has already narrowed cleanly and the next replay should reopen the handoff-safe follow-up without reconstructing the refresh branch by hand.',
        'Use replay_shortcuts when you need the broader issue #3 discovery bridge again before choosing between the safe-route and attached-bundle branches.'
    )
}

$route.recommended_first_command = $route.commands.safe_wiring_audit
$route.recommended_reentry_command = $route.commands[$recommendedReentryKey]

if ($Json) {
    $route | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 post runner patch route'
Write-Host ''
if ($route.repo_root) {
    Write-Host ("Repo root:   {0}" -f $route.repo_root)
}
if ($route.summary_path) {
    Write-Host ("Summary path:{0}" -f (" " + $route.summary_path))
}
if ($route.explicit_input_path_count -gt 0) {
    Write-Host ("Input paths: {0}" -f $route.explicit_input_path_count)
}
Write-Host ''
Write-Host ("Recommended first command:  {0}" -f $route.recommended_first_command)
Write-Host ("Why:                        {0}" -f $route.recommended_first_reason)
Write-Host ("Recommended re-entry path:  {0}" -f $route.recommended_reentry_command)
Write-Host ("Why:                        {0}" -f $route.recommended_reentry_reason)
Write-Host ''
Write-Host 'Commands:'
Write-Host ("  Safe wiring audit:        {0}" -f $route.commands.safe_wiring_audit)
Write-Host ("  Raw wiring audit:         {0}" -f $route.commands.raw_wiring_audit)
Write-Host ("  Refresh safe route:       {0}" -f $route.commands.refresh_status_safe_path_route)
Write-Host ("  Handoff safe route:       {0}" -f $route.commands.handoff_safe_refresh_route)
Write-Host ("  Bundle-first helper:      {0}" -f $route.commands.attached_bundle_first)
Write-Host ("  Replay shortcuts:         {0}" -f $route.commands.replay_shortcuts)
Write-Host ''
Write-Host ("Decision table:             {0}" -f $route.runner_patch_decision_table_path)
Write-Host ("Validation chain note:      {0}" -f $route.validation_chain_note_path)
Write-Host ("Windows full-use note:      {0}" -f $route.windows_full_use_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $route.notes) {
    Write-Host ("- {0}" -f $note)
}
