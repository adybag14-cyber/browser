[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function New-ValidationReference {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [ValidateSet("file", "directory")]
        [string]$Kind,
        [Parameter(Mandatory = $true)]
        [string]$Purpose
    )

    return [pscustomobject]@{
        Path = $Path
        Kind = $Kind
        Purpose = $Purpose
    }
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$references = @(
    (New-ValidationReference -Path "docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md" -Kind "file" -Purpose "Main issue #3 validation guide."),
    (New-ValidationReference -Path "docs/HEADED_GOOGLE_SUITE_VALIDATION_WINDOWS.md" -Kind "file" -Purpose "Compact read-first issue #3 guide."),
    (New-ValidationReference -Path "docs/GOOGLE_INPUT_VALIDATION.md" -Kind "file" -Purpose "Reduced Google title and Enter-order validation note."),
    (New-ValidationReference -Path "docs/GOOGLE_HOME_INPUT_PHASE_LOCALHOST_VALIDATION.md" -Kind "file" -Purpose "Dedicated reduced-home localhost input-phase note."),
    (New-ValidationReference -Path "docs/GOOGLE_HOMEPAGE_FIXTURE_VALIDATION.md" -Kind "file" -Purpose "Bounded saved-homepage fixture note used by the recommended runner."),
    (New-ValidationReference -Path "docs/GOOGLE_SUBMIT_PATH_VALIDATION.md" -Kind "file" -Purpose "Later-stage submit-path note used by the recommended runner."),
    (New-ValidationReference -Path "docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Shared Enter-order note used by the recommended runner."),
    (New-ValidationReference -Path "docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Smallest shared Enter-order note for the dedicated form-controls gate used late in the recommended runner."),
    (New-ValidationReference -Path "docs/GOOGLE_TRACE_VALIDATION.md" -Kind "file" -Purpose "Dedicated later trace-handoff note that the main issue #3 guide now routes to after the bounded checkpoints."),
    (New-ValidationReference -Path "docs/HEADED_ATTACHED_HTML_VALIDATION.md" -Kind "file" -Purpose "Attached HTML handoff guide used by the recommended runner."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the recommended issue #3 stack."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper layer for issue #3 validation scripts."),
    (New-ValidationReference -Path "scripts/windows/check_headed_validation_surface.ps1" -Kind "file" -Purpose "General headed validation surface checker."),
    (New-ValidationReference -Path "scripts/windows/check_google_validation_surface.ps1" -Kind "file" -Purpose "Compatibility wrapper for the Google validation surface checker."),
    (New-ValidationReference -Path "scripts/windows/check_google_title_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the bounded title-validation slice that now sits near the front of the recommended runner."),
    (New-ValidationReference -Path "scripts/windows/check_google_quick_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the fast title-plus-watch issue #3 slice that the main guide now routes through before the reduced homepage pass."),
    (New-ValidationReference -Path "scripts/windows/check_google_home_input_phase_validation_surface.ps1" -Kind "file" -Purpose "Dedicated reduced-home localhost input-phase surface checker."),
    (New-ValidationReference -Path "scripts/windows/check_google_homepage_fixture_validation_surface.ps1" -Kind "file" -Purpose "Dedicated saved-homepage fixture surface checker."),
    (New-ValidationReference -Path "scripts/windows/check_google_submit_path_validation_surface.ps1" -Kind "file" -Purpose "Dedicated later-stage submit-path surface checker."),
    (New-ValidationReference -Path "scripts/windows/check_google_submit_timing_validation_surface.ps1" -Kind "file" -Purpose "Dedicated bounded submit-timing surface checker used before trusting the Google-shaped keydown, keypress, and submit-ordering slice."),
    (New-ValidationReference -Path "scripts/windows/check_google_shared_enter_order_validation_surface.ps1" -Kind "file" -Purpose "Shared Enter-order surface checker used by the stricter late-stage stack."),
    (New-ValidationReference -Path "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1" -Kind "file" -Purpose "Dedicated final form-controls Enter-order surface checker."),
    (New-ValidationReference -Path "scripts/windows/check_google_trace_validation_surface.ps1" -Kind "file" -Purpose "Dedicated later trace-handoff surface checker used before trusting reduced-home or live Google trace capture."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_validation_surface.ps1" -Kind "file" -Purpose "General attached-HTML surface checker used by explicit saved-page follow-up."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Google-style attached-HTML surface checker used by Google-style follow-up."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared suite router that should still expose the later Google trace handoff after the bounded issue #3 checkpoints."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_recommended_validation_flow.ps1" -Kind "file" -Purpose "Printed flow helper for the one-command recommended issue #3 runner."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_summary_guide.ps1" -Kind "file" -Purpose "Saved-summary guide helper that points at the earliest failing issue #3 checkpoint."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_manifest.ps1" -Kind "file" -Purpose "Saved-manifest guide helper that exposes the single read-first artifact index for the recommended issue #3 runner."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_phase_boundary.ps1" -Kind "file" -Purpose "Saved-summary helper that points at the last passing and first failing issue #3 checkpoints."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_probe_triage.ps1" -Kind "file" -Purpose "Triage helper that routes issue #3 follow-up toward the sharpest saved probe or phase boundary."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_manual_fixture_replay.ps1" -Kind "file" -Purpose "Saved-fixture replay helper for the manual issue #3 follow-up path."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation.ps1" -Kind "file" -Purpose "One-command recommended issue #3 runner."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Broader issue #3 flow helper."),
    (New-ValidationReference -Path "scripts/windows/show_saved_page_google_validation_flow.ps1" -Kind "file" -Purpose "Saved-page follow-up helper that preserves the same Google-first phase ordering for manual localhost reruns."),
    (New-ValidationReference -Path "scripts/windows/show_google_home_input_phase_validation_flow.ps1" -Kind "file" -Purpose "Dedicated reduced-home localhost input-phase flow helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_title_validation_flow.ps1" -Kind "file" -Purpose "Narrow title-wrapper flow helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_quick_validation_flow.ps1" -Kind "file" -Purpose "Printed quick title-plus-watch helper that the main issue #3 guide now routes through before the reduced homepage pass."),
    (New-ValidationReference -Path "scripts/windows/show_google_title_probe_trace_guide.ps1" -Kind "file" -Purpose "Read-first marker guide for the bounded title probe."),
    (New-ValidationReference -Path "scripts/windows/show_google_homepage_fixture_validation_flow.ps1" -Kind "file" -Purpose "Saved-homepage fixture flow helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_submit_path_validation_flow.ps1" -Kind "file" -Purpose "Later-stage submit-path flow helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_submit_path_trace_guide.ps1" -Kind "file" -Purpose "Trace helper for the later-stage submit-path ladder."),
    (New-ValidationReference -Path "scripts/windows/show_google_submit_timing_validation_flow.ps1" -Kind "file" -Purpose "Submit-timing flow helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_shared_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Shared Enter-order ladder helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Dedicated final form-controls Enter-order flow helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1" -Kind "file" -Purpose "Quick diagnosis helper for the dedicated form-controls Enter-order gate."),
    (New-ValidationReference -Path "scripts/windows/show_google_trace_validation_flow.ps1" -Kind "file" -Purpose "Live Google trace handoff helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-style attached HTML flow helper."),
    (New-ValidationReference -Path "scripts/windows/run_google_input_validation.ps1" -Kind "file" -Purpose "Shared issue #3 phase runner."),
    (New-ValidationReference -Path "scripts/windows/run_google_home_input_phase_validation.ps1" -Kind "file" -Purpose "Dedicated reduced-home localhost input-phase wrapper."),
    (New-ValidationReference -Path "scripts/windows/run_google_title_validation.ps1" -Kind "file" -Purpose "Dedicated reduced title-wrapper runner."),
    (New-ValidationReference -Path "scripts/windows/run_google_quick_validation.ps1" -Kind "file" -Purpose "Dedicated quick title-plus-watch wrapper used by the main issue #3 guide before the reduced homepage pass."),
    (New-ValidationReference -Path "scripts/windows/run_google_home_title_probe.ps1" -Kind "file" -Purpose "Direct PowerShell title probe wrapper used for deeper narrowing inside the recommended title-first path."),
    (New-ValidationReference -Path "scripts/windows/run_google_home_watch_probe.ps1" -Kind "file" -Purpose "Self-starting watch probe wrapper used by the recommended runner."),
    (New-ValidationReference -Path "scripts/windows/run_google_homepage_fixture_validation.ps1" -Kind "file" -Purpose "Bounded saved-homepage fixture runner."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_submit_path_validation.ps1" -Kind "file" -Purpose "One-command later-stage submit-path runner."),
    (New-ValidationReference -Path "scripts/windows/run_google_submit_timing_validation.ps1" -Kind "file" -Purpose "Bounded submit-timing runner."),
    (New-ValidationReference -Path "scripts/windows/run_google_shared_enter_order_validation.ps1" -Kind "file" -Purpose "Shared Enter-order ladder runner."),
    (New-ValidationReference -Path "scripts/windows/run_google_form_controls_enter_order_validation.ps1" -Kind "file" -Purpose "Dedicated final form-controls Enter-order runner."),
    (New-ValidationReference -Path "scripts/windows/run_google_trace_validation.ps1" -Kind "file" -Purpose "One-command later trace-handoff runner for the dedicated live Google follow-up path."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_localhost_validation.ps1" -Kind "file" -Purpose "Attached-HTML localhost runner used for the saved-page follow-up path."),
    (New-ValidationReference -Path "scripts/windows/run_google_attached_html_validation.ps1" -Kind "file" -Purpose "Dedicated Google-style attached-HTML runner used when the current run already has attached snapshots under user_files or agent_files."),
    (New-ValidationReference -Path "scripts/windows/start_localhost_html_validation.ps1" -Kind "file" -Purpose "Direct localhost HTML launcher used by the saved-page manual follow-up documented in the main Windows guide."),
    (New-ValidationReference -Path "scripts/windows/start_staged_localhost_html_validation.ps1" -Kind "file" -Purpose "Saved-page staging helper used by explicit manual follow-up."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1" -Kind "file" -Purpose "Bounded localhost Google-style title probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/GOOGLE_HOME_TITLE_PROBE_TRACE.md" -Kind "file" -Purpose "Read-first marker note for the bounded title probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-style-localhost-probe.ps1" -Kind "file" -Purpose "Baseline Google-style localhost probe used near the start of the recommended runner."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-style-correction-localhost-probe.ps1" -Kind "file" -Purpose "Correction-pass Google-style localhost probe used near the start of the recommended runner."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-style-delayed-ready-localhost-probe.ps1" -Kind "file" -Purpose "Delayed-ready Google-style localhost probe used near the start of the recommended runner."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-home/chrome-google-home-enter-probe.ps1" -Kind "file" -Purpose "Reduced homepage Enter-submit probe on the real headed surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-home/chrome-google-home-keypress-submit-probe.ps1" -Kind "file" -Purpose "Reduced homepage keypress-before-submit probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-enter-order-localhost-probe.ps1" -Kind "file" -Purpose "Reusable localhost Enter-order wrapper used by the recommended stack."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-home-input-phase-localhost-probe.ps1" -Kind "file" -Purpose "Raw reduced-home localhost input-phase probe used by the recommended stack."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-home-enter-trace-probe.ps1" -Kind "file" -Purpose "Reduced-home trace probe used before the live Google homepage capture path."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-home-input-probe.ps1" -Kind "file" -Purpose "Live Google trace probe used after bounded phases stay green."),
    (New-ValidationReference -Path "tmp-browser-smoke/layout-smoke/chrome-google-submit-timing-probe.ps1" -Kind "file" -Purpose "Bounded keydown, keypress, and submit-ordering probe used by the submit-timing slice."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1" -Kind "file" -Purpose "Smallest shared form-controls Enter-order probe used late in the recommended runner."),
    (New-ValidationReference -Path "src/browser/tests/page/google_home_title_probe.html" -Kind "file" -Purpose "Localhost Google-style title fixture used near the front of the recommended runner."),
    (New-ValidationReference -Path "tmp-browser-smoke/manual-user/README.md" -Kind "file" -Purpose "Manual saved-page and attached-page follow-up guide.")
)

$results = foreach ($reference in $references) {
    $fullPath = Join-Path $resolvedRepoRoot $reference.Path
    $exists = if ($reference.Kind -eq "directory") {
        Test-Path -LiteralPath $fullPath -PathType Container
    } else {
        Test-Path -LiteralPath $fullPath -PathType Leaf
    }

    [pscustomobject]@{
        Path = $reference.Path
        Kind = $reference.Kind
        Purpose = $reference.Purpose
        Exists = [bool]$exists
    }
}

$missing = @($results | Where-Object { -not $_.Exists })

if ($Json) {
    [ordered]@{
        profile = "google-issue3-recommended"
        repo_root = $resolvedRepoRoot
        checked_count = @($results).Count
        missing_count = @($missing).Count
        references = @($results)
    } | ConvertTo-Json -Depth 6

    if ($missing.Count -gt 0) {
        exit 1
    }

    exit 0
}

Write-Host "Google issue #3 recommended validation surface check"
Write-Host ""
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
Write-Host ""

foreach ($result in $results) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host ("[{0}] {1}" -f $status, $result.Path)
    Write-Host ("  {0}" -f $result.Purpose)
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Google issue #3 recommended validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} recommended-validation path(s)." -f $missing.Count)
Write-Host "Repair the missing guide, helper, or probe before trusting the one-command issue #3 runner."
exit 1
