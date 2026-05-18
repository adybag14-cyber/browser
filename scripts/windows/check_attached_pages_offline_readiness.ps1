[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "InputPath")]
    [string[]]$InputPath,
    [string]$RepoRoot,
    [string]$PythonExe = "python",
    [switch]$GoogleStyle,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$checkerPath = Join-Path $resolvedRepoRoot "tmp-browser-smoke/attached-pages/check_attached_pages_offline_readiness.py"
if (-not (Test-Path -LiteralPath $checkerPath -PathType Leaf)) {
    throw "attached pages offline readiness checker not found: $checkerPath"
}

$resolvedPython = (Get-Command $PythonExe -ErrorAction Stop).Source
$resolvedInputPath = if ($PSCmdlet.ParameterSetName -eq "InputPath") {
    @(Get-ResolvedExplicitBundleInputPaths -InputPath $InputPath)
} else {
    Get-DefaultAttachedHtmlInputPath -RepoRoot $resolvedRepoRoot -GoogleStyle:$GoogleStyle
}
if (-not $resolvedInputPath -or $resolvedInputPath.Count -eq 0) {
    throw "No attached HTML inputs were resolved for the offline readiness check."
}

$checkerArgs = @($checkerPath)
foreach ($path in $resolvedInputPath) {
    $checkerArgs += @("--input", $path)
}
if ($Json) {
    $checkerArgs += "--json"
}

if (-not $Json) {
    Write-Host "Attached pages offline readiness"
    Write-Host ""
    Write-Host ("Mode: {0}" -f $(if ($GoogleStyle) { "google-style auto-discovery" } elseif ($PSCmdlet.ParameterSetName -eq "InputPath") { "explicit pinned inputs" } else { "auto-discovery" }))
    Write-Host ("Inputs pinned: {0}" -f $resolvedInputPath.Count)
    Show-FixtureSelectionSummary -FixturePaths $resolvedInputPath -RepoRoot $resolvedRepoRoot -GoogleStyle:$GoogleStyle
    Write-Host ""
}

& $resolvedPython @checkerArgs
exit $LASTEXITCODE
