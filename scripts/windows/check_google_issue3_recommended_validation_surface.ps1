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
    (New-ValidationReference -Path "docs/GOOGLE_INPUT_VALIDATION.md" -Kind "file" -Purpose "Reduced Google Enter-order validation note."),
    (New-ValidationReference -Path "docs/GOOGLE_HOME_INPUT_PHASE_LOCALHOST_VALIDATION.md" -Kind "file" -Purpose "Dedicated reduced-home localhost input-phase note."),
    (New-ValidationReference -Path "docs/GOOGLE_SUBMIT_PATH_VALIDATION.md" -Kind "file" -Purpose "Later-stage submit-path note used by the recommended runner."),
    (New-ValidationReference -Path "docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Shared Enter-order note used by the recommended runner."),
    (New-ValidationReference -Path "docs/HEADED_ATTACHED_HTML_VALIDATION.md" -Kind "file" -Purpose "Attached HTML handoff guide used by the recommended runner."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the recommended issue #3 stack."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper layer for issue #3 validation scripts."),
    (New-ValidationReference -Path "scripts/windows/check_headed_validation_surface.ps1" -Kind "file" -Purpose "General headed validation surface checker."),
    (New-ValidationReference -Path "scripts/windows/check_google_validation_surface.ps1" -Kind "file" -Purpose "Compatibility wrapper for the Google validation surface checker."),
    (New-ValidationReference -Path "scripts/windows/check_google_home_input_phase_validation_surface.ps1" -Kind "file" -Purpose "Dedicated reduced-home localhost input-phase surface checker."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_recommended_validation_flow.ps1" -Kind "file" -Purpose "Printed flow helper for the one-command recommended issue #3 runner."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation.ps1" -Kind "file" -Purpose "One-command recommended issue #3 runner."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Broader issue #3 flow helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_home_input_phase_validation_flow.ps1" -Kind "file" -Purpose "Dedicated reduced-home localhost input-phase flow helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_title_validation_flow.ps1" -Kind "file" -Purpose "Narrow title-wrapper flow helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_homepage_fixture_validation_flow.ps1" -Kind "file" -Purpose "Saved-homepage fixture flow helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_submit_timing_validation_flow.ps1" -Kind "file" -Purpose "Submit-timing flow helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_shared_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Shared Enter-order ladder helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_trace_validation_flow.ps1" -Kind "file" -Purpose "Live Google trace handoff helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-style attached HTML flow helper."),
    (New-ValidationReference -Path "scripts/windows/run_google_input_validation.ps1" -Kind "file" -Purpose "Shared issue #3 phase runner."),
    (New-ValidationReference -Path "scripts/windows/run_google_home_input_phase_validation.ps1" -Kind "file" -Purpose "Dedicated reduced-home localhost input-phase wrapper."),
    (New-ValidationReference -Path "scripts/windows/run_google_title_validation.ps1" -Kind "file" -Purpose "Dedicated reduced title-wrapper runner."),
    (New-ValidationReference -Path "scripts/windows/run_google_homepage_fixture_validation.ps1" -Kind "file" -Purpose "Bounded saved-homepage fixture runner."),
    (New-ValidationReference -Path "scripts/windows/run_google_submit_timing_validation.ps1" -Kind "file" -Purpose "Bounded submit-timing runner."),
    (New-ValidationReference -Path "scripts/windows/run_google_shared_enter_order_validation.ps1" -Kind "file" -Purpose "Shared Enter-order ladder runner."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1" -Kind "file" -Purpose "Bounded localhost Google-style title probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-home/chrome-google-home-keypress-submit-probe.ps1" -Kind "file" -Purpose "Reduced homepage keypress-before-submit probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-enter-order-localhost-probe.ps1" -Kind "file" -Purpose "Reusable localhost Enter-order wrapper used by the recommended stack."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-home-input-phase-localhost-probe.ps1" -Kind "file" -Purpose "Raw reduced-home localhost input-phase probe used by the recommended stack."),
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
