[CmdletBinding()]
param(
  [switch]$DeferredEnter,
  [switch]$GoogleEnterOrder,
  [switch]$ClickFocus,
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8154,
  [string]$InputText = "Q",
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$TitleWaitAttempts = 80,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($DeferredEnter -and $GoogleEnterOrder) {
  throw "Choose at most one specialized enter-submit mode."
}

if ($ClickFocus -and -not $GoogleEnterOrder) {
  throw "ClickFocus currently supports only -GoogleEnterOrder."
}

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

  throw "enter submit probe server did not become ready at $Url"
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

$probeMode = if ($GoogleEnterOrder) {
  "google-enter-order"
} elseif ($DeferredEnter) {
  "deferred-enter"
} else {
  "default-enter"
}

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-RepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\form-controls"
$profileRoot = Join-Path $root ("profile-" + $probeMode)
$artifactStem = switch ($probeMode) {
  "deferred-enter" { "enter-submit.deferred" }
  "google-enter-order" { "enter-submit.google-order" }
  default { "enter-submit.default" }
}
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

$pagePath = switch ($probeMode) {
  "deferred-enter" { "/deferred-submit.html" }
  "google-enter-order" { "/google-enter-order.html" }
  default { "/submit.html" }
}
$probeUrl = "http://$Host`:$Port$pagePath"
$typedTitleNeedle = switch ($probeMode) {
  "deferred-enter" { "Deferred Enter Typed $InputText" }
  "google-enter-order" { "Google Enter VALUE:$InputText" }
  default { "Enter Submit $InputText" }
}
$focusTitleNeedle = if ($probeMode -eq "google-enter-order") { "Google Enter Focused" } else { $null }
$pendingTitleNeedle = if ($probeMode -eq "deferred-enter") { "Deferred Enter Pending $InputText" } else { $null }
$submitTitleNeedle = "Submitted $InputText"
$serverSubmitPattern = switch ($probeMode) {
  "deferred-enter" { "FORM_SUBMIT /submitted\.html\?q=$([regex]::Escape($InputText))" }
  "google-enter-order" { "FORM_SUBMIT /submitted\.html\?submit_phase=.*\bq=$([regex]::Escape($InputText))" }
  default { "FORM_SUBMIT /submitted\.html\?name=$([regex]::Escape($InputText))" }
}
$googleServerPattern = if ($probeMode -eq "google-enter-order") {
  "GOOGLE_ENTER_SUBMIT q=$([regex]::Escape($InputText)) phase=([^ ]*) active_name=([^ ]*) active_id=([^ ]*) selection=([^ ]*) events=(.*)"
} else {
  $null
}
$expectedGoogleSelection = "{0}-{0}" -f $InputText.Length

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
$titleAfterPending = $null
$titleAfterSubmit = $null
$focusWorked = $false
$typedWorked = $false
$pendingWorked = $false
$submittedWorked = $false
$serverSawSubmit = $false
$googleSubmitPhase = $null
$googleActiveName = $null
$googleActiveId = $null
$googleSelection = $null
$googleEventLog = $null
$failure = $null

try {
  $python = Resolve-PythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port, $Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  Wait-HttpReady -Url "http://$Host`:$Port/ping" -TimeoutSeconds $ServerReadyTimeoutSeconds
  $ready = $true

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-FileReady -Path $pngPath -Attempts $WindowReadyAttempts
  if (-not $pngReady) { throw "enter submit probe screenshot did not become ready" }

  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts
  if ($hwnd -eq [IntPtr]::Zero) { throw "enter submit probe window handle not found" }

  Show-SmokeWindow $hwnd
  $titleBefore = Get-SmokeWindowTitle $hwnd

  if ($focusTitleNeedle) {
    if ($ClickFocus) {
      [void](Invoke-SmokeClientClick -Hwnd $hwnd -X 170 -Y 82)
    } else {
      Send-SmokeTab
    }
    $titleAfterFocus = Wait-TabTitle -ProcessId $browser.Id -Needle $focusTitleNeedle -Attempts $TitleWaitAttempts
    $focusWorked = $null -ne $titleAfterFocus
    if (-not $focusWorked) {
      if ($ClickFocus) {
        throw "google enter-order page did not focus the query input after the click-first repro step"
      }
      throw "google enter-order page did not focus the query input"
    }
  }

  Send-SmokeText $InputText
  $titleAfterType = Wait-TabTitle -ProcessId $browser.Id -Needle $typedTitleNeedle -Attempts $TitleWaitAttempts
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "autofocus input did not receive typed text" }

  Send-SmokeEnter
  if ($pendingTitleNeedle) {
    $titleAfterPending = Wait-TabTitle -ProcessId $browser.Id -Needle $pendingTitleNeedle -Attempts $TitleWaitAttempts
    $pendingWorked = $null -ne $titleAfterPending
  }
  $titleAfterSubmit = Wait-TabTitle -ProcessId $browser.Id -Needle $submitTitleNeedle -Attempts $TitleWaitAttempts
  if (Test-Path -LiteralPath $serverErr) {
    $serverLog = Get-Content -LiteralPath $serverErr -Raw
    $serverSawSubmit = $serverLog -match $serverSubmitPattern
    if ($googleServerPattern -and $serverLog -match $googleServerPattern) {
      $googleSubmitPhase = $Matches[1]
      $googleActiveName = $Matches[2]
      $googleActiveId = $Matches[3]
      $googleSelection = $Matches[4]
      $googleEventLog = $Matches[5]
    }
  }
  $submittedWorked = ($null -ne $titleAfterSubmit) -or $serverSawSubmit
  if (-not $submittedWorked) { throw "pressing Enter did not submit the form" }

  if ($probeMode -eq "google-enter-order") {
    if ([string]::IsNullOrWhiteSpace($googleSubmitPhase)) {
      throw "google enter-order probe did not capture submit phase telemetry"
    }
    if ($googleSubmitPhase -eq "keydown") {
      throw "google enter-order probe observed submit at keydown instead of after keypress"
    }
    if ($googleSubmitPhase -ne "keypress") {
      throw "google enter-order probe observed submit phase '$googleSubmitPhase' instead of keypress"
    }
    if ([string]::IsNullOrWhiteSpace($googleActiveName) -or $googleActiveName -eq "-") {
      throw "google enter-order probe did not capture the active field name at submit time"
    }
    if ($googleActiveName -ne "q" -and $googleActiveId -ne "q") {
      throw "google enter-order probe lost the query input as the active submit target"
    }
    if ([string]::IsNullOrWhiteSpace($googleSelection) -or $googleSelection -eq "-" -or $googleSelection -ne $expectedGoogleSelection) {
      throw "google enter-order probe did not preserve the expected caret position at submit time"
    }
    if ([string]::IsNullOrWhiteSpace($googleEventLog) -or $googleEventLog -notlike "*KP:Enter:$InputText*" -or $googleEventLog -notlike "*SUBMIT:$InputText*") {
      throw "google enter-order probe did not capture the expected Enter event trail"
    }
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
    mode = $probeMode
    click_focus = $ClickFocus
    repo_root = $repo
    browser_exe = $browserExe
    host = $Host
    port = $Port
    probe_url = $probeUrl
    input_text = $InputText
    server_ready_timeout_seconds = $ServerReadyTimeoutSeconds
    window_ready_attempts = $WindowReadyAttempts
    title_wait_attempts = $TitleWaitAttempts
    poll_milliseconds = $PollMilliseconds
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    title_before = $titleBefore
    title_after_focus = $titleAfterFocus
    title_after_type = $titleAfterType
    title_after_pending = $titleAfterPending
    title_after_submit = $titleAfterSubmit
    focus_worked = $focusWorked
    typed_worked = $typedWorked
    pending_title_seen = $pendingWorked
    submitted_worked = $submittedWorked
    server_saw_submit = $serverSawSubmit
    google_submit_phase = $googleSubmitPhase
    google_active_name = $googleActiveName
    google_active_id = $googleActiveId
    google_selection = $googleSelection
    google_event_log = $googleEventLog
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
