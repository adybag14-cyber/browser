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
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that can reopen the issue #3 attached localhost route.")
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_BUNDLE_BRIDGE.md" -Kind "file" -Purpose "Windows-first compact guide for the pinned three-page attached bundle route.")
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md" -Kind "file" -Purpose "Broader Windows full-use attached-page route note that hands off into the pinned bundle branch.")
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_FULL_USE_VALIDATION_ROUTER_ATTACHED_HTML_BRIDGE.md" -Kind "file" -Purpose "Windows-to-validation-router attached-page bridge note used before the route narrows into the bundle branch.")
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-page quickstart note kept beside the Windows-first bundle route.")
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md" -Kind "file" -Purpose "Attached-page change-area quickstart note used before the route narrows into the pinned bundle surface.")
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Reference note for the known three-page attached HTML compatibility bundle.")
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Compact suite-surface note for the pinned attached bundle route.")
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md" -Kind "file" -Purpose "Replay-route bridge note that keeps the bundle-first route visible beside broader attached-page fallbacks.")
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_ATTACHED_BUNDLE_BRIDGE.md" -Kind "file" -Purpose "Suite-router attached-bundle bridge note that keeps the pinned bundle branch visible from the catalog side.")
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used by the attached-bundle bridge commands.")
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level headed validation suite router that exposes the attached bundle change area.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1" -Kind "file" -Purpose "Windows full-use attached-page route helper that should stay aligned with the attached bundle bridge.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1" -Kind "file" -Purpose "Windows-to-validation-router attached-page bridge helper used before the compact bundle branch.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1" -Kind "file" -Purpose "Replay-side attached-page quickstart helper used before bundle-first narrowing.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Attached-page change-area quickstart helper that can reopen the broader attached-page route before bundle-first narrowing.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_target_bundle_suite_surface.ps1" -Kind "file" -Purpose "Compact suite-surface helper for the pinned attached bundle route.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_bundle_first_bridge.ps1" -Kind "file" -Purpose "Replay-route bundle bridge helper used to keep the pinned bundle path visible beside broader attached-page fallbacks.")
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Narrower issue #3 bundle-first helper used once the pinned three-page route is confirmed.")
    (New-ValidationReference -Path "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1" -Kind "file" -Purpose "Bundle validation-flow helper used before the delegated runner.")
    (New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Delegated runner for the pinned three-page attached bundle route.")
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
        profile = "google-issue3-windows-full-use-attached-bundle-bridge"
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

Write-Host "Google issue #3 Windows full-use attached bundle bridge surface check"
Write-Host ""
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
Write-Host ""

foreach ($result in $results) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host ("[{0}] {1}" -f $status, $result.Path)
    Write-Host ("  {0}" -f $result.Purpose)
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Google issue #3 Windows full-use attached bundle bridge surface is intact."
    exit 0
}

Write-Host ("Missing {0} Windows full-use attached bundle bridge path(s)." -f $missing.Count)
Write-Host "Repair the missing bridge note, helper, or delegated bundle route before trusting the Windows-first pinned-bundle path."
exit 1
