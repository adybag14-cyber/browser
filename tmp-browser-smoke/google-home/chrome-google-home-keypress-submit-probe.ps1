[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8167,
  [string]$InputText = "lightpanda",
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$TitleWaitAttempts = 80,
  [int]$PollMilliseconds = 250,
  [switch]$LeaveOpen
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = $PSScriptRoot
if (-not $RepoRoot) {
  $RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
}
if (-not $BrowserExe) {
  $BrowserExe = Join-Path $RepoRoot "zig-out\\bin\\lightpanda.exe"
}

$fixtureRoot = Join-Path $RepoRoot "src\\browser\\tests\\page"
$browserUrl = "http://{0}:{1}/google_home_title_probe.html" -f $Host, $Port
$probeUrl = $browserUrl
$readyPng = Join-Path $root "chrome-google-home-keypress-submit.ready.png"
$browserOut = Join-Path $root "chrome-google-home-keypress-submit.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-google-home-keypress-submit.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-google-home-keypress-submit.server.stdout.txt"
$serverErr = Join-Path $root "chrome-google-home-keypress-submit.server.stderr.txt"
Remove-Item $readyPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\\Win32Input.ps1")

function Wait-ProbeUrl([string]$Url, [int]$Attempts = 30) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { return $true }
    } catch {}
  }
  return $false
}

function Wait-WindowHandle([int]$Pid, [int]$Attempts) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $proc = Get-Process -Id $Pid -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      return [IntPtr]$proc.MainWindowHandle
    }
  }
  return [IntPtr]::Zero
}

function Wait-WindowTitle([IntPtr]$Hwnd, [scriptblock]$Matcher, [int]$Attempts, [int]$SleepMs) {
  $last = ""
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $last = Get-SmokeWindowTitle $Hwnd
    if (& $Matcher $last) {
      return $last
    }
  }
  return $last
}

function Get-LikePrefixPattern([string]$Prefix, [string]$Value) {
  return "{0}{1}*" -f $Prefix, ([System.Management.Automation.WildcardPattern]::Escape($Value))
}

function Focus-QueryInput([IntPtr]$Hwnd) {
  [void](Invoke-SmokeClientClick $Hwnd 480 250)
  $title = Wait-WindowTitle $Hwnd { param($t) $t -like "FOCUSED|*" -or $t -like "*|A=INPUT:q:*" } 12 80
  if ($title -like "FOCUSED|*" -or $title -like "*|A=INPUT:q:*") {
    return $title
  }

  for ($i = 0; $i -lt 16; $i++) {
    Send-SmokeTab
    $title = Wait-WindowTitle $Hwnd { param($t) $t -like "FOCUSED|*" -or $t -like "*|A=INPUT:q:*" } 6 60
    if ($title -like "FOCUSED|*" -or $title -like "*|A=INPUT:q:*") {
      return $title
    }
  }

  return $title
}

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$windowHandleReady = $false
$startupReadySignal = "none"
$focusWorked = $false
$typeWorked = $false
$keydownObserved = $false
$submitObserved = $false
$finalTitle = ""
$focusTitle = ""
$typedTitle = ""
$failure = $null

if (-not (Test-Path -LiteralPath $BrowserExe -PathType Leaf)) {
  throw "headed browser executable not found: $BrowserExe"
}
if (-not (Test-Path -LiteralPath $fixtureRoot -PathType Container)) {
  throw "google home title probe fixture root not found: $fixtureRoot"
}

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$Port,"--bind",$Host -WorkingDirectory $fixtureRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-ProbeUrl -Url $probeUrl -Attempts ($ServerReadyTimeoutSeconds * 4)
  if (-not $ready) { throw "google home title probe server did not become ready" }

  $browser = Start-Process -FilePath $BrowserExe -ArgumentList "browse",$browserUrl,"--window_width","960","--window_height","640","--screenshot_png",$readyPng -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds

    if ((Test-Path $readyPng) -and ((Get-Item $readyPng).Length -gt 0)) {
      $pngReady = $true
      $startupReadySignal = "screenshot"
    }

    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $windowHandleReady = $true
      if ($startupReadySignal -eq "none") {
        $startupReadySignal = "window-handle"
      }
      break
    }
  }

  $hwnd = Wait-WindowHandle -Pid $browser.Id -Attempts 2
  if ($hwnd -eq [IntPtr]::Zero) { throw "google home title probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds $PollMilliseconds

  $focusTitle = Focus-QueryInput -Hwnd $hwnd
  $focusWorked = $focusTitle -like "FOCUSED|*" -or $focusTitle -like "*|A=INPUT:q:*"
  if (-not $focusWorked) { throw "google home title probe did not focus the q input" }

  Send-SmokeCtrlA
  Start-Sleep -Milliseconds 100
  Send-SmokeText $InputText
  $typedTitle = Wait-WindowTitle $hwnd { param($t) $t -like $args[0] } $TitleWaitAttempts 60 -Args (Get-LikePrefixPattern -Prefix "TYPED:" -Value $InputText)
  $typeWorked = $typedTitle -like (Get-LikePrefixPattern -Prefix "TYPED:" -Value $InputText)
  if (-not $typeWorked) { throw "google home title probe did not update title after typing" }

  Send-SmokeEnter
  for ($i = 0; $i -lt ($TitleWaitAttempts * 4); $i++) {
    Start-Sleep -Milliseconds 20
    $finalTitle = Get-SmokeWindowTitle $hwnd
    if ($finalTitle -like (Get-LikePrefixPattern -Prefix "KEYDOWN:" -Value $InputText)) {
      $keydownObserved = $true
      continue
    }
    if ($finalTitle -like (Get-LikePrefixPattern -Prefix "SUBMIT:" -Value $InputText)) {
      $submitObserved = $true
      break
    }
  }

  if (-not $keydownObserved) { throw "google home title probe did not observe Enter keydown state before submit" }
  if (-not $submitObserved) { throw "google home title probe did not observe form submit after keypress" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = if ($server) { Get-CimInstance Win32_Process -Filter "ProcessId=$($server.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  $browserMeta = if ($browser) { Get-CimInstance Win32_Process -Filter "ProcessId=$($browser.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  if (-not $LeaveOpen) {
    if ($browserMeta -and $browserMeta.CommandLine -and $browserMeta.CommandLine -notmatch "codex\\\\.js|@openai/codex") { Stop-Process -Id $browser.Id -Force -ErrorAction SilentlyContinue }
    if ($serverMeta -and $serverMeta.CommandLine -and $serverMeta.CommandLine -notmatch "codex\\\\.js|@openai/codex") { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
  }
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    repo_root = $RepoRoot
    browser_exe = $BrowserExe
    host = $Host
    port = $Port
    input_text = $InputText
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    window_handle_ready = $windowHandleReady
    startup_ready_signal = $startupReadySignal
    focus_worked = $focusWorked
    type_worked = $typeWorked
    keydown_observed = $keydownObserved
    submit_observed = $submitObserved
    focus_title = $focusTitle
    typed_title = $typedTitle
    final_title = $finalTitle
    leave_open = [bool]$LeaveOpen
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
