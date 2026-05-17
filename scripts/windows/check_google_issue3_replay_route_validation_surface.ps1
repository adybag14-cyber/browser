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

function New-ValidationContentExpectation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Snippet,
        [Parameter(Mandatory = $true)]
        [string]$Purpose
    )

    return [pscustomobject]@{
        Path = $Path
        Snippet = $Snippet
        Purpose = $Purpose
    }
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$references = @(
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE.md" -Kind "file" -Purpose "Primary replay-route note that should stay aligned with the compact helper output."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md" -Kind "file" -Purpose "Replay-route shortcut bridge note that should remain visible from the replay-route surface."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md" -Kind "file" -Purpose "Replay-route bundle-first bridge note that stays aligned when the route pins to the three-page compatibility bundle."),
    (New-ValidationReference -Path "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md" -Kind "file" -Purpose "Replay-discovery handoff note reopened when the replay-route surface widens back out."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Replay quickstart note kept nearby from the replay-route surface."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md" -Kind "file" -Purpose "Pinned bundle reference note that should stay visible when replay-route narrows into the three-page compatibility branch."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md" -Kind "file" -Purpose "Broader validation-chain note that remains the later fallback after the replay-route surface narrows enough."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows runbook reopened when the replay-route surface needs the broader headed route again."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware validation commands."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose attached-page and bundle change-area commands feed the replay-route surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_input_validation_flow.ps1" -Kind "file" -Purpose "Bounded Google flow helper surfaced from the replay-route surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_catalog_entrypoints.ps1" -Kind "file" -Purpose "Suite-catalog bridge helper that the replay-route surface can reopen."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_handoff.ps1" -Kind "file" -Purpose "Suite-router handoff helper that can reopen the broader issue #3 branch before replay-route narrows again."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Next-step matrix helper surfaced from the replay-route surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Kind "file" -Purpose "Replay-route helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Kind "file" -Purpose "Replay-route shortcut helper surfaced as the default narrower follow-up from replay-route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_replay_shortcuts.ps1" -Kind "file" -Purpose "Compact replay-shortcuts helper surfaced once replay-route has already re-established issue #3."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first helper surfaced when replay-route should stay pinned to the known three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_safe_route_entrypoints.ps1" -Kind "file" -Purpose "Wrapper-heavy safe-route map surfaced after replay-route narrows enough."),
    (New-ValidationReference -Path "scripts/windows/run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1" -Kind "file" -Purpose "Fresh safe-route replay helper surfaced from replay-route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1" -Kind "file" -Purpose "Existing-output safe-route wrapper surfaced from replay-route."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_runner_patch_next_step.ps1" -Kind "file" -Purpose "Runner-patch follow-up helper surfaced from replay-route when wrapper state needs the next exact command."),
    (New-ValidationReference -Path "scripts/windows/show_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Broader attached-page localhost flow helper that replay-route reopens beside the narrower shortcut path."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Google-shaped attached-page flow helper kept visible from the replay-route surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1" -Kind "file" -Purpose "Shortcut-first suite-router bridge that replay-route can reopen before narrowing again.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Snippet "replay_route_shortcut_entrypoint_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments ([ordered]@{" -Purpose "Replay-route helper wires the replay-route shortcut helper into its command surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Snippet "attached_bundle_entrypoint_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments ([ordered]@{" -Purpose "Replay-route helper keeps the bundle-first helper wired into the pinned three-page compatibility branch."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Snippet "safe_route_entrypoints_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments ([ordered]@{" -Purpose "Replay-route helper keeps the wrapper-heavy safe-route map wired into its later-stage bridge."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Snippet "Write-Host ((\"  Replay shortcut:       {0}\") -f $route.replay_route_shortcut_entrypoint_command)" -Purpose "Replay-route console output keeps the replay-route shortcut command visible in the read-first bridge."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Snippet "Write-Host ((\"  Bundle helper:       {0}\") -f $route.attached_bundle_entrypoint_command)" -Purpose "Replay-route console output keeps the bundle-first helper visible in the attached-bundle branch."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_replay_route.ps1" -Snippet "'Use replay_route_shortcut_entrypoint_command when you are already inside the replay-route helper and want the smaller attached-HTML, replay-shortcuts, next-step-matrix, contextual-flow, bundle-first, and safe-route companion surface without reopening the broader top-level route first.'" -Purpose "Replay-route guidance still documents when the shortcut helper should be used from this broader surface."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_ROUTE.md" -Snippet "show_google_issue3_replay_route_shortcut_entrypoint.ps1" -Purpose "Replay-route note still names the replay-route shortcut helper as the next narrower bridge."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_REPLAY_ROUTE.md" -Snippet "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md" -Purpose "Replay-route note still keeps the bundle-first bridge visible when the route stays pinned to the three-page compatibility set.")
)

$referenceResults = foreach ($reference in $references) {
    $fullPath = Join-Path $resolvedRepoRoot $reference.Path
    $exists = if ($reference.Kind -eq "directory") {
        Test-Path -LiteralPath $fullPath -PathType Container
    } else {
        Test-Path -LiteralPath $fullPath -PathType Leaf
    }

    [pscustomobject]@{
        CheckType = "reference"
        Path = $reference.Path
        Kind = $reference.Kind
        Purpose = $reference.Purpose
        Exists = [bool]$exists
    }
}

$contentCache = @{}
$contentResults = foreach ($expectation in $contentExpectations) {
    $fullPath = Join-Path $resolvedRepoRoot $expectation.Path
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        [pscustomobject]@{
            CheckType = "content"
            Path = $expectation.Path
            Kind = "content-snippet"
            Purpose = $expectation.Purpose
            Exists = $false
            Snippet = $expectation.Snippet
        }
        continue
    }

    if (-not $contentCache.ContainsKey($fullPath)) {
        $contentCache[$fullPath] = Get-Content -LiteralPath $fullPath -Raw
    }

    [pscustomobject]@{
        CheckType = "content"
        Path = $expectation.Path
        Kind = "content-snippet"
        Purpose = $expectation.Purpose
        Exists = [bool]$contentCache[$fullPath].Contains($expectation.Snippet)
        Snippet = $expectation.Snippet
    }
}

$missingReferences = @($referenceResults | Where-Object { -not $_.Exists })
$missingContent = @($contentResults | Where-Object { -not $_.Exists })
$missing = @($missingReferences + $missingContent)

if ($Json) {
    [ordered]@{
        profile = "google-issue3-replay-route"
        repo_root = $resolvedRepoRoot
        checked_count = @($referenceResults).Count + @($contentResults).Count
        reference_count = @($referenceResults).Count
        content_check_count = @($contentResults).Count
        missing_count = @($missing).Count
        references = @($referenceResults)
        content_checks = @($contentResults)
    } | ConvertTo-Json -Depth 6

    if ($missing.Count -gt 0) {
        exit 1
    }

    exit 0
}

Write-Host "Google issue #3 replay-route surface check"
Write-Host ""
Write-Host (("Repo root: {0}") -f $resolvedRepoRoot)
Write-Host ""

foreach ($result in $referenceResults) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host (("[{0}] {1}") -f $status, $result.Path)
    Write-Host (("  {0}") -f $result.Purpose)
}

if ($contentResults.Count -gt 0) {
    Write-Host ""
    Write-Host "Helper source expectations:"
    foreach ($result in $contentResults) {
        $status = if ($result.Exists) { "PASS" } else { "FAIL" }
        Write-Host (("[{0}] {1}") -f $status, $result.Path)
        Write-Host (("  {0}") -f $result.Purpose)
    }
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "Google issue #3 replay-route surface is intact."
    exit 0
}

Write-Host (("Missing {0} replay-route path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing replay-route note, shortcut bridge, bundle-aware helper, safe-route companion, or helper-output contract before trusting this compact issue #3 replay surface."
exit 1
