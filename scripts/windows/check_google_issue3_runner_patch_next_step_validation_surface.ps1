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
    (New-ValidationReference -Path "docs/ISSUE3_REPO_ROOT_SAFE_REPLAY.md" -Kind "file" -Purpose "Repo-root replay note that now routes into the runner-patch next-step checker before acting on a saved handoff state."),
    (New-ValidationReference -Path "docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md" -Kind "file" -Purpose "Primary state-to-action reference for runner-patch handoff outcomes."),
    (New-ValidationReference -Path "docs/ISSUE3_RUNNER_OUTPUT_PATCH_RULES.md" -Kind "file" -Purpose "Field-level runner output patch rules referenced when the handoff still needs a direct source edit."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Shortest safe-route replay note used before widening back into the runner-patch lane."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Wrapper-order note for the broader issue #3 replay path."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_runner_patch_next_step.ps1" -Kind "file" -Purpose "Runner-patch next-step helper that translates wrapper states into concrete commands."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Safe-route entrypoint helper used to regain the broader replay context before or after the runner-patch state is handled."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay shortcut helper used when the broader issue #3 context needs to be reopened quickly."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level suite router that still serves as the first read for broader issue #3 validation re-entry."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation.ps1" -Kind "file" -Purpose "Direct runner source that still needs inspection when the handoff state is ready-for-runner-patch."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1" -Kind "file" -Purpose "Fresh safe-route handoff wrapper that emits the runner-patch state."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1" -Kind "file" -Purpose "Reuse-current-outputs wrapper that reopens the runner-patch guidance without a broader rerun."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_runner_output_wiring_status_safe.ps1" -Kind "file" -Purpose "Safe wiring audit reopened after the runner-patch handoff is handled."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_runner_output_wiring_status.ps1" -Kind "file" -Purpose "Raw wiring audit used only after the safe audit routes there."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation_repair_runner_output_contract_safe_route.ps1" -Kind "file" -Purpose "Repair wrapper used when the runner is already wired and only saved outputs need regeneration.")
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
        profile = "google-issue3-runner-patch-next-step"
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

Write-Host "Google issue #3 runner-patch next-step validation surface check"
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
    Write-Host "Google issue #3 runner-patch next-step validation surface is intact."
    exit 0
}

Write-Host ("Missing {0} runner-patch next-step validation path(s)." -f $missing.Count)
Write-Host "Repair the missing replay note, helper, wrapper, runner, or decision-table path before trusting the issue #3 runner-patch handoff state."
exit 1
