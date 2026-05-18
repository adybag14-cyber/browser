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
    (New-ValidationReference -Path "docs/HEADED_ATTACHED_HTML_VALIDATION.md" -Kind "file" -Purpose "Primary attached-HTML validation guide for the current compatibility bundle route."),
    (New-ValidationReference -Path "docs/HEADED_MODE_VALIDATION_GATES.md" -Kind "file" -Purpose "Canonical bounded-suite routing map that keeps the three-page compatibility bundle pinned to the right first gate before broader attached-page replay."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the bundle-aware attached-page helpers."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Bundle-specific reference note that keeps the pinned three-page route, reusable fixed-list proof path, and broader issue #3 re-entry surfaces visible together."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md" -Kind "file" -Purpose "Shortest quickstart bridge from the top-level validation router into the pinned attached HTML target-bundle path."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md" -Kind "file" -Purpose "Read-first proof-entry note that keeps the fixed-list screenshot-and-title proof route discoverable beside the pinned bundle replay path."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Compact suite-level attached HTML target-bundle re-entry note that keeps the broader attached-page and Google-shaped attached-page helpers visible beside the pinned three-page route."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md" -Kind "file" -Purpose "Pinned manual checklist for the known three-page compatibility bundle once the bundled localhost route is green."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Google-shaped attached-page companion note that keeps the narrower issue #3 localhost-first helper chain visible beside the pinned three-page route."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Canonical suite router that exposes the attached-html-target-bundle entry point before the narrower bundle helpers run."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact issue #3 bundle-suite helper that keeps the broader attached-page and Google-shaped attached-page surfaces visible beside the pinned bundle lane."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first issue #3 entrypoint that keeps the replay-side quickstart ladder visible before the route locks onto the pinned bundle branch."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Kind "file" -Purpose "Compact proof-entry helper that keeps the fixed-list screenshot-and-title follow-up pinned to the same bundle inputs after the delegated localhost runner."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Compact issue #3 next-step matrix that the bundle flow uses to carry the same pinned inputs into the narrower branch chooser after localhost replay."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Issue #3 replay-shortcuts helper that keeps the same pinned bundle inputs on the safe-route and replay-route handoff after bundle replay narrows the failure."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_target_bundle.ps1" -Kind "file" -Purpose "Checker for the known three-page attached HTML compatibility target bundle."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1" -Kind "file" -Purpose "Bundle-aware attached HTML flow helper."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Bundle-aware attached HTML localhost runner."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_validation_surface.ps1" -Kind "file" -Purpose "General attached-HTML validation surface checker used by the non-Google route."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Google-style attached-HTML validation surface checker used when the bundle includes the Google page."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_local_asset_closure.ps1" -Kind "file" -Purpose "Deep attached-HTML asset audit for the locked bundle paths."),
    (New-ValidationReference -Path "scripts/windows/check_local_html_fixture_validation_surface.ps1" -Kind "file" -Purpose "Reusable fixed-list local HTML fixture surface checker for the same saved compatibility pages."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "General attached-HTML flow helper referenced by the bundle checker when the bundle is not Google-routed."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_localhost_validation.ps1" -Kind "file" -Purpose "General attached-HTML localhost runner delegated to by the bundle-aware path."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-style attached-HTML flow helper referenced by the bundle checker when the bundle stays on the issue #3 route."),
    (New-ValidationReference -Path "scripts/windows/run_google_attached_html_validation.ps1" -Kind "file" -Purpose "Google-style attached-HTML localhost runner delegated to by the bundle-aware path."),
    (New-ValidationReference -Path "tmp-browser-smoke/local-html-fixtures/chrome-local-html-fixture-probe.ps1" -Kind "file" -Purpose "Reusable fixed-list screenshot-and-title probe for the same saved compatibility pages.")
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
        profile = "attached-html-target-bundle"
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

Write-Host "Attached HTML target-bundle validation surface check"
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
    Write-Host "Attached HTML target-bundle validation surface is intact, including the bundle reference note, the bundle quickstart, the proof-entry note, the compact bundle suite-surface note and helper, the bundle-first helper, the bundle proof entrypoint, the Google attached-page companion note, the issue #3 next-step matrix and replay-shortcuts follow-up helpers, the pinned manual checklist, and the reusable local fixture probe."
    exit 0
}

Write-Host ("Missing {0} attached HTML target-bundle validation path(s)." -f $missing.Count)
Write-Host "Repair the missing guide, reference note, quickstart, proof-entry note, compact suite-surface note or helper, bundle-first helper, bundle proof entrypoint, Google attached-page companion note, issue #3 next-step or replay-shortcuts helper, checklist, reusable fixture probe surface, or delegated attached-HTML validation path before trusting the bundle-pinned localhost route."
exit 1