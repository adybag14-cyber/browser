[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string]$BrowserExe,
    [string]$PreferredInitialPage,
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

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $sharedArguments -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $sharedArguments -Name PreferredInitialPage -Value $PreferredInitialPage

$googleInputArguments = [ordered]@{}
if ($BrowserExe) {
    $googleInputArguments['BrowserExe'] = $BrowserExe
}

$googleAttachedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $googleAttachedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $googleAttachedArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $googleAttachedArguments -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $googleAttachedArguments -Name PreferredInitialPage -Value $PreferredInitialPage

$replayShortcutArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $replayShortcutArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $replayShortcutArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $replayShortcutArguments -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $replayShortcutArguments -Name PreferredInitialPage -Value $PreferredInitialPage

$browserCommand = if ([string]::IsNullOrWhiteSpace($BrowserExe)) {
    '.\\zig-out\\bin\\lightpanda.exe'
} else {
    ConvertTo-PowerShellSingleQuotedLiteral -Value $BrowserExe
}
$realGoogleLaunch = "$browserCommand browse --browser_mode headed https://www.google.com/"

$entrypoint = [ordered]@{
    issue = 'Google issue #3 real Google search entrypoint'
    purpose = 'Print the shortest manual headed repro for the live Google homepage bug, then keep the local Google-input and attached-page comparison helpers beside it so issue #3 can move between the real site and the saved localhost routes without reopening the broader Windows notes first.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    browser_exe = $BrowserExe
    preferred_initial_page = $PreferredInitialPage
    build_command = 'zig build -Dtarget=x86_64-windows-msvc --summary all'
    launch_command = $realGoogleLaunch
    manual_repro = @(
        'Launch the headed browser on https://www.google.com/.',
        'Click the Google search box once the page is interactive.',
        'Type a short query such as headed mode test.',
        'Press Enter and watch whether the query value commits and navigation starts.'
    )
    helper_commands = [ordered]@{
        google_input_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -Arguments $googleInputArguments -RepoRootOverride $RepoRoot
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $googleAttachedArguments
        replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $replayShortcutArguments
    }
    note_paths = [ordered]@{
        windows_runbook = 'docs/WINDOWS_FULL_USE.md'
        replay_shortcut_bridge = 'docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md'
        google_attached_html_entrypoint = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'
        google_attached_html_flow = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    }
    notes = @(
        'Use this helper when the real Google homepage is still the current truth source and you want a compact manual repro before falling back to the saved localhost comparison routes.',
        'Run google_input_flow first when the live Google bug needs to be compared against the smaller local Google-style inputs that already accept typing more reliably.',
        'Run google_attached_html_entrypoint when the next check should stay pinned to the saved attached-page bundle instead of the live site.',
        'Run replay_route_shortcut when the current failure already points back into the narrower issue #3 replay chain and you want the compact attached-page and replay follow-up map again.',
        'Keep the Windows runbook and issue #3 notes nearby when the next step needs the broader Windows headed context or the longer attached-page route.'
    )
}

$entrypoint.recommended_next_key = if (-not [string]::IsNullOrWhiteSpace($SummaryPath) -or -not [string]::IsNullOrWhiteSpace($PreferredInitialPage)) {
    'google_attached_html_entrypoint'
} else {
    'google_input_flow'
}
$entrypoint.recommended_next_command = $entrypoint.helper_commands[$entrypoint.recommended_next_key]
$entrypoint.recommended_next_reason = if ($entrypoint.recommended_next_key -eq 'google_attached_html_entrypoint') {
    'A saved summary or preferred attached page is already in play, so compare the live Google failure against the narrower attached-page route next.'
} else {
    'No pinned attached-page context is in play yet, so compare the live Google failure against the smaller local Google-input route first.'
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 real Google search entrypoint'
Write-Host ''
if ($entrypoint.repo_root) {
    Write-Host (("Repo root:   {0}") -f $entrypoint.repo_root)
}
if ($entrypoint.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($entrypoint.summary_path)"))
}
if ($entrypoint.browser_exe) {
    Write-Host (("Browser exe: {0}") -f $entrypoint.browser_exe)
}
if ($entrypoint.preferred_initial_page) {
    Write-Host (("Preferred page: {0}") -f $entrypoint.preferred_initial_page)
}
Write-Host ''
Write-Host (("Build:  {0}") -f $entrypoint.build_command)
Write-Host (("Launch: {0}") -f $entrypoint.launch_command)
Write-Host ''
Write-Host 'Manual repro:'
for ($i = 0; $i -lt $entrypoint.manual_repro.Count; $i++) {
    Write-Host (("  {0}. {1}") -f ($i + 1), $entrypoint.manual_repro[$i])
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $entrypoint.recommended_next_command)
Write-Host (("Why:                    {0}") -f $entrypoint.recommended_next_reason)
Write-Host ''
Write-Host 'Comparison helpers:'
Write-Host (("  Local Google input:   {0}") -f $entrypoint.helper_commands.google_input_flow)
Write-Host (("  Attached-page route:  {0}") -f $entrypoint.helper_commands.google_attached_html_entrypoint)
Write-Host (("  Replay shortcut map:  {0}") -f $entrypoint.helper_commands.replay_route_shortcut)
Write-Host ''
Write-Host (("Windows runbook:        {0}") -f $entrypoint.note_paths.windows_runbook)
Write-Host (("Replay shortcut note:   {0}") -f $entrypoint.note_paths.replay_shortcut_bridge)
Write-Host (("Attached-page note:     {0}") -f $entrypoint.note_paths.google_attached_html_entrypoint)
Write-Host (("Attached-page flow:     {0}") -f $entrypoint.note_paths.google_attached_html_flow)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}
