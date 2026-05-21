[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [int]$Port = 8163,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$ScreenshotReadyAttempts = 80,
  [int]$PollMilliseconds = 250
)

$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\\ProbeRuntime.ps1")

$repo = if ([string]::IsNullOrWhiteSpace($RepoRoot)) { Resolve-LightpandaRepoRoot $PSScriptRoot } else { $RepoRoot }
$root = Join-Path $repo "tmp-browser-smoke\\image-smoke"
$profileRoot = Join-Path $root "profile-http-runtime-module-auth-anonymous"
$appDataRoot = Join-Path $profileRoot "lightpanda"
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$serverScript = Join-Path $root "http_runtime_server.py"
$outPng = Join-Path $root "http-runtime-module-auth-anonymous.png"
$browserOut = Join-Path $root "http-runtime-module-auth-anonymous.browser.stdout.txt"
$browserErr = Join-Path $root "http-runtime-module-auth-anonymous.browser.stderr.txt"
$serverOut = Join-Path $root "http-runtime-module-auth-anonymous.server.stdout.txt"
$serverErr = Join-Path $root "http-runtime-module-auth-anonymous.server.stderr.txt"
$requestLog = Join-Path $root "http-runtime.requests.jsonl"
$pageUrl = "http://img%20user:p%40ss@127.0.0.1:$port/auth-module-anonymous-page.html"

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$failure = $null
$entries = @()
$rootEntries = @()
$childEntries = @()
$beaconEntries = @()
$lastRoot = $null
$lastChild = $null
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
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, "$port")) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "http://127.0.0.1:$port/auth-module-anonymous-page.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "localhost anonymous module auth server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", $pageUrl, "--screenshot_png", $outPng) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-LightpandaFileReady -Path $outPng -Attempts $ScreenshotReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $pngReady) { throw "anonymous module auth screenshot did not become ready" }

  if (Test-Path -LiteralPath $requestLog) {
    $entries = Get-Content -LiteralPath $requestLog | Where-Object { $_.Trim().Length -gt 0 } | ForEach-Object { $_ | ConvertFrom-Json }
  }
  $rootEntries = @($entries | Where-Object { $_.path -eq "/auth-module-anon-root.js" })
  $childEntries = @($entries | Where-Object { $_.path -eq "/auth-module-anon-child.js" })
  $beaconEntries = @($entries | Where-Object { $_.path -eq "/module-anon-beacon.png" })
  $lastRoot = if ($rootEntries.Count -gt 0) { $rootEntries[-1] } else { $null }
  $lastChild = if ($childEntries.Count -gt 0) { $childEntries[-1] } else { $null }
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
    port = $port
    page_url = $pageUrl
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    screenshot_path = $outPng
    screenshot_length = if (Test-Path -LiteralPath $outPng) { (Get-Item $outPng).Length } else { 0 }
    root_request_count = $rootEntries.Count
    root_request_allowed = if ($lastRoot) { [bool]$lastRoot.allowed } else { $false }
    root_cookie = if ($lastRoot) { [string]$lastRoot.cookie } else { "" }
    root_referer = if ($lastRoot) { [string]$lastRoot.referer } else { "" }
    root_authorization = if ($lastRoot) { [string]$lastRoot.authorization } else { "" }
    child_request_count = $childEntries.Count
    child_request_allowed = if ($lastChild) { [bool]$lastChild.allowed } else { $false }
    child_cookie = if ($lastChild) { [string]$lastChild.cookie } else { "" }
    child_referer = if ($lastChild) { [string]$lastChild.referer } else { "" }
    child_authorization = if ($lastChild) { [string]$lastChild.authorization } else { "" }
    beacon_request_count = $beaconEntries.Count
    beacon_request_allowed = if ($lastBeacon) { [bool]$lastBeacon.allowed } else { $false }
    beacon_cookie = if ($lastBeacon) { [string]$lastBeacon.cookie } else { "" }
    beacon_referer = if ($lastBeacon) { [string]$lastBeacon.referer } else { "" }
    beacon_authorization = if ($lastBeacon) { [string]$lastBeacon.authorization } else { "" }
    browser_meta = $browserMeta
    server_meta = $serverMeta
    browser_gone = $browserGone
    server_gone = $serverGone
    error = if ($failure) { $failure } else { "" }
    browser_stderr = if (Test-Path -LiteralPath $browserErr) { (Get-Content -LiteralPath $browserErr -Raw) -replace "`r","\\r" -replace "`n","\\n" } else { "" }
    server_stderr = if (Test-Path -LiteralPath $serverErr) { (Get-Content -LiteralPath $serverErr -Raw) -replace "`r","\\r" -replace "`n","\\n" } else { "" }
  } | ConvertTo-Json -Depth 6
}

if ($failure) {
  exit 1
}
