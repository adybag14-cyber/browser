[CmdletBinding()]
param(
  [string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
  $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$requiredFiles = @(
  "tmp-browser-smoke\common\ProbeRuntime.ps1",
  "tmp-browser-smoke\canvas-smoke\canvas_server.py",
  "tmp-browser-smoke\canvas-smoke\chrome-canvas-render-probe.ps1",
  "tmp-browser-smoke\canvas-smoke\chrome-canvas-text-probe.ps1",
  "tmp-browser-smoke\canvas-smoke\chrome-canvas-drawimage-checkout-probe.ps1",
  "tmp-browser-smoke\canvas-smoke\chrome-canvas-webgl-clear-probe.ps1",
  "scripts\windows\show_canvas_validation_flow.ps1",
  "scripts\windows\run_canvas_validation.ps1"
)

$missing = @()
foreach ($relativePath in $requiredFiles) {
  $fullPath = Join-Path $RepoRoot $relativePath
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    $missing += $relativePath
  }
}

$result = [ordered]@{
  repo_root = $RepoRoot
  checked = $requiredFiles
  missing = $missing
  ready = ($missing.Count -eq 0)
}

if (-not $result.ready) {
  $result | ConvertTo-Json -Depth 4
  throw "Canvas validation surface is incomplete."
}

$result | ConvertTo-Json -Depth 4
