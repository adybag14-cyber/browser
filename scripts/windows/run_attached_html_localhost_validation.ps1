[CmdletBinding()]
param(
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8123,
    [switch]$SummaryOnly,
    [switch]$Wait,
    [switch]$LeaveServerRunning
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-DefaultAttachedHtmlInputPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $agentFilesRoot = Join-Path $RepoRoot "agent_files"
    if (-not (Test-Path -LiteralPath $agentFilesRoot -PathType Container)) {
        throw "agent_files directory not found: $agentFilesRoot"
    }

    $htmlFiles = Get-ChildItem -LiteralPath $agentFilesRoot -Recurse -File |
        Where-Object { $_.Extension -in @(".html", ".htm") } |
        Sort-Object FullName

    if ($htmlFiles.Count -eq 0) {
        throw "no attached HTML files were found anywhere under $agentFilesRoot"
    }

    return @($htmlFiles.FullName)
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

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\\..")).Path
}

$resolvedInputPath = if ($InputPath -and $InputPath.Count -gt 0) {
    @($InputPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path })
} else {
    Get-DefaultAttachedHtmlInputPath -RepoRoot $RepoRoot
}

$resolvedPreferredInitialPage = if ($PreferredInitialPage) {
    Resolve-AttachedPreferredInitialPage -ResolvedInputPath $resolvedInputPath -PreferredInitialPage $PreferredInitialPage
} else {
    $null
}

$runnerPath = Join-Path $RepoRoot "scripts/windows/run_saved_page_localhost_validation.ps1"
if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) {
    throw "saved-page localhost validation runner not found: $runnerPath"
}

$runnerArgs = @{
    InputPath = $resolvedInputPath
    RepoRoot = $RepoRoot
    Host = $Host
    Port = $Port
}
if ($resolvedPreferredInitialPage) {
    $runnerArgs["PreferredInitialPage"] = $resolvedPreferredInitialPage
}

if ($BrowserExe) {
    $runnerArgs["BrowserExe"] = $BrowserExe
}
if ($SummaryOnly) {
    $runnerArgs["SummaryOnly"] = $true
}
if ($Wait) {
    $runnerArgs["Wait"] = $true
}
if ($LeaveServerRunning) {
    $runnerArgs["LeaveServerRunning"] = $true
}

if (-not $SummaryOnly) {
    Write-Host "Attached HTML localhost validation"
    Write-Host ""
    Write-Host ("Inputs discovered: {0}" -f $resolvedInputPath.Count)
    if ($resolvedPreferredInitialPage) {
        Write-Host ("Preferred initial page override: {0}" -f $resolvedPreferredInitialPage)
    } else {
        Write-Host "Preferred initial page: auto (from saved-page summary)"
    }
    Write-Host "Runner: .\\scripts\\windows\\run_saved_page_localhost_validation.ps1"
    Write-Host ""
}

& $runnerPath @runnerArgs
