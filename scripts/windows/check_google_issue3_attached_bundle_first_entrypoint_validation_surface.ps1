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
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Windows replay note that should stay visible before the bundle-first route locks onto the pinned three-page compatibility set."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-html quickstart note that the bundle-first helper keeps nearby before the replay narrows."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-page quickstart note that remains visible before the bundle-only branch takes over."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md" -Kind "file" -Purpose "Attached-page shortcut note kept visible before the pinned bundle route narrows fully."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Google-shaped attached-page flow note kept adjacent when the current bundle still includes a Google-like page."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned three-page compatibility bundle reference note that anchors the bundle-first route."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md" -Kind "file" -Purpose "Pinned bundle quickstart note surfaced beside the bundle-first helper."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md" -Kind "file" -Purpose "Pinned bundle checklist note that should remain easy to reopen after localhost replay."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain note that remains the later fallback after the bundle-first branch narrows enough."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose attached-html and attached-html-target-bundle change areas feed the bundle-first route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-html quickstart helper surfaced before the pinned bundle route takes over."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html quickstart helper kept visible before the pinned bundle branch."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Shortest attached-page shortcut helper surfaced before the bundle-only branch."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-page localhost helper that should remain visible beside the bundle-first lane."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-shaped attached-page flow helper that stays visible when the pinned bundle includes a Google-like page."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_target_bundle_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the pinned attached-html target bundle surface."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_target_bundle.ps1" -Kind "file" -Purpose "Bundle checker that confirms the current saved pages still match the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1" -Kind "file" -Purpose "Bundle-aware flow helper that stays adjacent to the pinned bundle route."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Bundle-aware localhost runner surfaced by the bundle-first helper."),
    (New-ValidationReference -Path "scripts/windows/check_local_html_fixture_validation_surface.ps1" -Kind "file" -Purpose "Reusable fixed-list proof surface checker that should remain visible after the bundle runner turns green."),
    (New-ValidationReference -Path "tmp-browser-smoke/local-html-fixtures/chrome-local-html-fixture-probe.ps1" -Kind "file" -Purpose "Reusable screenshot-and-title proof probe used after the bundle replay completes."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Replay-shortcuts helper that should stay visible after the bundle replay narrows the next failure."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Safe-route helper map that remains the later fallback after the bundle-first route completes."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Kind "file" -Purpose "Pinned bundle proof helper that should remain available before widening back into the broader issue #3 helper chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first issue #3 entrypoint helper that this checker validates.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Snippet "bundle_surface_check_command = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments \$bundleSurfaceCheckArguments" -Purpose "Bundle-first helper exposes the bundle surface checker before localhost replay."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Snippet "local_html_fixture_surface_check_command = Format-HelperCommand -ScriptName 'check_local_html_fixture_validation_surface.ps1' -Arguments \$localHtmlFixtureSurfaceArguments" -Purpose "Bundle-first helper reopens the reusable fixed-list proof surface after the bundle runner turns green."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Snippet "local_html_fixture_probe_command = Format-PowerShellFileCommand -RelativePath 'tmp-browser-smoke\\local-html-fixtures\\chrome-local-html-fixture-probe.ps1' -Arguments \$localHtmlFixtureProbeArguments" -Purpose "Bundle-first helper keeps the fixed-list screenshot-and-title proof probe pinned to the same saved compatibility pages."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Snippet "replay_shortcuts_command = Format-HelperCommand -ScriptName 'show_google_issue3_replay_shortcuts.ps1' -Arguments \$replayShortcutsArguments" -Purpose "Bundle-first helper keeps the replay-shortcuts handoff visible after the pinned bundle replay."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Snippet "return_to_safe_route_command = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments \$safeRouteArguments" -Purpose "Bundle-first helper keeps the safe-route fallback visible after the pinned bundle replay narrows the failure."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Snippet "Write-Host ('Proof after bundle replay:')" -Purpose "Bundle-first helper prints the proof section so the reusable fixed-list validation stays visible after localhost replay."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Snippet "Write-Host ('Return after bundle replay:')" -Purpose "Bundle-first helper prints the replay return section so the next narrower handoff remains visible after the bundle run."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Snippet "Pass -RepoRoot and -SummaryPath when the replay is running from a non-default checkout" -Purpose "Usage notes document that repo-root and saved-summary context should be preserved on the narrower bundle-first branch."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Snippet "Pass -InputPath when you want to keep an explicit bundle path or fixed file list pinned through the bundle check" -Purpose "Usage notes document that explicit bundle inputs should stay pinned through the checker, runner, and proof commands.")
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
        profile = "google-issue3-attached-bundle-first-entrypoint"
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

Write-Host "Google issue #3 attached bundle first entrypoint surface check"
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
    Write-Host "Google issue #3 attached bundle first entrypoint surface is intact."
    exit 0
}

Write-Host (("Missing {0} attached bundle first entrypoint path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing bundle-first note, helper surface, proof follow-up, replay return path, or pinned-input contract before trusting this issue #3 compatibility-bundle route."
exit 1
