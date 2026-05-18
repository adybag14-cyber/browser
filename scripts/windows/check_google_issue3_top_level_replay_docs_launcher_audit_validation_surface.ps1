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
    (New-ValidationReference -Path 'docs/ISSUE3_TOP_LEVEL_REPLAY_DOCS_LAUNCHER_AUDIT.md' -Kind 'file' -Purpose 'Written checker-first note for replay-doc launcher drift on the top-level attached-page route.'),
    (New-ValidationReference -Path 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md' -Kind 'file' -Purpose 'Top-level attached HTML quickstart note that the replay-doc launcher audit helps guard.'),
    (New-ValidationReference -Path 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md' -Kind 'file' -Purpose 'Replay quickstart note that still participates in the replay-doc launcher audit coverage.'),
    (New-ValidationReference -Path 'scripts/windows/check_google_issue3_replay_docs_launcher_validation_surface.ps1' -Kind 'file' -Purpose 'Existing replay-doc launcher surface check surfaced by the new top-level audit helper.'),
    (New-ValidationReference -Path 'scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Kind 'file' -Purpose 'Existing launcher companion surface check surfaced by the new top-level audit helper.'),
    (New-ValidationReference -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Kind 'file' -Purpose 'Existing launcher companion helper surfaced by the new top-level audit helper.'),
    (New-ValidationReference -Path 'scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1' -Kind 'file' -Purpose 'Existing top-level attached HTML helper reopened after the checker-first launcher audit passes.'),
    (New-ValidationReference -Path 'scripts/windows/show_google_issue3_top_level_replay_docs_launcher_audit.ps1' -Kind 'file' -Purpose 'Top-level replay-doc launcher audit helper that this checker validates.')
)

$contentExpectations = @(
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_top_level_replay_docs_launcher_audit.ps1' -Snippet "check_google_issue3_replay_docs_launcher_validation_surface.ps1" -Purpose 'Top-level audit helper surfaces the replay-doc launcher checker first.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_top_level_replay_docs_launcher_audit.ps1' -Snippet "check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1" -Purpose 'Top-level audit helper surfaces the launcher companion checker as the second guard.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_top_level_replay_docs_launcher_audit.ps1' -Snippet "show_google_issue3_attached_pages_launcher_companion.ps1" -Purpose 'Top-level audit helper keeps the compact launcher companion visible after the two guard rails.'),
    (New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_top_level_replay_docs_launcher_audit.ps1' -Snippet "show_google_issue3_top_level_attached_html_quickstart.ps1" -Purpose 'Top-level audit helper returns to the broader top-level attached HTML quickstart only after the launcher guards pass.'),
    (New-ValidationContentExpectation -Path 'docs/ISSUE3_TOP_LEVEL_REPLAY_DOCS_LAUNCHER_AUDIT.md' -Snippet 'check_google_issue3_replay_docs_launcher_validation_surface.ps1' -Purpose 'Written note points at the replay-doc launcher checker first.'),
    (New-ValidationContentExpectation -Path 'docs/ISSUE3_TOP_LEVEL_REPLAY_DOCS_LAUNCHER_AUDIT.md' -Snippet 'show_google_issue3_attached_pages_launcher_companion.ps1' -Purpose 'Written note points at the compact launcher companion helper second.'),
    (New-ValidationContentExpectation -Path 'docs/ISSUE3_TOP_LEVEL_REPLAY_DOCS_LAUNCHER_AUDIT.md' -Snippet 'show_google_issue3_top_level_attached_html_quickstart.ps1' -Purpose 'Written note returns to the top-level attached HTML helper after the checker-first launcher audit route.' )
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

$missingReferences = @($referenceResults | Where-Object { -not $_.Exists })
$missingContent = @($contentResults | Where-Object { -not $_.Exists })
$missing = @($missingReferences + $missingContent)

if ($Json) {
    [ordered]@{
        profile = 'google-issue3-top-level-replay-docs-launcher-audit'
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

Write-Host 'Google issue #3 top-level replay-doc launcher audit surface check'
Write-Host ''
Write-Host (("Repo root: {0}") -f $resolvedRepoRoot)
Write-Host ''

foreach ($result in $referenceResults) {
    $status = if ($result.Exists) { 'PASS' } else { 'FAIL' }
    Write-Host (("[{0}] {1}") -f $status, $result.Path)
    Write-Host (("  {0}") -f $result.Purpose)
}

if ($contentResults.Count -gt 0) {
    Write-Host ''
    Write-Host 'Helper source expectations:'
    foreach ($result in $contentResults) {
        $status = if ($result.Exists) { 'PASS' } else { 'FAIL' }
        Write-Host (("[{0}] {1}") -f $status, $result.Path)
        Write-Host (("  {0}") -f $result.Purpose)
    }
}

Write-Host ''
if ($missing.Count -eq 0) {
    Write-Host 'Google issue #3 top-level replay-doc launcher audit surface is intact.'
    exit 0
}

Write-Host (("Missing {0} top-level replay-doc launcher audit path or source contract check(s).") -f $missing.Count)
Write-Host 'Repair the missing checker-first note, helper surface, or launcher-companion bridge before trusting the top-level replay-doc launcher audit route.'
exit 1
