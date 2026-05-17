[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8200,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\StorageProbeCommon.ps1"

$config = Resolve-StorageProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-localstorage-cross-tab"
$repo = $config.RepoRoot
$root = $config.SmokeRoot
$browserExe = $config.BrowserExe
$profileRoot = $config.ProfileRoot
$app = Reset-StorageProfile $profileRoot
Set-StorageProfileEnvironment $profileRoot
Seed-StorageProfile $app.AppDataRoot
$origin = "http://$Host`:$Port"
$entryPattern = ConvertTo-LocalStorageEntryPattern $origin "lppersist" "ok"
$browserOut = Join-Path $root "chrome-localstorage-cross-tab.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-localstorage-cross-tab.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-localstorage-cross-tab.server.stdout.txt"
$serverErr = Join-Path $root "chrome-localstorage-cross-tab.server.stderr.txt"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

$server = $null
$browser = $null
$ready = $false
$seedWorked = $false
$persistedToDisk = $false
$echoWorked = $false
$seedTabRetained = $false
$failure = $null
$titles = [ordered]@{}
$storageData = ""

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $server = Start-StorageServer -WorkingDirectory $root -Port $Port -Stdout $serverOut -Stderr $serverErr
  $ready = Wait-StorageServer -Host $Host -Port $Port -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "localstorage server did not become ready" }

  $browser = Start-StorageBrowser -RepoRoot $repo -BrowserExe $browserExe -StartupUrl "$origin/seed.html" -Stdout $browserOut -Stderr $browserErr
  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd -eq [IntPtr]::Zero) { throw "localstorage cross-tab window handle not found" }
  Show-SmokeWindow $hwnd

  $titles.seed = Wait-TabTitle -ProcessId $browser.Id -Needle "Local Storage Seeded" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $seedWorked = [bool]$titles.seed
  if (-not $seedWorked) { throw "seed page did not finish localStorage write" }

  $storageData = Wait-LocalStorageFileMatch $app.LocalStorageFile $entryPattern
  $persistedToDisk = [bool]$storageData
  if (-not $persistedToDisk) { throw "localStorage data did not persist to disk before cross-tab check" }

  Send-SmokeCtrlT
  Start-Sleep -Milliseconds ($PollMilliseconds + 100)
  $titles.echo = Invoke-StorageAddressNavigate $hwnd $browser.Id "$origin/echo.html" "Local Storage Echo ok"
  $echoWorked = [bool]$titles.echo
  if (-not $echoWorked) { throw "new tab did not see shared localStorage" }

  Send-SmokeCtrlShiftTab
  $titles.back_to_seed = Wait-TabTitle -ProcessId $browser.Id -Needle "Local Storage Seeded" -Attempts 30 -PollMilliseconds $PollMilliseconds
  $seedTabRetained = [bool]$titles.back_to_seed
  if (-not $seedTabRetained) { throw "seed tab was not preserved after cross-tab check" }
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
    seed_worked = $seedWorked
    persisted_to_disk = $persistedToDisk
    echo_worked = $echoWorked
    seed_tab_retained = $seedTabRetained
    local_storage_file = if ($storageData) { $storageData } else { Read-LocalStorageFileData $app.LocalStorageFile }
    titles = $titles
    error = $failure
    server_meta = Format-StorageProbeProcessMeta $serverMeta
    browser_meta = Format-StorageProbeProcessMeta $browserMeta
    browser_gone = $browserGone
    server_gone = $serverGone
  }
  Write-StorageProbeResult $result

  if ($failure -or -not $seedWorked -or -not $persistedToDisk -or -not $echoWorked -or -not $seedTabRetained) {
    exit 1
  }
}
