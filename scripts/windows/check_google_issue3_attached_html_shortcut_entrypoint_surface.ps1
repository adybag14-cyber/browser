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
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook reopened when the attached HTML shortcut route starts from the broader Windows-first path."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md" -Kind "file" -Purpose "Primary attached HTML shortcut note that should stay aligned with the compact helper output."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Windows full-use attached HTML route note kept visible beside the shortcut route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Windows-to-validation-router attached HTML bridge note kept nearby from the shortcut route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Windows-first attached HTML catalog quickstart note used before the shortcut route narrows again."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Windows replay quickstart note that can reopen the shortcut route from the replay-side ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached HTML quickstart note surfaced beside the shortcut route."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached HTML flow note kept visible from the shortcut route."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached HTML bridge note kept visible from the shortcut route."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md" -Kind "file" -Purpose "Attached HTML change-area quickstart note surfaced before the shortcut route narrows further."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Compact top-level attached HTML quickstart note surfaced from the shortcut route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Broader top-level attached HTML bridge note surfaced from the shortcut route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached HTML catalog quickstart note surfaced from the shortcut route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached HTML quickstart note surfaced before the shortcut route narrows into the issue-specific helper chain."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Suite-router shortcut bridge note kept nearby as the next narrower route from the attached HTML shortcut surface."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md" -Kind "file" -Purpose "Suite-router entrypoint guide note kept nearby from the attached HTML shortcut route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog guide note kept nearby when the shortcut route widens back out."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned attached bundle reference note surfaced before trusting the bundle-first branch from the shortcut route."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Compact bundle-suite note surfaced when the shortcut route should stay pinned to the known three-page bundle."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md" -Kind "file" -Purpose "Bundle checklist note kept nearby when the shortcut route stays on the pinned three-page compatibility lane."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain note that remains the later fallback after the shortcut route narrows enough."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose attached HTML change areas feed this shortcut route."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached HTML flow helper kept visible before the shortcut route narrows further."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Dedicated Google attached HTML flow helper surfaced from the shortcut route."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Dedicated Google attached HTML fail-fast checker surfaced from the shortcut route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached HTML bridge helper surfaced from the shortcut route."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1" -Kind "file" -Purpose "Windows-first route-level checker surfaced before the shortcut route takes over."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1" -Kind "file" -Purpose "Windows full-use attached HTML route helper surfaced from the shortcut route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1" -Kind "file" -Purpose "Windows-to-validation-router attached HTML bridge helper surfaced from the shortcut route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Windows-first attached HTML catalog quickstart helper surfaced from the shortcut route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached HTML quickstart helper surfaced from the shortcut route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Attached HTML change-area quickstart helper surfaced before the shortcut route narrows further."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Compact top-level attached HTML quickstart helper surfaced from the shortcut route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Broader top-level attached HTML bridge helper surfaced from the shortcut route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached HTML catalog quickstart helper surfaced from the shortcut route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut-first helper that can still precede the narrower suite-router shortcut route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached HTML quickstart helper surfaced before the shortcut route narrows into the shortest issue-specific bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Attached HTML shortcut helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Next narrower suite-router shortcut helper surfaced from the attached HTML shortcut route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper surfaced from the attached HTML shortcut route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Executable next-step matrix surfaced from the attached HTML shortcut route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact bundle-suite helper surfaced when the shortcut route should stay on the pinned three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper surfaced from the attached HTML shortcut route."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1" -Kind "file" -Purpose "Bundle validation flow helper surfaced when the shortcut route stays pinned to the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Bundle validation runner surfaced when the shortcut route stays pinned to the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map surfaced after the shortcut route narrows enough."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1" -Kind "file" -Purpose "Fresh safe-route replay helper surfaced from the attached HTML shortcut route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1" -Kind "file" -Purpose "Existing-output safe-route wrapper surfaced from the attached HTML shortcut route.")
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
        profile = "google-issue3-attached-html-shortcut-entrypoint"
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

Write-Host "Google issue #3 attached HTML shortcut entrypoint surface check"
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
    Write-Host "Google issue #3 attached HTML shortcut entrypoint surface is intact."
    exit 0
}

Write-Host (("Missing {0} attached HTML shortcut path(s).") -f $missing.Count)
Write-Host "Repair the missing attached HTML shortcut note, Windows replay bridge, Google attached-page companion, bundle fallback, or safe-route helper before trusting this compact issue #3 attached-page route."
exit 1
