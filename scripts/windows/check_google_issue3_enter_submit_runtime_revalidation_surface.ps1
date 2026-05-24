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
    (New-ValidationReference -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Kind "file" -Purpose "Branch-local gate note for deciding whether the direct issue #3 runtime patch can be reopened honestly."),
    (New-ValidationReference -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Kind "file" -Purpose "Branch-local runtime-first note for the issue #3 Enter-submit revalidation slice."),
    (New-ValidationReference -Path "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md" -Kind "file" -Purpose "Saved-browser-snapshot route note that should stay visible when no reusable checkout exists yet."),
    (New-ValidationReference -Path "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md" -Kind "file" -Purpose "Restored-checkout route note that should stay visible before saved-memory or runtime helpers trust a restored follow-up root."),
    (New-ValidationReference -Path "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md" -Kind "file" -Purpose "Saved-archive-integrity route note that should stay nearby when the runtime route still depends on proving the exact Memory snapshot and dependency bundles."),
    (New-ValidationReference -Path "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md" -Kind "file" -Purpose "Linux or WSL build-readiness companion that should stay nearby when the runtime route is still gated on environment recovery."),
    (New-ValidationReference -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Kind "file" -Purpose "Top-level execution guide that should stay aligned with the runtime revalidation route."),
    (New-ValidationReference -Path "docs/HEADED_MODE_ROADMAP.md" -Kind "file" -Purpose "Top-level roadmap that should keep the direct runtime re-entry helper visible from the validation quick routes."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows runbook that should stay nearby when replay widens back out from the runtime-only route."),
    (New-ValidationReference -Path "src/browser/Page.zig" -Kind "file" -Purpose "Browser-side target for deferred native Enter submit handling."),
    (New-ValidationReference -Path "src/display/win32_backend.zig" -Kind "file" -Purpose "Win32 backend target for queued text-input suppression matching and deferred Enter ordering."),
    (New-ValidationReference -Path "scripts/check_issue3_saved_memory_inputs.py" -Kind "file" -Purpose "Saved-memory preflight helper used before the runtime route trusts restored repo and dependency inputs."),
    (New-ValidationReference -Path "scripts/check_issue3_saved_archive_integrity.py" -Kind "file" -Purpose "Saved-archive verifier used after the saved-memory preflight when the route still depends on the exact Memory repo and dependency archives."),
    (New-ValidationReference -Path "scripts/check_issue3_restored_checkout.py" -Kind "file" -Purpose "Restored-checkout readiness helper used before the saved-memory preflight or runtime route trusts a restored checkout."),
    (New-ValidationReference -Path "scripts/check_linux_build_readiness.py" -Kind "file" -Purpose "Branch-compatible build-readiness helper referenced by the runtime re-entry gates note."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware commands."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Kind "file" -Purpose "Helper that prints the gated Windows-first Enter-submit runtime route."),
    (New-ValidationReference -Path "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh" -Kind "file" -Purpose "Fail-fast surface checker for the saved-browser-snapshot restore route used before helper replay moves into a restored checkout."),
    (New-ValidationReference -Path "scripts/linux/show_issue3_saved_browser_snapshot_route.sh" -Kind "file" -Purpose "Compact saved-browser-snapshot route printer used when no reusable checkout exists yet."),
    (New-ValidationReference -Path "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh" -Kind "file" -Purpose "Fail-fast surface checker for the saved-archive-integrity route used before restored-checkout validation trusts the exact saved bundles."),
    (New-ValidationReference -Path "scripts/linux/show_issue3_saved_archive_integrity_route.sh" -Kind "file" -Purpose "Compact saved-archive-integrity route printer used when the restored checkout still needs exact bundle verification."),
    (New-ValidationReference -Path "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh" -Kind "file" -Purpose "Fail-fast Linux or WSL surface checker for the direct issue #3 runtime route."),
    (New-ValidationReference -Path "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh" -Kind "file" -Purpose "Compact Linux or WSL route printer for the direct issue #3 runtime lane."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "Shared Enter-submit probe ladder used before the reduced Google fixture."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py" -Kind "file" -Purpose "Source-based checker for the direct Page.zig and win32_backend.zig runtime bridge markers."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1" -Kind "file" -Purpose "Reduced Google title probe used before reopening live Google."),
    (New-ValidationReference -Path "src/browser/tests/page/google_home_title_probe.html" -Kind "file" -Purpose "Reduced Google fixture referenced by the runtime revalidation route.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Purpose "The gate note keeps the runtime revalidation note in the required re-entry order."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "check_issue3_enter_submit_runtime_contract.py" -Purpose "The gate note keeps the source-based runtime contract checker visible before replay widens."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md" -Purpose "The gate note keeps the saved-browser-snapshot route note in the read-first companion set."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md" -Purpose "The gate note keeps the restored-checkout route note in the read-first companion set before helper replay trusts a restored follow-up root."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md" -Purpose "The gate note keeps the saved-archive-integrity route note in the read-first companion set."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "show_issue3_saved_browser_snapshot_route.sh" -Purpose "The gate note keeps the saved-browser-snapshot route printer visible before helper replay moves into a restored checkout."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "check_issue3_restored_checkout.py" -Purpose "The gate note keeps the restored-checkout readiness helper visible before the saved-memory preflight or runtime route trusts a restored follow-up root."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "check_issue3_saved_archive_integrity.py" -Purpose "The gate note keeps the saved-archive verification helper visible before deeper Linux or WSL staging is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh" -Purpose "The gate note keeps the saved-archive-integrity surface checker visible before restored-checkout verification is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/linux/show_issue3_saved_archive_integrity_route.sh" -Purpose "The gate note keeps the compact saved-archive-integrity route helper visible before restored-checkout verification is trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/check_issue3_saved_memory_inputs.py" -Purpose "The gate note keeps the saved-memory preflight visible before Linux or WSL build-readiness commands are trusted."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh" -Purpose "The gate note keeps the Linux or WSL runtime surface checker visible before the direct runtime patch is reopened."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_RUNTIME_REENTRY_GATES.md" -Snippet "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh" -Purpose "The gate note keeps the compact Linux or WSL runtime helper visible before the direct runtime patch is reopened."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md" -Snippet "docs/ISSUE3_RESTORED_CHECKOUT_REENTRY_ROUTE.md" -Purpose "The saved-browser-snapshot route keeps the restored-checkout route note visible before follow-up helpers trust the restored checkout."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md" -Snippet "scripts/check_issue3_restored_checkout.py" -Purpose "The saved-browser-snapshot route keeps the restored-checkout readiness helper visible before saved-memory or runtime follow-up begins."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1" -Purpose "The production guide keeps the fail-fast runtime surface checker visible from the direct issue #3 re-entry route."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1" -Purpose "The production guide keeps the compact runtime revalidation helper visible from the direct issue #3 re-entry route."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_ROADMAP.md" -Snippet "check_google_issue3_enter_submit_runtime_revalidation_surface.ps1" -Purpose "The roadmap quick routes keep the fail-fast runtime surface checker visible before the direct issue #3 route widens."),
    (New-ValidationContentExpectation -Path "docs/HEADED_MODE_ROADMAP.md" -Snippet "show_google_issue3_enter_submit_runtime_revalidation.ps1" -Purpose "The roadmap quick routes keep the compact runtime revalidation helper visible before the direct issue #3 route widens."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "src/browser/Page.zig" -Purpose "The runtime revalidation note keeps Page.zig named as a direct target."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "src/display/win32_backend.zig" -Purpose "The runtime revalidation note keeps win32_backend.zig named as a direct target."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "chrome-google-home-title-probe.ps1" -Purpose "The runtime revalidation note keeps the focused Google title probe visible."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "google_home_title_probe.html?google-home-probe=1" -Purpose "The runtime revalidation note keeps the reduced Google fixture replay command visible."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "Target `Page.zig` slice" -Purpose "The runtime revalidation note keeps the Page.zig work boundary explicit."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "Target `win32_backend.zig` slice" -Purpose "The runtime revalidation note keeps the Win32 backend work boundary explicit."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "Focused regression coverage" -Purpose "The runtime revalidation note keeps the narrow regression expectations visible."),
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet "google-form-controls-enter-order" -Purpose "Windows guide still surfaces the Google-shaped Enter-order route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet '"docs/ISSUE3_RUNTIME_REENTRY_GATES.md"' -Purpose "The helper points directly at the runtime re-entry gates note."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet '"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"' -Purpose "The helper keeps the runtime revalidation note on the same read-first surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet '"docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md"' -Purpose "The helper keeps the saved-browser-snapshot route note on the same read-first surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet '"docs/ISSUE3_SAVED_ARCHIVE_INTEGRITY_ROUTE.md"' -Purpose "The helper keeps the saved-archive-integrity route note on the same read-first surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet '"docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"' -Purpose "The helper keeps the Linux or WSL build-readiness note visible on the same read-first surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'saved_browser_snapshot_surface = $savedBrowserSnapshotSurfaceCommand' -Purpose "The helper prints the saved-browser-snapshot surface checker before replay depends on a restored checkout."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'saved_browser_snapshot_route = $savedBrowserSnapshotRouteCommand' -Purpose "The helper prints the saved-browser-snapshot route before Linux or WSL follow-up helpers are trusted."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'saved_archive_integrity_surface = $savedArchiveIntegritySurfaceCommand' -Purpose "The helper prints the saved-archive-integrity surface checker before restored-checkout verification is trusted."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'saved_archive_integrity_route = $savedArchiveIntegrityRouteCommand' -Purpose "The helper prints the saved-archive-integrity route before restored-checkout verification is trusted."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'saved_archive_integrity = $savedArchiveIntegrityCommand' -Purpose "The helper prints the exact saved-archive verification command before broader staging is trusted."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'saved_memory_preflight = $savedMemoryPreflightCommand' -Purpose "The helper prints the saved-memory preflight before broader Linux or WSL build-readiness commands."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'linux_runtime_surface = $linuxRuntimeSurfaceCommand' -Purpose "The helper prints the Linux or WSL runtime surface checker before the blocked runtime lane is reopened."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'linux_runtime_route = $linuxRuntimeRouteCommand' -Purpose "The helper prints the compact Linux or WSL runtime route before focused Zig output is trusted."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand' -Purpose "The helper prints the light preflight build-readiness command before focused Zig output is trusted."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'linux_build_readiness = $linuxBuildReadinessFullCommand' -Purpose "The helper prints the full build-readiness command for the re-entry gate."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'surface_check = Format-RepoRootCommand -ScriptPath "scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"' -Purpose "The helper exposes the fail-fast surface checker before the runtime replay commands."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1"' -Purpose "The helper keeps the shared click-first Enter-order route visible."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet 'reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1"' -Purpose "The helper prints the focused Google title probe command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "google_home_title_probe.html?google-home-probe=1" -Purpose "The helper prints the reduced Google fixture replay command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Stale queued suppression entries do not drop real later text_input bytes." -Purpose "The helper keeps the stale-suppression success signal visible."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Saved snapshot route:" -Purpose "The helper output prints the saved-browser-snapshot route before Linux or WSL follow-up helpers."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Saved archive route:" -Purpose "The helper output prints the saved-archive-integrity route before broader staging is trusted."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Saved archive verification:" -Purpose "The helper output prints the exact saved-archive verification command before broader staging is trusted."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Shared click-first route:" -Purpose "The helper output prints the click-first Google ordering route.")
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
        profile = "google-issue3-enter-submit-runtime-revalidation"
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

Write-Host "Google issue #3 Enter-submit runtime revalidation surface check"
Write-Host ""
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
Write-Host ""

foreach ($result in $referenceResults) {
    $status = if ($result.Exists) { "PASS" } else { "FAIL" }
    Write-Host ("[{0}] {1}" -f $status, $result.Path)
    Write-Host ("  {0}" -f $result.Purpose)
}

if ($contentResults.Count -gt 0) {
    Write-Host ""
    Write-Host "Helper source expectations:"
    foreach ($result in $contentResults) {
        $status = if ($result.Exists) { "PASS" } else { "FAIL" }
        Write-Host ("[{0}] {1}" -f $status, $result.Path)
        Write-Host ("  {0}" -f $result.Purpose)
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host ("Missing checks: {0}" -f $missing.Count)
    exit 1
}

Write-Host ""
Write-Host "All runtime revalidation surfaces are present."