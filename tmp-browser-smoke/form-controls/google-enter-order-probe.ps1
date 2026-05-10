[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8155,
  [string]$InputText = "QZ",
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$TitleWaitAttempts = 80,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot([string]$StartPath) {
  if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    return $env:LIGHTPANDA_REPO_ROOT
  }

  $cursor = [System.IO.Path]::GetFullPath($StartPath)
  while ($true) {
    if (Test-Path (Join-Path $cursor "build.zig")) {
      return $cursor
    }

    $parent = Split-Path $cursor -Parent
    if ([string]::IsNullOrEmpty($parent) -or $parent -eq $cursor) {
      throw "Could not resolve the Lightpanda repo root from $StartPath. Set LIGHTPANDA_REPO_ROOT to override."
    }
    $cursor = $parent
  }
}

function Resolve-PythonCommand {
  if (Get-Command python -ErrorAction SilentlyContinue) {
    return @{ FileName = "python"; Arguments = @() }
  }
  if (Get-Command py -ErrorAction SilentlyContinue) {
    return @{ FileName = "py"; Arguments = @("-3") }
  }
  throw "Python was not found in PATH. Install Python or start the form-controls probe server separately."
}

function Wait-HttpReady([string]$Url, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
      if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) {
        return
      }
    } catch {
    }
    Start-Sleep -Milliseconds $PollMilliseconds
  } while ((Get-Date) -lt $deadline)

  throw "google Enter-order probe server did not become ready at $Url"
}

function Wait-FileReady([string]$Path, [int]$Attempts) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    if ((Test-Path -LiteralPath $Path) -and ((Get-Item -LiteralPath $Path).Length -gt 0)) {
      return $true
    }
  }
  return $false
}

function Get-SubmitEventRecord([string]$LogPath, [string]$ExpectedText) {
  if (-not (Test-Path -LiteralPath $LogPath)) {
    return $null
  }

  $needle = "GOOGLE_ENTER_SUBMIT q=$ExpectedText "
  $matches = @(
    Get-Content -LiteralPath $LogPath | Where-Object { $_ -like "*$needle*" }
  )
  if ($matches.Count -eq 0) {
    return $null
  }

  $line = $matches[-1]
  $match = [regex]::Match($line, "GOOGLE_ENTER_SUBMIT q=(?<query>[^ ]*) phase=(?<phase>[^ ]*) events=(?<events>.*)$")
  if (-not $match.Success) {
    throw "google Enter-order probe could not parse the submit event record"
  }

  return @{
    Line = $line
    Query = $match.Groups["query"].Value
    Phase = $match.Groups["phase"].Value
    Events = $match.Groups["events"].Value
  }
}

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "tabs\TabProbeCommon.ps1")

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-RepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\form-controls"
$profileRoot = Join-Path $root "profile-google-enter-order"
$browserExe = if ($BrowserExe) { $BrowserExe } elseif (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_BROWSER_EXE)) { $env:LIGHTPANDA_BROWSER_EXE } else { Join-Path $repo "zig-out\bin\lightpanda.exe" }
$serverScript = Join-Path $root "form_server.py"
$browserOut = Join-Path $root "google-enter-order.browser.stdout.txt"
$browserErr = Join-Path $root "google-enter-order.browser.stderr.txt"
$serverOut = Join-Path $root "google-enter-order.server.stdout.txt"
$serverErr = Join-Path $root "google-enter-order.server.stderr.txt"
$pngPath = Join-Path $root "google-enter-order.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath $browserExe)) {
  throw "headed browser binary not found: $browserExe"
}
if (-not (Test-Path -LiteralPath $serverScript)) {
  throw "form-controls probe server script not found: $serverScript"
}

$probeUrl = "http://$Host`:$Port/google-enter-order.html"
$focusTitleNeedle = "Google Enter Focused"
$typedTitleNeedle = "Google Enter VALUE:$InputText"
$submittedTitleNeedle = "Submitted $InputText"

cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
$originalAppData = $env:APPDATA
$originalLocalAppData = $env:LOCALAPPDATA
$probeEnv = Get-TabProbeEnvironment $profileRoot
$env:APPDATA = $probeEnv.APPDATA
$env:LOCALAPPDATA = $probeEnv.LOCALAPPDATA

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$titleBefore = $null
$titleAfterClick = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$clickedWorked = $false
$typedWorked = $false
$submittedWorked = $false
$submitPhase = $null
$eventLog = $null
$submitAfterKeypress = $false
$submitAfterKeydown = $false
$submitRecord = $null
$failure = $null

try {
  $python = Resolve-PythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port, $Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  Wait-HttpReady -Url "http://$Host`:$Port/ping" -TimeoutSeconds $ServerReadyTimeoutSeconds
  $ready = $true

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "440", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-FileReady -Path $pngPath -Attempts $WindowReadyAttempts
  if (-not $pngReady) { throw "google Enter-order probe screenshot did not become ready" }

  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts
  if ($hwnd -eq [IntPtr]::Zero) { throw "google Enter-order probe window handle not found" }

  Show-SmokeWindow $hwnd
  $titleBefore = Get-SmokeWindowTitle $hwnd

  [void](Invoke-SmokeClientClick $hwnd 170 98)
  $titleAfterClick = Wait-TabTitle -ProcessId $browser.Id -Needle $focusTitleNeedle -Attempts $TitleWaitAttempts
  $clickedWorked = $null -ne $titleAfterClick
  if (-not $clickedWorked) { throw "clicking the Google-style field did not focus it" }

  Send-SmokeText $InputText
  $titleAfterType = Wait-TabTitle -ProcessId $browser.Id -Needle $typedTitleNeedle -Attempts $TitleWaitAttempts
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "Google-style search input did not receive typed text after click focus" }

  Send-SmokeEnter
  $titleAfterSubmit = Wait-TabTitle -ProcessId $browser.Id -Needle $submittedTitleNeedle -Attempts $TitleWaitAttempts
  $submitRecord = Get-SubmitEventRecord -LogPath $serverErr -ExpectedText $InputText
  if ($submitRecord) {
    $submitPhase = $submitRecord.Phase
    $eventLog = $submitRecord.Events
  }
  $submittedWorked = ($null -ne $titleAfterSubmit) -and ($null -ne $submitRecord)
  if (-not $submittedWorked) { throw "pressing Enter did not submit the Google-style form" }
  if ($null -eq $titleAfterSubmit) { throw "Google-style Enter submit did not navigate to the submitted page" }
  if ($null -eq $submitRecord) { throw "probe server did not capture the Google-style submit log" }
  if ($submitRecord.Query -ne $InputText) { throw "probe server captured the wrong submitted query text" }
  if ($submitPhase -ne "keypress") { throw "expected submit phase keypress, got '$submitPhase'" }
  if ([string]::IsNullOrWhiteSpace($eventLog)) { throw "probe server did not capture the Enter event log" }

  $focusIndex = $eventLog.IndexOf("FOCUS")
  $keydownIndex = $eventLog.IndexOf("KD:Enter:$InputText")
  $keypressIndex = $eventLog.IndexOf("KP:Enter:$InputText")
  $submitIndex = $eventLog.IndexOf("SUBMIT:$InputText")
  if ($focusIndex -lt 0) { throw "event log did not capture click focus" }
  if ($keydownIndex -lt 0) { throw "event log did not capture Enter keydown" }
  if ($keypressIndex -lt 0) { throw "event log did not capture Enter keypress" }
  if ($submitIndex -lt 0) { throw "event log did not capture form submit" }

  $submitAfterKeydown = $submitIndex -gt $keydownIndex
  $submitAfterKeypress = $submitIndex -gt $keypressIndex
  if (-not $submitAfterKeypress) { throw "form submit happened before Enter keypress reached the page" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  $env:APPDATA = $originalAppData
  $env:LOCALAPPDATA = $originalLocalAppData
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    host = $Host
    port = $Port
    probe_url = $probeUrl
    input_text = $InputText
    server_ready_timeout_seconds = $ServerReadyTimeoutSeconds
    window_ready_attempts = $WindowReadyAttempts
    title_wait_attempts = $TitleWaitAttempts
    poll_milliseconds = $PollMilliseconds
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    title_before = $titleBefore
    title_after_click = $titleAfterClick
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    clicked_worked = $clickedWorked
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    submit_phase = $submitPhase
    event_log = $eventLog
    submit_record = if ($submitRecord) { $submitRecord.Line } else { $null }
    submit_after_keydown = $submitAfterKeydown
    submit_after_keypress = $submitAfterKeypress
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
