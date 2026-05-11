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
    (New-ValidationReference -Path "docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md" -Kind "file" -Purpose "Main issue #3 guide that routes into the fast quick-validation slice."),
    (New-ValidationReference -Path "scripts/windows/show_google_title_validation_flow.ps1" -Kind "file" -Purpose "Printed title-validation flow that explains the first half of the quick slice."),
    (New-ValidationReference -Path "scripts/windows/check_google_title_validation_surface.ps1" -Kind "file" -Purpose "Dedicated title-validation surface checker used before the quick wrapper widens out."),
    (New-ValidationReference -Path "scripts/windows/show_google_quick_validation_flow.ps1" -Kind "file" -Purpose "Printed flow helper for the fast title-plus-watch quick-validation slice."),
    (New-ValidationReference -Path "scripts/windows/run_google_quick_validation.ps1" -Kind "file" -Purpose "Wrapper runner for the bounded quick-validation slice."),
    (New-ValidationReference -Path "scripts/windows/run_google_input_validation.ps1" -Kind "file" -Purpose "Underlying issue #3 runner that provides the quick phase implementation."),
    (New-ValidationReference -Path "scripts/windows/run_google_home_watch_probe.ps1" -Kind "file" -Purpose "Self-starting headed watch helper used by the quick wrapper after the title pass."),
    (New-ValidationReference -Path "scripts/windows/watch_headed_probe.ps1" -Kind "file" -Purpose "Lower-level watch helper used by the quick watch probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1" -Kind "file" -Purpose "Raw headed title probe that the quick slice still depends on for its bounded first pass."),
    (New-ValidationReference -Path "src/browser/tests/page/google_home_title_probe.html" -Kind "file" -Purpose "Localhost Google-style fixture that drives the quick title markers before the watch handoff.")
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
        profile = "google-quick"
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

Write-Host "Google quick validation surface check"
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
    Write-Host "Google quick validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} quick-validation path(s)." -f $missing.Count)
Write-Host "Repair the missing guide, helper, watch probe, or fixture before trusting the bounded quick issue #3 slice."
exit 1
