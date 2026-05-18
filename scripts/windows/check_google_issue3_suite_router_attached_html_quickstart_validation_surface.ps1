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
    (New-ValidationReference -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Kind "file" -Purpose "Top-level headed production guide that can reopen the attached-html route before the suite-router quickstart narrows it."),
    (New-ValidationReference -Path "docs/ISSUE3_PRODUCTION_EXECUTION_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Attached-html production route note that stays adjacent to the suite-router attached-html quickstart."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Broader Windows runbook that can reopen the attached-html lane before the suite-router-side quickstart takes over."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Windows-first attached-html route note surfaced by the quickstart's broader handoff guidance."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Windows full-use validation-router bridge kept adjacent to the suite-router quickstart."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Windows-first attached-html catalog quickstart that stays aligned with the suite-router quickstart."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Replay-side quickstart note that remains nearby when the attached-html lane widens again."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-html quickstart that stays adjacent to the suite-router attached-html bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Validation-router attached-html quickstart surfaced as the first narrower follow-up."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md" -Kind "file" -Purpose "Change-area attached-html quickstart that keeps the broader attached-page route visible."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Compact top-level attached-html quickstart kept adjacent to the suite-router attached-html route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html catalog quickstart that remains part of the same narrowed route family."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Broader top-level attached-html bridge note reopened from the suite-router quickstart."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md" -Kind "file" -Purpose "Companion-note map that keeps the nearby top-level attached-html note family easy to reopen."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md" -Kind "file" -Purpose "Top-level shortcut-first note that remains adjacent before the route narrows into shorter helpers."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Top-level shortcut bridge note that stays nearby when issue #3 is already obvious from the broader router."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog guide surfaced from the suite-router attached-html quickstart before replay shortcuts take over."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-html bridge note kept aligned with the suite-router attached-html route."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Compact bundle-suite surface note kept available when the three-page compatibility bundle stays pinned."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached-html flow note that stays adjacent when the current attached-page set is Google-like."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-html bridge note reopened from the suite-router quickstart."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain note that stays available once the quickstart route widens back into wrapper-heavy flows."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware commands for the attached-html quickstart lane."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose attached-html change areas feed the suite-router quickstart."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-html quickstart helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1" -Kind "file" -Purpose "Windows-first attached-html route helper that can precede the suite-router quickstart."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the Windows-first attached-html route kept nearby in the broader handoff."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1" -Kind "file" -Purpose "Windows full-use validation-router bridge helper kept aligned with the suite-router quickstart."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Windows-first catalog quickstart that stays adjacent to the suite-router attached-html route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-html quickstart helper that can precede the suite-router quickstart."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Validation-router attached-html quickstart surfaced as a primary narrower follow-up."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Change-area attached-html quickstart that keeps the broader attached-page route visible before narrower helpers take over."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-html flow helper surfaced directly from the suite-router quickstart."),
    (New-ValidationReference -Path "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py" -Kind "file" -Purpose "Launcher-backed attached-pages sidecar audit surfaced before the broader Google checker and the narrower issue-specific bridge take over."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the dedicated Google-shaped attached-html lane."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html surface checker kept visible when the route narrows from the broader Google-shaped lane into the issue-specific bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Dedicated Google-shaped attached-html flow helper kept visible before the route narrows again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact bundle-suite helper surfaced when the replay should stay pinned to the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Broader suite-catalog helper that remains adjacent to the suite-router attached-html route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Suite-catalog attached-html bridge helper surfaced from the suite-router attached-html route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Compact top-level attached-html helper surfaced from the suite-router quickstart."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html catalog helper kept adjacent to the same route family."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Top-level attached-html bridge helper reopened from the suite-router quickstart."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint helper surfaced when the attached-page set is Google-like."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Short attached-html shortcut helper kept visible before replay shortcuts or safe-route helpers take over."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper that the attached-html quickstart can narrow into."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Compact next-step matrix kept adjacent when the route still needs the explicit executable branch table."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper kept nearby when repo root, summary, or pinned bundle inputs already matter."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Pinned bundle-first helper used when the replay should stay on the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map that remains the later fallback once the attached-html lane has narrowed enough.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_attached_html_quickstart_validation_surface.ps1' -Purpose "Quickstart note keeps the suite-router attached-html fail-fast checker visible before the shorter route is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Snippet 'python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --audit-sidecars --input ''<attached-html-root>''' -Purpose "Quickstart note keeps the launcher-backed attached-pages sidecar audit visible before the broader Google checker or narrower issue-specific checker take over."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1' -Purpose "Quickstart note keeps the broader Google attached-html surface checker visible when the route is still reopening the Google-shaped attached-page lane."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1' -Purpose "Quickstart note keeps the issue-specific Google attached-html surface checker visible before the narrower bridge is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Snippet 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md' -Purpose "Quickstart note keeps the issue-specific Google attached-html note visible beside the broader Google helper chain."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Snippet '$command = ''python .\\tmp-browser-smoke\\attached-pages\\start_attached_pages_catalog.py --audit-sidecars''' -Purpose "Helper command builder now points the suite-router quickstart at the launcher-backed attached-pages sidecar audit."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Snippet 'attached_pages_sidecar_audit = $attachedPagesSidecarAuditCommand' -Purpose "Helper command map keeps the launcher-backed attached-pages sidecar audit wired into the quickstart surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Snippet 'suite_router_attached_html_surface_check = $suiteRouterAttachedHtmlSurfaceCheckCommand' -Purpose "Helper command map keeps the suite-router attached-html surface checker wired into the quickstart surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Snippet 'google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand' -Purpose "Helper command map keeps the broader Google attached-html surface checker wired into the quickstart surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Snippet 'google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand' -Purpose "Helper command map keeps the issue-specific Google attached-html surface checker wired into the quickstart surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Snippet 'google_attached_html_entrypoint = Format-HelperCommand -ScriptName ''show_google_issue3_google_attached_html_entrypoint.ps1'' -Arguments $bundleArguments' -Purpose "Helper command map keeps the issue-specific Google attached-html bridge surfaced from the quickstart."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Suite-router surface check:  {0}") -f $helper.commands.suite_router_attached_html_surface_check)' -Purpose "Broader attached-page handoff output still prints the suite-router attached-html surface checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Attached pages audit:        {0}") -f $helper.commands.attached_pages_sidecar_audit)' -Purpose "Broader attached-page handoff output still prints the launcher-backed attached-pages sidecar audit before the Google-specific checks take over."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Google attached surface:     {0}") -f $helper.commands.google_attached_html_surface_check)' -Purpose "Broader attached-page handoff output still prints the broader Google attached-html surface checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Issue-specific Google check: {0}") -f $helper.commands.google_issue3_attached_html_surface_check)' -Purpose "Broader attached-page handoff output still prints the issue-specific Google attached-html surface checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Attached pages audit:         {0}") -f $helper.commands.attached_pages_sidecar_audit)' -Purpose "Attached-page follow-up output still prints the launcher-backed attached-pages sidecar audit before the narrower bridge is trusted."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Google attached bridge:       {0}") -f $helper.commands.google_attached_html_entrypoint)' -Purpose "Attached-page follow-up output still prints the issue-specific Google attached-html bridge command.")
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
        profile = "google-issue3-suite-router-attached-html-quickstart"
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

Write-Host "Google issue #3 suite-router attached-html quickstart surface check"
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
    Write-Host "Google issue #3 suite-router attached-html quickstart surface is intact."
    exit 0
}

Write-Host (("Missing {0} suite-router attached-html quickstart path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing attached-html note, launcher-backed sidecar-audit command, helper output contract, broader Google attached-page checks, issue-specific Google bridge surface, or bundle-route companion before trusting this narrowed issue #3 surface."
exit 1