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
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Primary compact replay quickstart note for issue #3."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-html quickstart note reopened from the compact replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Broader Windows attached-html route note reused before the compact replay route narrows."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Windows-to-validation-router bridge note kept aligned with the compact replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Windows-side attached-html catalog quickstart note reopened from the compact replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Validation-router attached-html quickstart note used before the route narrows into smaller attached-page helpers."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html quickstart note reused by the compact replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Broader top-level attached-html bridge note kept beside the compact replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html catalog quickstart note reopened from the compact replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Suite-catalog-to-top-level attached-html catalog quickstart note reused by the compact replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog guide that can reopen the wider replay route before it narrows again."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-html quickstart note kept visible from the compact replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Longer Windows validation-chain note that stays aligned with the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/start_attached_pages_catalog.ps1" -Kind "file" -Purpose "Wrapper-backed attached-pages launcher used by the replay quickstart for sidecar audits before the route narrows."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_replay_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Compact replay quickstart checker that this script provides."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Replay-side attached-html surface checker reused by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1" -Kind "file" -Purpose "Broader Windows attached-html route checker reused by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1" -Kind "file" -Purpose "Attached-pages launcher companion checker reused when the compact replay route wants the smaller wrapper-backed preflight surface."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router that can reopen the compact replay route from google-recommended or attached-html entrypoints."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Suite-catalog entrypoint helper kept visible before the compact replay route narrows again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_quickstart.ps1" -Kind "file" -Purpose "Short suite-router bridge helper reused by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1" -Kind "file" -Purpose "Broader Windows attached-html route helper reopened before the compact replay route narrows."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1" -Kind "file" -Purpose "Windows-to-validation-router bridge helper reused by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Windows-side attached-html catalog quickstart helper reused by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-html quickstart helper reopened from the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Kind "file" -Purpose "Attached-pages launcher companion helper reused when the compact replay route wants the smaller wrapper-backed preflight surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Validation-router attached-html quickstart helper reused by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html quickstart helper surfaced by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Broader top-level attached-html bridge helper kept visible from the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html catalog quickstart helper reused by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Suite-catalog-to-top-level attached-html catalog quickstart helper reused by the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-html quickstart helper kept visible before the route collapses into narrower shortcuts."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut-first helper surfaced by the compact replay route before shortcut-only follow-up."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Shortest attached-html shortcut helper reached from the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Replay-shortcuts helper reached from the compact replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Next-step matrix helper that the compact replay route can reopen after the suite-catalog bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving replay helper reused when repo root, summary, or bundle inputs are already pinned."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Kind "file" -Purpose "Wider suite-router handoff helper reused when the compact replay route needs to widen again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Replay-route helper reused when the compact replay route needs a wider bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper reused when the compact replay route should stay pinned to the three-page compatibility bundle."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map reopened only after the compact replay route narrows as far as it can go.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1' -Purpose "Replay quickstart keeps the suite-catalog fail-fast checker visible before the broader catalog helper is reused."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_entrypoints.ps1' -Purpose "Replay quickstart keeps the suite-catalog helper visible as the broader read-first re-entry surface."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_quickstart_validation_surface.ps1' -Purpose "Replay quickstart keeps the suite-router quickstart checker visible before the shorter router-side bridge is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_quickstart.ps1' -Purpose "Replay quickstart keeps the shorter suite-router bridge visible for the compact route."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath ''<attached-html-root>'' -GoogleStyle -AuditSidecars' -Purpose "Replay quickstart keeps the wrapper-backed sidecar audit visible before the broader Google-shaped attached-page surface checks and helpers take over."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -RepoRoot ''<repo-root>'' -InputPath ''<attached-html-or-folder>'' -GoogleStyle -AuditSidecars' -Purpose "Replay quickstart preserves the repo-root-aware wrapper-backed sidecar audit when the replay is running from a non-default checkout."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -Purpose "Replay quickstart keeps the replay-side attached-html fail-fast checker visible before the narrower attached-page ladder is reused."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_next_steps_validation_surface.ps1' -Purpose "Replay quickstart keeps the suite-router next-step checker visible before the executable matrix is reused."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet '- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`' -Purpose "Replay quickstart keeps the compact attached-bundle suite note visible as a companion reference."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Purpose "Replay quickstart keeps the compact attached-bundle suite helper visible before the bundle-first branch is chosen."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1" -Snippet "suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments `$sharedArguments" -Purpose "Helper output keeps the suite-catalog entrypoint helper wired into the compact replay surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1" -Snippet "windows_replay_attached_html_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -Arguments `$routeSurfaceArguments" -Purpose "Helper output keeps the replay-side attached-html surface checker wired into the compact replay surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1" -Snippet "attached_pages_launcher_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments `$routeSurfaceArguments" -Purpose "Helper output keeps the launcher companion surface checker wired into the compact replay surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1" -Snippet "attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments `$sharedArguments" -Purpose "Helper output keeps the launcher companion helper wired into the compact replay surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1" -Snippet "attached_html_target_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments `$sharedArguments" -Purpose "Helper output keeps the compact attached-bundle suite helper wired into the compact replay surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1" -Snippet 'Treat replay_attached_html_note_path as the read-first written companion to windows_replay_attached_html_quickstart' -Purpose "Helper notes keep the replay-side attached-html note visible as the written companion once the route narrows."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1" -Snippet 'Write-Host (("  Launcher surface check:    {0}") -f $helper.commands.attached_pages_launcher_surface_check)' -Purpose "Helper output prints the launcher companion surface checker on the replay quickstart ladder."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1" -Snippet 'Write-Host (("  Launcher companion:        {0}") -f $helper.commands.attached_pages_launcher_companion)' -Purpose "Helper output prints the launcher companion helper on the replay quickstart ladder.")
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
        profile = "google-issue3-windows-replay-quickstart"
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

Write-Host "Google issue #3 Windows replay quickstart surface check"
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
    Write-Host "Google issue #3 Windows replay quickstart surface is intact."
    exit 0
}

Write-Host (("Missing {0} Windows replay quickstart path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the replay quickstart note, the compact suite-catalog or suite-router surfaces, the replay-side attached-html ladder, the bundle-aware helper surface, or the narrower helper contracts before trusting the issue #3 Windows replay quickstart route."
exit 1
