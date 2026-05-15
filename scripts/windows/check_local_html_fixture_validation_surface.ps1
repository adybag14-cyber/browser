[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string[]]$InputPath,
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

$inputMode = if ($InputPath -and $InputPath.Count -gt 0) {
    "explicit"
} else {
    "auto-discovered"
}
$explicitInputPathCount = if ($InputPath) { @($InputPath).Count } else { 0 }

$references = @(
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that documents the reusable local HTML fixture probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/README.md" -Kind "file" -Purpose "Top-level probe-suite index that routes saved-page follow-up into the local fixture probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/local-html-fixtures" -Kind "directory" -Purpose "Reusable staged localhost fixture workspace for saved HTML validation."),
    (New-ValidationReference -Path "tmp-browser-smoke/local-html-fixtures/chrome-local-html-fixture-probe.ps1" -Kind "file" -Purpose "Main reusable local HTML fixture probe runner."),
    (New-ValidationReference -Path "scripts/windows/check_local_html_fixture_asset_closure.ps1" -Kind "file" -Purpose "Dedicated deep asset-closure preflight for fixed local HTML fixture bundles."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_local_asset_closure.ps1" -Kind "file" -Purpose "Shared recursive CSS and module-asset audit used by the local fixture asset-closure preflight."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared validation helper surface used by the local fixture preflight wrappers."),
    (New-ValidationReference -Path "tmp-browser-smoke/common/Win32Input.ps1" -Kind "file" -Purpose "Shared headed Win32 window helpers used by the fixture probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/tabs/TabProbeCommon.ps1" -Kind "file" -Purpose "Shared probe process ownership helpers used by the fixture probe."),
    (New-ValidationReference -Path "scripts/windows/check_saved_page_localhost_validation_surface.ps1" -Kind "file" -Purpose "Broader saved-page localhost surface checker that now includes this reusable fixture path.")
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
        profile = "local-html-fixture"
        repo_root = $resolvedRepoRoot
        input_mode = $inputMode
        explicit_input_path_count = $explicitInputPathCount
        checked_count = @($results).Count
        missing_count = @($missing).Count
        references = @($results)
    } | ConvertTo-Json -Depth 6

    if ($missing.Count -gt 0) {
        exit 1
    }

    exit 0
}

Write-Host "Local HTML fixture validation surface check"
Write-Host ""
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
Write-Host ("Input mode: {0}" -f $inputMode)
if ($explicitInputPathCount -gt 0) {
    Write-Host ("Explicit input paths: {0}" -f $explicitInputPathCount)
}
Write-Host ""

foreach ($result in $results) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host ("[{0}] {1}" -f $status, $result.Path)
    Write-Host ("  {0}" -f $result.Purpose)
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Local HTML fixture validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} local HTML fixture validation path(s)." -f $missing.Count)
Write-Host "Repair the missing guide, helper, deep asset audit dependency, or probe directory before trusting the reusable local fixture replay path."
exit 1
