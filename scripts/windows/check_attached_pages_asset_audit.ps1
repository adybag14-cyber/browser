[CmdletBinding()]
param(
    [string[]]$InputPath,
    [string]$RepoRoot,
    [switch]$GoogleStyle,
    [switch]$Json,
    [switch]$AllowMissingAssets
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

if (-not $RepoRoot) {
    $RepoRoot = Resolve-LightpandaRepoRoot $PSScriptRoot
}

$serverScript = Join-Path $RepoRoot "tmp-browser-smoke/attached-pages/attached_pages_server.py"
if (-not (Test-Path -LiteralPath $serverScript -PathType Leaf)) {
    throw "Attached pages audit helper not found: $serverScript"
}

$pythonExe = if (Get-Command python -ErrorAction SilentlyContinue) {
    "python"
} elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    "python3"
} else {
    throw "Could not find python or python3 in PATH."
}

$resolvedInputPath = if ($InputPath -and $InputPath.Count -gt 0) {
    @($InputPath | ForEach-Object { (Resolve-Path -LiteralPath $_ -ErrorAction Stop).Path })
} else {
    Get-DefaultAttachedHtmlInputPath -RepoRoot $RepoRoot -GoogleStyle:$GoogleStyle
}

$argumentList = [System.Collections.Generic.List[string]]::new()
$argumentList.Add($serverScript) | Out-Null
foreach ($path in $resolvedInputPath) {
    $argumentList.Add("--input") | Out-Null
    $argumentList.Add($path) | Out-Null
}
$argumentList.Add("--audit-assets") | Out-Null
if ($Json) {
    $argumentList.Add("--audit-assets-json") | Out-Null
}
if ($AllowMissingAssets) {
    $argumentList.Add("--allow-missing-assets") | Out-Null
}

if (-not $Json) {
    Write-Host "Attached pages asset audit"
    Write-Host ""
    Write-Host (("Repo root: {0}") -f $RepoRoot)
    Write-Host (("Python:    {0}") -f $pythonExe)
    Write-Host (("Inputs:    {0}") -f $resolvedInputPath.Count)
    if ($GoogleStyle) {
        Write-Host "Mode:      Google-style attached-page preference"
    }
    Write-Host ""
    Show-FixtureSelectionSummary -FixturePaths $resolvedInputPath -RepoRoot $RepoRoot -GoogleStyle:$GoogleStyle
    Write-Host ""
    Write-Host (("Command: {0} {1}") -f $pythonExe, (($argumentList | ForEach-Object { Format-PowerShellLiteral "$_" }) -join " ")))
    Write-Host ""
}

& $pythonExe @argumentList
exit $LASTEXITCODE
