[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8151,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\TabProbeCommon.ps1"

$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe
$repo = $config.RepoRoot
$root = $config.SmokeRoot
$browserExe = $config.BrowserExe
$initialPng = Join-Path $root "tabs-initial.png"
$browserOut = Join-Path $root "chrome-tabs.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-tabs.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-tabs.server.stdout.txt"
$serverErr = Join-Path $root "chrome-tabs.server.stderr.txt"
Remove-Item $initialPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$newTabWorked = $false
$addressNavigateWorked = $false
$keyboardBackWorked = $false
$keyboardForwardWorked = $false
$clickSwitchWorked = $false
$closeWorked = $false
$failure = $null
$titles = [ordered]@{}

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind",$Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "http://$Host`:$Port/index.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "tab probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/index.html","--window_width","960","--window_height","640","--screenshot_png",$initialPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-LightpandaFileReady -Path $initialPng -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $pngReady) { throw "tab probe initial screenshot did not become ready" }

  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd -eq [IntPtr]::Zero) { throw "tab probe window handle not found" }

  Show-SmokeWindow $hwnd
  $titles.initial = Wait-TabTitle -ProcessId $browser.Id -Needle "Tab One" -Attempts 40 -PollMilliseconds $PollMilliseconds
  if (-not $titles.initial) { throw "initial tab title did not appear" }

  $newTabPoint = Get-TabClientPoint 0 -New
  [void](Invoke-SmokeClientClick $hwnd $newTabPoint.X $newTabPoint.Y)
  $titles.new_tab = Wait-TabTitle -ProcessId $browser.Id -Needle "New Tab" -Attempts 40 -PollMilliseconds $PollMilliseconds
  if (-not $titles.new_tab) {
    Start-Sleep -Milliseconds ($PollMilliseconds * 2)
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $titles.new_tab_current = Get-SmokeWindowTitle ([IntPtr]$proc.MainWindowHandle)
    }
  }
  $newTabWorked = [bool]$titles.new_tab
  if (-not $newTabWorked) { throw "new tab button did not open a blank tab" }

  [void](Invoke-SmokeClientClick $hwnd 160 40)
  Start-Sleep -Milliseconds 150
  Send-SmokeText "http://$Host`:$Port/two.html"
  Start-Sleep -Milliseconds 100
  Send-SmokeEnter
  $titles.second = Wait-TabTitle -ProcessId $browser.Id -Needle "Tab Two" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $addressNavigateWorked = [bool]$titles.second
  if (-not $addressNavigateWorked) { throw "new tab address bar navigation did not reach tab two" }

  Send-SmokeCtrlShiftTab
  $titles.back = Wait-TabTitle -ProcessId $browser.Id -Needle "Tab One" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $keyboardBackWorked = [bool]$titles.back
  if (-not $keyboardBackWorked) { throw "Ctrl+Shift+Tab did not return to tab one" }

  Send-SmokeCtrlTab
  $titles.forward = Wait-TabTitle -ProcessId $browser.Id -Needle "Tab Two" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $keyboardForwardWorked = [bool]$titles.forward
  if (-not $keyboardForwardWorked) { throw "Ctrl+Tab did not return to tab two" }

  $firstTabPoint = Get-TabClientPoint 0
  [void](Invoke-SmokeClientClick $hwnd $firstTabPoint.X $firstTabPoint.Y)
  $titles.click_switch = Wait-TabTitle -ProcessId $browser.Id -Needle "Tab One" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $clickSwitchWorked = [bool]$titles.click_switch
  if (-not $clickSwitchWorked) { throw "tab strip click did not activate the first tab" }

  $secondTabPoint = Get-TabClientPoint 1
  [void](Invoke-SmokeClientClick $hwnd $secondTabPoint.X $secondTabPoint.Y)
  $titles.reopen_second = Wait-TabTitle -ProcessId $browser.Id -Needle "Tab Two" -Attempts 40 -PollMilliseconds $PollMilliseconds
  if (-not $titles.reopen_second) { throw "second tab click did not reactivate tab two before close" }

  $closePoint = Get-TabClientPoint 1 -Close
  [void](Invoke-SmokeClientClick $hwnd $closePoint.X $closePoint.Y)
  $titles.after_close = Wait-TabTitle -ProcessId $browser.Id -Needle "Tab One" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $closeWorked = [bool]$titles.after_close
  if (-not $closeWorked) { throw "tab close button did not return to tab one" }
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
    host = $Host
    port = $Port
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    new_tab_worked = $newTabWorked
    address_navigate_worked = $addressNavigateWorked
    keyboard_back_worked = $keyboardBackWorked
    keyboard_forward_worked = $keyboardForwardWorked
    click_switch_worked = $clickSwitchWorked
    close_worked = $closeWorked
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
