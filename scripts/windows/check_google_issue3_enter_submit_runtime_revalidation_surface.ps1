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
    (New-ValidationReference -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Kind "file" -Purpose "Branch-local runtime-first note for the issue #3 Enter-submit revalidation slice."),
    (New-ValidationReference -Path "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md" -Kind "file" -Purpose "Top-level execution guide that should stay aligned with the runtime revalidation route."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows runbook that should stay nearby when replay widens back out from the runtime-only route."),
    (New-ValidationReference -Path "src/browser/Page.zig" -Kind "file" -Purpose "Browser-side target for deferred native Enter submit handling."),
    (New-ValidationReference -Path "src/display/win32_backend.zig" -Kind "file" -Purpose "Win32 backend target for queued text-input suppression matching and deferred Enter ordering."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used to resolve repo-root-aware commands."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Kind "file" -Purpose "Helper that prints the Windows-first Enter-submit runtime route."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "Shared Enter-submit probe ladder used before the reduced Google fixture."),
    (New-ValidationReference -Path "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1" -Kind "file" -Purpose "Reduced Google title probe used before reopening live Google."),
    (New-ValidationReference -Path "src/browser/tests/page/google_home_title_probe.html" -Kind "file" -Purpose "Reduced Google fixture referenced by the runtime revalidation route.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "src/browser/Page.zig" -Purpose "The runtime revalidation note keeps Page.zig named as a direct target."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "src/display/win32_backend.zig" -Purpose "The runtime revalidation note keeps win32_backend.zig named as a direct target."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "chrome-google-home-title-probe.ps1" -Purpose "The runtime revalidation note keeps the focused Google title probe visible."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "google_home_title_probe.html?google-home-probe=1" -Purpose "The runtime revalidation note keeps the reduced Google fixture replay command visible."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "Target `Page.zig` slice" -Purpose "The runtime revalidation note keeps the Page.zig work boundary explicit."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "Target `win32_backend.zig` slice" -Purpose "The runtime revalidation note keeps the Win32 backend work boundary explicit."),
    (New-ValidationContentExpectation -Path "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md" -Snippet "Focused regression coverage" -Purpose "The runtime revalidation note keeps the narrow regression expectations visible."),
    (New-ValidationContentExpectation -Path "docs/WINDOWS_FULL_USE.md" -Snippet "google-form-controls-enter-order" -Purpose "Windows guide still surfaces the Google-shaped Enter-order route."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "note_path = \"docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md\"" -Purpose "The helper points directly at the branch-local runtime revalidation note."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "surface_check = Format-RepoRootCommand -ScriptPath \"scripts\\windows\\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1\"" -Purpose "The helper exposes the fail-fast surface checker before the runtime replay commands."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "shared_enter_google_click = Format-RepoRootCommand -ScriptPath \"tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1\"" -Purpose "The helper keeps the shared click-first Enter-order route visible."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "reduced_google_probe = Format-RepoRootCommand -ScriptPath \"tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1\"" -Purpose "The helper prints the focused Google title probe command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "google_home_title_probe.html?google-home-probe=1" -Purpose "The helper prints the reduced Google fixture replay command."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1" -Snippet "Stale queued suppression entries do not drop real later text_input bytes." -Purpose "The helper keeps the stale-suppression success signal visible."),
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
