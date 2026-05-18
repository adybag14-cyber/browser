[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = '127.0.0.1',
  [int]$Port = 0,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$ScreenshotReadyAttempts = 80,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path (Split-Path $PSScriptRoot -Parent) 'common\ProbeRuntime.ps1')

function Get-FreePort {
  $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
  $listener.Start()
  try { return ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port } finally { $listener.Stop() }
}

$root = $PSScriptRoot
$repo = if ([string]::IsNullOrWhiteSpace($RepoRoot)) { Resolve-LightpandaRepoRoot $root } else { $RepoRoot }
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$serverScript = Join-Path $root 'canvas_server.py'
$port = if ($Port -gt 0) { $Port } else { Get-FreePort }
$pageUrl = "http://$Host`:$port/webgl-indexed.html"
$outPng = Join-Path $root 'canvas-webgl-indexed.png'
$browserOut = Join-Path $root 'canvas-webgl-indexed.browser.stdout.txt'
$browserErr = Join-Path $root 'canvas-webgl-indexed.browser.stderr.txt'
$serverOut = Join-Path $root 'canvas-webgl-indexed.server.stdout.txt'
$serverErr = Join-Path $root 'canvas-webgl-indexed.server.stderr.txt'
$profileRoot = Join-Path $root 'profile-canvas-webgl-indexed'
$appDataRoot = Join-Path $profileRoot 'lightpanda'

Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath $profileRoot) {
  Remove-Item -LiteralPath $profileRoot -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Force -Path $appDataRoot | Out-Null
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
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }
  if (-not (Test-Path -LiteralPath $serverScript)) { throw "canvas smoke server script not found: $serverScript" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $port)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw 'canvas webgl indexed server did not become ready' }

  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  $browser = Start-Process -FilePath $browserExe -ArgumentList @('browse', '--browser_mode', 'headed', '--window_width', '420', '--window_height', '360', '--screenshot_png', $outPng, $pageUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  $titleReady = $false
  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0 -and $proc.MainWindowTitle -like '*Canvas WebGL Indexed Ready*') {
      $titleReady = $true
      break
    }
  }
  if (-not $titleReady) { throw 'webgl indexed page did not reach the ready title' }

  $pngReady = Wait-LightpandaFileReady -Path $outPng -Attempts $ScreenshotReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $pngReady) { throw 'canvas webgl indexed screenshot did not become ready' }

  Add-Type -AssemblyName System.Drawing
  $bmp = [System.Drawing.Bitmap]::new($outPng)
  try {
    $blueCount = 0
    $whiteCount = 0
    for ($y = 0; $y -lt $bmp.Height; $y++) {
      for ($x = 0; $x -lt $bmp.Width; $x++) {
        $c = $bmp.GetPixel($x, $y)
        if (($c.R -le 40) -and ($c.G -le 40) -and ([math]::Abs($c.B - 255) -le 20)) { $blueCount++ }
        if (([math]::Abs($c.R - 255) -le 20) -and ([math]::Abs($c.G - 255) -le 20) -and ([math]::Abs($c.B - 255) -le 20)) { $whiteCount++ }
      }
    }
    $result = [ordered]@{
      repo_root = $repo
      browser_exe = $browserExe
      ready = $ready
      title_ready = $titleReady
      blue_count = $blueCount
      white_count = $whiteCount
      indexed_worked = $titleReady -and ($blueCount -gt 200) -and ($whiteCount -gt 2000)
    }
    if (-not $result.indexed_worked) { throw 'webgl indexed pixels were not observed in screenshot' }
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
