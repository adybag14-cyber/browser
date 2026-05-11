[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string[]]$InputPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Get-AttachedBundleTargetSpec {
    return @(
        [pscustomobject]@{
            Name = "google-safety-centre"
            DisplayName = "Control your online safety and privacy – Google Safety Centre"
            MatchPattern = "control your online safety and privacy.+google safety centre"
            Purpose = "Google-branded policy and content-heavy compatibility target."
        }
        [pscustomobject]@{
            Name = "anthropic-job-application"
            DisplayName = "Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic"
            MatchPattern = "job application.+interpretability at anthropic"
            Purpose = "Form-heavy application page compatibility target."
        }
        [pscustomobject]@{
            Name = "uap-encounters"
            DisplayName = "Presidential Unsealing and Reporting System for UAP Encounters"
            MatchPattern = "presidential unsealing and reporting system for uap encounters"
            Purpose = "Dense document and script-heavy compatibility target."
        }
    )
}

function Get-FixtureTitle {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        $match = [regex]::Match($raw, "<title[^>]*>(.*?)</title>", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($match.Success) {
            return [System.Net.WebUtility]::HtmlDecode($match.Groups[1].Value).Trim()
        }
    } catch {
        return ""
    }

    return ""
}

function Get-ResolvedBundleCandidates {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [string[]]$InputPath
    )

    $paths = if ($InputPath -and $InputPath.Count -gt 0) {
        @($InputPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path })
    } else {
        @(Get-AttachedHtmlCandidates -RepoRoot $RepoRoot | ForEach-Object { $_.FullName })
    }

    return @(
        $paths | ForEach-Object {
            [pscustomobject]@{
                Path = $_
                Title = Get-FixtureTitle -Path $_
                SearchText = (("{0}`n{1}" -f $_, (Get-FixtureTitle -Path $_))).ToLowerInvariant()
            }
        }
    )
}

if (-not $RepoRoot) {
    $RepoRoot = Resolve-LightpandaRepoRoot $PSScriptRoot
}

$searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot)
$targets = @(Get-AttachedBundleTargetSpec)
$candidates = @(Get-ResolvedBundleCandidates -RepoRoot $RepoRoot -InputPath $InputPath)

$matchedPaths = @()
$targetResults = foreach ($target in $targets) {
    $matches = @(
        $candidates | Where-Object {
            $_.SearchText -match $target.MatchPattern
        }
    )

    $selectedPath = $null
    $selectedTitle = ""
    $status = "missing"
    if ($matches.Count -eq 1) {
        $selectedPath = $matches[0].Path
        $selectedTitle = $matches[0].Title
        $matchedPaths += $selectedPath
        $status = "found"
    } elseif ($matches.Count -gt 1) {
        $status = "ambiguous"
    }

    [pscustomobject]@{
        name = $target.Name
        display_name = $target.DisplayName
        purpose = $target.Purpose
        status = $status
        match_count = $matches.Count
        path = $selectedPath
        title = $selectedTitle
        candidate_paths = @($matches | ForEach-Object { $_.Path })
    }
}

$assetAudit = @()
if ($matchedPaths.Count -gt 0) {
    $assetAudit = @(Get-MissingLocalFixtureAssetAudit -FixturePaths $matchedPaths)
}

$assetAuditByPath = @{}
foreach ($fixture in $assetAudit) {
    $assetAuditByPath[$fixture.path] = $fixture
}

$resultRows = @(
    $targetResults | ForEach-Object {
        $audit = if ($_.path -and $assetAuditByPath.ContainsKey($_.path)) { $assetAuditByPath[$_.path] } else { $null }
        [ordered]@{
            name = $_.name
            display_name = $_.display_name
            purpose = $_.purpose
            status = $_.status
            match_count = $_.match_count
            path = $_.path
            display_path = if ($_.path) { Convert-ToDisplayPath -Path $_.path -RepoRoot $RepoRoot } else { $null }
            title = $_.title
            missing_asset_count = if ($audit) { $audit.missing_asset_count } else { $null }
            candidate_paths = @($_.candidate_paths | ForEach-Object { Convert-ToDisplayPath -Path $_ -RepoRoot $RepoRoot })
        }
    }
)

$missingTargets = @($resultRows | Where-Object { $_.status -eq "missing" })
$ambiguousTargets = @($resultRows | Where-Object { $_.status -eq "ambiguous" })
$bundlePassed = $missingTargets.Count -eq 0 -and $ambiguousTargets.Count -eq 0

if ($Json) {
    [ordered]@{
        repo_root = $RepoRoot
        search_roots = $searchRoots
        input_mode = if ($InputPath -and $InputPath.Count -gt 0) { "explicit" } else { "auto-discovered" }
        discovered_candidate_count = $candidates.Count
        expected_target_count = $targets.Count
        matched_target_count = @($resultRows | Where-Object { $_.status -eq "found" }).Count
        passed = $bundlePassed
        targets = $resultRows
    } | ConvertTo-Json -Depth 8

    if (-not $bundlePassed) {
        exit 1
    }

    exit 0
}

Write-Host "Attached HTML target bundle check"
Write-Host ""
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Input mode: {0}" -f $(if ($InputPath -and $InputPath.Count -gt 0) { "explicit" } else { "auto-discovered" }))
if ($searchRoots.Count -gt 0) {
    Write-Host ("Search roots: {0}" -f ($searchRoots -join "; "))
}
Write-Host ("Discovered candidates: {0}" -f $candidates.Count)
Write-Host ""

foreach ($row in $resultRows) {
    $statusText = $row.status.ToUpperInvariant()
    Write-Host ("[{0}] {1}" -f $statusText, $row.display_name)
    Write-Host ("  Purpose: {0}" -f $row.purpose)
    if ($row.display_path) {
        Write-Host ("  Path: {0}" -f $row.display_path)
    }
    if ($row.title) {
        Write-Host ("  Title: {0}" -f $row.title)
    }
    if ($null -ne $row.missing_asset_count) {
        Write-Host ("  Shallow missing-asset count: {0}" -f $row.missing_asset_count)
    }
    if ($row.status -eq "ambiguous") {
        foreach ($candidatePath in $row.candidate_paths) {
            Write-Host ("  Candidate: {0}" -f $candidatePath)
        }
    }
}

Write-Host ""
if ($bundlePassed) {
    Write-Host "Known attached HTML compatibility bundle is present."
    Write-Host "Run check_attached_html_local_asset_closure.ps1 next if you also need deep sibling-asset proof before localhost replay."
    exit 0
}

Write-Host ("Known attached HTML compatibility bundle check failed: {0} missing, {1} ambiguous." -f $missingTargets.Count, $ambiguousTargets.Count)
Write-Host "Restore the expected saved pages or pass explicit InputPath values before relying on attached-page localhost compatibility coverage."
exit 1