$repo = "C:\Users\adyba\src\lightpanda-browser"
$root = Join-Path $repo "tmp-browser-smoke\google-investigation-next"
$profileRoot = Join-Path $root "profile-google-home-enter-submit"
$port = 8164
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$serverScript = Join-Path $root "google_home_server.py"
$browserOut = Join-Path $root "chrome-google-home-enter-submit.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-google-home-enter-submit.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-google-home-enter-submit.server.stdout.txt"
$serverErr = Join-Path $root "chrome-google-home-enter-submit.server.stderr.txt"
$pngPath = Join-Path $root "chrome-google-home-enter-submit.before.png"

cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

$env:APPDATA = $profileRoot
$env:LOCALAPPDATA = $profileRoot

. "$PSScriptRoot\..\tabs\TabProbeCommon.ps1"

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$typedWorked = $false
$submittedWorked = $false
$submitWaitedForKeypress = $false
$serverSawKeypressStage = $false
$failure = $null
$titles = [ordered]@{}

try {
  $server = Start-Process -FilePath "python" -ArgumentList $serverScript,$port -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/ping" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google home probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google-home-enter-submit.html","--window_width","960","--window_height","640","--screenshot_png",$pngPath -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google home probe screenshot did not become ready" }

  $hwnd = Wait-TabWindowHandle $browser.Id
  if ($hwnd -eq [IntPtr]::Zero) { throw "google home probe window handle not found" }

  Show-SmokeWindow $hwnd
  $titles.initial = Wait-TabTitle $browser.Id "Google Home Input Ready" 20
  if (-not $titles.initial) { throw "google home probe initial title missing" }

  Send-SmokeText "Q"
  $titles.after_type = Wait-TabTitle $browser.Id "Google Home Input Q" 30
  $typedWorked = [bool]$titles.after_type
  if (-not $typedWorked) { throw "google home probe text input did not update the query value" }

  Send-SmokeEnter
  $titles.after_submit = Wait-TabTitle $browser.Id "Google Home Result" 40
  $submittedWorked = [bool]$titles.after_submit
  if (Test-Path $serverErr) {
    $serverLog = Get-Content $serverErr -Raw
    $serverSawKeypressStage = $serverLog -match 'GOOGLE_HOME_SUBMIT .*q=Q.*keypress_seen=1.*submit_stage=keypress'
  }
  $submitWaitedForKeypress = ($titles.after_submit -like "*keypress Q*") -or $serverSawKeypressStage
  if (-not $submittedWorked) { throw "google home probe Enter path did not reach the result page" }
  if (-not $submitWaitedForKeypress) { throw "google home probe submitted before keypress completed" }
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
    screenshot_ready = $pngReady
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    submit_waited_for_keypress = $submitWaitedForKeypress
    server_saw_keypress_stage = $serverSawKeypressStage
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
