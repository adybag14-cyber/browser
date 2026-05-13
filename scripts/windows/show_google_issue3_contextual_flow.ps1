[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$InputText = "QZ",
    [string]$SharedInputText = "Q",
    [string]$TraceInputText = "lightpanda",
    [string]$SummaryPath,
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
    [switch]$ManualGoogleStyle,
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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
        $command += " " + ($Arguments -join " ")
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
        [string]$RepoRootOverride,
        [hashtable]$Arguments = @{},
        [string[]]$Switches = @()
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

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\\bin\\lightpanda.exe"
}

$recommendedArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $recommendedArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $recommendedArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $recommendedArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $recommendedArgs -Name InputText -Value $InputText
Add-SharedArgument -Arguments $recommendedArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $recommendedArgs -Name TraceInputText -Value $TraceInputText
Add-SharedArgument -Arguments $recommendedArgs -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $recommendedArgs -Name ManualInputPath -Values $InputPath
Add-SharedArgument -Arguments $recommendedArgs -Name ManualInitialPage -Value $PreferredInitialPage
$recommendedSwitches = @()
if ($ManualGoogleStyle) {
    $recommendedSwitches += "ManualGoogleStyle"
}
if ($LeaveOpen) {
    $recommendedSwitches += "LeaveOpen"
}

$submitTimingArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $submitTimingArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $submitTimingArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $submitTimingArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $submitTimingArgs -Name InputText -Value $InputText

$sharedEnterArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedEnterArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedEnterArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $sharedEnterArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $sharedEnterArgs -Name SharedInputText -Value $SharedInputText

$traceArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $traceArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $traceArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $traceArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $traceArgs -Name InputText -Value $TraceInputText
$traceSwitches = @()
if ($LeaveOpen) {
    $traceSwitches += "LeaveOpen"
}

$attachedGoogleArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedPathArrayArgument -Arguments $attachedGoogleArgs -Name InputPath -Values $InputPath
Add-SharedArgument -Arguments $attachedGoogleArgs -Name PreferredInitialPage -Value $PreferredInitialPage
$attachedGoogleSwitches = @()
if ($LeaveOpen) {
    $attachedGoogleSwitches += "LeaveOpen"
}

$bundleArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArgs -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleArgs -Name InputPath -Values $InputPath

$shortcutArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $shortcutArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $shortcutArgs -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $shortcutArgs -Name InputPath -Values $InputPath

$flow = [ordered]@{
    issue = "Headed Windows Google issue #3 contextual flow"
    focus = "Keep the broader issue #3 replay chain on one context-preserving command surface so the top-level suite router, the suite-catalog bridge, the next-step matrix, repo root, browser path, host, input text, trace text, and attached-page inputs stay aligned across the existing narrower helpers."
    repo_root = $RepoRoot
    browser_exe = $BrowserExe
    host = $Host
    input_text = $InputText
    shared_input_text = $SharedInputText
    trace_input_text = $TraceInputText
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    preferred_initial_page = $PreferredInitialPage
    manual_google_style = [bool]$ManualGoogleStyle
    leave_open = [bool]$LeaveOpen
    suite_router_entrypoint_guide_path = "docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md"
    suite_router_bridge_note_path = "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md"
    quickstart_note_path = "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md"
    commands = [ordered]@{
        suite_router = Format-HelperCommandWithRepoRootEnv -ScriptName "show_headed_validation_suites.ps1" -RepoRootOverride $RepoRoot -Arguments ([ordered]@{
            ChangeArea = "google-input"
        })
        suite_catalog_entrypoints = Format-HelperCommand -ScriptName "show_google_issue3_suite_catalog_entrypoints.ps1" -Arguments $shortcutArgs
        suite_router_next_steps = Format-HelperCommand -ScriptName "show_google_issue3_suite_router_next_steps.ps1" -Arguments $shortcutArgs
        suite_router_handoff = Format-HelperCommand -ScriptName "show_google_issue3_suite_router_handoff.ps1" -Arguments $shortcutArgs
        replay_shortcuts = Format-HelperCommand -ScriptName "show_google_issue3_replay_shortcuts.ps1" -Arguments $shortcutArgs
        safe_route_entrypoints = Format-HelperCommand -ScriptName "show_google_issue3_safe_route_entrypoints.ps1" -Arguments $shortcutArgs
        recommended_runner = Format-HelperCommand -ScriptName "run_google_issue3_recommended_validation.ps1" -Arguments $recommendedArgs -Switches $recommendedSwitches
        submit_timing_flow = Format-HelperCommand -ScriptName "show_google_submit_timing_validation_flow.ps1" -Arguments $submitTimingArgs
        shared_enter_order_flow = Format-HelperCommand -ScriptName "show_google_shared_enter_order_validation_flow.ps1" -Arguments $sharedEnterArgs
        live_trace_flow = Format-HelperCommand -ScriptName "show_google_trace_validation_flow.ps1" -Arguments $traceArgs -Switches $traceSwitches
        attached_google_flow = Format-HelperCommand -ScriptName "show_google_attached_html_validation_flow.ps1" -Arguments $attachedGoogleArgs -Switches $attachedGoogleSwitches
        attached_bundle_flow = Format-HelperCommand -ScriptName "show_attached_html_target_bundle_validation_flow.ps1" -Arguments $bundleArgs
        attached_bundle_runner = Format-HelperCommand -ScriptName "run_attached_html_target_bundle_validation.ps1" -Arguments $bundleArgs -Switches @("Wait")
    }
    notes = @(
        "Start with suite_router when you want the higher-level Google issue #3 catalog reopened on the same repo root before you decide whether to stay broad or drop to a narrower helper.",
        "Use suite_catalog_entrypoints when you want the exact top-level suite-router entrypoints, the Google flow helper, the next-step matrix, and the current replay helpers reprinted together on one compact surface while preserving RepoRoot, SummaryPath, and fixed InputPath context.",
        "Use suite_router_next_steps when the route is already known to stay inside issue #3 and you want the fastest current helper recommendation without reopening the broader handoff surface first.",
        "Use suite_router_handoff when you still want the wider read-first bridge after the catalog helper or next-step matrix has re-established the likely route.",
        "Use replay_shortcuts after the next-step matrix or replay-route helper when you want the narrower issue #3 shortcut surface for the attached-bundle branch, the bundle-first helper, and the safe-route entrypoints before choosing a wrapper-heavy next step.",
        "Use safe_route_entrypoints when a saved summary is already in play and you want the smaller wrapper-first commands reopened without another broad regeneration pass first, or after the route has already narrowed into the current safe-route stack.",
        "Use recommended_runner when you want one context-preserving command that keeps repo root, browser path, host, input text, shared input text, trace input text, summary path, and optional attached-page inputs aligned through the broader localhost-first issue #3 runner.",
        "Use submit_timing_flow when the saved homepage fixture or submit-path ladder is already green and you only want the bounded keydown, keypress, and submit-order slice reopened on the same host, browser, and repo-root context.",
        "Use shared_enter_order_flow when the next question is whether the stricter shared keypress-before-submit gate still agrees with the same host, browser, repo-root, and shared input context.",
        "Use live_trace_flow only after the bounded localhost and shared Enter-order gates are green and you want the reduced-home or live-trace handoff reopened without losing the current browser, host, trace text, or LeaveOpen mode.",
        "Use attached_google_flow when the next replay should keep the current attached-page set and preferred initial page pinned before widening back out to the broader manual follow-up.",
        "Use attached_bundle_flow and attached_bundle_runner when the current inputs are still the known three-page compatibility bundle and you want that narrower route exercised before another broader Google-only replay.",
        "Keep suite_router_entrypoint_guide_path, suite_router_bridge_note_path, and quickstart_note_path nearby when you want the matching written bridge beside these commands without reopening the broader Windows runbook.",
        "When LeaveOpen is set, the emitted recommended runner, live trace flow, and attached Google flow preserve that same post-run inspection mode."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google issue #3 contextual flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Repo root: {0}" -f $flow.repo_root)
Write-Host ("Browser exe: {0}" -f $flow.browser_exe)
Write-Host ("Host: {0}" -f $flow.host)
Write-Host ("Input text: {0}" -f $flow.input_text)
Write-Host ("Shared input text: {0}" -f $flow.shared_input_text)
Write-Host ("Trace input text: {0}" -f $flow.trace_input_text)
Write-Host ("Leave open after selected helpers: {0}" -f $flow.leave_open)
if ($flow.summary_path) {
    Write-Host ("Summary path: {0}" -f $flow.summary_path)
}
if ($flow.explicit_input_path_count -gt 0) {
    Write-Host ("Attached input paths: {0}" -f $flow.explicit_input_path_count)
}
Write-Host ""
Write-Host "[suite-router] Reopen the higher-level issue #3 catalog"
Write-Host ("  {0}" -f $flow.commands.suite_router)
Write-Host ""
Write-Host "[suite-catalog-entrypoints] Reprint the top-level router bridge with current context"
Write-Host ("  {0}" -f $flow.commands.suite_catalog_entrypoints)
Write-Host ""
Write-Host "[suite-router-next-steps] Pick the fastest current helper from the routed issue #3 state"
Write-Host ("  {0}" -f $flow.commands.suite_router_next_steps)
Write-Host ""
Write-Host "[suite-router-handoff] Reopen the broader read-first bridge if the route still needs more context"
Write-Host ("  {0}" -f $flow.commands.suite_router_handoff)
Write-Host ""
Write-Host "[replay-shortcuts] Print the broader issue #3 discovery surface"
Write-Host ("  {0}" -f $flow.commands.replay_shortcuts)
Write-Host ""
Write-Host "[safe-route-entrypoints] Reopen the wrapper-first next-step map"
Write-Host ("  {0}" -f $flow.commands.safe_route_entrypoints)
Write-Host ""
Write-Host "[recommended-runner] Run the broader localhost-first issue #3 replay with preserved context"
Write-Host ("  {0}" -f $flow.commands.recommended_runner)
Write-Host ""
Write-Host "[submit-timing-flow] Reopen the bounded keydown, keypress, and submit-order slice"
Write-Host ("  {0}" -f $flow.commands.submit_timing_flow)
Write-Host ""
Write-Host "[shared-enter-order-flow] Reopen the stricter shared keypress-before-submit ladder"
Write-Host ("  {0}" -f $flow.commands.shared_enter_order_flow)
Write-Host ""
Write-Host "[live-trace-flow] Reopen the reduced-home and live-trace handoff"
Write-Host ("  {0}" -f $flow.commands.live_trace_flow)
Write-Host ""
Write-Host "[attached-google-flow] Reopen the attached-page Google-style follow-up"
Write-Host ("  {0}" -f $flow.commands.attached_google_flow)
Write-Host ""
Write-Host "[attached-bundle-flow] Print the pinned three-page bundle route"
Write-Host ("  {0}" -f $flow.commands.attached_bundle_flow)
Write-Host ""
Write-Host "[attached-bundle-runner] Run the pinned three-page bundle route"
Write-Host ("  {0}" -f $flow.commands.attached_bundle_runner)
Write-Host ""
Write-Host ("Suite-router guide: {0}" -f $flow.suite_router_entrypoint_guide_path)
Write-Host ("Bridge note:        {0}" -f $flow.suite_router_bridge_note_path)
Write-Host ("Quickstart note:    {0}" -f $flow.quickstart_note_path)
Write-Host ""
Write-Host "Notes:"
foreach ($note in $flow.notes) {
    Write-Host ("- {0}" -f $note)
}
