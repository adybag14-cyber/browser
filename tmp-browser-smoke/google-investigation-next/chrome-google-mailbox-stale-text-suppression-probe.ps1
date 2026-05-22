$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\.." )).Path
$root = Join-Path $repoRoot "tmp-browser-smoke\google-investigation-next"
$port = 8196
$browserExe = Join-Path $repoRoot "zig-out\bin\lightpanda.exe"
$browserOut = Join-Path $root "google-mailbox-stale-text.browser.stdout.txt"
$browserErr = Join-Path $root "google-mailbox-stale-text.browser.stderr.txt"
$serverOut = Join-Path $root "google-mailbox-stale-text.server.stdout.txt"
$serverErr = Join-Path $root "google-mailbox-stale-text.server.stderr.txt"
$mailboxPath = Join-Path $root "google-mailbox-stale-text.input.txt"
$targetUrl = "http://127.0.0.1:$port/src/browser/tests/page/google_home_title_probe.html"

New-Item -ItemType Directory -Force -Path $root | Out-Null
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$mailboxPath -Force -ErrorAction SilentlyContinue

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

$server = $null
$browser = $null
$ready = $false
$windowReady = $false
$failure = $null
$titleBefore = $null
$titleAfterKey = $null
$titleAfterText = $null
$mailboxLog = $null
$oldMailbox = $env:LIGHTPANDA_WIN32_INPUT

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 30, [int]$SleepMs = 200) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    if ($title -like $Pattern) {
      return $title
    }
  }
  return $null
}

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1","--directory",$repoRoot -WorkingDirectory $repoRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $targetUrl -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google mailbox probe server did not become ready" }

  $env:LIGHTPANDA_WIN32_INPUT = $mailboxPath
  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse",$targetUrl,"--window_width","900","--window_height","700" -WorkingDirectory $repoRoot -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      $windowReady = $true
      break
    }
  }
  if (-not $windowReady) { throw "google mailbox probe window handle not found" }

  Show-SmokeWindow $hwnd
  $titleBefore = Wait-ForTitleLike $hwnd "*|V=|*" 40 250
  if (-not $titleBefore) { throw "google mailbox probe fixture did not expose its status title" }

  Send-HeadedKeyStroke -Code 65
  $titleAfterKey = Wait-ForTitleLike $hwnd "*|V=a|*" 30 200
  if (-not $titleAfterKey) { throw "mailbox key stroke did not reach the Google probe input" }

  Send-SmokeAsciiText "x"
  $titleAfterText = Wait-ForTitleLike $hwnd "*|V=ax|*" 30 200
  if (-not $titleAfterText) { throw "later mailbox text packet was suppressed instead of appending x" }

  if (Test-Path $mailboxPath) {
    $mailboxLog = Get-Content $mailboxPath -Raw
  }
} catch {
  $failure = $_.Exception.Message
} finally {
  if ($null -eq $oldMailbox) {
    Remove-Item Env:LIGHTPANDA_WIN32_INPUT -ErrorAction SilentlyContinue
  } else {
    $env:LIGHTPANDA_WIN32_INPUT = $oldMailbox
  }

  $serverMeta = if ($server) { Get-CimInstance Win32_Process -Filter "ProcessId=$($server.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  $browserMeta = if ($browser) { Get-CimInstance Win32_Process -Filter "ProcessId=$($browser.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  if ($browserMeta -and $browserMeta.CommandLine -and $browserMeta.CommandLine -notmatch "codex\.js|@openai/codex") { Stop-Process -Id $browser.Id -Force -ErrorAction SilentlyContinue }
  if ($serverMeta -and $serverMeta.CommandLine -and $serverMeta.CommandLine -notmatch "codex\.js|@openai/codex") { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    window_ready = $windowReady
    title_before = $titleBefore
    title_after_key = $titleAfterKey
    title_after_text = $titleAfterText
    mailbox_log = $mailboxLog
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
