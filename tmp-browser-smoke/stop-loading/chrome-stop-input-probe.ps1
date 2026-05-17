[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8153,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$TitleWaitAttempts = 80,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 20, [int]$SleepMs = 250) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    if ($title -like $Pattern) {
      return $title
    }
  }
  return $null
}

function Try-TypeIntoRestoredInput([IntPtr]$Hwnd, [string]$Text, [string]$Pattern, [switch]$AllowTabFallback) {
  Send-SmokeText $Text
  $title = Wait-ForTitleLike $Hwnd $Pattern 10 200
  if ($title) { return [ordered]@{ title = $title; click = $false; tab = $false } }

  [void](Invoke-SmokeClientClick $Hwnd 150 230)
  Start-Sleep -Milliseconds 120
  Send-SmokeText $Text
  $title = Wait-ForTitleLike $Hwnd $Pattern 10 200
  if ($title) { return [ordered]@{ title = $title; click = $true; tab = $false } }

  if ($AllowTabFallback) {
    Send-SmokeTab
    Start-Sleep -Milliseconds 120
    Send-SmokeText $Text
    $title = Wait-ForTitleLike $Hwnd $Pattern 10 200
    if ($title) { return [ordered]@{ title = $title; click = $false; tab = $true } }
  }

  return $null
}

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\stop-loading"
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$serverScript = Join-Path $root "slow_server.py"
$browserOut = Join-Path $root "chrome-stop-input.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-stop-input.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-stop-input.server.stdout.txt"
$serverErr = Join-Path $root "chrome-stop-input.server.stderr.txt"
$beforePng = Join-Path $root "chrome-stop-input.before.png"
$inputUrl = "http://$Host`:$Port/input.html"
$slowUrl = "http://$Host`:$Port/slow.html"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$beforePng -Force -ErrorAction SilentlyContinue

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$browserRunningAfterStop = $false
$preflightWorked = $false
$restoredInputWorked = $false
$usedTabFallback = $false
$usedClickFallback = $false
$titleBefore = $null
$titleAfterPreflight = $null
$titleAfterStop = $null
$titleAfterRestoreInput = $null
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
  if (-not $ready) { throw "stop input probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "260", "--window_height", "520", "--screenshot_png", $beforePng, $inputUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-LightpandaFileReady -Path $beforePng -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $pngReady) { throw "stop input probe screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "stop input probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $titleBefore = Get-SmokeWindowTitle $hwnd

  $preflight = Try-TypeIntoRestoredInput $hwnd "A" "Stop Restore Input A*" -AllowTabFallback
  if ($preflight) {
    $titleAfterPreflight = $preflight.title
    $preflightWorked = $true
    $usedClickFallback = $preflight.click
    $usedTabFallback = $preflight.tab
  } else {
    throw "preflight page input did not update the title"
  }

  [void](Invoke-SmokeClientClick $hwnd 130 40)
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
  Start-Sleep -Milliseconds 350

  $procAfter = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
  $browserRunningAfterStop = $null -ne $procAfter
  if (-not $browserRunningAfterStop) {
    throw "browser exited after stop"
  }
  $titleAfterStop = Get-SmokeWindowTitle $hwnd

  $restoreInput = Try-TypeIntoRestoredInput $hwnd "B" "Stop Restore Input AB*" -AllowTabFallback
  if ($restoreInput) {
    $titleAfterRestoreInput = $restoreInput.title
    if ($restoreInput.click) { $usedClickFallback = $true }
    if ($restoreInput.tab) { $usedTabFallback = $true }
  }
  $restoredInputWorked = $null -ne $titleAfterRestoreInput

  if (Test-Path -LiteralPath $serverErr) {
    $serverLog = Get-Content -LiteralPath $serverErr -Raw
    $serverSawAbort = $serverLog -match 'SLOW_RESPONSE_ABORTED /slow\.html'
    $serverSawResponse = $serverLog -match 'SLOW_RESPONSE_SENT /slow\.html'
  }

  if (-not $restoredInputWorked) {
    throw "restored page input did not preserve state and extend to AB after stop"
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
    input_url = $inputUrl
    slow_url = $slowUrl
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    title_before = $titleBefore
    title_after_preflight = $titleAfterPreflight
    title_after_stop = $titleAfterStop
    title_after_restore_input = $titleAfterRestoreInput
    preflight_worked = $preflightWorked
    slow_started = $slowStarted
    browser_running_after_stop = $browserRunningAfterStop
    restored_input_worked = $restoredInputWorked
    used_click_fallback = $usedClickFallback
    used_tab_fallback = $usedTabFallback
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
