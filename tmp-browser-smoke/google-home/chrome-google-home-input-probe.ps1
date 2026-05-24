$ErrorActionPreference = "Stop"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$root = Join-Path $repo "tmp-browser-smoke\google-home"
$port = 8156
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$serverScript = Join-Path $root "google_home_server.py"
$browserOut = Join-Path $root "chrome-google-home-input.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-google-home-input.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-google-home-input.server.stdout.txt"
$serverErr = Join-Path $root "chrome-google-home-input.server.stderr.txt"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

$server = $null
$browser = $null
$ready = $false
$titleReady = $false
$typedWorked = $false
$submittedWorked = $false
$titleBefore = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$failure = $null

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 24, [int]$SleepMs = 250) {
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
  $server = Start-Process -FilePath "python" -ArgumentList $serverScript,$port -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/ping" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google home probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google.html","--window_width","960","--window_height","720" -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google home probe window handle not found" }

  Show-SmokeWindow $hwnd
  $titleBefore = Wait-ForTitleLike $hwnd "*|Q=INPUT:q:*"
  $titleReady = $null -ne $titleBefore
  if (-not $titleReady) { throw "google home probe did not bind the query input" }

  Send-SmokeText "n"
  $titleAfterType = Wait-ForTitleLike $hwnd "TYPED:n*"
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "google home probe did not accept typed text" }

  Send-SmokeEnter
  $titleAfterSubmit = Wait-ForTitleLike $hwnd "SUBMIT:n*"
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) { throw "google home probe did not submit on Enter" }
} catch {
  $failure = $_.Exception.Message
} finally {
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
    title_ready = $titleReady
    title_before = $titleBefore
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
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
