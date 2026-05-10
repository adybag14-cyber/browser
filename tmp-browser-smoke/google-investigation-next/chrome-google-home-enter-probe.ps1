$ErrorActionPreference = "Stop"
$root = "C:\Users\adyba\src\lightpanda-browser\tmp-browser-smoke\google-investigation-next"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$port = 8164
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$serverScript = Join-Path $root "google_input_server.py"
$outPng = Join-Path $root "google-home-enter.before.png"
$browserOut = Join-Path $root "google-home-enter.browser.stdout.txt"
$browserErr = Join-Path $root "google-home-enter.browser.stderr.txt"
$serverOut = Join-Path $root "google-home-enter.server.stdout.txt"
$serverErr = Join-Path $root "google-home-enter.server.stderr.txt"
Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 30, [int]$SleepMs = 150) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    if ($title -like $Pattern) {
      return $title
    }
  }
  return $null
}

function Get-ProcessMeta($TargetPid) {
  return Get-CimInstance Win32_Process -Filter "ProcessId=$TargetPid" -ErrorAction SilentlyContinue |
    Select-Object Name,ProcessId,CommandLine,CreationDate
}

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$titleAfterType = $null
$titleAfterSubmit = $null
$typedWorked = $false
$submittedWorked = $false
$serverSawSubmit = $false
$traceLine = $null
$traceEntries = @()
$enterKeypressBeforeSubmit = $false
$submitValueMatched = $false
$failure = $null

try {
  $server = Start-Process -FilePath "python" -ArgumentList $serverScript,$port -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/ping" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google enter probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google-home-enter.html","--window_width","960","--window_height","720","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $outPng) -and ((Get-Item $outPng).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google enter probe screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google enter probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250

  Send-SmokeText "Q"
  $titleAfterType = Wait-ForTitleLike $hwnd "Google Probe Typed Q*"
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "google-style probe input did not receive typed text" }

  Send-SmokeEnter
  $titleAfterSubmit = Wait-ForTitleLike $hwnd "Google Probe Results Q*"
  if (Test-Path $serverErr) {
    $traceLine = Get-Content $serverErr | Select-String "TRACE q=Q " | Select-Object -Last 1
    if ($traceLine) {
      $serverSawSubmit = $true
      $lineText = [string]$traceLine.Line
      $submitValueMatched = $lineText -match "submit_value=Q"
      if ($lineText -match "trace=(.+)$") {
        $traceEntries = $Matches[1].Split("|")
        $submitIndex = [Array]::IndexOf($traceEntries, "submit:Q")
        $keypressIndex = [Array]::IndexOf($traceEntries, "keypress-enter:Q")
        $enterKeypressBeforeSubmit = ($keypressIndex -ge 0) -and ($submitIndex -ge 0) -and ($keypressIndex -lt $submitIndex)
      }
    }
  }

  $submittedWorked = ($null -ne $titleAfterSubmit) -or $serverSawSubmit
  if (-not $submittedWorked) { throw "pressing Enter did not submit the google-style form" }
  if (-not $submitValueMatched) { throw "submitted value did not preserve the typed query" }
  if (-not $enterKeypressBeforeSubmit) { throw "submit reached the server before the Enter keypress trace was recorded" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = if ($server) { Get-ProcessMeta $server.Id } else { $null }
  $browserMeta = if ($browser) { Get-ProcessMeta $browser.Id } else { $null }
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
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    server_saw_submit = $serverSawSubmit
    submit_value_matched = $submitValueMatched
    enter_keypress_before_submit = $enterKeypressBeforeSubmit
    trace_entries = $traceEntries
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
