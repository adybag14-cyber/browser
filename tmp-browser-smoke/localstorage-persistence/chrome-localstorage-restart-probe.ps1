[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8201,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\StorageProbeCommon.ps1"

$config = Resolve-StorageProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-localstorage-restart"
$repo = $config.RepoRoot
$root = $config.SmokeRoot
$browserExe = $config.BrowserExe
$profileRoot = $config.ProfileRoot
$app = Reset-StorageProfile $profileRoot
Set-StorageProfileEnvironment $profileRoot
Seed-StorageProfile $app.AppDataRoot
$origin = "http://$Host`:$Port"
$entryPattern = ConvertTo-LocalStorageEntryPattern $origin "lppersist" "ok"
$browserOneOut = Join-Path $root "chrome-localstorage-restart.run1.browser.stdout.txt"
$browserOneErr = Join-Path $root "chrome-localstorage-restart.run1.browser.stderr.txt"
$browserTwoOut = Join-Path $root "chrome-localstorage-restart.run2.browser.stdout.txt"
$browserTwoErr = Join-Path $root "chrome-localstorage-restart.run2.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-localstorage-restart.server.stdout.txt"
$serverErr = Join-Path $root "chrome-localstorage-restart.server.stderr.txt"
Remove-Item $browserOneOut,$browserOneErr,$browserTwoOut,$browserTwoErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

$server = $null
$browserOne = $null
$browserTwo = $null
$ready = $false
$seedWorked = $false
$persistedToDisk = $false
$restartWorked = $false
$browserOneGoneBeforeRestart = $false
$failure = $null
$titles = [ordered]@{}
$storageData = ""

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $server = Start-StorageServer -WorkingDirectory $root -Port $Port -Stdout $serverOut -Stderr $serverErr
  $ready = Wait-StorageServer -Host $Host -Port $Port -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "localstorage server did not become ready" }

  $browserOne = Start-StorageBrowser -RepoRoot $repo -BrowserExe $browserExe -StartupUrl "$origin/seed.html" -Stdout $browserOneOut -Stderr $browserOneErr
  $hwndOne = Wait-TabWindowHandle -ProcessId $browserOne.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwndOne -eq [IntPtr]::Zero) { throw "localstorage restart run1 window handle not found" }
  Show-SmokeWindow $hwndOne

  $titles.seed = Wait-TabTitle -ProcessId $browserOne.Id -Needle "Local Storage Seeded" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $seedWorked = [bool]$titles.seed
  if (-not $seedWorked) { throw "seed page did not finish localStorage write" }

  $storageData = Wait-LocalStorageFileMatch $app.LocalStorageFile $entryPattern
  $persistedToDisk = [bool]$storageData
  if (-not $persistedToDisk) { throw "localStorage data was not persisted before restart" }

  $browserOneMeta = Stop-OwnedProbeProcess $browserOne
  $browserOneGoneBeforeRestart = Wait-OwnedProbeProcessGone $browserOne.Id
  $browserOne = $null
  if (-not $browserOneGoneBeforeRestart) { throw "run1 browser pid did not exit before restart" }
  Start-Sleep -Milliseconds ($PollMilliseconds + 50)

  $browserTwo = Start-StorageBrowser -RepoRoot $repo -BrowserExe $browserExe -StartupUrl "$origin/echo.html" -Stdout $browserTwoOut -Stderr $browserTwoErr
  $hwndTwo = Wait-TabWindowHandle -ProcessId $browserTwo.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwndTwo -eq [IntPtr]::Zero) { throw "localstorage restart run2 window handle not found" }
  Show-SmokeWindow $hwndTwo

  $titles.restart = Wait-TabTitle -ProcessId $browserTwo.Id -Needle "Local Storage Echo ok" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $restartWorked = [bool]$titles.restart
  if (-not $restartWorked) { throw "restarted browser did not reuse persisted localStorage" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserOneMetaFinal = if ($browserOne) { Stop-OwnedProbeProcess $browserOne } else { $null }
  $browserTwoMeta = Stop-OwnedProbeProcess $browserTwo
  Start-Sleep -Milliseconds 200
  $browserOneGone = if ($browserOne) { -not (Get-Process -Id $browserOne.Id -ErrorAction SilentlyContinue) } else { $true }
  $browserTwoGone = if ($browserTwo) { -not (Get-Process -Id $browserTwo.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }
  if (-not $storageData) { $storageData = Read-LocalStorageFileData $app.LocalStorageFile }
  $browserOneMetaValue = if ($browserOneMeta) { $browserOneMeta } else { $browserOneMetaFinal }

  $result = [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    profile_root = $profileRoot
    host = $Host
    port = $Port
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_one_pid = if ($browserOne) { $browserOne.Id } else { 0 }
    browser_two_pid = if ($browserTwo) { $browserTwo.Id } else { 0 }
    ready = $ready
    seed_worked = $seedWorked
    persisted_to_disk = $persistedToDisk
    restart_worked = $restartWorked
    titles = $titles
    local_storage_file = $storageData
    error = $failure
    server_meta = Format-StorageProbeProcessMeta $serverMeta
    browser_one_meta = Format-StorageProbeProcessMeta $browserOneMetaValue
    browser_two_meta = Format-StorageProbeProcessMeta $browserTwoMeta
    browser_one_gone_before_restart = $browserOneGoneBeforeRestart
    browser_one_gone = $browserOneGone
    browser_two_gone = $browserTwoGone
    server_gone = $serverGone
  }
  Write-StorageProbeResult $result

  if ($failure -or -not $seedWorked -or -not $persistedToDisk -or -not $restartWorked) {
    exit 1
  }
}
