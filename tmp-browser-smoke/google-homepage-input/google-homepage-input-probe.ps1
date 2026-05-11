$ErrorActionPreference = "Stop"
$root = "C:\Users\adyba\src\lightpanda-browser\tmp-browser-smoke\google-homepage-input"
$port = 8155
$browserExe = "C:\Users\adyba\src\lightpanda-browser\zig-out\bin\lightpanda.exe"
$serverScript = Join-Path $root "google_home_input_server.py"
$browserOut = Join-Path $root "google-homepage-input.browser.stdout.txt"
$browserErr = Join-Path $root "google-homepage-input.browser.stderr.txt"
$serverOut = Join-Path $root "google-homepage-input.server.stdout.txt"
$serverErr = Join-Path $root "google-homepage-input.server.stderr.txt"
$pngPath = Join-Path $root "google-homepage-input.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$focusTitle = $null
$typedTitle = $null
$resultsTitle = $null
$focusWorked = $false
$typedWorked = $false
$submitWorked = $false
$serverSawSubmit = $false
$serverSawKeydownValue = $false
$serverSawKeypress = $false
$serverSawInput = $false
$serverSawValue = $false
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
  if (-not $ready) { throw "google homepage input probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google-home.html","--window_width","900","--window_height","620","--screenshot_png",$pngPath -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google homepage input probe screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google homepage input probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250

  [void](Invoke-SmokeClientClick $hwnd 238 165)
  $focusTitle = Wait-ForTitleLike $hwnd "Google Home Focus true"
  $focusWorked = $null -ne $focusTitle
  if (-not $focusWorked) { throw "clicking the Google-style input did not focus the field" }

  Send-SmokeText "Q"
  $typedTitle = Wait-ForTitleLike $hwnd "Google Home Input Q"
  $typedWorked = $null -ne $typedTitle
  if (-not $typedWorked) { throw "typed text did not land in the Google-style input" }

  Send-SmokeEnter
  $resultsTitle = Wait-ForTitleLike $hwnd "Google Results Q"
  if (Test-Path $serverErr) {
    $serverLog = Get-Content $serverErr -Raw
    $serverSawSubmit = $serverLog -match "GOOGLE_HOME_SUBMIT"
    $serverSawKeydownValue = $serverLog -match "submit_keydown='Q'"
    $serverSawKeypress = $serverLog -match "submit_keypress='true'"
    $serverSawInput = $serverLog -match "submit_input='true'"
    $serverSawValue = $serverLog -match "submit_value='Q'"
  }
  $submitWorked = ($null -ne $resultsTitle) -or ($serverSawSubmit -and $serverSawKeydownValue -and $serverSawKeypress -and $serverSawInput -and $serverSawValue)
  if (-not $submitWorked) { throw "pressing Enter did not preserve the typed query through submit" }
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
    focus_title = $focusTitle
    typed_title = $typedTitle
    results_title = $resultsTitle
    focus_worked = $focusWorked
    typed_worked = $typedWorked
    submit_worked = $submitWorked
    server_saw_submit = $serverSawSubmit
    server_saw_keydown_value = $serverSawKeydownValue
    server_saw_keypress = $serverSawKeypress
    server_saw_input = $serverSawInput
    server_saw_value = $serverSawValue
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
