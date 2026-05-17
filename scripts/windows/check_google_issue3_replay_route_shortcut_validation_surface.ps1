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

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$references = @(
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Kind "file" -Purpose "Replay-discovery note that keeps the broader issue #3 ladder visible before the replay-route shortcut narrows follow-up.")
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Written companion note for the replay-route shortcut helper.")
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Suite-router shortcut bridge note kept nearby when the replay-route shortcut widens back out.")
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog guide that remains a broader fallback beside the replay-route shortcut.")
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Google-shaped attached-page validation-flow note surfaced directly from the replay-route shortcut surface.")
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Replay-shortcuts-to-Windows-replay bridge note surfaced directly from the replay-route shortcut surface.")
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-page quickstart note guarded by the replay-route shortcut surface.")
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned three-page compatibility bundle reference note surfaced from the replay-route shortcut surface.")
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain note kept nearby when the replay-route shortcut widens back out.")
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that can still feed the replay-route shortcut path.")
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Primary replay-route shortcut helper that this checker validates.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Broader replay-route helper that feeds the replay-route shortcut surface.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Attached-page shortcut helper surfaced as the default next branch from the replay-route shortcut.")
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-page validation flow helper surfaced from the replay-route shortcut surface.")
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-shaped attached-page flow helper surfaced from the replay-route shortcut surface.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Replay-shortcuts helper surfaced from the replay-route shortcut surface.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1" -Kind "file" -Purpose "Replay-shortcuts bridge into the Windows replay attached-page quickstart surfaced from the replay-route shortcut surface.")
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the narrower Windows replay attached-page ladder surfaced from the replay-route shortcut surface.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Windows replay attached-page quickstart helper surfaced from the replay-route shortcut surface.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Broader shortcut-first bridge surfaced from the replay-route shortcut surface.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Compact next-step matrix surfaced from the replay-route shortcut surface.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper surfaced when repo root, summary, or pinned bundle inputs already matter.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper surfaced when the replay should stay pinned to the known three-page compatibility set.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map reopened only after the replay-route shortcut has clarified the next branch.")
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1" -Kind "file" -Purpose "Fresh safe replay helper surfaced from the replay-route shortcut surface.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1" -Kind "file" -Purpose "Reuse-current-outputs helper surfaced from the replay-route shortcut surface.")
)

$results = foreach ($reference in $references) {
    $fullPath = Join-Path $resolvedRepoRoot $reference.Path
    $exists = if ($reference.Kind -eq "directory") {
        Test-Path -LiteralPath $fullPath -PathType Container
    } else {
        Test-Path -LiteralPath $fullPath -PathType Leaf
    }

    [pscustomobject]@{
        Path = $reference.Path
        Kind = $reference.Kind
        Purpose = $reference.Purpose
        Exists = [bool]$exists
    }
}

$missing = @($results | Where-Object { -not $_.Exists })

if ($Json) {
    [ordered]@{
        profile = "google-issue3-replay-route-shortcut"
        repo_root = $resolvedRepoRoot
        checked_count = @($results).Count
        missing_count = @($missing).Count
        references = @($results)
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

foreach ($result in $results) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host (("[{0}] {1}") -f $status, $result.Path)
    Write-Host (("  {0}") -f $result.Purpose)
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Google issue #3 replay-route shortcut surface is intact."
    exit 0
}

Write-Host (("Missing {0} replay-route shortcut path(s).") -f $missing.Count)
Write-Host "Repair the missing replay-route shortcut note, attached-page helper, replay-side bridge, bundle-aware follow-up, or safe-route companion before trusting the issue #3 replay-route shortcut path."
exit 1