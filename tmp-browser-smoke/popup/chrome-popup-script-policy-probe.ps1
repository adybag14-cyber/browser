[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8176,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. "$PSScriptRoot\..\tabs\TabProbeCommon.ps1"
. "$PSScriptRoot\..\common\Win32Input.ps1"

$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-script-policy"
$repo = $config.RepoRoot
$root = Join-Path $repo "tmp-browser-smoke\popup"
$browserExe = $config.BrowserExe
$profileRoot = $config.ProfileRoot
$origin = "http://$Host`:$Port"
$settingsPath = Join-Path $profileRoot "lightpanda\browse-settings-v1.txt"
$browserOut = Join-Path $root "chrome-popup-script-policy.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-popup-script-policy.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-popup-script-policy.server.stdout.txt"
$serverErr = Join-Path $root "chrome-popup-script-policy.server.stderr.txt"

Reset-TabProbeProfile $profileRoot
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Set-TabProbeProfileEnvironment $profileRoot

function Wait-SettingsValue {
  param(
    [string]$Path,
    [string]$Needle,
    [int]$TimeoutSeconds = 8
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    if (Test-Path $Path) {
      $raw = Get-Content $Path -Raw
      if ($raw -match [regex]::Escape($Needle)) {
        return $true
      }
    }
    Start-Sleep -Milliseconds 200
  }
  return $false
}

$server = $null
$browser = $null
$ready = $false
$toggleOffWorked = $false
$toggleOnWorked = $false
$failure = $null
$titles = [ordered]@{}

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind",$Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "$origin/script-popup-policy-index.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "script popup policy server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/script-popup-policy-index.html") -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd -eq [IntPtr]::Zero) { throw "script popup policy window handle not found" }
  Show-SmokeWindow $hwnd

  $titles.initial = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Policy Start" -Attempts 8 -PollMilliseconds $PollMilliseconds
  if (-not $titles.initial) { throw "script popup policy start page did not load" }

  Send-SmokeCtrlComma
  Start-Sleep -Milliseconds 250
  Send-SmokeDown
  Start-Sleep -Milliseconds 150
  Send-SmokeSpace
  Start-Sleep -Milliseconds 150
  Send-SmokeCtrlComma
  $toggleOffWorked = Wait-SettingsValue $settingsPath "allow_script_popups`t0"
  if (-not $toggleOffWorked) { throw "settings overlay did not persist script popup policy off" }

  Send-SmokeCtrlComma
  Start-Sleep -Milliseconds 250
  Send-SmokeDown
  Start-Sleep -Milliseconds 150
  Send-SmokeSpace
  Start-Sleep -Milliseconds 150
  Send-SmokeCtrlComma
  $toggleOnWorked = Wait-SettingsValue $settingsPath "allow_script_popups`t1"
  if (-not $toggleOnWorked) { throw "settings overlay did not persist script popup policy on" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
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
    toggle_off_worked = $toggleOffWorked
    toggle_on_worked = $toggleOnWorked
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
