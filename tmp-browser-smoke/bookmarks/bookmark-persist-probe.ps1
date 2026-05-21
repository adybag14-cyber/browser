[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8149,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")
. (Join-Path $PSScriptRoot "BookmarkProbeCommon.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "tabs\TabProbeCommon.ps1")

$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-bookmark-persist"
$repo = $config.RepoRoot
$browserExe = $config.BrowserExe
$profileRoot = $config.ProfileRoot
$root = Join-Path $repo "tmp-browser-smoke\bookmarks"
$serverRoot = Join-Path $repo "tmp-browser-smoke\wrapped-link"
$origin = "http://$Host`:$Port"
$indexUrl = "$origin/index.html"
$nextUrl = "$origin/next.html"
$browser1ReadyPng = Join-Path $root "bookmark-run1.ready.png"
$browser2ReadyPng = Join-Path $root "bookmark-run2.ready.png"
$browser1Out = Join-Path $root "bookmark-run1.stdout.txt"
$browser1Err = Join-Path $root "bookmark-run1.stderr.txt"
$browser2Out = Join-Path $root "bookmark-run2.stdout.txt"
$browser2Err = Join-Path $root "bookmark-run2.stderr.txt"
$serverOut = Join-Path $root "bookmark-server.stdout.txt"
$serverErr = Join-Path $root "bookmark-server.stderr.txt"

Reset-TabProbeProfile $profileRoot
Remove-Item $browser1ReadyPng,$browser2ReadyPng,$browser1Out,$browser1Err,$browser2Out,$browser2Err,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Set-TabProbeProfileEnvironment $profileRoot
Set-BookmarkProbeEntries @()

function Count-Hits([string]$Pattern) {
  if (-not (Test-Path $serverErr)) { return 0 }
  return ([regex]::Matches((Get-Content $serverErr -Raw), $Pattern)).Count
}

function Wait-SmokeArtifact([string]$Path, [string]$Label) {
  $ready = Wait-LightpandaFileReady -Path $Path -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $ready) {
    throw "bookmark persist probe $Label did not become ready"
  }
}

$server = $null
$browser1 = $null
$browser2 = $null
$serverMeta = $null
$browser1Meta = $null
$browser2Meta = $null
$ready = $false
$bookmarkAdded = $false
$persistedWorked = $false
$bookmarkContent = ""
$bookmarkFile = Get-BookmarkProbeFile
$overlayPoint = $null
$browser1Title = $null
$browser2Title = $null
$initialIndexHits = 0
$afterOverlayIndexHits = 0
$failure = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind",$Host)) -WorkingDirectory $serverRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url $indexUrl -TimeoutSeconds 15 -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "bookmark persist probe server did not become ready" }

  $browser1 = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$indexUrl,"--window_width","320","--window_height","420","--screenshot_png",$browser1ReadyPng) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browser1Out -RedirectStandardError $browser1Err
  $hwnd1 = Wait-TabWindowHandle -ProcessId $browser1.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd1 -eq [IntPtr]::Zero) { throw "bookmark persist probe first window handle not found" }
  Wait-SmokeArtifact $browser1ReadyPng "run1 screenshot"
  Show-SmokeWindow $hwnd1
  Start-Sleep -Milliseconds $PollMilliseconds
  $browser1Title = Get-SmokeWindowTitle $hwnd1
  Send-SmokeCtrlD

  $bookmarkContent = Wait-BookmarkProbeContains $indexUrl
  $bookmarkAdded = $true

  $browser1Meta = Stop-OwnedProbeProcess $browser1
  $browser1 = $null
  Start-Sleep -Milliseconds 300

  $initialIndexHits = Count-Hits 'GET /index\.html HTTP/1\.1" 200'
  $browser2 = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed",$nextUrl,"--window_width","320","--window_height","420","--screenshot_png",$browser2ReadyPng) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browser2Out -RedirectStandardError $browser2Err
  $hwnd2 = Wait-TabWindowHandle -ProcessId $browser2.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd2 -eq [IntPtr]::Zero) { throw "bookmark persist probe second window handle not found" }
  Wait-SmokeArtifact $browser2ReadyPng "run2 screenshot"
  Show-SmokeWindow $hwnd2
  Start-Sleep -Milliseconds $PollMilliseconds
  $browser2Title = Get-SmokeWindowTitle $hwnd2
  Send-SmokeCtrlShiftB
  Start-Sleep -Milliseconds 350

  $overlayPoint = Invoke-SmokeClientClick $hwnd2 80 140
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $afterOverlayIndexHits = Count-Hits 'GET /index\.html HTTP/1\.1" 200'
    if ($afterOverlayIndexHits -gt $initialIndexHits) {
      $persistedWorked = $true
      break
    }
  }
  if (-not $persistedWorked) { throw "bookmark persist probe did not navigate from persisted bookmark overlay" }
} catch {
  $failure = $_.Exception.Message
} finally {
  if (-not $serverMeta) {
    $serverMeta = Stop-OwnedProbeProcess $server
  }
  if (-not $browser1Meta) {
    $browser1Meta = Stop-OwnedProbeProcess $browser1
  }
  if (-not $browser2Meta) {
    $browser2Meta = Stop-OwnedProbeProcess $browser2
  }
  Start-Sleep -Milliseconds 250

  [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    profile_root = $profileRoot
    host = $Host
    port = $Port
    server_pid = if ($server) { $server.Id } else { 0 }
    browser1_pid = if ($browser1Meta) { $browser1Meta.ProcessId } elseif ($browser1) { $browser1.Id } else { 0 }
    browser2_pid = if ($browser2Meta) { $browser2Meta.ProcessId } elseif ($browser2) { $browser2.Id } else { 0 }
    ready = $ready
    bookmark_added = $bookmarkAdded
    persisted_worked = $persistedWorked
    bookmark_file = $bookmarkFile
    bookmark_content = $bookmarkContent
    browser1_ready_png = $browser1ReadyPng
    browser2_ready_png = $browser2ReadyPng
    browser1_title = $browser1Title
    browser2_title = $browser2Title
    initial_index_hits = $initialIndexHits
    after_overlay_index_hits = $afterOverlayIndexHits
    overlay_point = $overlayPoint
    error = $failure
    server_meta = $serverMeta
    browser1_meta = $browser1Meta
    browser2_meta = $browser2Meta
    browser1_gone = if ($browser1Meta) { -not (Get-Process -Id $browser1Meta.ProcessId -ErrorAction SilentlyContinue) } elseif ($browser1) { -not (Get-Process -Id $browser1.Id -ErrorAction SilentlyContinue) } else { $true }
    browser2_gone = if ($browser2Meta) { -not (Get-Process -Id $browser2Meta.ProcessId -ErrorAction SilentlyContinue) } elseif ($browser2) { -not (Get-Process -Id $browser2.Id -ErrorAction SilentlyContinue) } else { $true }
    server_gone = if ($serverMeta) { -not (Get-Process -Id $serverMeta.ProcessId -ErrorAction SilentlyContinue) } elseif ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }
  } | ConvertTo-Json -Depth 7
}

if ($failure) {
  exit 1
}
