[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8167,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$ScreenshotReadyAttempts = 80,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")

$root = $PSScriptRoot
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $root }
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$serverScript = Join-Path $root "canvas_server.py"
$pageUrl = "http://$Host`:$Port/drawimage.html"
$outPng = Join-Path $root "canvas-drawimage-checkout.png"
$browserOut = Join-Path $root "canvas-drawimage-checkout.browser.stdout.txt"
$browserErr = Join-Path $root "canvas-drawimage-checkout.browser.stderr.txt"
$serverOut = Join-Path $root "canvas-drawimage-checkout.server.stdout.txt"
$serverErr = Join-Path $root "canvas-drawimage-checkout.server.stderr.txt"
$profileRoot = Join-Path $root "profile-canvas-drawimage-checkout"
$appDataRoot = Join-Path $profileRoot "lightpanda"

Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath $profileRoot) {
  Remove-Item -LiteralPath $profileRoot -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Force -Path $appDataRoot | Out-Null

if (-not (Test-Path -LiteralPath $browserExe)) {
  throw "headed browser binary not found: $browserExe"
}
if (-not (Test-Path -LiteralPath $serverScript)) {
  throw "canvas drawImage server script not found: $serverScript"
}

@"
lightpanda-browse-settings-v1
restore_previous_session	0
allow_script_popups	0
default_zoom_percent	100
homepage_url	
"@ | Set-Content -Path (Join-Path $appDataRoot "browse-settings-v1.txt") -NoNewline

function Read-Pixel($Bitmap, [int]$X, [int]$Y) {
  $c = $Bitmap.GetPixel($X, $Y)
  return [ordered]@{
    r = [int]$c.R
    g = [int]$c.G
    b = [int]$c.B
    a = [int]$c.A
  }
}

function Test-ApproxColor($Pixel, [int]$R, [int]$G, [int]$B, [int]$Tolerance) {
  return ([math]::Abs($Pixel.r - $R) -le $Tolerance) -and
         ([math]::Abs($Pixel.g - $G) -le $Tolerance) -and
         ([math]::Abs($Pixel.b - $B) -le $Tolerance)
}

function Find-BlueBounds($Path) {
  Add-Type -AssemblyName System.Drawing
  for ($attempt = 0; $attempt -lt 20; $attempt++) {
    try {
      $bmp = [System.Drawing.Bitmap]::new($Path)
      try {
        $minX = $bmp.Width
        $minY = $bmp.Height
        $maxX = -1
        $maxY = -1
        for ($y = 0; $y -lt $bmp.Height; $y++) {
          for ($x = 0; $x -lt $bmp.Width; $x++) {
            $c = $bmp.GetPixel($x, $y)
            if ($c.B -ge 220 -and $c.R -le 40 -and $c.G -le 40) {
              if ($x -lt $minX) { $minX = $x }
              if ($y -lt $minY) { $minY = $y }
              if ($x -gt $maxX) { $maxX = $x }
              if ($y -gt $maxY) { $maxY = $y }
            }
          }
        }
        if ($maxX -lt 0 -or $maxY -lt 0) {
          throw "blue border not found in $Path"
        }
        $red = Read-Pixel $bmp ($minX + 12) ($minY + 12)
        $blue = Read-Pixel $bmp ($minX + 45) ($minY + 15)
        $green = Read-Pixel $bmp ($minX + 75) ($minY + 25)
        return [ordered]@{
          left = $minX
          top = $minY
          right = $maxX
          bottom = $maxY
          width = $maxX - $minX + 1
          height = $maxY - $minY + 1
          red = $red
          blue = $blue
          green = $green
          size_worked = (($maxX - $minX + 1) -eq 120) -and (($maxY - $minY + 1) -eq 80)
          red_worked = Test-ApproxColor $red 255 0 0 24
          blue_worked = Test-ApproxColor $blue 0 0 255 24
          green_worked = Test-ApproxColor $green 0 255 0 24
        }
      }
      finally {
        $bmp.Dispose()
      }
    } catch {
      if ($attempt -eq 19) { throw }
      Start-Sleep -Milliseconds 200
    }
  }
}

$python = Resolve-LightpandaPythonCommand
$server = $null
$browser = $null

try {
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, "$Port")) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "canvas drawImage smoke server did not become ready" }

  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$pageUrl,"--window_width","420","--window_height","360","--screenshot_png",$outPng) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  try {
    $pngReady = Wait-LightpandaFileReady -Path $outPng -Attempts $ScreenshotReadyAttempts -PollMilliseconds $PollMilliseconds
    if (-not $pngReady) { throw "canvas drawImage screenshot did not become ready" }

    $bounds = Find-BlueBounds $outPng
    $bounds["repo_root"] = $repo
    $bounds["browser_exe"] = $browserExe
    $bounds["host"] = $Host
    $bounds["port"] = $Port
    $bounds["page_url"] = $pageUrl
    $bounds["ready"] = $ready
    $bounds["screenshot_length"] = (Get-Item $outPng).Length
    $bounds["drawimage_worked"] = $bounds.size_worked -and $bounds.red_worked -and $bounds.blue_worked -and $bounds.green_worked
    if (-not $bounds.drawimage_worked) {
      throw "canvas drawImage probe did not observe expected copied pixels"
    }
    $bounds | ConvertTo-Json -Depth 6
  }
  finally {
    [void](Stop-LightpandaOwnedProbeProcess $browser)
    for ($i = 0; $i -lt 20; $i++) {
      if (-not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue)) { break }
      Start-Sleep -Milliseconds 100
    }
  }
}
finally {
  [void](Stop-LightpandaOwnedProbeProcess $server)
  for ($i = 0; $i -lt 20; $i++) {
    if (-not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue)) { break }
    Start-Sleep -Milliseconds 100
  }
}
