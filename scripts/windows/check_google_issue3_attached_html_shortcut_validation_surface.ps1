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
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_SHORTCUT_ENTRYPOINT.md" -Kind "file" -Purpose "Written companion note for the issue #3 attached-page shortcut helper.")
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Replay quickstart note kept beside the attached-page shortcut route.")
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Windows full-use attached-page route note that still feeds the shortcut route when replay reopens from the runbook.")
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Windows-to-validation-router attached-page bridge note kept aligned with the shortcut route.")
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Windows-side attached-page catalog quickstart note kept aligned with the shortcut route.")
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-page quickstart note kept beside the shortcut route.")
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md" -Kind "file" -Purpose "Attached-page change-area quickstart note surfaced before the shortcut route narrows further.")
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Compact top-level attached-page quickstart note referenced by the shortcut route.")
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Broader top-level attached-page bridge note referenced by the shortcut route.")
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-page catalog quickstart note referenced by the shortcut route.")
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-page quickstart note referenced by the shortcut route.")
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Suite-router shortcut bridge note kept alongside the attached-page shortcut helper.")
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ENTRYPOINT_GUIDE.md" -Kind "file" -Purpose "Suite-router entrypoint guide kept alongside the attached-page shortcut helper.")
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ENTRYPOINTS.md" -Kind "file" -Purpose "Suite-catalog guide kept alongside the attached-page shortcut helper.")
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Broader Google-shaped attached-page flow note surfaced from the shortcut route.")
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-page bridge note surfaced from the shortcut route.")
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain note kept nearby when the route widens again.")
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Broader Windows headed runbook that feeds the attached-page shortcut route.")
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used by the shortcut commands when repo-root context is preserved.")
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level headed validation suite router that exposes the attached-HTML change areas.")
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Broader Google-shaped attached-page surface checker surfaced from the shortcut route.")
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_html_shortcut_validation_surface.ps1" -Kind "file" -Purpose "Primary attached-page shortcut surface checker for issue #3.")
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Issue-specific Google attached-page surface checker surfaced from the shortcut route.")
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-page localhost-first helper chain that can widen back out from the shortcut surface.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1" -Kind "file" -Purpose "Windows full-use attached-page route helper referenced by the shortcut route.")
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1" -Kind "file" -Purpose "Windows full-use attached-page surface checker referenced by the shortcut route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1" -Kind "file" -Purpose "Windows-to-validation-router attached-page bridge helper referenced by the shortcut route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Windows-side attached-page catalog quickstart helper referenced by the shortcut route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-page quickstart helper referenced by the shortcut route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Attached-page change-area quickstart helper surfaced from the shortcut route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level issue #3 shortcut helper referenced by the attached-page shortcut entrypoint.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-page quickstart helper referenced by the shortcut route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Top-level attached-page bridge helper referenced by the shortcut route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-page catalog quickstart helper referenced by the shortcut route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-page bridge helper surfaced from the shortcut route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Primary attached-page shortcut helper for issue #3.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Default next helper after the attached-page shortcut when no bundle inputs are pinned.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Narrow replay-shortcuts helper surfaced from the attached-page shortcut route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Next-step matrix surfaced from the attached-page shortcut route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Pinned three-page bundle helper surfaced from the attached-page shortcut route.")
    (New-ValidationReference -Path "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1" -Kind "file" -Purpose "Bundle validation-flow helper surfaced from the attached-page shortcut route.")
    (New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Bundle validation runner surfaced from the attached-page shortcut route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map surfaced from the attached-page shortcut route.")
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1" -Kind "file" -Purpose "Fresh safe replay runner surfaced from the attached-page shortcut route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1" -Kind "file" -Purpose "Reuse-current-outputs helper surfaced from the attached-page shortcut route.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Snippet '$googleAttachedHtmlSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_attached_html_validation_surface.ps1'' -RepoRootOverride $RepoRoot' -Purpose "Shortcut helper wires the broader Google-shaped attached-page surface checker into its command surface.")
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Snippet '$attachedHtmlShortcutSurfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName ''check_google_issue3_attached_html_shortcut_validation_surface.ps1'' -RepoRootOverride $RepoRoot' -Purpose "Shortcut helper wires its own fail-fast checker into the command surface.")
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Snippet 'google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand' -Purpose "Shortcut helper exposes the broader Google-shaped attached-page surface checker through the top-level command map.")
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Snippet 'google_issue_attached_html_entrypoint = Format-HelperCommand -ScriptName ''show_google_issue3_google_attached_html_entrypoint.ps1'' -Arguments $bundleArguments' -Purpose "Shortcut helper keeps the issue-specific Google attached-page bridge visible through the top-level command map.")
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Snippet 'google_attached_html_validation_flow_note_path = ''docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md''' -Purpose "Shortcut helper points at the broader Google-shaped attached-page validation-flow note.")
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Snippet 'google_attached_html_entrypoint_note_path = ''docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md''' -Purpose "Shortcut helper points at the issue-specific Google attached-page bridge note.")
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Snippet 'Write-Host (("  4. Google surface:      {0}") -f $entrypoint.top_level_commands.google_attached_html_surface_check)' -Purpose "Attached-page bridge output prints the broader Google-shaped surface checker before the issue-specific bridge.")
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Snippet 'Write-Host (("  5. Google issue bridge: {0}") -f $entrypoint.top_level_commands.google_issue_attached_html_entrypoint)' -Purpose "Attached-page bridge output prints the issue-specific Google attached-page bridge before the shortcut route narrows further.")
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Snippet 'Write-Host (("Google flow note:         {0}") -f $entrypoint.google_attached_html_validation_flow_note_path)' -Purpose "Shortcut helper prints the broader Google-shaped attached-page note path in its companion note surface.")
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Snippet 'Write-Host (("Google issue note:        {0}") -f $entrypoint.google_attached_html_entrypoint_note_path)' -Purpose "Shortcut helper prints the issue-specific Google attached-page note path in its companion note surface.")
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Snippet 'Use google_attached_html_surface_check when the replay still needs the dedicated Google-shaped attached-page fail-fast checker reprinted beside the broader attached-page flow helper before the route narrows into the shortcut-first issue #3 surfaces.' -Purpose "Usage notes explain when to re-run the broader Google-shaped attached-page checker from the shortcut route.")
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Snippet 'Use google_issue_attached_html_entrypoint when the replay should keep the narrower issue-specific Google attached-page bridge visible beside the broader attached-page flow before the route drops into the shortest shortcut-first helper chain.' -Purpose "Usage notes explain when to keep the issue-specific Google attached-page bridge visible from the shortcut route.")
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
        profile = "google-issue3-attached-html-shortcut"
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

Write-Host "Google issue #3 attached HTML shortcut surface check"
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
    Write-Host "Google issue #3 attached HTML shortcut surface is intact."
    exit 0
}

Write-Host (("Missing {0} attached HTML shortcut path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing shortcut note, broader Google-shaped checker or bridge surfacing, Windows-side companion route, or follow-on helper contract before trusting the issue #3 attached localhost shortcut path."
exit 1
