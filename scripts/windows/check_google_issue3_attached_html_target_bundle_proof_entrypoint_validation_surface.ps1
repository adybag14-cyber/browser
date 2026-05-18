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
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md" -Kind "file" -Purpose "Pinned three-page proof-entrypoint note that this checker protects."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Reference note for the fixed three-page compatibility bundle used by the proof route."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md" -Kind "file" -Purpose "Checklist note kept nearby for page-by-page manual follow-up after proof."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md" -Kind "file" -Purpose "Quickstart note for the same pinned bundle route that leads into the proof entrypoint."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Google-shaped attached-page flow note used when proof says the route should widen back out."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md" -Kind "file" -Purpose "Bundle-first replay bridge note kept aligned with the proof-only follow-up."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-html quickstart note kept nearby when proof is entered from the replay lane."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware commands."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Kind "file" -Purpose "Proof-entrypoint helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_target_bundle_validation_surface.ps1" -Kind "file" -Purpose "Pinned bundle surface checker that should stay visible before proof runs."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_target_bundle.ps1" -Kind "file" -Purpose "Pinned bundle checker that should stay visible before proof runs."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1" -Kind "file" -Purpose "Pinned bundle flow helper used immediately before proof."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Pinned bundle runner used immediately before proof."),
    (New-ValidationReference -Path "scripts/windows/check_local_html_fixture_validation_surface.ps1" -Kind "file" -Purpose "Fixed-list local HTML fixture surface checker used before the screenshot-and-title proof probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/local-html-fixtures/chrome-local-html-fixture-probe.ps1" -Kind "file" -Purpose "Fixed-list proof probe that captures the three-page screenshot-and-title evidence."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-page flow helper used when proof says the route should widen back into generic localhost replay."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-shaped attached-page flow helper used when proof says the narrower Google-first route should stay visible."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact suite-level bundle surface helper used to re-enter the pinned bundle route before or after proof."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper used when the replay should stay pinned to the same three-page bundle after proof."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Dedicated proof-entrypoint surface checker.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md" -Snippet 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Purpose "Proof-entrypoint note reprints the dedicated fail-fast checker command before the proof-only route is trusted."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Snippet 'bundle_surface_check_command = Format-HelperCommand -ScriptName ''check_attached_html_target_bundle_validation_surface.ps1'' -Arguments $bundleArguments' -Purpose "Proof-entrypoint helper still reprints the pinned bundle surface checker before proof runs."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Snippet 'local_html_fixture_surface_check_command = Format-HelperCommand -ScriptName ''check_local_html_fixture_validation_surface.ps1'' -Arguments $fixtureSurfaceArguments' -Purpose "Proof-entrypoint helper still reprints the fixed-list local HTML fixture checker before the screenshot-and-title probe runs."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Snippet 'bundle_suite_surface_command = Format-HelperCommand -ScriptName ''show_google_issue3_attached_html_target_bundle_suite_surface.ps1'' -Arguments $reentryArguments' -Purpose "Proof-entrypoint helper still keeps the compact suite-level bundle surface visible for re-entry before or after proof."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Snippet 'Write-Host (("  Surface check: {0}") -f $entrypoint.bundle_surface_check_command)' -Purpose "Printed proof-entrypoint output still keeps the bundle surface checker visible before the delegated replay."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Snippet 'Write-Host (("  Surface check: {0}") -f $entrypoint.local_html_fixture_surface_check_command)' -Purpose "Printed proof-entrypoint output still keeps the fixed-list proof surface checker visible before the screenshot-and-title probe."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Snippet 'Write-Host (("  Suite surface: {0}") -f $entrypoint.bundle_suite_surface_command)' -Purpose "Printed proof-entrypoint output still keeps the compact suite-level bundle surface visible for nearby re-entry."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Snippet 'Write-Host (("  Probe:         {0}") -f $entrypoint.local_html_fixture_probe_command)' -Purpose "Printed proof-entrypoint output still exposes the fixed-list screenshot-and-title probe command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Snippet 'Use bundle_surface_check_command and bundle_check_command first when you want one last fail-fast confirmation that the current pages still match the known three-page compatibility bundle before you collect proof.' -Purpose "Usage notes preserve the fail-fast order before proof is collected.")
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
        profile = "google-issue3-attached-html-target-bundle-proof-entrypoint"
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

Write-Host "Google issue #3 attached-html target-bundle proof entrypoint surface check"
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
    Write-Host "Google issue #3 attached-html target-bundle proof entrypoint surface is intact."
    exit 0
}

Write-Host (("Missing {0} attached-html target-bundle proof-entrypoint path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the proof-entrypoint note, helper, fixed-list probe surface, bundle replay helpers, or nearby re-entry surfaces before trusting the pinned three-page proof route."
exit 1