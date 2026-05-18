[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = '127.0.0.1',
  [int]$Port = 8425,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$ScreenshotReadyAttempts = 80,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path (Split-Path $PSScriptRoot -Parent) 'common\ProbeRuntime.ps1')

$root = $PSScriptRoot
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $root }
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$serverScript = Join-Path $root 'canvas_server.py'
$pageUrl = "http://$Host`:$Port/webgl-dimensions.html"
$outPng = Join-Path $root 'canvas-webgl-dimensions.png'
$browserOut = Join-Path $root 'canvas-webgl-dimensions.browser.stdout.txt'
$browserErr = Join-Path $root 'canvas-webgl-dimensions.browser.stderr.txt'
$serverOut = Join-Path $root 'canvas-webgl-dimensions.server.stdout.txt'
$serverErr = Join-Path $root 'canvas-webgl-dimensions.server.stderr.txt'
$profileRoot = Join-Path $root 'profile-canvas-webgl-dimensions'
$appDataRoot = Join-Path $profileRoot 'lightpanda'

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
"@ | Set-Content -Path (Join-Path $appDataRoot 'browse-settings-v1.txt') -NoNewline

$server = $null
$browser = $null
$failure = $null

try {
  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, "$Port")) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw 'canvas webgl dimensions server did not become ready' }

  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  $browser = Start-Process -FilePath $browserExe -ArgumentList @('browse', '--browser_mode', 'headed', '--window_width', '420', '--window_height', '360', '--screenshot_png', $outPng, $pageUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  $titleReady = $false
  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0 -and $proc.MainWindowTitle -like '*Canvas WebGL Dimensions Ready*') {
      $titleReady = $true
      break
    }
  }
  if (-not $titleReady) { throw 'webgl dimensions page did not reach the ready title' }

  $pngReady = Wait-LightpandaFileReady -Path $outPng -Attempts $ScreenshotReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $pngReady) { throw 'canvas webgl dimensions screenshot did not become ready' }

  Add-Type -AssemblyName System.Drawing
  $bmp = [System.Drawing.Bitmap]::new($outPng)
  try {
    $minX = $bmp.Width
    $minY = $bmp.Height
    $maxX = -1
    $maxY = -1
    $count = 0
    for ($y = 0; $y -lt $bmp.Height; $y++) {
      for ($x = 0; $x -lt $bmp.Width; $x++) {
        $c = $bmp.GetPixel($x, $y)
        if (([math]::Abs($c.R - 0) -le 20) -and ([math]::Abs($c.G - 128) -le 20) -and ([math]::Abs($c.B - 255) -le 20)) {
          $count++
          if ($x -lt $minX) { $minX = $x }
          if ($y -lt $minY) { $minY = $y }
          if ($x -gt $maxX) { $maxX = $x }
          if ($y -gt $maxY) { $maxY = $y }
        }
      }
    }
    if ($count -le 0) { throw 'webgl dimensions clear color not found in screenshot' }

    $width = $maxX - $minX + 1
    $height = $maxY - $minY + 1
    $result = [ordered]@{
      repo_root = $repo
      browser_exe = $browserExe
      ready = $ready
      title_ready = $titleReady
      count = $count
      width = $width
      height = $height
      size_worked = ($width -ge 60) -and ($height -eq 50)
      webgl_dimensions_worked = $titleReady -and ($width -ge 60) -and ($height -eq 50)
    }
    if (-not $result.webgl_dimensions_worked) { throw 'webgl dimensions region not observed at expected size' }
    $result | ConvertTo-Json -Depth 5
  } finally {
    $bmp.Dispose()
  }
} catch {
  $failure = $_.Exception.Message
} finally {
  [void](Stop-LightpandaOwnedProbeProcess $browser)
  [void](Stop-LightpandaOwnedProbeProcess $server)
}

if ($failure) {
  throw $failure
}
