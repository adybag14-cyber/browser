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
    (New-ValidationReference -Path "docs/HEADED_ATTACHED_HTML_VALIDATION.md" -Kind "file" -Purpose "Attached-HTML guide that routes general saved-page follow-up."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that lists the saved-page localhost helpers."),
    (New-ValidationReference -Path "tmp-browser-smoke/README.md" -Kind "file" -Purpose "Top-level probe-suite index for bounded headed validation."),
    (New-ValidationReference -Path "tmp-browser-smoke/manual-user/README.md" -Kind "file" -Purpose "Manual saved-page and attached-page follow-up guide."),
    (New-ValidationReference -Path "scripts/windows/show_localhost_html_validation_flow.ps1" -Kind "file" -Purpose "General saved-page localhost flow helper."),
    (New-ValidationReference -Path "scripts/windows/run_localhost_html_validation_recommended.ps1" -Kind "file" -Purpose "Shared localhost validation router used by the saved-page helpers."),
    (New-ValidationReference -Path "scripts/windows/run_saved_page_localhost_validation.ps1" -Kind "file" -Purpose "Saved-page localhost runner for direct directory inputs."),
    (New-ValidationReference -Path "scripts/windows/run_sanitized_saved_page_localhost_validation.ps1" -Kind "file" -Purpose "ASCII-safe runner for Unicode-heavy or standalone exported saved pages."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_localhost_validation.ps1" -Kind "file" -Purpose "Attached-HTML localhost runner that auto-discovers current-run snapshots."),
    (New-ValidationReference -Path "scripts/windows/start_localhost_html_validation.ps1" -Kind "file" -Purpose "Direct localhost launcher for one saved-page root."),
    (New-ValidationReference -Path "scripts/windows/start_staged_localhost_html_validation.ps1" -Kind "file" -Purpose "Staged localhost launcher for mixed saved-page inputs."),
    (New-ValidationReference -Path "scripts/windows/summarize_localhost_html_pages.ps1" -Kind "file" -Purpose "Saved-page inventory helper used before manual headed replay.")
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
        profile = "saved-page-localhost"
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

Write-Host "Saved-page localhost validation surface check"
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
    Write-Host "Saved-page localhost validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} saved-page localhost validation path(s)." -f $missing.Count)
Write-Host "Repair the missing guide, helper, runner, or inventory script before trusting the manual saved-page headed follow-up."
exit 1
