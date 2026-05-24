[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8155,
  [string]$InputText = "Q",
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
    return @{ FileName = "python"; Arguments = @("-m", "http.server") }
  }
  if (Get-Command py -ErrorAction SilentlyContinue) {
    return @{ FileName = "py"; Arguments = @("-3", "-m", "http.server") }
  }
  throw "Python was not found in PATH. Install Python or start the reduced Google probe server separately."
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

  throw "reduced Google probe server did not become ready at $Url"
}

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "tabs\TabProbeCommon.ps1")

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-RepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\form-controls"
$fixturePath = "src/browser/tests/page/google_home_title_probe.html"
$probeUrl = "http://$Host`:$Port/$fixturePath"
$browserExe = if ($BrowserExe) { $BrowserExe } elseif (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_BROWSER_EXE)) { $env:LIGHTPANDA_BROWSER_EXE } else { Join-Path $repo "zig-out\bin\lightpanda.exe" }
$browserOut = Join-Path $root "google-home-title.browser.stdout.txt"
$browserErr = Join-Path $root "google-home-title.browser.stderr.txt"
$serverOut = Join-Path $root "google-home-title.server.stdout.txt"
$serverErr = Join-Path $root "google-home-title.server.stderr.txt"
$pngPath = Join-Path $root "google-home-title.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath $browserExe)) {
  throw "headed browser binary not found: $browserExe"
}
if (-not (Test-Path -LiteralPath (Join-Path $repo $fixturePath))) {
  throw "reduced Google fixture not found: $(Join-Path $repo $fixturePath)"
}

$profileRoot = Join-Path $root "profile-google-home-title"
$appDataRoot = Join-Path $profileRoot "lightpanda"
$originalAppData = $env:APPDATA
$originalLocalAppData = $env:LOCALAPPDATA
$probeEnv = Get-TabProbeEnvironment $profileRoot

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$hwnd = [IntPtr]::Zero
$titleBefore = $null
$titleAfterFocus = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$focusWorked = $false
$typedWorked = $false
$submittedWorked = $false
$failure = $null
$clickedPoint = $null
$clickClient = $null
$focusNeedle = "FOCUSIN:INPUT:q"
$typedNeedle = "TYPED:$InputText"
$submitNeedle = "SUBMIT:$InputText|"
$clickCandidates = @(
  @{ X = 210; Y = 208 },
  @{ X = 208; Y = 218 },
  @{ X = 212; Y = 228 },
  @{ X = 206; Y = 238 }
)

try {
  $python = Resolve-PythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($Port, "--bind", $Host)) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  Wait-HttpReady -Url $probeUrl -TimeoutSeconds $ServerReadyTimeoutSeconds
  $ready = $true

  cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
  New-Item -ItemType Directory -Force -Path $appDataRoot | Out-Null
@"
lightpanda-browse-settings-v1
restore_previous_session	0
allow_script_popups	0
default_zoom_percent	100
homepage_url	
"@ | Set-Content -Path (Join-Path $appDataRoot "browse-settings-v1.txt") -NoNewline
  $env:APPDATA = $probeEnv.APPDATA
  $env:LOCALAPPDATA = $probeEnv.LOCALAPPDATA

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "420", "--window_height", "520", "--screenshot_png", $pngPath, $probeUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    if ((Test-Path -LiteralPath $pngPath) -and ((Get-Item -LiteralPath $pngPath).Length -gt 0)) {
      $pngReady = $true
      break
    }
  }
  if (-not $pngReady) {
    throw "reduced Google probe screenshot did not become ready"
  }

  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts
  if ($hwnd -eq [IntPtr]::Zero) {
    throw "reduced Google probe window handle not found"
  }

  Show-SmokeWindow $hwnd
  $titleBefore = Get-SmokeWindowTitle $hwnd

  foreach ($candidate in $clickCandidates) {
    $clickClient = [ordered]@{ x = $candidate.X; y = $candidate.Y }
    $clickedPoint = Invoke-SmokeClientClick -Hwnd $hwnd -X $candidate.X -Y $candidate.Y
    $titleAfterFocus = Wait-TabTitle -ProcessId $browser.Id -Needle $focusNeedle -Attempts 12
    if ($titleAfterFocus) {
      $focusWorked = $true
      break
    }
  }
  if (-not $focusWorked) {
    throw "reduced Google fixture did not focus the query input after click attempts"
  }

  Send-SmokeText $InputText
  $titleAfterType = Wait-TabTitle -ProcessId $browser.Id -Needle $typedNeedle -Attempts $TitleWaitAttempts
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) {
    throw "reduced Google fixture did not reflect typed text in the title telemetry"
  }

  Send-SmokeEnter
  $titleAfterSubmit = Wait-TabTitle -ProcessId $browser.Id -Needle $submitNeedle -Attempts $TitleWaitAttempts
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) {
    throw "reduced Google fixture did not record Enter submit telemetry"
  }
} catch {
  $failure = $_.Exception.Message
} finally {
  $env:APPDATA = $originalAppData
  $env:LOCALAPPDATA = $originalLocalAppData
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    host = $Host
    port = $Port
    fixture_path = $fixturePath
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
    click_client = $clickClient
    click_screen = if ($null -ne $clickedPoint) { [ordered]@{ x = $clickedPoint.X; y = $clickedPoint.Y } } else { $null }
    title_before = $titleBefore
    title_after_focus = $titleAfterFocus
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    focus_worked = $focusWorked
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
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
