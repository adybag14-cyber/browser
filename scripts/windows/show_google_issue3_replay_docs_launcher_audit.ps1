[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json,
    [switch]$AllowRawLauncher
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

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot

$checkerSwitches = [System.Collections.Generic.List[string]]::new()
if ($AllowRawLauncher) {
    $checkerSwitches.Add('AllowRawLauncher')
}

$helper = [ordered]@{
    issue = 'Google issue #3 replay docs launcher audit'
    purpose = 'Surface the replay-docs launcher audit so issue #3 follow-up can fail fast on stale raw-Python attached-pages launcher guidance and confirm the wrapper-backed sidecar route still stays visible in the key replay notes.'
    repo_root = $RepoRoot
    allow_raw_launcher = [bool]$AllowRawLauncher
    helper_path = 'scripts/windows/show_google_issue3_replay_docs_launcher_audit.ps1'
    checker_path = 'scripts/windows/check_google_issue3_replay_docs_launcher_audit.ps1'
    audit_script_path = 'tmp-browser-smoke/attached-pages/issue3_replay_docs_launcher_audit.py'
    target_notes = @(
        'docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md',
        'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md',
        'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md',
        'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    )
    commands = [ordered]@{
        replay_docs_launcher_audit_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_replay_docs_launcher_audit.ps1' -Arguments $sharedArguments -Switches $checkerSwitches
        replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $sharedArguments
        launcher_companion_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $sharedArguments
        launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments
    }
    recommended_next_key = 'replay_docs_launcher_audit_surface_check'
    recommended_next_reason = 'Start with the replay-docs launcher audit so stale raw-Python launcher references or missing wrapper-backed sidecar surfacing fail fast before you trust the narrower replay helpers again.'
    notes = @(
        'Use replay_docs_launcher_audit_surface_check first when the replay notes may have drifted away from the wrapper-backed attached-pages launcher route and you want a fast guard before reopening the narrower issue #3 helper chain.',
        'Use launcher_companion_surface_check and launcher_companion after the replay-docs audit when the branch still needs the attached-pages launcher companion route itself reprinted beside the replay ladder.',
        'Keep ISSUE3_REPLAY_DISCOVERY_HANDOFF.md, ISSUE3_WINDOWS_REPLAY_QUICKSTART.md, ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md, and ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md nearby when reviewing audit failures so the stale launcher guidance can be repaired at the right level of the replay route.',
        'Pass -AllowRawLauncher only when you want the helper to report current wrapper-backed sidecar coverage without failing the run on known raw-Python references.'
    )
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 replay docs launcher audit'
Write-Host ''
if ($helper.repo_root) {
    Write-Host (("Repo root: {0}") -f $helper.repo_root)
}
Write-Host (("Recommended next helper: {0}") -f $helper.commands[$helper.recommended_next_key]))
Write-Host (("Why:                    {0}") -f $helper.recommended_next_reason))
Write-Host ''
Write-Host 'Commands:'
Write-Host (("  Replay-docs audit:        {0}") -f $helper.commands.replay_docs_launcher_audit_surface_check))
Write-Host (("  Replay attached ladder:   {0}") -f $helper.commands.replay_attached_html_quickstart))
Write-Host (("  Launcher surface check:   {0}") -f $helper.commands.launcher_companion_surface_check))
Write-Host (("  Launcher companion:       {0}") -f $helper.commands.launcher_companion))
Write-Host ''
Write-Host 'Replay notes covered:'
foreach ($path in $helper.target_notes) {
    Write-Host (("- {0}") -f $path))
}
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note))
}
