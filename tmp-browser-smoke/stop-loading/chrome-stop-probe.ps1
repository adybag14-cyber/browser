[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8152,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\stop-loading"
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$serverScript = Join-Path $root "slow_server.py"
$browserOut = Join-Path $root "chrome-stop.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-stop.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-stop.server.stdout.txt"
$serverErr = Join-Path $root "chrome-stop.server.stderr.txt"
$beforePng = Join-Path $root "chrome-stop.before.png"
$indexUrl = "http://$Host`:$Port/index.html"
$slowUrl = "http://$Host`:$Port/slow.html"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$beforePng -Force -ErrorAction SilentlyContinue

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$browserRunningAfterStop = $false
$liveContextRestored = $false
$titleBefore = $null
$titleAfterStop = $null
$titleAfterResume = $null
$slowStarted = $false
$serverSawAbort = $false
$serverSawResponse = $false
$failure = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }
  if (-not (Test-Path -LiteralPath $serverScript)) { throw "stop-loading server script not found: $serverScript" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port, $Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "http://$Host`:$Port/ping" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "stop probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "240", "--window_height", "480", "--screenshot_png", $beforePng, $indexUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-LightpandaFileReady -Path $beforePng -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $pngReady) { throw "stop probe screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "stop probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $titleBefore = Get-SmokeWindowTitle $hwnd

  [void](Invoke-SmokeClientClick $hwnd 120 40)
  Start-Sleep -Milliseconds 200
  Send-SmokeCtrlA
  Start-Sleep -Milliseconds 100
  Send-SmokeText $slowUrl
  Start-Sleep -Milliseconds 200
  Send-SmokeEnter

  for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    if (Test-Path -LiteralPath $serverErr) {
      $serverLog = Get-Content -LiteralPath $serverErr -Raw
      if ($serverLog -match 'SLOW_RESPONSE_BEGIN /slow\.html') {
        $slowStarted = $true
        break
      }
    }
  }
  if (-not $slowStarted) { throw "slow navigation did not begin" }

  [void](Invoke-SmokeClientClick $hwnd 89 40)
  Start-Sleep -Milliseconds 250

  $procAfter = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
  $browserRunningAfterStop = $null -ne $procAfter
  if (-not $browserRunningAfterStop) {
    throw "browser exited after stop"
  }
  $titleAfterStop = Get-SmokeWindowTitle $hwnd

  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $procTick = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    $browserRunningAfterStop = $null -ne $procTick
    if (-not $browserRunningAfterStop) {
      break
    }
    $currentTitle = Get-SmokeWindowTitle $hwnd
    if ($currentTitle -ne $titleAfterStop -and $currentTitle -like "Stop Restore Tick *") {
      $titleAfterResume = $currentTitle
      $liveContextRestored = $true
    }
    if (Test-Path -LiteralPath $serverErr) {
      $serverLog = Get-Content -LiteralPath $serverErr -Raw
      $serverSawAbort = $serverLog -match 'SLOW_RESPONSE_ABORTED /slow\.html'
      $serverSawResponse = $serverLog -match 'SLOW_RESPONSE_SENT /slow\.html'
      if ($liveContextRestored -and ($serverSawAbort -or $serverSawResponse)) {
        break
      }
    }
  }

  if (Test-Path -LiteralPath $serverErr) {
    $serverLog = Get-Content -LiteralPath $serverErr -Raw
    $serverSawAbort = $serverLog -match 'SLOW_RESPONSE_ABORTED /slow\.html'
    $serverSawResponse = $serverLog -match 'SLOW_RESPONSE_SENT /slow\.html'
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
    index_url = $indexUrl
    slow_url = $slowUrl
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    title_before = $titleBefore
    title_after_stop = $titleAfterStop
    title_after_resume = $titleAfterResume
    slow_started = $slowStarted
    browser_running_after_stop = $browserRunningAfterStop
    live_context_restored = $liveContextRestored
    server_saw_abort = $serverSawAbort
    server_saw_response = $serverSawResponse
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
