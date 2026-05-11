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
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes into the shared form-controls validation helpers."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Shared suite router that should keep the form-controls ladder discoverable."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Issue #3 flow helper that should still point at the shared form-controls ladder."),
    (New-ValidationReference -Path "scripts/windows/show_form_controls_validation_flow.ps1" -Kind "file" -Purpose "Printed command ladder for the shared headed form-controls validation stack."),
    (New-ValidationReference -Path "scripts/windows/run_form_controls_validation_recommended.ps1" -Kind "file" -Purpose "One-command shared form-controls validation runner."),
    (New-ValidationReference -Path "scripts/windows/run_form_controls_validation.ps1" -Kind "file" -Purpose "Shared probe dispatcher for the headed form-controls stack."),
    (New-ValidationReference -Path "scripts/windows/run_google_home_title_probe.ps1" -Kind "file" -Purpose "Bounded reduced Google title gate used inside the shared form-controls ladder."),
    (New-ValidationReference -Path "scripts/windows/show_google_form_controls_enter_order_validation_flow.ps1" -Kind "file" -Purpose "Dedicated Google-style Enter-order flow helper that widens out from the shared ladder."),
    (New-ValidationReference -Path "scripts/windows/show_google_form_controls_enter_order_trace_guide.ps1" -Kind "file" -Purpose "Dedicated Google-style Enter-order trace guide referenced from the shared form-controls notes."),
    (New-ValidationReference -Path "scripts/windows/run_google_form_controls_enter_order_validation.ps1" -Kind "file" -Purpose "Dedicated Google-style Enter-order runner linked from the shared ladder."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/README.md" -Kind "file" -Purpose "Read-first notes for the shared form-controls probes."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/label-click-probe.ps1" -Kind "file" -Purpose "Label activation probe for the headed baseline."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "Immediate Enter-submit probe for the shared baseline."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/deferred-enter-submit-probe.ps1" -Kind "file" -Purpose "Deferred Enter-submit probe for the pending-submit path."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/chrome-google-home-enter-submit-probe.ps1" -Kind "file" -Purpose "Reduced Google-home submit probe used before the stricter Enter-order gate."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/chrome-google-enter-order-probe.ps1" -Kind "file" -Purpose "Compatibility wrapper for the stricter Google-style Enter-order probe."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/google-enter-order-probe.ps1" -Kind "file" -Purpose "Smallest shared headed Google-style Enter-order probe." )
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
        profile = "form-controls"
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

Write-Host "Form-controls validation surface check"
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
    Write-Host "Form-controls validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} form-controls validation path(s)." -f $missing.Count)
Write-Host "Repair the missing helper, router, runner, note, or probe before trusting the shared form-controls ladder."
exit 1
