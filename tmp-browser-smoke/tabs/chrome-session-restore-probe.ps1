[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8153,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\TabProbeCommon.ps1"

$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-restore"
$repo = $config.RepoRoot
$root = $config.SmokeRoot
$browserExe = $config.BrowserExe
$profileRoot = $config.ProfileRoot
$run1Png = Join-Path $root "chrome-restore.run1.png"
$run2Png = Join-Path $root "chrome-restore.run2.png"
$run1Out = Join-Path $root "chrome-restore.run1.browser.stdout.txt"
$run1Err = Join-Path $root "chrome-restore.run1.browser.stderr.txt"
$run2Out = Join-Path $root "chrome-restore.run2.browser.stdout.txt"
$run2Err = Join-Path $root "chrome-restore.run2.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-restore.server.stdout.txt"
$serverErr = Join-Path $root "chrome-restore.server.stderr.txt"

Reset-TabProbeProfile $profileRoot
Remove-Item $run1Png,$run2Png,$run1Out,$run1Err,$run2Out,$run2Err,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Set-TabProbeProfileEnvironment $profileRoot

$server = $null
$browser1 = $null
$browser2 = $null
$ready = $false
$sessionPrepared = $false
$activeRestoreWorked = $false
$otherTabWorked = $false
$run1ScreenshotReady = $false
$run2ScreenshotReady = $false
$titles = [ordered]@{}
$failure = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind",$Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "http://$Host`:$Port/index.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "restore probe server did not become ready" }

  $browser1 = Start-Process -FilePath $browserExe -ArgumentList "browse","http://$Host`:$Port/index.html","--window_width","960","--window_height","640","--screenshot_png",$run1Png -WorkingDirectory $repo -PassThru -RedirectStandardOutput $run1Out -RedirectStandardError $run1Err
  $run1ScreenshotReady = Wait-LightpandaFileReady -Path $run1Png -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $run1ScreenshotReady) { throw "restore probe run1 screenshot did not become ready" }
  $hwnd1 = Wait-TabWindowHandle -ProcessId $browser1.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd1 -eq [IntPtr]::Zero) { throw "restore probe run1 window handle not found" }
  Show-SmokeWindow $hwnd1

  $titles.run1_initial = Wait-TabTitle -ProcessId $browser1.Id -Needle "Tab One" -Attempts 40 -PollMilliseconds $PollMilliseconds
  if (-not $titles.run1_initial) { throw "restore probe run1 initial title missing" }

  $newTabPoint = Get-TabClientPoint 0 -New
  [void](Invoke-SmokeClientClick $hwnd1 $newTabPoint.X $newTabPoint.Y)
  $titles.run1_new_tab = Wait-TabTitle -ProcessId $browser1.Id -Needle "New Tab" -Attempts 40 -PollMilliseconds $PollMilliseconds
  if (-not $titles.run1_new_tab) { throw "restore probe run1 new tab missing" }

  [void](Invoke-SmokeClientClick $hwnd1 160 40)
  Start-Sleep -Milliseconds 150
  Send-SmokeText "http://$Host`:$Port/two.html"
  Start-Sleep -Milliseconds 100
  Send-SmokeEnter
  $titles.run1_second = Wait-TabTitle -ProcessId $browser1.Id -Needle "Tab Two" -Attempts 40 -PollMilliseconds $PollMilliseconds
  if (-not $titles.run1_second) { throw "restore probe run1 second tab navigation missing" }
  $sessionPrepared = $true

  $browser1Meta = Stop-OwnedProbeProcess $browser1
  Start-Sleep -Milliseconds 300
  if (Get-Process -Id $browser1.Id -ErrorAction SilentlyContinue) { throw "restore probe run1 browser did not exit" }

  $browser2 = Start-Process -FilePath $browserExe -ArgumentList "browse","http://$Host`:$Port/index.html","--window_width","960","--window_height","640","--screenshot_png",$run2Png -WorkingDirectory $repo -PassThru -RedirectStandardOutput $run2Out -RedirectStandardError $run2Err
  $run2ScreenshotReady = Wait-LightpandaFileReady -Path $run2Png -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $run2ScreenshotReady) { throw "restore probe run2 screenshot did not become ready" }
  $hwnd2 = Wait-TabWindowHandle -ProcessId $browser2.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd2 -eq [IntPtr]::Zero) { throw "restore probe run2 window handle not found" }
  Show-SmokeWindow $hwnd2

  $titles.run2_active = Wait-TabTitle -ProcessId $browser2.Id -Needle "Tab Two" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $activeRestoreWorked = [bool]$titles.run2_active
  if (-not $activeRestoreWorked) { throw "restore probe did not reopen the last active tab" }

  Send-SmokeCtrlShiftTab
  $titles.run2_other = Wait-TabTitle -ProcessId $browser2.Id -Needle "Tab One" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $otherTabWorked = [bool]$titles.run2_other
  if (-not $otherTabWorked) { throw "restore probe did not restore the other saved tab" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  if (-not $browser1Meta) { $browser1Meta = Stop-OwnedProbeProcess $browser1 }
  $browser2Meta = Stop-OwnedProbeProcess $browser2
  Start-Sleep -Milliseconds 200
  $browser1Gone = if ($browser1) { -not (Get-Process -Id $browser1.Id -ErrorAction SilentlyContinue) } else { $true }
  $browser2Gone = if ($browser2) { -not (Get-Process -Id $browser2.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    profile_root = $profileRoot
    host = $Host
    port = $Port
    server_pid = if ($server) { $server.Id } else { 0 }
    run1_browser_pid = if ($browser1) { $browser1.Id } else { 0 }
    run2_browser_pid = if ($browser2) { $browser2.Id } else { 0 }
    ready = $ready
    run1_screenshot_ready = $run1ScreenshotReady
    run2_screenshot_ready = $run2ScreenshotReady
    session_prepared = $sessionPrepared
    active_restore_worked = $activeRestoreWorked
    other_tab_worked = $otherTabWorked
    titles = $titles
    error = $failure
    server_meta = $serverMeta
    browser1_meta = $browser1Meta
    browser2_meta = $browser2Meta
    browser1_gone = $browser1Gone
    browser2_gone = $browser2Gone
    server_gone = $serverGone
  } | ConvertTo-Json -Depth 7
}

if ($failure) {
  exit 1
}
