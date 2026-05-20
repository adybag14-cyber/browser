[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "InputPath")]
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
    [string]$RepoRoot,
    [string]$PythonExe = "python",
    [switch]$GoogleStyle,
    [switch]$Json,
    [switch]$AllowMissingSidecars,
    [switch]$AllowMissingAssets
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$reportPath = Join-Path $resolvedRepoRoot "tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py"
if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
    throw "attached pages preflight report not found: $reportPath"
}

$resolvedPython = (Get-Command $PythonExe -ErrorAction Stop).Source

$reportArgs = @($reportPath, "--repo-root", $resolvedRepoRoot)

if ($PSCmdlet.ParameterSetName -eq "InputPath") {
    foreach ($path in $InputPath) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }
        $reportArgs += @("--input", $path)
    }
    if ($reportArgs.Count -le 3) {
        throw "No attached HTML inputs were provided for the preflight report helper."
    }
}

if (-not [string]::IsNullOrWhiteSpace($PreferredInitialPage)) {
    $reportArgs += @("--preferred-initial-page", $PreferredInitialPage)
}
if ($GoogleStyle) {
    $reportArgs += "--google-style"
}
if ($Json) {
    $reportArgs += "--json"
}
if ($AllowMissingSidecars) {
    $reportArgs += "--allow-missing-sidecars"
}
if ($AllowMissingAssets) {
    $reportArgs += "--allow-missing-assets"
}

& $resolvedPython @reportArgs
exit $LASTEXITCODE