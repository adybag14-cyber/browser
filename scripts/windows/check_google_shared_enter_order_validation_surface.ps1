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
    (New-ValidationReference -Path "docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the shared Enter-order ladder."),
    (New-ValidationReference -Path "docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the final shared form-controls gate."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the shared Enter-order helpers."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared headed validation suite router that should keep the google-shared-enter-order slice reachable from the broader catalog."),
    (New-ValidationReference -Path "scripts/windows/show_google_shared_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the shared Enter-order slice."),
    (New-ValidationReference -Path "scripts/windows/run_google_shared_enter_order_validation.ps1" -Kind "file" -Purpose "One-command shared Enter-order runner."),
    (New-ValidationReference -Path "scripts/windows/check_google_form_controls_enter_order_validation_surface.ps1" -Kind "file" -Purpose "Dedicated fail-fast checker for the final shared form-controls gate."),
    (New-ValidationReference -Path "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the final shared form-controls gate."),
    (New-ValidationReference -Path "scripts/windows/run_google_form_controls_enter_order_validation.ps1" -Kind "file" -Purpose "Dedicated shared form-controls Enter-order runner."),
    (New-ValidationReference -Path "scripts/windows/run_google_input_validation.ps1" -Kind "file" -Purpose "Shared baseline runner used before the stricter Enter-order probes."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-title-probe.ps1" -Kind "file" -Purpose "Reduced localhost Google title probe used before the Enter-order wrapper."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-home/chrome-google-home-keypress-submit-probe.ps1" -Kind "file" -Purpose "Reduced homepage keypress-before-submit probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-enter-order-localhost-probe.ps1" -Kind "file" -Purpose "Localhost Enter-order wrapper used before broader replay."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1" -Kind "file" -Purpose "Smallest shared form-controls Enter-order probe on the real headed surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/README.md" -Kind "file" -Purpose "Shared form-controls suite note for the final bounded gate.")
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
        profile = "google-shared-enter-order"
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

Write-Host "Google shared Enter-order validation surface check"
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
    Write-Host "Google shared Enter-order validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} shared Enter-order validation path(s)." -f $missing.Count)
Write-Host "Repair the missing guide, helper, probe, or suite-router entrypoint before trusting the shared Enter-order ladder."
exit 1
