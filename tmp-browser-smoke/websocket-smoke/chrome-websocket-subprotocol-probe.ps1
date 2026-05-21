[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = '127.0.0.1',
  [int]$Port = 0,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
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

$repo = if ([string]::IsNullOrWhiteSpace($RepoRoot)) { Resolve-LightpandaRepoRoot $PSScriptRoot } else { $RepoRoot }
$root = Join-Path $repo 'tmp-browser-smoke\websocket-smoke'
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$serverScript = Join-Path $root 'websocket_server.py'
$browserOut = Join-Path $root 'websocket-subprotocol.browser.stdout.txt'
$browserErr = Join-Path $root 'websocket-subprotocol.browser.stderr.txt'
$serverOut = Join-Path $root 'websocket-subprotocol.server.stdout.txt'
$serverErr = Join-Path $root 'websocket-subprotocol.server.stderr.txt'
$profileRoot = Join-Path $root 'profile-websocket-subprotocol'
$appDataRoot = Join-Path $profileRoot 'lightpanda'

Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
New-Item -ItemType Directory -Force -Path $appDataRoot | Out-Null
@"
lightpanda-browse-settings-v1
restore_previous_session	0
allow_script_popups	0
default_zoom_percent	100
homepage_url	
"@ | Set-Content -Path (Join-Path $appDataRoot 'browse-settings-v1.txt') -NoNewline

$port = if ($Port -gt 0) { $Port } else { Get-FreePort }
$pageUrl = "http://$Host`:$port/index.html?mode=subprotocol"
$server = $null
$browser = $null
$ready = $false
$titleReady = $false
$failure = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript,$port)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw 'websocket subprotocol server did not become ready' }

  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  $browser = Start-Process -FilePath $browserExe -ArgumentList 'browse','--browser_mode','headed',$pageUrl,'--window_width','840','--window_height','560' -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if (-not $proc) { break }
    if ($proc.MainWindowHandle -eq 0) { continue }
    if ($proc.MainWindowTitle -like '*WebSocket Subprotocol Ready*') {
      $titleReady = $true
      break
    }
    if ($proc.MainWindowTitle -like '*WebSocket Subprotocol Error*') {
      break
    }
  }

  if (-not $titleReady) {
    $lastTitle = (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue).MainWindowTitle
    throw "websocket subprotocol page did not reach ready title; last title: $lastTitle"
  }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-LightpandaOwnedProbeProcess $server
  $browserMeta = Stop-LightpandaOwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200

  $result = [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    host = $Host
    port = $port
    ready = $ready
    title_ready = $titleReady
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_gone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
    server_gone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }
    error = if ($failure) { $failure } else { '' }
    browser_stderr = if (Test-Path -LiteralPath $browserErr) { (Get-Content -LiteralPath $browserErr -Raw) -replace "`r","\\r" -replace "`n","\\n" } else { '' }
    server_stderr = if (Test-Path -LiteralPath $serverErr) { (Get-Content -LiteralPath $serverErr -Raw) -replace "`r","\\r" -replace "`n","\\n" } else { '' }
    server_meta = $serverMeta
    browser_meta = $browserMeta
  }
  $result | ConvertTo-Json -Depth 6

  if ($failure -or -not $ready -or -not $titleReady) {
    exit 1
  }
}
