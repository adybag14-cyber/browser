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

function Get-AttachedHtmlFlowMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [string[]]$ResolvedInputPath,
        [string]$PreferredInitialPage,
        [string]$ResolvedPreferredInitialPage,
        [Parameter(Mandatory = $true)]
        [bool]$UsingExplicitInputPath,
        [Parameter(Mandatory = $true)]
        [bool]$GoogleStyle,
        [Parameter(Mandatory = $true)]
        [bool]$LeaveOpen,
        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    $preferredInitialPageMode = if ($PreferredInitialPage) {
        "explicit"
    } elseif ($ResolvedPreferredInitialPage) {
        if ($GoogleStyle) { "google-style-auto" } else { "auto-selected" }
    } else {
        "saved-page-summary-auto"
    }

    return [ordered]@{
        input_mode = if ($UsingExplicitInputPath) { "explicit" } else { "auto-discovered attached HTML" }
        input_count = @($ResolvedInputPath).Count
        resolved_input_path = @($ResolvedInputPath)
        preferred_initial_page = $ResolvedPreferredInitialPage
        preferred_initial_page_mode = $preferredInitialPageMode
        validation_mode = if ($GoogleStyle) { "google-style" } else { "general" }
        leave_open = $LeaveOpen
        port = $Port
        search_roots = if ($UsingExplicitInputPath) { @() } else { @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot) }
    }
}

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
if ($GoogleStyle) {
    $helperArgs["ManualGoogleStyle"] = $true
}
if ($GoogleStyle -and $LeaveOpen) {
    $helperArgs["LeaveOpen"] = $true
}

$attachedHtmlMetadata = Get-AttachedHtmlFlowMetadata `
    -RepoRoot $repoRoot `
    -ResolvedInputPath $resolvedInputPath `
    -PreferredInitialPage $PreferredInitialPage `
    -ResolvedPreferredInitialPage $resolvedPreferredInitialPage `
    -UsingExplicitInputPath ([bool]$usingExplicitInputPath) `
    -GoogleStyle ([bool]$GoogleStyle) `
    -LeaveOpen ([bool]$LeaveOpen) `
    -Port $Port

if ($Json) {
    $helperArgs["Json"] = $true
    $helperJson = (& $helperPath @helperArgs) -join [Environment]::NewLine
    $result = [ordered]@{
        attached_html = $attachedHtmlMetadata
        flow = $helperJson | ConvertFrom-Json -Depth 10
    }
    $result | ConvertTo-Json -Depth 10
    exit $LASTEXITCODE
}

Write-Host "Attached HTML validation flow"
Write-Host ""
Write-Host ("Inputs discovered: {0}" -f $attachedHtmlMetadata.input_count)
Write-Host ("Input mode: {0}" -f $attachedHtmlMetadata.input_mode)
if ($resolvedPreferredInitialPage) {
    if ($PreferredInitialPage) {
        Write-Host ("Preferred initial page override: {0}" -f $resolvedPreferredInitialPage)
    } else {
        Write-Host ("Preferred initial page: {0}" -f $resolvedPreferredInitialPage)
    }
} else {
    Write-Host "Preferred initial page: auto (from saved-page summary)"
}
Write-Host ("Validation mode: {0}" -f $attachedHtmlMetadata.validation_mode)
Write-Host ""

& $helperPath @helperArgs
