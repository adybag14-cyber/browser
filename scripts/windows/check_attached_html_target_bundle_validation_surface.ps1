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
    (New-ValidationReference -Path "docs/HEADED_ATTACHED_HTML_VALIDATION.md" -Kind "file" -Purpose "Primary attached-HTML validation guide for the current compatibility bundle route."),
    (New-ValidationReference -Path "docs/HEADED_MODE_VALIDATION_GATES.md" -Kind "file" -Purpose "Canonical bounded-suite routing map that keeps the three-page compatibility bundle pinned to the right first gate before broader attached-page replay."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the bundle-aware attached-page helpers."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Bundle-specific reference note that keeps the pinned three-page route, reusable fixed-list proof path, and broader issue #3 re-entry surfaces visible together."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md" -Kind "file" -Purpose "Shortest quickstart bridge from the top-level validation router into the pinned attached HTML target-bundle path."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md" -Kind "file" -Purpose "Read-first proof-entry note that keeps the fixed-list screenshot-and-title proof route discoverable beside the pinned bundle replay path."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Compact suite-level attached HTML target-bundle re-entry note that keeps the broader attached-page, Google-shaped attached-page, and issue-specific Google attached-page helpers visible beside the pinned three-page route."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md" -Kind "file" -Purpose "Pinned manual checklist for the known three-page compatibility bundle once the bundled localhost route is green."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Google-shaped attached-page companion note that keeps the narrower issue #3 localhost-first helper chain visible beside the pinned three-page route."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-page entrypoint note that should stay visible when the bundle route still needs the narrower Google follow-up lane before bundle-only replay."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Canonical suite router that exposes the attached-html-target-bundle entry point before the narrower bundle helpers run."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact issue #3 bundle-suite helper that keeps the broader attached-page, Google-shaped attached-page, and issue-specific Google attached-page surfaces visible beside the pinned bundle lane."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first issue #3 entrypoint that keeps the replay-side quickstart ladder visible before the route locks onto the pinned bundle branch."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Proof-entrypoint surface checker that the bundle-first helper should keep visible after the delegated localhost runner."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Kind "file" -Purpose "Compact proof-entry helper that keeps the fixed-list screenshot-and-title follow-up pinned to the same bundle inputs after the delegated localhost runner."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Compact issue #3 next-step matrix that the bundle flow uses to carry the same pinned inputs into the narrower branch chooser after localhost replay."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Issue #3 replay-shortcuts helper that keeps the same pinned bundle inputs on the safe-route and replay-route handoff after bundle replay narrows the failure."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_target_bundle.ps1" -Kind "file" -Purpose "Checker for the known three-page attached HTML compatibility target bundle."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1" -Kind "file" -Purpose "Bundle-aware attached HTML flow helper."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Bundle-aware attached HTML localhost runner."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_validation_surface.ps1" -Kind "file" -Purpose "General attached-HTML validation surface checker used by the non-Google route."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Google-style attached-HTML validation surface checker used when the bundle includes the Google page."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Issue-specific Google attached-page surface checker that should stay visible on the bundle-suite helper before bundle-only replay."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-page entrypoint helper that should stay visible on the bundle-suite helper before bundle-only replay."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_local_asset_closure.ps1" -Kind "file" -Purpose "Deep attached-HTML asset audit for the locked bundle paths."),
    (New-ValidationReference -Path "scripts/windows/check_local_html_fixture_validation_surface.ps1" -Kind "file" -Purpose "Reusable fixed-list local HTML fixture surface checker for the same saved compatibility pages."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "General attached-HTML flow helper referenced by the bundle checker when the bundle is not Google-routed."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_localhost_validation.ps1" -Kind "file" -Purpose "General attached-HTML localhost runner delegated to by the bundle-aware path."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-style attached-HTML flow helper referenced by the bundle checker when the bundle stays on the issue #3 route."),
    (New-ValidationReference -Path "scripts/windows/run_google_attached_html_validation.ps1" -Kind "file" -Purpose "Google-style attached-HTML localhost runner delegated to by the bundle-aware path."),
    (New-ValidationReference -Path "tmp-browser-smoke/local-html-fixtures/chrome-local-html-fixture-probe.ps1" -Kind "file" -Purpose "Reusable fixed-list screenshot-and-title probe for the same saved compatibility pages.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet "bundle_proof = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md'" -Purpose "Bundle-suite helper keeps the read-first proof note in its printed nearby-note surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet "google_issue3_attached_html_entrypoint = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md'" -Purpose "Bundle-suite helper keeps the issue-specific Google attached-page note path in its printed nearby-note surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'google_issue3_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1'' -RepoRootOverride $RepoRoot' -Purpose "Bundle-suite helper keeps the issue-specific Google attached-page surface checker wired beside the broader Google-shaped route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'google_issue3_attached_html_entrypoint = Format-HelperCommand -ScriptName ''show_google_issue3_google_attached_html_entrypoint.ps1'' -Arguments $reentryArguments' -Purpose "Bundle-suite helper keeps the issue-specific Google attached-page entrypoint helper wired beside the broader Google-shaped route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'Write-Host (("Bundle proof note:          {0}") -f $surface.note_paths.bundle_proof)' -Purpose "Bundle-suite helper prints the proof note beside the other bundle companions so the written proof route stays visible with the executable proof entrypoint."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'Write-Host (("Issue #3 Google: {0}") -f $surface.helper_commands.google_issue3_attached_html_surface_check)' -Purpose "Bundle-suite helper prints the issue-specific Google attached-page surface checker beside the broader Google-shaped route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'Write-Host (("Issue #3 helper: {0}") -f $surface.helper_commands.google_issue3_attached_html_entrypoint)' -Purpose "Bundle-suite helper prints the issue-specific Google attached-page entrypoint beside the broader Google-shaped route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'Write-Host (("Issue #3 Google note:       {0}") -f $surface.note_paths.google_issue3_attached_html_entrypoint)' -Purpose "Bundle-suite helper prints the issue-specific Google attached-page note path beside the broader Google-shaped route."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Snippet '- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`' -Purpose "Bundle-suite note keeps the proof note in the nearby companion list for the same pinned route."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md" -Snippet '- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md`' -Purpose "Bundle proof note keeps the compact suite-surface companion note visible beside the proof-only route."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md" -Snippet 'Keep `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md` and `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md` open beside this proof-only bridge when the replay has not fully collapsed into proof collection.' -Purpose "Bundle proof note keeps the suite-surface and broader quickstart companions explicitly visible until the replay is ready to collapse into proof-only follow-up."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md" -Snippet '- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`' -Purpose "Bundle quickstart keeps the proof note in its nearby companion list for the same pinned route."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Purpose "Bundle quickstart keeps the proof-entrypoint surface checker visible before the narrower proof bridge is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Purpose "Bundle quickstart keeps the proof-only helper visible beside the delegated bundle runner and the written proof note."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Snippet "bundle_proof_surface_check_command = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $bundleSurfaceCheckArguments" -Purpose "Bundle-first helper keeps the proof-entrypoint surface checker wired beside the delegated bundle runner."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Snippet "bundle_proof_entrypoint_command = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $reentryArguments" -Purpose "Bundle-first helper keeps the proof-only helper wired beside the delegated bundle runner."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Snippet "attached_html_target_bundle_proof_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md'" -Purpose "Bundle-first helper keeps the written proof note path visible beside the locked bundle route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Snippet 'Write-Host ("  Proof surface:       {0}" -f $entrypoint.bundle_proof_surface_check_command)' -Purpose "Bundle-first helper prints the proof-entrypoint surface checker in the post-runner proof section."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Snippet 'Write-Host ("  Proof entrypoint:    {0}" -f $entrypoint.bundle_proof_entrypoint_command)' -Purpose "Bundle-first helper prints the proof-only helper in the post-runner proof section."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Snippet 'Write-Host ("Proof note:                   {0}" -f $entrypoint.attached_html_target_bundle_proof_note_path)' -Purpose "Bundle-first helper prints the written proof note beside the other bundle companion notes."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Snippet 'After the bundle runner turns green, reopen bundle_proof_surface_check_command and bundle_proof_entrypoint_command so the written proof note, the proof-only helper, and the reusable fixed-list screenshot-and-title proof stay pinned to the same bundle inputs before the route widens back out.' -Purpose "Bundle-first helper usage notes keep the proof-note and proof-entrypoint contract explicit after the delegated bundle runner.")
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
        profile = "attached-html-target-bundle"
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

Write-Host "Attached HTML target-bundle validation surface check"
Write-Host ""
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
Write-Host ""

foreach ($result in $referenceResults) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host ("[{0}] {1}" -f $status, $result.Path)
    Write-Host ("  {0}" -f $result.Purpose)
}

if ($contentResults.Count -gt 0) {
    Write-Host ""
    Write-Host "Helper source expectations:"
    foreach ($result in $contentResults) {
        $status = if ($result.Exists) { "PASS" } else { "FAIL" }
        Write-Host ("[{0}] {1}" -f $status, $result.Path)
        Write-Host ("  {0}" -f $result.Purpose)
    }
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Attached HTML target-bundle validation surface is intact, including the bundle reference note, the bundle quickstart, the proof-entry note, the compact bundle suite-surface note and helper, the issue-specific Google attached-page note plus its checker and entrypoint helper, the bundle-first helper, the proof-entrypoint surface checker, the bundle proof entrypoint, the Google attached-page companion note, the issue #3 next-step matrix and replay-shortcuts follow-up helpers, the pinned manual checklist, the reusable local fixture probe, and the proof-note plus issue-specific Google surfacing contract on the bundle suite and bundle-first helper surfaces."
    exit 0
}

Write-Host ("Missing {0} attached HTML target-bundle validation path or source-contract check(s)." -f $missing.Count)
Write-Host "Repair the missing guide, reference note, quickstart, proof-entry note, compact suite-surface note or helper, issue-specific Google note/checker/helper, bundle-first helper, proof-entrypoint surface checker, bundle proof entrypoint, Google attached-page companion note, issue #3 next-step or replay-shortcuts helper, checklist, reusable fixture probe surface, or bundle proof-note and issue-specific Google surfacing contract before trusting the bundle-pinned localhost route."
exit 1
