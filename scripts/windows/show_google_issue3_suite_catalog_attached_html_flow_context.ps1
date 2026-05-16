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
            $value = $entry.Value
            if ($value -is [System.Array]) {
                Add-SharedPathArrayArgument -Arguments $fallbackArguments -Name $entry.Key -Values @($value)
                continue
            }

            Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $value
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
        if ($value -is [System.Array]) {
            $filteredValues = @(
                $value | Where-Object {
                    $null -ne $_ -and (-not ($_ -is [string]) -or -not [string]::IsNullOrWhiteSpace($_))
                }
            )
            if ($filteredValues.Count -eq 0) {
                continue
            }

            $escapedValues = @(
                $filteredValues | ForEach-Object {
                    "'" + (("$($_)") -replace "'", "''") + "'"
                }
            )
            $command += (" -{0} {1}" -f $entry.Key, ($escapedValues -join ' '))
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
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $InputPath

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$googleAttachedHtmlFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $googleAttachedHtmlFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $googleAttachedHtmlFlowArguments -Name InputPath -Values $InputPath

$helper = [ordered]@{
    issue = 'Google issue #3 suite catalog attached HTML flow context'
    purpose = 'Print the smallest route from the suite-catalog helper back into the broader attached-page localhost flow while preserving repo-root overrides and pinned attached-page inputs before the route narrows into the shorter issue #3 helpers again.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    note_path = 'docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_FLOW_CONTEXT.md'
    commands = [ordered]@{
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $sharedArguments
        suite_catalog_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1' -RepoRootOverride $RepoRoot
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        attached_html_change_area_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $sharedArguments
        attached_html_validation_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_validation_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments
        validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $sharedArguments
        windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $sharedArguments
        suite_catalog_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $sharedArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $sharedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Use this helper when the suite-catalog route is already open but the broader attached-page localhost flow still needs the same repo-root and pinned-input context before the route narrows again.',
        'Use suite_catalog_surface_check first after branch moves or helper renames so the compact suite-catalog path fails fast before the narrower attached-page ladder opens.',
        'Use attached_html_validation_flow when you want the broader attached-page localhost helper to stay on the same pinned saved pages instead of widening back to generic auto-discovery.',
        'Use google_attached_html_validation_flow when the current attached inputs are already Google-shaped and you want the narrower Google-focused flow beside the broader attached-page helper before narrowing again.',
        'Use attached_bundle_first once explicit input paths are already pinned to the known three-page compatibility bundle and the replay should stay locked to that set before widening back into the broader issue #3 stack.'
    )
}

$helper.recommended_next_key = if ($helper.explicit_input_path_count -gt 0) {
    'attached_html_validation_flow'
} elseif (-not [string]::IsNullOrWhiteSpace($helper.repo_root) -or -not [string]::IsNullOrWhiteSpace($helper.summary_path)) {
    'attached_html_validation_flow'
} else {
    'attached_html_change_area_quickstart'
}
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.recommended_next_key -eq 'attached_html_validation_flow') {
    'The current replay already carries pinned inputs or non-default repo context, so keep the broader attached-page flow aligned to that same state before narrowing again.'
} else {
    'No pinned inputs or saved replay context are in play yet, so reopen the shorter attached-html change-area bridge first and only widen into the broader attached-page flow if the replay still needs it.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 suite catalog attached HTML flow context'
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
Write-Host (("Recommended next helper: {0}") -f $helper.recommended_next_command)
Write-Host (("Why:                    {0}") -f $helper.recommended_next_reason)
Write-Host ''
Write-Host 'Context-preserving route:'
Write-Host (("  Suite-catalog guide:        {0}") -f $helper.commands.suite_catalog_entrypoints)
Write-Host (("  Surface check:              {0}") -f $helper.commands.suite_catalog_surface_check)
Write-Host (("  Attached HTML route:        {0}") -f $helper.commands.attached_html_change_area)
Write-Host (("  Google attached route:      {0}") -f $helper.commands.google_attached_html_change_area)
Write-Host (("  Attached bundle route:      {0}") -f $helper.commands.attached_bundle_change_area)
Write-Host (("  Attached HTML quickstart:   {0}") -f $helper.commands.attached_html_change_area_quickstart)
Write-Host (("  Attached HTML flow:         {0}") -f $helper.commands.attached_html_validation_flow)
Write-Host (("  Google attached flow:       {0}") -f $helper.commands.google_attached_html_validation_flow)
Write-Host (("  Validation-router quick:    {0}") -f $helper.commands.validation_router_attached_html_quickstart)
Write-Host (("  Windows replay quick:       {0}") -f $helper.commands.windows_replay_attached_html_quickstart)
Write-Host (("  Suite-catalog bridge:       {0}") -f $helper.commands.suite_catalog_attached_html_entrypoint)
Write-Host (("  Attached shortcut:          {0}") -f $helper.commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:           {0}") -f $helper.commands.replay_shortcuts)
Write-Host (("  Bundle-first helper:        {0}") -f $helper.commands.attached_bundle_first)
Write-Host ''
Write-Host (("Reference note: {0}") -f $helper.note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
