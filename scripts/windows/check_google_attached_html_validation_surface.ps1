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
    (New-ValidationReference -Path "docs/HEADED_ATTACHED_HTML_VALIDATION.md" -Kind "file" -Purpose "Primary attached-HTML validation guide."),
    (New-ValidationReference -Path "docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md" -Kind "file" -Purpose "Issue #3 guide that routes into the Google-style attached-HTML follow-up."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md" -Kind "file" -Purpose "Issue #3 attached-html change-area quickstart that keeps the broader attached-page branch visible before the top-level helper narrows replay further."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Issue #3 top-level attached-html quickstart that keeps the dedicated Google-shaped fail-fast follow-up visible beside the compact attached-page helper chain."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that lists the attached-HTML helper chain."),
    (New-ValidationReference -Path "tmp-browser-smoke/README.md" -Kind "file" -Purpose "Top-level probe-suite index for bounded headed validation."),
    (New-ValidationReference -Path "tmp-browser-smoke/manual-user/README.md" -Kind "file" -Purpose "Manual saved-page and attached-page follow-up guide."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "General attached-HTML flow helper."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_localhost_validation.ps1" -Kind "file" -Purpose "General attached-HTML localhost runner."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_local_asset_closure.ps1" -Kind "file" -Purpose "Deep attached-HTML asset audit that catches missing nested CSS, image, and font dependencies before launch."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-style attached-HTML flow helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1" -Kind "file" -Purpose "Issue #3 attached-html change-area helper that bridges the broader attached-page branch into the narrower Google-shaped follow-up."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Issue #3 top-level attached-html helper that keeps the compact attached-page route aligned with the dedicated Google-style follow-up before replay narrows into catalog and shortcut helpers."),
    (New-ValidationReference -Path "scripts/windows/run_google_attached_html_validation.ps1" -Kind "file" -Purpose "Google-style attached-HTML localhost runner."),
    (New-ValidationReference -Path "scripts/windows/run_localhost_html_validation_recommended.ps1" -Kind "file" -Purpose "Shared localhost validation router used by the attached-HTML helpers."),
    (New-ValidationReference -Path "scripts/windows/show_saved_page_google_validation_flow.ps1" -Kind "file" -Purpose "Saved-page Google follow-up flow helper used by the Google-style attached-HTML chain."),
    (New-ValidationReference -Path "scripts/windows/run_saved_page_localhost_validation.ps1" -Kind "file" -Purpose "Saved-page localhost runner used when the follow-up moves out of auto-discovered attachments.")
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
        profile = "google-attached-html"
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

Write-Host "Google attached HTML validation surface check"
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
    Write-Host "Google attached HTML validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} attached-HTML validation path(s)." -f $missing.Count)
Write-Host "Repair the missing guide, quickstart, helper, runner, or asset-audit script before trusting the Google-style attached-HTML follow-up."
exit 1
