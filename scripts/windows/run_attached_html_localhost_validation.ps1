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

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\\..")).Path
}

$resolvedInputPath = if ($InputPath -and $InputPath.Count -gt 0) {
    @($InputPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path })
} else {
    Get-DefaultAttachedHtmlInputPath -RepoRoot $RepoRoot
}

$resolvedPreferredInitialPage = if ($PreferredInitialPage) {
    (Resolve-Path -LiteralPath $PreferredInitialPage).Path
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
