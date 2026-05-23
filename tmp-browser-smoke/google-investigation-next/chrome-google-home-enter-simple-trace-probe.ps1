$ErrorActionPreference = "Stop"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$root = Join-Path $repo "tmp-browser-smoke\google-investigation-next"
$profileRoot = Join-Path $root "profile-google-home-enter"
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$serverScript = Join-Path $root "google_home_trace_server.py"
$browserOut = Join-Path $root "chrome-google-home-enter.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-google-home-enter.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-google-home-enter.server.stdout.txt"
$serverErr = Join-Path $root "chrome-google-home-enter.server.stderr.txt"
$traceGlob = Join-Path $root "*.log"
$port = 8174

cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$traceGlob -Force -ErrorAction SilentlyContinue

$env:APPDATA = $profileRoot
$env:LOCALAPPDATA = $profileRoot

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

$server = $null
$browser = $null
$ready = $false
$typedWorked = $false
$submittedWorked = $false
$serverSawSubmit = $false
$failure = $null
$titleBefore = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$traceSummary = [ordered]@{}

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

function Get-TraceSummary([string]$Directory) {
  $result = [ordered]@{}
  foreach ($name in @(
    "browse-render.log",
    "session-wait.log"
  )) {
    $path = Join-Path $Directory $name
    $result[$name] = [ordered]@{
      exists = Test-Path $path
      lines = if (Test-Path $path) { (Get-Content $path | Measure-Object -Line).Lines } else { 0 }
      path = $path
    }
  }

  foreach ($prefix in @(
    "runtime-input-backend-",
    "wndproc-input-"
  )) {
    $matches = @(Get-ChildItem -Path $Directory -Filter "$prefix*.log" -ErrorAction SilentlyContinue)
    $result[$prefix + "*"] = [ordered]@{
      count = $matches.Count
      files = @($matches | ForEach-Object {
        [ordered]@{
          path = $_.FullName
          lines = (Get-Content $_.FullName | Measure-Object -Line).Lines
        }
      })
    }
  }

  return $result
}

try {
  $server = Start-Process -FilePath "python" -ArgumentList $serverScript,$port -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/ping" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google home trace server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google-home-enter-submit.html","--window_width","960","--window_height","640" -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-TabWindowHandle $browser.Id
  if ($hwnd -eq [IntPtr]::Zero) { throw "google home trace probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 300
  $titleBefore = Get-SmokeWindowTitle $hwnd

  [void](Invoke-SmokeClientClick $hwnd 470 190)
  Start-Sleep -Milliseconds 180
  Send-SmokeText "zebra lantern"
  $titleAfterType = Wait-ForTitleLike $hwnd "Typed zebra lantern*"
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "google home trace probe did not receive typed text" }

  Send-SmokeEnter
  $titleAfterSubmit = Wait-ForTitleLike $hwnd "Submitted zebra lantern*"
  if (Test-Path $serverOut) {
    $serverLog = Get-Content $serverOut -Raw
    $serverSawSubmit = $serverLog -match "FORM_SUBMIT /search\\?q=zebra lantern"
  }
  $submittedWorked = ($null -ne $titleAfterSubmit) -or $serverSawSubmit
  if (-not $submittedWorked) { throw "google home trace probe did not submit the local search form" }

  $traceSummary = Get-TraceSummary $root
} catch {
  $failure = $_.Exception.Message
  $traceSummary = Get-TraceSummary $root
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    title_before = $titleBefore
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    server_saw_submit = $serverSawSubmit
    trace_summary = $traceSummary
    error = $failure
    server_meta = $serverMeta
    browser_meta = $browserMeta
    browser_gone = $browserGone
    server_gone = $serverGone
  } | ConvertTo-Json -Depth 8
}

if ($failure) {
  exit 1
}
