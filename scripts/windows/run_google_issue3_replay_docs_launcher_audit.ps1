[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json,
    [switch]$AllowRawLauncher,
    [switch]$RequireWrapperSidecar,
    [switch]$RequireGoogleWrapperSidecar,
    [switch]$RequireLauncherCompanion,
    [switch]$RequireLauncherCompanionSurfaceCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'HeadedValidationHelpers.ps1')

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$auditScript = Join-Path $resolvedRepoRoot 'tmp-browser-smoke/attached-pages/issue3_replay_docs_launcher_audit.py'
if (-not (Test-Path -LiteralPath $auditScript -PathType Leaf)) {
    throw "Replay-doc launcher audit not found: $auditScript"
}

$arguments = [System.Collections.Generic.List[string]]::new()
$arguments.Add($auditScript)
$arguments.Add('--repo-root')
$arguments.Add($resolvedRepoRoot)

if ($Json) {
    $arguments.Add('--json')
}
if ($AllowRawLauncher) {
    $arguments.Add('--allow-raw-launcher')
}
if ($RequireWrapperSidecar) {
    $arguments.Add('--require-wrapper-sidecar')
}
if ($RequireGoogleWrapperSidecar) {
    $arguments.Add('--require-google-wrapper-sidecar')
}
if ($RequireLauncherCompanion) {
    $arguments.Add('--require-launcher-companion')
}
if ($RequireLauncherCompanionSurfaceCheck) {
    $arguments.Add('--require-launcher-companion-surface-check')
}

& python @arguments
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
