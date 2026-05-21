[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8180,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\layout-smoke"
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$serverScript = Join-Path $root "layout_server.py"
$common = Join-Path $root "LayoutProbeCommon.ps1"
. $common

$pageUrl = "http://$Host`:$Port/load-complete-screenshot.html"
$outPng = Join-Path $root "load-complete-screenshot.png"
$browserOut = Join-Path $root "load-complete-screenshot.browser.stdout.txt"
$browserErr = Join-Path $root "load-complete-screenshot.browser.stderr.txt"
$serverOut = Join-Path $root "load-complete-screenshot.server.stdout.txt"
$serverErr = Join-Path $root "load-complete-screenshot.server.stderr.txt"
$profileRoot = Join-Path $root "profile-load-complete-screenshot"

Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Reset-ProfileRoot $profileRoot

$server = $null
$browser = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }
  if (-not (Test-Path -LiteralPath $serverScript)) { throw "layout smoke server script not found: $serverScript" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  if (-not (Wait-LightpandaHttpReady -Url $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds)) {
    throw "layout smoke server did not become ready"
  }

  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  $started = Get-Date
  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed",$pageUrl,"--window_width","420","--window_height","320","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  try {
    if (-not (Wait-Screenshot $outPng)) { throw "load-complete screenshot did not become ready" }
    $elapsedMs = [int]((Get-Date) - $started).TotalMilliseconds
    $red = Find-ColorBounds $outPng { param($c) $c.R -ge 180 -and $c.G -le 140 -and $c.B -le 140 }
    $result = [ordered]@{
      red = $red
      elapsed_ms = $elapsedMs
      slow_image_visible = ($red.width -ge 70) -and ($red.height -ge 24)
      waited_for_load = ($elapsedMs -ge 900)
    }
    $result.load_complete_screenshot_worked = $result.slow_image_visible -and $result.waited_for_load
    if (-not $result.load_complete_screenshot_worked) {
      throw "load-complete screenshot probe captured before slow load finished"
    }
    $result | ConvertTo-Json -Depth 6
  }
  finally {
    $null = Stop-LightpandaOwnedProbeProcess $browser
    for ($i = 0; $i -lt 20; $i++) {
      if (-not $browser -or -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue)) { break }
      Start-Sleep -Milliseconds 100
    }
  }
}
finally {
  $null = Stop-LightpandaOwnedProbeProcess $server
  for ($i = 0; $i -lt 20; $i++) {
    if (-not $server -or -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue)) { break }
    Start-Sleep -Milliseconds 100
  }
}
