[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "InputPath")]
    [string[]]$InputPath,

    [Parameter(ParameterSetName = "FixtureRoot")]
    [string]$FixtureRoot,

    [Parameter(ParameterSetName = "FixtureRoot")]
    [string]$PreferredInitialPage,

    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8168,
    [int]$WindowWidth = 1366,
    [int]$WindowHeight = 900,
    [int]$ServerReadyAttempts = 40,
    [int]$WindowReadyAttempts = 80,
    [int]$PollMilliseconds = 250,
    [switch]$AllowMissingLocalAssets,
    [switch]$GoogleStyle,
    [switch]$SurfaceOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$surfaceChecker = Join-Path $PSScriptRoot "check_local_html_fixture_validation_surface.ps1"
$probeRunner = Join-Path $resolvedRepoRoot "tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1"
foreach ($requiredPath in @($surfaceChecker, $probeRunner)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "required local HTML fixture validation path not found: $requiredPath"
    }
}

$resolvedInputPath = @()
$mode = $PSCmdlet.ParameterSetName
switch ($PSCmdlet.ParameterSetName) {
    "InputPath" {
        if (-not $InputPath -or $InputPath.Count -eq 0) {
            throw "Provide at least one -InputPath value."
        }
        $resolvedInputPath = @($InputPath)
    }
    "FixtureRoot" {
        if (-not (Test-Path -LiteralPath $FixtureRoot)) {
            throw "fixture root not found: $FixtureRoot"
        }
        $resolvedInputPath = @($FixtureRoot)
    }
    default {
        $resolvedInputPath = @(Resolve-FixtureSelection -RepoRoot $resolvedRepoRoot -GoogleStyle:$GoogleStyle -MaxCount 3)
        if ($resolvedInputPath.Count -eq 0) {
            $searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $resolvedRepoRoot)
            throw "No fixture input was provided, and no attached HTML files were found under: $($searchRoots -join '; '). Pass -FixtureRoot for one saved-page directory or -InputPath for one or more saved HTML files or directories."
        }
        $mode = if ($GoogleStyle) { "Auto (Google-style attached HTML)" } else { "Auto (attached HTML)" }
    }
}

$surfaceArgs = @{
    RepoRoot = $resolvedRepoRoot
    InputPath = $resolvedInputPath
}

Write-Host "Local HTML fixture validation"
Write-Host ""
Write-Host ("Mode: {0}" -f $mode)
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
Write-Host ("Fixture inputs: {0}" -f $resolvedInputPath.Count)
if ($AllowMissingLocalAssets) {
    Write-Host "Asset policy: degraded mode allowed"
}
Write-Host ("Surface checker: .\scripts\windows\check_local_html_fixture_validation_surface.ps1")
Write-Host ("Probe runner: .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1")
Write-Host ""

& $surfaceChecker @surfaceArgs
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if ($SurfaceOnly) {
    Write-Host ""
    Write-Host "Surface check passed."
    exit 0
}

$probeArgs = @{
    RepoRoot = $resolvedRepoRoot
    Host = $Host
    Port = $Port
    WindowWidth = $WindowWidth
    WindowHeight = $WindowHeight
    ServerReadyAttempts = $ServerReadyAttempts
    WindowReadyAttempts = $WindowReadyAttempts
    PollMilliseconds = $PollMilliseconds
}
if ($BrowserExe) {
    $probeArgs.BrowserExe = $BrowserExe
}
if ($AllowMissingLocalAssets) {
    $probeArgs.AllowMissingLocalAssets = $true
}

if ($PSCmdlet.ParameterSetName -eq "FixtureRoot") {
    $probeArgs.FixtureRoot = $FixtureRoot
    if ($PreferredInitialPage) {
        $probeArgs.PreferredInitialPage = $PreferredInitialPage
    }
} else {
    $probeArgs.FixturePaths = $resolvedInputPath
}

Write-Host "Running staged local HTML fixture probe..."
Write-Host ""
& $probeRunner @probeArgs
exit $LASTEXITCODE
