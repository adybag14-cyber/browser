[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8164,
  [string]$InputText = "lightpanda",
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
  throw "Python was not found in PATH. Install Python or start the Google trace probe server separately."
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

  throw "google trace probe server did not become ready at $Url"
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

function Wait-TitleLike([int]$ProcessId, [string]$Needle, [int]$Attempts) {
  if ([string]::IsNullOrWhiteSpace($Needle)) {
    return $null
  }
  return Wait-TabTitle -ProcessId $ProcessId -Needle $Needle -Attempts $Attempts
}

function Convert-TitleState {
  param(
    [string]$Title
  )

  if ([string]::IsNullOrWhiteSpace($Title)) {
    return $null
  }

  $parts = $Title -split '\|'
  $state = [ordered]@{
    raw_title = $Title
    marker = if ($parts.Count -gt 0) { $parts[0] } else { $Title }
  }

  for ($i = 1; $i -lt $parts.Count; $i++) {
    $segment = $parts[$i]
    if ([string]::IsNullOrWhiteSpace($segment)) {
      continue
    }

    $pair = $segment -split '=', 2
    if ($pair.Count -ne 2) {
      $state[("extra_{0}" -f $i)] = $segment
      continue
    }

    $name = switch ($pair[0]) {
      'A' { 'active_element' }
      'Q' { 'query_element' }
      'V' { 'query_value' }
      'S' { 'selection' }
      'E' { 'last_event' }
      default { $pair[0].ToLowerInvariant() }
    }
    $state[$name] = $pair[1]
  }

  return [pscustomobject]$state
}

function Get-TraceArtifactPaths([string]$Root) {
  $artifacts = @()
  $patterns = @(
    "browse-render.log",
    "runtime-renderer.log",
    "session-wait.log",
    "runtime-input-backend-*.log",
    "wndproc-input-*.log"
  )
  foreach ($pattern in $patterns) {
    $artifacts += Get-ChildItem -LiteralPath $Root -Filter $pattern -File -ErrorAction SilentlyContinue |
      Sort-Object FullName |
      ForEach-Object { $_.FullName }
  }
  return $artifacts
}

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "tabs\TabProbeCommon.ps1")

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-RepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\google-investigation-next"
$profileRoot = Join-Path $root "profile-google-home-trace"
$browserExe = if ($BrowserExe) { $BrowserExe } elseif (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_BROWSER_EXE)) { $env:LIGHTPANDA_BROWSER_EXE } else { Join-Path $repo "zig-out\bin\lightpanda.exe" }
$serverScript = Join-Path $root "google_home_server.py"
$browserOut = Join-Path $root "chrome-google-home-enter-trace.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-google-home-enter-trace.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-google-home-enter-trace.server.stdout.txt"
$serverErr = Join-Path $root "chrome-google-home-enter-trace.server.stderr.txt"
$pngPath = Join-Path $root "chrome-google-home-enter-trace.before.png"
$probeUrl = "http://$Host`:$Port/google-home.html"
$inputEscaped = [System.Management.Automation.WildcardPattern]::Escape($InputText)
$submitPattern = "SEARCH /search\?q=$([regex]::Escape($InputText.Replace(' ', '+')))"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue
Get-ChildItem -LiteralPath $root -Filter "*.log" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath $browserExe)) {
  throw "headed browser binary not found: $browserExe"
}
if (-not (Test-Path -LiteralPath $serverScript)) {
  throw "google trace probe server script not found: $serverScript"
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
$focusedWorked = $false
$typedWorked = $false
$submittedWorked = $false
$serverSawSubmit = $false
$titleBefore = $null
$titleBeforeState = $null
$titleAfterFocus = $null
$titleAfterFocusState = $null
$titleAfterType = $null
$titleAfterTypeState = $null
$titleAfterKeydown = $null
$titleAfterKeydownState = $null
$titleAfterKeypress = $null
$titleAfterKeypressState = $null
$titleAfterDocKeypress = $null
$titleAfterDocKeypressState = $null
$titleAfterSubmit = $null
$titleAfterSubmitState = $null
$serverReadyAtUtc = $null
$screenshotReadyAtUtc = $null
$windowReadyAtUtc = $null
$focusObservedAtUtc = $null
$inputSentAtUtc = $null
$typedObservedAtUtc = $null
$enterSentAtUtc = $null
$keydownObservedAtUtc = $null
$keypressObservedAtUtc = $null
$docKeypressObservedAtUtc = $null
$submitObservedAtUtc = $null
$titleAtInputSend = $null
$titleAtInputSendState = $null
$titleAtEnterSend = $null
$titleAtEnterSendState = $null
$failureStage = "server_ready"
$failure = $null

try {
  $python = Resolve-PythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port, $Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  Wait-HttpReady -Url "http://$Host`:$Port/ping" -TimeoutSeconds $ServerReadyTimeoutSeconds
  $ready = $true
  $serverReadyAtUtc = (Get-Date).ToUniversalTime().ToString("o")
  $failureStage = "screenshot_ready"

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "960", "--window_height", "720", "--screenshot_png", $pngPath, $probeUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-FileReady -Path $pngPath -Attempts $WindowReadyAttempts
  if (-not $pngReady) { throw "google trace probe screenshot did not become ready" }
  $screenshotReadyAtUtc = (Get-Date).ToUniversalTime().ToString("o")
  $failureStage = "window_handle"

  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts
  if ($hwnd -eq [IntPtr]::Zero) { throw "google trace probe window handle not found" }
  $windowReadyAtUtc = (Get-Date).ToUniversalTime().ToString("o")
  $failureStage = "focus_marker"

  Show-SmokeWindow $hwnd
  $titleBefore = Get-SmokeWindowTitle $hwnd
  $titleBeforeState = Convert-TitleState $titleBefore

  Invoke-SmokeClientClick -Hwnd $hwnd -X 520 -Y 408 | Out-Null
  $titleAfterFocus = Wait-TitleLike -ProcessId $browser.Id -Needle "FOCUSED|" -Attempts $TitleWaitAttempts
  $titleAfterFocusState = Convert-TitleState $titleAfterFocus
  $focusedWorked = $null -ne $titleAfterFocus
  if (-not $focusedWorked) { throw "google trace probe did not focus the search input" }
  $focusObservedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
  $failureStage = "typed_marker"

  Send-SmokeAsciiText $InputText
  $inputSentAtUtc = (Get-Date).ToUniversalTime().ToString("o")
  $titleAtInputSend = $titleAfterFocus
  $titleAtInputSendState = $titleAfterFocusState
  $titleAfterType = Wait-TitleLike -ProcessId $browser.Id -Needle "TYPED:$inputEscaped" -Attempts $TitleWaitAttempts
  $titleAfterTypeState = Convert-TitleState $titleAfterType
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "google trace probe did not observe typed input text" }
  $typedObservedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
  $failureStage = "submit_marker"

  Send-SmokeEnter
  $enterSentAtUtc = (Get-Date).ToUniversalTime().ToString("o")
  $titleAtEnterSend = $titleAfterType
  $titleAtEnterSendState = $titleAfterTypeState
  $titleAfterKeydown = Wait-TitleLike -ProcessId $browser.Id -Needle "KEYDOWN:$inputEscaped:13:13" -Attempts 20
  $titleAfterKeydownState = Convert-TitleState $titleAfterKeydown
  if ($null -ne $titleAfterKeydown) {
    $keydownObservedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
  }
  $titleAfterKeypress = Wait-TitleLike -ProcessId $browser.Id -Needle "KEYPRESS:Enter:$inputEscaped" -Attempts 20
  $titleAfterKeypressState = Convert-TitleState $titleAfterKeypress
  if ($null -ne $titleAfterKeypress) {
    $keypressObservedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
  }
  $titleAfterDocKeypress = Wait-TitleLike -ProcessId $browser.Id -Needle "DOC-KP:" -Attempts 5
  $titleAfterDocKeypressState = Convert-TitleState $titleAfterDocKeypress
  if ($null -ne $titleAfterDocKeypress) {
    $docKeypressObservedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
  }
  $titleAfterSubmit = Wait-TitleLike -ProcessId $browser.Id -Needle "SUBMIT:$inputEscaped" -Attempts $TitleWaitAttempts
  $titleAfterSubmitState = Convert-TitleState $titleAfterSubmit
  if ($null -ne $titleAfterSubmit) {
    $submitObservedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
  }
  if (Test-Path -LiteralPath $serverErr) {
    $serverLog = Get-Content -LiteralPath $serverErr -Raw
    $serverSawSubmit = $serverLog -match $submitPattern
  }
  if ($serverSawSubmit -and $null -eq $submitObservedAtUtc) {
    $submitObservedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
  }
  $submittedWorked = ($null -ne $titleAfterSubmit) -or $serverSawSubmit
  if (-not $submittedWorked) { throw "google trace probe did not reach the submitted page" }
  $failureStage = $null
} catch {
  $failure = $_.Exception.Message
} finally {
  $traceArtifacts = Get-TraceArtifactPaths -Root $root
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  $env:APPDATA = $originalAppData
  $env:LOCALAPPDATA = $originalLocalAppData
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }
  if ($browser -and $browser.HasExited -and -not $submittedWorked -and $failureStage -ne $null) {
    $failureStage = "process_exit"
  }

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
    focused_worked = $focusedWorked
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    server_saw_submit = $serverSawSubmit
    server_ready_at_utc = $serverReadyAtUtc
    screenshot_ready_at_utc = $screenshotReadyAtUtc
    window_ready_at_utc = $windowReadyAtUtc
    focus_observed_at_utc = $focusObservedAtUtc
    input_sent_at_utc = $inputSentAtUtc
    typed_observed_at_utc = $typedObservedAtUtc
    enter_sent_at_utc = $enterSentAtUtc
    keydown_observed_at_utc = $keydownObservedAtUtc
    keypress_observed_at_utc = $keypressObservedAtUtc
    doc_keypress_observed_at_utc = $docKeypressObservedAtUtc
    submit_observed_at_utc = $submitObservedAtUtc
    failure_stage = $failureStage
    title_before = $titleBefore
    title_before_state = $titleBeforeState
    title_after_focus = $titleAfterFocus
    title_after_focus_state = $titleAfterFocusState
    title_at_input_send = $titleAtInputSend
    title_at_input_send_state = $titleAtInputSendState
    title_after_type = $titleAfterType
    title_after_type_state = $titleAfterTypeState
    title_at_enter_send = $titleAtEnterSend
    title_at_enter_send_state = $titleAtEnterSendState
    title_after_keydown = $titleAfterKeydown
    title_after_keydown_state = $titleAfterKeydownState
    title_after_keypress = $titleAfterKeypress
    title_after_keypress_state = $titleAfterKeypressState
    title_after_doc_keypress = $titleAfterDocKeypress
    title_after_doc_keypress_state = $titleAfterDocKeypressState
    title_after_submit = $titleAfterSubmit
    title_after_submit_state = $titleAfterSubmitState
    browser_stdout = $browserOut
    browser_stderr = $browserErr
    server_stdout = $serverOut
    server_stderr = $serverErr
    trace_artifacts = $traceArtifacts
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
