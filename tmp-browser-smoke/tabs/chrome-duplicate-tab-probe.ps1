[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8157,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\TabProbeCommon.ps1"

$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-duplicate"
$repo = $config.RepoRoot
$root = $config.SmokeRoot
$browserExe = $config.BrowserExe
$profileRoot = $config.ProfileRoot
$browserOut = Join-Path $root "chrome-duplicate.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-duplicate.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-duplicate.server.stdout.txt"
$serverErr = Join-Path $root "chrome-duplicate.server.stderr.txt"

Reset-TabProbeProfile $profileRoot
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Set-TabProbeProfileEnvironment $profileRoot

$server = $null
$browser = $null
$ready = $false
$duplicateWorked = $false
$switchBackWorked = $false
$switchForwardWorked = $false
$failure = $null
$titles = [ordered]@{}

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind",$Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "http://$Host`:$Port/duplicate-one.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "duplicate tab probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://$Host`:$Port/duplicate-one.html","--window_width","960","--window_height","640" -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd -eq [IntPtr]::Zero) { throw "duplicate tab probe window handle not found" }
  Show-SmokeWindow $hwnd

  $titles.initial = Wait-TabTitle -ProcessId $browser.Id -Needle "Duplicate One" -Attempts 40 -PollMilliseconds $PollMilliseconds
  if (-not $titles.initial) { throw "duplicate tab probe initial title missing" }

  Send-SmokeCtrlShiftD
  Start-Sleep -Milliseconds 250
  [void](Invoke-SmokeClientClick $hwnd 160 40)
  Start-Sleep -Milliseconds 120
  Send-SmokeText "http://$Host`:$Port/duplicate-two.html"
  Start-Sleep -Milliseconds 100
  Send-SmokeEnter

  $titles.duplicate = Wait-TabTitle -ProcessId $browser.Id -Needle "Duplicate Two" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $duplicateWorked = [bool]$titles.duplicate
  if (-not $duplicateWorked) { throw "duplicate tab probe did not navigate duplicated tab" }

  Send-SmokeCtrlShiftTab
  $titles.back = Wait-TabTitle -ProcessId $browser.Id -Needle "Duplicate One" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $switchBackWorked = [bool]$titles.back
  if (-not $switchBackWorked) { throw "duplicate tab probe did not switch back to original tab" }

  Send-SmokeCtrlTab
  $titles.forward = Wait-TabTitle -ProcessId $browser.Id -Needle "Duplicate Two" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $switchForwardWorked = [bool]$titles.forward
  if (-not $switchForwardWorked) { throw "duplicate tab probe did not switch forward to duplicated tab" }
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
    duplicate_worked = $duplicateWorked
    switch_back_worked = $switchBackWorked
    switch_forward_worked = $switchForwardWorked
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
