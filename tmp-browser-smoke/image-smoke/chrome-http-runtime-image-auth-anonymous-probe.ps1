[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [int]$Port = 8156,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$ScreenshotReadyAttempts = 80,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\\ProbeRuntime.ps1")

$repo = if ([string]::IsNullOrWhiteSpace($RepoRoot)) { Resolve-LightpandaRepoRoot $PSScriptRoot } else { $RepoRoot }
$root = Join-Path $repo "tmp-browser-smoke\\image-smoke"
$profileRoot = Join-Path $root "profile-http-runtime-auth-anonymous"
$appDataRoot = Join-Path $profileRoot "lightpanda"
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$serverScript = Join-Path $root "http_runtime_server.py"
$outPng = Join-Path $root "http-runtime-auth-anonymous.png"
$browserOut = Join-Path $root "http-runtime-auth-anonymous.browser.stdout.txt"
$browserErr = Join-Path $root "http-runtime-auth-anonymous.browser.stderr.txt"
$serverOut = Join-Path $root "http-runtime-auth-anonymous.server.stdout.txt"
$serverErr = Join-Path $root "http-runtime-auth-anonymous.server.stderr.txt"
$requestLog = Join-Path $root "http-runtime.requests.jsonl"
$pageUrl = "http://127.0.0.1:$Port/auth-anon-page.html"

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$analysis = $null
$failure = $null
$imageRequestCount = 0
$lastImage = $null

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
  $ready = Wait-LightpandaHttpReady -Url $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "localhost image auth anonymous server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", $pageUrl, "--screenshot_png", $outPng) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-LightpandaFileReady -Path $outPng -Attempts $ScreenshotReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $pngReady) { throw "image auth anonymous screenshot did not become ready" }

  Add-Type -AssemblyName System.Drawing
  $bmp = [System.Drawing.Bitmap]::new($outPng)
  try {
    $redCount = 0
    for ($y = 0; $y -lt $bmp.Height; $y++) {
      for ($x = 0; $x -lt $bmp.Width; $x++) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.R -ge 180 -and $c.G -le 80 -and $c.B -le 80) {
          $redCount++
        }
      }
    }
    $analysis = [ordered]@{
      width = $bmp.Width
      height = $bmp.Height
      red_count = $redCount
    }
  } finally {
    $bmp.Dispose()
  }

  $requestEntries = @()
  if (Test-Path $requestLog) {
    $requestEntries = Get-Content $requestLog | Where-Object { $_.Trim().Length -gt 0 } | ForEach-Object { $_ | ConvertFrom-Json }
  }
  $imageEntries = @($requestEntries | Where-Object { $_.path -eq "/auth-anon-red.png" })
  $imageRequestCount = $imageEntries.Count
  $lastImage = if ($imageEntries.Count -gt 0) { $imageEntries[-1] } else { $null }
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
    image_request_count = $imageRequestCount
    image_request_allowed = if ($lastImage) { [bool]$lastImage.allowed } else { $false }
    image_user_agent = if ($lastImage) { [string]$lastImage.user_agent } else { "" }
    image_cookie = if ($lastImage) { [string]$lastImage.cookie } else { "" }
    image_referer = if ($lastImage) { [string]$lastImage.referer } else { "" }
    image_authorization = if ($lastImage) { [string]$lastImage.authorization } else { "" }
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
