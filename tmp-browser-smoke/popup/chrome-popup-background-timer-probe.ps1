[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8177,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path $PSScriptRoot "..\tabs\TabProbeCommon.ps1")

$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-background-timer"
$repo = $config.RepoRoot
$root = Join-Path $repo "tmp-browser-smoke\popup"
$browserExe = $config.BrowserExe
$profileRoot = $config.ProfileRoot
$origin = "http://$Host`:$Port"
$browserOut = Join-Path $root "chrome-popup-background-timer.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-popup-background-timer.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-popup-background-timer.server.stdout.txt"
$serverErr = Join-Path $root "chrome-popup-background-timer.server.stderr.txt"

Reset-TabProbeProfile $profileRoot
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Set-TabProbeProfileEnvironment $profileRoot

$server = $null
$browser = $null
$ready = $false
$popupWorked = $false
$backgroundWorked = $false
$serverSawPopup = $false
$failure = $null
$titles = [ordered]@{}

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind",$Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "$origin/script-popup-background-timer.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "popup background timer server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/script-popup-background-timer.html") -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd -eq [IntPtr]::Zero) { throw "popup background timer window handle not found" }
  Show-SmokeWindow $hwnd

  $titles.initial = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Background Timer Start" -Attempts 6 -PollMilliseconds $PollMilliseconds
  if (-not $titles.initial) { throw "popup background timer start page did not load" }

  Start-Sleep -Milliseconds 900
  Send-SmokeCtrlDigit 2
  $titles.popup = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Script Blank Result" -Attempts 24 -PollMilliseconds $PollMilliseconds
  $popupWorked = [bool]$titles.popup
  if (-not $popupWorked) { throw "popup background timer did not open popup tab" }

  Send-SmokeCtrlDigit 1
  $titles.background = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Background Timer Fired" -Attempts 24 -PollMilliseconds $PollMilliseconds
  $backgroundWorked = [bool]$titles.background
  if (-not $backgroundWorked) { throw "popup background timer did not fire launcher callback after popup open" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
  if (Test-Path $serverErr) {
    $serverLog = Get-Content $serverErr -Raw
    $serverSawPopup = $serverLog -match 'GET /script-popup-blank-result\.html'
  }
  if (-not $failure -and -not $serverSawPopup) {
    $failure = "server did not observe popup background timer result request"
  }
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    profile_root = $profileRoot
    host = $Host
    port = $Port
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    popup_worked = $popupWorked
    background_worked = $backgroundWorked
    server_saw_popup = $serverSawPopup
    titles = $titles
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
