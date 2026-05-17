[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8152,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\TabProbeCommon.ps1"

$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-reopen"
$repo = $config.RepoRoot
$root = $config.SmokeRoot
$browserExe = $config.BrowserExe
$profileRoot = $config.ProfileRoot
$initialPng = Join-Path $root "chrome-reopen.initial.png"
$browserOut = Join-Path $root "chrome-reopen.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-reopen.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-reopen.server.stdout.txt"
$serverErr = Join-Path $root "chrome-reopen.server.stderr.txt"

Reset-TabProbeProfile $profileRoot
Remove-Item $initialPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Set-TabProbeProfileEnvironment $profileRoot

$server = $null
$browser = $null
$ready = $false
$newTabWorked = $false
$navigateWorked = $false
$closeWorked = $false
$reopenWorked = $false
$screenshotReady = $false
$titles = [ordered]@{}
$failure = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind",$Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "http://$Host`:$Port/index.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "reopen probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://$Host`:$Port/index.html","--window_width","960","--window_height","640","--screenshot_png",$initialPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $screenshotReady = Wait-LightpandaFileReady -Path $initialPng -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $screenshotReady) { throw "reopen probe initial screenshot did not become ready" }
  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd -eq [IntPtr]::Zero) { throw "reopen probe window handle not found" }
  Show-SmokeWindow $hwnd

  $titles.initial = Wait-TabTitle -ProcessId $browser.Id -Needle "Tab One" -Attempts 40 -PollMilliseconds $PollMilliseconds
  if (-not $titles.initial) { throw "initial tab title did not appear" }

  $newTabPoint = Get-TabClientPoint 0 -New
  [void](Invoke-SmokeClientClick $hwnd $newTabPoint.X $newTabPoint.Y)
  $titles.new_tab = Wait-TabTitle -ProcessId $browser.Id -Needle "New Tab" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $newTabWorked = [bool]$titles.new_tab
  if (-not $newTabWorked) { throw "new tab did not open" }

  [void](Invoke-SmokeClientClick $hwnd 160 40)
  Start-Sleep -Milliseconds 150
  Send-SmokeText "http://$Host`:$Port/two.html"
  Start-Sleep -Milliseconds 100
  Send-SmokeEnter
  $titles.second = Wait-TabTitle -ProcessId $browser.Id -Needle "Tab Two" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $navigateWorked = [bool]$titles.second
  if (-not $navigateWorked) { throw "second tab navigation did not complete" }

  Send-SmokeCtrlW
  $titles.after_close = Wait-TabTitle -ProcessId $browser.Id -Needle "Tab One" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $closeWorked = [bool]$titles.after_close
  if (-not $closeWorked) { throw "close tab shortcut did not return to tab one" }

  Send-SmokeCtrlShiftT
  $titles.after_reopen = Wait-TabTitle -ProcessId $browser.Id -Needle "Tab Two" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $reopenWorked = [bool]$titles.after_reopen
  if (-not $reopenWorked) { throw "reopen closed tab shortcut did not restore tab two" }
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
    screenshot_ready = $screenshotReady
    new_tab_worked = $newTabWorked
    navigate_worked = $navigateWorked
    close_worked = $closeWorked
    reopen_worked = $reopenWorked
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
