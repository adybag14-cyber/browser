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
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Replay quickstart note kept visible from the top-level shortcut-first route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-html quickstart note surfaced from the top-level shortcut-first route."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Kind "file" -Purpose "Replay discovery handoff note that remains a nearby written bridge for this shortcut-first surface."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md" -Kind "file" -Purpose "Primary top-level shortcut-first note that should stay aligned with the helper output."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Top-level shortcut bridge note reused by the shortcut-first helper chain."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Compact top-level attached-html quickstart note kept visible beside the shortcut-first helper."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html catalog quickstart note surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Suite-catalog-to-top-level attached-html catalog quickstart note kept visible from the shortcut-first route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-html quickstart note used by the shortcut-first route's default next-step chain."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Suite-router shortcut bridge note kept aligned with the top-level shortcut-first helper."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog guide note surfaced from the top-level shortcut-first route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-html bridge note surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached-html flow note kept visible when the shortcut-first route widens back into the Google-shaped attached-page lane."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint note kept visible when the shortcut-first route narrows from the broader Google-shaped attached-page lane into the narrower replay bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned bundle reference note kept visible when the shortcut-first route stays on the known three-page compatibility set."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Compact attached-bundle suite-surface note surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain note that remains the later fallback for this shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose change-area commands feed the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-html flow helper surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Dedicated Google attached-html surface checker surfaced directly from the shortcut-first route before the narrower helper chain takes over."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html surface checker kept visible when the shortcut-first route narrows from the broader Google-shaped attached-page lane into the narrower replay bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Dedicated Google attached-html flow helper surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html bridge helper kept visible when the shortcut-first route narrows from the broader Google-shaped attached-page lane into the narrower replay bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Broader Google input flow helper that can widen back out from the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut-first helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Default next helper after the top-level shortcut-first route when no bundle inputs are pinned."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-html quickstart helper surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Compact top-level attached-html quickstart helper kept adjacent to the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html catalog quickstart helper surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Suite-catalog-to-top-level attached-html catalog quickstart helper surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-html quickstart helper surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_suite_router_attached_html_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Suite-router attached-html quickstart surface checker that the top-level shortcut-first note reprints before trusting the narrower attached-page bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Shortest attached-html shortcut helper surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper surfaced when repo root, summary, or bundle context already matters."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Executable suite-router next-step matrix surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Suite-catalog guide helper surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Suite-catalog attached-html bridge helper surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Kind "file" -Purpose "Broader suite-router handoff helper that the shortcut-first route can reopen when it widens again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Replay-route helper surfaced from the shortcut-first route when the ladder widens again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact attached-bundle suite helper surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper surfaced when the shortcut-first route should stay pinned to the known three-page bundle."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1" -Kind "file" -Purpose "Fresh safe-route replay runner surfaced from the shortcut-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1" -Kind "file" -Purpose "Existing-output safe-route wrapper surfaced from the shortcut-first route.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_top_level_shortcut_first_entrypoint_validation_surface.ps1' -Purpose "Top-level shortcut-first note still reprints the live fail-fast checker command before the compact helper chain is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md" -Snippet 'check_google_issue3_suite_router_attached_html_quickstart_validation_surface.ps1' -Purpose "Top-level shortcut-first note still reprints the live suite-router attached-html validation checker before trusting the narrower attached-page bridge."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md" -Snippet 'check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1' -Purpose "Top-level shortcut-first note still reprints the issue-specific Google attached-html checker before the route narrows into the narrower replay bridge."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'top_level_shortcut_surface_check = $topLevelShortcutSurfaceCheckCommand' -Purpose "Helper command maps keep the dedicated top-level shortcut-first checker wired into the compact route surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand' -Purpose "Helper command maps keep the broader Google-shaped attached-page checker visible from the compact route surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'suite_router_shortcut_entrypoint = Format-HelperCommand -ScriptName ''show_google_issue3_suite_router_shortcut_first_entrypoint.ps1'' -Arguments $bundleArguments' -Purpose "Helper command maps keep the suite-router shortcut-first entrypoint wired as the default narrower follow-up."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'attached_bundle_suite_surface = Format-HelperCommand -ScriptName ''show_google_issue3_attached_html_target_bundle_suite_surface.ps1'' -Arguments $bundleArguments' -Purpose "Helper command maps keep the compact attached-bundle suite helper visible when the replay stays pinned to the three-page compatibility set."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host (("  6. Shortcut surface check:    {0}") -f $entrypoint.top_level_commands.top_level_shortcut_surface_check)' -Purpose "Printed top-level route keeps the dedicated checker visible before the shorter attached-page ladder takes over."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host (("  8. Google attached check:     {0}") -f $entrypoint.top_level_commands.google_attached_html_surface_check)' -Purpose "Printed top-level route keeps the broader Google-shaped attached-page checker visible before the narrower helper chain takes over."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host ((" 17. Bundle suite helper:       {0}") -f $entrypoint.helper_commands.attached_bundle_suite_surface)' -Purpose "Printed top-level route keeps the compact bundle helper visible before the route widens back out from pinned inputs."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'Use top_level_shortcut_surface_check before trusting this compact route when you want the helper surface to fail fast on missing shortcut notes, attached-page companion helpers, or pinned bundle follow-up commands.' -Purpose "Usage notes preserve when operators should rerun the dedicated shortcut-first checker from the top-level route.")
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
    Write-Host "Google issue #3 top-level shortcut-first entrypoint surface is intact."
    exit 0
}

Write-Host (("Missing {0} top-level shortcut-first path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing shortcut note, attached-page companion, broader or issue-specific Google attached-page checker or bridge, helper, or bundle fallback before trusting the issue #3 top-level shortcut-first route."
exit 1