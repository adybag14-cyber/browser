[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8332,
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
$pageUrl = "http://$Host`:$Port/text.html"
$outPng = Join-Path $root "canvas-text.png"
$browserOut = Join-Path $root "canvas-text.browser.stdout.txt"
$browserErr = Join-Path $root "canvas-text.browser.stderr.txt"
$serverOut = Join-Path $root "canvas-text.server.stdout.txt"
$serverErr = Join-Path $root "canvas-text.server.stderr.txt"
$profileRoot = Join-Path $root "profile-canvas-text"
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
  throw "canvas text server script not found: $serverScript"
}

@"
lightpanda-browse-settings-v1
restore_previous_session	0
allow_script_popups	0
default_zoom_percent	100
homepage_url	
"@ | Set-Content -Path (Join-Path $appDataRoot "browse-settings-v1.txt") -NoNewline

function Count-TextPixels($Path) {
  Add-Type -AssemblyName System.Drawing
  $bmp = [System.Drawing.Bitmap]::new($Path)
  try {
    $red = 0
    $blue = 0
    for ($y = 0; $y -lt $bmp.Height; $y++) {
      for ($x = 0; $x -lt $bmp.Width; $x++) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.R -gt 160 -and $c.G -lt 90 -and $c.B -lt 90) { $red++ }
        if ($c.R -lt 90 -and $c.G -lt 90 -and $c.B -gt 120) { $blue++ }
      }
    }
    return [ordered]@{
      red_pixels = $red
      blue_pixels = $blue
      text_worked = ($red -gt 40) -and ($blue -gt 40)
    }
  }
  finally {
    $bmp.Dispose()
  }
}

$python = Resolve-LightpandaPythonCommand
$server = $null
$browser = $null

try {
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, "$Port")) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "canvas text server did not become ready" }

  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$pageUrl,"--window_width","480","--window_height","360","--screenshot_png",$outPng) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  try {
    $pngReady = Wait-LightpandaFileReady -Path $outPng -Attempts $ScreenshotReadyAttempts -PollMilliseconds $PollMilliseconds
    if (-not $pngReady) { throw "canvas text screenshot did not become ready" }

    $counts = Count-TextPixels $outPng
    $counts["repo_root"] = $repo
    $counts["browser_exe"] = $browserExe
    $counts["host"] = $Host
    $counts["port"] = $Port
    $counts["page_url"] = $pageUrl
    $counts["ready"] = $ready
    $counts["screenshot_length"] = (Get-Item $outPng).Length
    if (-not $counts.text_worked) {
      throw "canvas text probe did not observe expected screenshot pixels"
    }
    $counts | ConvertTo-Json -Depth 6
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
