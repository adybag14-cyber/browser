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
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Windows full-use attached-html route note that the compact top-level helper keeps nearby."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md" -Kind "file" -Purpose "Attached-html change-area quickstart note surfaced before the compact top-level helper narrows the route again."),
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Validation-router attached-html quickstart note kept visible beside the compact top-level route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Compact top-level attached-html quickstart note that this checker validates."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Broader top-level attached-html bridge note kept adjacent to the compact top-level helper."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached-html flow note that remains visible from the compact top-level route."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint note that stays visible when the compact top-level route still needs the narrower Google-shaped bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned three-page bundle reference note that the compact top-level route now relies on before bundle-first replay narrows further."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Compact bundle-suite note kept visible when the replay stays pinned to the three-page compatibility set."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md" -Kind "file" -Purpose "Bundle proof note kept visible when the compact top-level route wants the written companion for the fixed-list screenshot-and-title proof path."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md" -Kind "file" -Purpose "Replay-route bundle-first bridge note that should stay available when the compact top-level route hands off into the pinned bundle path."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md" -Kind "file" -Purpose "Pinned bundle quickstart note kept visible beside the compact top-level route when the three-page compatibility set remains the narrowest lane."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md" -Kind "file" -Purpose "Pinned bundle checklist note kept nearby when the compact top-level route needs the page-by-page manual follow-up for the same three-page set."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html catalog quickstart note surfaced by the compact top-level route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Suite-catalog-to-top-level attached-html catalog quickstart note surfaced by the compact top-level route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog guide note kept nearby from the compact top-level route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md" -Kind "file" -Purpose "Top-level attached-html companion note map kept nearby from the compact top-level route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md" -Kind "file" -Purpose "Top-level shortcut-first note kept visible when the compact top-level route narrows further."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Top-level shortcut bridge note kept nearby beside the compact top-level route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-html quickstart note used by the compact top-level route's default follow-up."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Replay quickstart note that stays available while the compact top-level route is open."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain note that remains the later fallback for the compact top-level route."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose attached-html change areas feed the compact top-level route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1" -Kind "file" -Purpose "Windows full-use attached-html route helper surfaced beside the compact top-level route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Attached-html change-area quickstart helper surfaced before the compact top-level route narrows again."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-html flow helper that stays visible from the compact top-level route."),
    (New-ValidationReference -Path "tmp-browser-smoke/attached-pages/attached_pages_sidecar_audit.py" -Kind "file" -Purpose "Lighter attached-pages sidecar audit surfaced before the broader Google checker or narrower issue-specific bridge take over."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the dedicated Google attached-html lane kept visible from the compact top-level route."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint checker kept visible when the compact top-level route still depends on the narrower Google-shaped lane."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Dedicated Google attached-html flow helper surfaced from the compact top-level route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact bundle-suite helper surfaced when the replay remains pinned to the compatibility bundle."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Kind "file" -Purpose "Pinned bundle proof helper that should stay available before the compact top-level route widens back out after bundle replay."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Validation-router attached-html quickstart helper surfaced by the compact top-level route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Compact top-level attached-html quickstart helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Broader top-level attached-html bridge helper kept adjacent to the compact top-level route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut-first helper surfaced when the compact top-level route narrows further."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html catalog quickstart helper surfaced by the compact top-level route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Suite-catalog-to-top-level attached-html catalog quickstart helper surfaced by the compact top-level route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Suite-catalog guide helper that remains visible from the compact top-level route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-html quickstart helper used as the compact top-level route's default next step."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Suite-catalog attached-html bridge helper surfaced from the compact top-level route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html bridge helper surfaced from the compact top-level route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Shortest attached-html shortcut helper surfaced from the compact top-level route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Replay-shortcuts helper surfaced after the compact top-level route confirms issue #3 replay stays in bounds."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Executable suite-router next-step matrix surfaced from the compact top-level route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper surfaced when repo root, summary, or pinned bundle inputs already matter."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper surfaced after the compact top-level route when the compatibility bundle must stay pinned."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map that remains the later fallback after the compact top-level route narrows enough.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Snippet 'python .\tmp-browser-smoke\attached-pages\attached_pages_sidecar_audit.py --root ''<attached-html-root>''' -Purpose "Quickstart note keeps the lighter attached-pages sidecar audit visible before the broader Google checker or narrower issue-specific bridge take over."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Snippet '$attachedPagesSidecarAuditCommand = Format-AttachedPagesSidecarAuditCommand -InputPath $InputPath' -Purpose "Top-level attached-html quickstart builds the reusable attached-pages sidecar audit command before wiring the helper surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Snippet 'attached_pages_sidecar_audit = $attachedPagesSidecarAuditCommand' -Purpose "Top-level attached-html quickstart exposes the lighter attached-pages sidecar audit through the helper command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Snippet '$googleIssue3AttachedHtmlSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1'' -RepoRootOverride $RepoRoot' -Purpose "Top-level attached-html quickstart wires the issue-specific Google surface checker into its shared command surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Snippet 'google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand' -Purpose "Top-level attached-html quickstart exposes the issue-specific Google surface checker through the helper command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Snippet 'attached_bundle_proof_note_path = ''docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md''' -Purpose "Top-level attached-html quickstart keeps the bundle proof note path alongside the other pinned-bundle companions."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Attached pages audit:      {0}") -f $helper.commands.attached_pages_sidecar_audit)' -Purpose "Top-level attached-page entrypoints keep the lighter attached-pages sidecar audit visible before the Google-specific checks take over."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Issue-specific Google:     {0}") -f $helper.commands.google_issue3_attached_html_surface_check)' -Purpose "Top-level attached-page entrypoints keep the issue-specific Google checker visible before the route narrows again."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Snippet 'Write-Host (("Bundle proof note:          {0}") -f ('' '' + $helper.attached_bundle_proof_note_path))' -Purpose "Top-level attached-html quickstart prints the bundle proof note as a first-class nearby companion."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Attached pages audit:      {0}") -f $helper.commands.attached_pages_sidecar_audit)' -Purpose "Compact follow-up helpers keep the lighter attached-pages sidecar audit visible inside the narrower top-level helper surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Issue-specific Google:     {0}") -f $helper.commands.google_issue3_attached_html_surface_check)' -Purpose "Compact follow-up helpers keep the issue-specific Google checker visible inside the narrower top-level helper surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Snippet 'Use google_issue3_attached_html_surface_check when the replay has already narrowed from the broader Google-shaped attached-page lane into the issue-specific Google attached-page bridge and you want the entrypoint-specific fail-fast checker reprinted before the narrower helper chain.' -Purpose "Usage notes document when the issue-specific Google checker should be used from the top-level attached-page route.")
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
        profile = "google-issue3-top-level-attached-html-quickstart"
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

Write-Host "Google issue #3 top-level attached HTML quickstart surface check"
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
    Write-Host "Google issue #3 top-level attached HTML quickstart surface is intact."
    exit 0
}

Write-Host (("Missing {0} top-level attached HTML quickstart path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing compact top-level note, attached-page companion, helper surface, sidecar-audit surfacing, issue-specific Google checker surfacing, bundle proof note surfacing, or bundle fallback before trusting this issue #3 attached-page route."
exit 1
