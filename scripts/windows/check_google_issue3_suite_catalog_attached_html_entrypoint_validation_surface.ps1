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
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Primary suite-catalog attached-html bridge note that should stay aligned with the compact helper surface."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Broader suite-catalog guide reopened before the attached-page bridge narrows further."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that can reopen the attached-html route before the suite-catalog bridge narrows again."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Windows full-use attached-html route note reused by the suite-catalog bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Windows-to-validation-router bridge note reused by the suite-catalog attached-html route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Windows-side catalog quickstart note reopened before the route falls back into the narrower attached-page bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Replay-side quickstart note that can still feed back into the suite-catalog attached-html route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-html quickstart note kept visible beside the suite-catalog bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Validation-router attached-html quickstart note kept visible before the route narrows into the replay-side helper chain."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Compact top-level attached-html quickstart note used by the suite-catalog bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Broader top-level attached-html bridge note reused by the suite-catalog bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html catalog quickstart note surfaced by the suite-catalog bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Top-level shortcut bridge note kept visible before the suite-catalog route collapses into narrower helpers."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Suite-catalog-to-top-level attached-html catalog quickstart note surfaced by the bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md" -Kind "file" -Purpose "Top-level attached-html companion note map kept visible beside the suite-catalog bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-html quickstart note reused when the route widens back toward the suite-router surface."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Suite-router shortcut bridge note kept nearby when the route narrows beyond the attached-page ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned three-page attached-html bundle reference note reused when the bridge stays on the known compatibility set."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Longer Windows validation-chain note kept aligned with the suite-catalog attached-html bridge."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level suite router whose change-area commands feed the suite-catalog attached-html bridge."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast route checker reused before the suite-catalog bridge narrows from the broader Windows surface."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_suite_catalog_attached_html_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the issue #3 suite-catalog attached-html bridge surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Suite-catalog attached-html bridge helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Broader suite-catalog helper reopened before the attached-page bridge narrows again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut-first helper surfaced by the suite-catalog bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Validation-router attached-html quickstart helper surfaced by the suite-catalog bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-html quickstart helper surfaced by the suite-catalog bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Compact top-level attached-html quickstart helper surfaced by the suite-catalog bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Broader top-level attached-html bridge helper surfaced by the suite-catalog bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html catalog quickstart helper surfaced by the suite-catalog bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-html quickstart helper surfaced by the suite-catalog bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html bridge helper surfaced by the suite-catalog bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Shortest attached-html shortcut helper surfaced by the suite-catalog bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Suite-router shortcut-first helper surfaced after the attached-page ladder narrows further."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper surfaced by the suite-catalog bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Executable next-step matrix helper surfaced by the suite-catalog bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper surfaced when repo root, summary, or bundle inputs are already pinned."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper surfaced when the bridge should stay pinned to the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map surfaced only after the attached-page branch has narrowed enough."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1" -Kind "file" -Purpose "Broader Windows full-use attached-html route helper reopened before the suite-catalog bridge narrows again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1" -Kind "file" -Purpose "Windows-to-validation-router bridge helper surfaced by the suite-catalog bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Windows-side attached-html catalog quickstart helper surfaced by the suite-catalog bridge.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Snippet 'suite_catalog_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1'' -RepoRootOverride $RepoRoot' -Purpose "Suite-catalog attached-html bridge keeps the suite-catalog fail-fast checker wired into its helper command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Snippet 'windows_replay_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1'' -RepoRootOverride $RepoRoot' -Purpose "Suite-catalog attached-html bridge keeps the replay-side attached-html fail-fast checker wired into its helper command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Snippet 'attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName ''show_attached_html_validation_flow.ps1'' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot' -Purpose "Suite-catalog attached-html bridge keeps the broader attached-html flow helper visible before the route narrows again."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Snippet 'google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand' -Purpose "Suite-catalog attached-html bridge keeps the Google-shaped attached-html fail-fast checker surfaced from the helper command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Snippet 'Write-Host (("  7. Suite-catalog check:    {0}") -f $entrypoint.helper_commands.suite_catalog_surface_check)' -Purpose "Bridge output prints the suite-catalog fail-fast checker before the replay-side ladder narrows further."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Snippet 'Write-Host ((" 10. Replay surface check:   {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_surface_check)' -Purpose "Bridge output prints the replay-side attached-html fail-fast checker before the Windows replay quickstart."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Snippet 'Write-Host (("  13. Google surface check:   {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)' -Purpose "Bridge output keeps the Google-shaped attached-html checker visible before the top-level attached-page helpers."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Snippet 'Write-Host (("  17. Router attached quick:  {0}") -f $entrypoint.helper_commands.suite_router_attached_html_quickstart)' -Purpose "Bridge output keeps the shorter suite-router attached-html quickstart visible as the default narrowing path."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Snippet 'Write-Host (("  18. Google attached:        {0}") -f $entrypoint.helper_commands.google_attached_html_entrypoint)' -Purpose "Bridge output keeps the issue-specific Google attached-html entrypoint visible after the suite-router quickstart."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Snippet 'Write-Host (("  20. Bundle suite helper:    {0}") -f $entrypoint.helper_commands.attached_html_target_bundle_suite_surface)' -Purpose "Bridge output keeps the compact bundle-suite helper visible before the route drops to the bundle-first branch."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Snippet 'Use suite_router_attached_html_quickstart as the default next helper when explicit InputPath values are not already pinned and no saved replay context needs to take precedence first' -Purpose "Usage notes explain the default next helper for the suite-catalog attached-html bridge."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Snippet 'Use google_attached_html_entrypoint after the suite_router_attached_html_quickstart when the issue-specific attached-page bridge should stay visible before the replay narrows to the Google attached-html validation flow' -Purpose "Usage notes preserve the narrower issue-specific Google attached-html branch after the suite-router quickstart.")
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
        profile = "google-issue3-suite-catalog-attached-html-entrypoint"
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

Write-Host "Google issue #3 suite-catalog attached-html entrypoint surface check"
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
    Write-Host "Google issue #3 suite-catalog attached-html entrypoint surface is intact."
    exit 0
}

Write-Host (("Missing {0} issue #3 suite-catalog attached-html path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing guide, helper, delegated attached-page branch, or helper-output contract before trusting the issue #3 suite-catalog attached-html bridge."
exit 1