$ErrorActionPreference = "Stop"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$root = Join-Path $repo "tmp-browser-smoke\google-home"
$fixtureRoot = Join-Path $repo "src\browser\tests\page"
$port = 8167
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$readyPng = Join-Path $root "chrome-google-home-keypress-submit.ready.png"
$browserOut = Join-Path $root "chrome-google-home-keypress-submit.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-google-home-keypress-submit.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-google-home-keypress-submit.server.stdout.txt"
$serverErr = Join-Path $root "chrome-google-home-keypress-submit.server.stderr.txt"
Remove-Item $readyPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

Add-Type -AssemblyName System.Drawing
. "$PSScriptRoot\..\common\Win32Input.ps1"

function Wait-ProbeUrl([int]$Port, [int]$Attempts = 30) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$Port/google_home_title_probe.html" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { return $true }
    } catch {}
  }
  return $false
}

function Wait-WindowHandle([int]$Pid, [int]$Attempts = 60) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $Pid -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      return [IntPtr]$proc.MainWindowHandle
    }
  }
  return [IntPtr]::Zero
}

function Wait-WindowTitle([IntPtr]$Hwnd, [scriptblock]$Matcher, [int]$Attempts = 80, [int]$SleepMs = 50) {
  $last = ""
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $last = Get-SmokeWindowTitle $Hwnd
    if (& $Matcher $last) {
      return $last
    }
  }
  return $last
}

function Focus-QueryInput([IntPtr]$Hwnd) {
  [void](Invoke-SmokeClientClick $Hwnd 480 250)
  $title = Wait-WindowTitle $Hwnd { param($t) $t -like "FOCUSED|*" -or $t -like "*|A=INPUT:q:*" } 12 80
  if ($title -like "FOCUSED|*" -or $title -like "*|A=INPUT:q:*") {
    return $title
  }

  for ($i = 0; $i -lt 16; $i++) {
    Send-SmokeTab
    $title = Wait-WindowTitle $Hwnd { param($t) $t -like "FOCUSED|*" -or $t -like "*|A=INPUT:q:*" } 6 60
    if ($title -like "FOCUSED|*" -or $title -like "*|A=INPUT:q:*") {
      return $title
    }
  }
  return $title
}

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$hwnd = [IntPtr]::Zero
$focusWorked = $false
$typeWorked = $false
$keydownObserved = $false
$submitObserved = $false
$finalTitle = ""
$focusTitle = ""
$typedTitle = ""
$failure = $null

try {
  New-Item -ItemType Directory -Force -Path $root | Out-Null
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $fixtureRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-ProbeUrl -Port $port
  if (-not $ready) { throw "google home title probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google_home_title_probe.html","--window_width","960","--window_height","640","--screenshot_png",$readyPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $readyPng) -and ((Get-Item $readyPng).Length -gt 0)) {
      $pngReady = $true
      break
    }
  }
  if (-not $pngReady) { throw "google home title probe screenshot did not become ready" }

  $hwnd = Wait-WindowHandle -Pid $browser.Id
  if ($hwnd -eq [IntPtr]::Zero) { throw "google home title probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250

  $focusTitle = Focus-QueryInput -Hwnd $hwnd
  $focusWorked = $focusTitle -like "FOCUSED|*" -or $focusTitle -like "*|A=INPUT:q:*"
  if (-not $focusWorked) { throw "google home title probe did not focus the q input" }

  Send-SmokeCtrlA
  Start-Sleep -Milliseconds 100
  Send-SmokeText "lightpanda"
  $typedTitle = Wait-WindowTitle $hwnd { param($t) $t -like "TYPED:lightpanda|*" } 80 60
  $typeWorked = $typedTitle -like "TYPED:lightpanda|*"
  if (-not $typeWorked) { throw "google home title probe did not update title after typing" }

  Send-SmokeEnter
  for ($i = 0; $i -lt 200; $i++) {
    Start-Sleep -Milliseconds 20
    $finalTitle = Get-SmokeWindowTitle $hwnd
    if ($finalTitle -like "KEYDOWN:lightpanda:*") {
      $keydownObserved = $true
      continue
    }
    if ($finalTitle -like "SUBMIT:lightpanda|*") {
      $submitObserved = $true
      break
    }
  }

  if (-not $keydownObserved) { throw "google home title probe did not observe Enter keydown state before submit" }
  if (-not $submitObserved) { throw "google home title probe did not observe form submit after keypress" }
}
catch {
  $failure = $_.Exception.Message
}
finally {
  if ($browser) { Stop-Process -Id $browser.Id -Force -ErrorAction SilentlyContinue }
  if ($server) { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Milliseconds 250

  [ordered]@{
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    focus_worked = $focusWorked
    type_worked = $typeWorked
    keydown_observed = $keydownObserved
    submit_observed = $submitObserved
    focus_title = $focusTitle
    typed_title = $typedTitle
    final_title = $finalTitle
    error = $failure
    browser_gone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
    server_gone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }
  } | ConvertTo-Json -Depth 6
}

if ($failure) {
  exit 1
}
