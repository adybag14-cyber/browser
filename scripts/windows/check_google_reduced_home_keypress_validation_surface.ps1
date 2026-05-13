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
    (New-ValidationReference -Path "docs/GOOGLE_REDUCED_HOME_KEYPRESS_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the reduced-home keypress-before-submit checkpoint."),
    (New-ValidationReference -Path "docs/GOOGLE_SUBMIT_PATH_VALIDATION.md" -Kind "file" -Purpose "Broader later-stage submit-path note that widens out from the reduced-home keypress gate."),
    (New-ValidationReference -Path "scripts/windows/show_google_reduced_home_keypress_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the reduced-home keypress checkpoint."),
    (New-ValidationReference -Path "scripts/windows/run_google_reduced_home_keypress_validation.ps1" -Kind "file" -Purpose "Dedicated reduced-home keypress wrapper."),
    (New-ValidationReference -Path "scripts/windows/show_google_submit_path_validation_flow.ps1" -Kind "file" -Purpose "Broader submit-path flow helper that should still widen out from the reduced-home keypress gate."),
    (New-ValidationReference -Path "scripts/windows/show_google_submit_path_trace_guide.ps1" -Kind "file" -Purpose "Later-stage submit-path trace guide that should stay available after this smaller gate is green."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-home/chrome-google-home-keypress-submit-probe.ps1" -Kind "file" -Purpose "Raw reduced-home keypress-before-submit probe on the real headed surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/common/Win32Input.ps1" -Kind "file" -Purpose "Shared Win32 input helper used by the reduced-home probe for click and text delivery."),
    (New-ValidationReference -Path "tmp-browser-smoke/tabs/TabProbeCommon.ps1" -Kind "file" -Purpose "Shared tab-window helper used by the reduced-home probe for process cleanup and window discovery."),
    (New-ValidationReference -Path "src/browser/tests/page" -Kind "directory" -Purpose "Fixture root that serves the reduced Google-style homepage checkpoint used by the raw probe.")
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
        profile = "google-reduced-home-keypress"
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

Write-Host "Google reduced-home keypress validation surface check"
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
    Write-Host "Google reduced-home keypress validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} reduced-home keypress validation path(s)." -f $missing.Count)
Write-Host "Repair the missing note, helper, probe, or shared dependency before trusting this smaller issue #3 checkpoint."
exit 1
