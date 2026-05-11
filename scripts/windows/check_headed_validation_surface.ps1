[CmdletBinding()]
param(
    [ValidateSet("routing", "issue3", "attached-html", "linux-offline", "release-gates", "all")]
    [string]$Profile = "routing",
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

$profiles = @{
    "routing" = @(
        (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Primary Windows headed runbook."),
        (New-ValidationReference -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Kind "file" -Purpose "Execution-order guide for headed-mode delivery."),
        (New-ValidationReference -Path "docs/HEADED_MODE_VALIDATION_GATES.md" -Kind "file" -Purpose "Canonical headed validation gate matrix."),
        (New-ValidationReference -Path "tmp-browser-smoke/README.md" -Kind "file" -Purpose "Directory-level index for the headed probe suites."),
        (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared suite router for subsystem-to-probe mapping."),
        (New-ValidationReference -Path "scripts/windows/check_headed_validation_surface.ps1" -Kind "file" -Purpose "General headed validation surface checker."),
        (New-ValidationReference -Path "scripts/windows/run_localhost_html_validation_recommended.ps1" -Kind "file" -Purpose "One-command localhost follow-up router for saved or attached HTML."),
        (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Printed attached-HTML follow-up flow."),
        (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Printed Google-style attached-HTML follow-up flow.")
    )
    "issue3" = @(
        (New-ValidationReference -Path "docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md" -Kind "file" -Purpose "Main issue #3 validation guide."),
        (New-ValidationReference -Path "docs/HEADED_GOOGLE_SUITE_VALIDATION_WINDOWS.md" -Kind "file" -Purpose "Compact read-first issue #3 guide."),
        (New-ValidationReference -Path "docs/GOOGLE_INPUT_VALIDATION.md" -Kind "file" -Purpose "Reduced Google Enter-order validation note."),
        (New-ValidationReference -Path "docs/GOOGLE_SUBMIT_PATH_VALIDATION.md" -Kind "file" -Purpose "Dedicated later-stage submit-path note for the saved-homepage-fixture, submit-timing, and shared Enter-order slice."),
        (New-ValidationReference -Path "docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Shared Enter-order note for the Google path."),
        (New-ValidationReference -Path "docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Smallest shared form-controls Enter-order note for the Google path."),
        (New-ValidationReference -Path "docs/HEADED_ATTACHED_HTML_VALIDATION.md" -Kind "file" -Purpose "Attached HTML handoff guide used by the Google validation path."),
        (New-ValidationReference -Path "docs/HEADED_MODE_VALIDATION_GATES.md" -Kind "file" -Purpose "Shared validation gate matrix."),
        (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Primary Windows headed runbook."),
        (New-ValidationReference -Path "tmp-browser-smoke/README.md" -Kind "file" -Purpose "Probe suite index surfaced by the Windows docs."),
        (New-ValidationReference -Path "tmp-browser-smoke/manual-user/README.md" -Kind "file" -Purpose "Manual saved-page and attached-page follow-up guide."),
        (New-ValidationReference -Path "tmp-browser-smoke/form-controls/README.md" -Kind "file" -Purpose "Directory-level index for the shared form-controls probes."),
        (New-ValidationReference -Path "tmp-browser-smoke/form-controls/form_server.py" -Kind "file" -Purpose "Localhost helper for shared Enter-submit probes."),
        (New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "Shared headed Enter-submit probe."),
        (New-ValidationReference -Path "tmp-browser-smoke/form-controls/deferred-enter-submit-probe.ps1" -Kind "file" -Purpose "Shared deferred Enter-submit probe."),
        (New-ValidationReference -Path "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1" -Kind "file" -Purpose "Reduced Google Enter-order headed probe."),
        (New-ValidationReference -Path "tmp-browser-smoke/form-controls/chrome-google-enter-order-probe.ps1" -Kind "file" -Purpose "Chrome-prefixed reduced Google Enter-order headed probe."),
        (New-ValidationReference -Path "tmp-browser-smoke/layout-smoke/chrome-google-submit-timing-probe.ps1" -Kind "file" -Purpose "Bounded Google submit-timing probe."),
        (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper layer for the validation flows."),
        (New-ValidationReference -Path "scripts/windows/check_headed_validation_surface.ps1" -Kind "file" -Purpose "General headed validation surface checker."),
        (New-ValidationReference -Path "scripts/windows/check_google_validation_surface.ps1" -Kind "file" -Purpose "Compatibility wrapper for the Google validation surface checker."),
        (New-ValidationReference -Path "scripts/windows/check_google_issue3_recommended_validation_surface.ps1" -Kind "file" -Purpose "Dedicated surface checker for the one-command issue #3 runner."),
        (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared suite router."),
        (New-ValidationReference -Path "scripts/windows/show_google_suite_validation_flow.ps1" -Kind "file" -Purpose "Compact issue #3 read-first helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Stepwise issue #3 flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_quick_validation_flow.ps1" -Kind "file" -Purpose "Fast title-plus-watch flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_title_probe_trace_guide.ps1" -Kind "file" -Purpose "Bounded title-marker interpretation helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_title_validation_flow.ps1" -Kind "file" -Purpose "Narrow title-wrapper flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_homepage_fixture_validation_flow.ps1" -Kind "file" -Purpose "Saved-homepage fixture flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_submit_path_validation_flow.ps1" -Kind "file" -Purpose "Dedicated read-first helper for the later issue #3 submit-path ladder."),
        (New-ValidationReference -Path "scripts/windows/show_google_submit_timing_validation_flow.ps1" -Kind "file" -Purpose "Submit-timing flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_shared_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Shared Enter-order ladder helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_trace_validation_flow.ps1" -Kind "file" -Purpose "Live Google trace handoff helper."),
        (New-ValidationReference -Path "scripts/windows/show_form_controls_validation_flow.ps1" -Kind "file" -Purpose "Read-first helper for the shared form-controls baseline ladder."),
        (New-ValidationReference -Path "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Dedicated shared form-controls Enter-order helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-style attached HTML flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_saved_page_google_validation_flow.ps1" -Kind "file" -Purpose "Saved-page Google follow-up flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_issue3_recommended_validation_flow.ps1" -Kind "file" -Purpose "Printed flow helper for the one-command recommended issue #3 runner."),
        (New-ValidationReference -Path "scripts/windows/run_form_controls_validation.ps1" -Kind "file" -Purpose "Shared form-controls runner for the headed input baseline."),
        (New-ValidationReference -Path "scripts/windows/run_form_controls_validation_recommended.ps1" -Kind "file" -Purpose "One-command shared form-controls validation runner."),
        (New-ValidationReference -Path "scripts/windows/run_google_form_controls_enter_order_validation.ps1" -Kind "file" -Purpose "Dedicated shared form-controls Enter-order runner."),
        (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation.ps1" -Kind "file" -Purpose "One-command issue #3 validation runner."),
        (New-ValidationReference -Path "scripts/windows/run_google_issue3_submit_path_validation.ps1" -Kind "file" -Purpose "Later-stage issue #3 submit-path runner."),
        (New-ValidationReference -Path "scripts/windows/run_google_quick_validation.ps1" -Kind "file" -Purpose "Fast issue #3 title-plus-watch runner."),
        (New-ValidationReference -Path "scripts/windows/run_google_title_validation.ps1" -Kind "file" -Purpose "Dedicated reduced title-wrapper runner."),
        (New-ValidationReference -Path "scripts/windows/run_google_home_title_probe.ps1" -Kind "file" -Purpose "Reduced Google-home title marker probe."),
        (New-ValidationReference -Path "scripts/windows/run_google_home_validation.ps1" -Kind "file" -Purpose "Reduced Google-home submit runner."),
        (New-ValidationReference -Path "scripts/windows/run_google_homepage_fixture_validation.ps1" -Kind "file" -Purpose "Bounded saved-homepage fixture runner."),
        (New-ValidationReference -Path "scripts/windows/run_google_submit_timing_validation.ps1" -Kind "file" -Purpose "Bounded Google submit-timing runner."),
        (New-ValidationReference -Path "scripts/windows/run_google_shared_enter_order_validation.ps1" -Kind "file" -Purpose "Shared Enter-order ladder runner."),
        (New-ValidationReference -Path "scripts/windows/run_google_attached_html_validation.ps1" -Kind "file" -Purpose "Google attached-HTML runner."),
        (New-ValidationReference -Path "scripts/windows/run_localhost_html_validation_recommended.ps1" -Kind "file" -Purpose "Shared localhost validation router used by the Google follow-up."),
        (New-ValidationReference -Path "scripts/windows/start_localhost_html_validation.ps1" -Kind "file" -Purpose "Direct directory-backed localhost launcher for saved-page follow-up."),
        (New-ValidationReference -Path "scripts/windows/start_staged_localhost_html_validation.ps1" -Kind "file" -Purpose "Staged multi-input localhost launcher for saved-page follow-up.")
    )
    "attached-html" = @(
        (New-ValidationReference -Path "docs/HEADED_ATTACHED_HTML_VALIDATION.md" -Kind "file" -Purpose "Attached HTML validation guide."),
        (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook."),
        (New-ValidationReference -Path "docs/HEADED_MODE_VALIDATION_GATES.md" -Kind "file" -Purpose "Shared validation gate matrix."),
        (New-ValidationReference -Path "tmp-browser-smoke/README.md" -Kind "file" -Purpose "Top-level probe suite index."),
        (New-ValidationReference -Path "tmp-browser-smoke/manual-user/README.md" -Kind "file" -Purpose "Manual saved-page and attached-page follow-up guide."),
        (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper layer for attached HTML validation scripts."),
        (New-ValidationReference -Path "scripts/windows/check_headed_validation_surface.ps1" -Kind "file" -Purpose "General headed validation surface checker."),
        (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared suite router."),
        (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "General attached HTML flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-style attached HTML flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_saved_page_google_validation_flow.ps1" -Kind "file" -Purpose "Saved-page Google follow-up flow helper."),
        (New-ValidationReference -Path "scripts/windows/run_localhost_html_validation_recommended.ps1" -Kind "file" -Purpose "One-command attached or saved-page localhost router."),
        (New-ValidationReference -Path "scripts/windows/run_attached_html_localhost_validation.ps1" -Kind "file" -Purpose "General attached HTML localhost runner."),
        (New-ValidationReference -Path "scripts/windows/run_google_attached_html_validation.ps1" -Kind "file" -Purpose "Google-style attached HTML localhost runner."),
        (New-ValidationReference -Path "scripts/windows/run_saved_page_localhost_validation.ps1" -Kind "file" -Purpose "Saved-page localhost runner.")
    )
    "linux-offline" = @(
        (New-ValidationReference -Path "docs/LINUX_OFFLINE_BUILD_RECOVERY.md" -Kind "file" -Purpose "Linux offline build recovery guide."),
        (New-ValidationReference -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Kind "file" -Purpose "Execution-order guide that points to the Linux restore routine."),
        (New-ValidationReference -Path "scripts/linux/prepare_offline_build_inputs.sh" -Kind "file" -Purpose "Archive-parameterized offline restore helper."),
        (New-ValidationReference -Path "scripts/linux/restore_offline_build_inputs.sh" -Kind "file" -Purpose "Default Memory-path offline restore helper."),
        (New-ValidationReference -Path "scripts/linux/check_offline_build_prereqs.sh" -Kind "file" -Purpose "Offline build preflight checker.")
    )
    "release-gates" = @(
        (New-ValidationReference -Path "docs/HEADED_MODE_VALIDATION_GATES.md" -Kind "file" -Purpose "Canonical headed validation gate matrix."),
        (New-ValidationReference -Path "tmp-browser-smoke/README.md" -Kind "file" -Purpose "Probe suite index for release-gate routing."),
        (New-ValidationReference -Path "tmp-browser-smoke/tabs" -Kind "directory" -Purpose "Shell and navigation gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/browser-pages" -Kind "directory" -Purpose "Shell and browser-pages gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/settings" -Kind "directory" -Purpose "Settings gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/wrapped-link" -Kind "directory" -Purpose "Wrapped-link gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/popup" -Kind "directory" -Purpose "Popup gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/layout-smoke" -Kind "directory" -Purpose "Layout gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/inline-flow" -Kind "directory" -Purpose "Inline-flow gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/flow-layout" -Kind "directory" -Purpose "Flow-layout gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/rendered-link-dom" -Kind "directory" -Purpose "Rendered-link DOM gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/form-controls" -Kind "directory" -Purpose "Form-controls gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/font-render" -Kind "directory" -Purpose "Font-render gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/image-smoke" -Kind "directory" -Purpose "Image-smoke gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/stylesheet-smoke" -Kind "directory" -Purpose "Stylesheet-smoke gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/canvas-smoke" -Kind "directory" -Purpose "Canvas gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/downloads" -Kind "directory" -Purpose "Downloads gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/attachment-downloads" -Kind "directory" -Purpose "Attachment-downloads gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/cookie-persistence" -Kind "directory" -Purpose "Cookie persistence gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/localstorage-persistence" -Kind "directory" -Purpose "localStorage persistence gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/indexeddb-persistence" -Kind "directory" -Purpose "IndexedDB persistence gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/sessionstorage-scope" -Kind "directory" -Purpose "sessionStorage scope gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/fetch-abort" -Kind "directory" -Purpose "Fetch-abort gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/fetch-credentials" -Kind "directory" -Purpose "Fetch-credentials gate."),
        (New-ValidationReference -Path "tmp-browser-smoke/websocket-smoke" -Kind "directory" -Purpose "WebSocket gate.")
    )
}

$selectedReferences = switch ($Profile) {
    "all" {
        @(
            $profiles.Values |
                ForEach-Object { $_ } |
                Sort-Object -Property Path -Unique
        )
    }
    default {
        @(
            $profiles[$Profile] |
                Sort-Object -Property Path -Unique
        )
    }
}

$results = foreach ($reference in $selectedReferences) {
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
        profile = $Profile
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

Write-Host "Headed validation surface check"
Write-Host ""
Write-Host ("Profile: {0}" -f $Profile)
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
Write-Host ""

foreach ($result in $results) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host ("[{0}] {1}" -f $status, $result.Path)
    Write-Host ("  {0}" -f $result.Purpose)
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Validation surface is intact for this profile."
    exit 0
}

Write-Host ("Missing {0} validation path(s)." -f $missing.Count)
Write-Host "Repair the missing guide, helper, or suite before trusting the broader headed validation flow."
exit 1