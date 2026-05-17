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
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Kind "file" -Purpose "Read-first replay handoff note for the compact issue #3 attached-page quickstart ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_FIRST_ENTRYPOINT.md" -Kind "file" -Purpose "Shortcut-first note for the top-level issue #3 replay ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Written bridge for the shortcut-first attached-page route."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-page quickstart note that feeds the compact ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-page quickstart note for the compact issue #3 ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Broader top-level attached-page bridge note reopened by the compact ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Top-level catalog quickstart note surfaced from the compact ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_TOP_LEVEL_ATTACHED_HTML_CATALOG_QUICKSTART.md" -Kind "file" -Purpose "Suite-catalog-to-top-level catalog quickstart note kept adjacent to the compact ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Suite-router attached-page quickstart note guarded by this compact ladder checker."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_CATALOG_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Suite-catalog attached-page bridge note that remains beside the compact ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-page bridge note reached from the guarded compact ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached-page validation-flow note kept visible beside the compact ladder."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared repo-root helper support used by the compact quickstart checkers."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Top-level shortcut-first helper that anchors the compact issue #3 replay ladder."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_top_level_shortcut_first_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the shortcut-first surface at the top of the compact ladder."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-page quickstart helper used before the top-level compact ladder narrows further."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the replay-side attached-page quickstart surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-page quickstart helper inside the compact issue #3 ladder."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_top_level_attached_html_quickstart_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the top-level attached-page quickstart surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Top-level attached-page catalog quickstart helper surfaced from the compact ladder."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_top_level_attached_html_catalog_quickstart.ps1" -Kind "file" -Purpose "Suite-catalog-to-top-level catalog quickstart helper surfaced from the compact ladder."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Suite-router attached-page quickstart helper guarded by the compact ladder checker."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_suite_router_attached_html_quickstart_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the suite-router attached-page quickstart surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Suite-catalog attached-page bridge helper that stays adjacent to the compact ladder."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Issue-specific Google attached-page surface checker reached from the compact ladder."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Shortest attached-page shortcut helper reached after the compact ladder narrows further."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Replay shortcuts helper that follows the compact attached-page ladder."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Executable next-step matrix kept near the compact ladder when more branching context is needed."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_contextual_flow.ps1" -Kind "file" -Purpose "Context-preserving helper surfaced when repo root, summary, or input-path context must stay attached."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Later safe-route fallback map reopened after the compact attached-page ladder has done its job.")
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
        profile = "google-issue3-attached-html-quickstart-surfaces"
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

Write-Host "Google issue #3 attached-html quickstart surface check"
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
    Write-Host "Google issue #3 attached-html quickstart surfaces are intact."
    exit 0
}

Write-Host (("Missing {0} attached-html quickstart surface path(s).") -f $missing.Count)
Write-Host "Repair the compact shortcut, replay-side attached-page, top-level attached-page, suite-router attached-page, issue-specific Google attached-page, or safe-route companion surfaces before trusting the quickstart ladder."
exit 1
