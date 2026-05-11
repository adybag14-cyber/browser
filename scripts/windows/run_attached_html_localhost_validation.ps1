[CmdletBinding()]
param(
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8123,
    [switch]$GoogleStyle,
    [switch]$SummaryOnly,
    [switch]$Wait,
    [switch]$LeaveServerRunning,
    [switch]$AllowMissingLocalAssets
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

if (-not $RepoRoot) {
    $RepoRoot = Resolve-LightpandaRepoRoot $PSScriptRoot
}

$runnerPath = Join-Path $RepoRoot "scripts/windows/run_sanitized_saved_page_localhost_validation.ps1"
$surfaceChecker = Join-Path $RepoRoot "scripts/windows/check_attached_html_validation_surface.ps1"
$assetClosureChecker = Join-Path $RepoRoot "scripts/windows/check_attached_html_local_asset_closure.ps1"
if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) {
    throw "sanitized saved-page localhost validation runner not found: $runnerPath"
}
if (-not (Test-Path -LiteralPath $surfaceChecker -PathType Leaf)) {
    throw "attached HTML validation surface checker not found: $surfaceChecker"
}
if (-not (Test-Path -LiteralPath $assetClosureChecker -PathType Leaf)) {
    throw "attached HTML local asset-closure checker not found: $assetClosureChecker"
}

$surfaceCheckArgs = @{ RepoRoot = $RepoRoot }
if ($SummaryOnly) {
    $surfaceCheckArgs["Json"] = $true
    & $surfaceChecker @surfaceCheckArgs | Out-Null
} else {
    & $surfaceChecker @surfaceCheckArgs
    Write-Host ""
}
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$resolvedInputPath = if ($InputPath -and $InputPath.Count -gt 0) {
    @($InputPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path })
} else {
    Get-DefaultAttachedHtmlInputPath -RepoRoot $RepoRoot -GoogleStyle:$GoogleStyle
}

$resolvedPreferredInitialPage = if ($PreferredInitialPage) {
    Resolve-AttachedPreferredInitialPage -ResolvedInputPath $resolvedInputPath -PreferredInitialPage $PreferredInitialPage
} elseif ($GoogleStyle) {
    Select-GoogleStyleInitialPage -ResolvedInputPath $resolvedInputPath
} else {
    $null
}

$attachedAssetAudit = @(Get-MissingLocalFixtureAssetAudit -FixturePaths $resolvedInputPath)
$assetClosureArgs = @{
    RepoRoot = $RepoRoot
    InputPath = $resolvedInputPath
}
if ($GoogleStyle) {
    $assetClosureArgs["GoogleStyle"] = $true
}
if ($AllowMissingLocalAssets) {
    $assetClosureArgs["AllowMissingAssets"] = $true
}

if ($SummaryOnly) {
    $assetClosureArgs["Json"] = $true
    & $assetClosureChecker @assetClosureArgs | Out-Null
} else {
    & $assetClosureChecker @assetClosureArgs
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Write-Host ""
}
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
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
        if ($PreferredInitialPage) {
            Write-Host ("Preferred initial page override: {0}" -f $resolvedPreferredInitialPage)
        } else {
            Write-Host ("Preferred initial page: {0}" -f $resolvedPreferredInitialPage)
        }
    } else {
        Write-Host "Preferred initial page: auto (from saved-page summary)"
    }
    Write-Host ("Validation mode: {0}" -f $(if ($GoogleStyle) { "google-style" } else { "general" }))
    Write-Host "Staging mode: sanitized attached HTML inputs"
    Write-Host "Runner: .\\scripts\\windows\\run_sanitized_saved_page_localhost_validation.ps1"
    Write-Host ""
    if ($AllowMissingLocalAssets) {
        Write-Host "Preflight: attached HTML validation surface passed and deep attached-asset closure audit is advisory in degraded localhost mode."
    } else {
        Write-Host "Preflight: attached HTML validation surface and deep attached-asset closure audit passed before launch."
    }
    Write-Host ""
}

Show-MissingLocalFixtureAssetWarnings -AssetAudit $attachedAssetAudit -RepoRoot $RepoRoot

& $runnerPath @runnerArgs
