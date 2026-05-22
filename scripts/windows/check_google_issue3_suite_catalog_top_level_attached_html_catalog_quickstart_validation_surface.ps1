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
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Primary suite-catalog-to-top-level attached-html catalog quickstart note guarded by this checker."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Broader suite-catalog guide that should stay aligned before this compact route narrows replay again."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md" -Kind "file" -Purpose "Generic attached-html change-area quickstart note surfaced before this compact catalog route narrows replay again."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached-html flow note that remains visible from this compact catalog route."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-html bridge note that remains visible from this compact catalog route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-html quickstart note kept adjacent to this compact route."),
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Validation-router attached-html quickstart note kept visible before replay narrows into the smaller helper ladders."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Compact top-level attached-html quickstart note kept nearby from this compact route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Broader top-level attached-html bridge note kept nearby from this compact route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html catalog quickstart note surfaced by this compact route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-html bridge note used after this compact route narrows further."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned three-page compatibility bundle reference note reused when replay stays on the locked bundle lane."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain fallback note that remains the later escape hatch for this route."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands for this compact route."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose attached-html change areas feed this compact catalog route."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1" -Kind "file" -Purpose "Suite-catalog surface checker that should stay green before this compact route is trusted."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the suite-catalog-to-top-level attached-html catalog quickstart surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Suite-catalog-to-top-level attached-html catalog quickstart helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Broader suite-catalog helper reopened before this compact route narrows replay again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Generic attached-html change-area quickstart helper surfaced before this compact route narrows replay again."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-page localhost flow helper kept visible from this compact route."),
    (New-ValidationReference -Path "scripts/windows/start_attached_pages_catalog.ps1" -Kind "file" -Purpose "Wrapper-backed sidecar audit surfaced from this compact route before the Google-specific ladders."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the dedicated Google attached-html lane kept visible from this compact route."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html checker kept visible from this compact route."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Dedicated Google attached-html flow helper surfaced from this compact route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-html quickstart helper kept visible from this compact route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Validation-router attached-html quickstart helper surfaced by this compact route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Compact top-level attached-html quickstart helper kept adjacent to this compact route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Broader top-level attached-html bridge helper surfaced by this compact route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html catalog quickstart helper surfaced by this compact route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Suite-catalog attached-html bridge helper surfaced after this compact route narrows further."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html bridge helper kept visible when the replay still needs the Google-shaped follow-up branch."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Shortest attached-html shortcut helper surfaced once this compact route confirms the nearby helper ladder is intact."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Replay-shortcuts helper surfaced once this compact route confirms the nearby helper ladder is intact."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Executable suite-router next-step matrix surfaced from this compact route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper surfaced when repo root, saved summary, or pinned bundle inputs already matter."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper surfaced when the compatibility bundle must stay pinned before widening back into the broader issue #3 helper chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map that remains the later fallback after this compact route narrows enough.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Snippet "google_attached_html_sidecar_audit = Format-SidecarAuditCommand -RepoRootOverride $RepoRoot -InputPathOverride $InputPath" -Purpose "Helper command map keeps the lighter sidecar-bundle audit visible from this compact route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Snippet "broader_google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot" -Purpose "Helper command map keeps the broader Google attached-html surface checker visible before the narrower issue-specific checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Snippet "google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1' -RepoRootOverride $RepoRoot" -Purpose "Helper command map keeps the issue-specific Google attached-html checker visible from this compact route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Snippet "top_level_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $bundleArguments" -Purpose "Helper command map keeps the broader top-level attached-html bridge visible before the catalog handoff narrows again."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Snippet "Write-Host ((\"  8. Sidecar audit:              {0}\") -f $entrypoint.helper_commands.google_attached_html_sidecar_audit)" -Purpose "Printed helper output keeps the sidecar audit visible before the Google-specific ladders."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Snippet "Write-Host ((\"  9. Google surface checker:     {0}\") -f $entrypoint.helper_commands.broader_google_attached_html_surface_check)" -Purpose "Printed helper output keeps the broader Google surface checker visible before the narrower issue-specific checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Snippet "Write-Host ((\" 10. Issue-specific check:       {0}\") -f $entrypoint.helper_commands.google_attached_html_surface_check)" -Purpose "Printed helper output keeps the issue-specific Google checker visible before the route narrows further."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Snippet "Write-Host ((\" 15. Top-level bridge:           {0}\") -f $entrypoint.helper_commands.top_level_attached_html_entrypoint)" -Purpose "Printed helper output keeps the broader top-level attached-html bridge visible before the catalog handoff narrows again."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Snippet "Write-Host ((\"Google guide note:              {0}\") -f $entrypoint.google_attached_html_entrypoint_note_path)" -Purpose "Printed helper output keeps the issue-specific Google attached-html note visible beside the compact route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Snippet "Write-Host ((\"Top-level bridge note:          {0}\") -f $entrypoint.top_level_attached_html_bridge_note_path)" -Purpose "Printed helper output keeps the broader top-level attached-html bridge note visible beside the compact route."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Snippet "python .\\tmp-browser-smoke\\attached-pages\\attached_pages_sidecar_audit.py --root '<attached-html-root>'" -Purpose "Companion note still calls out the sidecar-bundle audit in the Google fail-fast handoff."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Snippet "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" -Purpose "Companion note still calls out the issue-specific Google checker before the route narrows further."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Snippet "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_attached_html_entrypoint.ps1" -Purpose "Companion note still calls out the broader top-level attached-html bridge before the catalog handoff narrows again.")
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
        profile = "google-issue3-suite-catalog-top-level-attached-html-catalog-quickstart"
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

Write-Host "Google issue #3 suite-catalog top-level attached HTML catalog quickstart surface check"
Write-Host ""
Write-Host (("Repo root: {0}") -f $resolvedRepoRoot)
Write-Host ""

foreach ($result in $referenceResults) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host (("[{0}] {1}") -f $status, $result.Path)
    Write-Host (("  {0}") -f $result.Purpose)
}

if ($contentResults.Count -gt 0) {
    Write-Host ""
    Write-Host "Helper source expectations:"
    foreach ($result in $contentResults) {
        $status = if ($result.Exists) { "PASS" } else { "FAIL" }
        Write-Host (("[{0}] {1}") -f $status, $result.Path)
        Write-Host (("  {0}") -f $result.Purpose)
    }
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Google issue #3 suite-catalog top-level attached HTML catalog quickstart surface is intact."
    exit 0
}

Write-Host (("Missing {0} suite-catalog top-level attached HTML catalog quickstart path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing sidecar audit, broader or issue-specific Google checker, top-level bridge, delegated helper, note surface, bundle fallback, or safe-route return path before trusting this compact issue #3 attached-page catalog route."
exit 1
