[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8156,
  [string]$InputText = "n",
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$TitleWaitAttempts = 80,
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
  throw "Python was not found in PATH. Install Python or start the reduced Google fixture server separately."
}

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "tabs\TabProbeCommon.ps1")

function Wait-HttpReady([string]$Url, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
      if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) {
        return
      }
    } catch {
    }
    Start-Sleep -Milliseconds $PollMilliseconds
  } while ((Get-Date) -lt $deadline)

  throw "google fixture server did not become ready at $Url"
}

function Wait-FileReady([string]$Path, [int]$Attempts) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    if ((Test-Path -LiteralPath $Path) -and ((Get-Item -LiteralPath $Path).Length -gt 0)) {
      return $true
    }
  }
  return $false
}

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

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-RepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\form-controls"
$profileRoot = Join-Path $root "profile-google-home-enter-submit"
$browserExe = if ($BrowserExe) { $BrowserExe } elseif (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_BROWSER_EXE)) { $env:LIGHTPANDA_BROWSER_EXE } else { Join-Path $repo "zig-out\bin\lightpanda.exe" }
$fixturePath = "src/browser/tests/page/google_home_title_probe.html"
$fixtureUrl = "http://$Host`:$Port/$fixturePath"
$browserOut = Join-Path $root "google-home-enter-submit.browser.stdout.txt"
$browserErr = Join-Path $root "google-home-enter-submit.browser.stderr.txt"
$serverOut = Join-Path $root "google-home-enter-submit.server.stdout.txt"
$serverErr = Join-Path $root "google-home-enter-submit.server.stderr.txt"
$pngPath = Join-Path $root "google-home-enter-submit.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath $browserExe)) {
  throw "headed browser binary not found: $browserExe"
}

cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
$originalAppData = $env:APPDATA
$originalLocalAppData = $env:LOCALAPPDATA
$probeEnv = Get-TabProbeEnvironment $profileRoot
$env:APPDATA = $probeEnv.APPDATA
$env:LOCALAPPDATA = $probeEnv.LOCALAPPDATA

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

try {
  $python = Resolve-PythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m", "http.server", $Port, "--bind", $Host)) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  Wait-HttpReady -Url $fixtureUrl -TimeoutSeconds $ServerReadyTimeoutSeconds
  $ready = $true

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "960", "--window_height", "720", "--screenshot_png", $pngPath, $fixtureUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-FileReady -Path $pngPath -Attempts $WindowReadyAttempts
  if (-not $pngReady) { throw "google fixture screenshot did not become ready" }

  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts
  if ($hwnd -eq [IntPtr]::Zero) { throw "google fixture window handle not found" }

  Show-SmokeWindow $hwnd
  $titleBefore = Get-SmokeWindowTitle $hwnd

  $typeResult = Try-TypeIntoFixture $hwnd $InputText
  if (-not $typeResult) { throw "google fixture did not accept typed text" }
  $titleAfterType = $typeResult.title
  $typedWorked = $true
  $usedClickFallback = $typeResult.click
  $usedTabFallback = $typeResult.tab

  Send-SmokeEnter
  $titleAfterEnterKeydown = Wait-ForTitleLike $hwnd ("KEYDOWN:{0}:13:13*" -f $InputText) $TitleWaitAttempts $PollMilliseconds
  $enterKeydownWorked = $null -ne $titleAfterEnterKeydown
  if (-not $enterKeydownWorked) { throw "Enter did not reach the focused query input before submit" }

  $titleAfterSubmit = Wait-ForTitleLike $hwnd ("SUBMIT:{0}|*" -f $InputText) $TitleWaitAttempts $PollMilliseconds
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) { throw "Enter did not submit the reduced Google fixture" }
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
    input_text = $InputText
    fixture_url = $fixtureUrl
    server_ready_timeout_seconds = $ServerReadyTimeoutSeconds
    window_ready_attempts = $WindowReadyAttempts
    title_wait_attempts = $TitleWaitAttempts
    poll_milliseconds = $PollMilliseconds
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
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
