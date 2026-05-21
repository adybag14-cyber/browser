[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8231,
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

$pageUrl = "http://$Host`:$Port/box-shadow.html"
$outPng = Join-Path $root "box-shadow.png"
$browserOut = Join-Path $root "box-shadow.browser.stdout.txt"
$browserErr = Join-Path $root "box-shadow.browser.stderr.txt"
$serverOut = Join-Path $root "box-shadow.server.stdout.txt"
$serverErr = Join-Path $root "box-shadow.server.stderr.txt"
$profileRoot = Join-Path $root "profile-box-shadow"

Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Reset-ProfileRoot $profileRoot

$server = $null
$browser = $null

$python = Resolve-LightpandaPythonCommand
$server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }
  if (-not (Test-Path -LiteralPath $serverScript)) { throw "layout smoke server script not found: $serverScript" }
  if (-not (Wait-LightpandaHttpReady -Url $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds)) { throw "box shadow smoke server did not become ready" }

  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed",$pageUrl,"--window_width","320","--window_height","220","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  try {
    if (-not (Wait-Screenshot $outPng)) { throw "box shadow screenshot did not become ready" }

    Add-Type -AssemblyName System.Drawing
    $bmp = [System.Drawing.Bitmap]::new($outPng)
    try {
      $shadowPixel = Read-Pixel $bmp 200 170
      $shadowEdgePixel = Read-Pixel $bmp 210 180

      $result = [ordered]@{
        shadow_pixel = $shadowPixel
        shadow_edge_pixel = $shadowEdgePixel
        shadow_pixel_dark = ($shadowPixel.r -lt 240 -and $shadowPixel.g -lt 240 -and $shadowPixel.b -lt 240)
        shadow_edge_dark = ($shadowEdgePixel.r -lt 240 -and $shadowEdgePixel.g -lt 240 -and $shadowEdgePixel.b -lt 240)
        shadow_visible = ($shadowPixel.r -lt 240 -and $shadowEdgePixel.r -lt 240)
      }
      $result.box_shadow_worked = $result.shadow_pixel_dark -and $result.shadow_visible
      if (-not $result.box_shadow_worked) {
        throw "box shadow probe did not observe the expected offset shadow"
      }
      $result | ConvertTo-Json -Depth 6
    }
    finally {
      $bmp.Dispose()
    }
  }
  finally {
    Stop-VerifiedProcess $browser.Id
    for ($i = 0; $i -lt 20; $i++) {
      if (-not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue)) { break }
      Start-Sleep -Milliseconds 100
    }
  }
}
finally {
  Stop-VerifiedProcess $server.Id
  for ($i = 0; $i -lt 20; $i++) {
    if (-not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue)) { break }
    Start-Sleep -Milliseconds 100
  }
}
