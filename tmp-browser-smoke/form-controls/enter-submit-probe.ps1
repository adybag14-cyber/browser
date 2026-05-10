$ErrorActionPreference = "Stop"
param(
  [switch]$DeferredEnter,
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8154,
  [string]$InputText = "Q",
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$TitleWaitAttempts = 20,
  [int]$PollMilliseconds = 250
)

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

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-RepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\form-controls"
$browserExe = if ($BrowserExe) { $BrowserExe } elseif (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_BROWSER_EXE)) { $env:LIGHTPANDA_BROWSER_EXE } else { Join-Path $repo "zig-out\bin\lightpanda.exe" }
$serverScript = Join-Path $root "form_server.py"
$browserOut = Join-Path $root "enter-submit.browser.stdout.txt"
$browserErr = Join-Path $root "enter-submit.browser.stderr.txt"
$serverOut = Join-Path $root "enter-submit.server.stdout.txt"
$serverErr = Join-Path $root "enter-submit.server.stderr.txt"
$pngPath = Join-Path $root "enter-submit.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath $browserExe)) {
  throw "headed browser binary not found: $browserExe"
}
if (-not (Test-Path -LiteralPath $serverScript)) {
  throw "form-controls probe server script not found: $serverScript"
}

$pagePath = if ($DeferredEnter) { "/deferred-submit.html" } else { "/submit.html" }
$probeUrl = "http://$Host`:$Port$pagePath"
$inputTextTitle = [System.Management.Automation.WildcardPattern]::Escape($InputText)
$typedTitlePattern = if ($DeferredEnter) { "Deferred Enter Typed $inputTextTitle*" } else { "Enter Submit $inputTextTitle*" }
$pendingTitlePattern = if ($DeferredEnter) { "Deferred Enter Pending $inputTextTitle*" } else { $null }
$serverSubmitPattern = if ($DeferredEnter) { "FORM_SUBMIT /submitted\.html\?q=$([regex]::Escape($InputText))" } else { "FORM_SUBMIT /submitted\.html\?name=$([regex]::Escape($InputText))" }

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

function Wait-HttpReady([string]$Url, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
      if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) {
        return
      }
    } catch {}
    Start-Sleep -Milliseconds $PollMilliseconds
  } while ((Get-Date) -lt $deadline)

  throw "enter submit probe server did not become ready at $Url"
}

function Wait-ForWindowHandle([int]$ProcessId, [int]$Attempts) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $proc = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      return [IntPtr]$proc.MainWindowHandle
    }
  }
  return [IntPtr]::Zero
}

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $title = Get-SmokeWindowTitle $Hwnd
    if ($title -like $Pattern) {
      return $title
    }
  }
  return $null
}

function Stop-OwnedProcess($Process) {
  if (-not $Process) {
    return $null
  }

  $meta = Get-CimInstance Win32_Process -Filter "ProcessId=$($Process.Id)" -ErrorAction SilentlyContinue |
    Select-Object Name,ProcessId,CommandLine,CreationDate
  if ($meta -and $meta.CommandLine -and $meta.CommandLine -notmatch "codex\\.js|@openai/codex") {
    Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
  }
  return $meta
}

try {
  $python = Resolve-PythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  Wait-HttpReady "http://$Host`:$Port/ping" $ServerReadyTimeoutSeconds
  $ready = $true

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$probeUrl,"--window_width","420","--window_height","520","--screenshot_png",$pngPath) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "enter submit probe screenshot did not become ready" }

  $hwnd = Wait-ForWindowHandle $browser.Id $WindowReadyAttempts
  if ($hwnd -eq [IntPtr]::Zero) { throw "enter submit probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds $PollMilliseconds
  $titleBefore = Get-SmokeWindowTitle $hwnd

  Send-SmokeText $InputText
  $titleAfterType = Wait-ForTitleLike $hwnd $typedTitlePattern $TitleWaitAttempts
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "autofocus input did not receive typed text" }

  Send-SmokeEnter
  if ($pendingTitlePattern) {
    $titleAfterPending = Wait-ForTitleLike $hwnd $pendingTitlePattern $TitleWaitAttempts
    $pendingWorked = $null -ne $titleAfterPending
  }
  $titleAfterSubmit = Wait-ForTitleLike $hwnd "Submitted $inputTextTitle*" $TitleWaitAttempts
  if (Test-Path $serverErr) {
    $serverLog = Get-Content $serverErr -Raw
    $serverSawSubmit = $serverLog -match $serverSubmitPattern
  }
  $submittedWorked = ($null -ne $titleAfterSubmit) -or $serverSawSubmit
  if (-not $submittedWorked) { throw "pressing Enter did not submit the form" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProcess $server
  $browserMeta = Stop-OwnedProcess $browser
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    mode = if ($DeferredEnter) { "deferred-enter" } else { "default-enter" }
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
