$ErrorActionPreference = "Stop"
$repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$root = $PSScriptRoot
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$port = 8177
$serverScript = Join-Path $root "google_style_probe_server.py"
$browserOut = Join-Path $root "google-style-correction.browser.stdout.txt"
$browserErr = Join-Path $root "google-style-correction.browser.stderr.txt"
$serverOut = Join-Path $root "google-style-correction.server.stdout.txt"
$serverErr = Join-Path $root "google-style-correction.server.stderr.txt"
$pngPath = Join-Path $root "google-style-correction.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

. (Join-Path (Split-Path $root -Parent) "common\Win32Input.ps1")

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$typedPairWorked = $false
$backspaceWorked = $false
$correctedWorked = $false
$submittedWorked = $false
$titleAfterPair = $null
$titleAfterBackspace = $null
$titleAfterCorrection = $null
$titleAfterSubmit = $null
$failure = $null

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 25, [int]$SleepMs = 200) {
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
  if (-not $ready) { throw "google style correction probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/headed_google_style_input_correction_probe.html","--window_width","900","--window_height","760","--screenshot_png",$pngPath -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google style correction probe screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google style correction probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 300
  Send-SmokeText "QW"
  $titleAfterPair = Wait-ForTitleLike $hwnd "typed:QW"
  $typedPairWorked = $null -ne $titleAfterPair
  if (-not $typedPairWorked) { throw "google style correction probe did not commit the initial multi-character text" }

  Send-SmokeWindowVirtualKey -Hwnd $hwnd -Vk 8
  $titleAfterBackspace = Wait-ForTitleLike $hwnd "typed:Q"
  $backspaceWorked = $null -ne $titleAfterBackspace
  if (-not $backspaceWorked) { throw "google style correction probe did not apply backspace after focus churn" }

  Send-SmokeText "Z"
  $titleAfterCorrection = Wait-ForTitleLike $hwnd "typed:QZ"
  $correctedWorked = $null -ne $titleAfterCorrection
  if (-not $correctedWorked) { throw "google style correction probe did not commit corrected text after backspace" }

  Send-SmokeEnter
  $titleAfterSubmit = Wait-ForTitleLike $hwnd "submitted:QZ"
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) { throw "google style correction probe did not submit corrected text on Enter" }
} catch {
  $failure = $_.Exception.Message
} finally {
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
    typed_pair_worked = $typedPairWorked
    backspace_worked = $backspaceWorked
    corrected_worked = $correctedWorked
    submitted_worked = $submittedWorked
    title_after_pair = $titleAfterPair
    title_after_backspace = $titleAfterBackspace
    title_after_correction = $titleAfterCorrection
    title_after_submit = $titleAfterSubmit
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
