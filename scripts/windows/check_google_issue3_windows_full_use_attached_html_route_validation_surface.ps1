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

function New-ValidationContentExpectation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Snippet,
        [Parameter(Mandatory = $true)]
        [string]$Purpose
    )

    return [pscustomobject]@{
        Path = $Path
        Snippet = $Snippet
        Purpose = $Purpose
    }
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$references = @(
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that points into the issue #3 attached-HTML route.") )
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Compact Windows full-use note for the issue #3 attached localhost route.") )
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Windows-first attached-page catalog quickstart note that keeps the wrapper-first, sidecar-first ladder visible beside the broader route.") )
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md" -Kind "file" -Purpose "Windows-first pinned three-page bundle bridge note kept beside the broader Windows full-use route when replay stays on the attached bundle path.") )
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Windows-to-validation-router attached-page bridge note used by the route helper.") )
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-page quickstart note kept beside the broader Windows full-use route.") )
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Validation-router attached-page quickstart note used before the route narrows into the smaller attached-page helpers.") )
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md" -Kind "file" -Purpose "Attached-page change-area quickstart note used before the route narrows into the shorter issue-specific helpers.") )
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Broader top-level attached-page bridge note used by the route helper.") )
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Compact top-level attached-page quickstart note used by the route helper.") )
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Catalog-side attached-page quickstart note used by the route helper.") )
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md" -Kind "file" -Purpose "Companion note map used after the broader top-level attached-page bridge is reopened.") )
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-page quickstart note used by the route helper.") )
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md" -Kind "file" -Purpose "Short suite-router entrypoint guide that WINDOWS_FULL_USE keeps nearby for the fastest bridge from the validation catalog into the issue #3 helper chain.") )
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Suite-router shortcut bridge note kept near the Windows runbook when replay should stay on the shorter issue #3 helper ladder.") )
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-page bridge note used by the route helper.") )
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Windows replay quickstart note kept alongside the route helper.") )
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Shortcut bridge note that connects the broader Windows replay ladder back to the shorter issue #3 helper chain.") )
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Top-level shortcut bridge note kept nearby when the attached-page route narrows back into the shorter helper surface.") )
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Google-shaped attached-page flow note surfaced by the Windows full-use route when the replay stays on the narrower issue #3 lane.") )
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Shorter issue-specific Google attached-page entrypoint note kept nearby before the route collapses into the shorter helper chain.") )
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Compact attached-bundle suite-surface note that the Windows full-use route uses before handing off to the narrower bundle-first helper.") )
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md" -Kind "file" -Purpose "Pinned attached-bundle quickstart note kept beside the Windows full-use route when the known three-page compatibility set is still the active replay target.") )
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used by the route commands when repo-root context is preserved.") )
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level headed validation suite router that exposes the attached-HTML change areas.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1" -Kind "file" -Purpose "Windows full-use attached-HTML route helper for issue #3.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1" -Kind "file" -Purpose "Windows-to-validation-router attached-page bridge helper referenced by the route helper.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Windows-first attached-page catalog quickstart helper referenced by the route note family.") )
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the Windows-first attached-page catalog quickstart so the narrower wrapper-first, sidecar-first ladder is verified before it is trusted.") )
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_full_use_attached_bundle_bridge_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the pinned three-page Windows full-use attached bundle bridge so the narrower bundle branch is verified before it is trusted.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-page quickstart helper referenced by the newer Windows replay route notes.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Validation-router attached-page quickstart helper referenced by the broader attached-page route notes.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_quickstart.ps1" -Kind "file" -Purpose "Compact suite-router quickstart helper that the Windows full-use route uses before narrowing into the shorter attached-page or replay shortcuts.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Attached-page change-area quickstart helper referenced by the route helper before it narrows further.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Compact top-level attached-page quickstart helper referenced by the route helper.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Broader top-level attached-page bridge helper referenced by the route helper.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Catalog-side top-level attached-page quickstart helper referenced by the route helper.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Suite-catalog bridge helper that keeps the catalog-side top-level attached-page quickstart aligned with the broader Windows full-use route.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-page quickstart helper referenced by the route helper.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Suite-catalog entrypoint helper that the route helper surfaces before it narrows into the shorter attached-page chains.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Suite-catalog attached-page bridge helper referenced by the route helper.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-HTML helper referenced by the route helper.") )
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the Google-shaped attached-page fallback lane surfaced by the Windows full-use route.") )
    (New-ValidationReference -Path "scripts/windows/check_attached_html_local_asset_closure.ps1" -Kind "file" -Purpose "Local-asset closure audit used by the Google-shaped attached-page fallback before the headed replay opens a browser.") )
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-shaped attached-page helper surfaced by the Windows full-use route before the issue #3 helper chain narrows again.") )
    (New-ValidationReference -Path "scripts/windows/run_google_attached_html_validation.ps1" -Kind "file" -Purpose "Google-shaped attached-page runner used when the Windows full-use route stays on the narrower issue #3 attached-page lane.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact attached-bundle suite-surface helper that the Windows full-use route prints before the narrower bundle-first helper.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_bundle_first_bridge.ps1" -Kind "file" -Purpose "Replay-route bundle-first bridge helper kept near the Windows full-use route when the known three-page compatibility bundle should stay visible from the replay side too.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Shortest attached-page shortcut helper referenced by the route helper.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper referenced by the route helper.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Issue #3 suite-router next-step helper that the route surfaces when a replay needs a concise next-step matrix after the broader attached-page bridge is restored.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper referenced by the route helper when replay state is already pinned.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map referenced by the route helper.") )
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Pinned three-page bundle helper referenced by the route helper.") )
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath "<saved-html-or-folder>" -AuditSidecars' -Purpose "Windows full-use keeps the wrapper-backed sidecar audit in the attached-pages preflight ladder before replay is blamed."),
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_bundle_bridge_validation_surface.ps1' -Purpose "Windows full-use keeps the pinned bundle bridge checker visible before the route narrows into the locked three-page branch."),
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_bundle_bridge.ps1' -Purpose "Windows full-use keeps the pinned bundle bridge helper visible before replay commits to the locked three-page branch."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1 -RepoRoot ''<repo-root>''' -Purpose "Route note keeps the repo-root-preserving route-level fail-fast checker visible when replay is already running from a non-default checkout."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1 -RepoRoot ''<repo-root>''' -Purpose "Route note keeps the repo-root-preserving catalog-level fail-fast checker visible when replay is already running from a non-default checkout."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -RepoRoot ''<repo-root>'' -InputPath ''<bundle-html-or-folder>'' -AuditSidecars' -Purpose "Route note keeps the repo-root-preserving wrapper-backed sidecar audit visible when replay is already pinned to a bundle from a non-default checkout."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot ''<repo-root>'' -SummaryPath ''<saved-summary-path>'' -InputPath ''<bundle-html-or-folder>''' -Purpose "Route note keeps the repo-root-preserving bundle suite surface visible before the replay narrows into the locked three-page branch from a non-default checkout."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot ''<repo-root>'' -SummaryPath ''<saved-summary-path>'' -InputPath ''<bundle-html-or-folder>''' -Purpose "Route note keeps the repo-root-preserving bundle-first helper visible once replay is already pinned to the known three-page compatibility set from a non-default checkout."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1' -Purpose "Route note keeps the catalog-level fail-fast checker visible before the narrower Windows-first attached-page ladder is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Purpose "Route note keeps the Windows-first attached-page catalog quickstart visible before the route narrows further."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Purpose "Route note keeps the replay-side attached-page quickstart visible beside the broader Windows-full-use ladder."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_change_area_quickstart.ps1' -Purpose "Route note keeps the attached-html change-area bridge visible before the issue-specific helper chain narrows further."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath ''<attached-html-root>'' -AuditSidecars' -Purpose "Route note keeps the Windows wrapper-backed sidecar audit surfaced in the current attached-html follow-up ladder."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath ''<bundle-html-or-folder>''' -Purpose "Route note keeps the compact attached-bundle suite surface visible before the replay narrows into the locked three-page branch."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1 -InputPath ''<bundle-html-or-folder>''' -Purpose "Route note keeps the bundle-first helper visible once the route is pinned to the known three-page compatibility set."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath ''<attached-html-root>'' -AuditSidecars' -Purpose "Catalog quickstart note keeps the wrapper-backed sidecar audit visible as the default attached-pages preflight."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -RepoRoot ''<repo-root>'' -InputPath ''<bundle-html-or-folder>'' -AuditSidecars' -Purpose "Catalog quickstart note keeps the repo-root-preserving wrapper-backed sidecar audit visible for pinned bundle inputs."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -Purpose "Catalog quickstart note keeps the replay-side fail-fast checker visible before the narrower replay ladder is trusted."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Snippet 'attached_pages_sidecar_audit = $attachedPagesSidecarAuditCommand' -Purpose "Catalog helper keeps the wrapper-backed sidecar audit wired into its helper command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Snippet 'recommended_next_key = ''attached_pages_sidecar_audit''' -Purpose "Catalog helper keeps the wrapper-backed sidecar audit as the default next step after the Windows-first route is reprinted.")
)

$referenceResults = foreach ($reference in $references) {
    $fullPath = Join-Path $resolvedRepoRoot $reference.Path
    $exists = if ($reference.Kind -eq "directory") {
        Test-Path -LiteralPath $fullPath -PathType Container
    } else {
        Test-Path -LiteralPath $fullPath -PathType Leaf
    }

    [pscustomobject]@{
        CheckType = "reference"
        Path = $reference.Path
        Kind = $reference.Kind
        Purpose = $reference.Purpose
        Exists = [bool]$exists
    }
}

$contentCache = @{}
$contentResults = foreach ($expectation in $contentExpectations) {
    $fullPath = Join-Path $resolvedRepoRoot $expectation.Path
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        [pscustomobject]@{
            CheckType = "content"
            Path = $expectation.Path
            Kind = "content-snippet"
            Purpose = $expectation.Purpose
            Exists = $false
            Snippet = $expectation.Snippet
        }
        continue
    }

    if (-not $contentCache.ContainsKey($fullPath)) {
        $contentCache[$fullPath] = Get-Content -LiteralPath $fullPath -Raw
    }

    [pscustomobject]@{
        CheckType = "content"
        Path = $expectation.Path
        Kind = "content-snippet"
        Purpose = $expectation.Purpose
        Exists = [bool]$contentCache[$fullPath].Contains($expectation.Snippet)
        Snippet = $expectation.Snippet
    }
}

$missingReferences = @($referenceResults | Where-Object { -not $_.Exists })
$missingContent = @($contentResults | Where-Object { -not $_.Exists })
$missing = @($missingReferences + $missingContent)

if ($Json) {
    [ordered]@{
        profile = "google-issue3-windows-full-use-attached-html-route"
        repo_root = $resolvedRepoRoot
        checked_count = @($referenceResults).Count + @($contentResults).Count
        reference_count = @($referenceResults).Count
        content_check_count = @($contentResults).Count
        missing_count = @($missing).Count
        references = @($referenceResults)
        content_checks = @($contentResults)
    } | ConvertTo-Json -Depth 6

    if ($missing.Count -gt 0) {
        exit 1
    }

    exit 0
}

Write-Host "Google issue #3 Windows full-use attached HTML route surface check"
Write-Host ""
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
Write-Host ""

foreach ($result in $referenceResults) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host ("[{0}] {1}" -f $status, $result.Path)
    Write-Host ("  {0}" -f $result.Purpose)
}

if ($contentResults.Count -gt 0) {
    Write-Host ""
    Write-Host "Helper source expectations:"
    foreach ($result in $contentResults) {
        $status = if ($result.Exists) { "PASS" } else { "FAIL" }
        Write-Host ("[{0}] {1}" -f $status, $result.Path)
        Write-Host ("  {0}" -f $result.Purpose)
    }
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Google issue #3 Windows full-use attached HTML route surface is intact, including the newer catalog quickstart note and its wrapper-first, sidecar-first helper contract."
    exit 0
}

Write-Host ("Missing {0} Windows full-use attached HTML route path or source contract check(s)." -f $missing.Count)
Write-Host "Repair the missing route note, catalog quickstart note, helper, sidecar-audit preflight, pinned bundle bridge, or attached-page quickstart contract before trusting the Windows full-use issue #3 attached localhost route."
exit 1