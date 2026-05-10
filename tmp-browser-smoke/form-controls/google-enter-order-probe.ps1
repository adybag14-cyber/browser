[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8154,
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
  throw "Python was not found in PATH. Install Python or start the form-controls probe server separately."
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

  throw "google enter order probe server did not become ready at $Url"
}

function Get-SubmitEventRecord([string]$LogPath, [string]$ExpectedText) {
  if (-not (Test-Path -LiteralPath $LogPath)) {
    return $null
  }

  $needle = "GOOGLE_ENTER_SUBMIT q=$ExpectedText "
  $matches = @(
    Get-Content -LiteralPath $LogPath | Where-Object { $_ -like "*$needle*" }
  )
  if ($matches.Count -eq 0) {
    return $null
  }

  $line = $matches[-1]
  $match = [regex]::Match($line, "GOOGLE_ENTER_SUBMIT q=(?<query>[^ ]*) phase=(?<phase>[^ ]*) events=(?<events>.*)$")
  if (-not $match.Success) {
    throw "google enter order probe could not parse the submit event record"
  }

  return @{
    Line = $line
    Query = $match.Groups["query"].Value
    Phase = $match.Groups["phase"].Value
    Events = $match.Groups["events"].Value
  }
}

function Assert-EventSequence([string]$Events, [string]$InputText) {
  $parts = @($Events -split ",")
  $typedEvent = "IN:$InputText"
  $keydownEvent = "KD:Enter:$InputText"
  $keypressEvent = "KP:Enter:$InputText"
  $submitEvent = "SUBMIT:$InputText"

  $typedIndex = [Array]::IndexOf($parts, $typedEvent)
  $keydownIndex = [Array]::IndexOf($parts, $keydownEvent)
  $keypressIndex = [Array]::IndexOf($parts, $keypressEvent)
  $submitIndex = [Array]::IndexOf($parts, $submitEvent)

  if ($typedIndex -lt 0) { throw "google enter order probe did not observe the typed input event" }
  if ($keydownIndex -lt 0) { throw "google enter order probe did not observe the Enter keydown event" }
  if ($keypressIndex -lt 0) { throw "google enter order probe did not observe the Enter keypress event" }
  if ($submitIndex -lt 0) { throw "google enter order probe did not observe the submit event" }
  if ($typedIndex -gt $keydownIndex) { throw "google enter order probe saw keydown before the input value was committed" }
  if ($keydownIndex -gt $keypressIndex) { throw "google enter order probe saw keypress before keydown" }
  if ($keypressIndex -gt $submitIndex) { throw "google enter order probe saw submit before keypress" }
}

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "tabs\TabProbeCommon.ps1")

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
$probeUrl = "http://$Host`:$Port/google-enter-order.html"
$typedTitleNeedle = "Google Enter VALUE:$InputText"
$submitTitleNeedle = "Submitted $InputText"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath $browserExe)) {
  throw "headed browser binary not found: $browserExe"
}
if (-not (Test-Path -LiteralPath $serverScript)) {
  throw "form-controls probe server script not found: $serverScript"
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
$titleBefore = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$typedWorked = $false
$submittedWorked = $false
$submitPhase = $null
$submitEvents = $null
$submitRecord = $null
$failure = $null

try {
  $python = Resolve-PythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port, $Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  Wait-HttpReady -Url "http://$Host`:$Port/ping" -TimeoutSeconds $ServerReadyTimeoutSeconds
  $ready = $true

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "460", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-FileReady -Path $pngPath -Attempts $WindowReadyAttempts
  if (-not $pngReady) { throw "google enter order probe screenshot did not become ready" }

  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts
  if ($hwnd -eq [IntPtr]::Zero) { throw "google enter order probe window handle not found" }

  Show-SmokeWindow $hwnd
  $titleBefore = Get-SmokeWindowTitle $hwnd

  Send-SmokeText $InputText
  $titleAfterType = Wait-TabTitle -ProcessId $browser.Id -Needle $typedTitleNeedle -Attempts $TitleWaitAttempts
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "google enter order probe did not commit the typed query" }

  Send-SmokeEnter
  $titleAfterSubmit = Wait-TabTitle -ProcessId $browser.Id -Needle $submitTitleNeedle -Attempts $TitleWaitAttempts

  $submitRecord = Get-SubmitEventRecord -LogPath $serverErr -ExpectedText $InputText
  if ($null -eq $submitRecord) { throw "google enter order probe did not capture the submit event record" }

  $submitPhase = $submitRecord.Phase
  $submitEvents = $submitRecord.Events
  if ($submitRecord.Query -ne $InputText) {
    throw "google enter order probe submitted the wrong query text"
  }
  if ($submitPhase -ne "keypress") {
    throw "google enter order probe submitted during '$submitPhase' instead of 'keypress'"
  }
  Assert-EventSequence -Events $submitEvents -InputText $InputText
  $submittedWorked = ($null -ne $titleAfterSubmit) -or ($null -ne $submitRecord)
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
    mode = "google-enter-order"
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
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    submit_phase = $submitPhase
    submit_events = $submitEvents
    submit_record = if ($submitRecord) { $submitRecord.Line } else { $null }
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
