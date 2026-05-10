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

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

$repoRoot = Resolve-LightpandaRepoRoot $PSScriptRoot
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
