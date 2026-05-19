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
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Primary issue #3 suite-catalog guide that should stay aligned with the compact attached-html helper map."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Broader Windows runbook that can reopen the suite-catalog route before attached-html follow-up narrows again."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Windows full-use attached-html route note reused by the suite-catalog bridge when replay re-enters from the broader Windows surface."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Windows-to-validation-router bridge note used by the suite-catalog route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Windows-side catalog quickstart note surfaced by the suite-catalog route before it narrows back into replay-side attached-html helpers."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-html quickstart note used by the suite-catalog ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Validation-router attached-html quickstart note kept visible from the suite-catalog route."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md" -Kind "file" -Purpose "Attached-html change-area quickstart note surfaced before the route narrows further."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_CONTEXT_SURFACE.md" -Kind "file" -Purpose "Attached-html context-surface note that keeps the broader attached-page lane, the Google-shaped lane, and the pinned bundle lane visible together from the suite-catalog route."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached-html flow guide that the suite-catalog route now keeps visible before replay narrows into the shorter attached-page helpers."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint note that the suite-catalog surface should keep available beside the dedicated Google attached-page flow."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Suite-catalog-to-top-level attached-html catalog quickstart note used by the suite-catalog helper chain."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-html bridge note reopened before the route collapses into shortcuts."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-html quickstart note kept nearby when the route widens back toward the suite-router surface."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_HANDOFF.md" -Kind "file" -Purpose "Written suite-router handoff note that should stay aligned with the wider compact route the suite-catalog helper can reopen before replay-route follow-up."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Compact top-level attached-html quickstart note used by the suite-catalog route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html catalog quickstart note surfaced from the suite-catalog route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Broader top-level attached-html bridge note reused by the suite-catalog helper chain."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Replay-side quickstart note that can still feed back into the suite-catalog route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Longer Windows validation-chain note kept aligned with the suite-catalog entry surface."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Replay-route shortcut note that the suite-catalog guide reopens before the route narrows into bundle-side follow-up."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Compact bundle-side helper note that the suite-catalog route keeps visible before the pinned bundle branch takes over."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md" -Kind "file" -Purpose "Pinned bundle proof note that the suite-catalog route keeps visible after the delegated bundle runner turns green."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md" -Kind "file" -Purpose "Replay-route bundle-first bridge note that should stay available once the suite-catalog route narrows toward the pinned three-page compatibility bundle."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level suite router whose change-area commands feed the issue #3 suite-catalog bridge."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the issue #3 suite-catalog helper surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Suite-catalog helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Replay-side attached-html surface checker referenced by the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1" -Kind "file" -Purpose "Windows full-use attached-html route checker referenced by the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Dedicated Google attached-html surface checker that should fail fast before the suite-catalog route depends on that narrower helper chain."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_local_asset_closure.ps1" -Kind "file" -Purpose "Deep attached-html asset audit reused by the dedicated Google attached-html helper chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1" -Kind "file" -Purpose "Broader Windows full-use attached-html route helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1" -Kind "file" -Purpose "Windows-to-validation-router bridge helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Windows-side attached-html catalog quickstart helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-html quickstart helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Validation-router attached-html quickstart helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Attached-html change-area quickstart helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_context_surface.ps1" -Kind "file" -Purpose "Dedicated attached-html context-surface helper surfaced from the suite-catalog chain when replay context already matters."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Dedicated Google attached-html flow helper that the suite-catalog route keeps visible before replay narrows into shorter attached-page helpers."),
    (New-ValidationReference -Path "scripts/windows/run_google_attached_html_validation.ps1" -Kind "file" -Purpose "Dedicated Google attached-html runner paired with the narrower helper chain surfaced by the suite-catalog route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Suite-catalog-to-top-level attached-html catalog quickstart helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Suite-catalog attached-html bridge helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_quickstart.ps1" -Kind "file" -Purpose "Compact suite-router bridge helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-html quickstart helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_suite_router_handoff_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the wider suite-router handoff surface that the suite-catalog route can reopen before replay-route follow-up."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Kind "file" -Purpose "Suite-router handoff helper surfaced from the suite-catalog chain before replay-route and safe-route follow-up."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Compact top-level attached-html quickstart helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html catalog quickstart helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut-first helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Broader top-level attached-html bridge helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Google localhost-first flow helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html bridge surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Shortest attached-html shortcut helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Replay-route shortcut helper that the suite-catalog guide uses before the route narrows into bundle-side follow-up or the tighter replay shortcut chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Executable next-step matrix helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper surfaced when the suite-catalog route already has a pinned repo root, summary, or bundle path."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Kind "file" -Purpose "Suite-router handoff helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Replay-route helper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact attached bundle suite surface helper surfaced by the suite-catalog route before bundle-first follow-up."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_target_bundle_validation_surface.ps1" -Kind "file" -Purpose "Bundle-side fail-fast surface checker that should stay available once the suite-catalog route narrows to the pinned three-page compatibility bundle."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1" -Kind "file" -Purpose "Pinned bundle validation-flow helper that the suite-catalog route keeps available before the bundle-first helper or delegated runner takes over."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_bundle_first_bridge.ps1" -Kind "file" -Purpose "Replay-route bundle-first bridge helper surfaced when the suite-catalog route narrows from replay-route into the pinned three-page compatibility bundle."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper surfaced when the suite-catalog route should stay pinned to the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Kind "file" -Purpose "Pinned bundle proof helper surfaced by the suite-catalog route after the delegated bundle runner and bundle-first lane turn green."),
    (New-ValidationReference -Path "scripts/windows/check_local_html_fixture_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast local-fixture proof checker reused when the suite-catalog route reopens the fixed-list screenshot-and-title proof path for the same pinned bundle inputs."),
    (New-ValidationReference -Path "tmp-browser-smoke/local-html-fixtures/chrome-local-html-fixture-probe.ps1" -Kind "file" -Purpose "Fixed-list screenshot-and-title proof probe reused by the suite-catalog route after the pinned bundle runner and proof entrypoint succeed."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1" -Kind "file" -Purpose "Fresh safe-route wrapper surfaced from the suite-catalog chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1" -Kind "file" -Purpose "Reuse-current-output safe-route wrapper surfaced from the suite-catalog chain.")
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
        profile = "google-issue3-suite-catalog-entrypoints"
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

Write-Host "Google issue #3 suite-catalog entrypoints surface check"
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
    Write-Host "Google issue #3 suite-catalog entrypoints surface is intact."
    exit 0
}

Write-Host (("Missing {0} issue #3 suite-catalog path(s).") -f $missing.Count)
Write-Host "Repair the missing suite-router handoff note or checker, the wider suite-router handoff helper, the suite-catalog note, helper, context-surface bridge, replay-route shortcut, or pinned bundle follow-up surface before trusting the issue #3 suite-catalog entrypoint route."
exit 1