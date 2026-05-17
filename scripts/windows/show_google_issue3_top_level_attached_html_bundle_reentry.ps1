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
            if ($entry.Value -is [System.Array]) {
                Add-SharedPathArrayArgument -Arguments $fallbackArguments -Name $entry.Key -Values $entry.Value
            } else {
                Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $entry.Value
            }
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
        $command += " -$($entry.Key) '$escapedValue'"
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

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$bundleSurfaceCheckArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleSurfaceCheckArguments -Name RepoRoot -Value $RepoRoot

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$googleAttachedHtmlFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $googleAttachedHtmlFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $googleAttachedHtmlFlowArguments -Name InputPath -Values $InputPath

$surface = [ordered]@{
    issue = 'Google issue #3 top-level attached HTML bundle re-entry'
    purpose = 'Keep the top-level attached-page route pinned to the known three-page compatibility bundle by printing the broader top-level attached-page bridge, the compact bundle suite surface, the fail-fast bundle surface check, the bundle flow helper, the bundle-first handoff, the delegated bundle runner, and the proof follow-up on one smaller helper.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    helper_commands = [ordered]@{
        top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments
        top_level_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $bundleArguments
        top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        suite_catalog_top_level_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1' -Arguments $bundleArguments
        broader_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments
        attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $bundleArguments
        attached_bundle_surface_check = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $bundleSurfaceCheckArguments
        attached_bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        attached_bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleArguments -Switches @('Wait')
        attached_bundle_proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $bundleArguments
        replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
    }
    note_paths = [ordered]@{
        top_level_attached_html_bridge = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
        top_level_attached_html_catalog_quickstart = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
        suite_catalog_top_level_attached_html_catalog_quickstart = 'docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md'
        bundle_reference = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
        bundle_suite_surface = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md'
        bundle_quickstart = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md'
        bundle_checklist = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md'
        replay_route_bundle_first_bridge = 'docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md'
        google_attached_html_flow = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
        this_note = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BUNDLE_REENTRY.md'
    }
    notes = @(
        'Use this helper when the top-level attached-page route is already the right issue #3 branch and the next replay should stay pinned to the known three-page compatibility bundle.',
        'Start with the broader top-level attached-page bridge when the replay still needs the wider route context reprinted before it narrows into the bundle-only lane.',
        'Keep the broader attached-page flow and the dedicated Google-shaped attached-page flow visible beside the compact bundle helper when the replay may still widen back out before the bundle lane is trusted.',
        'Run the bundle surface check before trusting the pinned bundle route after helper renames or branch updates.',
        'Use the bundle-first helper when explicit InputPath values are already pinned and the replay should stay on the same bundle inputs all the way into the delegated runner and proof follow-up.',
        'Use the proof entrypoint after the delegated bundle runner when the next decision depends on the fixed-list screenshot-and-title proof staying on the same saved inputs.'
    )
}

$surface.recommended_next_key = if ($surface.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} else {
    'attached_bundle_surface_check'
}
$surface.recommended_next_command = $surface.helper_commands[$surface.recommended_next_key]
$surface.recommended_next_reason = if ($surface.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit attached-page inputs are already pinned, so stay on the narrower bundle-first bridge before delegating into the bundle runner and proof follow-up.'
} else {
    'No explicit bundle inputs are pinned yet, so fail fast on the bundle surface first while the broader top-level attached-page and bundle context are still visible together.'
}

if ($Json) {
    $surface | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 top-level attached HTML bundle re-entry'
Write-Host ''
if ($surface.repo_root) {
    Write-Host (("Repo root:   {0}") -f $surface.repo_root)
}
if ($surface.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($surface.summary_path)"))
}
if ($surface.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $surface.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $surface.recommended_next_command)
Write-Host (("Why:                    {0}") -f $surface.recommended_next_reason)
Write-Host ''
Write-Host 'Top-level attached-page bundle route:'
Write-Host (("  1. Top-level attached bridge:      {0}") -f $surface.helper_commands.top_level_attached_html_entrypoint)
Write-Host (("  2. Top-level quickstart:           {0}") -f $surface.helper_commands.top_level_attached_html_quickstart)
Write-Host (("  3. Top-level catalog quickstart:   {0}") -f $surface.helper_commands.top_level_attached_html_catalog_quickstart)
Write-Host (("  4. Catalog-side quickstart:        {0}") -f $surface.helper_commands.suite_catalog_top_level_attached_html_catalog_quickstart)
Write-Host (("  5. Broader attached flow:          {0}") -f $surface.helper_commands.broader_attached_html_flow)
Write-Host (("  6. Google attached flow:           {0}") -f $surface.helper_commands.google_attached_html_flow)
Write-Host (("  7. Bundle suite surface:           {0}") -f $surface.helper_commands.attached_bundle_suite_surface)
Write-Host (("  8. Bundle surface check:           {0}") -f $surface.helper_commands.attached_bundle_surface_check)
Write-Host (("  9. Bundle flow helper:             {0}") -f $surface.helper_commands.attached_bundle_flow)
Write-Host ((" 10. Bundle-first route:             {0}") -f $surface.helper_commands.attached_bundle_first)
Write-Host ((" 11. Bundle runner:                  {0}") -f $surface.helper_commands.attached_bundle_runner)
Write-Host ((" 12. Bundle proof entrypoint:        {0}") -f $surface.helper_commands.attached_bundle_proof_entrypoint)
Write-Host ''
Write-Host 'Keep nearby if the route widens again:'
Write-Host (("  Replay-route shortcut:             {0}") -f $surface.helper_commands.replay_route_shortcut)
Write-Host (("  Replay shortcuts:                  {0}") -f $surface.helper_commands.replay_shortcuts)
Write-Host (("  Contextual flow:                   {0}") -f $surface.helper_commands.contextual_flow)
Write-Host (("  Safe-route map:                    {0}") -f $surface.helper_commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Top-level bridge note:               {0}") -f $surface.note_paths.top_level_attached_html_bridge)
Write-Host (("Top-level catalog note:              {0}") -f $surface.note_paths.top_level_attached_html_catalog_quickstart)
Write-Host (("Catalog-side quickstart note:        {0}") -f $surface.note_paths.suite_catalog_top_level_attached_html_catalog_quickstart)
Write-Host (("Bundle reference note:               {0}") -f $surface.note_paths.bundle_reference)
Write-Host (("Bundle suite-surface note:           {0}") -f $surface.note_paths.bundle_suite_surface)
Write-Host (("Bundle quickstart note:              {0}") -f $surface.note_paths.bundle_quickstart)
Write-Host (("Bundle checklist note:               {0}") -f $surface.note_paths.bundle_checklist)
Write-Host (("Replay-route bundle-first note:      {0}") -f $surface.note_paths.replay_route_bundle_first_bridge)
Write-Host (("Google attached-flow note:           {0}") -f $surface.note_paths.google_attached_html_flow)
Write-Host (("This note:                           {0}") -f $surface.note_paths.this_note)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $surface.notes) {
    Write-Host (("- {0}") -f $note)
}
