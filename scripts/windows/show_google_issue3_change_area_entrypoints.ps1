[CmdletBinding()]
param(
    [ValidateSet(
        "title",
        "quick",
        "home",
        "homepage-fixture",
        "home-keypress-submit",
        "submit-path",
        "submit-timing",
        "form-controls-enter-order",
        "shared-enter-order",
        "live-trace",
        "saved-html",
        "attached-html",
        "attached-html-target-bundle"
    )]
    [string]$ChangeArea = "title",
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-PhaseEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Summary,
        [Parameter(Mandatory = $true)]
        [string]$RouterCommand,
        [string]$SuiteCommand,
        [string]$SurfaceCheckCommand,
        [string]$FlowCommand,
        [string]$RunnerCommand,
        [string[]]$CompanionCommands = @(),
        [string[]]$NextWhenGreen = @()
    )

    return [ordered]@{
        change_area = $ChangeArea
        summary = $Summary
        router_command = $RouterCommand
        suite_command = $SuiteCommand
        surface_check_command = $SurfaceCheckCommand
        flow_command = $FlowCommand
        runner_command = $RunnerCommand
        companion_commands = $CompanionCommands
        next_when_green = $NextWhenGreen
    }
}

$phaseMap = @{
    "title" = (New-PhaseEntry `
        -Summary "Narrowest real-surface title, focus, typing, and Enter-submit checkpoint before the broader reduced-home or later submit-path ladders." `
        -RouterCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input" `
        -SuiteCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-title" `
        -SurfaceCheckCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_title_validation_surface.ps1" `
        -FlowCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_title_validation_flow.ps1" `
        -RunnerCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_title_validation.ps1" `
        -CompanionCommands @(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_title_probe_trace_guide.ps1"
        ) `
        -NextWhenGreen @(
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea quick",
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea home"
        ))
    "quick" = (New-PhaseEntry `
        -Summary "Fast title-plus-watch pass when the title checkpoint is already wired and you want a short rerun before widening into the reduced homepage or later timing slices." `
        -RouterCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input" `
        -SuiteCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-quick" `
        -SurfaceCheckCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_recommended_validation_surface.ps1" `
        -FlowCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_quick_validation_flow.ps1" `
        -RunnerCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_quick_validation.ps1" `
        -NextWhenGreen @(
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea home",
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea homepage-fixture"
        ))
    "home" = (New-PhaseEntry `
        -Summary "Reduced homepage focus, typing, keydown, and Enter-submit pass on the real headed surface after the localhost investigation probes are green." `
        -RouterCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input" `
        -SuiteCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-home" `
        -SurfaceCheckCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_recommended_validation_surface.ps1" `
        -FlowCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_input_validation_flow.ps1" `
        -RunnerCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_home_validation.ps1" `
        -NextWhenGreen @(
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea homepage-fixture",
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea submit-timing"
        ))
    "homepage-fixture" = (New-PhaseEntry `
        -Summary "Saved localhost Google homepage fixture checkpoint for focus, typed text, and Enter submit before the later Enter-order and submit-path wrappers." `
        -RouterCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-submit-path" `
        -SuiteCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-homepage-fixture" `
        -SurfaceCheckCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_homepage_fixture_validation_surface.ps1" `
        -FlowCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1" `
        -RunnerCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_homepage_fixture_validation.ps1" `
        -NextWhenGreen @(
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea home-keypress-submit",
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea submit-path"
        ))
    "home-keypress-submit" = (New-PhaseEntry `
        -Summary "Reduced-home keypress-before-submit bridge between the saved homepage fixture checkpoint and the broader submit-path or submit-timing ladders." `
        -RouterCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-submit-path" `
        -SuiteCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-home-keypress-submit" `
        -SurfaceCheckCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_home_keypress_submit_validation_surface.ps1" `
        -FlowCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_home_keypress_submit_validation_flow.ps1" `
        -RunnerCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_home_keypress_submit_validation.ps1" `
        -NextWhenGreen @(
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea submit-path",
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea submit-timing"
        ))
    "submit-path" = (New-PhaseEntry `
        -Summary "Later-stage saved-homepage-fixture, reduced Enter-trace, submit-timing, and shared Enter-order ladder when the earlier title and reduced-home checkpoints are already green." `
        -RouterCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-submit-path" `
        -SuiteCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-submit-path" `
        -SurfaceCheckCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_submit_path_validation_surface.ps1" `
        -FlowCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_path_validation_flow.ps1" `
        -RunnerCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_submit_path_validation.ps1" `
        -CompanionCommands @(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_path_trace_guide.ps1",
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_path_handoff.ps1"
        ) `
        -NextWhenGreen @(
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea submit-timing",
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea shared-enter-order"
        ))
    "submit-timing" = (New-PhaseEntry `
        -Summary "Bounded keydown, keypress, and submit-ordering slice before the stricter shared Enter-order ladder or the live-trace handoff." `
        -RouterCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-submit-path" `
        -SuiteCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-submit-timing" `
        -SurfaceCheckCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_submit_timing_validation_surface.ps1" `
        -FlowCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1" `
        -RunnerCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_submit_timing_validation.ps1" `
        -NextWhenGreen @(
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea form-controls-enter-order",
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea shared-enter-order"
        ))
    "form-controls-enter-order" = (New-PhaseEntry `
        -Summary "Smallest shared form-controls keypress-before-submit gate before widening into the broader shared Enter-order stack." `
        -RouterCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order" `
        -SuiteCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-form-controls-enter-order" `
        -SurfaceCheckCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_form_controls_enter_order_validation_surface.ps1" `
        -FlowCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_validation_flow.ps1" `
        -RunnerCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_form_controls_enter_order_validation.ps1" `
        -CompanionCommands @(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_trace_guide.ps1"
        ) `
        -NextWhenGreen @(
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea shared-enter-order"
        ))
    "shared-enter-order" = (New-PhaseEntry `
        -Summary "Shared Enter-order ladder that combines label-click baseline, shared submit gates, reduced Google-home form coverage, and the stricter localhost keypress-before-submit wrapper." `
        -RouterCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order" `
        -SuiteCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-shared-enter-order" `
        -SurfaceCheckCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_shared_enter_order_validation_surface.ps1" `
        -FlowCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1" `
        -RunnerCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_shared_enter_order_validation.ps1" `
        -NextWhenGreen @(
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea live-trace",
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea saved-html"
        ))
    "live-trace" = (New-PhaseEntry `
        -Summary "Read-first reduced-home and live Google trace-capture handoff once the bounded timing and shared Enter-order gates are green but the real homepage still diverges." `
        -RouterCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-live-trace" `
        -SuiteCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-live-trace" `
        -SurfaceCheckCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_trace_validation_surface.ps1" `
        -FlowCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_trace_validation_flow.ps1" `
        -RunnerCommand "" `
        -NextWhenGreen @(
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea saved-html",
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea attached-html"
        ))
    "saved-html" = (New-PhaseEntry `
        -Summary "Saved-page localhost Google-style follow-up once the bounded issue #3 gates are green and you want the same command chain applied to exported or staged HTML pages." `
        -RouterCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-saved-html" `
        -SuiteCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-saved-html" `
        -SurfaceCheckCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_saved_page_localhost_validation_surface.ps1" `
        -FlowCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_saved_page_google_validation_flow.ps1 -InputPath '<saved-html-or-folder>'" `
        -RunnerCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_localhost_html_validation_recommended.ps1 -Wait" `
        -NextWhenGreen @(
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea attached-html",
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea attached-html-target-bundle"
        ))
    "attached-html" = (New-PhaseEntry `
        -Summary "Google-style attached-page localhost follow-up for current-run HTML after the bounded issue #3 gates are green." `
        -RouterCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-attached-html" `
        -SuiteCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-attached-html" `
        -SurfaceCheckCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1" `
        -FlowCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1" `
        -RunnerCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_attached_html_validation.ps1 -Wait" `
        -CompanionCommands @(
            ".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html",
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_entrypoint.ps1",
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_attached_html_quickstart.ps1"
        ) `
        -NextWhenGreen @(
            ".\\scripts\\windows\\show_google_issue3_change_area_entrypoints.ps1 -ChangeArea attached-html-target-bundle"
        ))
    "attached-html-target-bundle" = (New-PhaseEntry `
        -Summary "Pinned three-page attached-HTML compatibility route when the current follow-up inputs are still the known bundle and you want the fail-fast bundle checker plus the delegated localhost runner." `
        -RouterCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle" `
        -SuiteCommand ".\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName attached-html-target-bundle" `
        -SurfaceCheckCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_target_bundle_validation_surface.ps1" `
        -FlowCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_target_bundle_validation_flow.ps1" `
        -RunnerCommand "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1 -Wait" `
        -CompanionCommands @(
            "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1",
            ".\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html"
        ) `
        -NextWhenGreen @(
            "Use the saved screenshots, titles, and localhost summaries to choose the next shared engine fix or the next narrower bundle-specific regression probe."
        ))
}

$entry = $phaseMap[$ChangeArea]
if (-not $entry) {
    throw "Unknown issue #3 change area: $ChangeArea"
}

if ($Json) {
    $entry | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Issue #3 change-area entrypoints"
Write-Host ""
Write-Host ("Change area: {0}" -f $ChangeArea)
Write-Host ("Summary: {0}" -f $entry.summary)
Write-Host ""
Write-Host ("Shared router: {0}" -f $entry.router_command)
if ($entry.suite_command) {
    Write-Host ("Suite route: {0}" -f $entry.suite_command)
}
if ($entry.surface_check_command) {
    Write-Host ("Surface check: {0}" -f $entry.surface_check_command)
}
if ($entry.flow_command) {
    Write-Host ("Flow helper: {0}" -f $entry.flow_command)
}
if ($entry.runner_command) {
    Write-Host ("Runner: {0}" -f $entry.runner_command)
}
if ($entry.companion_commands.Count -gt 0) {
    Write-Host ""
    Write-Host "Companion commands:"
    foreach ($command in $entry.companion_commands) {
        Write-Host ("- {0}" -f $command)
    }
}
if ($entry.next_when_green.Count -gt 0) {
    Write-Host ""
    Write-Host "Next when green:"
    foreach ($next in $entry.next_when_green) {
        Write-Host ("- {0}" -f $next)
    }
}
