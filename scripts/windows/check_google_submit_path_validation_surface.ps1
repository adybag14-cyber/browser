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
    (New-ValidationReference -Path "docs/GOOGLE_SUBMIT_PATH_VALIDATION.md" -Kind "file" -Purpose "Read-first note for the later issue #3 submit-path ladder."),
    (New-ValidationReference -Path "docs/GOOGLE_SHARED_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Shared Enter-order note used after the submit-timing slice."),
    (New-ValidationReference -Path "docs/GOOGLE_FORM_CONTROLS_ENTER_ORDER_VALIDATION.md" -Kind "file" -Purpose "Smallest shared Enter-order note for the final bounded proof."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the submit-path helpers."),
    (New-ValidationReference -Path "scripts/windows/show_google_submit_path_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the later issue #3 submit-path slice."),
    (New-ValidationReference -Path "scripts/windows/show_google_submit_path_handoff.ps1" -Kind "file" -Purpose "Saved reduced Enter-analysis handoff helper for the next bounded submit-path replay."),
    (New-ValidationReference -Path "scripts/windows/show_google_submit_path_trace_guide.ps1" -Kind "file" -Purpose "Read-first trace helper for the later submit-path ladder."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_submit_path_validation.ps1" -Kind "file" -Purpose "One-command later-stage issue #3 submit-path runner."),
    (New-ValidationReference -Path "scripts/windows/show_google_homepage_fixture_validation_flow.ps1" -Kind "file" -Purpose "Saved homepage fixture flow helper."),
    (New-ValidationReference -Path "scripts/windows/run_google_homepage_fixture_validation.ps1" -Kind "file" -Purpose "Saved homepage fixture runner."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/analyze-google-enter-trace.ps1" -Kind "file" -Purpose "Reduced Google Enter-trace analyzer used to preserve the bounded post-run diagnosis artifact."),
    (New-ValidationReference -Path "scripts/windows/show_google_submit_timing_validation_flow.ps1" -Kind "file" -Purpose "Submit-timing flow helper."),
    (New-ValidationReference -Path "scripts/windows/run_google_submit_timing_validation.ps1" -Kind "file" -Purpose "Bounded submit-timing runner."),
    (New-ValidationReference -Path "scripts/windows/show_google_shared_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Shared Enter-order flow helper."),
    (New-ValidationReference -Path "scripts/windows/run_google_shared_enter_order_validation.ps1" -Kind "file" -Purpose "Shared Enter-order ladder runner."),
    (New-ValidationReference -Path "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Dedicated shared form-controls Enter-order flow helper."),
    (New-ValidationReference -Path "scripts/windows/run_google_form_controls_enter_order_validation.ps1" -Kind "file" -Purpose "Dedicated shared form-controls Enter-order runner."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/chrome-google-homepage-probe.ps1" -Kind "file" -Purpose "Bounded saved homepage fixture probe on the real headed surface."),
    (New-ValidationReference -Path "tmp-browser-smoke/layout-smoke/chrome-google-submit-timing-probe.ps1" -Kind "file" -Purpose "Bounded keydown, keypress, and submit-ordering probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-home/chrome-google-home-keypress-submit-probe.ps1" -Kind "file" -Purpose "Reduced homepage keypress-before-submit probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/google-enter-order-localhost-probe.ps1" -Kind "file" -Purpose "Reusable localhost Enter-order wrapper used before wider replay."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-home/README.md" -Kind "file" -Purpose "Reduced homepage suite note for the bounded submit-path handoff."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/README.md" -Kind "file" -Purpose "Shared form-controls suite note for the last bounded submit-order gate.")
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
        profile = "google-submit-path"
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

Write-Host "Google submit-path validation surface check"
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
    Write-Host "Google submit-path validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} submit-path validation path(s)." -f $missing.Count)
Write-Host "Repair the missing guide, helper, analyzer, or probe before trusting the later issue #3 submit-path ladder."
exit 1
