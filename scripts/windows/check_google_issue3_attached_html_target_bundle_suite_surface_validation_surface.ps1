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
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Companion bundle-suite note for the compact pinned three-page route."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned bundle reference note that defines the known three-page compatibility set."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md" -Kind "file" -Purpose "Pinned bundle quickstart note that stays adjacent before bundle-first replay narrows further."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md" -Kind "file" -Purpose "Pinned bundle checklist note that remains nearby once the delegated bundle replay turns green."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Google-shaped attached-page flow note that can become the next broader follow-up after the pinned bundle lane."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Top-level attached-page bridge note that remains a nearby re-entry surface from the compact bundle lane."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md" -Kind "file" -Purpose "Replay-route bundle-first bridge note kept visible beside the compact bundle lane."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose attached-html-target-bundle, attached-html, and google-attached-html surfaces feed this compact bundle lane."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact bundle-suite helper whose printed surface this checker validates."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Broader Google-shaped attached-page fail-fast checker kept visible beside the compact bundle lane."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_local_asset_closure.ps1" -Kind "file" -Purpose "Deeper asset-closure checker that stays visible before the bundle-only route begins."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-page localhost flow helper kept visible beside the compact bundle lane."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-shaped attached-page flow helper kept visible before the pinned bundle route narrows fully."),
    (New-ValidationReference -Path "scripts/windows/run_google_attached_html_validation.ps1" -Kind "file" -Purpose "Google-shaped attached-page runner that remains visible before the bundle-only replay takes over."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_target_bundle_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the pinned target-bundle validation surface."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_target_bundle.ps1" -Kind "file" -Purpose "Pinned target-bundle checker that confirms the current inputs still match the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1" -Kind "file" -Purpose "Pinned target-bundle flow helper surfaced by the compact bundle lane."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Pinned target-bundle localhost runner surfaced by the compact bundle lane."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1" -Kind "file" -Purpose "Pinned proof helper that stays visible after the bundle replay turns green."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Top-level attached-page bridge helper that remains a nearby re-entry surface from the compact bundle lane."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper that preserves pinned replay context when explicit inputs are already in play."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Replay-route helper that remains visible when the next failure state is still broader than the pinned bundle lane."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Replay-shortcuts helper that stays visible after the compact bundle lane narrows the next step.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'attached_html_target_bundle = Format-HelperCommandWithRepoRootEnv -ScriptName ''show_headed_validation_suites.ps1'' -Arguments $attachedHtmlTargetBundleSuiteArguments -RepoRootOverride $RepoRoot' -Purpose "Bundle-suite helper keeps the attached-html-target-bundle suite command visible from the compact route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName ''show_headed_validation_suites.ps1'' -Arguments $attachedHtmlSuiteArguments -RepoRootOverride $RepoRoot' -Purpose "Bundle-suite helper keeps the broader attached-html suite command visible beside the pinned bundle lane."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'google_attached_html = Format-HelperCommandWithRepoRootEnv -ScriptName ''show_headed_validation_suites.ps1'' -Arguments $googleAttachedHtmlSuiteArguments -RepoRootOverride $RepoRoot' -Purpose "Bundle-suite helper keeps the narrower Google-shaped suite command visible beside the pinned bundle lane."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'bundle_surface_check = Format-HelperCommand -ScriptName ''check_attached_html_target_bundle_validation_surface.ps1'' -Arguments $bundleSurfaceCheckArguments' -Purpose "Bundle-suite helper keeps the pinned target-bundle surface checker visible before bundle-only replay."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'bundle_check = Format-HelperCommand -ScriptName ''check_attached_html_target_bundle.ps1'' -Arguments $bundleCheckerArguments' -Purpose "Bundle-suite helper keeps the pinned target-bundle checker visible before bundle-only replay."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'bundle_proof_entrypoint = Format-HelperCommand -ScriptName ''show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1'' -Arguments $reentryArguments' -Purpose "Bundle-suite helper keeps the pinned proof entrypoint visible after bundle replay."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'top_level_attached_html_bridge = Format-HelperCommand -ScriptName ''show_google_issue3_top_level_attached_html_entrypoint.ps1'' -Arguments $reentryArguments' -Purpose "Bundle-suite helper keeps the broader top-level attached-page bridge visible as a nearby re-entry route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'bundle_first_entrypoint = Format-HelperCommand -ScriptName ''show_google_issue3_attached_bundle_first_entrypoint.ps1'' -Arguments $bundleFirstArguments' -Purpose "Bundle-suite helper keeps the narrower bundle-first entrypoint visible when explicit replay context is already pinned."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'replay_route = Format-HelperCommand -ScriptName ''show_google_issue3_replay_route.ps1'' -Arguments $reentryArguments' -Purpose "Bundle-suite helper keeps the replay-route bridge visible when the route should widen again after bundle replay."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'replay_shortcuts = Format-HelperCommand -ScriptName ''show_google_issue3_replay_shortcuts.ps1'' -Arguments $reentryArguments' -Purpose "Bundle-suite helper keeps the replay-shortcuts bridge visible when the compact bundle lane has narrowed the next step."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'Write-Host ''Suite surface:''' -Purpose "Printed helper output keeps the compact suite-surface heading intact."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'Write-Host (("  Bundle suite:    {0}") -f $surface.suite_commands.attached_html_target_bundle)' -Purpose "Printed helper output keeps the pinned bundle suite command visible."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'Write-Host (("  Broader suite:   {0}") -f $surface.suite_commands.attached_html)' -Purpose "Printed helper output keeps the broader attached-html suite command visible."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'Write-Host (("  Google suite:    {0}") -f $surface.suite_commands.google_attached_html)' -Purpose "Printed helper output keeps the Google-shaped suite command visible."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'Write-Host (("  Proof entry:     {0}") -f $surface.helper_commands.bundle_proof_entrypoint)' -Purpose "Printed helper output keeps the pinned proof entrypoint visible after bundle replay."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'Write-Host (("  Bundle-first:    {0}") -f $surface.helper_commands.bundle_first_entrypoint)' -Purpose "Printed helper output keeps the narrower bundle-first entrypoint visible in the nearby re-entry section."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'Write-Host (("  Replay route:    {0}") -f $surface.helper_commands.replay_route)' -Purpose "Printed helper output keeps the replay-route bridge visible after bundle replay."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'Write-Host (("  Replay shortcuts:{0}") -f (" $($surface.helper_commands.replay_shortcuts)"))' -Purpose "Printed helper output keeps the replay-shortcuts bridge visible after bundle replay."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Snippet 'Run bundle_surface_check before trusting the bundle-only replay after branch moves or helper renames.' -Purpose "Usage notes document that the pinned target-bundle surface checker should run before trusting bundle-only replay.")
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
        profile = "google-issue3-attached-html-target-bundle-suite-surface"
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

Write-Host "Google issue #3 attached-html target-bundle suite surface check"
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
    Write-Host "Google issue #3 attached-html target-bundle suite surface is intact."
    exit 0
}

Write-Host (("Missing {0} attached-html target-bundle suite-surface path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing bundle-suite note, suite-router command surface, broader attached-page handoff, pinned target-bundle checker, proof follow-up, or replay re-entry path before trusting this issue #3 compatibility-bundle route."
exit 1
