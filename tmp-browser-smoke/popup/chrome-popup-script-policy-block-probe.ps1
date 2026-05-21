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

$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-script-policy-block"
$repo = $config.RepoRoot
$root = Join-Path $repo "tmp-browser-smoke\popup"
$browserExe = $config.BrowserExe
$profileRoot = $config.ProfileRoot
$appDataRoot = Join-Path $profileRoot "lightpanda"
$settingsPath = Join-Path $appDataRoot "browse-settings-v1.txt"
$origin = "http://$Host`:$Port"
$browserOut = Join-Path $root "chrome-popup-script-policy-block.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-popup-script-policy-block.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-popup-script-policy-block.server.stdout.txt"
$serverErr = Join-Path $root "chrome-popup-script-policy-block.server.stderr.txt"

Reset-TabProbeProfile $profileRoot
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
@"
lightpanda-browse-settings-v1
restore_previous_session	1
allow_script_popups	0
default_zoom_percent	100
homepage_url	
"@ | Set-Content -Path $settingsPath -NoNewline
Set-TabProbeProfileEnvironment $profileRoot

function Get-ResultHitCount {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return 0 }
  $log = Get-Content $Path -Raw
  return ([regex]::Matches($log, 'GET /script-popup-blank-result\.html')).Count
}

$server = $null
$browser = $null
$ready = $false
$blockedWorked = $false
$failure = $null
$titles = [ordered]@{}

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind",$Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "$origin/script-popup-blank-index.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "script popup block server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/script-popup-blank-index.html") -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd -eq [IntPtr]::Zero) { throw "script popup block window handle not found" }
  Show-SmokeWindow $hwnd

  $titles.initial = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Script Blank Start" -Attempts 8 -PollMilliseconds $PollMilliseconds
  if (-not $titles.initial) { throw "script popup block start page did not load" }

  Start-Sleep -Seconds 2
  $resultHits = Get-ResultHitCount $serverErr
  $titles.stillInitial = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Script Blank Start" -Attempts 4 -PollMilliseconds $PollMilliseconds
  $blockedWorked = ($resultHits -eq 0) -and ($titles.stillInitial -ne $null)
  if (-not $blockedWorked) { throw "blocked script popup still reached the popup result page" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
  $finalHits = Get-ResultHitCount $serverErr
  if (-not $failure -and $finalHits -ne 0) {
    $failure = "expected zero blocked popup result requests but saw $finalHits"
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
    blocked_worked = $blockedWorked
    settings_path = $settingsPath
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
