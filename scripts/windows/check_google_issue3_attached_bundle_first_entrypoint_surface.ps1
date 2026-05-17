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
    (New-ValidationReference -Path "docs/HEADED_ATTACHED_HTML_VALIDATION.md" -Kind "file" -Purpose "Primary attached-HTML validation guide for the broader compatibility route that feeds the pinned issue #3 bundle lane."),
    (New-ValidationReference -Path "docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md" -Kind "file" -Purpose "Issue #3 Google validation guide that keeps the Google-shaped attached-page route visible before replay stays pinned to the compatibility bundle."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Shortest Windows replay note kept nearby before the bundle-first helper locks onto the pinned three-page route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-html quickstart that re-enters the bundle-first helper from the broader Windows replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html quickstart that stays visible before the replay drops from the broader attached-page ladder into the pinned bundle route."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md" -Kind "file" -Purpose "Issue #3 attached-html shortcut note that preserves the shorter attached-page bridge before replay narrows into the bundle-only branch."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google-shaped attached-page flow note that stays visible when the pinned bundle still includes the Google page."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned three-page compatibility bundle reference note used by the bundle-first helper."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md" -Kind "file" -Purpose "Shortest quickstart note for the attached-html target-bundle route."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md" -Kind "file" -Purpose "Pinned manual checklist for the known three-page compatibility bundle after localhost replay turns green."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain note kept nearby after the bundle replay narrows the next failure."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the issue #3 attached-page and target-bundle helpers."),
    (New-ValidationReference -Path "tmp-browser-smoke/README.md" -Kind "file" -Purpose "Top-level probe-suite index for bounded headed validation."),
    (New-ValidationReference -Path "tmp-browser-smoke/manual-user/README.md" -Kind "file" -Purpose "Manual saved-page and attached-page follow-up guide for bundle-driven localhost replay."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router that exposes the broader attached-html, Google attached-html, and target-bundle change areas."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-html quickstart helper surfaced before replay commits to the pinned bundle route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html quickstart helper kept visible before the pinned bundle branch takes over."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Issue #3 attached-html shortcut helper that keeps explicit bundle inputs preserved before replay narrows into the bundle-only branch."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-html flow helper reprinted beside the replay-side and top-level quickstarts before the pinned bundle route."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-shaped attached-html flow helper reprinted when the pinned bundle still includes the Google page."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_target_bundle_validation_surface.ps1" -Kind "file" -Purpose "Generic attached-html target-bundle surface checker that the issue-specific entrypoint keeps nearby."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_target_bundle.ps1" -Kind "file" -Purpose "Checker that revalidates the pinned three-page compatibility bundle before the delegated localhost runner."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific attached-bundle-first helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1" -Kind "file" -Purpose "Bundle-aware attached-html flow helper used after the issue-specific entrypoint surface is confirmed."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Bundle-aware localhost runner used by the pinned three-page compatibility route."),
    (New-ValidationReference -Path "scripts/windows/check_local_html_fixture_validation_surface.ps1" -Kind "file" -Purpose "Reusable fixed-list local HTML fixture surface checker reopened after the bundle replay turns green."),
    (New-ValidationReference -Path "tmp-browser-smoke/local-html-fixtures/chrome-local-html-fixture-probe.ps1" -Kind "file" -Purpose "Reusable fixed-list screenshot-and-title proof path used after the bundle replay."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Issue #3 replay-shortcuts helper that keeps the broader discovery bridge visible after the bundle replay."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Safe-route helper map reopened only after the bundle replay or the fixed-list proof path narrows the next failure.")
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
        profile = "google-issue3-attached-bundle-first-entrypoint"
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

Write-Host "Google issue #3 attached bundle first entrypoint surface check"
Write-Host ""
Write-Host (("Repo root: {0}") -f $resolvedRepoRoot)
Write-Host ""

foreach ($result in $results) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host (("[{0}] {1}") -f $status, $result.Path)
    Write-Host (("  {0}") -f $result.Purpose)
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Google issue #3 attached bundle first entrypoint surface is intact."
    exit 0
}

Write-Host (("Missing {0} issue-specific attached bundle first entrypoint path(s).") -f $missing.Count)
Write-Host "Repair the missing replay-side quickstart, top-level quickstart, attached-page shortcut, broader attached-page flow helper, Google-shaped attached-page flow guide, pinned bundle checker or runner, reusable fixed-list proof path, or safe-route follow-up before trusting this narrower issue #3 bundle-first route."
exit 1
