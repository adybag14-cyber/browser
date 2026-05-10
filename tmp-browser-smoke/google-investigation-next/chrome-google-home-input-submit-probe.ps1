$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..\.." )).Path
$port = 8158
$fixturePath = "src/browser/tests/page/google_home_title_probe.html"
$fixtureUrl = "http://127.0.0.1:$port/$fixturePath"
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$outPng = Join-Path $root "google-home-input-submit.png"
$browserOut = Join-Path $root "google-home-input-submit.browser.stdout.txt"
$browserErr = Join-Path $root "google-home-input-submit.browser.stderr.txt"
$serverOut = Join-Path $root "google-home-input-submit.server.stdout.txt"
$serverErr = Join-Path $root "google-home-input-submit.server.stderr.txt"
Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

. "$PSScriptRoot\..\common\Win32Input.ps1"

function Get-ProcessCommandLine($TargetPid) {
  $meta = Get-CimInstance Win32_Process -Filter "ProcessId=$TargetPid" -ErrorAction SilentlyContinue |
    Select-Object Name,ProcessId,CommandLine,CreationDate
  if ($meta) { return [string]$meta.CommandLine }
  return ""
}

function Stop-VerifiedProcess($TargetPid) {
  $cmd = Get-ProcessCommandLine $TargetPid
  if ($cmd -and $cmd -notmatch "codex\.js|@openai/codex") {
    try {
      Stop-Process -Id $TargetPid -Force -ErrorAction Stop
    } catch {
      if (Get-Process -Id $TargetPid -ErrorAction SilentlyContinue) { throw }
    }
  }
}

function Wait-ForWindowTitle($Hwnd, $Pattern, $Attempts = 40, $SleepMs = 150) {
  $last = $null
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $last = Get-SmokeWindowTitle $Hwnd
    if ($last -like $Pattern) {
      return $last
    }
  }
  return $last
}

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$hwnd = [IntPtr]::Zero
$titleReady = $null
$titleAfterType = $null
$titleAfterEnter = $null
$titleAfterFallbackTab = $null
$autofocusWorked = $false
$typedWorked = $false
$submitWorked = $false
$enterKeydownObserved = $false
$failure = $null

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $repo -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $fixtureUrl -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google home input submit probe server did not become ready" }

  $profileRoot = Join-Path $root "profile-google-home-input-submit"
  $appDataRoot = Join-Path $profileRoot "lightpanda"
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

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse",$fixtureUrl,"--window_width","1120","--window_height","720","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $outPng) -and ((Get-Item $outPng).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google home input submit probe screenshot did not become ready" }

  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google home input submit probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $titleReady = Wait-ForWindowTitle $hwnd "*A=INPUT:q::1*" 50 150
  if ($titleReady -notlike "*A=INPUT:q::1*") {
    Send-SmokeTab
    $titleAfterFallbackTab = Wait-ForWindowTitle $hwnd "*A=INPUT:q::1*" 20 150
    if ($titleAfterFallbackTab) {
      $titleReady = $titleAfterFallbackTab
    }
  }
  $autofocusWorked = $titleReady -like "*A=INPUT:q::1*"
  if (-not $autofocusWorked) { throw "google home input submit probe never focused the query input" }

  Send-SmokeText "n"
  $titleAfterType = Wait-ForWindowTitle $hwnd "TYPED:n|*" 40 150
  if ($titleAfterType -notlike "TYPED:n|*") {
    $titleAfterType = Wait-ForWindowTitle $hwnd "*|V=n|*" 20 150
  }
  $typedWorked = ($titleAfterType -like "TYPED:n|*") -or ($titleAfterType -like "*|V=n|*")
  if (-not $typedWorked) { throw "google home input submit probe did not observe typed query text" }

  Send-SmokeEnter
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 75
    $titleAfterEnter = Get-SmokeWindowTitle $hwnd
    if ($titleAfterEnter -like "KEYDOWN:n:13:13|*" -or $titleAfterEnter -like "DOC-KD:INPUT:q::1:Enter:13:13|*") {
      $enterKeydownObserved = $true
    }
    if ($titleAfterEnter -like "SUBMIT:n|*") {
      $submitWorked = $true
      break
    }
  }
  if (-not $submitWorked) {
    $titleAfterEnter = Wait-ForWindowTitle $hwnd "SUBMIT:n|*" 20 150
    if ($titleAfterEnter -like "SUBMIT:n|*") {
      $submitWorked = $true
    }
  }
  if (-not $submitWorked) { throw "google home input submit probe did not observe Enter submit" }
}
catch {
  $failure = $_.Exception.Message
}
finally {
  $serverMeta = if ($server) { Get-CimInstance Win32_Process -Filter "ProcessId=$($server.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  $browserMeta = if ($browser) { Get-CimInstance Win32_Process -Filter "ProcessId=$($browser.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  if ($browserMeta -and $browserMeta.CommandLine -and $browserMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-VerifiedProcess $browser.Id }
  if ($serverMeta -and $serverMeta.CommandLine -and $serverMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-VerifiedProcess $server.Id }
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    fixture_url = $fixtureUrl
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    title_ready = $titleReady
    title_after_fallback_tab = $titleAfterFallbackTab
    title_after_type = $titleAfterType
    title_after_enter = $titleAfterEnter
    autofocus_worked = $autofocusWorked
    typed_worked = $typedWorked
    enter_keydown_observed = $enterKeydownObserved
    submit_worked = $submitWorked
    error = $failure
    browser_gone = $browserGone
    server_gone = $serverGone
  } | ConvertTo-Json -Depth 6
}

if ($failure) {
  exit 1
}
