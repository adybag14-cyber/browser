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
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Broader Windows headed runbook that can reopen the issue #3 attached-page route before this top-level bridge takes over.")
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Windows full-use attached-page route note that can reopen the top-level attached HTML bridge.")
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Windows-first validation-router bridge note kept aligned before this top-level attached HTML bridge narrows the route again.")
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain note that can reopen this top-level attached-page route after higher-level validation routing.")
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md" -Kind "file" -Purpose "Compact attached-page change-area quickstart note that should stay aligned with the top-level attached HTML bridge.")
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Compact top-level attached-page quickstart note that should stay aligned with the broader top-level bridge.")
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Written companion note for the issue #3 top-level attached HTML bridge.")
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-page catalog quickstart note that should stay aligned with this bridge.")
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md" -Kind "file" -Purpose "Nearby-note map for the top-level attached-page route family.")
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-page quickstart note surfaced immediately after this top-level bridge.")
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-page bridge note kept nearby when this route widens again.")
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md" -Kind "file" -Purpose "Attached-page shortcut note surfaced after the top-level bridge narrows further.")
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Replay-route shortcut companion note surfaced after the top-level bridge narrows further.")
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used by the top-level attached-page commands when repo-root context is preserved.")
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level headed validation suite router that reopens the attached-page change areas.")
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1" -Kind "file" -Purpose "Windows full-use attached-page route checker surfaced before this top-level bridge takes over.")
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_html_shortcut_validation_surface.ps1" -Kind "file" -Purpose "Attached-page shortcut checker surfaced when this top-level bridge narrows into the shortest route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Attached-page change-area quickstart helper surfaced before the top-level attached HTML bridge narrows the route.")
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-page validation flow helper surfaced before or beside this top-level bridge.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut-first helper kept nearby when the route should stay compact after the broader top-level bridge.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Compact top-level attached-page quickstart helper surfaced beside this bridge.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Primary issue #3 top-level attached HTML bridge helper.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Catalog-side top-level attached-page quickstart helper surfaced by this bridge.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-page quickstart helper surfaced immediately after this bridge.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google-shaped attached-page helper surfaced when the route should stay broader after this bridge.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Suite-catalog helper surfaced when repo-root, saved-summary, or bundle state already matters.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Suite-catalog attached-page bridge helper kept nearby when this route widens again.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Shortest attached-page helper surfaced after this bridge narrows the route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Replay-route shortcut helper surfaced after this bridge narrows the route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper surfaced after this bridge narrows the route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Next-step matrix surfaced after this bridge narrows the route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper surfaced when repo-root or saved-summary state already matters.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Pinned three-page bundle helper surfaced when attached bundle inputs are already fixed.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map surfaced when the route widens again after this bridge.")
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
        profile = "google-issue3-top-level-attached-html-bridge"
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

Write-Host "Google issue #3 top-level attached HTML bridge surface check"
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
    Write-Host "Google issue #3 top-level attached HTML bridge surface is intact."
    exit 0
}

Write-Host (("Missing {0} top-level attached HTML bridge path(s).") -f $missing.Count)
Write-Host "Repair the missing note, helper, or checker before trusting the issue #3 top-level attached localhost bridge."
exit 1
