[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8168,
  [string]$InputText = "lightpanda",
  [int]$QueryClientX = 212,
  [int]$QueryClientY = 232,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$TitleWaitAttempts = 80,
  [int]$TabFocusAttempts = 12,
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
  throw "Python was not found in PATH. Install Python or start the Google homepage fixture server separately."
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

  throw "google homepage probe server did not become ready at $Url"
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

function Wait-TitleNeedle([int]$ProcessId, [string]$Needle, [int]$Attempts) {
  return Wait-TabTitle -ProcessId $ProcessId -Needle $Needle -Attempts $Attempts
}

function Focus-GoogleQueryInput([IntPtr]$Hwnd, [int]$ProcessId, [int]$X, [int]$Y, [int]$TabAttempts, [int]$TitleAttempts) {
  $title = $null
  [void](Invoke-SmokeClientClick -Hwnd $Hwnd -X $X -Y $Y)
  $title = Wait-TitleNeedle -ProcessId $ProcessId -Needle "A=INPUT:q::1" -Attempts $TitleAttempts
  if ($title) {
    return @{
      title = $title
      method = "click"
      tabs_used = 0
    }
  }

  for ($tab = 1; $tab -le $TabAttempts; $tab++) {
    Send-SmokeTab
    $title = Wait-TitleNeedle -ProcessId $ProcessId -Needle "A=INPUT:q::1" -Attempts 6
    if ($title) {
      return @{
        title = $title
        method = "tab"
        tabs_used = $tab
      }
    }
  }

  return @{
    title = $null
    method = "unfocused"
    tabs_used = $TabAttempts
  }
}

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-RepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\google-home"
$profileRoot = Join-Path $root "profile-google-home-title"
$browserExe = if ($BrowserExe) { $BrowserExe } elseif (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_BROWSER_EXE)) { $env:LIGHTPANDA_BROWSER_EXE } else { Join-Path $repo "zig-out\bin\lightpanda.exe" }
$browserOut = Join-Path $root "google-home-title.browser.stdout.txt"
$browserErr = Join-Path $root "google-home-title.browser.stderr.txt"
$serverOut = Join-Path $root "google-home-title.server.stdout.txt"
$serverErr = Join-Path $root "google-home-title.server.stderr.txt"
$pngPath = Join-Path $root "google-home-title.before.png"
$probePath = "/src/browser/tests/page/google_home_title_probe.html"
$probeUrl = "http://$Host`:$Port$probePath"

New-Item -ItemType Directory -Force -Path $root | Out-Null
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath $browserExe)) {
  throw "headed browser binary not found: $browserExe"
}
if (-not (Test-Path -LiteralPath (Join-Path $repo "src\browser\tests\page\google_home_title_probe.html"))) {
  throw "google homepage fixture not found under src\\browser\\tests\\page"
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
$fixtureLoaded = $false
$focusWorked = $false
$typedWorked = $false
$submittedWorked = $false
$focusMethod = $null
$tabsUsed = 0
$titleBefore = $null
$titleReady = $null
$titleAfterFocus = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$finalTitle = $null
$failure = $null

try {
  $python = Resolve-PythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m", "http.server", $Port, "--bind", $Host)) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  Wait-HttpReady -Url $probeUrl -TimeoutSeconds $ServerReadyTimeoutSeconds
  $ready = $true

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-FileReady -Path $pngPath -Attempts $WindowReadyAttempts
  if (-not $pngReady) { throw "google homepage probe screenshot did not become ready" }

  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts
  if ($hwnd -eq [IntPtr]::Zero) { throw "google homepage probe window handle not found" }

  Show-SmokeWindow $hwnd
  $titleBefore = Get-SmokeWindowTitle $hwnd
  $titleReady = Wait-TitleNeedle -ProcessId $browser.Id -Needle "Q=INPUT:q::1" -Attempts $TitleWaitAttempts
  $fixtureLoaded = $null -ne $titleReady
  if (-not $fixtureLoaded) { throw "google homepage probe did not bind the query input fixture" }

  $focusResult = Focus-GoogleQueryInput -Hwnd $hwnd -ProcessId $browser.Id -X $QueryClientX -Y $QueryClientY -TabAttempts $TabFocusAttempts -TitleAttempts 12
  $titleAfterFocus = $focusResult.title
  $focusMethod = $focusResult.method
  $tabsUsed = $focusResult.tabs_used
  $focusWorked = $null -ne $titleAfterFocus
  if (-not $focusWorked) { throw "google homepage probe did not focus the query input" }

  Send-SmokeText $InputText
  $titleAfterType = Wait-TitleNeedle -ProcessId $browser.Id -Needle "TYPED:$InputText" -Attempts $TitleWaitAttempts
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "google homepage probe did not record typed query text" }

  Send-SmokeEnter
  $titleAfterSubmit = Wait-TitleNeedle -ProcessId $browser.Id -Needle "SUBMIT:$InputText" -Attempts $TitleWaitAttempts
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) { throw "google homepage probe did not observe query submit on Enter" }
} catch {
  $failure = $_.Exception.Message
} finally {
  if ($browser) {
    $hwnd = Get-TabWindowHandle $browser.Id
    if ($hwnd -ne [IntPtr]::Zero) {
      $finalTitle = Get-SmokeWindowTitle $hwnd
    }
  }

  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }
  $env:APPDATA = $originalAppData
  $env:LOCALAPPDATA = $originalLocalAppData

  [ordered]@{
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    fixture_loaded = $fixtureLoaded
    focus_worked = $focusWorked
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    focus_method = $focusMethod
    tabs_used = $tabsUsed
    click_client = [ordered]@{ x = $QueryClientX; y = $QueryClientY }
    probe_url = $probeUrl
    title_before = $titleBefore
    title_ready = $titleReady
    title_after_focus = $titleAfterFocus
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    final_title = $finalTitle
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
