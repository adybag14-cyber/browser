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
    (New-ValidationReference -Path "docs/GOOGLE_HOMEPAGE_FIXTURE_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the bounded Google homepage-fixture checkpoint."),
    (New-ValidationReference -Path "docs/HEADED_GOOGLE_VALIDATION_WINDOWS.md" -Kind "file" -Purpose "Main issue #3 guide that routes into the bounded homepage-fixture slice."),
    (New-ValidationReference -Path "docs/GOOGLE_SUBMIT_PATH_VALIDATION.md" -Kind "file" -Purpose "Later-stage note that picks up after the homepage-fixture slice is green."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that lists the homepage-fixture helper chain."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared suite router that should keep the homepage-fixture slice discoverable."),
    (New-ValidationReference -Path "scripts/windows/show_google_homepage_fixture_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the bounded homepage-fixture slice."),
    (New-ValidationReference -Path "scripts/windows/run_google_homepage_fixture_validation.ps1" -Kind "file" -Purpose "One-command bounded homepage-fixture runner."),
    (New-ValidationReference -Path "scripts/windows/show_google_submit_path_validation_flow.ps1" -Kind "file" -Purpose "Follow-on submit-path flow helper that should stay available after the homepage-fixture gate."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_submit_path_validation.ps1" -Kind "file" -Purpose "Follow-on later-stage submit-path runner."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/chrome-google-homepage-probe.ps1" -Kind "file" -Purpose "Raw bounded homepage-fixture probe on the real headed surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/form_server.py" -Kind "file" -Purpose "Localhost helper used by the shared form-controls probes."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/README.md" -Kind "file" -Purpose "Directory note for the shared form-controls and homepage-fixture probes.")
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
        profile = "google-homepage-fixture"
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

Write-Host "Google homepage-fixture validation surface check"
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
    Write-Host "Google homepage-fixture validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} homepage-fixture validation path(s)." -f $missing.Count)
Write-Host "Repair the missing guide, helper, or probe before trusting the bounded homepage-fixture slice."
exit 1
