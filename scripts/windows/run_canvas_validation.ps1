[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$RenderPort = 8166,
  [int]$DrawImagePort = 8167,
  [int]$TextPort = 8332,
  [int]$WebGlClearPort = 8170,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$ScreenshotReadyAttempts = 80,
  [int]$PollMilliseconds = 250,
  [switch]$SkipWebGlClear
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

$surfaceCheck = Join-Path $scriptRoot "check_canvas_validation_surface.ps1"
$renderProbe = Join-Path $RepoRoot "tmp-browser-smoke\canvas-smoke\chrome-canvas-render-probe.ps1"
$textProbe = Join-Path $RepoRoot "tmp-browser-smoke\canvas-smoke\chrome-canvas-text-probe.ps1"
$drawImageProbe = Join-Path $RepoRoot "tmp-browser-smoke\canvas-smoke\chrome-canvas-drawimage-checkout-probe.ps1"
$webGlClearProbe = Join-Path $RepoRoot "tmp-browser-smoke\canvas-smoke\chrome-canvas-webgl-clear-probe.ps1"

if (-not (Test-Path -LiteralPath $surfaceCheck -PathType Leaf)) {
  throw "Canvas validation surface checker not found: $surfaceCheck"
}
if (-not (Test-Path -LiteralPath $renderProbe -PathType Leaf)) {
  throw "Canvas render probe not found: $renderProbe"
}
if (-not (Test-Path -LiteralPath $textProbe -PathType Leaf)) {
  throw "Canvas text probe not found: $textProbe"
}
if (-not (Test-Path -LiteralPath $drawImageProbe -PathType Leaf)) {
  throw "Checkout-portable canvas drawImage probe not found: $drawImageProbe"
}
if ((-not $SkipWebGlClear) -and (-not (Test-Path -LiteralPath $webGlClearProbe -PathType Leaf))) {
  throw "Canvas WebGL clear probe not found: $webGlClearProbe"
}

$sharedArgs = @{
  RepoRoot = $RepoRoot
  BrowserExe = $BrowserExe
  Host = $Host
  ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
  ScreenshotReadyAttempts = $ScreenshotReadyAttempts
  PollMilliseconds = $PollMilliseconds
}

Write-Host "Canvas headed validation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Host: {0}" -f $Host)
Write-Host ("Render port: {0}" -f $RenderPort)
Write-Host ("Text port: {0}" -f $TextPort)
Write-Host ("DrawImage port: {0}" -f $DrawImagePort)
if (-not $SkipWebGlClear) {
  Write-Host ("WebGL clear port: {0}" -f $WebGlClearPort)
}
Write-Host ""

Write-Host "=== canvas-validation-surface ==="
Write-Host ("Script: {0}" -f $surfaceCheck)
& $surfaceCheck -RepoRoot $RepoRoot

Write-Host ""
Write-Host "=== canvas-render ==="
Write-Host ("Script: {0}" -f $renderProbe)
& $renderProbe @sharedArgs -Port $RenderPort

Write-Host ""
Write-Host "=== canvas-text ==="
Write-Host ("Script: {0}" -f $textProbe)
& $textProbe @sharedArgs -Port $TextPort

Write-Host ""
Write-Host "=== canvas-drawimage ==="
Write-Host ("Script: {0}" -f $drawImageProbe)
& $drawImageProbe @sharedArgs -Port $DrawImagePort

if (-not $SkipWebGlClear) {
  Write-Host ""
  Write-Host "=== canvas-webgl-clear ==="
  Write-Host ("Script: {0}" -f $webGlClearProbe)
  & $webGlClearProbe @sharedArgs -Port $WebGlClearPort
}

Write-Host ""
Write-Host "Next: if the bounded canvas render, text, drawImage, and optional WebGL clear probes stay green, widen into scripts\windows\show_headed_validation_suites.ps1 -ChangeArea rendering for broader headed rendering follow-up."
