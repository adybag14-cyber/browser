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
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Compact replay quickstart note that still anchors the suite-router next-steps handoff."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Kind "file" -Purpose "Replay-discovery handoff note that remains part of the read-first suite-router bridge into the next-step matrix."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md" -Kind "file" -Purpose "Focused suite-router next-steps note that should stay aligned with the live helper and the broader replay notes."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Suite-router shortcut bridge note that explains the shorter issue 3 handoff kept visible by the next-step matrix."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Replay-route shortcut bridge note that stays adjacent to the narrower replay-route entrypoint from the next-step matrix."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-html quickstart note surfaced when the matrix re-enters through attached localhost follow-up."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html quickstart note kept visible when the route widens back out from the matrix."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Top-level attached-html bridge note that the matrix still points to when attached-page guidance broadens."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html catalog quickstart note that stays visible beside the matrix's attached-page branch."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-html bridge note kept visible when the route reopens from the broader suite catalog."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Windows replay attached-html quickstart note that remains part of the broader replay ladder beside the next-step matrix."),
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Validation-router attached-html quickstart note kept nearby when the route is still reopening from the broader router."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint note that the next-step matrix keeps visible for the narrower attached-page route."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached-html validation-flow note surfaced beside the next-step matrix's narrower attached-page route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain note reopened when the route widens back into the wrapper-heavy helper stack."),
    (New-ValidationReference -Path "docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md" -Kind "file" -Purpose "Runner-patch decision table note used by the matrix's runner-state follow-up helper."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows runbook that remains the broader replay fallback beside the suite-router matrix."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared repo-root and attached-html helper surface used by the suite-router next-steps matrix."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose Google and attached-html change areas feed the next-step matrix."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Shortcut-first suite-router entrypoint that remains the default issue 3 handoff surfaced by the matrix."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-html quickstart helper kept visible from the next-step matrix when attached-page follow-up is already known."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Broader Google-shaped attached-html surface checker that stays visible before the narrower issue-specific route."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint surface checker that remains adjacent to the narrower attached-page route from the matrix."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-html validation-flow helper still printed by the matrix when the route is reopening from attached localhost follow-up."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Dedicated Google attached-html validation-flow helper kept visible by the matrix before the route narrows again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint helper that remains a narrower next-step option from the matrix."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Kind "file" -Purpose "Wider suite-router handoff helper that still feeds into the next-step matrix when the route has not narrowed yet."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Replay-route helper surfaced when the route widens back out from the shortcut map."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Replay-route shortcut helper that the matrix keeps visible before the broader route widens again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper surfaced by the matrix once the route is already known to stay inside issue 3."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper used when repo root, saved summary, or pinned bundle inputs already matter."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first entrypoint kept visible when the route should stay pinned to the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1" -Kind "file" -Purpose "Attached-html target bundle flow helper surfaced after the bundle-aware route from the matrix."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Bundle validation runner surfaced by the matrix after the attached bundle branch is chosen."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route entrypoint map that remains the later fallback after the matrix narrows the route enough."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1" -Kind "file" -Purpose "Fresh safe-route replay helper kept visible when the matrix needs to widen back into the runner-patch path."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1" -Kind "file" -Purpose "Reuse-current-outputs wrapper helper surfaced when the matrix re-enters the safe-route stack with existing summaries."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_runner_patch_next_step.ps1" -Kind "file" -Purpose "Runner next-step helper used once the matrix already knows the current wrapper-emitted runner state."),
    (New-ValidationReference -Path "scripts/windows/show_google_submit_timing_validation_flow.ps1" -Kind "file" -Purpose "Submit-timing validation flow that remains part of the matrix's later-stage context-preserving commands."),
    (New-ValidationReference -Path "scripts/windows/show_google_shared_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Shared Enter-order validation flow that remains part of the matrix's later-stage context-preserving commands."),
    (New-ValidationReference -Path "scripts/windows/show_google_trace_validation_flow.ps1" -Kind "file" -Purpose "Live trace validation flow that remains part of the matrix's later-stage context-preserving commands."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Suite-router next-steps helper whose dependent surface this checker validates.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_next_steps.ps1' -Purpose "Windows replay quickstart keeps the executable next-step matrix visible when the replay wants the helper to choose the fastest correct follow-up."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_handoff_validation_surface.ps1' -Purpose "Replay-discovery handoff keeps the compact suite-router handoff fail-fast checker visible before the shorter bridge is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_handoff.ps1' -Purpose "Replay-discovery handoff keeps the compact suite-router handoff helper visible when the read-first route still needs the shorter attached-page bridge before replay shortcuts or the next-step matrix."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1' -Purpose "The suite-router next-steps note keeps the Google attached-page branch pointed at the issue-specific entrypoint helper instead of drifting back to a broader flow helper."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md" -Snippet '- `docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md` for the Google-shaped attached-page bridge that stays available before the route collapses into the narrower issue `#3` helpers' -Purpose "The suite-router next-steps note keeps the Google attached-page companion note visible beside the narrower issue-specific branch."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet 'suite_router_surface_check = $suiteRouterSurfaceCheckCommand' -Purpose "Helper command maps keep the suite-router surface checker wired into the next-steps surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet 'google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand' -Purpose "Helper command maps keep the broader Google attached-html surface checker visible from the next-steps surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet 'google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand' -Purpose "Helper command maps keep the issue-specific Google attached-html surface checker visible from the next-steps surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet 'Write-Host (("  Suite-router surface:       {0}") -f $helper.suite_router_commands.suite_router_surface_check)' -Purpose "Read-first suite-router output still prints the suite-router surface check command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet 'Write-Host (("  Google attached surface:    {0}") -f $helper.suite_router_commands.google_attached_html_surface_check)' -Purpose "Read-first suite-router output still prints the broader Google attached-html surface check command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet 'Write-Host (("  Issue-specific surface:     {0}") -f $helper.suite_router_commands.google_issue3_attached_html_surface_check)' -Purpose "Read-first suite-router output still prints the issue-specific Google attached-html surface check command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet 'Write-Host (("  Surface check:            {0}") -f $helper.helper_commands.suite_router_surface_check)' -Purpose "Key helper command output still prints the suite-router surface check command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet 'Write-Host (("  Google surface check:     {0}") -f $helper.helper_commands.google_attached_html_surface_check)' -Purpose "Key helper command output still prints the broader Google attached-html surface check command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Snippet 'Write-Host (("  Issue-specific check:     {0}") -f $helper.helper_commands.google_issue3_attached_html_surface_check)' -Purpose "Key helper command output still prints the issue-specific Google attached-html surface check command.")
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
        profile = "google-issue3-suite-router-next-steps"
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

Write-Host "Google issue #3 suite-router next-steps surface check"
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
    Write-Host "Google issue #3 suite-router next-steps surface is intact."
    exit 0
}

Write-Host (("Missing {0} suite-router next-steps path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the replay quickstart or discovery handoff notes, the suite-router shortcut bridge, replay-route shortcut note, attached-html quickstarts, Google attached-html entrypoint surface, bundle-aware helpers, runner-patch helpers, or later-stage validation flow stack before trusting the next-step matrix."
exit 1