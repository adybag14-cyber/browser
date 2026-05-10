$ErrorActionPreference = "Stop"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$pageRoot = Join-Path $repo "src\browser\tests\page"
$probeRoot = Join-Path $repo "tmp-browser-smoke\form-controls"
$profileRoot = Join-Path $probeRoot "profile-google-homepage"
$port = 8155
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$browserOut = Join-Path $probeRoot "chrome-google-homepage.browser.stdout.txt"
$browserErr = Join-Path $probeRoot "chrome-google-homepage.browser.stderr.txt"
$serverOut = Join-Path $probeRoot "chrome-google-homepage.server.stdout.txt"
$serverErr = Join-Path $probeRoot "chrome-google-homepage.server.stderr.txt"
$pngPath = Join-Path $probeRoot "chrome-google-homepage.before.png"
$pageUrl = "http://127.0.0.1:$port/google_home_title_probe.html"

cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

$env:APPDATA = $profileRoot
$env:LOCALAPPDATA = $profileRoot

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$typedWorked = $false
$submittedWorked = $false
$usedClickFallback = $false
$usedTabFallback = $false
$titleBefore = $null
$titleAfterFocus = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$failure = $null

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 20, [int]$SleepMs = 250) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    if ($title -like $Pattern) {
      return $title
    }
  }
  return $null
}

function Try-FocusGoogleQuery([IntPtr]$Hwnd) {
  [void](Invoke-SmokeClientClick $Hwnd 480 245)
  $title = Wait-ForTitleLike $Hwnd "FOCUS*|A=INPUT:q*"
  if ($title) {
    return [ordered]@{ title = $title; click = $true; tab = $false }
  }

  Send-SmokeTab
  $title = Wait-ForTitleLike $Hwnd "FOCUS*|A=INPUT:q*"
  if ($title) {
    return [ordered]@{ title = $title; click = $false; tab = $true }
  }

  return $null
}

function Try-TypeGoogleQuery([IntPtr]$Hwnd, [string]$Text) {
  Send-SmokeText $Text
  $title = Wait-ForTitleLike $Hwnd "TYPED:$Text*"
  if ($title) {
    return [ordered]@{ title = $title; click = $false; tab = $false }
  }

  [void](Invoke-SmokeClientClick $Hwnd 480 245)
  Start-Sleep -Milliseconds 120
  Send-SmokeText $Text
  $title = Wait-ForTitleLike $Hwnd "TYPED:$Text*"
  if ($title) {
    return [ordered]@{ title = $title; click = $true; tab = $false }
  }

  Send-SmokeTab
  Start-Sleep -Milliseconds 120
  Send-SmokeText $Text
  $title = Wait-ForTitleLike $Hwnd "TYPED:$Text*"
  if ($title) {
    return [ordered]@{ title = $title; click = $false; tab = $true }
  }

  return $null
}

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $pageRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $pageUrl -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google homepage probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse",$pageUrl,"--window_width","960","--window_height","720","--screenshot_png",$pngPath -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google homepage probe screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google homepage probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $titleBefore = Get-SmokeWindowTitle $hwnd

  $focusResult = Try-FocusGoogleQuery $hwnd
  if ($focusResult) {
    $titleAfterFocus = $focusResult.title
    if ($focusResult.click) { $usedClickFallback = $true }
    if ($focusResult.tab) { $usedTabFallback = $true }
  }

  $typeResult = Try-TypeGoogleQuery $hwnd "Q"
  if ($typeResult) {
    $titleAfterType = $typeResult.title
    $typedWorked = $true
    if ($typeResult.click) { $usedClickFallback = $true }
    if ($typeResult.tab) { $usedTabFallback = $true }
  } else {
    throw "google homepage probe did not observe typed text in the query input"
  }

  Send-SmokeEnter
  $titleAfterSubmit = Wait-ForTitleLike $hwnd "SUBMIT:Q*"
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) {
    throw "google homepage probe did not observe Enter submit after typing"
  }
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
    title_before = $titleBefore
    title_after_focus = $titleAfterFocus
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    used_click_fallback = $usedClickFallback
    used_tab_fallback = $usedTabFallback
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
