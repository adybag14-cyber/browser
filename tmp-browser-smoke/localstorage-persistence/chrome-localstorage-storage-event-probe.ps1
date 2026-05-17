[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8321,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\StorageProbeCommon.ps1"

$config = Resolve-StorageProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-localstorage-storage-event"
$repo = $config.RepoRoot
$root = $config.SmokeRoot
$browserExe = $config.BrowserExe
$profileRoot = $config.ProfileRoot
$app = Reset-StorageProfile $profileRoot
Set-StorageProfileEnvironment $profileRoot
Seed-StorageProfile $app.AppDataRoot
$origin = "http://$Host`:$Port"
$browserOut = Join-Path $root "chrome-localstorage-storage-event.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-localstorage-storage-event.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-localstorage-storage-event.server.stdout.txt"
$serverErr = Join-Path $root "chrome-localstorage-storage-event.server.stderr.txt"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

$server = $null
$browser = $null
$ready = $false
$listenerReady = $false
$writerWorked = $false
$listenerReceived = $false
$listenerRetained = $false
$failure = $null
$titles = [ordered]@{}

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $server = Start-StorageServer -WorkingDirectory $root -Port $Port -Stdout $serverOut -Stderr $serverErr
  $ready = Wait-StorageServer -Host $Host -Port $Port -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "localstorage server did not become ready" }

  $browser = Start-StorageBrowser -RepoRoot $repo -BrowserExe $browserExe -StartupUrl "$origin/listener.html" -Stdout $browserOut -Stderr $browserErr
  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd -eq [IntPtr]::Zero) { throw "localstorage event window handle not found" }
  Show-SmokeWindow $hwnd

  $titles.listener_ready = Wait-TabTitle -ProcessId $browser.Id -Needle "Local Storage Listener Ready" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $listenerReady = [bool]$titles.listener_ready
  if (-not $listenerReady) { throw "listener page did not become ready" }

  Send-SmokeCtrlT
  Start-Sleep -Milliseconds ($PollMilliseconds + 100)
  $titles.writer = Invoke-StorageAddressNavigate $hwnd $browser.Id "$origin/writer.html" "Local Storage Writer Wrote"
  $writerWorked = [bool]$titles.writer
  if (-not $writerWorked) { throw "writer page did not write localStorage" }

  Send-SmokeCtrlShiftTab
  $titles.back_to_listener = Wait-TabTitle -ProcessId $browser.Id -Needle "Local Storage Event ok" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $listenerReceived = [bool]$titles.back_to_listener
  if (-not $listenerReceived) { throw "listener tab did not receive storage event" }

  Send-SmokeCtrlTab
  $titles.return_to_writer = Wait-TabTitle -ProcessId $browser.Id -Needle "Local Storage Writer Wrote" -Attempts 20 -PollMilliseconds $PollMilliseconds
  $listenerRetained = [bool]$titles.return_to_writer
  if (-not $listenerRetained) { throw "writer tab was not preserved after storage event delivery" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  $result = [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    profile_root = $profileRoot
    host = $Host
    port = $Port
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    listener_ready = $listenerReady
    writer_worked = $writerWorked
    listener_received = $listenerReceived
    writer_tab_retained = $listenerRetained
    titles = $titles
    error = $failure
    server_meta = Format-StorageProbeProcessMeta $serverMeta
    browser_meta = Format-StorageProbeProcessMeta $browserMeta
    browser_gone = $browserGone
    server_gone = $serverGone
  }
  Write-StorageProbeResult $result

  if ($failure -or -not $listenerReady -or -not $writerWorked -or -not $listenerReceived -or -not $listenerRetained) {
    exit 1
  }
}
