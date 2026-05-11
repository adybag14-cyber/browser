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
    (New-ValidationReference -Path "docs/GOOGLE_TRACE_VALIDATION.md" -Kind "file" -Purpose "Dedicated read-first note for the later issue #3 trace handoff."),
    (New-ValidationReference -Path "docs/GOOGLE_SUBMIT_PATH_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the later issue #3 submit-path ladder that should already be green before live trace capture."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the trace handoff after the bounded issue #3 gates."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared suite router that should keep the live trace handoff discoverable."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Main issue #3 flow helper that points at the trace handoff."),
    (New-ValidationReference -Path "scripts/windows/show_google_submit_path_validation_flow.ps1" -Kind "file" -Purpose "Printed later-stage submit-path handoff that precedes the live trace slice."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_submit_path_validation.ps1" -Kind "file" -Purpose "One-command later-stage submit-path runner used before live trace capture."),
    (New-ValidationReference -Path "scripts/windows/show_google_trace_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the later issue #3 trace-validation slice."),
    (New-ValidationReference -Path "scripts/windows/run_google_trace_validation.ps1" -Kind "file" -Purpose "One-command later-stage trace runner for the dedicated live-trace handoff."),
    (New-ValidationReference -Path "scripts/windows/run_google_input_validation.ps1" -Kind "file" -Purpose "Shared issue #3 runner that exposes the trace phase."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-home-enter-trace-probe.ps1" -Kind "file" -Purpose "Reduced-home trace probe used before the real Google homepage capture."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-home-input-probe.ps1" -Kind "file" -Purpose "Raw live Google homepage trace probe for deeper headed-input narrowing.")
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
        profile = "google-trace"
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

Write-Host "Google trace validation surface check"
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
    Write-Host "Google trace validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} trace-validation path(s)." -f $missing.Count)
Write-Host "Repair the missing guide, helper, or probe before trusting the live Google trace handoff."
exit 1
