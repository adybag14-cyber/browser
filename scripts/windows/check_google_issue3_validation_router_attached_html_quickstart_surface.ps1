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
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Broader Windows headed runbook that can reopen the issue #3 attached HTML validation-router route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Windows replay quickstart note kept beside the validation-router attached HTML bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Windows full-use attached-page route note that can reopen this validation-router quickstart."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md" -Kind "file" -Purpose "Shorter change-area quickstart note kept beside the broader validation-router attached HTML bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Written companion note for the issue #3 validation-router attached HTML quickstart helper."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Windows full-use validation-router bridge note kept aligned when the replay re-enters the narrower attached-html ladder from the broader Windows-first route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Windows-facing validation-router quickstart note kept aligned with the same attached HTML bridge."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Compact top-level attached-page quickstart note surfaced by the validation-router helper."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-page catalog quickstart note surfaced by the validation-router helper."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Broader top-level attached-page bridge note kept nearby when the route widens again."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md" -Kind "file" -Purpose "Top-level shortcut-first entrypoint note surfaced by the validation-router helper before the route collapses into narrower replay helpers."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Google-shaped attached-page validation-flow note that may be reopened before the shorter issue #3 attached-page helpers."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google-shaped attached-page entrypoint note surfaced when the validation-router helper keeps the dedicated Google lane visible before the narrower replay helpers."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-page quickstart note surfaced by the validation-router helper."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md" -Kind "file" -Purpose "Compact next-step matrix note surfaced when the validation-router helper still needs the executable issue #3 branch chooser nearby."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-page bridge note kept nearby when the route widens again."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Replay-route shortcut bridge note kept nearby before the validation-router route narrows into the smaller replay-route helper."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_SHORTCUTS_WINDOWS_REPLAY_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Replay-shortcuts Windows replay bridge note kept nearby before the validation-router route collapses into the tighter replay shortcut chain."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md" -Kind "file" -Purpose "Pinned attached-page bundle proof-entrypoint note kept nearby before the validation-router route drops into the proof-only bundle branch."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used by the validation-router attached HTML quickstart chain."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level headed validation suite router that reopens the attached HTML change areas, including the Google-shaped attached-page branch."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Replay-side attached-page quickstart surface checker that should fail fast before the validation-router bridge trusts the narrower replay ladder."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-page quickstart helper that can reopen this validation-router quickstart from the narrower Windows replay lane."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1" -Kind "file" -Purpose "Broader Windows full-use attached-page route checker that should fail fast before the validation-router route is reopened from the Windows runbook."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1" -Kind "file" -Purpose "Windows full-use attached-page route helper that can reopen this validation-router quickstart."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Shorter change-area quickstart helper kept beside the broader validation-router route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Context-preserving suite-catalog helper surfaced when repo-root, saved-summary, or bundle state already matters."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast suite-catalog surface checker that should stay visible before the validation-router route hands off to the broader issue #3 context-preserving bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_quickstart.ps1" -Kind "file" -Purpose "Shorter suite-router bridge surfaced when the broader validation catalog still matters before the top-level attached-page quickstarts."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Primary issue #3 validation-router attached HTML quickstart helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Default top-level attached-page quickstart helper after the validation-router route narrows."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Catalog-side top-level attached-page quickstart helper surfaced by the validation-router route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Broader top-level attached-page bridge helper surfaced by the validation-router route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut-first helper surfaced by the validation-router route before the replay narrows into the smaller shortcut chain."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Dedicated Google-shaped attached-page surface checker that should stay available before the narrower issue #3 helper chain reuses the Google attached-page flow."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-shaped attached-page flow helper that may be reopened from the validation-router route before the shorter issue #3 helper chain."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Issue-specific Google-shaped attached-page entrypoint surface checker that should fail fast before the validation-router route trusts the narrower Google replay bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google-shaped attached-page entrypoint helper surfaced when the validation-router route keeps that narrower branch visible before replay shortcuts."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-page quickstart helper surfaced by the validation-router route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Short attached-page helper surfaced after the validation-router route narrows further."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_replay_route_shortcut_validation_surface.ps1" -Kind "file" -Purpose "Replay-route shortcut surface checker that should fail fast before the validation-router route collapses into the replay-route shortcut bridge."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Replay-route shortcut helper surfaced when the validation-router route narrows toward the replay-route companion."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1" -Kind "file" -Purpose "Replay-shortcuts Windows replay bridge helper surfaced when the validation-router route still needs that narrower replay-side bridge before collapsing into the tightest shortcut chain."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Replay-shortcuts helper surfaced after the validation-router route narrows further."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Next-step matrix surfaced by the validation-router attached HTML quickstart."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Pinned attached-page bundle proof-entrypoint surface checker that should fail fast before the validation-router route reuses the proof-only bundle branch."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Kind "file" -Purpose "Pinned attached-page bundle proof-entrypoint helper surfaced before the validation-router route drops into the proof-only bundle branch."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Pinned three-page bundle helper surfaced when attached bundle paths are already fixed.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -Purpose "Written validation-router quickstart note keeps its own fail-fast checker visible before the route narrows again."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1' -Purpose "Written validation-router quickstart note keeps the broader Google attached-page surface checker visible before the Google-specific bridge is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1' -Purpose "Written validation-router quickstart note keeps the issue-specific Google attached-page bridge visible after the broader Google surface check."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Snippet 'docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md' -Purpose "Written validation-router quickstart note keeps the Windows full-use bridge note visible beside the narrower attached-html ladder."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -Purpose "Windows full-use bridge note keeps the validation-router surface checker visible before the route narrows into the attached-html helper ladder."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1' -Purpose "Windows full-use bridge note keeps the validation-router attached-html quickstart helper visible in its default read-first route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Snippet 'validation_router_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_issue3_validation_router_attached_html_quickstart_surface.ps1'' -RepoRootOverride $RepoRoot' -Purpose "Validation-router quickstart helper keeps its dedicated fail-fast checker wired into the printed command surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Snippet 'google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_attached_html_validation_surface.ps1'' -RepoRootOverride $RepoRoot' -Purpose "Validation-router quickstart helper keeps the broader Google attached-page surface checker wired before the narrower issue-specific bridge."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Snippet 'google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName ''show_google_attached_html_validation_flow.ps1'' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot' -Purpose "Validation-router quickstart helper keeps the broader Google attached-page flow helper wired beside the fail-fast checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Snippet 'google_attached_html_entrypoint = Format-HelperCommand -ScriptName ''show_google_issue3_google_attached_html_entrypoint.ps1'' -Arguments $bundleArguments' -Purpose "Validation-router quickstart helper keeps the issue-specific Google attached-page bridge wired after the broader Google helper surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Snippet 'suite_catalog_entrypoints_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_issue3_suite_catalog_entrypoints_validation_surface.ps1'' -RepoRootOverride $RepoRoot' -Purpose "Validation-router quickstart helper keeps the suite-catalog fail-fast checker wired before handing off to the context-preserving issue #3 bridge."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Snippet 'suite_router_next_steps = Format-HelperCommand -ScriptName ''show_google_issue3_suite_router_next_steps.ps1'' -Arguments $bundleArguments' -Purpose "Validation-router quickstart helper keeps the executable suite-router next-step matrix wired into the later attached-page route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Snippet 'attached_bundle_first = Format-HelperCommand -ScriptName ''show_google_issue3_attached_bundle_first_entrypoint.ps1'' -Arguments $browserAwareArguments' -Purpose "Validation-router quickstart helper keeps the pinned three-page bundle branch wired when replay inputs are already fixed."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Surface checker:            {0}") -f $helper.commands.validation_router_attached_html_surface_check)' -Purpose "Printed validation-router quickstart output keeps its fail-fast checker visible at the top of the bridge."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Google attached surface:     {0}") -f $helper.commands.google_attached_html_surface_check)' -Purpose "Printed validation-router quickstart output keeps the broader Google attached-page surface checker visible from the router bridge."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Google attached flow:        {0}") -f $helper.commands.google_attached_html_flow)' -Purpose "Printed validation-router quickstart output keeps the broader Google attached-page flow helper visible beside the surface checker."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Google attached bridge:      {0}") -f $helper.commands.google_attached_html_entrypoint)' -Purpose "Printed validation-router quickstart output keeps the issue-specific Google attached-page bridge visible before replay shortcuts."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Suite catalog surface:       {0}") -f $helper.commands.suite_catalog_entrypoints_surface_check)' -Purpose "Printed validation-router quickstart output keeps the suite-catalog fail-fast checker visible before the broader context-preserving route opens."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Next-step matrix:            {0}") -f $helper.commands.suite_router_next_steps)' -Purpose "Printed validation-router quickstart output keeps the suite-router next-step matrix visible as a later-stage fallback."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Snippet 'Write-Host (("  Bundle-first helper:         {0}") -f $helper.commands.attached_bundle_first)' -Purpose "Printed validation-router quickstart output keeps the pinned three-page bundle branch visible when inputs are already fixed."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Snippet 'Use suite_catalog_entrypoints_surface_check when RepoRoot, SummaryPath, or pinned InputPath values already matter and you want the suite-catalog surface to fail fast before this validation-router bridge hands control over to the broader issue #3 context-preserving route.' -Purpose "Validation-router quickstart notes explain when to use the suite-catalog guard before the helper hands off to the broader issue #3 bridge.")
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
        profile = "google-issue3-validation-router-attached-html-quickstart"
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

Write-Host "Google issue #3 validation-router attached HTML quickstart surface check"
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
    Write-Host "Google issue #3 validation-router attached HTML quickstart surface is intact."
    exit 0
}

Write-Host (("Missing {0} validation-router attached HTML quickstart path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing quickstart note, suite-catalog surface checker handoff, helper command surfacing, replay-route shortcut surface, Google entrypoint checker, proof-entrypoint surface, or downstream route script before trusting the issue #3 validation-router attached localhost bridge."
exit 1