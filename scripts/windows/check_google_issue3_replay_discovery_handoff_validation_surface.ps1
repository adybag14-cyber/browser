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
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Kind "file" -Purpose "Replay-discovery handoff note that this checker protects."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Broader Windows runbook that can reopen the attached localhost route before the replay-discovery handoff narrows again."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Windows full-use attached-html route note that stays aligned with the replay-discovery handoff's broader branch."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Windows-to-validation-router attached-html bridge note kept visible by the replay-discovery handoff."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Windows full-use attached-html catalog quickstart note surfaced before the replay-discovery handoff narrows further."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Compact replay quickstart note that remains adjacent to the replay-discovery handoff."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-html quickstart note that should remain easy to reopen from the handoff."),
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Validation-router attached-html quickstart note kept nearby when the route reopens from the broader router."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached-html validation-flow note that the replay-discovery handoff should keep easy to reopen."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint note that the replay-discovery handoff should keep visible for the narrower route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html quickstart note that remains part of the replay-discovery handoff chain."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Top-level attached-html bridge note that the replay-discovery handoff can widen back into."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html catalog quickstart note surfaced by the replay-discovery handoff."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Suite-catalog top-level attached-html catalog quickstart note kept adjacent to the replay-discovery handoff's narrower route."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_COMPANION_NOTES.md" -Kind "file" -Purpose "Top-level attached-html companion notes that remain a nearby fallback from the replay-discovery handoff."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-html quickstart note reopened from the replay-discovery handoff once the route narrows again."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-html bridge note kept visible by the replay-discovery handoff."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Broader suite-catalog guide note that remains the top-level fallback beside the replay-discovery handoff."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Replay-shortcuts bridge note that remains adjacent to the replay-side attached-html route from the handoff."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_QUICKSTART_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Replay quickstart shortcut note that stays near the narrower replay helper family reopened from the handoff."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Replay-route shortcut note that remains adjacent when the handoff route widens into replay route."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md" -Kind "file" -Purpose "Suite-router next-steps note that should stay aligned with the compact chooser surfaced from replay discovery."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Longer Windows validation-chain note that remains the broader fallback after the replay-discovery handoff narrows enough."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose change-area commands feed the replay-discovery handoff."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1" -Kind "file" -Purpose "Windows full-use attached-html route helper that remains part of the broader replay-discovery handoff chain."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast route checker for the Windows full-use attached-html branch reopened from the handoff."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1" -Kind "file" -Purpose "Windows-to-validation-router attached-html bridge helper kept visible by the replay-discovery handoff."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Windows full-use attached-html catalog quickstart helper kept adjacent before the route narrows again."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Replay-side attached-html quickstart surface checker that remains part of the handoff's fail-fast ladder."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-html quickstart helper reopened by the replay-discovery handoff."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Validation-router attached-html quickstart helper that remains part of the compact replay-discovery chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Attached-html change-area quickstart helper that keeps the narrower attached-page route visible from the handoff."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-html validation-flow helper surfaced by the replay-discovery handoff before the route narrows again."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Broader Google-shaped attached-html surface checker that the replay-discovery handoff should keep visible before the issue-specific checker."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint surface checker that should remain visible from the replay-discovery handoff's narrower route."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Dedicated Google attached-html validation-flow helper reopened by the replay-discovery handoff."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint helper that remains part of the replay-discovery handoff's narrower route."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_suite_router_handoff_validation_surface.ps1" -Kind "file" -Purpose "Compact suite-router handoff checker surfaced before the handoff helper is trusted."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Kind "file" -Purpose "Compact suite-router handoff helper surfaced directly from the replay-discovery note."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_suite_router_next_steps_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast suite-router next-steps checker surfaced before the compact chooser is trusted."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Executable next-step matrix helper surfaced from the replay-discovery note."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html quickstart helper that stays in the replay-discovery handoff chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Top-level attached-html bridge helper reopened before the route widens again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-html catalog quickstart helper kept adjacent to the replay-discovery handoff."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut-first issue 3 bridge that the replay-discovery handoff reopens before narrower replay helpers."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Suite-catalog top-level attached-html catalog quickstart helper kept visible by the replay-discovery handoff."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-html quickstart helper surfaced when the handoff route narrows again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Broader suite-catalog entrypoint helper that remains available from the replay-discovery handoff."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Suite-catalog attached-html bridge helper kept adjacent to the replay-discovery handoff."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Attached-html shortcut helper that remains part of the narrower replay helper family reopened from the handoff."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1" -Kind "file" -Purpose "Replay-shortcuts bridge helper that remains adjacent when the replay-side attached-html route narrows into shortcut helpers."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_replay_route_shortcut_validation_surface.ps1" -Kind "file" -Purpose "Replay-route shortcut surface checker that should stay visible before the narrower replay-route bridge is trusted."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Replay-route helper surfaced once the replay-discovery handoff widens beyond the narrower attached-page route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Replay-route shortcut helper kept adjacent to the replay-discovery handoff's replay-route branch."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Replay-shortcuts helper that remains the narrower stable helper surface reopened from the handoff."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map that remains the later fallback after the replay-discovery handoff narrows enough."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1" -Kind "file" -Purpose "Fresh safe-route replay helper surfaced once the route widens back into the runner-patch path."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1" -Kind "file" -Purpose "Reuse-current-outputs wrapper helper surfaced when the handoff re-enters the safe-route stack with an existing summary."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_replay_discovery_handoff_validation_surface.ps1" -Kind "file" -Purpose "Replay-discovery handoff surface checker that this profile validates.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1' -Purpose "Replay-discovery handoff keeps the broader Google-shaped attached-html checker visible before the issue-specific checker is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1' -Purpose "Replay-discovery handoff keeps the issue-specific Google attached-html checker visible after the broader checker."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_next_steps_validation_surface.ps1' -Purpose "Replay-discovery handoff keeps the suite-router next-steps fail-fast checker visible before the compact chooser is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_next_steps.ps1' -Purpose "Replay-discovery handoff keeps the executable next-step matrix visible when the route still needs the compact chooser."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1' -Purpose "Replay-discovery handoff keeps the replay-route shortcut checker visible before the narrower replay-route bridge is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Purpose "Replay-discovery handoff keeps the replay-route shortcut entrypoint visible once the replay widens back out from the compact chooser."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet 'suite_router_surface_check = $suiteRouterSurfaceCheckCommand' -Purpose "Live next-step helper still wires in the suite-router surface checker that this replay-discovery checker expects."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet 'google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand' -Purpose "Live next-step helper still wires in the broader Google-shaped checker that this replay-discovery checker expects."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet 'google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand' -Purpose "Live next-step helper still wires in the issue-specific checker that this replay-discovery checker expects."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet 'Write-Host (("  Surface check:            {0}") -f $helper.helper_commands.suite_router_surface_check)' -Purpose "Live next-step helper still prints the suite-router surface checker in its key helper surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet 'Write-Host (("  Google surface check:     {0}") -f $helper.helper_commands.google_attached_html_surface_check)' -Purpose "Live next-step helper still prints the broader Google-shaped checker in its key helper surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet 'Write-Host (("  Issue-specific check:     {0}") -f $helper.helper_commands.google_issue3_attached_html_surface_check)' -Purpose "Live next-step helper still prints the issue-specific checker in its key helper surface.")
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
        profile = "google-issue3-replay-discovery-handoff"
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

Write-Host "Google issue #3 replay-discovery handoff surface check"
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
    Write-Host "Google issue #3 replay-discovery handoff surface is intact."
    exit 0
}

Write-Host (("Missing {0} replay-discovery handoff path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the replay-discovery note, the suite-router next-step chooser surface, the broader and issue-specific Google attached-html checker ladder, or the replay-route shortcut bridge before trusting the read-first issue #3 handoff."
exit 1