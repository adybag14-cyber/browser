[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
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
    throw "Replay-doc launcher audit script not found: $auditScript"
}

$pythonArgs = [System.Collections.Generic.List[string]]::new()
$pythonArgs.Add($auditScript)
$pythonArgs.Add('--repo-root')
$pythonArgs.Add($resolvedRepoRoot)
$pythonArgs.Add('--require-wrapper-sidecar')
$pythonArgs.Add('--require-google-wrapper-sidecar')
$pythonArgs.Add('--require-launcher-companion')
$pythonArgs.Add('--require-launcher-companion-surface-check')
if ($Json) {
    $pythonArgs.Add('--json')
}

if (-not $Json) {
    Write-Host 'Google issue #3 replay-doc launcher surface check'
    Write-Host ''
    Write-Host (("Repo root: {0}") -f $resolvedRepoRoot)
    Write-Host (("Audit script: {0}") -f $auditScript)
    Write-Host ''
}

& python @pythonArgs
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    if (-not $Json) {
        Write-Host ''
        Write-Host 'Issue #3 replay-doc launcher surface is intact.'
    }
    exit 0
}

if (-not $Json) {
    Write-Host ''
    Write-Host 'Replay-doc launcher audit failed. Repair raw Python replay-note launcher references or missing wrapper-backed sidecar and launcher-companion surfacing before trusting the issue #3 replay docs.'
}

exit $exitCode
