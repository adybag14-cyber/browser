[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8168,
  [string]$InputText = "n",
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

$browserUrl = "http://{0}:{1}/google_home_title_probe.html" -f $Host, $Port
$pingUrl = "http://{0}:{1}/ping" -f $Host, $Port
$serverScript = Join-Path $root "google_probe_server.py"
$browserOut = Join-Path $root "google-home-enter.browser.stdout.txt"
$browserErr = Join-Path $root "google-home-enter.browser.stderr.txt"
$serverOut = Join-Path $root "google-home-enter.server.stdout.txt"
$serverErr = Join-Path $root "google-home-enter.server.stderr.txt"
$pngPath = Join-Path $root "google-home-enter.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\\Win32Input.ps1")

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$windowHandleReady = $false
$windowReadyFallbackUsed = $false
$startupReadySignal = "none"
$boundTitle = $null
$focusedTitle = $null
$typedTitle = $null
$keydownTitle = $null
$submitTitle = $null
$typedWorked = $false
$keydownWorked = $false
$submittedWorked = $false
$failure = $null

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts, [int]$SleepMs) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    if ($title -like $Pattern) {
      return $title
    }
  }
  return $null
}

function Get-LikePrefixPattern([string]$Prefix, [string]$Value) {
  return "{0}{1}*" -f $Prefix, ([System.Management.Automation.WildcardPattern]::Escape($Value))
}

if (-not (Test-Path -LiteralPath $serverScript -PathType Leaf)) {
  throw "google reduced probe server script not found: $serverScript"
}
if (-not (Test-Path -LiteralPath $BrowserExe -PathType Leaf)) {
  throw "headed browser executable not found: $BrowserExe"
}

try {
  $server = Start-Process -FilePath "python" -ArgumentList $serverScript,$Port -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt ($ServerReadyTimeoutSeconds * 4); $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $pingUrl -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google reduced probe server did not become ready" }

  $browser = Start-Process -FilePath $BrowserExe -ArgumentList "browse",$browserUrl,"--window_width","1280","--window_height","900","--screenshot_png",$pngPath -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds

    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) {
      $pngReady = $true
    }

    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      $windowHandleReady = $true
    }

    if ($pngReady -or $windowHandleReady) {
      if ($pngReady) {
        $startupReadySignal = "screenshot"
      } else {
        $startupReadySignal = "window-handle"
        $windowReadyFallbackUsed = $true
      }
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google reduced probe window handle not found" }
  if (-not $pngReady) { $windowReadyFallbackUsed = $true }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds $PollMilliseconds

  $boundTitle = Wait-ForTitleLike $hwnd "BOUND*" $TitleWaitAttempts $PollMilliseconds
  if ($null -eq $boundTitle) { throw "reduced Google fixture never bound the query input" }

  Invoke-SmokeClientClick -Hwnd $hwnd -X 620 -Y 318 | Out-Null
  $focusedTitle = Wait-ForTitleLike $hwnd "FOCUSED*" $TitleWaitAttempts $PollMilliseconds
  if ($null -eq $focusedTitle) { throw "query input did not focus after click" }

  Send-SmokeText $InputText
  $typedTitle = Wait-ForTitleLike $hwnd (Get-LikePrefixPattern -Prefix "TYPED:" -Value $InputText) $TitleWaitAttempts $PollMilliseconds
  $typedWorked = $null -ne $typedTitle
  if (-not $typedWorked) { throw "query input did not receive typed text" }

  Send-SmokeEnter
  $keydownTitle = Wait-ForTitleLike $hwnd (Get-LikePrefixPattern -Prefix "KEYDOWN:" -Value $InputText) $TitleWaitAttempts $PollMilliseconds
  $keydownWorked = $null -ne $keydownTitle
  if (-not $keydownWorked) { throw "Enter did not leave the reduced Google fixture in KEYDOWN before submit" }

  $submitTitle = Wait-ForTitleLike $hwnd (Get-LikePrefixPattern -Prefix "SUBMIT:" -Value $InputText) $TitleWaitAttempts $PollMilliseconds
  $submittedWorked = $null -ne $submitTitle
  if (-not $submittedWorked) { throw "Enter did not submit after keypress on the reduced Google fixture" }
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
    window_ready_fallback_used = $windowReadyFallbackUsed
    startup_ready_signal = $startupReadySignal
    bound_title = $boundTitle
    focused_title = $focusedTitle
    typed_title = $typedTitle
    keydown_title = $keydownTitle
    submit_title = $submitTitle
    typed_worked = $typedWorked
    keydown_worked = $keydownWorked
    submitted_worked = $submittedWorked
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
