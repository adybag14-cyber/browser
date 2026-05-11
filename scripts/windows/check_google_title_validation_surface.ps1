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
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the dedicated title-validation slice."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Main issue #3 flow helper that hands off into the title-validation slice."),
    (New-ValidationReference -Path "scripts/windows/show_google_title_validation_flow.ps1" -Kind "file" -Purpose "Printed flow helper for the bounded title-validation slice."),
    (New-ValidationReference -Path "scripts/windows/show_google_title_probe_trace_guide.ps1" -Kind "file" -Purpose "Marker guide for the bounded title probe output."),
    (New-ValidationReference -Path "scripts/windows/run_google_title_validation.ps1" -Kind "file" -Purpose "Wrapper runner for the bounded title-validation slice."),
    (New-ValidationReference -Path "scripts/windows/run_google_home_title_probe.ps1" -Kind "file" -Purpose "Direct PowerShell title probe wrapper used for deeper narrowing."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1" -Kind "file" -Purpose "Raw headed title probe used when the wrapper needs deeper diagnosis."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/GOOGLE_HOME_TITLE_PROBE_TRACE.md" -Kind "file" -Purpose "Read-first note for interpreting the bounded title markers."),
    (New-ValidationReference -Path "src/browser/tests/page/google_home_title_probe.html" -Kind "file" -Purpose "Localhost Google-style fixture that drives the bounded title-validation slice.")
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
        profile = "google-title"
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

Write-Host "Google title validation surface check"
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
    Write-Host "Google title validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} title-validation path(s)." -f $missing.Count)
Write-Host "Repair the missing guide, helper, probe, or fixture before trusting the bounded issue #3 title-validation slice."
exit 1
