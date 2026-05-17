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
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_ENTRYPOINT.md" -Kind "file" -Purpose "Primary replay-route shortcut entrypoint note that should stay aligned with the compact helper output."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Replay-route shortcut bridge note that keeps the shorter attached-page and replay follow-up route visible."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Kind "file" -Purpose "Replay discovery note kept nearby when the compact replay-route helper widens back out."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Suite-router shortcut bridge note surfaced from the replay-route shortcut helper chain."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog guide note kept visible from the replay-route shortcut surface."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Google-shaped attached-page validation flow note surfaced from the compact replay-route surface."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Replay-shortcuts to Windows replay attached-page bridge note surfaced from the compact replay-route route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Windows replay attached-page quickstart note surfaced from the compact replay-route route."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned attached-page bundle reference note kept nearby when the compact replay-route route stays on the known three-page compatibility set."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Compact bundle-side surface note kept nearby when the replay-route shortcut stays pinned to the three-page compatibility set."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md" -Kind "file" -Purpose "Written replay-route bundle-first bridge note that stays aligned with the bundle-aware replay-route shortcut follow-up."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain note that remains the later fallback after the replay-route shortcut narrows enough."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Broader Windows headed runbook reopened when the compact replay-route branch needs the larger Windows-first context again."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose attached-page and bundle change-area commands feed the replay-route shortcut surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Broader Google input flow helper that can widen back out from the replay-route shortcut surface."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-page localhost flow helper surfaced from the replay-route shortcut surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-shaped attached-page validation flow helper surfaced from the replay-route shortcut surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Replay-route helper that should precede this narrower replay-route shortcut surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Replay-route shortcut helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Attached-page shortcut helper surfaced from the replay-route shortcut surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Suite-router shortcut-first helper surfaced from the replay-route shortcut surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper surfaced from the replay-route shortcut surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1" -Kind "file" -Purpose "Replay-shortcuts to Windows replay attached-page bridge helper surfaced from the replay-route shortcut surface."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Replay-side fail-fast checker surfaced from the replay-route shortcut surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Windows replay attached-page quickstart helper surfaced from the replay-route shortcut surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact bundle-side helper surfaced before the replay-route bundle-first bridge and bundle-first helper take over."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Executable next-step matrix surfaced from the replay-route shortcut surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper surfaced when repo root, summary, or pinned bundle inputs already matter."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper surfaced when the replay-route shortcut should stay pinned to the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_bundle_first_bridge.ps1" -Kind "file" -Purpose "Compact replay-side bundle-first bridge helper surfaced from the replay-route shortcut surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map surfaced after the replay-route shortcut has narrowed the current replay enough."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1" -Kind "file" -Purpose "Fresh safe-route replay helper surfaced from the replay-route shortcut surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1" -Kind "file" -Purpose "Existing-output safe-route wrapper surfaced from the replay-route shortcut surface.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Snippet '$replayRouteShortcutSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_issue3_replay_route_shortcut_validation_surface.ps1'' -RepoRootOverride $RepoRoot' -Purpose "Replay-route shortcut helper wires its dedicated fail-fast checker into the shared command surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Snippet 'replay_route_shortcut_surface_check = $replayRouteShortcutSurfaceCheckCommand' -Purpose "Replay-route shortcut helper exposes its dedicated checker through the printed route and companion helper maps."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Snippet 'replay_shortcuts_windows_replay_attached_html_bridge = $replayShortcutsWindowsReplayAttachedHtmlBridgeCommand' -Purpose "Replay-route shortcut helper keeps the replay-to-Windows attached-page bridge wired into the compact follow-up surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Snippet 'Write-Host (("  2. Shortcut check:    {0}") -f $entrypoint.top_level_commands.replay_route_shortcut_surface_check)' -Purpose "Printed replay-route bridge keeps the dedicated checker visible before attached-page or replay-shortcuts follow-up."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Snippet 'Write-Host (("  8. Replay-to-Windows: {0}") -f $entrypoint.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)' -Purpose "Printed replay-route bridge keeps the replay-to-Windows attached-page bridge visible before the route narrows again."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Snippet 'Write-Host (("  Shortcut surface:     {0}") -f $entrypoint.helper_commands.replay_route_shortcut_surface_check)' -Purpose "Companion helper output reprints the dedicated replay-route shortcut checker inside the compact helper surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Snippet 'Use replay_route_shortcut_surface_check before trusting this compact replay-route branch after branch moves or from another checkout' -Purpose "Usage notes explain when to rerun the replay-route shortcut checker before trusting the compact route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Snippet 'Use attached_html_shortcut as the default next helper whenever no explicit bundle inputs are already pinned' -Purpose "Usage notes preserve the default narrowing path from replay-route shortcut into the shorter attached-page helper."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Snippet 'Use replay_shortcuts_windows_replay_attached_html_bridge when the replay-route shortcut still needs the replay-side surface check' -Purpose "Usage notes preserve the replay-to-Windows bridge follow-up from the compact replay-route surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Snippet 'Use attached_bundle_first whenever explicit InputPath values are already pinned or when the replay should stay on the known three-page compatibility set' -Purpose "Usage notes preserve the bundle-pinned fallback beside the replay-route shortcut ladder.")
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
        profile = "google-issue3-replay-route-shortcut"
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

Write-Host "Google issue #3 replay-route shortcut surface check"
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
    Write-Host "Google issue #3 replay-route shortcut surface is intact."
    exit 0
}

Write-Host (("Missing {0} replay-route shortcut path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing replay-route note, helper output contract, attached-page helper, replay-side bridge, bundle-aware follow-up, or safe-route companion before trusting this compact issue #3 replay-route branch."
exit 1