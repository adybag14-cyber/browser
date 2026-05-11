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
    (New-ValidationReference -Path "docs/GOOGLE_HOME_INPUT_PHASE_LOCALHOST_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the reduced-home localhost input-phase checkpoint."),
    (New-ValidationReference -Path "docs/GOOGLE_HOMEPAGE_FIXTURE_VALIDATION.md" -Kind "file" -Purpose "Earlier bounded homepage-fixture note that feeds into this checkpoint."),
    (New-ValidationReference -Path "docs/GOOGLE_SUBMIT_TIMING_VALIDATION.md" -Kind "file" -Purpose "Later bounded timing note that should stay available after this checkpoint is green."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the reduced-home localhost checkpoint."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Broader issue #3 flow helper that should keep this narrower checkpoint discoverable."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_recommended_validation_flow.ps1" -Kind "file" -Purpose "Recommended issue #3 flow helper that should print this checkpoint before the later timing and shared ladders."),
    (New-ValidationReference -Path "scripts/windows/show_google_home_input_phase_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the reduced-home localhost input-phase checkpoint."),
    (New-ValidationReference -Path "scripts/windows/run_google_home_input_phase_validation.ps1" -Kind "file" -Purpose "One-command reduced-home localhost input-phase wrapper."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-home-input-phase-localhost-probe.ps1" -Kind "file" -Purpose "Raw reduced-home localhost keypress-before-submit probe on the real headed surface.")
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

Write-Host ("Missing {0} input-phase localhost validation path(s)." -f $missing.Count)
Write-Host "Repair the missing guide, helper, wrapper, or probe before trusting the reduced-home localhost keypress-before-submit checkpoint."
exit 1
