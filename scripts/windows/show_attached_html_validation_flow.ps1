[CmdletBinding()]
param(
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
    [int]$Port = 8123,
    [switch]$GoogleStyle,
    [switch]$Json,
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-AttachedHtmlSearchRoots {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $candidateRoots = New-Object System.Collections.Generic.List[string]
    $candidateRoots.Add((Join-Path $RepoRoot "user_files"))
    $candidateRoots.Add((Join-Path $RepoRoot "agent_files"))

    $repoParent = Split-Path $RepoRoot -Parent
    if (-not [string]::IsNullOrWhiteSpace($repoParent) -and $repoParent -ne $RepoRoot) {
        $candidateRoots.Add((Join-Path $repoParent "user_files"))
        $candidateRoots.Add((Join-Path $repoParent "agent_files"))
    }

    $currentRoot = (Get-Location).Path
    if (-not [string]::IsNullOrWhiteSpace($currentRoot)) {
        $candidateRoots.Add((Join-Path $currentRoot "user_files"))
        $candidateRoots.Add((Join-Path $currentRoot "agent_files"))
    }

    return $candidateRoots |
        Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
        Select-Object -Unique
}

function Get-DefaultAttachedHtmlInputPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot)
    if ($searchRoots.Count -eq 0) {
        throw "attached HTML directories not found under the repo root, its parent workspace, or the current working directory"
    }

    $htmlFiles = @(
        foreach ($root in $searchRoots) {
            Get-ChildItem -LiteralPath $root -Recurse -File |
                Where-Object { $_.Extension -in @(".html", ".htm") } |
                Sort-Object FullName |
                ForEach-Object { $_.FullName }
        }
    ) | Select-Object -Unique

    if ($htmlFiles.Count -eq 0) {
        throw "no attached HTML files were found anywhere under $($searchRoots -join '; ')"
    }

    return @($htmlFiles)
}

function Normalize-AttachedHtmlSelector {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $normalized = ($Path -replace "\\", "/").Trim()
    while ($normalized.StartsWith("./")) {
        $normalized = $normalized.Substring(2)
    }
    return $normalized.TrimStart('/')
}

function Resolve-AttachedPreferredInitialPage {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ResolvedInputPath,
        [Parameter(Mandatory = $true)]
        [string]$PreferredInitialPage
    )

    if (Test-Path -LiteralPath $PreferredInitialPage -PathType Leaf) {
        return (Resolve-Path -LiteralPath $PreferredInitialPage).Path
    }

    $normalizedSelector = Normalize-AttachedHtmlSelector -Path $PreferredInitialPage
    $matches = @(
        $ResolvedInputPath | Where-Object {
            $resolvedPath = $_
            $normalizedResolvedPath = Normalize-AttachedHtmlSelector -Path $resolvedPath
            $leaf = [System.IO.Path]::GetFileName($resolvedPath)

            [string]::Equals($resolvedPath, $PreferredInitialPage, [System.StringComparison]::OrdinalIgnoreCase) -or
            [string]::Equals($leaf, $PreferredInitialPage, [System.StringComparison]::OrdinalIgnoreCase) -or
            [string]::Equals($normalizedResolvedPath, $normalizedSelector, [System.StringComparison]::OrdinalIgnoreCase) -or
            $normalizedResolvedPath.EndsWith("/" + $normalizedSelector, [System.StringComparison]::OrdinalIgnoreCase)
        } | Select-Object -Unique
    )

    if ($matches.Count -eq 1) {
        return $matches[0]
    }
    if ($matches.Count -gt 1) {
        throw "preferred initial page '$PreferredInitialPage' matched multiple attached HTML files. Pass a more specific path. Matches: $($matches -join '; ')"
    }

    throw "preferred initial page '$PreferredInitialPage' was not found in the attached HTML inputs. Pass a full path or a unique attached HTML file name."
}

function Select-GoogleStyleInitialPage {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ResolvedInputPath
    )

    return $ResolvedInputPath |
        Where-Object {
            $leaf = [System.IO.Path]::GetFileName($_)
            $leaf -match "Google|Safety|Search|Privacy"
        } |
        Select-Object -First 1
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\\..")).Path
$usingExplicitInputPath = $InputPath -and $InputPath.Count -gt 0
$resolvedInputPath = if ($usingExplicitInputPath) {
    @($InputPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path })
} else {
    Get-DefaultAttachedHtmlInputPath -RepoRoot $repoRoot
}

$resolvedPreferredInitialPage = if ($PreferredInitialPage) {
    Resolve-AttachedPreferredInitialPage -ResolvedInputPath $resolvedInputPath -PreferredInitialPage $PreferredInitialPage
} elseif ($GoogleStyle) {
    Select-GoogleStyleInitialPage -ResolvedInputPath $resolvedInputPath
} else {
    $null
}

$helperPath = if ($GoogleStyle) {
    Join-Path $repoRoot "scripts/windows/show_saved_page_google_validation_flow.ps1"
} else {
    Join-Path $repoRoot "scripts/windows/show_localhost_html_validation_flow.ps1"
}

if (-not (Test-Path -LiteralPath $helperPath -PathType Leaf)) {
    throw "validation flow helper not found: $helperPath"
}

$helperArgs = @{
    Port = $Port
}
if (-not ($GoogleStyle -and -not $usingExplicitInputPath)) {
    $helperArgs["InputPath"] = $resolvedInputPath
}
if ($resolvedPreferredInitialPage) {
    $helperArgs["PreferredInitialPage"] = $resolvedPreferredInitialPage
}

if ($Json) {
    $helperArgs["Json"] = $true
}
if ($GoogleStyle) {
    $helperArgs["ManualGoogleStyle"] = $true
}
if ($GoogleStyle -and $LeaveOpen) {
    $helperArgs["LeaveOpen"] = $true
}

if (-not $Json) {
    Write-Host "Attached HTML validation flow"
    Write-Host ""
    Write-Host ("Inputs discovered: {0}" -f $resolvedInputPath.Count)
    Write-Host ("Input mode: {0}" -f $(if ($usingExplicitInputPath) { "explicit" } else { "auto-discovered attached HTML" }))
    if ($resolvedPreferredInitialPage) {
        if ($PreferredInitialPage) {
            Write-Host ("Preferred initial page override: {0}" -f $resolvedPreferredInitialPage)
        } else {
            Write-Host ("Preferred initial page: {0}" -f $resolvedPreferredInitialPage)
        }
    } else {
        Write-Host "Preferred initial page: auto (from saved-page summary)"
    }
    Write-Host ("Validation mode: {0}" -f $(if ($GoogleStyle) { "google-style" } else { "general" }))
    Write-Host ""
}

& $helperPath @helperArgs
