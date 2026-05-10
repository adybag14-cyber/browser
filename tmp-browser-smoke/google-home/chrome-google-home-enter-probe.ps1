$repo = "C:\Users\adyba\src\lightpanda-browser"
$root = Join-Path $repo "tmp-browser-smoke\google-home"
$profileRoot = Join-Path $root "profile-google-home-enter"
$port = 8168
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$browserOut = Join-Path $root "chrome-google-home-enter.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-google-home-enter.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-google-home-enter.server.stdout.txt"
$serverErr = Join-Path $root "chrome-google-home-enter.server.stderr.txt"
$pagePath = "/src/browser/tests/page/google_home_title_probe.html"

cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

$env:APPDATA = $profileRoot
$env:LOCALAPPDATA = $profileRoot

. "$PSScriptRoot\..\tabs\TabProbeCommon.ps1"

$server = $null
$browser = $null
$ready = $false
$focusedTitle = $null
$typedTitle = $null
$submitTitle = $null
$submitWorked = $false
$failure = $null

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $repo -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port$pagePath" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google home enter probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port$pagePath","--window_width","960","--window_height","640" -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-TabWindowHandle $browser.Id
  if ($hwnd -eq [IntPtr]::Zero) { throw "google home enter probe window handle not found" }
  Show-SmokeWindow $hwnd

  $focusedTitle = Wait-TabTitle $browser.Id "FOCUSED"
  if (-not $focusedTitle) { throw "google home enter probe did not focus the query input" }

  Send-SmokeText "QZ"
  $typedTitle = Wait-TabTitle $browser.Id "TYPED:QZ"
  if (-not $typedTitle) { throw "google home enter probe did not record typed query text" }

  Send-SmokeEnter
  $submitTitle = Wait-TabTitle $browser.Id "SUBMIT:QZ"
  $submitWorked = [bool]$submitTitle
  if (-not $submitWorked) { throw "google home enter probe did not submit after Enter" }
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
    focused_title = $focusedTitle
    typed_title = $typedTitle
    submit_title = $submitTitle
    submit_worked = $submitWorked
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
