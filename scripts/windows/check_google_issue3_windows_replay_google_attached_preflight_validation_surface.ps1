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
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Compact replay quickstart note that can hand off into this replay-side preflight lane."),
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Replay-side attached-html quickstart note that should stay aligned with this preflight lane."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md" -Kind "file" -Purpose "Dedicated Google attached-page flow note reopened after the wrapper-backed launcher audits."),
    (New-ValidationReference -Path "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md" -Kind "file" -Purpose "Issue-specific Google attached-page entrypoint note reopened after the wrapper-backed launcher audits."),
    (New-ValidationReference -Path "docs/ISSUE3_SUITE_ROUTER_NEXT_STEPS.md" -Kind "file" -Purpose "Executable next-step matrix note reopened after the replay-side launcher preflight lane."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware commands."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_windows_replay_google_attached_preflight_validation_surface.ps1" -Kind "file" -Purpose "Fail-fast checker for the replay-side Google attached preflight surface."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_google_attached_preflight.ps1" -Kind "file" -Purpose "Replay-side Google attached preflight helper that this checker validates."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1" -Kind "file" -Purpose "Launcher companion checker reused before the wrapper-backed sidecar and asset ladder."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1" -Kind "file" -Purpose "Launcher companion helper reused by the replay-side preflight lane."),
    (New-ValidationReference -Path "scripts/windows/start_attached_pages_catalog.ps1" -Kind "file" -Purpose "Windows wrapper that provides the Google-style sidecar, asset, manifest, and launch commands."),
    (New-ValidationReference -Path "scripts/windows/check_google_attached_html_validation_surface.ps1" -Kind "file" -Purpose "Broader Google attached-page surface checker reopened after the wrapper-backed launcher audits."),
    (New-ValidationReference -Path "scripts/windows/check_attached_html_local_asset_closure.ps1" -Kind "file" -Purpose "Deeper asset-closure audit reopened after the lighter sidecar audit."),
    (New-ValidationReference -Path "scripts/windows/show_google_attached_html_validation_flow.ps1" -Kind "file" -Purpose "Dedicated Google attached-page flow helper reopened after the wrapper-backed launcher audits."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1" -Kind "file" -Purpose "Issue-specific Google attached-page checker reopened after the wrapper-backed launcher audits."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1" -Kind "file" -Purpose "Issue-specific Google attached-page entrypoint helper reopened after the wrapper-backed launcher audits."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_suite_router_next_steps.ps1" -Kind "file" -Purpose "Next-step matrix helper reopened after the replay-side launcher preflight lane."),
    (New-ValidationReference -Path "tmp-browser-smoke/attached-pages/README.md" -Kind "file" -Purpose "Attached-pages launcher guide that should stay aligned with the replay-side preflight lane.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_google_attached_preflight.ps1" -Snippet "surface_check_command = Format-HelperCommand -ScriptName 'check_google_issue3_windows_replay_google_attached_preflight_validation_surface.ps1' -Arguments \$surfaceCheckArguments" -Purpose "Replay-side preflight helper keeps its dedicated fail-fast checker wired into the helper surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_google_attached_preflight.ps1" -Snippet "launcher_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments \$surfaceCheckArguments" -Purpose "Replay-side preflight helper reruns the launcher companion checker before trusting the wrapper-backed preflight ladder."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_google_attached_preflight.ps1" -Snippet "wrapper_google_sidecar_audit = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments \$launcherArguments -Switches @('GoogleStyle', 'AuditSidecars')" -Purpose "Replay-side preflight helper keeps the wrapper-backed Google sidecar audit visible."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_google_attached_preflight.ps1" -Snippet "wrapper_google_asset_audit = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments \$launcherArguments -Switches @('GoogleStyle', 'AuditAssets')" -Purpose "Replay-side preflight helper keeps the wrapper-backed Google asset audit visible."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_google_attached_preflight.ps1" -Snippet "google_asset_closure = Format-HelperCommand -ScriptName 'check_attached_html_local_asset_closure.ps1' -Arguments \$googleFlowArguments -Switches @('GoogleStyle')" -Purpose "Replay-side preflight helper keeps the deeper Google asset-closure audit visible after the lighter wrapper-backed launcher audits."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_google_attached_preflight.ps1" -Snippet "google_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments \$sharedArguments" -Purpose "Replay-side preflight helper keeps the issue-specific Google entrypoint visible after the launcher audits."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_google_attached_preflight.ps1" -Snippet "Write-Host ((\"  3. Sidecar audit:       {0}\") -f \$helper.helper_commands.wrapper_google_sidecar_audit)" -Purpose "Replay-side preflight helper prints the wrapper-backed sidecar audit early in the ladder."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_google_attached_preflight.ps1" -Snippet "Write-Host ((\"Launcher companion:       {0}\") -f \$helper.companion_paths.attached_pages_launcher_companion)" -Purpose "Replay-side preflight helper prints the launcher companion path beside the written replay notes."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_google_attached_preflight.ps1" -Snippet "Prefer launcher_companion first, then wrapper_google_sidecar_audit, then wrapper_google_asset_audit." -Purpose "Replay-side preflight helper documents the intended audit order so export-side failures are checked before browser-side failures.")
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
        profile = "google-issue3-windows-replay-google-attached-preflight"
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

Write-Host "Google issue #3 Windows replay Google attached preflight surface check"
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
    Write-Host "Google issue #3 Windows replay Google attached preflight surface is intact."
    exit 0
}

Write-Host (("Missing {0} replay-side Google attached preflight path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the missing helper, wrapper-backed launcher lane, Google attached follow-up, or replay note path before trusting this replay-side preflight helper."
exit 1
