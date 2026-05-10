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
$resolvedInputPath = if ($InputPath -and $InputPath.Count -gt 0) {
    @($InputPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path })
} else {
    Get-DefaultAttachedHtmlInputPath -RepoRoot $repoRoot
}

$resolvedPreferredInitialPage = if ($PreferredInitialPage) {
    (Resolve-Path -LiteralPath $PreferredInitialPage).Path
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
    InputPath = $resolvedInputPath
    Port = $Port
}
if ($resolvedPreferredInitialPage) {
    $helperArgs["PreferredInitialPage"] = $resolvedPreferredInitialPage
}

if ($Json) {
    $helperArgs["Json"] = $true
}
if ($GoogleStyle -and $LeaveOpen) {
    $helperArgs["LeaveOpen"] = $true
}

if (-not $Json) {
    Write-Host "Attached HTML validation flow"
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
    Write-Host ""
}

& $helperPath @helperArgs
