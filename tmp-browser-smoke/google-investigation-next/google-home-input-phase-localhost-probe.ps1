[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8178,
  [string]$InputText = "Q",
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$TitleWaitAttempts = 25,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "tabs\TabProbeCommon.ps1")
. (Join-Path $PSScriptRoot "GoogleProbeCommon.ps1")

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-GoogleProbeRepoRoot $PSScriptRoot }
$root = $PSScriptRoot
$browserExe = if ($BrowserExe) { $BrowserExe } elseif (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_BROWSER_EXE)) { $env:LIGHTPANDA_BROWSER_EXE } else { Join-Path $repo "zig-out\bin\lightpanda.exe" }
$serverScript = Join-Path $root "google_probe_server.py"
$profileRoot = Join-Path $root "profile-google-home-input-phase"
$browserOut = Join-Path $root "google-home-input-phase.browser.stdout.txt"
$browserErr = Join-Path $root "google-home-input-phase.browser.stderr.txt"
$serverOut = Join-Path $root "google-home-input-phase.server.stdout.txt"
$serverErr = Join-Path $root "google-home-input-phase.server.stderr.txt"
$pngPath = Join-Path $root "google-home-input-phase.before.png"
$probeUrl = "http://$Host`:$Port/google-home-input.html"
$typedTitle = "Google Home Typed $InputText*"
$resultTitle = "Google Home Result *"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath $browserExe)) {
  throw "headed browser binary not found: $browserExe"
}
if (-not (Test-Path -LiteralPath $serverScript)) {
  throw "google input-phase probe server script not found: $serverScript"
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
$submittedWorked = $false
$submittedAfterKeypress = $false
$titleAfterType = $null
$titleAfterSubmit = $null
$focusStrategy = "none"
$failure = $null

try {
  $python = Resolve-GoogleProbePythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  Wait-GoogleProbeHttpReady -Url "http://$Host`:$Port/ping" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  $ready = $true

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "960", "--window_height", "680", "--screenshot_png", $pngPath, $probeUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-GoogleProbeFileReady -Path $pngPath -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $pngReady) { throw "google input-phase probe screenshot did not become ready" }

  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts
  if ($hwnd -eq [IntPtr]::Zero) { throw "google input-phase probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 300
  $clickResult = Invoke-GoogleProbeTypeWithFocusRecovery -Hwnd $hwnd -ClickX 470 -ClickY 184 -Text $InputText -TitlePattern $typedTitle -Attempts $TitleWaitAttempts -PollMilliseconds $PollMilliseconds
  if (-not $clickResult) { throw "google input-phase probe did not commit typed text" }
  $typedWorked = $true
  $titleAfterType = $clickResult.title
  $focusStrategy = $clickResult.focus_strategy

  Send-SmokeEnter
  $titleAfterSubmit = Wait-GoogleProbeTitleLike -Hwnd $hwnd -Pattern $resultTitle -Attempts $TitleWaitAttempts -PollMilliseconds $PollMilliseconds
  if (Test-Path -LiteralPath $serverErr) {
    $serverLog = Get-Content -LiteralPath $serverErr -Raw
    $submittedAfterKeypress = $serverLog -match 'GOOGLE_HOME_INPUT_SUBMIT /submitted\.html\?q=Q&submit_phase=keypress'
  }
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) { throw "google input-phase probe did not reach the submitted page" }
  if (-not $submittedAfterKeypress) { throw "google input-phase probe submitted before keypress completed" }
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
    mode = "google-home-input-phase-localhost"
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
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    submitted_after_keypress = $submittedAfterKeypress
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    focus_strategy = $focusStrategy
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
