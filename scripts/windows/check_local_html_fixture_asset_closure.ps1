[CmdletBinding(DefaultParameterSetName = "ByPaths")]
param(
    [Parameter(Mandatory = $true, ParameterSetName = "ByPaths")]
    [string[]]$FixturePaths,
    [Parameter(Mandatory = $true, ParameterSetName = "ByRoot")]
    [string]$FixtureRoot,
    [string]$RepoRoot,
    [switch]$Json,
    [switch]$AllowMissingAssets
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Resolve-FixtureFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ParameterSetName,
        [string[]]$FixturePaths,
        [string]$FixtureRoot
    )

    if ($ParameterSetName -eq "ByPaths") {
        $resolved = @()
        foreach ($path in $FixturePaths) {
            if (-not (Test-Path -LiteralPath $path)) {
                throw "fixture path not found: $path"
            }

            $item = Get-Item -LiteralPath $path
            if ($item.PSIsContainer) {
                $resolved += Get-ChildItem -LiteralPath $item.FullName -Recurse -File -Filter *.html | Sort-Object FullName
            } else {
                $resolved += $item
            }
        }

        return @($resolved | Select-Object -ExpandProperty FullName -Unique)
    }

    $root = [System.IO.Path]::GetFullPath($FixtureRoot)
    if (-not (Test-Path -LiteralPath $root)) {
        throw "fixture root not found: $root"
    }

    $resolved = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter *.html | Sort-Object FullName)
    if (-not $resolved) {
        throw "fixture root does not contain any .html files: $root"
    }

    return @($resolved | Select-Object -ExpandProperty FullName -Unique)
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$closureChecker = Join-Path $PSScriptRoot "check_attached_html_local_asset_closure.ps1"
if (-not (Test-Path -LiteralPath $closureChecker -PathType Leaf)) {
    throw "Attached HTML asset-closure checker not found: $closureChecker"
}

$resolvedFixtures = Resolve-FixtureFiles `
    -ParameterSetName $PSCmdlet.ParameterSetName `
    -FixturePaths $FixturePaths `
    -FixtureRoot $FixtureRoot

$checkerArgs = @{
    RepoRoot = $resolvedRepoRoot
    InputPath = $resolvedFixtures
}
if ($AllowMissingAssets) {
    $checkerArgs.AllowMissingAssets = $true
}

if ($Json) {
    $checkerArgs.Json = $true
    & $closureChecker @checkerArgs
    exit $LASTEXITCODE
}

Write-Host "Local HTML fixture asset-closure check"
Write-Host ""
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
Write-Host ("Fixtures: {0}" -f $resolvedFixtures.Count)
Write-Host ""

& $closureChecker @checkerArgs
exit $LASTEXITCODE
