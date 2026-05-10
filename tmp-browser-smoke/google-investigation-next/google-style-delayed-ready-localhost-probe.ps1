$ErrorActionPreference = "Stop"
$repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$root = $PSScriptRoot
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$port = 8178
$serverScript = Join-Path $root "google_style_probe_server.py"
$browserOut = Join-Path $root "google-style-delayed-ready.browser.stdout.txt"
$browserErr = Join-Path $root "google-style-delayed-ready.browser.stderr.txt"
$serverOut = Join-Path $root "google-style-delayed-ready.server.stdout.txt"
$serverErr = Join-Path $root "google-style-delayed-ready.server.stderr.txt"
$pngPath = Join-Path $root "google-style-delayed-ready.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

. (Join-Path (Split-Path $root -Parent) "common\Win32Input.ps1")

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$delayedReadyWorked = $false
$typedWorked = $false
$submittedWorked = $false
$titleAfterReady = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$failure = $null

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 30, [int]$SleepMs = 200) {
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
  $server = Start-Process -FilePath "python" -ArgumentList $serverScript,$port -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/ping" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google delayed-ready probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/headed_google_style_input_delayed_ready_probe.html","--window_width","900","--window_height","760","--screenshot_png",$pngPath -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google delayed-ready probe screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google delayed-ready probe window handle not found" }

  $titleAfterReady = Wait-ForTitleLike $hwnd "ready:*"
  $delayedReadyWorked = $null -ne $titleAfterReady
  if (-not $delayedReadyWorked) { throw "google delayed-ready probe never exposed a ready title state" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 300
  Send-SmokeText "Q"
  $titleAfterType = Wait-ForTitleLike $hwnd "typed:Q"
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "google delayed-ready probe did not commit typed text after readiness gate" }

  Send-SmokeEnter
  $titleAfterSubmit = Wait-ForTitleLike $hwnd "submitted:Q"
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) { throw "google delayed-ready probe did not submit after readiness gate" }
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
    delayed_ready_worked = $delayedReadyWorked
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    title_after_ready = $titleAfterReady
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
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
