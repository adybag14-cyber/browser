$ErrorActionPreference = "Stop"

$repo = "C:\Users\adyba\src\lightpanda-browser"
$root = Join-Path $repo "tmp-browser-smoke\google-investigation-next"
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$port = 8159
$probePath = "src/browser/tests/page/google_home_title_probe.html"
$probeUrl = "http://127.0.0.1:$port/$probePath"
$serverOut = Join-Path $root "google-title.server.stdout.txt"
$serverErr = Join-Path $root "google-title.server.stderr.txt"
$browserOut = Join-Path $root "google-title.browser.stdout.txt"
$browserErr = Join-Path $root "google-title.browser.stderr.txt"
$screenshotPath = Join-Path $root "google-title.before.png"

New-Item -ItemType Directory -Force -Path $root | Out-Null
Remove-Item $serverOut,$serverErr,$browserOut,$browserErr,$screenshotPath -Force -ErrorAction SilentlyContinue

. (Join-Path $repo "tmp-browser-smoke\common\Win32Input.ps1")

$server = $null
$browser = $null
$ready = $false
$windowReady = $false
$initialReady = $false
$focusedWorked = $false
$typedWorked = $false
$submittedWorked = $false
$failure = $null
$titleInitial = $null
$titleFocused = $null
$titleTyped = $null
$titleSubmitted = $null

function Wait-ForGoogleProbeTitle {
  param(
    [IntPtr]$Hwnd,
    [string[]]$Patterns,
    [int]$Attempts = 30,
    [int]$SleepMs = 250
  )

  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    foreach ($pattern in $Patterns) {
      if ($title -like $pattern) {
        return $title
      }
    }
  }

  return $null
}

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $repo -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $probeUrl -TimeoutSec 2
      if ($resp.StatusCode -eq 200) {
        $ready = $true
        break
      }
    } catch {}
  }
  if (-not $ready) { throw "google title probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse",$probeUrl,"--window_width","1280","--window_height","900","--screenshot_png",$screenshotPath -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 80; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      $windowReady = $true
      break
    }
  }
  if (-not $windowReady) { throw "google title probe window handle not found" }

  Show-SmokeWindow $hwnd

  $titleInitial = Wait-ForGoogleProbeTitle $hwnd @("*BOUND*","*NOQ*","*INIT*") 50 250
  $initialReady = $null -ne $titleInitial
  if (-not $initialReady) { throw "google title probe page did not publish an initial title marker" }

  [void](Invoke-SmokeClientClick $hwnd 640 248)
  $titleFocused = Wait-ForGoogleProbeTitle $hwnd @("*FOCUSED*","*FOCUSIN:INPUT:q*","*A=INPUT:q*") 20 250
  if (-not $titleFocused) {
    [void](Invoke-SmokeClientClick $hwnd 640 248)
    $titleFocused = Wait-ForGoogleProbeTitle $hwnd @("*FOCUSED*","*FOCUSIN:INPUT:q*","*A=INPUT:q*") 20 250
  }
  $focusedWorked = $null -ne $titleFocused
  if (-not $focusedWorked) { throw "google title probe did not focus the query input after click" }

  Send-SmokeText "zig headed"
  $titleTyped = Wait-ForGoogleProbeTitle $hwnd @("*TYPED:zig headed*","*|V=zig headed|*") 30 250
  $typedWorked = $null -ne $titleTyped
  if (-not $typedWorked) { throw "google title probe did not reflect typed text in the query input" }

  Send-SmokeEnter
  $titleSubmitted = Wait-ForGoogleProbeTitle $hwnd @("*SUBMIT:zig headed*") 30 250
  $submittedWorked = $null -ne $titleSubmitted
  if (-not $submittedWorked) { throw "google title probe did not observe submit after Enter" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = if ($server) { Get-CimInstance Win32_Process -Filter "ProcessId=$($server.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  $browserMeta = if ($browser) { Get-CimInstance Win32_Process -Filter "ProcessId=$($browser.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  if ($browserMeta -and $browserMeta.CommandLine -and $browserMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-Process -Id $browser.Id -Force -ErrorAction SilentlyContinue }
  if ($serverMeta -and $serverMeta.CommandLine -and $serverMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Milliseconds 200

  [ordered]@{
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    window_ready = $windowReady
    initial_ready = $initialReady
    focused_worked = $focusedWorked
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    title_initial = $titleInitial
    title_focused = $titleFocused
    title_typed = $titleTyped
    title_submitted = $titleSubmitted
    error = $failure
    server_meta = $serverMeta
    browser_meta = $browserMeta
  } | ConvertTo-Json -Depth 7
}

if ($failure) {
  exit 1
}
