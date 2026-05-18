[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$PythonExe = "python",
    [switch]$AllowRawLauncher,
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

$auditScriptPath = Join-Path $resolvedRepoRoot "tmp-browser-smoke/attached-pages/attached_pages_launcher_reference_audit.py"
if (-not (Test-Path -LiteralPath $auditScriptPath -PathType Leaf)) {
    throw "attached-pages launcher reference audit helper not found: $auditScriptPath"
}

$targetPaths = @(
    (Join-Path $resolvedRepoRoot "docs/ISSUE3_REPLAY_DISCOVERY_HANDOFF.md"),
    (Join-Path $resolvedRepoRoot "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md")
)

foreach ($path in $targetPaths) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "launcher reference audit target not found: $path"
    }
}

$resolvedPython = (Get-Command $PythonExe -ErrorAction Stop).Source

$auditArgs = @($auditScriptPath)
foreach ($path in $targetPaths) {
    $auditArgs += @("--path", $path)
}
$auditArgs += @("--require-wrapper-sidecar", "--require-google-wrapper-sidecar")

if ($AllowRawLauncher) {
    $auditArgs += "--allow-raw-launcher"
}
if ($Json) {
    $auditArgs += "--json"
}

& $resolvedPython @auditArgs
exit $LASTEXITCODE
