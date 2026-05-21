[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8154,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "tabs\TabProbeCommon.ps1")

$repo = if ([string]::IsNullOrWhiteSpace($RepoRoot)) { Resolve-LightpandaRepoRoot $PSScriptRoot } else { $RepoRoot }
$root = Join-Path $repo "tmp-browser-smoke\downloads"
$profileRoot = Join-Path $root "profile-download"
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$pageUrl = "http://$Host`:$Port/index.html"
$initialPng = Join-Path $root "chrome-download.initial.png"
$browserOut = Join-Path $root "chrome-download.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-download.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-download.server.stdout.txt"
$serverErr = Join-Path $root "chrome-download.server.stderr.txt"

Remove-Item $initialPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Remove-Item $profileRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $profileRoot -Force | Out-Null

Add-Type -AssemblyName System.Drawing

function Get-ColorBounds([System.Drawing.Bitmap]$Bitmap, [scriptblock]$Matcher) {
  $bounds = [ordered]@{min_x=$null; min_y=$null; max_x=$null; max_y=$null; count=0}
  for ($y = 0; $y -lt $Bitmap.Height; $y++) {
    for ($x = 0; $x -lt $Bitmap.Width; $x++) {
      $c = $Bitmap.GetPixel($x, $y)
      if (& $Matcher $c) {
        if ($null -eq $bounds.min_x -or $x -lt $bounds.min_x) { $bounds.min_x = $x }
        if ($null -eq $bounds.min_y -or $y -lt $bounds.min_y) { $bounds.min_y = $y }
        if ($null -eq $bounds.max_x -or $x -gt $bounds.max_x) { $bounds.max_x = $x }
        if ($null -eq $bounds.max_y -or $y -gt $bounds.max_y) { $bounds.max_y = $y }
        $bounds.count++
      }
    }
  }
  return $bounds
}

function Wait-FileExists([string]$Path, [int]$Attempts = 60, [int]$DelayMs = 200) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $DelayMs
    if ((Test-Path $Path) -and ((Get-Item $Path).Length -gt 0)) {
      return $true
    }
  }
  return $false
}

$env:APPDATA = $profileRoot
$env:LOCALAPPDATA = $profileRoot
$env:LIGHTPANDA_BARE_METAL_INPUT = Join-Path $profileRoot "lightpanda\bare-metal-input-v1.txt"
$downloadsDir = Join-Path $profileRoot "lightpanda\downloads"
$downloadsFile = Join-Path $profileRoot "lightpanda\downloads-v1.txt"
$downloadedFile = Join-Path $downloadsDir "example-download.txt"

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$downloadWorked = $false
$metadataWorked = $false
$failure = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind",$Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "download probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$pageUrl,"--window_width","960","--window_height","640","--screenshot_png",$initialPng) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd -eq [IntPtr]::Zero) { throw "download probe window handle not found" }
  $null = Wait-TabTitle -ProcessId $browser.Id -Needle "Download Smoke" -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds

  $pngReady = Wait-LightpandaFileReady -Path $initialPng -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $pngReady) { throw "download probe screenshot did not become ready" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250

  $bmp = [System.Drawing.Bitmap]::new($initialPng)
  try {
    $blue = Get-ColorBounds $bmp { param($c) $c.B -ge 150 -and $c.R -le 90 -and $c.G -le 120 }
  } finally {
    $bmp.Dispose()
  }
  if ($null -eq $blue.min_x) { throw "download probe could not find link bounds" }

  $linkX = [int][Math]::Floor(($blue.min_x + $blue.max_x) / 2)
  $linkY = [int][Math]::Floor(($blue.min_y + $blue.max_y) / 2)
  [void](Invoke-SmokeClientClick $hwnd $linkX $linkY)

  $downloadWorked = Wait-FileExists $downloadedFile
  if (-not $downloadWorked) { throw "downloaded file was not created" }

  $metadataWorked = Wait-FileExists $downloadsFile
  if (-not $metadataWorked) { throw "downloads state file was not created" }

  $content = Get-Content $downloadedFile -Raw
  if ($content -ne "download smoke payload`n" -and $content -ne "download smoke payload") {
    throw "downloaded file content mismatch"
  }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = if ($server) { Stop-OwnedProbeProcess $server } else { $null }
  $browserMeta = if ($browser) { Stop-OwnedProbeProcess $browser } else { $null }
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    host = $Host
    port = $Port
    page_url = $pageUrl
    server_ready_timeout_seconds = $ServerReadyTimeoutSeconds
    window_ready_attempts = $WindowReadyAttempts
    poll_milliseconds = $PollMilliseconds
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    download_worked = $downloadWorked
    metadata_worked = $metadataWorked
    downloaded_file = $downloadedFile
    downloads_file = $downloadsFile
    error = $failure
    server_meta = $serverMeta
    browser_meta = $browserMeta
    browser_gone = $browserGone
    server_gone = $serverGone
  } | ConvertTo-Json -Depth 7
}

if ($failure) {
  exit 1
}
