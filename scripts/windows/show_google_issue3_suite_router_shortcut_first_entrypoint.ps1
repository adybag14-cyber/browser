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
        [string[]]$Switches = @(),
        [System.Collections.Generic.List[string]]$Arguments
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

function Add-RepoRootEnvToCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [string]$RepoRootOverride
    )

    if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        return $Command
    }

    $escapedRepoRoot = ("$RepoRootOverride") -replace "'", "''"
    return "powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$env:LIGHTPANDA_REPO_ROOT = '$escapedRepoRoot'; $Command`""
}

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$attachedHtmlFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $attachedHtmlFlowArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $attachedHtmlFlowArguments -Name InputPath -Values $InputPath

$entrypoint = [ordered]@{
    issue = 'Google issue #3 suite-router shortcut-first entrypoint'
    purpose = 'Keep the shortest top-level route from the headed validation suite router into the newer replay-shortcuts helper, while also surfacing the broader attached-page localhost flow, the narrower Google-shaped attached-page flow, and the issue #3-specific attached-page shortcut beside the pinned-bundle branch and preserving repo-root, saved-summary, and pinned bundle-input context when it is already in play.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    top_level_commands = [ordered]@{
        google_recommended = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            SuiteName = 'google-recommended'
        }) -RepoRootOverride $RepoRoot
        google_input_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-input'
        }) -RepoRootOverride $RepoRoot
        attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html'
        }) -RepoRootOverride $RepoRoot
        google_attached_html_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-attached-html'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        google_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_input_validation_flow.ps1' -RepoRootOverride $RepoRoot
    }
    helper_commands = [ordered]@{
        attached_html_flow = Add-RepoRootEnvToCommand -Command (Format-HelperCommand -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments) -RepoRootOverride $RepoRoot
        google_attached_html_flow = Add-RepoRootEnvToCommand -Command (Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments) -RepoRootOverride $RepoRoot
        attached_html_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_shortcut_entrypoint.ps1' -Arguments $bundleArguments
        replay_shortcuts = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments $bundleArguments
        contextual_flow = Format-HelperCommand -ScriptName 'show_google_issue3_contextual_flow.ps1' -Arguments $bundleArguments
        suite_router_next_steps = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_next_steps.ps1' -Arguments $bundleArguments
        suite_router_handoff = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_handoff.ps1' -Arguments $bundleArguments
        replay_route = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route.ps1' -Arguments $bundleArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $bundleArguments
        fresh_safe_route_replay = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments $bundleArguments
        reuse_current_outputs = Format-HelperCommand -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments $bundleArguments
    }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    suite_router_bridge_note_path = 'docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md'
    suite_catalog_entrypoint_note_path = 'docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md'
    google_attached_html_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    notes = @(
        'Use this helper when issue #3 work is clearly inside the top-level Windows validation router and you want the shortcut-first bridge printed without reopening the broader suite-catalog or replay-route surfaces first.',
        'Start with google_recommended when you want the top-level suite catalog to name the broader localhost-first issue #3 runner before the route narrows.',
        'Start with google_input_change_area when the route is already known to stay inside issue #3 and you want the same top-level helper family reprinted before dropping into attached_html_flow, google_attached_html_flow, attached_html_shortcut, replay_shortcuts, contextual_flow, attached_bundle_first, or the wrapper-heavy safe-route helpers.',
        'Start with attached_html_change_area when the replay is already narrowed to the broader attached-page compatibility follow-up route and you want that top-level branch kept visible before deciding whether to stay on the pinned bundle-first path or narrow again into the issue #3-specific attached-page helper.',
        'Start with google_attached_html_change_area when the replay is already inside the issue #3-specific attached-page follow-up surface before the bundle is pinned, so that narrower Google-only route stays visible before you choose attached_html_flow, google_attached_html_flow, attached_html_shortcut, replay_shortcuts, contextual_flow, attached_bundle_first, or the wrapper-heavy safe-route helpers.',
        'Start with attached_bundle_change_area when the current saved or attached pages are still the known three-page compatibility bundle and you want that pinned branch shown from the top-level suite router first.',
        'Use attached_html_flow when you want the broader attached-page localhost helper reprinted directly from the compact suite-router surface before choosing between the narrower Google-shaped attached-page flow, the attached-page shortcut, replay shortcuts, contextual flow, attached_bundle_first, or the safe-route map.',
        'Use google_attached_html_flow when the current attached inputs are already Google-shaped and you want that narrower helper printed directly from the compact suite-router surface before deciding whether to narrow into the attached-page shortcut, replay shortcuts, contextual flow, attached_bundle_first, or the wrapper-heavy safe-route helpers.',
        'Use attached_html_shortcut when the replay is already narrowed to attached-page follow-up and you want the dedicated attached-page shortcut kept visible before you widen back into replay_shortcuts, the next-step matrix, attached_bundle_first, or the safe-route map.',
        'Use replay_shortcuts as the default next helper when no pinned bundle inputs, saved summary, or non-default repo root need to stay visible first.',
        'Use contextual_flow instead when RepoRoot or SummaryPath is already in play and you want the next surface to keep that replay context aligned before choosing between attached_html_flow, google_attached_html_flow, attached_html_shortcut, replay_shortcuts, replay_route, attached_bundle_first, or the later wrapper-heavy helpers.',
        'Use attached_bundle_first instead when explicit InputPath values are already pinned and the replay should stay on the known three-page compatibility set before widening back into the broader Google-only helpers.',
        'Use suite_router_next_steps when you still want the explicit start-point matrix after this shorter bridge, suite_router_handoff when you want the wider compact bridge, and replay_route when you want the slightly broader helper chain after replay_shortcuts has already re-established the issue #3 route.',
        'Keep the quickstart, suite-router bridge, suite-catalog guide, Google attached-page flow note, and validation-chain notes nearby when you want the written route beside these commands.'
    )
}

$entrypoint.recommended_next_key = if ($entrypoint.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} elseif (-not [string]::IsNullOrWhiteSpace($entrypoint.repo_root) -or -not [string]::IsNullOrWhiteSpace($entrypoint.summary_path)) {
    'contextual_flow'
} else {
    'replay_shortcuts'
}
$entrypoint.recommended_next_command = $entrypoint.helper_commands[$entrypoint.recommended_next_key]
$entrypoint.recommended_next_reason = if ($entrypoint.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already in play, so stay pinned to the known three-page compatibility bundle before widening back into the broader Google-only issue #3 path.'
} elseif ($entrypoint.recommended_next_key -eq 'contextual_flow') {
    'A non-default repo root or saved summary is already in play, so keep that replay context aligned before choosing between the broader attached-page flows, the attached-page shortcut, replay shortcuts, replay route, the attached bundle branch, or the safe-route wrappers.'
} else {
    'No pinned bundle inputs, saved summary, or non-default repo root are in play yet, so jump straight from the top-level suite router into the narrower replay-shortcuts helper.'
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 suite-router shortcut-first entrypoint'
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
Write-Host 'Top-level suite-router bridge:'
Write-Host (("  1. Google recommended:   {0}") -f $entrypoint.top_level_commands.google_recommended)
Write-Host (("  2. Google input:         {0}") -f $entrypoint.top_level_commands.google_input_change_area)
Write-Host (("  3. Attached HTML:        {0}") -f $entrypoint.top_level_commands.attached_html_change_area)
Write-Host (("  4. Google attached HTML: {0}") -f $entrypoint.top_level_commands.google_attached_html_change_area)
Write-Host (("  5. Attached bundle:      {0}") -f $entrypoint.top_level_commands.attached_bundle_change_area)
Write-Host (("  6. Google flow:          {0}") -f $entrypoint.top_level_commands.google_flow)
Write-Host (("  7. Attached-page flow:   {0}") -f $entrypoint.helper_commands.attached_html_flow)
Write-Host (("  8. Google attached flow: {0}") -f $entrypoint.helper_commands.google_attached_html_flow)
Write-Host (("  9. Attached shortcut:    {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host ((" 10. Replay shortcuts:     {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host ((" 11. Contextual flow:      {0}") -f $entrypoint.helper_commands.contextual_flow)
Write-Host ((" 12. Next-step matrix:     {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host ((" 13. Bundle first:         {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host ''
Write-Host 'Companion helpers:'
Write-Host (("  Attached-page flow:  {0}") -f $entrypoint.helper_commands.attached_html_flow)
Write-Host (("  Google attached:     {0}") -f $entrypoint.helper_commands.google_attached_html_flow)
Write-Host (("  Attached shortcut:   {0}") -f $entrypoint.helper_commands.attached_html_shortcut)
Write-Host (("  Replay shortcuts:    {0}") -f $entrypoint.helper_commands.replay_shortcuts)
Write-Host (("  Contextual flow:     {0}") -f $entrypoint.helper_commands.contextual_flow)
Write-Host (("  Next-step matrix:    {0}") -f $entrypoint.helper_commands.suite_router_next_steps)
Write-Host (("  Suite-router handoff:{0}") -f (' ' + $entrypoint.helper_commands.suite_router_handoff))
Write-Host (("  Replay route:        {0}") -f $entrypoint.helper_commands.replay_route)
Write-Host (("  Bundle first:        {0}") -f $entrypoint.helper_commands.attached_bundle_first)
Write-Host (("  Safe-route map:      {0}") -f $entrypoint.helper_commands.safe_route_entrypoints)
Write-Host (("  Fresh safe replay:   {0}") -f $entrypoint.helper_commands.fresh_safe_route_replay)
Write-Host (("  Reuse current output:{0}") -f (' ' + $entrypoint.helper_commands.reuse_current_outputs))
Write-Host ''
Write-Host (("Quickstart note:      {0}") -f $entrypoint.quickstart_note_path)
Write-Host (("Suite-router bridge:  {0}") -f $entrypoint.suite_router_bridge_note_path)
Write-Host (("Suite-catalog guide:  {0}") -f $entrypoint.suite_catalog_entrypoint_note_path)
Write-Host (("Google attached note: {0}") -f $entrypoint.google_attached_html_flow_note_path)
Write-Host (("Validation chain:     {0}") -f $entrypoint.validation_chain_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}
