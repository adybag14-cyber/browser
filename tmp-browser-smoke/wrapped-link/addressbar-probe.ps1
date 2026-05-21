[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8144,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

$repo = Resolve-LightpandaRepoRoot $PSScriptRoot
$root = Join-Path $repo "tmp-browser-smoke\wrapped-link"
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$browserOut = Join-Path $root "addressbar.browser.stdout.txt"
$browserErr = Join-Path $root "addressbar.browser.stderr.txt"
$serverOut = Join-Path $root "addressbar.server.stdout.txt"
$serverErr = Join-Path $root "addressbar.server.stderr.txt"
$png = Join-Path $root "addressbar.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$png -Force -ErrorAction SilentlyContinue

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$navigated = $false
$titleBefore = $null
$titleAfter = $null
$serverSawNext = $false
$failure = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind",$Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "http://$Host`:$Port/index.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "addressbar probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/index.html","--window_width","240","--window_height","480","--screenshot_png",$png -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-LightpandaFileReady -Path $png -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $pngReady) { throw "addressbar screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "addressbar window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $titleBefore = Get-SmokeWindowTitle $hwnd
  [void](Invoke-SmokeClientClick $hwnd 120 40)
  Start-Sleep -Milliseconds 200
  Send-SmokeCtrlA
  Start-Sleep -Milliseconds 100
  Send-SmokeText "http://$Host`:$Port/next.html"
  Start-Sleep -Milliseconds 250
  Send-SmokeEnter

  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $titleAfter = Get-SmokeWindowTitle $hwnd
    if ($titleAfter -like "Wrapped Link Target*") {
      $navigated = $true
      break
    }
  }
  if (-not $navigated -and (Test-Path -LiteralPath $serverErr)) {
    $serverLog = Get-Content -LiteralPath $serverErr -Raw
    $serverSawNext = $serverLog -match 'GET /next\.html HTTP/1\.1" 200'
    if ($serverSawNext) {
      $navigated = $true
    }
  }
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
    host = $Host
    port = $Port
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    title_before = $titleBefore
    title_after = $titleAfter
    navigated = $navigated
    server_saw_next = $serverSawNext
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
