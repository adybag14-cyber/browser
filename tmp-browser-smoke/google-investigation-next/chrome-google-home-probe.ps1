$ErrorActionPreference = "Stop"

$port = 8158

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
$root = Join-Path $repo "tmp-browser-smoke\google-investigation-next"
$browserExe = if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_BROWSER_EXE)) { $env:LIGHTPANDA_BROWSER_EXE } else { Join-Path $repo "zig-out\bin\lightpanda.exe" }
$serverScript = Join-Path $root "google_home_server.py"
$browserOut = Join-Path $root "google-home.browser.stdout.txt"
$browserErr = Join-Path $root "google-home.browser.stderr.txt"
$serverOut = Join-Path $root "google-home.server.stdout.txt"
$serverErr = Join-Path $root "google-home.server.stderr.txt"
$pngPath = Join-Path $root "google-home.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$boundTitle = $null
$titleBefore = $null
$focusedTitle = $null
$typedTitle = $null
$submittedTitle = $null
$searchRequested = $false
$focusWorked = $false
$typedWorked = $false
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

function Try-FocusQuery([IntPtr]$Hwnd) {
  $focusPattern = "FOCUSED*"
  $activePattern = "*A=INPUT:q::*"

  $title = Wait-ForTitleLike $Hwnd $focusPattern 3 200
  if ($title) { return $title }

  for ($i = 0; $i -lt 3; $i++) {
    Send-SmokeTab
    $title = Wait-ForTitleLike $Hwnd $focusPattern 5 200
    if ($title) { return $title }
    $title = Wait-ForTitleLike $Hwnd $activePattern 2 150
    if ($title) { return $title }
  }

  foreach ($coords in @(@{ X = 480; Y = 345 }, @{ X = 500; Y = 345 }, @{ X = 460; Y = 345 })) {
    [void](Invoke-SmokeClientClick $Hwnd $coords.X $coords.Y)
    $title = Wait-ForTitleLike $Hwnd $focusPattern 5 200
    if ($title) { return $title }
    $title = Wait-ForTitleLike $Hwnd $activePattern 2 150
    if ($title) { return $title }
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

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google-home.html","--window_width","960","--window_height","720","--screenshot_png",$pngPath -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 80; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google home probe screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 80; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google home probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $titleBefore = Get-SmokeWindowTitle $hwnd
  $boundTitle = Wait-ForTitleLike $hwnd "BOUND*" 12 250
  if (-not $boundTitle) { throw "google home fixture never bound the query input" }

  $focusedTitle = Try-FocusQuery $hwnd
  $focusWorked = $null -ne $focusedTitle
  if (-not $focusWorked) { throw "google home fixture never focused the query input" }

  Send-SmokeText "Q"
  $typedTitle = Wait-ForTitleLike $hwnd "TYPED:Q*" 12 250
  $typedWorked = $null -ne $typedTitle
  if (-not $typedWorked) { throw "google home fixture did not reflect typed text" }

  Send-SmokeEnter
  $submittedTitle = Wait-ForTitleLike $hwnd "SUBMIT:Q*" 12 250
  if (Test-Path $serverErr) {
    $serverLog = Get-Content $serverErr -Raw
    $searchRequested = $serverLog -match 'SEARCH /search\?q=Q'
  }
  $submittedWorked = ($null -ne $submittedTitle) -or $searchRequested
  if (-not $submittedWorked) { throw "google home fixture did not submit the query on Enter" }
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
    title_before = $titleBefore
    bound_title = $boundTitle
    focused_title = $focusedTitle
    typed_title = $typedTitle
    submitted_title = $submittedTitle
    focus_worked = $focusWorked
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    search_requested = $searchRequested
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
