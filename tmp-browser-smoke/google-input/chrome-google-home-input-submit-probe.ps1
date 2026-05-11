$repo = "C:\Users\adyba\src\lightpanda-browser"
$root = Join-Path $repo "tmp-browser-smoke\google-input"
$serverRoot = Join-Path $repo "src\browser\tests\page"
$profileRoot = Join-Path $root "profile-google-home-input"
$port = 8162
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$browserOut = Join-Path $root "chrome-google-home-input.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-google-home-input.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-google-home-input.server.stdout.txt"
$serverErr = Join-Path $root "chrome-google-home-input.server.stderr.txt"

cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

$env:APPDATA = $profileRoot
$env:LOCALAPPDATA = $profileRoot

. "$PSScriptRoot\..\tabs\TabProbeCommon.ps1"

$server = $null
$browser = $null
$ready = $false
$typed = $false
$submitted = $false
$failure = $null
$titles = [ordered]@{}

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $serverRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/google_home_title_probe.html" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google home input probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google_home_title_probe.html","--window_width","960","--window_height","640" -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-TabWindowHandle $browser.Id
  if ($hwnd -eq [IntPtr]::Zero) { throw "google home input probe window handle not found" }
  Show-SmokeWindow $hwnd

  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $title = Get-SmokeWindowTitle $hwnd
    if ($title -like "*BOUND|*") {
      $titles.bound = $title
      break
    }
  }
  if (-not $titles.bound) { throw "google home input probe did not bind the reduced fixture" }

  Send-SmokeText "n"
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 150
    $title = Get-SmokeWindowTitle $hwnd
    if ($title -like "*|V=n|*" -or $title -like "*KEYPRESS:n:*" -or $title -like "*KEYDOWN:n:*") {
      $titles.after_type = $title
      $typed = $true
      break
    }
  }
  if (-not $typed) { throw "google home input probe did not reflect typed text in the title" }

  Send-SmokeEnter
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 150
    $title = Get-SmokeWindowTitle $hwnd
    if ($title -like "SUBMIT:n|*") {
      $titles.after_enter = $title
      $submitted = $true
      break
    }
  }
  if (-not $submitted) { throw "google home input probe did not submit after Enter" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    typed = $typed
    submitted = $submitted
    titles = $titles
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
