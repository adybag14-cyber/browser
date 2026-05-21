[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8177,
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

$pageUrl = "http://$Host`:$Port/flex-center.html"
$outPng = Join-Path $root "flex-center.png"
$browserOut = Join-Path $root "flex-center.browser.stdout.txt"
$browserErr = Join-Path $root "flex-center.browser.stderr.txt"
$serverOut = Join-Path $root "flex-center.server.stdout.txt"
$serverErr = Join-Path $root "flex-center.server.stderr.txt"
$profileRoot = Join-Path $root "profile-flex-center"

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
  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed",$pageUrl,"--window_width","960","--window_height","720","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  try {
    if (-not (Wait-Screenshot $outPng)) { throw "flex center screenshot did not become ready" }
    $red = Find-ColorBounds $outPng { param($c) $c.R -ge 180 -and $c.G -le 90 -and $c.B -le 90 }
    $blue = Find-ColorBounds $outPng { param($c) $c.B -ge 180 -and $c.R -le 90 -and $c.G -le 150 }
    $redCenterX = ($red.left + $red.right) / 2.0
    $blueCenterX = ($blue.left + $blue.right) / 2.0
    $redCenterY = ($red.top + $red.bottom) / 2.0
    $blueCenterY = ($blue.top + $blue.bottom) / 2.0
    $result = [ordered]@{
      red = $red
      blue = $blue
      red_center_x = $redCenterX
      blue_center_x = $blueCenterX
      red_center_y = $redCenterY
      blue_center_y = $blueCenterY
      centered_horizontally = ([math]::Abs($redCenterX - $blueCenterX) -le 12)
      vertically_stacked = ($blue.top -gt $red.bottom)
    }
    $result.layout_probe_worked = $result.centered_horizontally -and $result.vertically_stacked
    if (-not $result.layout_probe_worked) {
      throw "flex layout probe did not keep items centered and vertically stacked"
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