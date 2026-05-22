param(
  [string]$BrowserExe = "",
  [string]$Url = "https://www.google.com/",
  [string]$SearchText = "lightpanda",
  [int]$WindowWidth = 1366,
  [int]$WindowHeight = 768,
  [int]$InputX = 683,
  [int]$InputY = 352,
  [int]$PostLaunchSleepMs = 1200,
  [int]$PostTypeSleepMs = 600,
  [int]$PostEnterSleepMs = 1800
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$repoRoot = Split-Path (Split-Path $root -Parent) -Parent
if (-not $BrowserExe) {
  $BrowserExe = Join-Path $repoRoot "zig-out\bin\lightpanda.exe"
}

$browserOut = Join-Path $root "google-input-trace.browser.stdout.txt"
$browserErr = Join-Path $root "google-input-trace.browser.stderr.txt"
$pngPath = Join-Path $root "google-input-trace.before.png"
$renderTracePath = Join-Path $root "browse-render.log"
$waitTracePath = Join-Path $root "session-wait.log"
$rendererTracePath = Join-Path $root "runtime-renderer.log"

Remove-Item $browserOut,$browserErr,$pngPath,$renderTracePath,$waitTracePath,$rendererTracePath -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $root -Filter "runtime-input-backend-*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $root -Filter "wndproc-input-*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

$browser = $null
$pngReady = $false
$titleBefore = $null
$titleAfterType = $null
$titleAfterEnter = $null
$failure = $null

function Wait-ForWindowHandle([int]$Pid, [int]$Attempts = 80, [int]$SleepMs = 250) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $proc = Get-Process -Id $Pid -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      return [IntPtr]$proc.MainWindowHandle
    }
  }
  return [IntPtr]::Zero
}

function Wait-ForScreenshot([string]$Path, [int]$Attempts = 80, [int]$SleepMs = 250) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    if ((Test-Path $Path) -and ((Get-Item $Path).Length -gt 0)) {
      return $true
    }
  }
  return $false
}

function Read-TraceTail([string]$Path, [int]$Tail = 20) {
  if (-not (Test-Path $Path)) {
    return @()
  }
  return @(Get-Content $Path -Tail $Tail)
}

function Read-LatestPatternTail([string]$Pattern, [int]$Tail = 20) {
  $match = Get-ChildItem -Path $root -Filter $Pattern -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTimeUtc -Descending |
    Select-Object -First 1
  if (-not $match) {
    return [ordered]@{
      path = $null
      tail = @()
    }
  }
  return [ordered]@{
    path = $match.FullName
    tail = @(Get-Content $match.FullName -Tail $Tail)
  }
}

try {
  if (-not (Test-Path $BrowserExe)) {
    throw "browser executable not found at $BrowserExe"
  }

  $browser = Start-Process -FilePath $BrowserExe -ArgumentList "browse",$Url,"--browser_mode","headed","--window_width",$WindowWidth,"--window_height",$WindowHeight,"--screenshot_png",$pngPath -WorkingDirectory $repoRoot -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  $pngReady = Wait-ForScreenshot -Path $pngPath
  if (-not $pngReady) {
    throw "google input trace probe screenshot did not become ready"
  }

  $hwnd = Wait-ForWindowHandle -Pid $browser.Id
  if ($hwnd -eq [IntPtr]::Zero) {
    throw "google input trace probe window handle not found"
  }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds $PostLaunchSleepMs
  $titleBefore = Get-SmokeWindowTitle $hwnd

  Invoke-SmokeClientClick -Hwnd $hwnd -X $InputX -Y $InputY | Out-Null
  Start-Sleep -Milliseconds 250
  Send-SmokeText $SearchText
  Start-Sleep -Milliseconds $PostTypeSleepMs
  $titleAfterType = Get-SmokeWindowTitle $hwnd

  Send-SmokeEnter
  Start-Sleep -Milliseconds $PostEnterSleepMs
  $titleAfterEnter = Get-SmokeWindowTitle $hwnd
} catch {
  $failure = $_.Exception.Message
} finally {
  $browserMeta = if ($browser) { Get-CimInstance Win32_Process -Filter "ProcessId=$($browser.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  if ($browserMeta -and $browserMeta.CommandLine -and $browserMeta.CommandLine -notmatch "codex\\.js|@openai/codex") {
    Stop-Process -Id $browser.Id -Force -ErrorAction SilentlyContinue
  }
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    browser_exe = $BrowserExe
    url = $Url
    screenshot_ready = $pngReady
    screenshot_path = $pngPath
    title_before = $titleBefore
    title_after_type = $titleAfterType
    title_after_enter = $titleAfterEnter
    error = $failure
    browser_meta = $browserMeta
    browser_gone = $browserGone
    traces = [ordered]@{
      browse_render = [ordered]@{
        path = $renderTracePath
        exists = Test-Path $renderTracePath
        tail = @(Read-TraceTail -Path $renderTracePath)
      }
      session_wait = [ordered]@{
        path = $waitTracePath
        exists = Test-Path $waitTracePath
        tail = @(Read-TraceTail -Path $waitTracePath)
      }
      runtime_renderer = [ordered]@{
        path = $rendererTracePath
        exists = Test-Path $rendererTracePath
        tail = @(Read-TraceTail -Path $rendererTracePath)
      }
      runtime_input_backend = Read-LatestPatternTail -Pattern "runtime-input-backend-*.log"
      wndproc_input = Read-LatestPatternTail -Pattern "wndproc-input-*.log"
    }
    browser_stdout_tail = @(Read-TraceTail -Path $browserOut)
    browser_stderr_tail = @(Read-TraceTail -Path $browserErr)
  } | ConvertTo-Json -Depth 7
}

if ($failure) {
  exit 1
}
