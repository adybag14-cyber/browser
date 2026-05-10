[CmdletBinding()]
param(
    [ValidateSet("issue3", "attached-html", "all")]
    [string]$Profile = "issue3",
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
    "issue3" = @(
        (New-ValidationReference -Path "docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md" -Kind "file" -Purpose "Main issue #3 validation guide."),
        (New-ValidationReference -Path "docs/HEADED_GOOGLE_SUITE_VALIDATION_WINDOWS.md" -Kind "file" -Purpose "Compact read-first issue #3 guide."),
        (New-ValidationReference -Path "docs/HEADED_ATTACHED_HTML_VALIDATION.md" -Kind "file" -Purpose "Attached HTML handoff guide used by the Google validation path."),
        (New-ValidationReference -Path "docs/HEADED_MODE_VALIDATION_GATES.md" -Kind "file" -Purpose "Shared headed validation gate matrix."),
        (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Primary Windows headed runbook."),
        (New-ValidationReference -Path "tmp-browser-smoke/README.md" -Kind "file" -Purpose "Probe suite index surfaced by the Windows docs."),
        (New-ValidationReference -Path "tmp-browser-smoke/manual-user/README.md" -Kind "file" -Purpose "Manual saved-page and attached-page follow-up guide."),
        (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper layer for attached and Google validation scripts."),
        (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared suite router."),
        (New-ValidationReference -Path "scripts/windows/show_google_suite_validation_flow.ps1" -Kind "file" -Purpose "Compact issue #3 read-first helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Stepwise issue #3 validation flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_title_probe_trace_guide.ps1" -Kind "file" -Purpose "Bounded title-marker interpretation helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_title_validation_flow.ps1" -Kind "file" -Purpose "Narrow title wrapper flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_homepage_fixture_validation_flow.ps1" -Kind "file" -Purpose "Bounded saved-homepage fixture flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_submit_timing_validation_flow.ps1" -Kind "file" -Purpose "Bounded Google-shaped submit-timing flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_shared_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Shared Enter-order ladder flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Narrow shared form-controls Enter-order flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-style attached HTML flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_saved_page_google_validation_flow.ps1" -Kind "file" -Purpose "Saved-page Google follow-up flow helper."),
        (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation.ps1" -Kind "file" -Purpose "One-command issue #3 validation runner."),
        (New-ValidationReference -Path "scripts/windows/run_google_attached_html_validation.ps1" -Kind "file" -Purpose "One-command Google attached HTML runner."),
        (New-ValidationReference -Path "scripts/windows/run_localhost_html_validation_recommended.ps1" -Kind "file" -Purpose "Shared localhost validation router used by the Google follow-up."),
        (New-ValidationReference -Path "scripts/windows/run_attached_html_localhost_validation.ps1" -Kind "file" -Purpose "General attached HTML localhost runner."),
        (New-ValidationReference -Path "scripts/windows/run_saved_page_localhost_validation.ps1" -Kind "file" -Purpose "Saved-page localhost runner used underneath the Google flow.")
    )
    "attached-html" = @(
        (New-ValidationReference -Path "docs/HEADED_ATTACHED_HTML_VALIDATION.md" -Kind "file" -Purpose "Attached HTML validation guide."),
        (New-ValidationReference -Path "tmp-browser-smoke/README.md" -Kind "file" -Purpose "Top-level probe suite index."),
        (New-ValidationReference -Path "tmp-browser-smoke/manual-user/README.md" -Kind "file" -Purpose "Manual saved-page and attached-page follow-up guide."),
        (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper layer for attached HTML validation scripts."),
        (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared suite router."),
        (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "General attached HTML flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-style attached HTML flow helper."),
        (New-ValidationReference -Path "scripts/windows/show_saved_page_google_validation_flow.ps1" -Kind "file" -Purpose "Saved-page Google follow-up flow helper."),
        (New-ValidationReference -Path "scripts/windows/run_localhost_html_validation_recommended.ps1" -Kind "file" -Purpose "One-command attached or saved-page localhost router."),
        (New-ValidationReference -Path "scripts/windows/run_attached_html_localhost_validation.ps1" -Kind "file" -Purpose "General attached HTML localhost runner."),
        (New-ValidationReference -Path "scripts/windows/run_google_attached_html_validation.ps1" -Kind "file" -Purpose "Google-style attached HTML localhost runner."),
        (New-ValidationReference -Path "scripts/windows/run_saved_page_localhost_validation.ps1" -Kind "file" -Purpose "Saved-page localhost runner.")
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

Write-Host "Google headed validation surface check"
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
Write-Host "Repair the missing guide or helper before trusting the broader issue #3 flow."
exit 1
