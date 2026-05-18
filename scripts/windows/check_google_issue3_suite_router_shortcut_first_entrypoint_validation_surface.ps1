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
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Replay quickstart note that should stay aligned with the shortcut-first bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Primary suite-router shortcut bridge note referenced by the compact shortcut-first helper."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Adjacent suite-router attached-html quickstart note that the compact shortcut-first helper prints beside the shortcut bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog guide note that remains available from the shortcut-first bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Replay-route shortcut note that should stay adjacent to the compact shortcut-first bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached-page flow note surfaced when the shortcut-first route widens into the Google-shaped attached-page lane."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-page entrypoint note surfaced from the compact shortcut-first bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain note that remains the fallback when the compact shortcut-first bridge widens again."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose issue #3 change-area commands feed the shortcut-first bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Shortcut-first suite-router helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-page localhost flow helper surfaced from the shortcut-first bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Dedicated Google-shaped attached-page flow helper surfaced from the shortcut-first bridge."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Broader Google-shaped attached-page surface checker surfaced from the shortcut-first bridge before the issue-specific checker."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_local_asset_closure.ps1" -Kind "file" -Purpose "Deeper Google-style asset-closure audit surfaced from the shortcut-first bridge before the issue-specific checker."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Issue-specific Google attached-page surface checker surfaced from the compact shortcut-first bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-page bridge surfaced from the compact shortcut-first bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Attached-page shortcut helper surfaced from the compact shortcut-first bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper surfaced as the default next step from the shortcut-first bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Replay-route shortcut helper that should stay visible from the compact shortcut-first bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper surfaced when repo root or saved summary is already pinned."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Next-step matrix helper that remains adjacent when the route widens slightly again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Kind "file" -Purpose "Broader suite-router handoff helper that remains available from the compact shortcut-first bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Replay-route helper surfaced when the shortcut-first bridge widens back out."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Pinned bundle-first helper used when the route should stay on the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map that remains the later-stage fallback after the shortcut-first bridge narrows enough."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1" -Kind "file" -Purpose "Fresh safe-route replay wrapper surfaced from the compact shortcut-first bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1" -Kind "file" -Purpose "Reuse-current-output safe-route wrapper surfaced from the compact shortcut-first bridge.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'suite_router_shortcut_surface_check = $suiteRouterShortcutSurfaceCheckCommand' -Purpose "Shortcut-first helper keeps its dedicated fail-fast checker wired into the helper command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'suite_router_attached_html_surface_check = $suiteRouterAttachedHtmlSurfaceCheckCommand' -Purpose "Shortcut-first helper keeps the adjacent suite-router attached-html checker wired beside the compact route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'suite_router_attached_html_quickstart_note_path = ''docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md''' -Purpose "Shortcut-first helper keeps the adjacent suite-router attached-html quickstart note pinned beside the compact bridge."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand' -Purpose "Shortcut-first helper keeps the broader Google-shaped attached-page surface checker wired beside the narrower issue-specific checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'google_attached_html_asset_audit = $googleAttachedHtmlAssetClosureCommand' -Purpose "Shortcut-first helper keeps the deeper Google-style asset audit surfaced beside the broader Google-shaped checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand' -Purpose "Shortcut-first helper keeps the issue-specific Google attached-page checker surfaced before the route narrows again."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'google_attached_html_entrypoint = Format-HelperCommand -ScriptName ''show_google_issue3_google_attached_html_entrypoint.ps1'' -Arguments $bundleArguments' -Purpose "Shortcut-first helper keeps the issue-specific Google attached-page bridge surfaced beside the broader and narrower fail-fast checks."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'google_attached_html_entrypoint_note_path = ''docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md''' -Purpose "Shortcut-first helper keeps the issue-specific Google attached-page entrypoint note pinned beside the printed helper surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'replay_route_shortcut = Format-HelperCommand -ScriptName ''show_google_issue3_replay_route_shortcut_entrypoint.ps1'' -Arguments $bundleArguments' -Purpose "Shortcut-first helper keeps the narrower replay-route bridge wired into the compact follow-up surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host (("  7. Shortcut surface:       {0}") -f $entrypoint.helper_commands.suite_router_shortcut_surface_check)' -Purpose "Printed shortcut-first route keeps the dedicated checker visible before the attached-page and replay follow-up ladder."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host (("  9. Attached quick check:   {0}") -f $entrypoint.helper_commands.suite_router_attached_html_surface_check)' -Purpose "Printed shortcut-first route keeps the adjacent attached-html checker visible beside the compact bridge."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host ((" 12. Google surface check:   {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)' -Purpose "Printed shortcut-first route keeps the broader Google-shaped checker visible before the deeper asset audit and narrower issue-specific checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host ((" 13. Google asset audit:     {0}") -f $entrypoint.helper_commands.google_attached_html_asset_audit)' -Purpose "Printed shortcut-first route keeps the deeper Google-style asset audit visible before the narrower issue-specific checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host ((" 14. Issue-specific check:   {0}") -f $entrypoint.helper_commands.google_issue3_attached_html_surface_check)' -Purpose "Printed shortcut-first route keeps the issue-specific Google checker visible before the narrower issue #3 bridge takes over."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host ((" 15. Google entrypoint:      {0}") -f $entrypoint.helper_commands.google_attached_html_entrypoint)' -Purpose "Printed shortcut-first route keeps the issue-specific Google attached-page bridge visible before the attached-page shortcut and replay-shortcuts ladder."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host ((" 18. Replay-route shortcut:  {0}") -f $entrypoint.helper_commands.replay_route_shortcut)' -Purpose "Printed shortcut-first route keeps the replay-route shortcut bridge visible beside replay shortcuts."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host (("Suite-router attached:   {0}") -f $entrypoint.suite_router_attached_html_quickstart_note_path)' -Purpose "Printed shortcut-first note surface keeps the adjacent attached-html quickstart note visible beside the compact bridge."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'Use google_attached_html_asset_audit when missing sidecars or local asset drift might explain the current Google-shaped attached-page failure and you want the deeper audit reprinted before the narrower issue-specific checker or bridge takes over.' -Purpose "Usage notes preserve when to reopen the deeper Google-style asset audit from the compact shortcut-first surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Snippet 'Use replay_shortcuts as the default next helper when no pinned bundle inputs, saved summary, or non-default repo root need to stay visible first.' -Purpose "Usage notes preserve the default narrowing path from the shortcut-first bridge into replay shortcuts."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_next_steps_validation_surface.ps1' -Purpose "Replay quickstart keeps the suite-router next-steps fail-fast checker visible before the executable matrix is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_next_steps_validation_surface.ps1 -RepoRoot ''<repo-root>''' -Purpose "Replay quickstart preserves the suite-router next-steps fail-fast checker when the replay is running from a non-default checkout."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_next_steps_validation_surface.ps1' -Purpose "Replay-discovery handoff keeps the suite-router next-steps fail-fast checker visible before the executable matrix is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_next_steps.ps1' -Purpose "Replay-discovery handoff keeps the suite-router next-step matrix visible after the fail-fast checker."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_shortcut_first_entrypoint_validation_surface.ps1' -Purpose "Companion bridge note still reprints the live shortcut-first checker command."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_attached_html_quickstart_validation_surface.ps1' -Purpose "Companion bridge note still reprints the live attached-html checker command beside the compact shortcut bridge."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1' -Purpose "Companion bridge note keeps the broader Google-shaped attached-page checker visible from the compact suite-router route."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle' -Purpose "Companion bridge note keeps the deeper Google-style asset audit visible from the compact suite-router route."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Snippet 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md' -Purpose "Companion bridge note keeps the issue-specific Google attached-page entrypoint note visible beside the broader checker and asset audit."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1' -Purpose "Companion bridge note still surfaces the issue-specific Google attached-page entrypoint from the compact suite-router route."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Purpose "Companion bridge note still surfaces the replay-route shortcut helper from the compact suite-router route.")
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
        profile = "google-issue3-suite-router-shortcut-first-entrypoint"
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

Write-Host "Google issue #3 suite-router shortcut-first entrypoint surface check"
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
    Write-Host "Google issue #3 suite-router shortcut-first entrypoint surface is intact."
    exit 0
}

Write-Host (("Missing {0} suite-router shortcut-first path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing shortcut note, helper output contract, attached-page companion helper, replay-route shortcut, or safe-route fallback before trusting the compact issue #3 shortcut-first bridge."
exit 1
