[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json,
    [switch]$AllowRawLauncher
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'HeadedValidationHelpers.ps1')

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$auditScriptPath = Join-Path $resolvedRepoRoot 'tmp-browser-smoke/attached-pages/issue3_replay_docs_launcher_audit.py'
if (-not (Test-Path -LiteralPath $auditScriptPath -PathType Leaf)) {
    throw "Replay-docs launcher audit script not found: $auditScriptPath"
}

$pythonArgs = [System.Collections.Generic.List[string]]::new()
$pythonArgs.Add($auditScriptPath)
$pythonArgs.Add('--repo-root')
$pythonArgs.Add($resolvedRepoRoot)
$pythonArgs.Add('--require-wrapper-sidecar')
$pythonArgs.Add('--require-google-wrapper-sidecar')
$pythonArgs.Add('--require-launcher-companion')
$pythonArgs.Add('--require-launcher-companion-surface-check')

if ($AllowRawLauncher) {
    $pythonArgs.Add('--allow-raw-launcher')
}
if ($Json) {
    $pythonArgs.Add('--json')
}

& python @pythonArgs
exit $LASTEXITCODE
