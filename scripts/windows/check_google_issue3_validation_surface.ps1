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
  "tmp-browser-smoke\google-investigation-next\GoogleProbeCommon.ps1",
  "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1",
  "src\browser\tests\page\google_home_title_probe.html",
  "scripts\windows\watch_headed_probe.ps1",
  "scripts\windows\show_headed_validation_suites.ps1",
  "docs\ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
  "docs\ISSUE3_RUNTIME_REENTRY_GATES.md",
  "scripts\windows\check_google_issue3_validation_surface.ps1",
  "scripts\windows\run_google_issue3_validation.ps1"
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
  throw "Google issue #3 validation surface is incomplete."
}

$result | ConvertTo-Json -Depth 4
