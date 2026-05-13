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
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows headed runbook that routes operators from the top-level validation router into the current issue #3 replay helpers."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Shortest issue #3 replay note for the current safe-route path."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Current wrapper-order note for fresh issue #3 replay and runner handoff sequencing."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Read-first bridge from the higher-level suite router into the replay-route and replay-shortcuts helpers."),
    (New-ValidationReference -Path "docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md" -Kind "file" -Purpose "Direct runner patch loop reference once the safe-route handoff lands on a narrowed state."),
    (New-ValidationReference -Path "docs/ISSUE3_REPO_ROOT_SAFE_REPLAY.md" -Kind "file" -Purpose "Repo-root-aware replay note for preserving non-default checkout context through the issue #3 helper chain."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level headed validation router that exposes the issue #3 suite and change-area entry points."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Bounded localhost-first Google flow helper printed before the narrower issue #3 replay helpers."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Kind "file" -Purpose "Compact helper that keeps the higher-level suite-router entrypoints and the current issue #3 replay helpers together."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Broader issue #3 replay route helper that bridges the suite router, attached-bundle branch, and safe-route next steps."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Narrower issue #3 replay helper that keeps the direct shortcut map, attached bundle route, and safe-route bridge together."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Pinned three-page compatibility-bundle entrypoint for the current issue #3 replay family."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Safe-route helper map that follows the higher-level suite-router and replay-route helpers."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_runner_patch_next_step.ps1" -Kind "file" -Purpose "State-specific runner next-step helper for ready-for-runner-patch, already-direct, and regenerate-outputs states."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_target_bundle_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the attached three-page compatibility bundle route referenced by the issue #3 replay helpers."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the Google-style attached HTML follow-up referenced by the bundle and replay helpers."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_target_bundle_validation_flow.ps1" -Kind "file" -Purpose "Bundle-aware flow helper used when the current replay should stay pinned to the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Kind "file" -Purpose "Bundle-aware localhost runner delegated to by the attached-bundle-first helper."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1" -Kind "file" -Purpose "Default fresh issue #3 safe-route replay that regenerates the current runner handoff artifact."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1" -Kind "file" -Purpose "Helper for reusing already-current issue #3 safe-route outputs without a broader regeneration first.")
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
        profile = "google-issue3-suite-router-handoff"
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

Write-Host "Google issue #3 suite-router handoff surface check"
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
    Write-Host "Google issue #3 suite-router handoff surface is intact."
    exit 0
}

Write-Host ("Missing {0} issue #3 suite-router handoff path(s)." -f $missing.Count)
Write-Host "Repair the missing runbook, replay note, suite router, helper, bundle path, or safe-route script before trusting the higher-level issue #3 replay chain."
exit 1
