[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [int]$Port = 8159,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$ScreenshotReadyAttempts = 80,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\\ProbeRuntime.ps1")

$repo = if ([string]::IsNullOrWhiteSpace($RepoRoot)) { Resolve-LightpandaRepoRoot $PSScriptRoot } else { $RepoRoot }
$root = Join-Path $repo "tmp-browser-smoke\\image-smoke"
$profileRoot = Join-Path $root "profile-http-runtime-script-auth"
$appDataRoot = Join-Path $profileRoot "lightpanda"
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$serverScript = Join-Path $root "http_runtime_server.py"
$outPng = Join-Path $root "http-runtime-script-auth.png"
$browserOut = Join-Path $root "http-runtime-script-auth.browser.stdout.txt"
$browserErr = Join-Path $root "http-runtime-script-auth.browser.stderr.txt"
$serverOut = Join-Path $root "http-runtime-script-auth.server.stdout.txt"
$serverErr = Join-Path $root "http-runtime-script-auth.server.stderr.txt"
$requestLog = Join-Path $root "http-runtime.requests.jsonl"
$pageUrl = "http://img%20user:p%40ss@127.0.0.1:$Port/auth-script-page.html"
$readyUrl = "http://127.0.0.1:$Port/auth-script-page.html"

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$analysis = $null
$failure = $null
$scriptEntries = @()
$beaconEntries = @()
$lastScript = $null
$lastBeacon = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }
  if (-not (Test-Path -LiteralPath $serverScript)) { throw "image smoke server script not found: $serverScript" }

  Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr,$requestLog -Force -ErrorAction SilentlyContinue
  cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
  New-Item -ItemType Directory -Force -Path $appDataRoot | Out-Null
  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  @"
lightpanda-browse-settings-v1
restore_previous_session	0
allow_script_popups	0
default_zoom_percent	100
homepage_url	
"@ | Set-Content -Path (Join-Path $appDataRoot "browse-settings-v1.txt") -NoNewline

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, "$Port")) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url $readyUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "localhost script auth server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", $pageUrl, "--screenshot_png", $outPng) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-LightpandaFileReady -Path $outPng -Attempts $ScreenshotReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $pngReady) { throw "script auth screenshot did not become ready" }

  Add-Type -AssemblyName System.Drawing
  $bmp = [System.Drawing.Bitmap]::new($outPng)
  try {
    $greenCount = 0
    for ($y = 0; $y -lt $bmp.Height; $y++) {
      for ($x = 0; $x -lt $bmp.Width; $x++) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.G -ge 150 -and $c.R -le 80 -and $c.B -le 120) {
          $greenCount++
        }
      }
    }
    $analysis = [ordered]@{
      width = $bmp.Width
      height = $bmp.Height
      green_count = $greenCount
    }
  } finally {
    $bmp.Dispose()
  }

  $requestEntries = @()
  if (Test-Path $requestLog) {
    $requestEntries = Get-Content $requestLog | Where-Object { $_.Trim().Length -gt 0 } | ForEach-Object { $_ | ConvertFrom-Json }
  }
  $scriptEntries = @($requestEntries | Where-Object { $_.path -eq "/auth-inherit-script.js" })
  $beaconEntries = @($requestEntries | Where-Object { $_.path -eq "/script-beacon.png" })
  $lastScript = if ($scriptEntries.Count -gt 0) { $scriptEntries[-1] } else { $null }
  $lastBeacon = if ($beaconEntries.Count -gt 0) { $beaconEntries[-1] } else { $null }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-LightpandaOwnedProbeProcess $server
  $browserMeta = Stop-LightpandaOwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    port = $Port
    page_url = $pageUrl
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    screenshot_path = $outPng
    screenshot_length = if (Test-Path $outPng) { (Get-Item $outPng).Length } else { 0 }
    analysis = $analysis
    script_request_count = $scriptEntries.Count
    script_request_allowed = if ($lastScript) { [bool]$lastScript.allowed } else { $false }
    script_user_agent = if ($lastScript) { [string]$lastScript.user_agent } else { "" }
    script_cookie = if ($lastScript) { [string]$lastScript.cookie } else { "" }
    script_referer = if ($lastScript) { [string]$lastScript.referer } else { "" }
    script_authorization = if ($lastScript) { [string]$lastScript.authorization } else { "" }
    beacon_request_count = $beaconEntries.Count
    beacon_request_allowed = if ($lastBeacon) { [bool]$lastBeacon.allowed } else { $false }
    beacon_cookie = if ($lastBeacon) { [string]$lastBeacon.cookie } else { "" }
    beacon_referer = if ($lastBeacon) { [string]$lastBeacon.referer } else { "" }
    beacon_authorization = if ($lastBeacon) { [string]$lastBeacon.authorization } else { "" }
    error = $failure
    browser_meta = $browserMeta
    server_meta = $serverMeta
    browser_gone = $browserGone
    server_gone = $serverGone
  } | ConvertTo-Json -Depth 6
}

if ($failure) {
  exit 1
}
