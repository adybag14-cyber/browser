$ErrorActionPreference = "Stop"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$artifactRoot = Join-Path $repo "tmp-browser-smoke\form-controls"
$serveRoot = Join-Path $repo "src\browser\tests\page"
$port = 8158
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$browserOut = Join-Path $artifactRoot "google-home-enter-submit.browser.stdout.txt"
$browserErr = Join-Path $artifactRoot "google-home-enter-submit.browser.stderr.txt"
$serverOut = Join-Path $artifactRoot "google-home-enter-submit.server.stdout.txt"
$serverErr = Join-Path $artifactRoot "google-home-enter-submit.server.stderr.txt"
$pngPath = Join-Path $artifactRoot "google-home-enter-submit.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$titleBefore = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$typedWorked = $false
$submittedWorked = $false
$failure = $null
$enterTitles = @()
$sawEnterKeydownTitle = $false
$enterKeydownBeforeSubmit = $false

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

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 60, [int]$SleepMs = 100) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    if ($title -like $Pattern) {
      return $title
    }
  }
  return $null
}

function Watch-TitlesAfterEnter([IntPtr]$Hwnd, [int]$Attempts = 80, [int]$SleepMs = 50) {
  $history = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    if (-not [string]::IsNullOrWhiteSpace($title)) {
      $history.Add($title)
      if ($title -like "SUBMIT:n*") {
        break
      }
    }
  }
  return $history
}

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $serveRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/google_home_title_probe.html" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google home title probe server did not become ready" }

  $profileRoot = Join-Path $artifactRoot "profile-google-home-enter-submit"
  $appDataRoot = Join-Path $profileRoot "lightpanda"
  cmd /c "rmdir /s /q `\"$profileRoot`\"" | Out-Null
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

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google_home_title_probe.html","--window_width","1280","--window_height","760","--screenshot_png",$pngPath -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
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
  $titleBefore = Get-SmokeWindowTitle $hwnd

  $titleFocused = Wait-ForTitleLike $hwnd "FOCUSED*"
  if ($null -ne $titleFocused) {
    $titleBefore = $titleFocused
  }

  Send-SmokeText "n"
  $titleAfterType = Wait-ForTitleLike $hwnd "TYPED:n*"
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "google home query did not receive typed text" }

  Send-SmokeEnter
  $enterTitles = Watch-TitlesAfterEnter $hwnd
  foreach ($candidate in $enterTitles) {
    if ($candidate -like "KEYDOWN:n:13:13*") {
      $sawEnterKeydownTitle = $true
    }
    if ($candidate -like "SUBMIT:n*") {
      $titleAfterSubmit = $candidate
      $submittedWorked = $true
      break
    }
  }
  if ($sawEnterKeydownTitle -and $titleAfterSubmit) {
    $keydownIndex = [Array]::IndexOf($enterTitles.ToArray(), ($enterTitles | Where-Object { $_ -like "KEYDOWN:n:13:13*" } | Select-Object -First 1))
    $submitIndex = [Array]::IndexOf($enterTitles.ToArray(), $titleAfterSubmit)
    $enterKeydownBeforeSubmit = $keydownIndex -ge 0 -and $submitIndex -ge 0 -and $keydownIndex -lt $submitIndex
  }
  if (-not $submittedWorked) { throw "pressing Enter did not mark the reduced Google fixture as submitted" }
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
    title_before = $titleBefore
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    saw_enter_keydown_title = $sawEnterKeydownTitle
    enter_keydown_before_submit = $enterKeydownBeforeSubmit
    enter_titles = $enterTitles
    error = $failure
    browser_gone = $browserGone
    server_gone = $serverGone
  } | ConvertTo-Json -Depth 7
}

if ($failure) {
  exit 1
}
