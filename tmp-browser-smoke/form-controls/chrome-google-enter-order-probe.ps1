[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8154,
  [string]$InputText = "QZ",
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
  throw "Python was not found in PATH. Install Python or start the form-controls probe server separately."
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

  throw "google enter-order probe server did not become ready at $Url"
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

function Wait-GoogleSubmitResult {
  param(
    [int]$ProcessId,
    [string]$ServerLogPath,
    [string]$InputText,
    [int]$Attempts
  )

  $escapedInput = [regex]::Escape($InputText)
  $result = [ordered]@{
    title = $null
    title_phase = $null
    server_phase = $null
    server_events = $null
    server_saw_submit = $false
  }

  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds

    $proc = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $title = Get-SmokeWindowTitle ([IntPtr]$proc.MainWindowHandle)
      if ($title -like "*Google Enter SUBMIT:$InputText*") {
        $result.title = $title
        if ($title -match "\|(?<phase>[^|]+)$") {
          $result.title_phase = $matches["phase"]
        }
      }
    }

    if (Test-Path -LiteralPath $ServerLogPath) {
      $serverLog = Get-Content -LiteralPath $ServerLogPath -Raw
      if ($serverLog -match "GOOGLE_ENTER_SUBMIT q=$escapedInput phase=(?<phase>\w+) events=(?<events>[^\r\n]*)") {
        $result.server_phase = $matches["phase"]
        $result.server_events = $matches["events"]
        $result.server_saw_submit = $true
      }
    }

    if ($result.title_phase -eq "keypress" -or $result.server_phase -eq "keypress") {
      return $result
    }
    if (($null -ne $result.title_phase -and $result.title_phase -ne "keypress") -or
        ($null -ne $result.server_phase -and $result.server_phase -ne "keypress")) {
      return $result
    }
  }

  return $result
}

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-RepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\form-controls"
$profileRoot = Join-Path $root "profile-google-enter-order"
$artifactStem = "google-enter-order"
$browserExe = if ($BrowserExe) { $BrowserExe } elseif (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_BROWSER_EXE)) { $env:LIGHTPANDA_BROWSER_EXE } else { Join-Path $repo "zig-out\bin\lightpanda.exe" }
$serverScript = Join-Path $root "form_server.py"
$browserOut = Join-Path $root "$artifactStem.browser.stdout.txt"
$browserErr = Join-Path $root "$artifactStem.browser.stderr.txt"
$serverOut = Join-Path $root "$artifactStem.server.stdout.txt"
$serverErr = Join-Path $root "$artifactStem.server.stderr.txt"
$pngPath = Join-Path $root "$artifactStem.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath $browserExe)) {
  throw "headed browser binary not found: $browserExe"
}
if (-not (Test-Path -LiteralPath $serverScript)) {
  throw "form-controls probe server script not found: $serverScript"
}

$probeUrl = "http://$Host`:$Port/google-enter-order.html"
$typedTitleNeedle = "Google Enter VALUE:$InputText"
$focusedTitleNeedle = "Google Enter Focused"

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
$titleBefore = $null
$titleAfterFocus = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$submitPhase = $null
$submitEvents = $null
$typedWorked = $false
$focusWorked = $false
$submittedWorked = $false
$serverSawSubmit = $false
$clickPoint = $null
$failure = $null

try {
  $python = Resolve-PythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port, $Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  Wait-HttpReady -Url "http://$Host`:$Port/ping" -TimeoutSeconds $ServerReadyTimeoutSeconds
  $ready = $true

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "900", "--window_height", "640", "--screenshot_png", $pngPath, $probeUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-FileReady -Path $pngPath -Attempts $WindowReadyAttempts
  if (-not $pngReady) { throw "google enter-order probe screenshot did not become ready" }

  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts
  if ($hwnd -eq [IntPtr]::Zero) { throw "google enter-order probe window handle not found" }

  Show-SmokeWindow $hwnd
  $titleBefore = Get-SmokeWindowTitle $hwnd

  $clickPoint = Invoke-SmokeClientClick $hwnd 170 96
  $titleAfterFocus = Wait-TabTitle -ProcessId $browser.Id -Needle $focusedTitleNeedle -Attempts $TitleWaitAttempts
  $focusWorked = $null -ne $titleAfterFocus
  if (-not $focusWorked) { throw "google enter-order input did not take focus after click" }

  Send-SmokeText $InputText
  $titleAfterType = Wait-TabTitle -ProcessId $browser.Id -Needle $typedTitleNeedle -Attempts $TitleWaitAttempts
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "google enter-order input did not receive typed text" }

  Send-SmokeEnter
  $submitResult = Wait-GoogleSubmitResult -ProcessId $browser.Id -ServerLogPath $serverErr -InputText $InputText -Attempts $TitleWaitAttempts
  $titleAfterSubmit = $submitResult.title
  $submitPhase = if ($submitResult.server_phase) { $submitResult.server_phase } else { $submitResult.title_phase }
  $submitEvents = $submitResult.server_events
  $serverSawSubmit = $submitResult.server_saw_submit
  $submittedWorked = $submitPhase -eq "keypress"
  if (-not $submittedWorked) {
    if ($submitPhase) {
      throw "google enter-order submit phase regressed to $submitPhase"
    }
    throw "google enter-order probe did not observe a submit"
  }
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
    title_after_focus = $titleAfterFocus
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    typed_worked = $typedWorked
    focus_worked = $focusWorked
    submitted_worked = $submittedWorked
    submit_phase = $submitPhase
    submit_events = $submitEvents
    server_saw_submit = $serverSawSubmit
    click_screen = if ($null -ne $clickPoint) { [ordered]@{ x = $clickPoint.X; y = $clickPoint.Y } } else { $null }
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
