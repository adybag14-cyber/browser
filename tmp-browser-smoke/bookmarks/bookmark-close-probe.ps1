[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [int]$Port = 8155,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. "$PSScriptRoot\..\common\Win32Input.ps1"
. "$PSScriptRoot\BookmarkProbeCommon.ps1"

$repo = if ([string]::IsNullOrWhiteSpace($RepoRoot)) { Resolve-LightpandaRepoRoot $PSScriptRoot } else { $RepoRoot }
$serverRoot = Join-Path $repo "tmp-browser-smoke\wrapped-link"
$bookmarksRoot = Join-Path $repo "tmp-browser-smoke\bookmarks"
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$readyPng = Join-Path $bookmarksRoot "bookmark-close.ready.png"
$browserOut = Join-Path $bookmarksRoot "bookmark-close.browser.stdout.txt"
$browserErr = Join-Path $bookmarksRoot "bookmark-close.browser.stderr.txt"
$serverOut = Join-Path $bookmarksRoot "bookmark-close.server.stdout.txt"
$serverErr = Join-Path $bookmarksRoot "bookmark-close.server.stderr.txt"
Remove-Item $readyPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

Add-Type -AssemblyName System.Drawing

function Wait-SmokeWindow([System.Diagnostics.Process]$Process) {
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $proc = Get-Process -Id $Process.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      return [IntPtr]$proc.MainWindowHandle
    }
  }
  throw "bookmark close probe window handle not found"
}

function Wait-SmokeArtifact([string]$Path, [string]$Label) {
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    if ((Test-Path $Path) -and ((Get-Item $Path).Length -gt 0)) {
      return
    }
  }
  throw "bookmark close probe $Label did not become ready"
}

function Get-ColorBounds([System.Drawing.Bitmap]$Bitmap, [scriptblock]$Matcher) {
  $bounds = [ordered]@{min_x=$null; min_y=$null; max_x=$null; max_y=$null; count=0}
  for ($y = 0; $y -lt $Bitmap.Height; $y++) {
    for ($x = 0; $x -lt $Bitmap.Width; $x++) {
      $c = $Bitmap.GetPixel($x, $y)
      if (& $Matcher $c) {
        if ($null -eq $bounds.min_x -or $x -lt $bounds.min_x) { $bounds.min_x = $x }
        if ($null -eq $bounds.min_y -or $y -lt $bounds.min_y) { $bounds.min_y = $y }
        if ($null -eq $bounds.max_x -or $x -gt $bounds.max_x) { $bounds.max_x = $x }
        if ($null -eq $bounds.max_y -or $y -gt $bounds.max_y) { $bounds.max_y = $y }
        $bounds.count++
      }
    }
  }
  return $bounds
}

function Count-Hits([string]$Pattern) {
  if (-not (Test-Path $serverErr)) { return 0 }
  return ([regex]::Matches((Get-Content $serverErr -Raw), $Pattern)).Count
}

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$closeWorked = $false
$navigateWorked = $false
$initialNextHits = 0
$afterNextHits = 0
$backup = $null
$failure = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }
  if (-not (Test-Path -LiteralPath $serverRoot)) { throw "wrapped link probe root not found: $serverRoot" }

  $backup = Backup-BookmarkProbeFile
  Set-BookmarkProbeEntries @("http://127.0.0.1:$Port/index.html")

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind","127.0.0.1")) -WorkingDirectory $serverRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "http://127.0.0.1:$Port/index.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "bookmark close probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$Port/index.html","--window_width","320","--window_height","420","--screenshot_png",$readyPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  Wait-SmokeArtifact $readyPng "screenshot"
  $pngReady = $true

  $hwnd = Wait-SmokeWindow $browser

  $bmp = [System.Drawing.Bitmap]::new($readyPng)
  try {
    $blue = Get-ColorBounds $bmp { param($c) $c.B -ge 150 -and $c.R -le 90 -and $c.G -le 120 }
  } finally {
    $bmp.Dispose()
  }
  if ($null -eq $blue.min_x) { throw "bookmark close probe could not find wrapped link" }

  $linkX = [int][Math]::Floor(($blue.min_x + $blue.max_x) / 2)
  $linkY = [int][Math]::Floor(($blue.min_y + $blue.max_y) / 2)
  $initialNextHits = Count-Hits 'GET /next\.html HTTP/1\.1" 200'

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds $PollMilliseconds
  Send-SmokeCtrlShiftB
  Start-Sleep -Milliseconds $PollMilliseconds
  [void](Invoke-SmokeClientClick $hwnd 286 115)
  Start-Sleep -Milliseconds $PollMilliseconds
  $closeWorked = $true

  Show-SmokeWindow $hwnd
  [void](Invoke-SmokeClientClick $hwnd $linkX $linkY)

  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $afterNextHits = Count-Hits 'GET /next\.html HTTP/1\.1" 200'
    if ($afterNextHits -gt $initialNextHits) {
      $navigateWorked = $true
      break
    }
  }
  if (-not $navigateWorked) { throw "bookmark close probe did not allow page navigation after close button" }
} catch {
  $failure = $_.Exception.Message
} finally {
  if ($browser) { Stop-Process -Id $browser.Id -Force -ErrorAction SilentlyContinue }
  if ($server) { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Milliseconds $PollMilliseconds
  Restore-BookmarkProbeFile $backup

  [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    port = $Port
    ready_png = $readyPng
    server_root = $serverRoot
    server_ready_timeout_seconds = $ServerReadyTimeoutSeconds
    poll_milliseconds = $PollMilliseconds
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    close_worked = $closeWorked
    navigate_worked = $navigateWorked
    initial_next_hits = $initialNextHits
    after_next_hits = $afterNextHits
    bookmark_file = Get-BookmarkProbeFile
    error = $failure
    browser_gone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
    server_gone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }
    backup_restored = if ($backup) { -not (Test-Path $backup) } else { $true }
  } | ConvertTo-Json -Depth 6
}

if ($failure) {
  exit 1
}
