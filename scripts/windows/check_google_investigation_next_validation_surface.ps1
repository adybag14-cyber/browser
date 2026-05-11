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
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the reduced Google investigation probes."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared suite router that should keep the reduced Google investigation suite discoverable."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Broader issue #3 flow helper that should continue to route through the reduced localhost suite first."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation.ps1" -Kind "file" -Purpose "One-command issue #3 runner that depends on the reduced localhost suite near the front of the stack."),
    (New-ValidationReference -Path "scripts/windows/show_google_investigation_next_validation_flow.ps1" -Kind "file" -Purpose "Printed flow helper for the reduced Google investigation suite."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/README.md" -Kind "file" -Purpose "Read-first note for the bounded localhost Google investigation probes."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/GoogleProbeCommon.ps1" -Kind "file" -Purpose "Shared helper layer for the bounded localhost Google investigation probes."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google_home_server.py" -Kind "file" -Purpose "Reusable localhost server for the reduced Google investigation probes."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-style-localhost-probe.ps1" -Kind "file" -Purpose "Baseline Google-style named-form localhost probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-style-correction-localhost-probe.ps1" -Kind "file" -Purpose "Correction and backspace localhost probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-enter-order-localhost-probe.ps1" -Kind "file" -Purpose "Enter-order localhost probe that distinguishes keydown from keypress submit."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-style-delayed-ready-localhost-probe.ps1" -Kind "file" -Purpose "Delayed-readiness localhost probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-home-enter-trace-probe.ps1" -Kind "file" -Purpose "Reduced homepage headed trace probe on the real Win32 surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-home-input-probe.ps1" -Kind "file" -Purpose "Live Google homepage headed trace probe."),
    (New-ValidationReference -Path "src/browser/tests/page/headed_google_style_input_probe.html" -Kind "file" -Purpose "Baseline Google-style localhost fixture."),
    (New-ValidationReference -Path "src/browser/tests/page/headed_google_style_input_correction_probe.html" -Kind "file" -Purpose "Correction localhost fixture."),
    (New-ValidationReference -Path "src/browser/tests/page/headed_google_style_input_delayed_ready_probe.html" -Kind "file" -Purpose "Delayed-readiness localhost fixture."),
    (New-ValidationReference -Path "src/browser/tests/page/headed_google_enter_order_probe.html" -Kind "file" -Purpose "Enter-order localhost fixture."),
    (New-ValidationReference -Path "src/browser/tests/page/google_home_title_probe.html" -Kind "file" -Purpose "Reduced homepage fixture reused by the real-surface trace step.")
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
        profile = "google-investigation-next"
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

Write-Host "Google investigation-next validation surface check"
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
    Write-Host "Google investigation-next validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} google-investigation-next validation path(s)." -f $missing.Count)
Write-Host "Repair the missing guide, helper, runner, probe, or fixture before trusting the reduced localhost Google investigation suite."
exit 1
