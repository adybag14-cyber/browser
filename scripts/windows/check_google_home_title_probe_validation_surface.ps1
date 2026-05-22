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
    (New-ValidationReference -Path "docs/GOOGLE_HOME_TITLE_PROBE_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the reduced Google homepage title probe gate."),
    (New-ValidationReference -Path "docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Broader shared Enter-order note that this reduced homepage probe widens back into."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that should still route developers into the shared Google validation ladder."),
    (New-ValidationReference -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Kind "file" -Purpose "Runtime handoff note for the direct Page.zig and win32_backend.zig fix once the reduced homepage probe points back at runtime."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared repo-root and attached-input helper functions used by validation surfaces."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared suite router that should keep the Google shared Enter-order route discoverable."),
    (New-ValidationReference -Path "scripts/windows/show_google_shared_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Broader shared Enter-order flow helper that should remain the next widening step after the reduced homepage probe."),
    (New-ValidationReference -Path "scripts/windows/show_google_home_title_probe_trace_guide.ps1" -Kind "file" -Purpose "Quick diagnosis helper for interpreting the reduced homepage title probe markers."),
    (New-ValidationReference -Path "scripts/windows/watch_headed_probe.ps1" -Kind "file" -Purpose "Common headed probe watcher that drives the reduced homepage title probe capture."),
    (New-ValidationReference -Path "tmp-browser-smoke/common/Win32Input.ps1" -Kind "file" -Purpose "Shared Win32 input helper used for click and text delivery on headed probes."),
    (New-ValidationReference -Path "tmp-browser-smoke/tabs/TabProbeCommon.ps1" -Kind "file" -Purpose "Shared headed window and owned-process helper used by the reduced homepage probe chain."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1" -Kind "file" -Purpose "Reduced Google homepage title probe on the real headed surface."),
    (New-ValidationReference -Path "src/browser/tests/page/google_home_title_probe.html" -Kind "file" -Purpose "Reduced Google-style homepage fixture served by the headed title probe.")
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
        profile = "google-home-title-probe"
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

Write-Host "Google home title-probe validation surface check"
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
    Write-Host "Google home title-probe validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} reduced homepage title-probe validation path(s)." -f $missing.Count)
Write-Host "Repair the missing note, helper, watcher, probe, or reduced homepage fixture before trusting the Google home title-probe gate."
exit 1
