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
    (New-ValidationReference -Path "docs/HEADED_ATTACHED_HTML_VALIDATION.md" -Kind "file" -Purpose "Primary attached-HTML validation guide."),
    (New-ValidationReference -Path "docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md" -Kind "file" -Purpose "Issue #3 guide that routes into the Google-style attached-HTML follow-up."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md" -Kind "file" -Purpose "Issue #3 attached-html change-area quickstart that keeps the broader attached-page branch visible before the top-level helper narrows replay further."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Issue #3 top-level attached-html quickstart that keeps the dedicated Google-shaped follow-up and the shorter attached-page branch visible beside the broader top-level route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md" -Kind "file" -Purpose "Top-level shortcut-first note that keeps the shorter attached-page branch visible beside the broader top-level route before replay narrows further."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Top-level shortcut bridge note that preserves the written handoff from the broader attached-page route into the shorter shortcut helper family."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Shortest Windows replay note kept nearby by the issue-specific Google attached-html entrypoint."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Suite-router shortcut bridge note that preserves the written handoff from the issue-specific Google attached-html route into the shorter helper family."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog guide that remains visible beside the narrower issue-specific attached-page route."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint note validated by this checker."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached-html validation-flow note kept visible from the issue-specific entrypoint."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain note that remains available after the issue-specific attached-page route widens again."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that lists the attached-HTML helper chain."),
    (New-ValidationReference -Path "tmp-browser-smoke/README.md" -Kind "file" -Purpose "Top-level probe-suite index for bounded headed validation."),
    (New-ValidationReference -Path "tmp-browser-smoke/manual-user/README.md" -Kind "file" -Purpose "Manual saved-page and attached-page follow-up guide."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose attached-html change areas feed the issue-specific Google attached-page route."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "General attached-HTML flow helper."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_localhost_validation.ps1" -Kind "file" -Purpose "General attached-HTML localhost runner."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_local_asset_closure.ps1" -Kind "file" -Purpose "Deep attached-HTML asset audit that catches missing nested CSS, image, and font dependencies before launch."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Broader Google attached-html fail-fast checker that remains visible from the issue-specific entrypoint."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-style attached-HTML flow helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Issue #3 attached-html change-area helper that bridges the broader attached-page branch into the narrower Google-shaped follow-up."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Issue #3 top-level attached-html helper that keeps the compact attached-page route aligned before replay narrows into catalog and shortcut helpers."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut-first helper that keeps the shorter attached-page branch visible before replay drops into the suite-router shortcut helper family."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Suite-router shortcut-first helper surfaced as the default next step from the issue-specific Google attached-html entrypoint."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Replay-shortcuts helper surfaced after the issue-specific attached-page route confirms replay stays inside issue #3."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper surfaced when repo root, summary, or pinned bundle inputs already matter."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Compact next-step matrix surfaced from the issue-specific attached-page route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Suite-catalog guide helper that remains visible from the issue-specific attached-page route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Kind "file" -Purpose "Suite-router handoff helper kept available from the issue-specific attached-page route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Replay-route helper surfaced from the issue-specific attached-page route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Pinned three-page compatibility bundle helper surfaced when the issue-specific route should stay on the known attached-page bundle."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Safe-route helper map that remains available after the issue-specific attached-page route narrows far enough."),
    (New-ValidationReference -Path "scripts/windows/run_google_attached_html_validation.ps1" -Kind "file" -Purpose "Google-style attached-HTML localhost runner."),
    (New-ValidationReference -Path "scripts/windows/run_localhost_html_validation_recommended.ps1" -Kind "file" -Purpose "Shared localhost validation router used by the attached-HTML helpers."),
    (New-ValidationReference -Path "scripts/windows/show_saved_page_google_validation_flow.ps1" -Kind "file" -Purpose "Saved-page Google follow-up flow helper used by the Google-style attached-HTML chain."),
    (New-ValidationReference -Path "scripts/windows/run_saved_page_localhost_validation.ps1" -Kind "file" -Purpose "Saved-page localhost runner used when the follow-up moves out of auto-discovered attachments.")
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
        profile = "google-issue3-google-attached-html-entrypoint"
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

Write-Host "Google issue #3 attached HTML entrypoint surface check"
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
    Write-Host "Google issue #3 attached HTML entrypoint surface is intact."
    exit 0
}

Write-Host (("Missing {0} issue-specific Google attached HTML entrypoint path(s).") -f $missing.Count)
Write-Host "Repair the missing issue-specific note, Google attached-page helper, shortcut bridge, bundle-aware fallback, or replay companion before trusting this narrower issue #3 attached-page route."
exit 1
