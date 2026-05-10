# Acceptance probe: reduced Google homepage fixture should accept headed Win32 text input and Enter submit.
$repo = "C:\Users\adyba\src\lightpanda-browser"
$root = Join-Path $repo "tmp-browser-smoke\google-home"
$fixtureRoot = Join-Path $repo "src\browser\tests"
$profileRoot = Join-Path $root "profile-google-home"
$port = 8176
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$browserOut = Join-Path $root "chrome-google-home.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-google-home.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-google-home.server.stdout.txt"
$serverErr = Join-Path $root "chrome-google-home.server.stderr.txt"

cmd /c "rmdir /s /q ``"$profileRoot``"" | Out-Null
New-Item -ItemType Directory -Force -Path $root | Out-Null
New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

$env:APPDATA = $profileRoot
$env:LOCALAPPDATA = $profileRoot

. "$PSScriptRoot\..\tabs\TabProbeCommon.ps1"

function Wait-WindowTitlePattern([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 40) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds 200
    $title = Get-SmokeWindowTitle $Hwnd
    if ($title -match $Pattern) {
      return $title
    }
  }
  return $null
}

$server = $null
$browser = $null
$ready = $false
$focusWorked = $false
$typedWorked = $false
$submitWorked = $false
$failure = $null
$titles = [ordered]@{}
$clickClient = [ordered]@{ x = 480; y = 260 }
$clickScreen = $null

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $fixtureRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/page/google_home_title_probe.html" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "reduced Google home probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/page/google_home_title_probe.html","--window_width","960","--window_height","720" -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-TabWindowHandle $browser.Id
  if ($hwnd -eq [IntPtr]::Zero) { throw "reduced Google home probe window handle not found" }
  Show-SmokeWindow $hwnd

  $titles.bound = Wait-WindowTitlePattern $hwnd "\|Q=INPUT:q::1\|"
  if (-not $titles.bound) { throw "reduced Google home probe did not bind the query input" }

  $clickScreen = Invoke-SmokeClientClick $hwnd $clickClient.x $clickClient.y
  $titles.after_click = Wait-WindowTitlePattern $hwnd "A=INPUT:q::1"
  if (-not $titles.after_click) {
    Send-SmokeTab
    $titles.after_tab = Wait-WindowTitlePattern $hwnd "A=INPUT:q::1"
  }
  $focusWorked = [bool]($titles.after_click -or $titles.after_tab)
  if (-not $focusWorked) { throw "reduced Google home probe did not focus the query input" }

  Send-SmokeText "n"
  $titles.after_type = Wait-WindowTitlePattern $hwnd "TYPED:n.*\|V=n\|"
  $typedWorked = [bool]$titles.after_type
  if (-not $typedWorked) { throw "reduced Google home probe did not commit typed text" }

  Send-SmokeEnter
  $titles.after_enter = Wait-WindowTitlePattern $hwnd "SUBMIT:n"
  $submitWorked = [bool]$titles.after_enter
  if (-not $submitWorked) { throw "reduced Google home probe did not submit on Enter" }
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
    focus_worked = $focusWorked
    typed_worked = $typedWorked
    submit_worked = $submitWorked
    titles = $titles
    click_client = $clickClient
    click_screen = if ($clickScreen) { [ordered]@{ x = $clickScreen.X; y = $clickScreen.Y } } else { $null }
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
