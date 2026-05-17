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
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Kind "file" -Purpose "Top-level replay discovery note that should stay aligned with the suite-router handoff surface."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Primary compact suite-router bridge note referenced by the handoff helper."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-html quickstart note that should remain visible from the handoff surface."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog guide note that the handoff helper prints beside the newer bridge surfaces."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-html bridge note that should stay aligned with the handoff output."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html quickstart note that the handoff helper keeps on the same compact bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Top-level attached-html bridge note that should remain visible from the handoff surface."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html catalog quickstart note surfaced by the handoff helper."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-html quickstart note that should remain easy to reopen from the handoff surface."),
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Validation-router attached-html quickstart note kept adjacent to the handoff output."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint note used by the narrower attached-page follow-up lane."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached-html flow guide that the handoff surface should keep easy to reopen."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Replay-route shortcut note that stays adjacent to the suite-router handoff surface."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Longer Windows validation-chain note that remains the broader fallback when the handoff route widens again."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Broader Windows runbook that can reopen the attached localhost route before the suite-router handoff narrows again."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose change-area commands feed the suite-router handoff."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Kind "file" -Purpose "Suite-router handoff helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Shortest suite-router issue #3 bridge that the handoff surface should keep visible."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-html quickstart helper surfaced from the handoff route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Executable next-step matrix helper surfaced from the handoff route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Broader suite-catalog bridge helper that the handoff surface can reopen."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Compact top-level attached-html quickstart helper that the handoff helper prints in its compact bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Broader top-level attached-html bridge helper that stays visible from the handoff output."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper that the handoff route narrows into by default."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Replay-route helper surfaced from the handoff route when the ladder widens again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Replay-route shortcut helper kept visible from the handoff surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper surfaced when repo root, summary, or pinned bundle inputs already matter."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Broader Google localhost-first validation helper surfaced from the handoff route."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast surface checker for the issue-specific Google attached-html entrypoint lane."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Dedicated Google attached-html flow helper that should remain easy to reopen from the handoff route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-html entrypoint helper that should remain available from the handoff route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Pinned attached-bundle helper surfaced when the handoff route should stay on the three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map that remains the later-stage fallback after the handoff route narrows enough.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Snippet 'suite_router_surface_check = $handoffSurfaceCheckCommand' -Purpose "Helper command maps keep the suite-router surface checker wired into the handoff helper."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Snippet 'google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand' -Purpose "Helper command maps keep the issue-specific Google attached-html surface checker visible from the handoff helper."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Snippet 'google_attached_html_flow = $googleAttachedHtmlFlowCommand' -Purpose "Helper command maps keep the dedicated Google attached-html flow helper visible from the handoff helper."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Snippet "google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments" -Purpose "Helper command maps keep the issue-specific Google attached-html entrypoint visible from the handoff helper."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Snippet 'Write-Host (("  5. Handoff surface check:         {0}") -f $handoff.bridge_sequence.suite_router_surface_check)' -Purpose "Read-first bridge output still prints the suite-router surface check command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Snippet 'Write-Host (("  6. Google attached surface check: {0}") -f $handoff.bridge_sequence.google_attached_html_surface_check)' -Purpose "Read-first bridge output still prints the issue-specific Google attached-html surface check command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Snippet 'Write-Host (("  7. Google attached flow:          {0}") -f $handoff.bridge_sequence.google_attached_html_flow)' -Purpose "Read-first bridge output still prints the dedicated Google attached-html flow command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Snippet 'Write-Host (("  9. Google attached bridge:        {0}") -f $handoff.bridge_sequence.google_attached_html_entrypoint)' -Purpose "Read-first bridge output still prints the issue-specific Google attached-html entrypoint command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Snippet 'Write-Host (("  Handoff surface check:         {0}") -f $handoff.helper_commands.suite_router_surface_check)' -Purpose "Shortcut helper output still prints the suite-router surface check command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Snippet 'Write-Host (("  Google attached surface check: {0}") -f $handoff.helper_commands.google_attached_html_surface_check)' -Purpose "Shortcut helper output still prints the issue-specific Google attached-html surface check command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Snippet 'Write-Host (("  Google attached flow:          {0}") -f $handoff.helper_commands.google_attached_html_flow)' -Purpose "Shortcut helper output still prints the dedicated Google attached-html flow command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Snippet 'Write-Host (("  Google attached bridge:        {0}") -f $handoff.helper_commands.google_attached_html_entrypoint)' -Purpose "Shortcut helper output still prints the issue-specific Google attached-html entrypoint command.")
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
        profile = "google-issue3-suite-router-handoff"
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

Write-Host "Google issue #3 suite-router handoff surface check"
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
    Write-Host "Google issue #3 suite-router handoff surface is intact."
    exit 0
}

Write-Host (("Missing {0} suite-router handoff path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the suite-router note, top-level attached-html helper, issue-specific Google attached-html checker, Google attached-html flow, Google attached-html helper, replay-route shortcut, or later-stage fallback before trusting the issue #3 suite-router handoff surface."
exit 1