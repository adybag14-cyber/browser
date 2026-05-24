[CmdletBinding()]
param(
    [ValidateSet(
        "attached-html",
        "attached-html-target-bundle",
        "browser-shell",
        "google-attached-html",
        "google-form-controls-enter-order",
        "google-input",
        "google-recommended",
        "google-shared-enter-order",
        "input",
        "manual-html",
        "navigation",
        "network",
        "popup",
        "rendering",
        "stop-loading"
    )]
    [string]$SuiteName,
    [string]$RepoRoot = "",
    [string]$BrowserExe = "",
    [string]$SummaryPath = "",
    [string]$InputPath = "",
    [string]$PreferredInitialPage = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$suiteTargets = @{
    "attached-html" = @{ Parameter = "ChangeArea"; Value = "attached-html" }
    "attached-html-target-bundle" = @{ Parameter = "SuiteName"; Value = "attached-html-target-bundle" }
    "browser-shell" = @{ Parameter = "ChangeArea"; Value = "browser-shell" }
    "google-attached-html" = @{ Parameter = "SuiteName"; Value = "google-attached-html" }
    "google-form-controls-enter-order" = @{ Parameter = "SuiteName"; Value = "google-form-controls-enter-order" }
    "google-input" = @{ Parameter = "ChangeArea"; Value = "google-input" }
    "google-recommended" = @{ Parameter = "SuiteName"; Value = "google-recommended" }
    "google-shared-enter-order" = @{ Parameter = "SuiteName"; Value = "google-shared-enter-order" }
    "input" = @{ Parameter = "ChangeArea"; Value = "input" }
    "manual-html" = @{ Parameter = "ChangeArea"; Value = "manual-html" }
    "navigation" = @{ Parameter = "ChangeArea"; Value = "navigation" }
    "network" = @{ Parameter = "ChangeArea"; Value = "network" }
    "popup" = @{ Parameter = "ChangeArea"; Value = "popup" }
    "rendering" = @{ Parameter = "ChangeArea"; Value = "rendering" }
    "stop-loading" = @{ Parameter = "ChangeArea"; Value = "stop-loading" }
}

$target = $suiteTargets[$SuiteName]
if ($null -eq $target) {
    throw "Unsupported suite name: $SuiteName"
}

$routerPath = Join-Path $PSScriptRoot "show_headed_validation_suites.ps1"
if (-not (Test-Path -LiteralPath $routerPath -PathType Leaf)) {
    throw "Headed validation router not found: $routerPath"
}

$forwardArgs = @{}
$forwardArgs[$target.Parameter] = $target.Value

if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
    $forwardArgs["RepoRoot"] = $RepoRoot
}
if (-not [string]::IsNullOrWhiteSpace($BrowserExe)) {
    $forwardArgs["BrowserExe"] = $BrowserExe
}
if (-not [string]::IsNullOrWhiteSpace($SummaryPath)) {
    $forwardArgs["SummaryPath"] = $SummaryPath
}
if (-not [string]::IsNullOrWhiteSpace($InputPath)) {
    $forwardArgs["InputPath"] = $InputPath
}
if (-not [string]::IsNullOrWhiteSpace($PreferredInitialPage)) {
    $forwardArgs["PreferredInitialPage"] = $PreferredInitialPage
}

& $routerPath @forwardArgs
