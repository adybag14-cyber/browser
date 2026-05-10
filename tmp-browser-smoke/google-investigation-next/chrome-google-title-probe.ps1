[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8159,
    [string]$InputText = "zig headed",
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$WindowReadyAttempts = 80,
    [int]$TitleWaitAttempts = 30,
    [int]$PollMilliseconds = 250,
    [int]$QueryClickX = 640,
    [int]$QueryClickY = 248
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $scriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

$root = $scriptRoot
$probePath = "src/browser/tests/page/google_home_title_probe.html"
$probeUrl = "http://$Host`:$Port/$probePath"
$serverOut = Join-Path $root "google-title.server.stdout.txt"
$serverErr = Join-Path $root "google-title.server.stderr.txt"
$browserOut = Join-Path $root "google-title.browser.stdout.txt"
$browserErr = Join-Path $root "google-title.browser.stderr.txt"
$screenshotPath = Join-Path $root "google-title.before.png"

New-Item -ItemType Directory -Force -Path $root | Out-Null
Remove-Item $serverOut,$serverErr,$browserOut,$browserErr,$screenshotPath -Force -ErrorAction SilentlyContinue

. (Join-Path $RepoRoot "tmp-browser-smoke\common\Win32Input.ps1")

$server = $null
$browser = $null
$ready = $false
$windowReady = $false
$initialReady = $false
$focusedWorked = $false
$typedWorked = $false
$submittedWorked = $false
$failure = $null
$titleInitial = $null
$titleFocused = $null
$titleTyped = $null
$titleSubmitted = $null

function Wait-ForGoogleProbeTitle {
  param(
    [IntPtr]$Hwnd,
    [string[]]$Patterns,
    [int]$Attempts = $TitleWaitAttempts,
    [int]$SleepMs = $PollMilliseconds
  )

  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    foreach ($pattern in $Patterns) {
      if ($title -like $pattern) {
        return $title
      }
    }
  }

  return $null
}

try {
  $serverPollAttempts = [Math]::Max([int][Math]::Ceiling(($ServerReadyTimeoutSeconds * 1000) / [Math]::Max($PollMilliseconds, 1)), 1)
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$Port,"--bind",$Host -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt $serverPollAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $probeUrl -TimeoutSec 2
      if ($resp.StatusCode -eq 200) {
        $ready = $true
        break
      }
    } catch {}
  }
  if (-not $ready) { throw "google title probe server did not become ready" }

  $browser = Start-Process -FilePath $BrowserExe -ArgumentList "browse",$probeUrl,"--window_width","1280","--window_height","900","--screenshot_png",$screenshotPath -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      $windowReady = $true
      break
    }
  }
  if (-not $windowReady) { throw "google title probe window handle not found" }

  Show-SmokeWindow $hwnd

  $titleInitial = Wait-ForGoogleProbeTitle $hwnd @("*BOUND*","*NOQ*","*INIT*")
  $initialReady = $null -ne $titleInitial
  if (-not $initialReady) { throw "google title probe page did not publish an initial title marker" }

  [void](Invoke-SmokeClientClick $hwnd $QueryClickX $QueryClickY)
  $titleFocused = Wait-ForGoogleProbeTitle $hwnd @("*FOCUSED*","*FOCUSIN:INPUT:q*","*A=INPUT:q*")
  if (-not $titleFocused) {
    [void](Invoke-SmokeClientClick $hwnd $QueryClickX $QueryClickY)
    $titleFocused = Wait-ForGoogleProbeTitle $hwnd @("*FOCUSED*","*FOCUSIN:INPUT:q*","*A=INPUT:q*")
  }
  $focusedWorked = $null -ne $titleFocused
  if (-not $focusedWorked) { throw "google title probe did not focus the query input after click" }

  Send-SmokeText $InputText
  $escapedInputText = [WildcardPattern]::Escape($InputText)
  $titleTyped = Wait-ForGoogleProbeTitle $hwnd @("*TYPED:$escapedInputText*","*|V=$escapedInputText|*")
  $typedWorked = $null -ne $titleTyped
  if (-not $typedWorked) { throw "google title probe did not reflect typed text in the query input" }

  Send-SmokeEnter
  $titleSubmitted = Wait-ForGoogleProbeTitle $hwnd @("*SUBMIT:$escapedInputText*")
  $submittedWorked = $null -ne $titleSubmitted
  if (-not $submittedWorked) { throw "google title probe did not observe submit after Enter" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = if ($server) { Get-CimInstance Win32_Process -Filter "ProcessId=$($server.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  $browserMeta = if ($browser) { Get-CimInstance Win32_Process -Filter "ProcessId=$($browser.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  if ($browserMeta -and $browserMeta.CommandLine -and $browserMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-Process -Id $browser.Id -Force -ErrorAction SilentlyContinue }
  if ($serverMeta -and $serverMeta.CommandLine -and $serverMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Milliseconds 200

  [ordered]@{
    repo_root = $RepoRoot
    browser_exe = $BrowserExe
    host = $Host
    port = $Port
    input_text = $InputText
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    window_ready = $windowReady
    initial_ready = $initialReady
    focused_worked = $focusedWorked
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    title_initial = $titleInitial
    title_focused = $titleFocused
    title_typed = $titleTyped
    title_submitted = $titleSubmitted
    screenshot_path = $screenshotPath
    error = $failure
    server_meta = $serverMeta
    browser_meta = $browserMeta
  } | ConvertTo-Json -Depth 7
}

if ($failure) {
  exit 1
}
