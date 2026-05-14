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

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$helper = [ordered]@{
    issue = 'Google issue #3 Windows full-use validation-router attached HTML quickstart'
    purpose = 'Print the shortest bridge from the broader Windows runbook into the validation-router attached HTML quickstart, then into the compact top-level attached-page helpers for issue #3 while preserving repo-root, saved-summary, and pinned bundle context when it already exists.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    validation_router_attached_html_quickstart_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    top_level_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    suite_router_attached_html_quickstart_note_path = 'docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md'
    commands = [ordered]@{
        windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $bundleArguments
        validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_html_target_bundle = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
    }
    notes = @(
        'Use this helper when you are starting from docs/WINDOWS_FULL_USE.md or the broader Windows runbook and the next replay is already trending toward the attached localhost compatibility pages for issue #3.',
        'Use windows_full_use_attached_html_route when you still want the broader Windows-facing attached-page bridge visible before the route drops into the shorter validation-router helper.',
        'Use validation_router_attached_html_quickstart as the default next helper when no pinned bundle inputs, non-default repo root, or saved summary need to take precedence first.',
        'Use attached_html when the replay is already centered on the broader attached localhost compatibility pages and you still want the shared validation catalog branch reprinted before narrowing into the issue-specific helper chain.',
        'Use google_attached_html when the replay should still keep the Google-shaped attached-page route visible before the compact top-level attached-page quickstarts take over.',
        'Use top_level_attached_html_quickstart when you want the shortest top-level attached-page bridge immediately after the validation-router helper.',
        'Use top_level_attached_html_catalog_quickstart when you want the compact top-level attached-page quickstart and the suite-catalog-side attached-page bridge kept visible together before narrowing again.',
        'Use top_level_attached_html_entrypoint when the broader top-level attached-page bridge should stay visible beside the compact quickstarts before widening back into replay shortcuts or the next-step matrix.',
        'Use suite_router_attached_html_quickstart when the route has already dropped back to the suite-router side and you want the shorter attached-page bridge preserved there.',
        'Use replay_shortcuts or suite_router_next_steps only after the validation-router helper and the compact top-level attached-page quickstarts are already in view.',
        'Use attached_html_target_bundle and attached_bundle_first when explicit InputPath values are already pinned to the known three-page compatibility bundle and that branch should stay visible first.',
        'Keep the Windows runbook, the Windows full-use attached-page route note, the validation-router attached-page quickstart note, the top-level attached-page quickstart note, the top-level attached-page catalog quickstart note, and the suite-router attached-page quickstart note nearby when you want the written route beside these commands.'
    )
}

$helper.recommended_next_key = if ($helper.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($helper.repo_root) -or -not [string]::IsNullOrWhiteSpace($helper.summary_path)) {
    'windows_full_use_attached_html_route'
} else {
    'validation_router_attached_html_quickstart'
}
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader issue #3 helper chain.'
} elseif ($helper.recommended_next_key -eq 'windows_full_use_attached_html_route') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned through the broader Windows-facing attached-page bridge before narrowing again.'
} else {
    'No pinned bundle inputs, non-default repo root, or saved summary are in play yet, so jump straight from the broader Windows runbook into the validation-router attached-page quickstart.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 Windows full-use validation-router attached HTML quickstart'
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
Write-Host 'Broader Windows-facing bridge:'
Write-Host (("  Windows full-use attached route: {0}") -f $helper.commands.windows_full_use_attached_html_route)
Write-Host (("  Validation-router quickstart:    {0}") -f $helper.commands.validation_router_attached_html_quickstart)
Write-Host (("  Attached HTML change area:       {0}") -f $helper.commands.attached_html)
Write-Host (("  Google attached change area:     {0}") -f $helper.commands.google_attached_html)
Write-Host (("  Attached bundle change area:     {0}") -f $helper.commands.attached_html_target_bundle)
Write-Host ''
Write-Host 'Attached-page follow-up helpers:'
Write-Host (("  Top-level quickstart:       {0}") -f $helper.commands.top_level_attached_html_quickstart)
Write-Host (("  Catalog quickstart:         {0}") -f $helper.commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  Top-level attached bridge:  {0}") -f $helper.commands.top_level_attached_html_entrypoint)
Write-Host (("  Suite-router quickstart:    {0}") -f $helper.commands.suite_router_attached_html_quickstart)
Write-Host (("  Replay shortcuts:           {0}") -f $helper.commands.replay_shortcuts)
Write-Host (("  Next-step matrix:           {0}") -f $helper.commands.suite_router_next_steps)
Write-Host (("  Bundle-first helper:        {0}") -f $helper.commands.attached_bundle_first)
Write-Host ''
Write-Host (("Windows runbook:               {0}") -f $helper.windows_runbook_note_path)
Write-Host (("Windows attached route note:   {0}") -f $helper.windows_full_use_attached_html_route_note_path)
Write-Host (("Validation-router note:        {0}") -f $helper.validation_router_attached_html_quickstart_note_path)
Write-Host (("Top-level quickstart note:     {0}") -f $helper.top_level_attached_html_quickstart_note_path)
Write-Host (("Catalog quickstart note:       {0}") -f $helper.top_level_attached_html_catalog_quickstart_note_path)
Write-Host (("Suite-router quickstart note:  {0}") -f $helper.suite_router_attached_html_quickstart_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
