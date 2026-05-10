[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8176,
  [string]$InputText = "QZ",
  [string]$CorrectionWrongSuffix = "W",
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
$serverScript = Join-Path $root "google_style_probe_server.py"
$profileRoot = Join-Path $root "profile-google-style-correction"
$browserOut = Join-Path $root "google-style-correction.browser.stdout.txt"
$browserErr = Join-Path $root "google-style-correction.browser.stderr.txt"
$serverOut = Join-Path $root "google-style-correction.server.stdout.txt"
$serverErr = Join-Path $root "google-style-correction.server.stderr.txt"
$pngPath = Join-Path $root "google-style-correction.before.png"
$probeUrl = "http://$Host`:$Port/headed_google_style_input_correction_probe.html"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

if (-not (Test-Path -LiteralPath $browserExe)) {
  throw "headed browser binary not found: $browserExe"
}
if (-not (Test-Path -LiteralPath $serverScript)) {
  throw "Google style correction probe server script not found: $serverScript"
}
if ([string]::IsNullOrEmpty($InputText)) {
  throw "InputText must not be empty."
}

$replacementChar = $InputText.Substring($InputText.Length - 1, 1)
$stablePrefix = if ($InputText.Length -gt 1) { $InputText.Substring(0, $InputText.Length - 1) } else { "" }
$wrongSuffix = if ($CorrectionWrongSuffix -eq $replacementChar) {
  if ($replacementChar -ne "X") { "X" } else { "Y" }
} else {
  $CorrectionWrongSuffix
}
$initialText = "$stablePrefix$wrongSuffix"
$backspaceTitle = "typed:$stablePrefix"

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
$typedPairWorked = $false
$backspaceWorked = $false
$correctedWorked = $false
$submittedWorked = $false
$titleAfterPair = $null
$titleAfterBackspace = $null
$titleAfterCorrection = $null
$titleAfterSubmit = $null
$failure = $null

try {
  $python = Resolve-GoogleProbePythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port, $Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  Wait-GoogleProbeHttpReady -Url "http://$Host`:$Port/ping" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  $ready = $true

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "900", "--window_height", "760", "--screenshot_png", $pngPath, $probeUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-GoogleProbeFileReady -Path $pngPath -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $pngReady) { throw "google style correction probe screenshot did not become ready" }

  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts
  if ($hwnd -eq [IntPtr]::Zero) { throw "google style correction probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 300
  Send-SmokeText $initialText
  $titleAfterPair = Wait-GoogleProbeTitleLike -Hwnd $hwnd -Pattern "typed:$initialText" -Attempts $TitleWaitAttempts -PollMilliseconds $PollMilliseconds
  $typedPairWorked = $null -ne $titleAfterPair
  if (-not $typedPairWorked) { throw "google style correction probe did not commit the initial multi-character text" }

  Send-SmokeWindowVirtualKey -Hwnd $hwnd -Vk 8
  $titleAfterBackspace = Wait-GoogleProbeTitleLike -Hwnd $hwnd -Pattern $backspaceTitle -Attempts $TitleWaitAttempts -PollMilliseconds $PollMilliseconds
  $backspaceWorked = $null -ne $titleAfterBackspace
  if (-not $backspaceWorked) { throw "google style correction probe did not apply backspace after focus churn" }

  Send-SmokeText $replacementChar
  $titleAfterCorrection = Wait-GoogleProbeTitleLike -Hwnd $hwnd -Pattern "typed:$InputText" -Attempts $TitleWaitAttempts -PollMilliseconds $PollMilliseconds
  $correctedWorked = $null -ne $titleAfterCorrection
  if (-not $correctedWorked) { throw "google style correction probe did not commit corrected text after backspace" }

  Send-SmokeEnter
  $titleAfterSubmit = Wait-GoogleProbeTitleLike -Hwnd $hwnd -Pattern "submitted:$InputText" -Attempts $TitleWaitAttempts -PollMilliseconds $PollMilliseconds
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) { throw "google style correction probe did not submit corrected text on Enter" }
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
    mode = "google-style-correction-localhost"
    repo_root = $repo
    browser_exe = $browserExe
    host = $Host
    port = $Port
    probe_url = $probeUrl
    input_text = $InputText
    correction_wrong_suffix = $wrongSuffix
    initial_text = $initialText
    server_ready_timeout_seconds = $ServerReadyTimeoutSeconds
    window_ready_attempts = $WindowReadyAttempts
    title_wait_attempts = $TitleWaitAttempts
    poll_milliseconds = $PollMilliseconds
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    typed_pair_worked = $typedPairWorked
    backspace_worked = $backspaceWorked
    corrected_worked = $correctedWorked
    submitted_worked = $submittedWorked
    title_after_pair = $titleAfterPair
    title_after_backspace = $titleAfterBackspace
    title_after_correction = $titleAfterCorrection
    title_after_submit = $titleAfterSubmit
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
