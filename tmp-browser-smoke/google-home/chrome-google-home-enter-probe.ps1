$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$port = 8155
$browserExe = Join-Path $repoRoot "zig-out\bin\lightpanda.exe"
$serverScript = Join-Path $root "google_probe_server.py"
$browserOut = Join-Path $root "google-home-enter.browser.stdout.txt"
$browserErr = Join-Path $root "google-home-enter.browser.stderr.txt"
$serverOut = Join-Path $root "google-home-enter.server.stdout.txt"
$serverErr = Join-Path $root "google-home-enter.server.stderr.txt"
$pngPath = Join-Path $root "google-home-enter.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$boundTitle = $null
$focusedTitle = $null
$typedTitle = $null
$keydownTitle = $null
$submitTitle = $null
$typedWorked = $false
$keydownWorked = $false
$submittedWorked = $false
$failure = $null

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 20, [int]$SleepMs = 200) {
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
  $server = Start-Process -FilePath "python" -ArgumentList $serverScript,$port -WorkingDirectory $repoRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/ping" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google reduced probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google_home_title_probe.html","--window_width","1280","--window_height","900","--screenshot_png",$pngPath -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google reduced probe screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google reduced probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250

  $boundTitle = Wait-ForTitleLike $hwnd "BOUND*"
  if ($null -eq $boundTitle) { throw "reduced Google fixture never bound the query input" }

  Invoke-SmokeClientClick -Hwnd $hwnd -X 620 -Y 318 | Out-Null
  $focusedTitle = Wait-ForTitleLike $hwnd "FOCUSED*"
  if ($null -eq $focusedTitle) { throw "query input did not focus after click" }

  Send-SmokeText "n"
  $typedTitle = Wait-ForTitleLike $hwnd "TYPED:n*"
  $typedWorked = $null -ne $typedTitle
  if (-not $typedWorked) { throw "query input did not receive typed text" }

  Send-SmokeEnter
  $keydownTitle = Wait-ForTitleLike $hwnd "KEYDOWN:n*"
  $keydownWorked = $null -ne $keydownTitle
  if (-not $keydownWorked) { throw "Enter did not leave the reduced Google fixture in KEYDOWN before submit" }

  $submitTitle = Wait-ForTitleLike $hwnd "SUBMIT:n*"
  $submittedWorked = $null -ne $submitTitle
  if (-not $submittedWorked) { throw "Enter did not submit after keypress on the reduced Google fixture" }
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
    bound_title = $boundTitle
    focused_title = $focusedTitle
    typed_title = $typedTitle
    keydown_title = $keydownTitle
    submit_title = $submitTitle
    typed_worked = $typedWorked
    keydown_worked = $keydownWorked
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
