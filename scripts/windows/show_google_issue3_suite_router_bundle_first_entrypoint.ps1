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
        [string]$RepoRootOverride
    )

    if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        $fallbackArguments = [System.Collections.Generic.List[string]]::new()
        foreach ($entry in $Arguments.GetEnumerator()) {
            Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $entry.Value
        }
        return Format-HelperCommand -ScriptName $ScriptName -Arguments $fallbackArguments
    }

    $command = "& '.\\scripts\\windows\\$ScriptName'"
    foreach ($entry in $Arguments.GetEnumerator()) {
        $value = $entry.Value
        if ($null -eq $value) {
            continue
        }
        if ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)) {
            continue
        }

        $escapedValue = ("$value") -replace "'", "''"
        $command += ((" -{0} '{1}'" -f $entry.Key, $escapedValue))
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

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$entrypoint = [ordered]@{
    issue = 'Google issue #3 suite-router bundle-first entrypoint'
    purpose = 'Print the shortest route from the top-level validation router into the pinned attached HTML target bundle path for issue #3 while preserving repo-root, saved-summary, and explicit bundle-input context.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    commands = [ordered]@{
        google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ SuiteName = 'google-recommended' }) -RepoRootOverride $RepoRoot
        google_input = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-input' }) -RepoRootOverride $RepoRoot
        attached_html_target_bundle = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'attached-html-target-bundle' }) -RepoRootOverride $RepoRoot
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        bundle_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -RepoRootOverride $RepoRoot
        bundle_input_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_attached_html_target_bundle.ps1' -RepoRootOverride $RepoRoot
        bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleArguments
        bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleArguments -Switches @('Wait')
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
    }
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    replay_quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    bundle_checklist_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md'
    windows_route_note_path = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md'
    validation_gates_note_path = 'docs/HEADED_MODE_VALIDATION_GATES.md'
    notes = @(
        'Use this helper when the current issue #3 follow-up is already the known three-page compatibility bundle and you want the bundle-first route printed without reopening the broader router notes by hand.',
        'Start with google_recommended or google_input when you want the higher-level validation router surface visible first.',
        'Use attached_html_target_bundle when the route should jump directly from the shared router into the pinned bundle branch.',
        'Run bundle_surface_check before trusting the pinned bundle chain after branch moves, because it fails fast on missing helper scripts or notes.',
        'Run bundle_input_check when the current inputs may not actually be the known three-page compatibility set.',
        'Use attached_bundle_first when explicit InputPath values are already pinned and you want the dedicated issue #3 bundle-first helper to preserve that context through the rest of the chain.',
        'Use bundle_flow and bundle_runner when the route is ready to execute the delegated localhost replay instead of reopening the broader attached-page helper stack.',
        'Only widen into attached_html_shortcut, replay_shortcuts, or safe_route_entrypoints after the pinned bundle route has either reproduced the current failure or been ruled out cleanly.',
        'Keep the suite-router bridge note, the replay quickstart note, the bundle checklist note, the Windows attached-page route note, and the validation gates note nearby when you want the written route beside these commands.'
    )
}

$entrypoint.recommended_next_key = if ($entrypoint.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} else {
    'attached_html_target_bundle'
}
$entrypoint.recommended_next_command = $entrypoint.commands[$entrypoint.recommended_next_key]
$entrypoint.recommended_next_reason = if ($entrypoint.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit bundle inputs are already pinned, so keep that same input set on the dedicated bundle-first helper before widening back into the broader issue #3 route.'
} else {
    'No explicit bundle path is pinned yet, so jump straight from the shared validation router into the attached-html-target-bundle branch and keep the route locked there first.'
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 suite-router bundle-first entrypoint'
Write-Host ''
if ($entrypoint.repo_root) {
    Write-Host (("Repo root:   {0}") -f $entrypoint.repo_root)
}
if ($entrypoint.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($entrypoint.summary_path)"))
}
if ($entrypoint.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $entrypoint.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $entrypoint.recommended_next_command)
Write-Host (("Why:                    {0}") -f $entrypoint.recommended_next_reason)
Write-Host ''
Write-Host 'Top-level router bridge:'
Write-Host (("  Google recommended:      {0}") -f $entrypoint.commands.google_recommended)
Write-Host (("  Google input:            {0}") -f $entrypoint.commands.google_input)
Write-Host (("  Attached bundle change:  {0}") -f $entrypoint.commands.attached_html_target_bundle)
Write-Host ''
Write-Host 'Pinned bundle route:'
Write-Host (("  Bundle-first helper:     {0}") -f $entrypoint.commands.attached_bundle_first)
Write-Host (("  Surface checker:         {0}") -f $entrypoint.commands.bundle_surface_check)
Write-Host (("  Bundle checker:          {0}") -f $entrypoint.commands.bundle_input_check)
Write-Host (("  Flow helper:             {0}") -f $entrypoint.commands.bundle_flow)
Write-Host (("  Runner:                  {0}") -f $entrypoint.commands.bundle_runner)
Write-Host ''
Write-Host 'Only widen after the bundle route is clear:'
Write-Host (("  Attached shortcut:       {0}") -f $entrypoint.commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:        {0}") -f $entrypoint.commands.replay_shortcuts)
Write-Host (("  Safe-route map:          {0}") -f $entrypoint.commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Suite-router bridge note:  {0}") -f $entrypoint.suite_router_bridge_note_path)
Write-Host (("Replay quickstart note:    {0}") -f $entrypoint.replay_quickstart_note_path)
Write-Host (("Bundle checklist note:     {0}") -f $entrypoint.bundle_checklist_note_path)
Write-Host (("Windows route note:        {0}") -f $entrypoint.windows_route_note_path)
Write-Host (("Validation gates note:     {0}") -f $entrypoint.validation_gates_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}
