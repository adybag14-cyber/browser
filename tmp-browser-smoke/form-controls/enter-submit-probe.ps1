$ErrorActionPreference = "Stop"
param(
  [switch]$DeferredEnter
)

$port = 8154

function Resolve-RepoRoot([string]$StartPath) {
  if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    return $env:LIGHTPANDA_REPO_ROOT
  }

  $cursor = [System.IO.Path]::GetFullPath($StartPath)
  while ($true) {
    if (Test-Path (Join-Path $cursor "build.zig")) {
      return $cursor
    }

    $parent = Split-Path $cursor -Parent
    if ([string]::IsNullOrEmpty($parent) -or $parent -eq $cursor) {
      throw "Could not resolve the Lightpanda repo root from $StartPath. Set LIGHTPANDA_REPO_ROOT to override."
    }
    $cursor = $parent
  }
}

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

$repo = Resolve-RepoRoot $PSScriptRoot
$root = Join-Path $repo "tmp-browser-smoke\form-controls"
$browserExe = if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_BROWSER_EXE)) { $env:LIGHTPANDA_BROWSER_EXE } else { Join-Path $repo "zig-out\bin\lightpanda.exe" }
$serverScript = Join-Path $root "form_server.py"
$browserOut = Join-Path $root "enter-submit.browser.stdout.txt"
$browserErr = Join-Path $root "enter-submit.browser.stderr.txt"
$serverOut = Join-Path $root "enter-submit.server.stdout.txt"
$serverErr = Join-Path $root "enter-submit.server.stderr.txt"
$pngPath = Join-Path $root "enter-submit.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

$pagePath = if ($DeferredEnter) { "/deferred-submit.html" } else { "/submit.html" }
$typedTitlePattern = if ($DeferredEnter) { "Deferred Enter Typed Q*" } else { "Enter Submit Q*" }
$pendingTitlePattern = if ($DeferredEnter) { "Deferred Enter Pending Q*" } else { $null }
$serverSubmitPattern = if ($DeferredEnter) { 'FORM_SUBMIT /submitted\.html\?q=Q' } else { 'FORM_SUBMIT /submitted\.html\?name=Q' }

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$titleBefore = $null
$titleAfterType = $null
$titleAfterPending = $null
$titleAfterSubmit = $null
$typedWorked = $false
$pendingWorked = $false
$submittedWorked = $false
$serverSawSubmit = $false
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
  $server = Start-Process -FilePath "python" -ArgumentList $serverScript,$port -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/ping" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "enter submit probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port$pagePath","--window_width","420","--window_height","520","--screenshot_png",$pngPath -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "enter submit probe screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "enter submit probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $titleBefore = Get-SmokeWindowTitle $hwnd

  Send-SmokeText "Q"
  $titleAfterType = Wait-ForTitleLike $hwnd $typedTitlePattern
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "autofocus input did not receive typed text" }

  Send-SmokeEnter
  if ($pendingTitlePattern) {
    $titleAfterPending = Wait-ForTitleLike $hwnd $pendingTitlePattern
    $pendingWorked = $null -ne $titleAfterPending
  }
  $titleAfterSubmit = Wait-ForTitleLike $hwnd "Submitted Q*"
  if (Test-Path $serverErr) {
    $serverLog = Get-Content $serverErr -Raw
    $serverSawSubmit = $serverLog -match $serverSubmitPattern
  }
  $submittedWorked = ($null -ne $titleAfterSubmit) -or $serverSawSubmit
  if (-not $submittedWorked) { throw "pressing Enter did not submit the form" }
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
    mode = if ($DeferredEnter) { "deferred-enter" } else { "default-enter" }
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    title_before = $titleBefore
    title_after_type = $titleAfterType
    title_after_pending = $titleAfterPending
    title_after_submit = $titleAfterSubmit
    typed_worked = $typedWorked
    pending_title_seen = $pendingWorked
    submitted_worked = $submittedWorked
    server_saw_submit = $serverSawSubmit
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
