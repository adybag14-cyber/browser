$ErrorActionPreference = "Stop"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$root = Join-Path $repo "tmp-browser-smoke\google-home"
$testsRoot = Join-Path $repo "src\browser\tests"
$port = 9582
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$probeUrl = "http://127.0.0.1:$port/page/google_home_title_probe.html"
$outPng = Join-Path $root "google-home-enter-submit.png"
$browserOut = Join-Path $root "google-home-enter-submit.browser.stdout.txt"
$browserErr = Join-Path $root "google-home-enter-submit.browser.stderr.txt"
$serverOut = Join-Path $root "google-home-enter-submit.server.stdout.txt"
$serverErr = Join-Path $root "google-home-enter-submit.server.stderr.txt"

New-Item -ItemType Directory -Force -Path $root | Out-Null
Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

. "$PSScriptRoot\..\common\Win32Input.ps1"

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

function Add-TitleSample {
  param(
    [System.Collections.Generic.List[string]]$History,
    [string]$Title
  )

  if ([string]::IsNullOrWhiteSpace($Title)) {
    return
  }

  if ($History.Count -eq 0 -or $History[$History.Count - 1] -ne $Title) {
    $History.Add($Title)
  }
}

function Wait-TitleState {
  param(
    [IntPtr]$Hwnd,
    [System.Collections.Generic.List[string]]$History,
    [scriptblock]$Predicate,
    [int]$Attempts = 60,
    [int]$SleepMs = 200
  )

  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    Add-TitleSample $History $title
    if (& $Predicate $title) {
      return $title
    }
  }

  return $null
}

function Focus-GoogleQueryInput {
  param(
    [IntPtr]$Hwnd,
    [System.Collections.Generic.List[string]]$History
  )

  $title = Wait-TitleState $Hwnd $History { param($t) $t -like "*|A=INPUT:q:*" } 10 150
  if ($title) {
    return $title
  }

  [void](Invoke-SmokeClientClick $Hwnd 180 180)
  Start-Sleep -Milliseconds 120

  for ($i = 0; $i -lt 8; $i++) {
    Send-SmokeTab
    $title = Wait-TitleState $Hwnd $History { param($t) $t -like "*|A=INPUT:q:*" } 4 150
    if ($title) {
      return $title
    }
  }

  return $null
}

$server = $null
$browser = $null
$ready = $false
$hwnd = [IntPtr]::Zero
$titleHistory = [System.Collections.Generic.List[string]]::new()
$initialTitle = $null
$focusTitle = $null
$typedTitle = $null
$finalTitle = $null
$failure = $null
$sawKeydown = $false
$sawSubmit = $false
$sawKeypress = $false
$submitAfterKeydown = $false

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $testsRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $probeUrl -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google home probe server did not become ready" }

  $profileRoot = Join-Path $root "profile-google-home-enter-submit"
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

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse",$probeUrl,"--window_width","1280","--window_height","900","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 80; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google home probe window handle not found" }

  Show-SmokeWindow $hwnd
  $initialTitle = Wait-TitleState $hwnd $titleHistory { param($t) $t -like "BOUND|*" -or $t -like "FOCUSIN:*" -or $t -like "*|A=INPUT:q:*" } 60 200
  if (-not $initialTitle) {
    throw "google home fixture did not publish an instrumented title state"
  }

  $focusTitle = Focus-GoogleQueryInput $hwnd $titleHistory
  if (-not $focusTitle) {
    throw "google home fixture did not focus the q input"
  }

  Send-SmokeText "n"
  $typedTitle = Wait-TitleState $hwnd $titleHistory { param($t) $t -like "TYPED:n*" -or $t -like "*|V=n|*" } 50 150
  if (-not $typedTitle) {
    throw "google home fixture did not reflect typed text in the q input"
  }

  Send-SmokeEnter
  $null = Wait-TitleState $hwnd $titleHistory {
    param($t)
    $t -like "SUBMIT:n*" -or $t -like "KEYDOWN:n*" -or $t -like "KEYPRESS:Enter:n*"
  } 50 150
  $finalTitle = Wait-TitleState $hwnd $titleHistory { param($t) $t -like "SUBMIT:n*" } 20 150

  $historyArray = $titleHistory.ToArray()
  $keydownIndex = -1
  $submitIndex = -1
  for ($i = 0; $i -lt $historyArray.Length; $i++) {
    $title = $historyArray[$i]
    if (-not $sawKeydown -and $title -like "KEYDOWN:n*") {
      $sawKeydown = $true
      $keydownIndex = $i
    }
    if (-not $sawKeypress -and $title -like "KEYPRESS:Enter:n*") {
      $sawKeypress = $true
    }
    if (-not $sawSubmit -and $title -like "SUBMIT:n*") {
      $sawSubmit = $true
      $submitIndex = $i
    }
  }

  $submitAfterKeydown = $sawKeydown -and $sawSubmit -and $submitIndex -gt $keydownIndex
  if (-not $submitAfterKeydown) {
    throw "google home fixture did not reach SUBMIT after KEYDOWN for native Enter"
  }
}
catch {
  $failure = $_.Exception.Message
}
finally {
  $browserMeta = if ($browser) { Get-CimInstance Win32_Process -Filter "ProcessId=$($browser.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  $serverMeta = if ($server) { Get-CimInstance Win32_Process -Filter "ProcessId=$($server.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  if ($browserMeta -and $browserMeta.CommandLine -and $browserMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-VerifiedProcess $browser.Id }
  if ($serverMeta -and $serverMeta.CommandLine -and $serverMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-VerifiedProcess $server.Id }
  Start-Sleep -Milliseconds 200

  [ordered]@{
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    probe_url = $probeUrl
    initial_title = $initialTitle
    focus_title = $focusTitle
    typed_title = $typedTitle
    final_title = $finalTitle
    saw_keydown = $sawKeydown
    saw_keypress = $sawKeypress
    saw_submit = $sawSubmit
    submit_after_keydown = $submitAfterKeydown
    title_history = $titleHistory.ToArray()
    error = $failure
  } | ConvertTo-Json -Depth 6
}

if ($failure) {
  exit 1
}
