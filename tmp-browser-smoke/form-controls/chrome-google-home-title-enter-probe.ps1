$ErrorActionPreference = "Stop"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$root = Join-Path $repo "src\browser\tests\page"
$port = 8156
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$outPng = Join-Path $root "google-home-title-enter.png"
$browserOut = Join-Path $root "google-home-title-enter.browser.stdout.txt"
$browserErr = Join-Path $root "google-home-title-enter.browser.stderr.txt"
$serverOut = Join-Path $root "google-home-title-enter.server.stdout.txt"
$serverErr = Join-Path $root "google-home-title-enter.server.stderr.txt"
Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

. "$repo\tmp-browser-smoke\common\Win32Input.ps1"

$script:TitleSamples = New-Object System.Collections.Generic.List[string]

function Add-TitleSample([string]$Title) {
  if ($null -eq $Title -or $Title.Length -eq 0) { return }
  if ($script:TitleSamples.Count -eq 0 -or $script:TitleSamples[$script:TitleSamples.Count - 1] -ne $Title) {
    $script:TitleSamples.Add($Title)
  }
}

function Wait-ForProbeTitle([IntPtr]$Hwnd, [scriptblock]$Predicate, [int]$Attempts = 40, [int]$SleepMs = 150) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    Add-TitleSample $title
    if (& $Predicate $title) {
      return $title
    }
  }
  return $null
}

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

function Focus-GoogleQueryInput([IntPtr]$Hwnd) {
  $clickPoint = Invoke-SmokeClientClick $Hwnd 480 230
  $focusedTitle = Wait-ForProbeTitle $Hwnd { param($title) $title -like "*A=INPUT:q*|Q=INPUT:q*" } 10 120
  if ($focusedTitle) {
    return [ordered]@{
      method = "click"
      click_screen = [ordered]@{ x = $clickPoint.X; y = $clickPoint.Y }
      title = $focusedTitle
    }
  }

  for ($i = 0; $i -lt 10; $i++) {
    Send-SmokeTab
    $focusedTitle = Wait-ForProbeTitle $Hwnd { param($title) $title -like "*A=INPUT:q*|Q=INPUT:q*" } 4 120
    if ($focusedTitle) {
      return [ordered]@{
        method = "tab"
        tab_presses = $i + 1
        title = $focusedTitle
      }
    }
  }

  throw "google title probe did not focus the query input"
}

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$hwnd = [IntPtr]::Zero
$initialTitle = $null
$focusResult = $null
$typedTitle = $null
$keydownTitle = $null
$submitTitle = $null
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
  if (-not $ready) { throw "google title probe server did not become ready" }

  $profileRoot = Join-Path $root "profile-google-home-title-enter"
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

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google_home_title_probe.html","--window_width","960","--window_height","640","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $outPng) -and ((Get-Item $outPng).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google title probe screenshot did not become ready" }

  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google title probe window handle not found" }

  Show-SmokeWindow $hwnd
  $initialTitle = Wait-ForProbeTitle $hwnd { param($title) $title -like "*Q=INPUT:q*" } 40 150
  if (-not $initialTitle) { throw "google title probe did not bind the query input" }

  $focusResult = Focus-GoogleQueryInput $hwnd

  Send-SmokeText "n"
  $typedTitle = Wait-ForProbeTitle $hwnd { param($title) $title -like "*TYPED:n*|V=n*" } 20 120
  if (-not $typedTitle) { throw "google title probe did not record typed query text" }

  Send-SmokeEnter
  for ($i = 0; $i -lt 80; $i++) {
    Start-Sleep -Milliseconds 50
    $title = Get-SmokeWindowTitle $hwnd
    Add-TitleSample $title
    if (-not $keydownTitle -and $title -like "*KEYDOWN:n:13:13*") {
      $keydownTitle = $title
    }
    if ($title -like "*SUBMIT:n*") {
      $submitTitle = $title
      $submitAfterKeypress = $title -like "*|E=KP:Enter|*"
      break
    }
  }

  if (-not $submitTitle) { throw "google title probe did not reach the submit marker" }
  if (-not $submitAfterKeypress) { throw "google title probe submitted before keypress reached the reduced Google fixture" }
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
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    initial_title = $initialTitle
    focus = $focusResult
    typed_title = $typedTitle
    keydown_title = $keydownTitle
    submit_title = $submitTitle
    submit_after_keypress = $submitAfterKeypress
    title_samples = $script:TitleSamples
    error = $failure
    browser_gone = $browserGone
    server_gone = $serverGone
  } | ConvertTo-Json -Depth 7
}

if ($failure) {
  exit 1
}
