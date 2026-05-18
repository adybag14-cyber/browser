$ErrorActionPreference = "Stop"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$root = Join-Path $repo "tmp-browser-smoke\google-investigation-next"
$pageRoot = Join-Path $repo "src\browser\tests\page"
$port = 8162
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$mailboxPath = Join-Path $root "google-search.mailbox.txt"
$pngPath = Join-Path $root "google-mailbox.before.png"
$browserOut = Join-Path $root "google-mailbox.browser.stdout.txt"
$browserErr = Join-Path $root "google-mailbox.browser.stderr.txt"
$serverOut = Join-Path $root "google-mailbox.server.stdout.txt"
$serverErr = Join-Path $root "google-mailbox.server.stderr.txt"

Remove-Item $mailboxPath,$pngPath,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $root | Out-Null

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$hwnd = [IntPtr]::Zero
$titleBefore = $null
$titleAfterFocus = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$focusWorked = $false
$typedWorked = $false
$submittedWorked = $false
$failure = $null
$focusMethod = $null
$focusAttempt = $null

function Wait-ForSmokeTitle {
  param(
    [IntPtr]$Hwnd,
    [scriptblock]$Predicate,
    [int]$Attempts = 30,
    [int]$SleepMs = 200
  )

  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    if (& $Predicate $title) {
      return $title
    }
  }
  return $null
}

function Test-GoogleInputFocused([string]$Title) {
  return ($Title -match '\|A=INPUT:q:' -or $Title -match '^FOCUSED\|')
}

function Test-GoogleTypedValue([string]$Title, [string]$Expected) {
  return ($Title -like "TYPED:$Expected*" -or $Title -match "\|V=$([regex]::Escape($Expected))\|")
}

function Test-GoogleSubmittedValue([string]$Title, [string]$Expected) {
  return ($Title -like "SUBMIT:$Expected*" -or $Title -match "^KEYDOWN:$([regex]::Escape($Expected)):13:13\|")
}

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $pageRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/google_home_title_probe.html" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google mailbox probe server did not become ready" }

  $profileRoot = Join-Path $root "profile-google-mailbox"
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
  $env:LIGHTPANDA_WIN32_INPUT = $mailboxPath

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google_home_title_probe.html","--window_width","960","--window_height","720","--screenshot_png",$pngPath -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google mailbox probe screenshot did not become ready" }

  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google mailbox probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $titleBefore = Get-SmokeWindowTitle $hwnd

  $clickTargets = @(
    @{ x = 480; y = 250 },
    @{ x = 480; y = 270 },
    @{ x = 480; y = 230 }
  )
  foreach ($candidate in $clickTargets) {
    Invoke-SmokeClientClick -Hwnd $hwnd -X $candidate.x -Y $candidate.y | Out-Null
    $titleAfterFocus = Wait-ForSmokeTitle -Hwnd $hwnd -Predicate { param($title) Test-GoogleInputFocused $title } -Attempts 10 -SleepMs 150
    if ($titleAfterFocus) {
      $focusWorked = $true
      $focusMethod = "click"
      $focusAttempt = [ordered]@{ x = $candidate.x; y = $candidate.y }
      break
    }
  }

  if (-not $focusWorked) {
    for ($i = 1; $i -le 12; $i++) {
      Send-SmokeTab
      $titleAfterFocus = Wait-ForSmokeTitle -Hwnd $hwnd -Predicate { param($title) Test-GoogleInputFocused $title } -Attempts 6 -SleepMs 150
      if ($titleAfterFocus) {
        $focusWorked = $true
        $focusMethod = "tab"
        $focusAttempt = $i
        break
      }
    }
  }
  if (-not $focusWorked) { throw "google search input did not receive focus from mailbox click or Tab traversal" }

  Send-SmokeText "mailbox"
  $titleAfterType = Wait-ForSmokeTitle -Hwnd $hwnd -Predicate { param($title) Test-GoogleTypedValue $title "mailbox" } -Attempts 20 -SleepMs 150
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "google mailbox typing did not update the query value" }

  Send-SmokeEnter
  $titleAfterSubmit = Wait-ForSmokeTitle -Hwnd $hwnd -Predicate { param($title) Test-GoogleSubmittedValue $title "mailbox" } -Attempts 20 -SleepMs 150
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) { throw "google mailbox Enter did not reach the submit path" }
}
catch {
  $failure = $_.Exception.Message
}
finally {
  Remove-Item Env:LIGHTPANDA_WIN32_INPUT -ErrorAction SilentlyContinue

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
    mailbox_path = $mailboxPath
    title_before = $titleBefore
    title_after_focus = $titleAfterFocus
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    focus_worked = $focusWorked
    focus_method = $focusMethod
    focus_attempt = $focusAttempt
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
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
