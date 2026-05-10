[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8176,
    [string]$ProbePagePath = "/src/browser/tests/page/google_home_title_probe.html",
    [string]$InputText = "n",
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$WindowReadyAttempts = 60,
    [int]$TitleWaitAttempts = 80,
    [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $scriptRoot "..\..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}
if (-not (Test-Path -LiteralPath $BrowserExe)) {
    throw "headed browser binary not found: $BrowserExe"
}

$root = $scriptRoot
$profileRoot = Join-Path $root "profile-google-home"
$browserOut = Join-Path $root "chrome-google-home.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-google-home.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-google-home.server.stdout.txt"
$serverErr = Join-Path $root "chrome-google-home.server.stderr.txt"
$probeUrl = "http://$Host`:$Port$ProbePagePath"

cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
New-Item -ItemType Directory -Force -Path $root | Out-Null
New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

$env:APPDATA = $profileRoot
$env:LOCALAPPDATA = $profileRoot

. "$PSScriptRoot\..\tabs\TabProbeCommon.ps1"

function Resolve-PythonCommand {
  if (Get-Command python -ErrorAction SilentlyContinue) {
    return @{ FileName = "python"; Arguments = @("-m", "http.server") }
  }
  if (Get-Command py -ErrorAction SilentlyContinue) {
    return @{ FileName = "py"; Arguments = @("-3", "-m", "http.server") }
  }
  throw "Python was not found in PATH. Install Python or start the localhost server separately."
}

function Wait-HttpReady {
  param(
    [string]$Url,
    [int]$TimeoutSeconds
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    try {
      $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
      if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
        return
      }
    } catch {
    }
    Start-Sleep -Milliseconds $PollMilliseconds
  } while ((Get-Date) -lt $deadline)

  throw "reduced Google home probe server did not become ready at $Url"
}

function Wait-ProbeWindowHandle {
  param(
    [int]$ProcessId,
    [int]$Attempts
  )

  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $hwnd = Get-TabWindowHandle $ProcessId
    if ($hwnd -ne [IntPtr]::Zero) {
      return $hwnd
    }
  }

  return [IntPtr]::Zero
}

function Wait-WindowTitlePattern {
  param(
    [IntPtr]$Hwnd,
    [string]$Pattern,
    [int]$Attempts = 40
  )

  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $title = Get-SmokeWindowTitle $Hwnd
    if ($title -match $Pattern) {
      return $title
    }
  }

  return $null
}

$server = $null
$browser = $null
$ready = $false
$focusWorked = $false
$typedWorked = $false
$submitWorked = $false
$failure = $null
$titles = [ordered]@{}
$clickClient = [ordered]@{ x = 480; y = 260 }
$clickScreen = $null

try {
  $python = Resolve-PythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($Port, "--bind", $Host)) -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  Wait-HttpReady -Url $probeUrl -TimeoutSeconds $ServerReadyTimeoutSeconds
  $ready = $true

  $browser = Start-Process -FilePath $BrowserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "960", "--window_height", "720", $probeUrl) -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-ProbeWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts
  if ($hwnd -eq [IntPtr]::Zero) { throw "reduced Google home probe window handle not found" }
  Show-SmokeWindow $hwnd

  $titles.bound = Wait-WindowTitlePattern -Hwnd $hwnd -Pattern "\|Q=INPUT:q::1\|" -Attempts $TitleWaitAttempts
  if (-not $titles.bound) { throw "reduced Google home probe did not bind the query input" }

  $clickScreen = Invoke-SmokeClientClick $hwnd $clickClient.x $clickClient.y
  $titles.after_click = Wait-WindowTitlePattern -Hwnd $hwnd -Pattern "A=INPUT:q::1" -Attempts $TitleWaitAttempts
  if (-not $titles.after_click) {
    Send-SmokeTab
    $titles.after_tab = Wait-WindowTitlePattern -Hwnd $hwnd -Pattern "A=INPUT:q::1" -Attempts $TitleWaitAttempts
  }
  $focusWorked = [bool]($titles.after_click -or $titles.after_tab)
  if (-not $focusWorked) { throw "reduced Google home probe did not focus the query input" }

  Send-SmokeText $InputText
  $titles.after_type = Wait-WindowTitlePattern -Hwnd $hwnd -Pattern ("TYPED:{0}.*\|V={0}\|" -f [regex]::Escape($InputText)) -Attempts $TitleWaitAttempts
  $typedWorked = [bool]$titles.after_type
  if (-not $typedWorked) { throw "reduced Google home probe did not commit typed text" }

  Send-SmokeEnter
  $titles.after_enter = Wait-WindowTitlePattern -Hwnd $hwnd -Pattern ("SUBMIT:{0}" -f [regex]::Escape($InputText)) -Attempts $TitleWaitAttempts
  $submitWorked = [bool]$titles.after_enter
  if (-not $submitWorked) { throw "reduced Google home probe did not submit on Enter" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    repo_root = $RepoRoot
    browser_exe = $BrowserExe
    host = $Host
    port = $Port
    probe_page_path = $ProbePagePath
    probe_url = $probeUrl
    input_text = $InputText
    server_ready_timeout_seconds = $ServerReadyTimeoutSeconds
    window_ready_attempts = $WindowReadyAttempts
    title_wait_attempts = $TitleWaitAttempts
    poll_milliseconds = $PollMilliseconds
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    focus_worked = $focusWorked
    typed_worked = $typedWorked
    submit_worked = $submitWorked
    titles = $titles
    click_client = $clickClient
    click_screen = if ($clickScreen) { [ordered]@{ x = $clickScreen.X; y = $clickScreen.Y } } else { $null }
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
