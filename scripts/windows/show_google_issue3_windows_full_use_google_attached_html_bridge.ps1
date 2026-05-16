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

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $InputPath

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$route = [ordered]@{
    issue = 'Google issue #3 Windows full-use Google attached HTML bridge'
    purpose = 'Print the Windows-first route that keeps the broader attached-page helper surface, the dedicated Google-shaped attached-page flow helper, and the pinned bundle fallback visible together before replay narrows into the smaller issue #3 helpers.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    top_level_commands = [ordered]@{
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        windows_full_use_route_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -RepoRootOverride $RepoRoot
        windows_full_use_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $sharedArguments
        windows_validation_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $sharedArguments
        windows_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments
        broader_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $sharedArguments
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $sharedArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $sharedArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $sharedArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $sharedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $sharedArguments
    }
    windows_runbook_note_path = 'docs/WINDOWS_FULL_USE.md'
    windows_full_use_attached_html_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    windows_full_use_validation_router_attached_html_bridge_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md'
    windows_full_use_attached_html_catalog_quickstart_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md'
    google_attached_html_validation_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    attached_html_target_bundle_reference_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
    notes = @(
        'Use this helper when replay is reopening from docs/WINDOWS_FULL_USE.md or the broader Windows-first issue #3 route and you want the Google-shaped attached-page flow surfaced before the route narrows again.',
        'Run windows_full_use_route_surface_check first after branch moves so the broader Windows-first route fails fast on missing notes or helper scripts before the replay narrows.',
        'Use windows_full_use_route when you want the current Windows-first attached-page route printed as the broader parent surface before you drop into the tighter Google-shaped attached-page follow-up.',
        'Use windows_validation_bridge and windows_catalog_quickstart when you still want the broader Windows-to-validation-router bridge and Windows-first catalog step reprinted before the Google-shaped helper takes over.',
        'Use broader_attached_html_flow when the current attached-page set is not clearly Google-shaped yet and you still want the general attached-page localhost helper visible beside the narrower Google-shaped helper.',
        'Use google_attached_html_flow when the current attached inputs already include a Google-like page and you want the dedicated asset-closure, preferred-initial-page, and attached-page Google helper chain visible before the route narrows back into the issue #3 helper family.',
        'Use google_attached_html_entrypoint after the broader Windows-first route and the dedicated Google-shaped helper when you want the issue-specific attached-page bridge reprinted before the shorter attached-page shortcut.',
        'Use attached_html_shortcut only after the broader Windows-first and Google-shaped helper surfaces are already visible and the replay is ready to stay on the tighter issue #3 helper chain.',
        'Use replay_shortcuts or suite_router_next_steps after the shorter attached-page shortcut when you want the next compact helper layer without reopening the broader Windows-first route.',
        'Use contextual_flow when RepoRoot, SummaryPath, or pinned InputPath values already matter and the next helper should preserve that replay context before narrowing again.',
        'Use attached_bundle_first when explicit InputPath values are already pinned to the known three-page compatibility bundle and keep docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md nearby so the same inputs stay locked through the bundle-first replay path.'
    )
}

$route.recommended_next_key = if ($route.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($route.repo_root) -or -not [string]::IsNullOrWhiteSpace($route.summary_path)) {
    'contextual_flow'
} else {
    'windows_full_use_route'
}
$route.recommended_next_command = $route.helper_commands[$route.recommended_next_key]
$route.recommended_next_reason = if ($route.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so keep the replay on the known three-page compatibility bundle before widening back into the broader attached-page helper chain.'
} elseif ($route.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing between the broader attached-page helper, the Google-shaped helper, the shorter issue #3 shortcut, or the bundle-first fallback.'
} else {
    'No pinned bundle inputs, non-default repo root, or saved summary are in play yet, so reopen the broader Windows-first route first and keep the dedicated Google-shaped attached-page helper visible beside it before narrowing again.'
}

if ($Json) {
    $route | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 Windows full-use Google attached HTML bridge'
Write-Host ''
if ($route.repo_root) {
    Write-Host (("Repo root:   {0}") -f $route.repo_root)
}
if ($route.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($route.summary_path)"))
}
if ($route.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $route.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $route.recommended_next_command)
Write-Host (("Why:                    {0}") -f $route.recommended_next_reason)
Write-Host ''
Write-Host 'Top-level re-entry points:'
Write-Host (("  Attached HTML:        {0}") -f $route.top_level_commands.attached_html_change_area)
Write-Host (("  Google attached HTML: {0}") -f $route.top_level_commands.google_attached_html_change_area)
Write-Host (("  Attached bundle:      {0}") -f $route.top_level_commands.attached_bundle_change_area)
Write-Host ''
Write-Host 'Windows-first route:'
Write-Host (("  Surface checker:      {0}") -f $route.helper_commands.windows_full_use_route_surface_check)
Write-Host (("  Full-use route:       {0}") -f $route.helper_commands.windows_full_use_route)
Write-Host (("  Validation bridge:    {0}") -f $route.helper_commands.windows_validation_bridge)
Write-Host (("  Catalog quickstart:   {0}") -f $route.helper_commands.windows_catalog_quickstart)
Write-Host ''
Write-Host 'Attached-page flow handoff:'
Write-Host (("  Broader attached:     {0}") -f $route.helper_commands.broader_attached_html_flow)
Write-Host (("  Google attached:      {0}") -f $route.helper_commands.google_attached_html_flow)
Write-Host (("  Google entrypoint:    {0}") -f $route.helper_commands.google_attached_html_entrypoint)
Write-Host (("  Attached shortcut:    {0}") -f $route.helper_commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:     {0}") -f $route.helper_commands.replay_shortcuts)
Write-Host (("  Next-step matrix:     {0}") -f $route.helper_commands.suite_router_next_steps)
Write-Host (("  Contextual flow:      {0}") -f $route.helper_commands.contextual_flow)
Write-Host (("  Bundle-first helper:  {0}") -f $route.helper_commands.attached_bundle_first)
Write-Host ''
Write-Host (("Windows runbook:         {0}") -f $route.windows_runbook_note_path)
Write-Host (("Windows route note:      {0}") -f $route.windows_full_use_attached_html_route_note_path)
Write-Host (("Validation bridge note:  {0}") -f $route.windows_full_use_validation_router_attached_html_bridge_note_path)
Write-Host (("Windows catalog note:    {0}") -f $route.windows_full_use_attached_html_catalog_quickstart_note_path)
Write-Host (("Google attached note:    {0}") -f $route.google_attached_html_validation_flow_note_path)
Write-Host (("Bundle reference note:   {0}") -f $route.attached_html_target_bundle_reference_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $route.notes) {
    Write-Host (("- {0}") -f $note)
}
