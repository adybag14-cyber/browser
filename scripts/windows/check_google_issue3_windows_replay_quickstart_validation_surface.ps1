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
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Primary compact replay quickstart note for issue #3."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-html quickstart note reopened from the compact replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Broader Windows attached-html route note reused before the compact replay route narrows."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Windows-to-validation-router bridge note kept aligned with the compact replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Windows-side attached-html catalog quickstart note reopened from the compact replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Validation-router attached-html quickstart note used before the route narrows into smaller attached-page helpers."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html quickstart note reused by the compact replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Broader top-level attached-html bridge note kept beside the compact replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html catalog quickstart note reopened from the compact replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Suite-catalog-to-top-level attached-html catalog quickstart note reused by the compact replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog guide that can reopen the wider replay route before it narrows again."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-html quickstart note kept visible from the compact replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Longer Windows validation-chain note that stays aligned with the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_replay_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Compact replay quickstart checker that this script provides."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Replay-side attached-html surface checker reused by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1" -Kind "file" -Purpose "Broader Windows attached-html route checker reused by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router that can reopen the compact replay route from google-recommended or attached-html entrypoints."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Suite-catalog entrypoint helper kept visible before the compact replay route narrows again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_quickstart.ps1" -Kind "file" -Purpose "Short suite-router bridge helper reused by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1" -Kind "file" -Purpose "Broader Windows attached-html route helper reopened before the compact replay route narrows."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1" -Kind "file" -Purpose "Windows-to-validation-router bridge helper reused by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Windows-side attached-html catalog quickstart helper reused by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-html quickstart helper reopened from the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Validation-router attached-html quickstart helper reused by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html quickstart helper surfaced by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Broader top-level attached-html bridge helper kept visible from the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html catalog quickstart helper reused by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Suite-catalog-to-top-level attached-html catalog quickstart helper reused by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-html quickstart helper kept visible before the route collapses into narrower shortcuts."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut-first helper surfaced by the compact replay route before shortcut-only follow-up."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Shortest attached-html shortcut helper reached from the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Replay-shortcuts helper reached from the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Next-step matrix helper that the compact replay route can reopen after the suite-catalog bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving replay helper reused when repo root, summary, or bundle inputs are already pinned."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Kind "file" -Purpose "Wider suite-router handoff helper reused when the compact replay route needs to widen again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Replay-route helper reused when the compact replay route needs a wider bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper reused when the compact replay route should stay pinned to the three-page compatibility bundle."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map reopened only after the compact replay route narrows as far as it can go." )
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
        profile = "google-issue3-windows-replay-quickstart"
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

Write-Host "Google issue #3 Windows replay quickstart surface check"
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
    Write-Host "Google issue #3 Windows replay quickstart surface is intact."
    exit 0
}

Write-Host (("Missing {0} Windows replay quickstart path(s).") -f $missing.Count)
Write-Host "Repair the missing note, helper, or narrower attached-html bridge before trusting the issue #3 Windows replay quickstart route."
exit 1
