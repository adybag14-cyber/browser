$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$pageRoot = Join-Path $repoRoot "src\browser\tests\page"
$browserExe = Join-Path $repoRoot "zig-out\bin\lightpanda.exe"
$port = 8155
$browserOut = Join-Path $root "chrome-google-home-title.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-google-home-title.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-google-home-title.server.stdout.txt"
$serverErr = Join-Path $root "chrome-google-home-title.server.stderr.txt"
$beforePng = Join-Path $root "chrome-google-home-title.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$beforePng -Force -ErrorAction SilentlyContinue

. "$PSScriptRoot\..\common\Win32Input.ps1"

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$initialProbeReady = $false
$clickFocusWorked = $false
$tabFocusWorked = $false
$focusWorked = $false
$typedWorked = $false
$submittedWorked = $false
$failure = $null
$initialTitle = $null
$titleAfterClick = $null
$titleAfterTab = $null
$titleAfterType = $null
$titleAfterSubmit = $null

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 20, [int]$SleepMs = 200) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    if ($title -like $Pattern) {
      return $title
    }
  }
  return $null
}

try {
  if (-not (Test-Path $pageRoot)) { throw "google title probe page root not found at $pageRoot" }
  if (-not (Test-Path $browserExe)) { throw "headed browser executable not found at $browserExe" }

  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $pageRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/google_home_title_probe.html" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google title probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google_home_title_probe.html","--window_width","1280","--window_height","900","--screenshot_png",$beforePng -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $beforePng) -and ((Get-Item $beforePng).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google title probe screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google title probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250

  $initialTitle = Wait-ForTitleLike $hwnd "*BOUND*" 40 250
  $initialProbeReady = $null -ne $initialTitle
  if (-not $initialProbeReady) {
    $initialTitle = Get-SmokeWindowTitle $hwnd
    throw "google title probe page did not publish its bound status"
  }

  [void](Invoke-SmokeClientClick $hwnd 640 390)
  $titleAfterClick = Wait-ForTitleLike $hwnd "*A=INPUT:q:*" 20 200
  $clickFocusWorked = $null -ne $titleAfterClick

  if (-not $clickFocusWorked) {
    for ($i = 0; $i -lt 8; $i++) {
      Send-SmokeTab
      $titleAfterTab = Wait-ForTitleLike $hwnd "*A=INPUT:q:*" 8 150
      if ($titleAfterTab) {
        $tabFocusWorked = $true
        break
      }
    }
  }

  $focusWorked = $clickFocusWorked -or $tabFocusWorked
  if (-not $focusWorked) { throw "query input never became the active element" }

  Send-SmokeText "headed probe"
  $titleAfterType = Wait-ForTitleLike $hwnd "*|V=headed probe|*" 20 200
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "query input did not retain typed text" }

  Send-SmokeEnter
  $titleAfterSubmit = Wait-ForTitleLike $hwnd "SUBMIT:headed probe*" 20 200
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) { throw "pressing Enter did not reach the probe submit path" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = if ($server) { Get-CimInstance Win32_Process -Filter "ProcessId=$($server.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  $browserMeta = if ($browser) { Get-CimInstance Win32_Process -Filter "ProcessId=$($browser.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  if ($browserMeta -and $browserMeta.CommandLine -and $browserMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-Process -Id $browser.Id -Force -ErrorAction SilentlyContinue }
  if ($serverMeta -and $serverMeta.CommandLine -and $serverMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    initial_probe_ready = $initialProbeReady
    title_initial = $initialTitle
    title_after_click = $titleAfterClick
    title_after_tab = $titleAfterTab
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    click_focus_worked = $clickFocusWorked
    tab_focus_worked = $tabFocusWorked
    focus_worked = $focusWorked
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
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
