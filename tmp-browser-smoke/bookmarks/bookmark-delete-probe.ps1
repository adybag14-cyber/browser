[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8152,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")
. (Join-Path $PSScriptRoot "BookmarkProbeCommon.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "tabs\TabProbeCommon.ps1")

$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-bookmark-delete"
$repo = $config.RepoRoot
$browserExe = $config.BrowserExe
$profileRoot = $config.ProfileRoot
$root = Join-Path $repo "tmp-browser-smoke\bookmarks"
$serverRoot = Join-Path $repo "tmp-browser-smoke\wrapped-link"
$readyPng = Join-Path $root "bookmark-delete.ready.png"
$browserOut = Join-Path $root "bookmark-delete.browser.stdout.txt"
$browserErr = Join-Path $root "bookmark-delete.browser.stderr.txt"
$serverOut = Join-Path $root "bookmark-delete.server.stdout.txt"
$serverErr = Join-Path $root "bookmark-delete.server.stderr.txt"
$origin = "http://$Host`:$Port"
$url = "$origin/index.html"

Reset-TabProbeProfile $profileRoot
Remove-Item $readyPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Set-TabProbeProfileEnvironment $profileRoot

function Wait-SmokeArtifact([string]$Path, [string]$Label) {
  $ready = Wait-LightpandaFileReady -Path $Path -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $ready) {
    throw "bookmark delete probe $Label did not become ready"
  }
}

$server = $null
$browser = $null
$ready = $false
$deleteWorked = $false
$remainingContent = ""
$backup = $null
$failure = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $backup = Backup-BookmarkProbeFile
  Set-BookmarkProbeEntries @($url)

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind",$Host)) -WorkingDirectory $serverRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url $url -TimeoutSeconds 15 -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "bookmark delete probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","$origin/next.html","--window_width","320","--window_height","420","--screenshot_png",$readyPng) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd -eq [IntPtr]::Zero) { throw "bookmark delete probe window handle not found" }
  Wait-SmokeArtifact $readyPng "screenshot"
  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds $PollMilliseconds

  Send-SmokeCtrlShiftB
  Start-Sleep -Milliseconds $PollMilliseconds
  Send-SmokeDelete
  $remainingContent = Wait-BookmarkProbeNotContains $url
  $deleteWorked = $true
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  Start-Sleep -Milliseconds 250
  Restore-BookmarkProbeFile $backup

  [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    profile_root = $profileRoot
    host = $Host
    port = $Port
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    delete_worked = $deleteWorked
    remaining_content = $remainingContent
    bookmark_file = Get-BookmarkProbeFile
    error = $failure
    server_meta = $serverMeta
    browser_meta = $browserMeta
    browser_gone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
    server_gone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }
    backup_restored = if ($backup) { -not (Test-Path $backup) } else { $true }
  } | ConvertTo-Json -Depth 7
}

if ($failure) {
  exit 1
}
