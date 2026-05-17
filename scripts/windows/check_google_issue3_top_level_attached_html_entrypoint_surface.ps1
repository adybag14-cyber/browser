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
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Primary top-level attached-html bridge note that this checker protects."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Shorter top-level attached-html quickstart note that stays adjacent to the broader bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html catalog quickstart note that the broader bridge reopens before suite-catalog follow-up."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Suite-catalog-to-top-level attached-html catalog quickstart note surfaced beside the broader bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md" -Kind "file" -Purpose "Companion-note map for the broader top-level attached-html bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md" -Kind "file" -Purpose "Top-level shortcut-first note surfaced before the broader bridge narrows into shorter replay helpers."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Top-level shortcut bridge note that remains a nearby fallback from the broader bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md" -Kind "file" -Purpose "Attached-html change-area quickstart note that feeds the broader top-level bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md" -Kind "file" -Purpose "Shortest issue-specific attached-html note reopened after the broader bridge narrows further."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google-style attached-html flow note kept visible from the broader bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-html quickstart note that should stay aligned with the top-level bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Short replay note that links into this broader top-level bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Windows full-use attached-html route note that can reopen before the broader bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Windows-to-validation-router attached-html bridge note surfaced ahead of the broader top-level bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Validation-router attached-html quickstart note that remains adjacent to the broader bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-html quickstart note used by the default narrower follow-up from the broader bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Suite-router shortcut bridge note that stays aligned when the route narrows after the broader bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog guide note that remains a wider fallback from the broader bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-html bridge note surfaced beside the broader top-level bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Kind "file" -Purpose "Replay-discovery handoff note that feeds the broader top-level bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Replay-route shortcut bridge note that remains reachable after the broader bridge narrows further."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned three-page bundle reference note that should stay visible before bundle-first follow-up."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Compact bundle-suite note surfaced beside the broader bridge when the bundle path is pinned."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Longer Windows validation-chain fallback note reopened only after the narrower bridge chain is exhausted."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Broader Windows runbook that can reopen the attached localhost route before this bridge narrows again."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose attached-html change-area commands feed the broader bridge."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the broader Windows full-use attached-html route surfaced before the top-level bridge."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Replay-side fail-fast checker surfaced before the broader top-level bridge."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_html_shortcut_validation_surface.ps1" -Kind "file" -Purpose "Attached-html shortcut fail-fast checker kept visible from the broader top-level bridge."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_html_change_area_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Attached-html change-area quickstart fail-fast checker surfaced before the broader top-level bridge."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Dedicated Google-style attached-html fail-fast checker kept visible from the broader top-level bridge."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_top_level_shortcut_first_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Top-level shortcut-first fail-fast checker surfaced before the broader top-level bridge narrows further."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Broader top-level attached-html bridge helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Attached-html change-area quickstart helper surfaced before the broader top-level bridge."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-html flow helper kept visible from the top-level bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Dedicated Google-style attached-html flow helper surfaced beside the broader top-level bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut-first helper surfaced before the broader top-level bridge narrows into shorter replay helpers."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Shorter top-level attached-html quickstart helper that stays adjacent to the broader bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Validation-router attached-html quickstart helper surfaced before the broader bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-html quickstart helper that feeds the broader bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html catalog quickstart helper surfaced beside the broader bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Suite-catalog-to-top-level attached-html catalog quickstart helper surfaced beside the broader bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Default shorter suite-router attached-html bridge reopened after the broader top-level bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html bridge surfaced when the broader bridge narrows into the Google-shaped lane."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Suite-catalog guide helper that remains a wider fallback from the broader bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Suite-catalog attached-html bridge helper surfaced beside the broader top-level bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Shortest issue-specific attached-html helper reopened after the broader bridge narrows further."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Suite-router shortcut helper surfaced from the broader bridge when the route keeps shrinking."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Replay-route shortcut helper that stays visible after the broader bridge narrows further."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper reachable from the broader bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Compact next-step matrix helper that stays adjacent to the broader bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper surfaced when repo root, summary, or pinned bundle inputs already matter."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact bundle-suite helper surfaced beside the broader bridge when the route stays pinned to the three-page bundle."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Pinned bundle-first helper reopened after the broader bridge when explicit bundle inputs are already in play."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map that remains the later-stage fallback once the broader bridge chain is exhausted."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1" -Kind "file" -Purpose "Fresh safe-route replay command that remains reachable from the broader bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1" -Kind "file" -Purpose "Reuse-current-outputs wrapper that stays reachable from the broader bridge once a summary already exists.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Snippet '$topLevelAttachedHtmlSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_issue3_top_level_attached_html_entrypoint_validation_surface.ps1'' -RepoRootOverride $RepoRoot' -Purpose "Top-level attached-html entrypoint wires its own fail-fast checker into the shared command surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Snippet 'top_level_attached_html_surface_check = $topLevelAttachedHtmlSurfaceCheckCommand' -Purpose "Top-level attached-html entrypoint exposes its own surface checker through the top-level command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Snippet 'attached_html_change_area_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_issue3_attached_html_change_area_quickstart_validation_surface.ps1'' -RepoRootOverride $RepoRoot' -Purpose "Top-level attached-html entrypoint keeps the attached-html change-area quickstart checker visible before reopening that narrower branch."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Snippet 'google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand' -Purpose "Top-level attached-html entrypoint exposes the broader Google attached-html checker through the helper command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Snippet 'Write-Host (("  8. Top-level surface check:    {0}") -f $entrypoint.top_level_commands.top_level_attached_html_surface_check)' -Purpose "The numbered top-level bridge output prints the broader top-level surface checker before the route narrows again."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Snippet 'Write-Host ((" 10. Change-area surface check:  {0}") -f $entrypoint.top_level_commands.attached_html_change_area_surface_check)' -Purpose "The numbered top-level bridge output prints the change-area quickstart checker beside the attached-page helper ladder."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Snippet 'Write-Host ((" 13. Google surface check:       {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)' -Purpose "The numbered top-level bridge output prints the broader Google checker before the Google-shaped flow helper."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Snippet 'Write-Host (("  Top-level surface check:  {0}") -f $entrypoint.top_level_commands.top_level_attached_html_surface_check)' -Purpose "The companion helper block keeps the broader top-level surface checker visible from the compact helper map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Snippet 'Write-Host (("  Change-area surface check:{0}") -f ('' '' + $entrypoint.top_level_commands.attached_html_change_area_surface_check))' -Purpose "The companion helper block keeps the change-area quickstart checker visible from the compact helper map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Snippet 'Write-Host (("  Google surface check:     {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)' -Purpose "The companion helper block keeps the broader Google checker visible from the compact helper map.")
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
        profile = "google-issue3-top-level-attached-html-entrypoint"
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

Write-Host "Google issue #3 top-level attached-html entrypoint surface check"
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
    Write-Host "Google issue #3 top-level attached-html entrypoint surface is intact."
    exit 0
}

Write-Host (("Missing {0} top-level attached-html entrypoint path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing top-level attached-html note, helper, fail-fast checker, replay-side bridge, suite-catalog companion, bundle helper, or surfaced command contract before trusting the broader issue #3 attached-page bridge."
exit 1