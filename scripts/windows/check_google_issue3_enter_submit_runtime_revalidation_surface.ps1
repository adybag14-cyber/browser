[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'HeadedValidationHelpers.ps1')

function New-ValidationReference {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [ValidateSet('file', 'directory')]
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
    (New-ValidationReference -Path 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md' -Kind 'file' -Purpose 'Branch-local re-entry note for the remaining Google headed Enter-submit runtime slice.'),
    (New-ValidationReference -Path 'docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md' -Kind 'file' -Purpose 'Broader execution guide that keeps the runtime-first note in the headed workflow context.'),
    (New-ValidationReference -Path 'docs/WINDOWS_FULL_USE.md' -Kind 'file' -Purpose 'Windows-first runbook kept nearby when replay widens beyond the reduced fixture.'),
    (New-ValidationReference -Path 'src/browser/Page.zig' -Kind 'file' -Purpose 'Browser-side target for deferred native Enter submit handling.'),
    (New-ValidationReference -Path 'src/display/win32_backend.zig' -Kind 'file' -Purpose 'Win32 backend target for queued text-input suppression matching and deferred Enter ordering.'),
    (New-ValidationReference -Path 'src/browser/tests/page/google_home_title_probe.html' -Kind 'file' -Purpose 'Reduced Google-shaped replay fixture used before widening back to live Google.'),
    (New-ValidationReference -Path 'tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1' -Kind 'file' -Purpose 'Focused Windows headed title probe used to confirm the Google event-order boundary before wider replay.'),
    (New-ValidationReference -Path 'scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1' -Kind 'file' -Purpose 'Runtime revalidation helper that prints the reduced replay route and expected signals.'),
    (New-ValidationReference -Path 'scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1' -Kind 'file' -Purpose 'Runtime revalidation surface checker that validates the branch-local files and note surface.'),
    (New-ValidationReference -Path 'scripts/windows/HeadedValidationHelpers.ps1' -Kind 'file' -Purpose 'Shared helper surface used to resolve LIGHTPANDA_REPO_ROOT-aware helper commands.')
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md' -Snippet 'src/browser/Page.zig' -Purpose 'The runtime revalidation note keeps Page.zig named as a direct target.'),
    (New-ValidationContentExpectation -Path 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md' -Snippet 'src/display/win32_backend.zig' -Purpose 'The runtime revalidation note keeps win32_backend.zig named as a direct target.'),
    (New-ValidationContentExpectation -Path 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md' -Snippet 'chrome-google-home-title-probe.ps1' -Purpose 'The runtime revalidation note keeps the focused Google title probe visible.'),
    (New-ValidationContentExpectation -Path 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md' -Snippet 'google_home_title_probe.html?google-home-probe=1' -Purpose 'The runtime revalidation note keeps the reduced Google fixture replay command visible.'),
    (New-ValidationContentExpectation -Path 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md' -Snippet 'Target `Page.zig` slice' -Purpose 'The runtime revalidation note keeps the Page.zig work boundary explicit.'),
    (New-ValidationContentExpectation -Path 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md' -Snippet 'Target `win32_backend.zig` slice' -Purpose 'The runtime revalidation note keeps the Win32 backend work boundary explicit.'),
    (New-ValidationContentExpectation -Path 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md' -Snippet 'Focused regression coverage' -Purpose 'The runtime revalidation note keeps the narrow regression expectations visible.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1' -Snippet "note_path = 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md'" -Purpose 'The helper points directly at the branch-local runtime revalidation note.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1' -Snippet "surface_check = \$surfaceCheckCommand" -Purpose 'The helper exposes the fail-fast surface checker before the runtime replay commands.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1' -Snippet "title_probe = \$titleProbeCommand" -Purpose 'The helper prints the focused Google title probe command.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1' -Snippet "reduced_fixture_replay = \$fixtureReplayCommand" -Purpose 'The helper prints the reduced Google fixture replay command.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1' -Snippet 'Stale queued suppression entries do not drop real later text_input bytes.' -Purpose 'The helper keeps the stale-suppression success signal visible.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1' -Snippet 'Read first: {0}' -Purpose 'The helper output keeps the read-first runtime note visible.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1' -Snippet 'Google title probe:' -Purpose 'The helper output prints the focused title probe section.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1' -Snippet 'Reduced fixture run:' -Purpose 'The helper output prints the reduced fixture replay section.')
)

$referenceResults = foreach ($reference in $references) {
    $fullPath = Join-Path $resolvedRepoRoot $reference.Path
    $exists = if ($reference.Kind -eq 'directory') {
        Test-Path -LiteralPath $fullPath -PathType Container
    } else {
        Test-Path -LiteralPath $fullPath -PathType Leaf
    }

    [pscustomobject]@{
        CheckType = 'reference'
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
            CheckType = 'content'
            Path = $expectation.Path
            Kind = 'content-snippet'
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
        CheckType = 'content'
        Path = $expectation.Path
        Kind = 'content-snippet'
        Purpose = $expectation.Purpose
        Exists = [bool]$contentCache[$fullPath].Contains($expectation.Snippet)
        Snippet = $expectation.Snippet
    }
}

$missing = @(
    @($referenceResults | Where-Object { -not $_.Exists }) +
    @($contentResults | Where-Object { -not $_.Exists })
)

if ($Json) {
    [ordered]@{
        profile = 'google-issue3-enter-submit-runtime-revalidation'
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

Write-Host 'Google issue #3 Enter-submit runtime revalidation surface check'
Write-Host ''
Write-Host ('Repo root: {0}' -f $resolvedRepoRoot)
Write-Host ''

foreach ($result in $referenceResults) {
    $status = if ($result.Exists) { 'PASS' } else { 'FAIL' }
    Write-Host ('[{0}] {1}' -f $status, $result.Path)
    Write-Host ('  {0}' -f $result.Purpose)
}

if ($contentResults.Count -gt 0) {
    Write-Host ''
    Write-Host 'Helper source expectations:'
    foreach ($result in $contentResults) {
        $status = if ($result.Exists) { 'PASS' } else { 'FAIL' }
        Write-Host ('[{0}] {1}' -f $status, $result.Path)
        Write-Host ('  {0}' -f $result.Purpose)
    }
}

if ($missing.Count -gt 0) {
    Write-Host ''
    Write-Host ('Missing checks: {0}' -f $missing.Count)
    exit 1
}

Write-Host ''
Write-Host 'All runtime revalidation surfaces are present.'
