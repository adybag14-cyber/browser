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
    (New-ValidationReference -Path "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md" -Kind "file" -Purpose "Windows replay quickstart note whose helper contract should keep the validation-router bridge visible."),
    (New-ValidationReference -Path "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md" -Kind "file" -Purpose "Validation-router attached HTML quickstart note kept nearby when the replay quickstart narrows into the attached-page ladder."),
    (New-ValidationReference -Path "scripts/windows/HeadedValidationHelpers.ps1" -Kind "file" -Purpose "Shared helper surface used by the replay quickstart helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1" -Kind "file" -Purpose "Replay quickstart helper whose validation-router bridge surfacing this checker guards."),
    (New-ValidationReference -Path "scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1" -Kind "file" -Purpose "Validation-router attached HTML fail-fast checker that should stay visible from the replay quickstart helper."),
    (New-ValidationReference -Path "scripts/windows/show_google_issue3_validation_router_attached_html_quickstart.ps1" -Kind "file" -Purpose "Validation-router attached HTML quickstart helper that should stay visible from the replay quickstart helper.")
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1" -Snippet "validation_router_attached_html_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_validation_router_attached_html_quickstart_surface.ps1' -Arguments `$routeSurfaceArguments" -Purpose "Replay quickstart helper keeps the validation-router fail-fast checker wired into its command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1" -Snippet "validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments `$sharedArguments" -Purpose "Replay quickstart helper keeps the validation-router attached HTML quickstart wired into its command map."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1" -Snippet 'Write-Host ((\"  Validation-router check:   {0}\") -f $helper.commands.validation_router_attached_html_surface_check)' -Purpose "Replay quickstart helper output prints the validation-router fail-fast checker before the attached-page ladder narrows further."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1" -Snippet 'Write-Host ((\"  Validation-router quick:   {0}\") -f $helper.commands.validation_router_attached_html_quickstart)' -Purpose "Replay quickstart helper output prints the validation-router attached HTML quickstart before the narrower replay attached-page ladder takes over."),
    (New-ValidationContentExpectation -Path "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1" -Snippet 'Use validation_router_attached_html_surface_check immediately before validation_router_attached_html_quickstart when attached localhost replay is already the next obvious branch and you want that narrower bridge to fail fast on drifted quickstart notes, missing helper scripts, or renamed attached-page follow-up before the replay narrows further.' -Purpose "Replay quickstart helper notes explain when to reopen the validation-router checker before the narrower attached-page ladder.")
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
        profile = "google-issue3-windows-replay-validation-router-surface"
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

Write-Host "Google issue #3 Windows replay validation-router surface check"
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
    Write-Host "Google issue #3 Windows replay quickstart still keeps the validation-router fail-fast checker and attached HTML quickstart visible before the narrower replay attached-page ladder takes over."
    exit 0
}

Write-Host (("Missing {0} Windows replay validation-router path or helper-contract check(s).") -f $missing.Count)
Write-Host "Repair the replay quickstart helper's validation-router command map, printed output, or guidance notes before trusting the narrower attached-page ladder."
exit 1
