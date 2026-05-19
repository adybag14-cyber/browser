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
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Replay quickstart note that points issue #3 follow-up into the attached localhost helper ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Primary read-first note for the Windows replay attached-html quickstart route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Broader Windows full-use route note reopened before the replay quickstart narrows into attached-page helpers."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Windows full-use to validation-router bridge note reused by the replay attached-html route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Windows-first attached-page catalog quickstart note kept beside the replay attached-html route."),
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Validation-router attached-html quickstart note kept visible before the replay route narrows further."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md" -Kind "file" -Purpose "Attached-html change-area quickstart note surfaced directly from the replay attached-html ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Compact top-level attached-page quickstart note used immediately after the replay route reopens the attached-page chain."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Broader top-level attached-page bridge note kept beside the compact top-level quickstart."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-page catalog quickstart note referenced by the replay attached-html helper chain."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md" -Kind "file" -Purpose "Top-level attached-page companion-note map kept visible beside the replay attached-html helper chain before narrower shortcuts take over."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Suite-catalog-to-top-level attached-html catalog quickstart note surfaced from the replay attached-html helper chain."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Top-level shortcut bridge note kept visible before the replay route drops into the narrower shortcut helpers."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog entrypoints guide kept visible before the replay route falls back into the narrower attached-page bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-page bridge note reopened before the replay route collapses into shorter shortcuts."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-page quickstart note used on the replay path before shortcut-only follow-up."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Suite-router shortcut bridge note kept nearby when the route narrows beyond the attached-page ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Replay-route shortcut bridge note kept visible before the route narrows into the shorter attached-page shortcut surface."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Google-shaped attached-page validation flow note kept visible when the replay stays on the Google-style attached-html lane."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-page bridge note kept visible when the replay narrows beyond the broader Google-shaped attached-html lane but before bundle-only or shortcut-first follow-up."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned three-page attached-html bundle reference note kept nearby when the replay stays on the locked compatibility set."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Compact bundle-suite surface note kept nearby when the replay re-enters the locked compatibility bundle before narrowing further."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md" -Kind "file" -Purpose "Pinned bundle proof note kept nearby when the replay-side attached-html route narrows into the fixed-list proof path."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Longer Windows validation-chain note kept aligned with the replay attached-html route."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay attached-html quickstart helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast route checker that should stay aligned with the replay-side quickstart chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1" -Kind "file" -Purpose "Windows full-use attached-page route helper reopened ahead of the replay attached-html ladder."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1" -Kind "file" -Purpose "Windows full-use to validation-router bridge helper used before the replay route narrows further."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Windows-first attached-page catalog quickstart helper used before the replay route narrows further."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Validation-router attached-html quickstart helper reused by the replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Attached-html change-area quickstart helper reopened from the replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Compact top-level attached-html quickstart helper surfaced by the replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Broader top-level attached-html bridge helper kept visible from the replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html catalog quickstart helper surfaced by the replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Suite-catalog-to-top-level attached-html catalog quickstart helper surfaced from the replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Suite-catalog entrypoints helper kept visible before the replay route falls back into the narrower attached-page bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Suite-catalog attached-page bridge helper surfaced from the replay route."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-page validation flow helper kept visible beside the Google-shaped attached-html lane from the replay route."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast launcher companion checker that should stay visible once the replay helper surfaces the sidecar-first attached-pages route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Kind "file" -Purpose "Launcher companion helper that keeps the wrapper-backed sidecar audit route and the pinned proof-only bundle follow-up visible from the replay ladder."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-shaped attached-page validation flow helper surfaced when the replay stays on the Google-style attached-html lane."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-page bridge helper kept visible when the replay narrows beyond the broader Google-shaped attached-html lane but before bundle-only or shortcut-first follow-up."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-page quickstart helper surfaced from the replay route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut bridge helper surfaced before the replay route collapses into the narrower attached-page shortcut."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Replay-route shortcut helper surfaced before the replay route collapses into the narrower attached-page shortcut."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Shortest attached-page shortcut helper used after the replay route narrows far enough."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Replay-shortcuts helper used after the replay attached-html route narrows far enough."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact bundle-suite surface helper surfaced before the replay route narrows into the bundle-first branch."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Proof-entrypoint surface checker surfaced directly from the replay-side ladder when proof-only bundle follow-up matters."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Kind "file" -Purpose "Proof-entrypoint helper surfaced directly from the replay-side ladder when proof-only bundle follow-up matters."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper used when replay stays pinned to the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper used when repo root, summary, or pinned bundle paths are already known."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Broader safe-route helper reopened only after the replay attached-html route has already narrowed follow-up."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1" -Kind "file" -Purpose "Bundle-aware attached-page flow helper reused by the replay route's pinned bundle branch."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Bundle-aware attached-page runner reused by the replay route's pinned bundle branch.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1' -Purpose "Replay quickstart keeps the suite-catalog fail-fast checker in its read-first discovery block before the broader suite-catalog helper is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_catalog_entrypoints.ps1' -Purpose "Replay quickstart keeps the suite-catalog helper visible in its read-first discovery block before the replay narrows again."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet '.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle' -Purpose "Replay quickstart keeps the compact attached-bundle re-entry visible from the broader top-level router before the route collapses into narrower helpers."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Purpose "Replay quickstart keeps the compact attached-bundle suite surface in the pinned bundle route before bundle-first replay takes over."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1' -Purpose "Replay quickstart keeps the bundle-first helper surfaced in the pinned attached-bundle route before the delegated runner."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Snippet 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md' -Purpose "Replay attached-html quickstart keeps the pinned bundle proof companion note visible once the route narrows toward the fixed-list proof path."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1' -Purpose "Replay attached-html quickstart keeps the dedicated Google attached-page surface checker visible before the narrower issue-specific Google bridge or shortcut-first follow-up takes over."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1' -Purpose "Replay attached-html quickstart keeps the broader Google attached-page flow helper visible after the dedicated Google surface check and before narrower issue-specific or shortcut-only follow-up."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1' -Purpose "Replay attached-html quickstart keeps the issue-specific Google attached-page bridge visible before the compact bundle suite or narrower shortcut follow-up takes over."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Purpose "Replay attached-html quickstart keeps the proof-entrypoint surface checker visible before the proof-only bundle follow-up is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Purpose "Replay attached-html quickstart keeps the proof-entrypoint helper visible beside the compact bundle suite surface and bundle-first follow-up."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Purpose "Top-level shortcut bridge keeps the replay-attached quickstart visible before the route narrows back into shortcut-only follow-up."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Purpose "Top-level shortcut bridge keeps the replay-route shortcut helper visible after the replay-attached quickstart stays in view."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1' -Purpose "Replay-route shortcut bridge keeps its fail-fast checker visible before the route drops into the shorter attached-page shortcut surface."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1' -Purpose "Replay-route shortcut bridge keeps the replay-to-Windows bridge visible before the route collapses back into the shorter attached-page helper chain."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $sharedArguments" -Purpose "Replay quickstart helper keeps the suite-catalog helper wired into its replay-side command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot" -Purpose "Replay quickstart helper keeps the dedicated Google attached-page surface checker wired into its replay-side command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "google_attached_html_validation_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot" -Purpose "Replay quickstart helper keeps the broader Google attached-page flow helper wired into its replay-side command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $sharedArguments" -Purpose "Replay quickstart helper keeps the issue-specific Google attached-page bridge wired into its replay-side command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedArguments" -Purpose "Replay quickstart helper keeps the compact attached-bundle surface wired into its replay-side command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "attached_bundle_proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $routeSurfaceArguments" -Purpose "Replay quickstart helper keeps the proof-entrypoint surface checker wired into its replay-side command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "attached_bundle_proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $sharedArguments" -Purpose "Replay quickstart helper keeps the proof-entrypoint helper wired into its replay-side command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "attached_pages_launcher_companion_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $routeSurfaceArguments" -Purpose "Replay quickstart helper keeps the launcher companion surface checker wired into its replay-side command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet "attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments" -Purpose "Replay quickstart helper keeps the launcher companion helper wired into its replay-side command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Suite-catalog guide:      {0}") -f $helper.commands.suite_catalog_entrypoints)' -Purpose "Replay quickstart helper output prints the suite-catalog helper so the broader discovery surface stays visible before the route narrows again."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Google attached check:    {0}") -f $helper.commands.google_attached_html_surface_check)' -Purpose "Replay quickstart helper output prints the dedicated Google attached-page surface checker before the replay narrows into the issue-specific bridge or the shorter shortcut ladder."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Google attached flow:     {0}") -f $helper.commands.google_attached_html_validation_flow)' -Purpose "Replay quickstart helper output prints the broader Google attached-page flow helper before the replay narrows into the issue-specific bridge or shorter shortcut-only follow-up."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Google issue bridge:      {0}") -f $helper.commands.google_attached_html_entrypoint)' -Purpose "Replay quickstart helper output prints the issue-specific Google attached-page bridge before the route narrows into bundle-only or shortcut-only follow-up."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Bundle suite surface:     {0}") -f $helper.commands.attached_bundle_suite_surface)' -Purpose "Replay quickstart helper output prints the compact attached-bundle surface before the route drops into the bundle-first helper."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Bundle proof check:       {0}") -f $helper.commands.attached_bundle_proof_surface_check)' -Purpose "Replay quickstart helper output prints the proof-entrypoint surface checker before the route narrows into proof-only bundle follow-up."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Bundle proof entry:      {0}") -f $helper.commands.attached_bundle_proof_entrypoint)' -Purpose "Replay quickstart helper output prints the proof-entrypoint helper before the route narrows into proof-only bundle follow-up."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Launcher surface check:   {0}") -f $helper.commands.attached_pages_launcher_companion_surface_check)' -Purpose "Replay quickstart helper output prints the launcher companion surface checker so the sidecar-first attached-pages contract stays visible from the replay ladder."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Launcher companion:       {0}") -f $helper.commands.attached_pages_launcher_companion)' -Purpose "Replay quickstart helper output prints the launcher companion helper so the wrapper-backed sidecar-audit route stays visible from the replay ladder."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Use attached_bundle_suite_surface when the replay is already close to the known three-page compatibility bundle but you still want the compact suite-level surface printed before the narrower bundle-first helper or the delegated bundle flow takes over.' -Purpose "Replay quickstart helper notes preserve when to prefer the compact attached-bundle surface before the narrower bundle-first branch."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Use attached_bundle_proof_entrypoint when the replay is already pinned to the known three-page compatibility bundle and you want the proof-only follow-up helper kept visible beside the proof surface checker before the route widens again.' -Purpose "Replay quickstart helper notes preserve when to prefer the proof-entrypoint helper beside the pinned bundle route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Use suite_catalog_entrypoints when you want the wider suite-catalog route map reprinted before the replay falls back into the narrower attached-page bridge.' -Purpose "Replay quickstart helper notes preserve when to widen back into the suite-catalog route before the replay narrows again."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Use google_attached_html_surface_check when branch state may have moved and the replay should fail fast on the dedicated Google-shaped attached-page lane before reopening the narrower Google helper from this same replay ladder.' -Purpose "Replay quickstart helper notes preserve when to rerun the dedicated Google attached-page surface checker before the route narrows into the issue-specific bridge."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Use google_attached_html_validation_flow when the current attached inputs are already Google-shaped and you want the dedicated attached-page asset-closure and preferred-initial-page helper visible after the dedicated Google-shaped attached-page surface check and before the route narrows back into the suite-router sidecar or the shorter attached-page shortcut.' -Purpose "Replay quickstart helper notes preserve when to keep the broader Google attached-page flow visible before the compact helper chain narrows."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Snippet 'Use google_attached_html_entrypoint when the replay already needs the issue-specific Google attached-html bridge kept visible after the dedicated Google attached-page flow and before the compact bundle suite or the narrower shortcuts take over.' -Purpose "Replay quickstart helper notes preserve when to reopen the issue-specific Google attached-page bridge before the route narrows into bundle-only or shortcut-only follow-up."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet "proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $surfaceCheckArguments" -Purpose "Launcher companion helper keeps the proof-entrypoint surface checker wired into its command map so preflight can bridge straight into proof-only follow-up."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet "proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $wrapperArguments" -Purpose "Launcher companion helper keeps the proof-entrypoint helper wired into its command map so preflight can bridge straight into proof-only follow-up."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet 'Write-Host (("  Surface check:      {0}") -f $helper.helper_commands.proof_surface_check)' -Purpose "Launcher companion helper output prints the proof-entrypoint surface checker once sidecar and asset preflight finishes."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet 'Write-Host (("  Proof entrypoint:   {0}") -f $helper.helper_commands.proof_entrypoint)' -Purpose "Launcher companion helper output prints the proof-entrypoint helper once sidecar and asset preflight finishes."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet 'Use proof_surface_check and proof_entrypoint when the current attached-page replay is already pinned to the known three-page compatibility bundle and you want the proof-only checker and helper pair reprinted directly from the launcher-companion surface before widening back into the broader replay helper chain.' -Purpose "Launcher companion helper notes preserve when to bridge directly from launcher preflight into the pinned proof route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Snippet 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md' -Purpose "Launcher companion helper keeps the pinned proof companion note visible beside the sidecar-first route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet "windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments" -Purpose "Top-level shortcut helper keeps the replay-attached quickstart wired into its helper map before the route narrows further."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host (("  12. Windows replay quick:      {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)' -Purpose "Top-level shortcut helper prints the replay-attached quickstart in its numbered ladder before narrower shortcut follow-up takes over."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Snippet 'Write-Host (("  Windows replay quick:   {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)' -Purpose "Top-level shortcut helper prints the replay-attached quickstart again in its companion-helper summary so the attached localhost bridge stays visible."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Snippet 'replay_shortcuts_windows_replay_attached_html_bridge = $replayShortcutsWindowsReplayAttachedHtmlBridgeCommand' -Purpose "Replay-route shortcut helper keeps the replay-to-Windows bridge wired into its helper map before the route collapses into shorter attached-page follow-up."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Snippet 'Write-Host (("  8. Replay-to-Windows: {0}") -f $entrypoint.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)' -Purpose "Replay-route shortcut helper prints the replay-to-Windows bridge in its numbered ladder before the route collapses into shorter attached-page follow-up."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Snippet 'Write-Host (("  Replay-to-Windows:    {0}") -f $entrypoint.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)' -Purpose "Replay-route shortcut helper prints the replay-to-Windows bridge again in its companion-helper summary so the Windows replay bridge stays visible."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Snippet 'Write-Host (("  Replay bridge check:  {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_surface_check)' -Purpose "Replay-route shortcut helper prints the replay-attached quickstart checker in its companion-helper summary so the replay-side contract can still fail fast before widening back out."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Snippet 'Write-Host (("  Windows replay quick: {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)' -Purpose "Replay-route shortcut helper prints the replay-attached quickstart in its companion-helper summary so the Windows replay ladder stays visible beside the shortcut route.")
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
        profile = "google-issue3-windows-replay-attached-html-quickstart"
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

Write-Host "Google issue #3 Windows replay attached-html quickstart surface check"
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
    Write-Host "Google issue #3 Windows replay attached-html quickstart surface is intact, including the suite-catalog fail-fast discovery block, the replay-side helper contract, the dedicated Google attached-page surface checker and flow helper, the issue-specific Google attached-page bridge, the compact attached-bundle surface, the executable proof-entrypoint checker/helper pair, the launcher-companion proof bridge, the top-level shortcut handoff, the replay-route shortcut bridge, the pinned proof-only bundle follow-up, the bundle-first replay branch, and the broader attached-page fallbacks that keep the shorter replay note honest."
    exit 0
}

Write-Host (("Missing {0} Windows replay attached-html quickstart path or source-contract check(s).") -f $missing.Count)
Write-Host "Repair the missing route note, helper, dedicated Google attached-page surface checker or flow helper, issue-specific Google attached-page bridge, suite-catalog fail-fast block, attached-bundle surface, executable proof-entrypoint checker/helper pair, launcher-companion proof bridge, top-level shortcut handoff, replay-route shortcut bridge, proof-only bundle follow-up, bundle-first route, or replay-side helper-output contract before trusting the issue #3 Windows replay attached-html quickstart."
exit 1