$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$port = 8156
$fixturePath = "src/browser/tests/page/google_home_title_probe.html"
$fixtureUrl = "http://127.0.0.1:$port/$fixturePath"
$browserOut = Join-Path $root "google-home-enter-submit.browser.stdout.txt"
$browserErr = Join-Path $root "google-home-enter-submit.browser.stderr.txt"
$serverOut = Join-Path $root "google-home-enter-submit.server.stdout.txt"
$serverErr = Join-Path $root "google-home-enter-submit.server.stderr.txt"
$pngPath = Join-Path $root "google-home-enter-submit.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$typedWorked = $false
$enterKeydownWorked = $false
$submittedWorked = $false
$usedClickFallback = $false
$usedTabFallback = $false
$titleBefore = $null
$titleAfterType = $null
$titleAfterEnterKeydown = $null
$titleAfterSubmit = $null
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

function Wait-ForWindowHandle([int]$ProcessId, [int]$Attempts = 60, [int]$SleepMs = 250) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $proc = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      return [IntPtr]$proc.MainWindowHandle
    }
  }
  return [IntPtr]::Zero
}

function Try-TypeIntoFixture([IntPtr]$Hwnd, [string]$Text) {
  Send-SmokeText $Text
  $title = Wait-ForTitleLike $Hwnd ("TYPED:{0}*" -f $Text) 10 200
  if ($title) {
    return [ordered]@{ title = $title; click = $false; tab = $false }
  }

  [void](Invoke-SmokeClientClick $Hwnd 480 300)
  Start-Sleep -Milliseconds 150
  Send-SmokeText $Text
  $title = Wait-ForTitleLike $Hwnd ("TYPED:{0}*" -f $Text) 10 200
  if ($title) {
    return [ordered]@{ title = $title; click = $true; tab = $false }
  }

  Send-SmokeTab
  Start-Sleep -Milliseconds 150
  Send-SmokeText $Text
  $title = Wait-ForTitleLike $Hwnd ("TYPED:{0}*" -f $Text) 10 200
  if ($title) {
    return [ordered]@{ title = $title; click = $false; tab = $true }
  }

  return $null
}

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $repo -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $fixtureUrl -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google fixture server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse",$fixtureUrl,"--window_width","960","--window_height","720","--screenshot_png",$pngPath -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google fixture screenshot did not become ready" }

  $hwnd = Wait-ForWindowHandle $browser.Id
  if ($hwnd -eq [IntPtr]::Zero) { throw "google fixture window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $titleBefore = Get-SmokeWindowTitle $hwnd

  $typeResult = Try-TypeIntoFixture $hwnd "n"
  if (-not $typeResult) { throw "google fixture did not accept typed text" }
  $titleAfterType = $typeResult.title
  $typedWorked = $true
  $usedClickFallback = $typeResult.click
  $usedTabFallback = $typeResult.tab

  Send-SmokeEnter
  $titleAfterEnterKeydown = Wait-ForTitleLike $hwnd "KEYDOWN:n:13:13*" 10 200
  $enterKeydownWorked = $null -ne $titleAfterEnterKeydown
  if (-not $enterKeydownWorked) { throw "Enter did not reach the focused query input before submit" }

  $titleAfterSubmit = Wait-ForTitleLike $hwnd "SUBMIT:n|*" 10 200
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) { throw "Enter did not submit the reduced Google fixture" }
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
    fixture_url = $fixtureUrl
    title_before = $titleBefore
    title_after_type = $titleAfterType
    title_after_enter_keydown = $titleAfterEnterKeydown
    title_after_submit = $titleAfterSubmit
    typed_worked = $typedWorked
    enter_keydown_worked = $enterKeydownWorked
    submitted_worked = $submittedWorked
    used_click_fallback = $usedClickFallback
    used_tab_fallback = $usedTabFallback
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
