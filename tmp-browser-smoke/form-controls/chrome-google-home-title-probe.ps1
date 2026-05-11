$ErrorActionPreference = "Stop"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$root = Join-Path $repo "tmp-browser-smoke\form-controls"
$port = 8156
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$fixturePath = "src/browser/tests/page/google_home_title_probe.html"
$probeUrl = "http://127.0.0.1:$port/$fixturePath"
$serverScript = "-m http.server $port --bind 127.0.0.1"
$browserOut = Join-Path $root "google-home-title.browser.stdout.txt"
$browserErr = Join-Path $root "google-home-title.browser.stderr.txt"
$serverOut = Join-Path $root "google-home-title.server.stdout.txt"
$serverErr = Join-Path $root "google-home-title.server.stderr.txt"
$pngPath = Join-Path $root "google-home-title.before.png"
$profileRoot = Join-Path $root "profile-google-home-title"
$appDataRoot = Join-Path $profileRoot "lightpanda"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 20, [int]$SleepMs = 120) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    if ($title -like $Pattern) {
      return $title
    }
  }
  return $null
}

function Stop-VerifiedProcess($TargetPid) {
  $meta = Get-CimInstance Win32_Process -Filter "ProcessId=$TargetPid" -ErrorAction SilentlyContinue |
    Select-Object Name,ProcessId,CommandLine,CreationDate
  if ($meta -and $meta.CommandLine -and $meta.CommandLine -notmatch "codex\.js|@openai/codex") {
    try {
      Stop-Process -Id $TargetPid -Force -ErrorAction Stop
    } catch {
      if (Get-Process -Id $TargetPid -ErrorAction SilentlyContinue) { throw }
    }
  }
}

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$titleBound = $null
$titleFocused = $null
$titleAfterType = $null
$submitTitle = $null
$enterTrace = @()
$keypressObserved = $false
$keydownObserved = $false
$submitAfterKeypress = $false
$failure = $null

try {
  cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
  New-Item -ItemType Directory -Force -Path $appDataRoot | Out-Null
@"
lightpanda-browse-settings-v1
restore_previous_session	0
allow_script_popups	0
default_zoom_percent	100
homepage_url	
"@ | Set-Content -Path (Join-Path $appDataRoot "browse-settings-v1.txt") -NoNewline
  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot

  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $repo -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $probeUrl -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google home title probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse",$probeUrl,"--window_width","1280","--window_height","720","--screenshot_png",$pngPath -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google home title probe screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google home title probe window handle not found" }

  Show-SmokeWindow $hwnd
  $titleBound = Wait-ForTitleLike $hwnd "*|Q=INPUT:q::1|*"
  if (-not $titleBound) { throw "reduced google fixture did not bind the query input" }

  for ($i = 0; $i -lt 24; $i++) {
    Send-SmokeTab
    $titleFocused = Wait-ForTitleLike $hwnd "*|A=INPUT:q::1|Q=INPUT:q::1|*" 2 120
    if ($titleFocused) { break }
  }
  if (-not $titleFocused) { throw "Tab traversal did not move focus onto the reduced Google query input" }

  Send-SmokeText "QZ"
  $titleAfterType = Wait-ForTitleLike $hwnd "TYPED:QZ|*|V=QZ|*"
  if (-not $titleAfterType) { throw "typing did not update the reduced Google query value" }

  Send-SmokeEnter
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 80
    $title = Get-SmokeWindowTitle $hwnd
    if (-not $title) { continue }
    $enterTrace += $title
    if ($title -like "KEYDOWN:QZ:13:13|*") { $keydownObserved = $true }
    if ($title -like "KEYPRESS:Enter:QZ|*") { $keypressObserved = $true }
    if ($title -like "SUBMIT:QZ|*") {
      $submitTitle = $title
      break
    }
  }
  if (-not $submitTitle) { throw "pressing Enter did not submit the reduced Google fixture" }

  $submitAfterKeypress = $submitTitle -like "*|E=KP:Enter|Enter|13|13|13|0"
  if (-not $submitAfterKeypress) {
    throw "submit completed before the reduced Google fixture recorded a keypress-backed Enter path"
  }
}
catch {
  $failure = $_.Exception.Message
}
finally {
  if ($browser) { Stop-VerifiedProcess $browser.Id }
  if ($server) { Stop-VerifiedProcess $server.Id }
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    title_bound = $titleBound
    title_focused = $titleFocused
    title_after_type = $titleAfterType
    submit_title = $submitTitle
    keydown_observed = $keydownObserved
    keypress_observed = $keypressObserved
    submit_after_keypress = $submitAfterKeypress
    enter_trace = $enterTrace
    error = $failure
    browser_gone = $browserGone
    server_gone = $serverGone
  } | ConvertTo-Json -Depth 6
}

if ($failure) {
  exit 1
}
