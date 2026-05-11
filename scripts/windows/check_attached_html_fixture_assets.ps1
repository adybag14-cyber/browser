[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "Explicit", Mandatory = $true)]
    [string[]]$InputPath,

    [string]$RepoRoot,
    [switch]$GoogleStyle,
    [switch]$Json,
    [switch]$ShowPassing
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Get-ResolvedFixturePaths {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [string[]]$InputPath,
        [Parameter(Mandatory = $true)]
        [bool]$GoogleStyle,
        [Parameter(Mandatory = $true)]
        [string]$ParameterSetName
    )

    if ($ParameterSetName -eq "Explicit") {
        return @($InputPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path })
    }

    return @(Get-DefaultAttachedHtmlInputPath -RepoRoot $RepoRoot -GoogleStyle:$GoogleStyle)
}

if (-not $RepoRoot) {
    $RepoRoot = Resolve-LightpandaRepoRoot $PSScriptRoot
}

$searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot)
$resolvedInputPath = Get-ResolvedFixturePaths `
    -RepoRoot $RepoRoot `
    -InputPath $InputPath `
    -GoogleStyle ([bool]$GoogleStyle) `
    -ParameterSetName $PSCmdlet.ParameterSetName
$assetAudit = @(Get-MissingLocalFixtureAssetAudit -FixturePaths $resolvedInputPath)
$fixturesWithMissingAssets = @($assetAudit | Where-Object { $_.missing_asset_count -gt 0 })

if ($Json) {
    $result = [ordered]@{
        repo_root = $RepoRoot
        parameter_set = $PSCmdlet.ParameterSetName
        google_style = [bool]$GoogleStyle
        search_roots = $searchRoots
        fixture_count = $resolvedInputPath.Count
        missing_fixture_count = $fixturesWithMissingAssets.Count
        fixtures = @(
            $assetAudit | ForEach-Object {
                [ordered]@{
                    path = $_.path
                    display_path = Convert-ToDisplayPath -Path $_.path -RepoRoot $RepoRoot
                    missing_asset_count = $_.missing_asset_count
                    missing_assets = $_.missing_assets
                }
            }
        )
    }

    $result | ConvertTo-Json -Depth 8
    if ($fixturesWithMissingAssets.Count -gt 0) {
        exit 1
    }
    exit 0
}

Write-Host "Attached HTML fixture asset audit"
Write-Host ""
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Input mode: {0}" -f $(if ($PSCmdlet.ParameterSetName -eq "Explicit") { "explicit" } else { "auto-discovered" }))
Write-Host ("Validation mode: {0}" -f $(if ($GoogleStyle) { "google-style" } else { "general" }))
if ($searchRoots.Count -gt 0) {
    Write-Host ("Search roots: {0}" -f ($searchRoots -join "; "))
}
Write-Host ("Fixtures audited: {0}" -f $resolvedInputPath.Count)
Write-Host ""

foreach ($fixture in $assetAudit) {
    if (-not $ShowPassing -and $fixture.missing_asset_count -eq 0) {
        continue
    }

    $displayPath = Convert-ToDisplayPath -Path $fixture.path -RepoRoot $RepoRoot
    if ($fixture.missing_asset_count -eq 0) {
        Write-Host ("[PASS] {0}" -f $displayPath)
        Write-Host "  All referenced sibling local assets were found."
        continue
    }

    Write-Host ("[FAIL] {0}" -f $displayPath)
    Write-Host ("  Missing assets: {0}" -f $fixture.missing_asset_count)
    foreach ($asset in ($fixture.missing_assets | Select-Object -First 10)) {
        Write-Host ("  - {0}" -f $asset)
    }
    if ($fixture.missing_asset_count -gt 10) {
        Write-Host ("  - ... {0} more" -f ($fixture.missing_asset_count - 10))
    }
}

Write-Host ""
if ($fixturesWithMissingAssets.Count -eq 0) {
    Write-Host "Attached HTML asset audit passed."
    exit 0
}

Write-Host ("Attached HTML asset audit failed for {0} fixture(s)." -f $fixturesWithMissingAssets.Count)
Write-Host "Restore the missing sibling files or *_files directories before relying on localhost headed replay."
exit 1
