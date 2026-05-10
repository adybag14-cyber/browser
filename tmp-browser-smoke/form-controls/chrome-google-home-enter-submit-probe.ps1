[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8155,
  [string]$InputText = "chatgpt",
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 80,
  [int]$TitleWaitAttempts = 40,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

function Resolve-PythonCommand {
  if (Get-Command python -ErrorAction SilentlyContinue) {
    return @{ FileName = "python"; Arguments = @() }
  }
  if (Get-Command py -ErrorAction SilentlyContinue) {
    return @{ FileName = "py"; Arguments = @("-3") }
  }
  throw "Python was not found in PATH. Install Python or start the Google fixture probe server separately."
}

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "tabs\TabProbeCommon.ps1")

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-RepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\form-controls"
$profileRoot = Join-Path $root "profile-google-home-enter-submit"
$browserExe = if ($BrowserExe) { $BrowserExe } elseif (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_BROWSER_EXE)) { $env:LIGHTPANDA_BROWSER_EXE } else { Join-Path $repo "zig-out\bin\lightpanda.exe" }
$serverScript = Join-Path $root "google_fixture_server.py"
$browserOut = Join-Path $root "google-home-enter-submit.browser.stdout.txt"
$browserErr = Join-Path $root "google-home-enter-submit.browser.stderr.txt"
$serverOut = Join-Path $root "google-home-enter-submit.server.stdout.txt"
$serverErr = Join-Path $root "google-home-enter-submit.server.stderr.txt"
$pngPath = Join-Path $root "google-home-enter-submit.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath $browserExe)) {
  throw "headed browser binary not found: $browserExe"
}
if (-not (Test-Path -LiteralPath $serverScript)) {
  throw "google fixture probe server script not found: $serverScript"
}

$probeUrl = "http://$Host`:$Port/google.html"
$originalAppData = $env:APPDATA
$originalLocalAppData = $env:LOCALAPPDATA
$probeEnv = Get-TabProbeEnvironment $profileRoot
$env:APPDATA = $probeEnv.APPDATA
$env:LOCALAPPDATA = $probeEnv.LOCALAPPDATA

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$titleBefore = $null
$titleFocused = $null
$titleAfterType = $null
$titleAfterEnterKeyDown = $null
$titleAfterSubmit = $null
$focusWorked = $false
$typedWorked = $false
$enterKeyDownWorked = $false
$submittedWorked = $false
$serverSawNavigation = $false
$failure = $null

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = $TitleWaitAttempts, [int]$SleepMs = 200) {
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
  $python = Resolve-PythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port, $Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $deadline = (Get-Date).AddSeconds($ServerReadyTimeoutSeconds)
  do {
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://$Host`:$Port/ping" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
    Start-Sleep -Milliseconds $PollMilliseconds
  } while ((Get-Date) -lt $deadline)
  if (-not $ready) { throw "google home enter submit probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","1440","--window_height","900","--screenshot_png",$pngPath,$probeUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google home enter submit probe screenshot did not become ready" }

  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts
  if ($hwnd -eq [IntPtr]::Zero) { throw "google home enter submit probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds ($PollMilliseconds * 2)
  $titleBefore = Get-SmokeWindowTitle $hwnd
  $titleFocused = Wait-ForTitleLike $hwnd "*|A=INPUT:q:*|Q=INPUT:q:*"
  $focusWorked = $null -ne $titleFocused
  if (-not $focusWorked) { throw "google query input did not become active" }

  Send-SmokeText $InputText
  $titleAfterType = Wait-ForTitleLike $hwnd "TYPED:$InputText*"
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "google query input did not receive typed text" }

  Send-SmokeEnter
  $titleAfterEnterKeyDown = Wait-ForTitleLike $hwnd "KEYDOWN:$InputText:13:13*"
  $enterKeyDownWorked = $null -ne $titleAfterEnterKeyDown
  if (-not $enterKeyDownWorked) { throw "google query input did not surface Enter keydown before submit" }

  $titleAfterSubmit = Wait-ForTitleLike $hwnd "SUBMIT:$InputText*"
  if (Test-Path $serverErr) {
    $serverLog = Get-Content $serverErr -Raw
    $serverSawNavigation = $serverLog -match 'GOOGLE_SEARCH '
  }
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) { throw "google query input did not surface submit after Enter" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  $env:APPDATA = $originalAppData
  $env:LOCALAPPDATA = $originalLocalAppData
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    host = $Host
    port = $Port
    probe_url = $probeUrl
    input_text = $InputText
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    title_before = $titleBefore
    title_focused = $titleFocused
    title_after_type = $titleAfterType
    title_after_enter_keydown = $titleAfterEnterKeyDown
    title_after_submit = $titleAfterSubmit
    focus_worked = $focusWorked
    typed_worked = $typedWorked
    enter_keydown_worked = $enterKeyDownWorked
    submitted_worked = $submittedWorked
    server_saw_navigation = $serverSawNavigation
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
