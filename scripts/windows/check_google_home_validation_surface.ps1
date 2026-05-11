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
    (New-ValidationReference -Path "docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md" -Kind "file" -Purpose "Main issue #3 guide that routes into the reduced homepage stage."),
    (New-ValidationReference -Path "docs/GOOGLE_HOME_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the dedicated reduced homepage gate."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that lists the reduced homepage runner among the issue #3 helpers."),
    (New-ValidationReference -Path "scripts/windows/show_google_quick_validation_flow.ps1" -Kind "file" -Purpose "Printed quick-validation handoff that should stay green before the reduced homepage gate."),
    (New-ValidationReference -Path "scripts/windows/run_google_quick_validation.ps1" -Kind "file" -Purpose "Dedicated quick-validation runner that feeds into the reduced homepage checkpoint."),
    (New-ValidationReference -Path "scripts/windows/show_google_home_validation_flow.ps1" -Kind "file" -Purpose "Printed flow helper for the reduced homepage validation slice."),
    (New-ValidationReference -Path "scripts/windows/run_google_home_validation.ps1" -Kind "file" -Purpose "Wrapper runner for the reduced homepage validation slice."),
    (New-ValidationReference -Path "scripts/windows/run_google_input_validation.ps1" -Kind "file" -Purpose "Underlying issue #3 runner that provides the home phase implementation."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-home/README.md" -Kind "file" -Purpose "Reduced-homepage suite note for the real-surface Google helper."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-home/chrome-google-home-enter-probe.ps1" -Kind "file" -Purpose "Raw reduced homepage probe that the wrapper still depends on."),
    (New-ValidationReference -Path "src/browser/tests/page/google_home_title_probe.html" -Kind "file" -Purpose "Localhost Google-style fixture that drives the reduced homepage title markers.")
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
        profile = "google-home"
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

Write-Host "Google reduced homepage validation surface check"
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
    Write-Host "Google reduced homepage validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} reduced homepage validation path(s)." -f $missing.Count)
Write-Host "Repair the missing guide, helper, runner, or raw reduced-homepage probe before trusting this bounded real-surface issue #3 slice."
exit 1
