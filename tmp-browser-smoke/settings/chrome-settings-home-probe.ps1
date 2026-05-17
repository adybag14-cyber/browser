[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8155,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\..\tabs\TabProbeCommon.ps1"

$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-home"
$repo = $config.RepoRoot
$root = Join-Path $repo "tmp-browser-smoke\settings"
$browserExe = $config.BrowserExe
$profileRoot = $config.ProfileRoot
$settingsFile = Join-Path $profileRoot "lightpanda\browse-settings-v1.txt"
$browserOut = Join-Path $root "chrome-settings-home.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-settings-home.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-settings-home.server.stdout.txt"
$serverErr = Join-Path $root "chrome-settings-home.server.stderr.txt"
$origin = "http://$Host`:$Port"

Reset-TabProbeProfile $profileRoot
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Set-TabProbeProfileEnvironment $profileRoot

function Wait-SettingsFileMatch([string]$Path, [string]$Needle, [int]$Attempts = 40, [int]$DelayMilliseconds = 250) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $DelayMilliseconds
    if ((Test-Path -LiteralPath $Path) -and ((Get-Content -LiteralPath $Path -Raw) -like "*$Needle*")) {
      return $true
    }
  }
  return $false
}

$server = $null
$browser = $null
$ready = $false
$defaultZoomSaved = $false
$homepageSaved = $false
$homeWorked = $false
$failure = $null
$titles = [ordered]@{}

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind",$Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "$origin/home.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "settings home probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/home.html") -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd -eq [IntPtr]::Zero) { throw "settings home probe window handle not found" }
  Show-SmokeWindow $hwnd

  $titles.initial = Wait-TabTitle -ProcessId $browser.Id -Needle "Settings Home" -Attempts 40 -PollMilliseconds $PollMilliseconds
  if (-not $titles.initial) { throw "settings home probe initial title missing" }

  Send-SmokeCtrlComma
  Start-Sleep -Milliseconds ($PollMilliseconds - 50)
  Send-SmokeDown
  Start-Sleep -Milliseconds 100
  Send-SmokeRight
  $defaultZoomSaved = Wait-SettingsFileMatch -Path $settingsFile -Needle "default_zoom_percent`t110" -DelayMilliseconds $PollMilliseconds
  if (-not $defaultZoomSaved) { throw "settings home probe did not persist default zoom" }

  Send-SmokeDown
  Start-Sleep -Milliseconds 100
  Send-SmokeEnter
  $homepageSaved = Wait-SettingsFileMatch -Path $settingsFile -Needle "homepage_url`t$origin/home.html" -DelayMilliseconds $PollMilliseconds
  if (-not $homepageSaved) { throw "settings home probe did not persist homepage" }

  Send-SmokeCtrlComma
  Start-Sleep -Milliseconds 150
  [void](Invoke-SmokeClientClick $hwnd 160 40)
  Start-Sleep -Milliseconds 120
  Send-SmokeText "$origin/index.html"
  Start-Sleep -Milliseconds 100
  Send-SmokeEnter
  $titles.index = Wait-TabTitle -ProcessId $browser.Id -Needle "Settings Start" -Attempts 40 -PollMilliseconds $PollMilliseconds
  if (-not $titles.index) { throw "settings home probe did not navigate to index page" }

  Send-SmokeAltHome
  $titles.after_home = Wait-TabTitle -ProcessId $browser.Id -Needle "Settings Home" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $homeWorked = [bool]$titles.after_home
  if (-not $homeWorked) { throw "settings home probe alt+home did not navigate to homepage" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = if ($server) { Stop-OwnedProbeProcess $server } else { $null }
  $browserMeta = if ($browser) { Stop-OwnedProbeProcess $browser } else { $null }
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
    default_zoom_saved = $defaultZoomSaved
    homepage_saved = $homepageSaved
    home_worked = $homeWorked
    settings_file = $settingsFile
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
