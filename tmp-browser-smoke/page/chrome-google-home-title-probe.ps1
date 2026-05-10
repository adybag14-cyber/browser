$ErrorActionPreference = "Stop"
$root = "C:\Users\adyba\src\lightpanda-browser\src\browser\tests\page"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$port = 8158
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$outPng = Join-Path $root "google-home-title-probe.png"
$browserOut = Join-Path $root "google-home-title.browser.stdout.txt"
$browserErr = Join-Path $root "google-home-title.browser.stderr.txt"
$serverOut = Join-Path $root "google-home-title.server.stdout.txt"
$serverErr = Join-Path $root "google-home-title.server.stderr.txt"
Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

. (Join-Path $repo "tmp-browser-smoke\common\Win32Input.ps1")

function Wait-ForTitleMatch([IntPtr]$Hwnd, [scriptblock]$Predicate, [int]$Attempts = 40, [int]$SleepMs = 200) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    if (& $Predicate $title) {
      return $title
    }
  }
  return $null
}

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 40, [int]$SleepMs = 200) {
  return Wait-ForTitleMatch $Hwnd { param($Title) $Title -like $Pattern } $Attempts $SleepMs
}

function Focus-GoogleQuery([IntPtr]$Hwnd) {
  $focusedTitle = Wait-ForTitleMatch $Hwnd {
    param($Title)
    $Title -match 'A=INPUT:q:[^|]*\|Q=INPUT:q:'
  } 6 250
  if ($focusedTitle) {
    return $focusedTitle
  }

  for ($i = 0; $i -lt 6; $i++) {
    Send-SmokeTab
    $focusedTitle = Wait-ForTitleMatch $Hwnd {
      param($Title)
      $Title -match 'A=INPUT:q:[^|]*\|Q=INPUT:q:'
    } 6 200
    if ($focusedTitle) {
      return $focusedTitle
    }
  }

  return $null
}

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$boundTitle = $null
$focusedTitle = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$typedWorked = $false
$submittedWorked = $false
$submitAfterKeypress = $false
$failure = $null

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/google_home_title_probe.html" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google home title probe server did not become ready" }

  $profileRoot = Join-Path $root "profile-google-home-title"
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

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google_home_title_probe.html","--window_width","1366","--window_height","768","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $outPng) -and ((Get-Item $outPng).Length -gt 0)) { $pngReady = $true; break }
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
  Start-Sleep -Milliseconds 250

  $boundTitle = Wait-ForTitleMatch $hwnd {
    param($Title)
    $Title -like "*Q=INPUT:q*"
  } 50 200
  if (-not $boundTitle) { throw "google home title probe never bound the query input" }

  $focusedTitle = Focus-GoogleQuery $hwnd
  if (-not $focusedTitle) { throw "google home title probe could not focus the query input" }

  Send-SmokeText "QZ"
  $titleAfterType = Wait-ForTitleMatch $hwnd {
    param($Title)
    ($Title -like "*|V=QZ|*") -and ($Title -like "*Q=INPUT:q*")
  } 50 200
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "google home title probe did not observe typed query text" }

  Send-SmokeEnter
  $titleAfterSubmit = Wait-ForTitleLike $hwnd "SUBMIT:QZ*|V=QZ*"
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) { throw "google home title probe did not observe query submit" }

  $submitAfterKeypress = $titleAfterSubmit -match '\|E=KP:'
  if (-not $submitAfterKeypress) { throw "google home title probe submit did not preserve keypress ordering" }
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
    bound_title = $boundTitle
    focused_title = $focusedTitle
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    submit_after_keypress = $submitAfterKeypress
    error = $failure
    browser_gone = $browserGone
    server_gone = $serverGone
  } | ConvertTo-Json -Depth 7
}

if ($failure) {
  exit 1
}
