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
    (New-ValidationReference -Path "docs/GOOGLE_SUBMIT_TIMING_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the bounded issue #3 submit-timing slice."),
    (New-ValidationReference -Path "docs/GOOGLE_SUBMIT_PATH_VALIDATION.md" -Kind "file" -Purpose "Broader later-stage issue #3 note that routes into the submit-timing slice."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the submit-timing helper."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared suite router that should keep the bounded submit-timing slice discoverable."),
    (New-ValidationReference -Path "scripts/windows/show_google_submit_timing_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the bounded submit-timing slice."),
    (New-ValidationReference -Path "scripts/windows/run_google_submit_timing_validation.ps1" -Kind "file" -Purpose "One-command bounded submit-timing wrapper."),
    (New-ValidationReference -Path "tmp-browser-smoke/layout-smoke/chrome-google-submit-timing-probe.ps1" -Kind "file" -Purpose "Raw Google-shaped headed keydown, keypress, and submit-ordering probe.")
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
        profile = "google-submit-timing"
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

Write-Host "Google submit-timing validation surface check"
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
    Write-Host "Google submit-timing validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} submit-timing validation path(s)." -f $missing.Count)
Write-Host "Repair the missing guide, helper, wrapper, or raw probe before trusting the bounded issue #3 submit-timing slice."
exit 1
