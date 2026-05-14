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
        $command += ((" -{0} '{1}'" -f $entry.Key, $escapedValue))
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

$checkerArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $checkerArguments -Name RepoRoot -Value $RepoRoot

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $InputPath

$helper = [ordered]@{
    issue = 'Google issue #3 Windows full-use attached HTML route surface check'
    purpose = 'Print the fail-fast validation-surface checker and the immediate attached-localhost route helpers for the issue #3 Windows full-use replay path.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    validation_surface_script_path = 'scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1'
    route_helper_script_path = 'scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1'
    commands = [ordered]@{
        validation_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -Arguments $checkerArguments
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $sharedArguments
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $sharedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Run validation_surface_check first when you are reopening the issue #3 attached-localhost branch from the broader Windows headed runbook and want missing route notes or helper scripts to fail fast before you spend time on replay setup.',
        'After the checker passes, reopen windows_full_use_attached_html_route to print the broader attached-page route map, the nearby route notes, and the recommended next helper before the route narrows again.',
        'Use attached_html_change_area when the next replay should stay on the generic attached localhost branch from the broader validation router before the issue-specific helper chain narrows further.',
        'Use top_level_attached_html_quickstart when the route has already narrowed to attached localhost follow-up and you want the shortest top-level attached-page bridge printed immediately after the checker and route helper.',
        'Use attached_bundle_first when explicit InputPath values are already pinned to the known three-page compatibility bundle and the route should stay on that locked branch first.',
        'Use safe_route_entrypoints only after the attached-page route has already narrowed enough that the wrapper-heavy issue #3 command surface is the next useful layer.',
        'Keep docs/WINDOWS_FULL_USE.md and docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md nearby when you want the written route beside this checker-first helper surface.'
    )
}

$helper.recommended_after_check_key = if ($helper.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} else {
    'windows_full_use_attached_html_route'
}
$helper.recommended_after_check_command = $helper.commands[$helper.recommended_after_check_key]
$helper.recommended_after_check_reason = if ($helper.recommended_after_check_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so stay on the known three-page compatibility bundle immediately after the route checker passes.'
} else {
    'No pinned bundle inputs are in play yet, so reopen the broader Windows full-use attached-html route helper immediately after the checker passes.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 Windows full-use attached HTML route surface check'
Write-Host ''
if ($helper.repo_root) {
    Write-Host (("Repo root:   {0}") -f $helper.repo_root)
}
if ($helper.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($helper.summary_path)"))
}
if ($helper.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $helper.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Run this checker first:     {0}") -f $helper.commands.validation_surface_check)
Write-Host (("After it passes, use:       {0}") -f $helper.recommended_after_check_command)
Write-Host (("Why:                       {0}") -f $helper.recommended_after_check_reason)
Write-Host ''
Write-Host 'Broader attached-page route:'
Write-Host (("  Attached HTML change area: {0}") -f $helper.commands.attached_html_change_area)
Write-Host (("  Windows route helper:      {0}") -f $helper.commands.windows_full_use_attached_html_route)
Write-Host (("  Top-level quickstart:      {0}") -f $helper.commands.top_level_attached_html_quickstart)
Write-Host (("  Bundle-first helper:       {0}") -f $helper.commands.attached_bundle_first)
Write-Host (("  Safe-route map:            {0}") -f $helper.commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Windows runbook:             {0}") -f $helper.windows_runbook_note_path)
Write-Host (("Attached route note:         {0}") -f $helper.windows_full_use_attached_html_route_note_path)
Write-Host (("Surface checker script:      {0}") -f $helper.validation_surface_script_path)
Write-Host (("Route helper script:         {0}") -f $helper.route_helper_script_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
