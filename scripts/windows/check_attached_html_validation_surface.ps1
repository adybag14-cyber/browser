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
    (New-ValidationReference -Path "docs/HEADED_ATTACHED_HTML_VALIDATION.md" -Kind "file" -Purpose "Primary attached-HTML validation guide for the general localhost replay path."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that lists the attached-page helper chain."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md" -Kind "file" -Purpose "Bundle-pinned manual checklist for the known three-page compatibility target set."),
    (New-ValidationReference -Path "tmp-browser-smoke/README.md" -Kind "file" -Purpose "Top-level probe-suite index that routes attached-page follow-up into the bounded suites first."),
    (New-ValidationReference -Path "tmp-browser-smoke/manual-user/README.md" -Kind "file" -Purpose "Manual saved-page and attached-page follow-up guide."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "General attached-HTML flow helper."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_local_asset_closure.ps1" -Kind "file" -Purpose "Deep attached-HTML asset audit that catches missing nested CSS, JavaScript module, image, and font dependencies before launch."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_target_bundle_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast surface checker for the known attached-HTML compatibility bundle route."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_target_bundle.ps1" -Kind "file" -Purpose "Checker for the known three-page attached HTML compatibility target bundle."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1" -Kind "file" -Purpose "Bundle-pinned flow helper that prints the locked compatibility-route commands."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Bundle-pinned localhost runner for the known attached-HTML compatibility target set."),
    (New-ValidationReference -Path "scripts/windows/start_attached_pages_catalog.ps1" -Kind "file" -Purpose "Shared attached-pages catalog helper used by the bundle flow for sidecar and asset audits."),
    (New-ValidationReference -Path "scripts/windows/run_localhost_html_validation_recommended.ps1" -Kind "file" -Purpose "Shared localhost validation router used by the attached-HTML helpers."),
    (New-ValidationReference -Path "scripts/windows/run_sanitized_saved_page_localhost_validation.ps1" -Kind "file" -Purpose "ASCII-safe runner used by the general attached-HTML localhost path after input discovery.")
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
        profile = "attached-html"
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

Write-Host "Attached HTML validation surface check"
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
    Write-Host "Attached HTML validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} attached-HTML validation path(s)." -f $missing.Count)
Write-Host "Repair the missing general guide, bundle route, runner, or asset-audit helper before trusting the broader attached-page localhost follow-up."
exit 1