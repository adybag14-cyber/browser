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
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Compact replay quickstart note that anchors the suite-router quickstart bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Replay quickstart shortcut bridge note that remains part of the read-first suite-router quickstart surface."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md" -Kind "file" -Purpose "Suite-router entrypoint guide that explains the higher-level quickstart surface."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Suite-router shortcut bridge note that remains adjacent to the quickstart helper output."),
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Validation-router attached-html quickstart note surfaced by the suite-router quickstart helper."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-html quickstart note that the quickstart helper keeps visible."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog entrypoints guide that remains part of the quickstart helper's companion note set."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-html bridge note surfaced by the quickstart helper."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached-html flow note kept visible by the quickstart helper."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Top-level attached-html bridge note that remains part of the quickstart surface."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html quickstart note surfaced by the suite-router quickstart helper."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html catalog quickstart note kept visible from the quickstart surface."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Safe-route note that remains the broader fallback beside the suite-router quickstart helper."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared repo-root helper surface used by the suite-router quickstart checker and helper."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose entrypoints feed the suite-router quickstart helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_quickstart.ps1" -Kind "file" -Purpose "Suite-router quickstart helper whose dependent surface this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Validation-router attached-html quickstart helper surfaced by the suite-router quickstart helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut-first entrypoint that stays visible from the suite-router quickstart helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Top-level attached-html bridge helper kept visible by the suite-router quickstart helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Dedicated Google attached-html flow helper surfaced from the suite-router quickstart helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint helper that remains part of the quickstart surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-html quickstart helper that remains the default next step from the quickstart surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html quickstart helper kept visible from the suite-router quickstart surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html catalog quickstart helper that remains part of the quickstart surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Broader suite-catalog re-entry helper surfaced by the suite-router quickstart helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Suite-catalog attached-html bridge helper surfaced by the suite-router quickstart helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific attached-html shortcut helper that remains part of the quickstart surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Replay-shortcuts helper surfaced by the suite-router quickstart helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Suite-router next-steps matrix helper that remains adjacent to the quickstart surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper surfaced when repo-root, summary, or pinned bundle inputs already matter."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Safe-route helper surfaced once the quickstart route narrows enough."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper surfaced when the quickstart route should stay pinned to the known three-page compatibility set.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_quickstart.ps1" -Snippet "Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_suite_router_quickstart_validation_surface.ps1' -RepoRootOverride `$RepoRoot" -Purpose "Helper command builder keeps the suite-router quickstart surface checker wired into the helper surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_quickstart.ps1" -Snippet "suite_router_surface_check = `$suiteRouterSurfaceCheckCommand" -Purpose "Helper command map keeps the suite-router quickstart surface checker visible from the helper surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_quickstart.ps1" -Snippet 'Write-Host (("  Quickstart surface: {0}") -f $helper.commands.suite_router_surface_check)' -Purpose "Helper output prints the suite-router quickstart surface checker before the narrower follow-up helpers are trusted."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_quickstart.ps1" -Snippet "show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments `$bundleArguments" -Purpose "Helper command map still points the compact suite-router quickstart at the attached-html quickstart follow-up."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_quickstart.ps1" -Snippet "show_google_issue3_suite_router_next_steps.ps1' -Arguments `$bundleArguments" -Purpose "Helper command map still keeps the next-step matrix available beside the compact suite-router quickstart."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_quickstart.ps1" -Snippet 'Recommended next helper:' -Purpose "Helper output still prints the recommendation block before the compact follow-up map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_quickstart.ps1" -Snippet 'Follow-up helpers:' -Purpose "Helper output still prints the compact follow-up map after the recommendation block.")
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
        profile = "google-issue3-suite-router-quickstart"
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

Write-Host "Google issue #3 suite-router quickstart surface check"
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
    Write-Host "Google issue #3 suite-router quickstart surface is intact."
    exit 0
}

Write-Host (("Missing {0} suite-router quickstart path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing quickstart note, suite-catalog bridge, attached-html helper, replay-shortcut helper, next-step matrix, context-preserving helper, or bundle-first fallback before trusting the suite-router quickstart surface."
exit 1
