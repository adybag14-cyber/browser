[CmdletBinding()]
param(
    [string]$BundleRoot = "",
    [string]$RepoRoot = "",
    [string]$BrowserExe = "",
    [string]$PreferredInitialPage = "Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StartPath
    )

    $cursor = [System.IO.Path]::GetFullPath($StartPath)
    while ($true) {
        if (Test-Path (Join-Path $cursor "build.zig")) {
            return $cursor
        }

        $parent = Split-Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            throw "Could not resolve the Lightpanda repo root from $StartPath. Pass -RepoRoot to override."
        }

        $cursor = $parent
    }
}

function Quote-PowerShellLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

if (-not $RepoRoot) {
    $RepoRoot = Resolve-RepoRoot -StartPath $PSScriptRoot
}

$defaultBrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
if (-not $BrowserExe) {
    $BrowserExe = $defaultBrowserExe
}

$bundleFiles = @(
    "Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html",
    "Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html",
    "Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html"
)

$quotedRepoRoot = Quote-PowerShellLiteral -Value $RepoRoot
$quotedBrowserExe = Quote-PowerShellLiteral -Value $BrowserExe
$quotedPreferredInitialPage = Quote-PowerShellLiteral -Value $PreferredInitialPage
$bundlePlaceholder = "'<bundle-root-containing-the-three-attached-html-files>'"
$bundleRootCommandArg = if ($BundleRoot) {
    "-InputPath " + (Quote-PowerShellLiteral -Value $BundleRoot)
} else {
    "-InputPath $bundlePlaceholder"
}
$bundleRootDisplay = if ($BundleRoot) {
    $BundleRoot
} else {
    "<bundle-root-containing-the-three-attached-html-files>"
}

$catalogAuditSidecars = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -RepoRoot $quotedRepoRoot $bundleRootCommandArg -AuditSidecars"
$catalogAuditAssets = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -RepoRoot $quotedRepoRoot $bundleRootCommandArg -AuditAssets"
$catalogPrintManifest = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\start_attached_pages_catalog.ps1 -RepoRoot $quotedRepoRoot $bundleRootCommandArg -PrintManifest"
$routerCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -RepoRoot $quotedRepoRoot -BrowserExe $quotedBrowserExe -ChangeArea attached-html-target-bundle $bundleRootCommandArg"
$suiteSurfaceCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -RepoRoot $quotedRepoRoot -BrowserExe $quotedBrowserExe $bundleRootCommandArg"
$bundleFirstCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1 -RepoRoot $quotedRepoRoot -BrowserExe $quotedBrowserExe $bundleRootCommandArg"
$googleFlowCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1 -RepoRoot $quotedRepoRoot -BrowserExe $quotedBrowserExe $bundleRootCommandArg -PreferredInitialPage $quotedPreferredInitialPage"
$runnerCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_attached_html_validation.ps1 -RepoRoot $quotedRepoRoot -BrowserExe $quotedBrowserExe $bundleRootCommandArg -PreferredInitialPage $quotedPreferredInitialPage -Wait"

Write-Host "Issue #3 current attached bundle quickstart"
Write-Host ""
Write-Host "Use this when the replay should stay pinned to the current three-page compatibility bundle before widening back into the broader attached-page router."
Write-Host "Guide: docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md"
Write-Host "Bundle root: $bundleRootDisplay"
Write-Host ("Browser exe: {0}" -f $BrowserExe)
Write-Host ("Preferred initial page: {0}" -f $PreferredInitialPage)
Write-Host ""
Write-Host "Pinned files:"
foreach ($bundleFile in $bundleFiles) {
    Write-Host ("- {0}" -f $bundleFile)
}
Write-Host ""
Write-Host "[preflight]"
Write-Host ("  {0}" -f $catalogAuditSidecars)
Write-Host ("  {0}" -f $catalogAuditAssets)
Write-Host ("  {0}" -f $catalogPrintManifest)
Write-Host ""
Write-Host "[route]"
Write-Host ("  {0}" -f $routerCommand)
Write-Host ("  {0}" -f $suiteSurfaceCommand)
Write-Host ("  {0}" -f $bundleFirstCommand)
Write-Host ("  {0}" -f $googleFlowCommand)
Write-Host ("  {0}" -f $runnerCommand)
Write-Host ""
Write-Host "Notes:"
Write-Host "- Run the sidecar audit first so a missing sibling _files directory is visible before the browser is blamed."
Write-Host "- Keep the dedicated Google-style flow visible even on the pinned bundle route so the stronger Google-like page stays easy to reopen."
Write-Host "- Pass -BundleRoot when the three attached files live outside the repo root or when you want the exact bundle reused end to end."
