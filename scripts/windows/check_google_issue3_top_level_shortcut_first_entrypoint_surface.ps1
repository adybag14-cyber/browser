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
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Shortest replay quickstart note surfaced beside the top-level shortcut-first helper."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-html quickstart note surfaced by the top-level shortcut-first helper."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Kind "file" -Purpose "Replay-discovery handoff note that stays adjacent to the top-level shortcut-first route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md" -Kind "file" -Purpose "Primary written companion for the top-level shortcut-first helper."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Broader top-level shortcut bridge note kept nearby when the route widens again."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html quickstart note that the shortcut-first helper keeps close when replay narrows into attached-page follow-up."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html catalog quickstart note surfaced by the shortcut-first helper."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Suite-catalog to top-level attached-html catalog quickstart note surfaced by the shortcut-first helper."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-html quickstart note surfaced by the shortcut-first helper."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Suite-router shortcut bridge note that remains part of the narrower issue #3 ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog guide note that remains available from the top-level shortcut-first route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-html bridge note surfaced before the route narrows again."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached-html flow note kept nearby by the top-level shortcut-first helper."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned three-page bundle reference note surfaced by the top-level shortcut-first helper."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Compact attached-html target-bundle suite-surface note surfaced by the top-level shortcut-first helper."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader Windows validation-chain note that remains the later fallback from the top-level shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose suite and change-area commands feed the top-level shortcut-first helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut-first helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Narrower suite-router shortcut entrypoint surfaced as the default next helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-html quickstart helper surfaced by the top-level shortcut-first helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html quickstart helper surfaced by the top-level shortcut-first helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html catalog quickstart helper surfaced by the top-level shortcut-first helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Suite-catalog to top-level attached-html catalog quickstart helper surfaced by the top-level shortcut-first helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-html quickstart helper surfaced by the top-level shortcut-first helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific attached-html shortcut helper surfaced when the route narrows further."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper surfaced by the top-level shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper surfaced when repo root, summary path, or pinned bundle inputs already matter."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Executable issue #3 branch matrix surfaced from the top-level shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Suite-catalog helper surfaced by the top-level shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Suite-catalog attached-html bridge helper surfaced by the top-level shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Kind "file" -Purpose "Broader suite-router handoff helper that remains a wider fallback from the top-level shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Replay-route helper that remains a wider fallback from the top-level shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact attached-html target-bundle suite-surface helper surfaced by the top-level shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Pinned three-page bundle helper surfaced when explicit input paths should stay in play."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map that remains the later-stage fallback after the shortcut-first route narrows enough."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-html flow helper surfaced from the top-level shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the broader Google attached-html lane kept visible from the top-level shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Dedicated Google attached-html flow helper surfaced from the top-level shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Broader Google localhost-first validation helper kept visible from the top-level shortcut-first route.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet '$topLevelShortcutSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_issue3_top_level_shortcut_first_entrypoint_validation_surface.ps1'' -RepoRootOverride $RepoRoot' -Purpose "Top-level shortcut-first helper wires its dedicated fail-fast checker into the shared command surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'top_level_shortcut_surface_check = $topLevelShortcutSurfaceCheckCommand' -Purpose "Top-level shortcut-first helper exposes its dedicated checker through the top-level command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName ''show_google_issue3_suite_router_shortcut_first_entrypoint.ps1'' -Arguments $bundleArguments' -Purpose "Top-level shortcut-first helper keeps the narrower suite-router shortcut entrypoint wired into the helper command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'attached_bundle_suite_surface = Format-HelperCommand -ScriptName ''show_google_issue3_attached_html_target_bundle_suite_surface.ps1'' -Arguments $bundleArguments' -Purpose "Top-level shortcut-first helper keeps the compact bundle-suite surface available before the route narrows into bundle-first replay."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host (("  6. Shortcut surface check:    {0}") -f $entrypoint.top_level_commands.top_level_shortcut_surface_check)' -Purpose "Top-level bridge output prints the shortcut-first fail-fast checker before narrower helper handoffs."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host (("  8. Google attached check:     {0}") -f $entrypoint.top_level_commands.google_attached_html_surface_check)' -Purpose "Top-level bridge output keeps the broader Google attached-html checker visible beside the shortcut-first route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host (("  Shortcut surface check:{0}") -f ('' '' + $entrypoint.helper_commands.top_level_shortcut_surface_check))' -Purpose "Companion helper output reprints the dedicated shortcut-first checker inside the compact helper surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host (("  Bundle suite helper:    {0}") -f $entrypoint.helper_commands.attached_bundle_suite_surface)' -Purpose "Companion helper output keeps the compact bundle-suite helper visible before the route drops into bundle-first replay."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'Use suite_router_shortcut_entrypoint as the default next helper whenever no pinned bundle inputs need to take precedence' -Purpose "Usage notes explain the default narrowing path from the top-level shortcut-first surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'Use attached_bundle_suite_surface when you want the smallest read-first helper for the known three-page compatibility set before reopening the bundle-first route or widening back into the broader attached-page helper family.' -Purpose "Usage notes preserve the compact bundle-suite route beside the shorter shortcut-first ladder.")
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
        profile = "google-issue3-top-level-shortcut-first-entrypoint"
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

Write-Host "Google issue #3 top-level shortcut-first entrypoint surface check"
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
    Write-Host "Google issue #3 top-level shortcut-first surface is intact."
    exit 0
}

Write-Host (("Missing {0} top-level shortcut-first path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing shortcut note, attached-page helper, bundle helper, source contract, or later-stage fallback before trusting the compact issue #3 top-level shortcut-first surface."
exit 1