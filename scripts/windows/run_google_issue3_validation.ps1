[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$InputText = "n",
  [int]$Port = 9582,
  [int]$TimeoutSeconds = 90,
  [int]$PollMilliseconds = 250,
  [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = $PSScriptRoot
if (-not $RepoRoot) {
  $RepoRoot = (Resolve-Path (Join-Path $scriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
  $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

$surfaceCheck = Join-Path $scriptRoot "check_google_issue3_validation_surface.ps1"
$probe = Join-Path $RepoRoot "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1"

if (-not (Test-Path -LiteralPath $surfaceCheck -PathType Leaf)) {
  throw "Google issue #3 validation surface checker not found: $surfaceCheck"
}
if (-not (Test-Path -LiteralPath $probe -PathType Leaf)) {
  throw "Google issue #3 title probe not found: $probe"
}

Write-Host "Issue #3 reduced Google headed validation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Browser exe: {0}" -f $BrowserExe)
Write-Host ("Port: {0}" -f $Port)
Write-Host ("Input text: {0}" -f $InputText)
Write-Host ""

Write-Host "=== google-issue3-validation-surface ==="
Write-Host ("Script: {0}" -f $surfaceCheck)
& $surfaceCheck -RepoRoot $RepoRoot

Write-Host ""
Write-Host "=== google-home-title-probe ==="
Write-Host ("Script: {0}" -f $probe)
& $probe `
  -RepoRoot $RepoRoot `
  -BrowserExe $BrowserExe `
  -InputText $InputText `
  -Port $Port `
  -TimeoutSeconds $TimeoutSeconds `
  -PollMilliseconds $PollMilliseconds `
  -LeaveOpen:$LeaveOpen

Write-Host ""
Write-Host "Next: if the reduced Google title probe stays green, widen into scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-shared-enter-order and scripts\windows\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order before retrying the direct Page.zig and win32_backend.zig runtime patch."
