[CmdletBinding()]
param(
    [string]$PageRoot,
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

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

if (-not $PageRoot -and (-not $InputPath -or $InputPath.Count -eq 0)) {
    throw "either PageRoot or InputPath is required"
}

$summaryHelper = Join-Path $PSScriptRoot "summarize_localhost_html_pages.ps1"
$directHelper = Join-Path $PSScriptRoot "start_localhost_html_validation.ps1"
$stagedHelper = Join-Path $PSScriptRoot "start_staged_localhost_html_validation.ps1"

foreach ($helper in @($summaryHelper, $directHelper, $stagedHelper)) {
    if (-not (Test-Path -LiteralPath $helper -PathType Leaf)) {
        throw "required helper not found: $helper"
    }
}

$summaryArgs = @{
    RepoRoot = $RepoRoot
    Host = $Host
    Port = $Port
}
if ($PageRoot) {
    $summaryArgs.PageRoot = $PageRoot
}
if ($InputPath -and $InputPath.Count -gt 0) {
    $summaryArgs.InputPath = $InputPath
}
if ($PreferredInitialPage) {
    $summaryArgs.PreferredInitialPage = $PreferredInitialPage
}

$summaryJson = & $summaryHelper @summaryArgs
$summary = $summaryJson | ConvertFrom-Json -Depth 8

Write-Host ("Recommended bounded suites: {0}" -f (($summary.overall_recommended_suites | Where-Object { $_ }) -join ", ")))
Write-Host ("Recommended initial page: {0}" -f $summary.recommended_initial_page)
Write-Host ("Flow helper: {0}" -f $summary.recommended_flow_helper)
Write-Host ("Next step: {0}" -f $summary.next_step)
Write-Host ""

if ($SummaryOnly) {
    $summary | ConvertTo-Json -Depth 8
    exit 0
}

$initialPage = [string]$summary.recommended_initial_page

$launchHelper = if ($InputPath -and $InputPath.Count -gt 0) {
    $stagedHelper
} else {
    $directHelper
}

$launchArgs = @{
    RepoRoot = $RepoRoot
    Host = $Host
    Port = $Port
    LaunchBrowser = $true
}
if ($BrowserExe) {
    $launchArgs.BrowserExe = $BrowserExe
}
if ($Wait) {
    $launchArgs.Wait = $true
}
if ($LeaveServerRunning) {
    $launchArgs.LeaveServerRunning = $true
}
if ($initialPage) {
    $launchArgs.InitialPage = $initialPage
}
if ($InputPath -and $InputPath.Count -gt 0) {
    $launchArgs.InputPath = $InputPath
} else {
    $launchArgs.PageRoot = $PageRoot
}

Write-Host ("Launching saved-page localhost validation with {0}" -f ([System.IO.Path]::GetFileName($launchHelper)))
Write-Host ("Initial page target: {0}" -f $initialPage)
Write-Host ""

& $launchHelper @launchArgs
