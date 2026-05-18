[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8166,
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
$pageUrl = "http://$Host`:$Port/index.html"
$outPng = Join-Path $root "canvas-render.png"
$browserOut = Join-Path $root "canvas-render.browser.stdout.txt"
$browserErr = Join-Path $root "canvas-render.browser.stderr.txt"
$serverOut = Join-Path $root "canvas-render.server.stdout.txt"
$serverErr = Join-Path $root "canvas-render.server.stderr.txt"
$profileRoot = Join-Path $root "profile-canvas-render"
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
  throw "canvas smoke server script not found: $serverScript"
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
        $border = Read-Pixel $bmp ($minX + 20) $minY
        $fill = Read-Pixel $bmp ($minX + 12) ($minY + 12)
        $clear = Read-Pixel $bmp ($minX + 90) ($minY + 60)
        return [ordered]@{
          left = $minX
          top = $minY
          right = $maxX
          bottom = $maxY
          width = $maxX - $minX + 1
          height = $maxY - $minY + 1
          border = $border
          fill = $fill
          clear = $clear
          size_worked = (($maxX - $minX + 1) -eq 120) -and (($maxY - $minY + 1) -eq 80)
          border_worked = Test-ApproxColor $border 0 0 255 40
          fill_worked = Test-ApproxColor $fill 255 128 128 24
          clear_worked = Test-ApproxColor $clear 255 255 255 8
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
$server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, "$Port")) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr

try {
  $ready = Wait-LightpandaHttpReady -Url $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "canvas smoke server did not become ready" }

  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse",$pageUrl,"--window_width","420","--window_height","360","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  try {
    $pngReady = Wait-LightpandaFileReady -Path $outPng -Attempts $ScreenshotReadyAttempts -PollMilliseconds $PollMilliseconds
    if (-not $pngReady) { throw "canvas screenshot did not become ready" }

    $bounds = Find-BlueBounds $outPng
    $bounds["ready"] = $ready
    $bounds["screenshot_length"] = (Get-Item $outPng).Length
    $bounds["canvas_worked"] = $bounds.size_worked -and $bounds.border_worked -and $bounds.fill_worked -and $bounds.clear_worked
    if (-not $bounds.canvas_worked) {
      throw "canvas smoke probe did not observe expected border/fill/clear pixels"
    }
    $bounds | ConvertTo-Json -Depth 6
  }
  finally {
    if ($browser) {
      [void](Stop-LightpandaOwnedProbeProcess $browser)
      for ($i = 0; $i -lt 20; $i++) {
        if (-not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue)) { break }
        Start-Sleep -Milliseconds 100
      }
    }
  }
}
finally {
  if ($server) {
    [void](Stop-LightpandaOwnedProbeProcess $server)
    for ($i = 0; $i -lt 20; $i++) {
      if (-not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue)) { break }
      Start-Sleep -Milliseconds 100
    }
  }
}