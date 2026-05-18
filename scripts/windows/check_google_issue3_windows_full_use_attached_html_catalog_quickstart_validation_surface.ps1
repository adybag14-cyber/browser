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
    (New-ValidationReference -Path "docs/HEADED_MODE_VALIDATION_GATES.md" -Kind "file" -Purpose "Canonical bounded-suite routing map that points issue #3 attached localhost follow-up through the Windows-first attached-page catalog quickstart."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes issue #3 attached localhost replay into the narrower catalog quickstart lane."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Broader Windows full-use attached-page route note that precedes the catalog quickstart."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Windows-to-validation-router bridge note used before the catalog quickstart narrows the route again."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Windows-first attached-page catalog quickstart note guarded by this surface check."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md" -Kind "file" -Purpose "Attached-html change-area quickstart note that the Windows-first catalog helper now routes through before the broader attached-page flow helper and replay-side quickstarts."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-page quickstart note kept beside the broader Windows full-use route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-page catalog quickstart note kept visible beside the Windows-first helper."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Suite-catalog companion note for the top-level attached-page catalog ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-page bridge note referenced by the Windows-first catalog helper."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google-shaped attached-page guide kept visible when the narrower catalog route still needs the Google follow-up branch nearby."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned three-page compatibility bundle reference note reopened from the catalog quickstart when the replay stays on the locked bundle."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Compact bundle-suite note that keeps the locked three-page route visible beside the Windows-first catalog quickstart."),
    (New-ValidationReference -Path "tmp-browser-smoke/attached-pages/README.md" -Kind "file" -Purpose "Lower-level attached-pages launcher guide that should stay aligned with the Windows-first catalog quickstart's sidecar-first replay order."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used by the catalog quickstart and its companion route scripts when repo-root context is preserved."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level headed validation router that exposes the attached HTML, Google attached HTML, and target-bundle change areas."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1" -Kind "file" -Purpose "Broader Windows full-use route checker that should stay green before the narrower catalog quickstart is trusted."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1" -Kind "file" -Purpose "Windows full-use attached-page route helper that precedes the catalog quickstart."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1" -Kind "file" -Purpose "Windows-to-validation-router attached-page bridge helper used just before the catalog quickstart."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Windows-first attached-page catalog quickstart helper guarded by this surface check."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Attached-html change-area quickstart helper that keeps the attached-html branch visible before the Windows-first catalog route narrows deeper into replay-side and top-level helpers."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-page quickstart helper kept visible beside the Windows-first catalog helper."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-page flow helper reopened when the current pages no longer stay on the narrower catalog route."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Dedicated Google-shaped attached-page flow helper reopened when the current pages still need the issue #3 follow-up lane."),
    (New-ValidationReference -Path "scripts/windows/start_attached_pages_catalog.ps1" -Kind "file" -Purpose "Windows wrapper that keeps the attached-pages launcher, sidecar audit, asset audit, and localhost startup on the same PowerShell entrypoint."),
    (New-ValidationReference -Path "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py" -Kind "file" -Purpose "Cross-platform attached-pages launcher that the Windows-first catalog quickstart now depends on for sidecar-first audit and localhost startup."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Compact top-level attached-page quickstart helper kept beside the Windows-first catalog route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Broader top-level attached-page bridge helper referenced by the catalog quickstart."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-page catalog quickstart helper that follows the Windows-first catalog route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut bridge helper kept visible when the route narrows further from the Windows-first catalog helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Replay-route shortcut bridge helper kept beside the Windows-first catalog route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact attached-bundle suite helper reopened from the Windows-first catalog route when the current pages still match the locked three-page bundle."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Suite-catalog companion helper for the top-level attached-page catalog ladder."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Suite-catalog attached-page bridge helper referenced by the Windows-first catalog quickstart."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-page bridge helper kept visible when the replay still needs the Google-shaped follow-up branch."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Shortest attached-page shortcut helper reopened when the catalog route narrows further."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper referenced after the Windows-first catalog route is green."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper used when repo root, saved summary, or explicit bundle paths are already pinned."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper reopened when the current pages still match the pinned three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map reopened only after the Windows-first attached-page catalog route is known good.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath ''<attached-html-root>'' -AuditSidecars' -Purpose "Catalog quickstart note keeps the Windows wrapper-backed sidecar audit visible as the default attached-pages preflight."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -InputPath ''<attached-html-root>'' -GoogleStyle -AuditSidecars' -Purpose "Catalog quickstart note keeps the Google-style Windows wrapper-backed sidecar audit visible when the broader Google-shaped attached-page route should stay in view."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -RepoRoot ''<repo-root>'' -InputPath ''<bundle-html-or-folder>'' -AuditSidecars' -Purpose "Catalog quickstart note keeps the repo-root-preserving Windows wrapper-backed sidecar audit visible for pinned bundle inputs."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Snippet '- `scripts/windows/start_attached_pages_catalog.ps1`' -Purpose "Catalog quickstart note keeps the Windows wrapper surfaced as a first-class companion path beside the lower-level launcher guide."),
    (New-ValidationContentExpectation -Path "tmp-browser-smoke/attached-pages/README.md" -Snippet 'The intended order is sidecars first, broader asset audit second, manifest or server startup last.' -Purpose "Attached-pages launcher guide keeps the fuller preflight ladder order visible beside the Windows-first catalog route."),
    (New-ValidationContentExpectation -Path "tmp-browser-smoke/attached-pages/README.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 \
  -InputPath "C:\path\to\saved-pages-dir" \
  -AuditAssets' -Purpose "Attached-pages launcher guide keeps the wrapper-backed asset-audit step visible after the sidecar preflight."),
    (New-ValidationContentExpectation -Path "tmp-browser-smoke/attached-pages/README.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -GoogleStyle -PrintManifest' -Purpose "Attached-pages launcher guide keeps the wrapper-backed Google-style manifest step visible before localhost launch."),
    (New-ValidationContentExpectation -Path "tmp-browser-smoke/attached-pages/README.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 \
  -InputPath "C:\path\to\saved-pages-dir" \
  -RequireCompleteSidecars' -Purpose "Attached-pages launcher guide keeps the wrapper-backed strict sidecar gate visible before manifest or launch steps."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Snippet "recommended_next_key = 'attached_pages_sidecar_audit'" -Purpose "Windows-first catalog helper keeps the wrapper-backed sidecar audit as its default next step."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Snippet 'attached_pages_sidecar_audit = $attachedPagesSidecarAuditCommand' -Purpose "Windows-first catalog helper keeps the wrapper-backed sidecar audit wired into the helper command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Snippet 'attached_pages_asset_audit = $attachedPagesAssetAuditCommand' -Purpose "Windows-first catalog helper keeps the wrapper-backed asset audit wired into the helper command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Snippet 'attached_pages_print_manifest = $attachedPagesManifestPrintCommand' -Purpose "Windows-first catalog helper keeps the wrapper-backed manifest print wired into the helper command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Snippet 'attached_pages_strict_launch = $attachedPagesStrictLaunchCommand' -Purpose "Windows-first catalog helper keeps the strict sidecar-gated launch wired into the helper command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Snippet 'attached_pages_launcher_wrapper_path = ''scripts/windows/start_attached_pages_catalog.ps1''' -Purpose "Windows-first catalog helper keeps the wrapper path surfaced beside the attached-pages README."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Snippet 'attached_pages_launcher_entrypoint_path = ''tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py''' -Purpose "Windows-first catalog helper keeps the lower-level attached-pages launcher surfaced beside the wrapper path and README."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Snippet 'Write-Host ((\" 10. Sidecar audit:         {0}\") -f $entrypoint.helper_commands.attached_pages_sidecar_audit)' -Purpose "Windows-first catalog helper keeps the printed sidecar audit command aligned with the wrapper-backed launcher surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Snippet 'Write-Host ((\" 11. Asset audit:           {0}\") -f $entrypoint.helper_commands.attached_pages_asset_audit)' -Purpose "Windows-first catalog helper keeps the printed asset audit command aligned with the wrapper-backed launcher surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Snippet 'Write-Host ((\" 12. Print manifest:        {0}\") -f $entrypoint.helper_commands.attached_pages_print_manifest)' -Purpose "Windows-first catalog helper keeps the printed manifest command aligned with the wrapper-backed launcher surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Snippet 'Write-Host ((\" 13. Strict launch:         {0}\") -f $entrypoint.helper_commands.attached_pages_strict_launch)' -Purpose "Windows-first catalog helper keeps the printed strict sidecar-gated launch command aligned with the wrapper-backed launcher surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Snippet 'Write-Host ((\"Attached-pages wrapper:     {0}\") -f $entrypoint.attached_pages_launcher_wrapper_path)' -Purpose "Windows-first catalog helper keeps the printed wrapper companion path visible beside the launcher guide."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Snippet 'Write-Host ((\"Attached-pages launcher:    {0}\") -f $entrypoint.attached_pages_launcher_entrypoint_path)' -Purpose "Windows-first catalog helper keeps the printed lower-level launcher path visible beside the wrapper and README.")
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
        profile = "google-issue3-windows-full-use-attached-html-catalog-quickstart"
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

Write-Host "Google issue #3 Windows full-use attached HTML catalog quickstart surface check"
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
    Write-Host "Google issue #3 Windows full-use attached HTML catalog quickstart surface is intact."
    exit 0
}

Write-Host ("Missing {0} Windows full-use attached HTML catalog quickstart path or source contract check(s)." -f $missing.Count)
Write-Host "Repair the missing route note, launcher guide, launcher entrypoint, Windows wrapper, wrapper-backed attached-pages preflight ladder contract, attached-html change-area bridge, catalog quickstart helper, companion top-level or suite-catalog bridge, Google-shaped fallback, bundle re-entry helper, or safe-route return script before trusting this narrower attached-page ladder."
exit 1