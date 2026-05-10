[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "PageRoot")]
    [string]$PageRoot,

    [Parameter(ParameterSetName = "InputPath")]
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

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

$runner = Join-Path $PSScriptRoot "run_localhost_html_validation_recommended.ps1"
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw "Google-style attached HTML validation runner not found: $runner"
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}
$resolvedPageRoot = if ($PageRoot) {
    (Resolve-Path -LiteralPath $PageRoot).Path
} else {
    $null
}
$resolvedInputPath = switch ($PSCmdlet.ParameterSetName) {
    "PageRoot" { @() }
    "InputPath" { @($InputPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path }) }
    default { Get-DefaultAttachedHtmlInputPath -RepoRoot $resolvedRepoRoot -GoogleStyle }
}
$resolvedPreferredInitialPage = if ($PreferredInitialPage) {
    if ($PSCmdlet.ParameterSetName -eq "PageRoot") {
        $PreferredInitialPage
    } else {
        Resolve-AttachedPreferredInitialPage -ResolvedInputPath $resolvedInputPath -PreferredInitialPage $PreferredInitialPage
    }
} elseif ($PSCmdlet.ParameterSetName -eq "PageRoot") {
    $null
} else {
    Select-GoogleStyleInitialPage -ResolvedInputPath $resolvedInputPath
}

$arguments = @{
    Host = $Host
    Port = $Port
    GoogleStyle = $true
    RepoRoot = $resolvedRepoRoot
}
if ($BrowserExe) {
    $arguments.BrowserExe = $BrowserExe
}
if ($resolvedPreferredInitialPage) {
    $arguments.PreferredInitialPage = $resolvedPreferredInitialPage
}
if ($SummaryOnly) {
    $arguments.SummaryOnly = $true
}
if ($Wait) {
    $arguments.Wait = $true
}
if ($LeaveServerRunning) {
    $arguments.LeaveServerRunning = $true
}

Write-Host "Google-style attached HTML validation"
Write-Host ""
Write-Host "Mode: attached HTML auto-discovery with the Google-style localhost follow-up"
switch ($PSCmdlet.ParameterSetName) {
    "PageRoot" {
        Write-Host ("Mode detail: explicit page root ({0})" -f $resolvedPageRoot)
    }
    "InputPath" {
        Write-Host ("Mode detail: explicit saved HTML inputs ({0}) locked before launch." -f $resolvedInputPath.Count)
    }
    default {
        Write-Host ("Mode detail: auto-discovered attached HTML inputs ({0}) locked before launch." -f $resolvedInputPath.Count)
    }
}
if ($PSCmdlet.ParameterSetName -eq "Auto") {
    $searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $resolvedRepoRoot)
    if ($searchRoots.Count -gt 0) {
        Write-Host "Search roots:"
        foreach ($root in $searchRoots) {
            Write-Host ("- {0}" -f (Convert-ToDisplayPath -Path $root -RepoRoot $resolvedRepoRoot))
        }
    }
}
if ($resolvedInputPath.Count -gt 0) {
    Write-Host ""
    Show-FixtureSelectionSummary -FixturePaths $resolvedInputPath -RepoRoot $resolvedRepoRoot
}
if ($resolvedPreferredInitialPage) {
    Write-Host ""
    if ($PreferredInitialPage) {
        Write-Host ("Preferred initial page override: {0}" -f $resolvedPreferredInitialPage)
    } else {
        Write-Host ("Preferred initial page: {0}" -f $resolvedPreferredInitialPage)
    }
}
Write-Host "Override: use -PreferredInitialPage to pin the first Google-like page, or pass -PageRoot / -InputPath to skip auto-discovery."
if ($SummaryOnly) {
    Write-Host "Launch mode: summary only"
} elseif ($Wait) {
    Write-Host "Launch mode: launch and wait"
}
Write-Host "Runner: .\scripts\windows\run_localhost_html_validation_recommended.ps1 -GoogleStyle"
Write-Host ""

switch ($PSCmdlet.ParameterSetName) {
    "PageRoot" {
        & $runner @arguments -PageRoot $resolvedPageRoot
        exit $LASTEXITCODE
    }
    default {
        & $runner @arguments -InputPath $resolvedInputPath
        exit $LASTEXITCODE
    }
}
