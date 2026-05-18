[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
    [string]$BrowserExe,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-PowerShellSingleQuotedLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    }

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
            if ($entry.Value -is [System.Array]) {
                Add-SharedPathArrayArgument -Arguments $fallbackArguments -Name $entry.Key -Values $entry.Value
            } else {
                Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $entry.Value
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
        if ($value -is [System.Array]) {
            $command += " -$($entry.Key)"
            foreach ($item in $value) {
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

$bundleCheckerArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleCheckerArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleCheckerArguments -Name InputPath -Values $InputPath

$bundleRouteArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleRouteArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleRouteArguments -Name BrowserExe -Value $BrowserExe
Add-SharedPathArrayArgument -Arguments $bundleRouteArguments -Name InputPath -Values $InputPath

$bundleSurfaceCheckArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleSurfaceCheckArguments -Name RepoRoot -Value $RepoRoot

$reentryArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $reentryArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $reentryArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $reentryArguments -Name InputPath -Values $InputPath

$bundleFirstArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleFirstArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleFirstArguments -Name SummaryPath -Value $SummaryPath
Add-SharedArgument -Arguments $bundleFirstArguments -Name BrowserExe -Value $BrowserExe
Add-SharedPathArrayArgument -Arguments $bundleFirstArguments -Name InputPath -Values $InputPath

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath -and $InputPath.Count -gt 0) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$googleAttachedHtmlFlowArguments = [ordered]@{}
if ($InputPath -and $InputPath.Count -gt 0) {
    $googleAttachedHtmlFlowArguments['InputPath'] = @($InputPath)
}
if ($BrowserExe) {
    $googleAttachedHtmlFlowArguments['BrowserExe'] = $BrowserExe
}

$surface = [ordered]@{
    issue = 'Google issue #3 attached-html target-bundle suite surface'
    purpose = 'Print the compact suite-level route for the known three-page attached HTML compatibility bundle while keeping the broader attached-page lane, the full Google-shaped attached-page validation route, the pinned bundle checker, and the proof-entry follow-up visible beside the attached-html-target-bundle change-area output.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    browser_exe = $BrowserExe
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    suite_commands = [ordered]@{
        attached_html_target_bundle = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'attached-html-target-bundle' }) -RepoRootOverride $RepoRoot
        attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'attached-html' }) -RepoRootOverride $RepoRoot
        google_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-attached-html' }) -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot
        google_attached_html_asset_closure = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_attached_html_local_asset_closure.ps1' -Arguments $attachedHtmlFlowArguments -Switches @('GoogleStyle') -RepoRootOverride $RepoRoot
        broader_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments -RepoRootOverride $RepoRoot
        google_attached_html_runner = Format-HelperCommandWithRepoRootEnv -ScriptName 'run_google_attached_html_validation.ps1' -Arguments $googleAttachedHtmlFlowArguments -Switches @('Wait') -RepoRootOverride $RepoRoot
        bundle_surface_check = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $bundleSurfaceCheckArguments
        bundle_check = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle.ps1' -Arguments $bundleCheckerArguments
        bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleRouteArguments
        bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleRouteArguments -Switches @('Wait')
        bundle_proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $reentryArguments
        top_level_attached_html_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $reentryArguments
        bundle_first_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleFirstArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $reentryArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $reentryArguments
    }
    note_paths = [ordered]@{
        bundle_reference = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
        bundle_quickstart = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md'
        bundle_checklist = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md'
        top_level_attached_html_bridge = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md'
        bundle_first_bridge = 'docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md'
        google_attached_html_flow = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
        windows_replay_attached_html_quickstart = 'docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md'
        validation_chain = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    }
    notes = @(
        'Use this helper when you want the attached-html-target-bundle suite surface printed with the broader attached-page lane, the full Google-shaped attached-page follow-up route, the bundle checker, and the proof-entry follow-up still visible beside it.',
        'Start with the attached_html_target_bundle suite command when the current attached pages are already the likely three-page compatibility bundle and you want the compact suite surface first.',
        'Keep the attached_html suite command nearby when the replay may still need the broader attached-page fallback before it locks onto the pinned bundle branch.',
        'Keep the google_attached_html suite command nearby when the current inputs include a Google-like attached page and the narrower Google-shaped helper chain still matters before bundle-first replay.',
        'Run google_attached_html_surface_check, google_attached_html_asset_closure, broader_attached_html_flow, google_attached_html_flow, and google_attached_html_runner before the bundle-only route when the next decision still depends on seeing the broader attached-page lane and the full Google-shaped attached-page chain beside the pinned bundle lane.',
        'Run bundle_surface_check before trusting the bundle-only replay after branch moves or helper renames.',
        'Run bundle_check right after bundle_surface_check when you want the current saved-page set revalidated as the same known three-page compatibility bundle before the delegated runner takes over.',
        'Pass -BrowserExe when the bundle-specific route should stay pinned to a non-default Windows headed build through the suite surface, bundle-first entrypoint, printed bundle flow, and delegated bundle runner.',
        'Use bundle_proof_entrypoint after the bundle runner when the delegated bundle replay is green and the next decision depends on keeping the fixed-list screenshot-and-title proof pinned to the same saved inputs.',
        'Use top_level_attached_html_bridge when the bundle replay still needs the broader top-level attached-page bridge reprinted before the route drops into the bundle-first helper or the replay-route helpers.',
        'Use bundle_first_entrypoint when explicit input paths, repo-root context, replay-route context, or a non-default BrowserExe are already in play and you want the narrower issue #3 bridge printed before the delegated bundle flow.',
        'Return to replay_route or replay_shortcuts only after the pinned bundle route makes the next attached-page failure state clear.'
    )
}

$surface.recommended_next_key = if ($surface.explicit_input_path_count -gt 0) {
    'bundle_first_entrypoint'
} else {
    'bundle_surface_check'
}
$surface.recommended_next_command = $surface.helper_commands[$surface.recommended_next_key]
$surface.recommended_next_reason = if ($surface.recommended_next_key -eq 'bundle_first_entrypoint') {
    'Explicit attached-page paths are already pinned, so keep that same bundle context on the narrower issue #3 bridge before you delegate into the bundle flow and runner.'
} else {
    'No explicit bundle paths are pinned yet, so fail fast on the bundle surface first while the broader attached-page lane, the full Google-shaped attached-page route, the bundle checker, and the proof-entry follow-up stay visible beside the suite surface.'
}

if ($Json) {
    $surface | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 attached-html target-bundle suite surface'
Write-Host ''
if ($surface.repo_root) {
    Write-Host (("Repo root:   {0}") -f $surface.repo_root)
}
if ($surface.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($surface.summary_path)"))
}
if ($surface.browser_exe) {
    Write-Host (("Browser exe: {0}") -f $surface.browser_exe)
}
if ($surface.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $surface.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $surface.recommended_next_command)
Write-Host (("Why:                    {0}") -f $surface.recommended_next_reason)
Write-Host ''
Write-Host 'Suite surface:'
Write-Host (("  Bundle suite:    {0}") -f $surface.suite_commands.attached_html_target_bundle)
Write-Host (("  Broader suite:   {0}") -f $surface.suite_commands.attached_html)
Write-Host (("  Google suite:    {0}") -f $surface.suite_commands.google_attached_html)
Write-Host ''
Write-Host 'Keep visible beside bundle replay:'
Write-Host (("  Google surface:  {0}") -f $surface.helper_commands.google_attached_html_surface_check)
Write-Host (("  Google assets:   {0}") -f $surface.helper_commands.google_attached_html_asset_closure)
Write-Host (("  Broader flow:    {0}") -f $surface.helper_commands.broader_attached_html_flow)
Write-Host (("  Google flow:     {0}") -f $surface.helper_commands.google_attached_html_flow)
Write-Host (("  Google runner:   {0}") -f $surface.helper_commands.google_attached_html_runner)
Write-Host (("  Surface check:   {0}") -f $surface.helper_commands.bundle_surface_check)
Write-Host (("  Bundle check:    {0}") -f $surface.helper_commands.bundle_check)
Write-Host (("  Bundle flow:     {0}") -f $surface.helper_commands.bundle_flow)
Write-Host (("  Bundle runner:   {0}") -f $surface.helper_commands.bundle_runner)
Write-Host (("  Proof entry:     {0}") -f $surface.helper_commands.bundle_proof_entrypoint)
Write-Host ''
Write-Host 'Narrower issue #3 re-entry:'
Write-Host (("  Top-level bridge:{0}") -f (" $($surface.helper_commands.top_level_attached_html_bridge)"))
Write-Host (("  Bundle-first:    {0}") -f $surface.helper_commands.bundle_first_entrypoint)
Write-Host (("  Replay route:    {0}") -f $surface.helper_commands.replay_route)
Write-Host (("  Replay shortcuts:{0}") -f (" $($surface.helper_commands.replay_shortcuts)"))
Write-Host ''
Write-Host (("Bundle reference note:      {0}") -f $surface.note_paths.bundle_reference)
Write-Host (("Bundle quickstart note:     {0}") -f $surface.note_paths.bundle_quickstart)
Write-Host (("Bundle checklist note:      {0}") -f $surface.note_paths.bundle_checklist)
Write-Host (("Top-level bridge note:      {0}") -f $surface.note_paths.top_level_attached_html_bridge)
Write-Host (("Bundle-first bridge note:   {0}") -f $surface.note_paths.bundle_first_bridge)
Write-Host (("Google attached-flow note:  {0}") -f $surface.note_paths.google_attached_html_flow)
Write-Host (("Replay quickstart note:     {0}") -f $surface.note_paths.windows_replay_attached_html_quickstart)
Write-Host (("Validation chain note:      {0}") -f $surface.note_paths.validation_chain)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $surface.notes) {
    Write-Host (("- {0}") -f $note)
}
