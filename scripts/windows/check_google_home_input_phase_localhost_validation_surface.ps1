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
    (New-ValidationReference -Path "docs/GOOGLE_HOME_INPUT_PHASE_LOCALHOST_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the reduced Google localhost input-phase gate."),
    (New-ValidationReference -Path "docs/GOOGLE_INPUT_VALIDATION.md" -Kind "file" -Purpose "Broader issue #3 Google-input note that should point back to this smaller gate."),
    (New-ValidationReference -Path "scripts/windows/check_google_validation_surface.ps1" -Kind "file" -Purpose "Shared Google validation surface dispatcher that should keep this smaller profile discoverable."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Broader issue #3 flow helper that should still route back to this smaller localhost gate."),
    (New-ValidationReference -Path "scripts/windows/check_google_home_input_phase_localhost_validation_surface.ps1" -Kind "file" -Purpose "Dedicated surface checker for this smaller localhost gate."),
    (New-ValidationReference -Path "scripts/windows/show_google_home_input_phase_localhost_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the reduced Google localhost input-phase gate."),
    (New-ValidationReference -Path "scripts/windows/run_google_home_input_phase_localhost_validation.ps1" -Kind "file" -Purpose "One-command wrapper for the reduced Google localhost input-phase gate."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-home-input-phase-localhost-probe.ps1" -Kind "file" -Purpose "Raw reduced Google localhost input-phase probe on the real headed surface.")
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
        profile = "google-home-input-phase-localhost"
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

Write-Host "Google home input-phase localhost validation surface check"
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
    Write-Host "Google home input-phase localhost validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} reduced Google localhost validation path(s)." -f $missing.Count)
Write-Host "Repair the missing note, helper, wrapper, or raw probe before trusting this smaller issue #3 input-phase gate."
exit 1
