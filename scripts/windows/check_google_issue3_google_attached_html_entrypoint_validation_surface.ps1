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
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Compact replay quickstart note that stays adjacent to the issue-specific Google attached-html route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Suite-router shortcut bridge note that explains the shorter issue 3 handoff into the Google attached-html entrypoint."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog guide that remains the broader fallback beside the issue-specific Google attached-html route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-html bridge note kept visible when the route re-enters from the broader validation catalog."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Suite-catalog top-level attached-html catalog quickstart note kept adjacent to the narrower issue-specific route."),
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Validation-router attached-html quickstart note kept nearby when the route reopens from the broader router."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Top-level attached-html bridge note that remains visible when the route widens back out."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint note that this checker protects."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached-html validation-flow note kept visible from the entrypoint."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain note reopened when the issue-specific Google attached-html route widens again."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned three-page compatibility bundle reference note surfaced when the replay should stay on the known attached-page bundle."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Companion bundle-suite note surfaced when the issue-specific Google attached-html route is already close to the pinned three-page compatibility lane."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose Google attached-html change area feeds the entrypoint."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Broader Google attached-html surface checker that should stay visible before the issue-specific checker."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the issue-specific Google attached-html entrypoint lane surfaced directly from the entrypoint."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_local_asset_closure.ps1" -Kind "file" -Purpose "Attached-html local asset audit kept visible before the route narrows into the shorter issue 3 helper chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader Google attached-html flow helper kept visible from the entrypoint."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Default shortcut-first issue 3 bridge reopened when no stronger replay context is already pinned."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper surfaced once the route is already known to stay inside issue 3."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper surfaced when repo root, summary path, or pinned bundle inputs already matter."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Executable next-step matrix helper that remains adjacent to the issue-specific Google attached-html route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Broader suite-catalog helper that remains available from the issue-specific Google attached-html route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Suite-catalog attached-html bridge helper kept visible from the issue-specific Google attached-html route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Suite-catalog top-level attached-html catalog quickstart helper kept adjacent to the narrower issue-specific route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Kind "file" -Purpose "Wider suite-router handoff helper that the entrypoint can reopen."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Replay-route helper surfaced when the issue-specific Google attached-html route widens again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper surfaced when the replay should stay pinned to the three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact bundle-suite helper kept nearby when the route stays pinned to the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1" -Kind "file" -Purpose "Bundle validation-flow helper kept visible before the route widens back into the broader issue 3 helper chain."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Bundle validation runner surfaced after the bundle-aware entrypoint when the replay should stay locked to the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Safe-route helper map that remains the later fallback after the issue-specific Google attached-html route narrows enough."),
    (New-ValidationReference -Path "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py" -Kind "file" -Purpose "Launcher-backed sidecar-bundle audit entrypoint that the read-first Google attached-html route now surfaces before the deeper local asset crawl."),
    (New-ValidationReference -Path "tmp-browser-smoke/attached-pages/attached_pages_sidecar_audit.py" -Kind "file" -Purpose "Underlying sidecar audit helper that the launcher-backed route depends on before the deeper local asset crawl.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'google_attached_html_sidecar_audit = Format-SidecarAuditCommand -RepoRootOverride $RepoRoot -InputPathOverride $InputPath' -Purpose "Issue-specific Google attached-html entrypoint now surfaces the lighter sidecar-bundle audit before the broader Google-shaped checks."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'broader_google_attached_html_surface_check = Format-HelperCommand -ScriptName ''check_google_attached_html_validation_surface.ps1'' -Arguments $googleAttachedHtmlSurfaceCheckArguments' -Purpose "Issue-specific Google attached-html entrypoint now keeps the broader Google-shaped surface checker visible after the lighter sidecar audit and before the narrower issue-specific checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'google_attached_html_asset_closure = Format-HelperCommand -ScriptName ''check_attached_html_local_asset_closure.ps1'' -Arguments $googleAttachedHtmlAssetAuditArguments -Switches @(''GoogleStyle'')' -Purpose "Issue-specific Google attached-html entrypoint now keeps the deeper asset-closure audit visible before the narrower issue-specific checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1'' -RepoRootOverride $RepoRoot' -Purpose "Issue-specific Google attached-html entrypoint wires its dedicated fail-fast checker into the helper command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'google_attached_html_validation_flow = Format-HelperCommand -ScriptName ''show_google_attached_html_validation_flow.ps1'' -Arguments $googleAttachedHtmlFlowArguments' -Purpose "Issue-specific Google attached-html entrypoint keeps the broader Google attached flow helper visible before the route narrows again."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'Write-Host (("  6. Sidecar audit:        {0}") -f $entrypoint.helper_commands.google_attached_html_sidecar_audit)' -Purpose "Top-level bridge output now prints the lighter sidecar-bundle audit before the broader surface checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'Write-Host (("  7. Broader surface:      {0}") -f $entrypoint.helper_commands.broader_google_attached_html_surface_check)' -Purpose "Top-level bridge output prints the broader Google attached-html surface checker after the sidecar audit and before the deeper asset audit."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'Write-Host (("  8. Asset closure:        {0}") -f $entrypoint.helper_commands.google_attached_html_asset_closure)' -Purpose "Top-level bridge output prints the deeper asset-closure audit before the issue-specific checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'Write-Host (("  9. Issue-specific check: {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)' -Purpose "Top-level bridge output still prints the issue-specific fail-fast checker after the lighter sidecar and broader Google-shaped checks."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'Write-Host (("  Sidecar audit:         {0}") -f $entrypoint.helper_commands.google_attached_html_sidecar_audit)' -Purpose "Companion helper output keeps the lighter sidecar-bundle audit visible from the compact entrypoint surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'Write-Host (("  Broader surface check: {0}") -f $entrypoint.helper_commands.broader_google_attached_html_surface_check)' -Purpose "Companion helper output keeps the broader Google attached-html surface checker visible from the compact entrypoint surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'Write-Host (("  Asset closure audit:   {0}") -f $entrypoint.helper_commands.google_attached_html_asset_closure)' -Purpose "Companion helper output keeps the deeper asset audit visible from the compact entrypoint surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'Use google_attached_html_sidecar_audit when the current saved export may be missing its whole sibling `_files` bundle and you want that simpler failure mode ruled in or out before the broader surface check or the deeper asset audit.' -Purpose "Usage notes explain when to rerun the lighter sidecar-bundle audit from this compact route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'Use broader_google_attached_html_surface_check when the replay is already narrowed to the Google-shaped attached-page route and you want the wider fail-fast helper surface reprinted after the sidecar audit but before the deeper asset audit or the narrower issue-specific checker.' -Purpose "Usage notes explain when to rerun the broader Google attached-html surface checker from this compact route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'Use google_attached_html_asset_closure when local asset drift might explain the current Google-shaped attached-page failure and you want the deeper asset audit reprinted after the sidecar audit and broader surface check but before the route narrows into the issue-specific checker or shortcut ladder.' -Purpose "Usage notes explain when to rerun the deeper asset-closure audit from this compact route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'Use google_attached_html_surface_check when the replay is already narrowed to the issue-specific attached-page route and you want the dedicated fail-fast entrypoint surface reprinted after the sidecar audit, broader Google-shaped surface check, and asset audit but before the broader flow helper or its downstream runner handoff.' -Purpose "Usage notes explain when to rerun the issue-specific entrypoint checker after the broader Google-shaped checks."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Snippet 'Use google_attached_html_validation_flow when the broader Google-style attached-page flow helper still needs to stay visible after the sidecar audit, broader surface check, asset audit, and dedicated entrypoint surface check and before the route narrows into the shorter issue #3 shortcut-first, replay-shortcut, context-preserving, or bundle-aware branches.' -Purpose "Usage notes explain when the broader Google attached flow should stay visible before the route narrows further."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Snippet 'python .\tmp-browser-smoke\attached-pages\start_attached_pages_catalog.py --audit-sidecars' -Purpose "Read-first entrypoint note keeps the launcher-backed sidecar-bundle audit visible before the broader Google-shaped surface checker and deeper asset crawl."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_attached_html_validation_surface.ps1' -Purpose "Read-first entrypoint note keeps the broader Google attached-html surface checker visible before the issue-specific checker takes over."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1' -Purpose "Read-first entrypoint note keeps the issue-specific fail-fast checker visible alongside the broader Google-shaped checks.")
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
        profile = "google-issue3-google-attached-html-entrypoint"
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

Write-Host "Google issue #3 Google attached-html entrypoint surface check"
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
    Write-Host "Google issue #3 Google attached-html entrypoint surface is intact."
    exit 0
}

Write-Host (("Missing {0} Google attached-html entrypoint path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the issue-specific note, the broader Google-shaped surface and asset-audit companions, the suite-catalog or top-level bridges, the bundle-aware helpers, the dedicated issue-specific checker surfacing, or the later fallback stack before trusting the Google attached-html entrypoint route."
exit 1
