[CmdletBinding()]
param(
    [string]$RepoRoot,
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
        if ([string]::IsNullOrWhiteSpace($value)) {
            continue
        }
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

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $InputPath

$surfaceCheckArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $surfaceCheckArguments -Name RepoRoot -Value $RepoRoot

$helper = [ordered]@{
    issue = 'Google issue #3 top-level replay-doc launcher audit'
    purpose = 'Print the shortest checker-first route for replay-doc launcher drift before a future run widens back into the broader top-level attached-page quickstart notes.'
    repo_root = $RepoRoot
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    note_path = 'docs/ISSUE3_TOP_LEVEL_REPLAY_DOCS_LAUNCHER_AUDIT.md'
    top_level_attached_html_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    commands = [ordered]@{
        replay_docs_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_replay_docs_launcher_validation_surface.ps1' -Arguments $surfaceCheckArguments
        launcher_companion_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $surfaceCheckArguments
        launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments
        top_level_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $sharedArguments
    }
    recommended_next_key = 'replay_docs_surface_check'
    recommended_next_reason = 'Run the replay-doc launcher audit first so stale raw Python note paths, missing wrapper-sidecar coverage, or missing launcher-companion surfaces fail fast before the broader top-level attached-page route is trusted again.'
    notes = @(
        'Use replay_docs_surface_check first when the top-level attached-page notes may still be carrying older raw Python launcher commands.',
        'Use launcher_companion_surface_check next when the compact launcher ladder itself may have drifted from the wrapper-backed sidecar route.',
        'Use launcher_companion to reopen the wrapper-backed sidecar audit, asset audit, manifest, strict launch, and Python fallback in one compact helper surface.',
        'Return to top_level_quickstart only after the replay-doc audit and launcher companion both agree on the same guarded launcher route.'
    )
}

$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 top-level replay-doc launcher audit'
Write-Host ''
if ($helper.repo_root) {
    Write-Host (("Repo root:   {0}") -f $helper.repo_root)
}
if ($helper.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $helper.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $helper.recommended_next_command)
Write-Host (("Why:                    {0}") -f $helper.recommended_next_reason)
Write-Host ''
Write-Host 'Checker-first route:'
Write-Host (("  Replay-doc surface check:    {0}") -f $helper.commands.replay_docs_surface_check)
Write-Host (("  Launcher companion check:    {0}") -f $helper.commands.launcher_companion_surface_check)
Write-Host (("  Launcher companion helper:   {0}") -f $helper.commands.launcher_companion)
Write-Host (("  Top-level quickstart helper: {0}") -f $helper.commands.top_level_quickstart)
Write-Host ''
Write-Host (("Launcher audit note:     {0}") -f (' ' + $helper.note_path))
Write-Host (("Top-level quickstart:    {0}") -f (' ' + $helper.top_level_attached_html_note_path))
Write-Host (("Replay quickstart note:  {0}") -f (' ' + $helper.replay_quickstart_note_path))
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
