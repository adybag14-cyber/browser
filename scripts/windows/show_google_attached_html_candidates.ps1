[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

if (-not $RepoRoot) {
    $RepoRoot = Resolve-LightpandaRepoRoot $PSScriptRoot
}

$searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot)
$candidates = @(
    Get-AttachedHtmlCandidates -RepoRoot $RepoRoot |
        Sort-Object @(
            @{ Expression = { Get-GoogleStyleFixtureScore $_ }; Descending = $true },
            @{ Expression = { $_.FullName } }
        )
)
$googleStyleCandidates = @($candidates | Where-Object { Test-GoogleStyleFixture $_ })
$preferredInitialPage = if ($googleStyleCandidates.Count -gt 0) {
    Select-GoogleStyleInitialPage -ResolvedInputPath @($googleStyleCandidates | ForEach-Object { $_.FullName })
} else {
    $null
}

$candidateRecords = foreach ($candidate in $candidates) {
    $score = Get-GoogleStyleFixtureScore $candidate
    [pscustomobject]@{
        display_path = Convert-ToDisplayPath -Path $candidate.FullName -RepoRoot $RepoRoot
        full_path = $candidate.FullName
        google_style = ($score -gt 4)
        google_style_score = $score
        preferred_initial_page = [string]::Equals($preferredInitialPage, $candidate.FullName, [System.StringComparison]::OrdinalIgnoreCase)
    }
}

if ($Json) {
    [pscustomobject]@{
        search_roots = $searchRoots
        candidate_count = $candidateRecords.Count
        google_style_candidate_count = @($candidateRecords | Where-Object { $_.google_style }).Count
        preferred_initial_page = $preferredInitialPage
        candidates = $candidateRecords
    } | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Google-style attached HTML candidates"
Write-Host ""
if ($searchRoots.Count -gt 0) {
    Write-Host "Search roots:"
    foreach ($root in $searchRoots) {
        Write-Host ("- {0}" -f (Convert-ToDisplayPath -Path $root -RepoRoot $RepoRoot))
    }
    Write-Host ""
}

if ($candidateRecords.Count -eq 0) {
    Write-Host "No attached HTML files were found under the current search roots."
    exit 0
}

Write-Host ("Attached HTML files found: {0}" -f $candidateRecords.Count)
Write-Host ("Google-style matches: {0}" -f @($candidateRecords | Where-Object { $_.google_style }).Count)
if ($preferredInitialPage) {
    Write-Host ("Preferred initial page: {0}" -f (Convert-ToDisplayPath -Path $preferredInitialPage -RepoRoot $RepoRoot))
}
Write-Host ""
Write-Host "Candidates:"
foreach ($record in $candidateRecords) {
    $status = if ($record.google_style) { "google-style" } else { "non-google-style" }
    $preferred = if ($record.preferred_initial_page) { " preferred-initial-page" } else { "" }
    Write-Host ("- [{0}] score={1}{2} {3}" -f $status, $record.google_style_score, $preferred, $record.display_path)
}
Write-Host ""
Write-Host "Next commands:"
Write-Host "- powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"
Write-Host "- powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -Wait"
