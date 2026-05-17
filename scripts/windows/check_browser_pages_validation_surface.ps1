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
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook for the broader headed validation workflow."),
    (New-ValidationReference -Path "docs/HEADED_MODE_ROADMAP.md" -Kind "file" -Purpose "Roadmap and lane reference for headed validation work."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation suite router for the shell and browser-pages suite."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared repo-root helpers used by validation wrappers."),
    (New-ValidationReference -Path "scripts/windows/check_browser_pages_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the browser-pages validation route."),
    (New-ValidationReference -Path "scripts/windows/show_browser_pages_validation_flow.ps1" -Kind "file" -Purpose "Printed read-first flow for the browser-pages validation route."),
    (New-ValidationReference -Path "tmp-browser-smoke/browser-pages" -Kind "directory" -Purpose "browser:// page and shell validation workspace."),
    (New-ValidationReference -Path "tmp-browser-smoke/browser-pages/BrowserPagesProbeCommon.ps1" -Kind "file" -Purpose "Shared browser-pages probe helpers and repo-root-aware process setup."),
    (New-ValidationReference -Path "tmp-browser-smoke/browser-pages/chrome-browser-pages-title-fidelity-probe.ps1" -Kind "file" -Purpose "Title generation and internal-page restore checkpoint."),
    (New-ValidationReference -Path "tmp-browser-smoke/browser-pages/chrome-browser-pages-start-shell-probe.ps1" -Kind "file" -Purpose "Browser Start shell navigation checkpoint."),
    (New-ValidationReference -Path "tmp-browser-smoke/browser-pages/chrome-browser-pages-history-filter-probe.ps1" -Kind "file" -Purpose "browser://history quick-filter checkpoint."),
    (New-ValidationReference -Path "tmp-browser-smoke/browser-pages/chrome-browser-pages-bookmarks-filter-probe.ps1" -Kind "file" -Purpose "browser://bookmarks quick-filter checkpoint."),
    (New-ValidationReference -Path "tmp-browser-smoke/browser-pages/chrome-browser-pages-downloads-filter-probe.ps1" -Kind "file" -Purpose "browser://downloads quick-filter checkpoint."),
    (New-ValidationReference -Path "tmp-browser-smoke/tabs/TabProbeCommon.ps1" -Kind "file" -Purpose "Shared window-title and process-ownership helpers used by browser-pages probes.")
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
        profile = "browser-pages"
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

Write-Host "Browser pages validation surface check"
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
    Write-Host "Browser pages validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} browser-pages validation path(s)." -f $missing.Count)
Write-Host "Repair the missing helper, doc, or probe dependency before trusting the browser-pages shell route."
exit 1