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
    (New-ValidationReference -Path "docs/HEADED_MODE_ROADMAP.md" -Kind "file" -Purpose "Roadmap note aligned to the live validation-router surface on this branch."),
    (New-ValidationReference -Path "docs/WINDOWS_FULL_USE.md" -Kind "file" -Purpose "Windows runbook that should stay aligned with the live validation-router surface."),
    (New-ValidationReference -Path "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Top-level attached-html quickstart note surfaced from the validation router for issue #3 follow-up."),
    (New-ValidationReference -Path "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_SUITE_SURFACE.md" -Kind "file" -Purpose "Bundle-specific attached-html surface note kept available when the router stays pinned to the three-page compatibility set."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used by the issue #3 validation-router companions."),
    (New-ValidationReference -Path "scripts/windows/show_headed_validation_suites.ps1" -Kind "file" -Purpose "Top-level validation router whose issue #3 follow-up surface this checker validates."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1" -Kind "file" -Purpose "Top-level issue #3 attached-html quickstart that the validation router now surfaces directly."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Kind "file" -Purpose "Bundle-first issue #3 helper that the validation router keeps visible for pinned compatibility-bundle follow-up."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Kind "file" -Purpose "Bounded input probe that remains the first Google-recommended validation step."),
    (New-ValidationReference -Path "tmp-browser-smoke/form-controls/label-click-probe.ps1" -Kind "file" -Purpose "Bounded input probe that remains part of the shared input route before manual Google follow-up."),
    (New-ValidationReference -Path "tmp-browser-smoke/wrapped-link/chrome-history-probe.ps1" -Kind "file" -Purpose "Bounded localhost navigation probe still surfaced by the validation router."),
    (New-ValidationReference -Path "tmp-browser-smoke/wrapped-link/chrome-reload-probe.ps1" -Kind "file" -Purpose "Bounded localhost reload probe still surfaced by the validation router.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet '[ValidateSet("", "attached-html", "attached-html-target-bundle", "google-attached-html", "google-input", "input", "navigation")]' -Purpose "Validation router still exposes the attached-html and Google input change-area entrypoints needed for issue #3 follow-up."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet '$issue3AttachedHtmlArguments = [System.Collections.Generic.List[string]]::new()' -Purpose "Validation router still builds a shared argument list for issue #3 attached-html follow-up helpers."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet "Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments `\$issue3AttachedHtmlArguments" -Purpose "Validation router still surfaces the top-level issue #3 attached-html quickstart helper."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet "Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments `\$issue3AttachedHtmlArguments" -Purpose "Validation router still surfaces the bundle-first issue #3 helper for pinned compatibility-bundle follow-up."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Write-Route -Name "issue3-attached-html-follow-up" -Commands @(' -Purpose "Validation router still prints a dedicated issue #3 attached-html follow-up block for Google-recommended and Google-input paths."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Write-Route -Name "manual-localhost-follow-up" -Commands $commands -Notes (Get-AttachedHtmlNotes)' -Purpose "Validation router still preserves the honest manual localhost attached-html route beside the narrower issue #3 helper surface."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Use the top-level attached-page quickstart when the next step is saved-page follow-up on the shorter issue #3 helper ladder.' -Purpose "Google-input notes still describe when to use the top-level attached-html quickstart follow-up."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Use the bundle-first helper when the replay should stay pinned to the known three-page compatibility set or when -InputPath already fixes the bundle inputs.' -Purpose "Router notes still describe when to use the bundle-first follow-up path."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet 'Use the bounded input probe first, then live Google, then the shorter issue #3 attached-page helper surface before falling back to the broader manual localhost replay.' -Purpose "Google-recommended route still documents the intended bounded-input to Google to issue #3 follow-up order.")
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
        profile = "google-issue3-validation-router-surface"
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

Write-Host "Google issue #3 validation-router surface check"
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
    Write-Host "Google issue #3 validation-router surface is intact."
    exit 0
}

Write-Host (("Missing {0} validation-router path or source contract check(s).") -f $missing.Count)
Write-Host "Repair the top-level router, its issue #3 attached-html follow-up surface, or the bounded probe references before trusting this Google follow-up route."
exit 1
