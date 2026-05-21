[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8168,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path $PSScriptRoot "..\tabs\TabProbeCommon.ps1")

$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-named-anchor"
$repo = $config.RepoRoot
$root = Join-Path $repo "tmp-browser-smoke\popup"
$browserExe = $config.BrowserExe
$profileRoot = $config.ProfileRoot
$origin = "http://$Host`:$Port"
$browserOut = Join-Path $root "chrome-popup-named-anchor.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-popup-named-anchor.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-popup-named-anchor.server.stdout.txt"
$serverErr = Join-Path $root "chrome-popup-named-anchor.server.stderr.txt"
$screenshotPath = Join-Path $root "chrome-popup-named-anchor.png"

Reset-TabProbeProfile $profileRoot
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$screenshotPath -Force -ErrorAction SilentlyContinue
Set-TabProbeProfileEnvironment $profileRoot

Add-Type -AssemblyName System.Drawing

function Get-ColorBounds(
  [string]$Path,
  [scriptblock]$Predicate,
  [int]$MinX = 0,
  [int]$MinY = 0,
  [int]$MaxX = -1,
  [int]$MaxY = -1
) {
  $bitmap = [System.Drawing.Bitmap]::FromFile($Path)
  try {
    $foundMinX = 99999
    $foundMinY = 99999
    $foundMaxX = -1
    $foundMaxY = -1
    $scanMaxX = if ($MaxX -ge 0) { [Math]::Min($MaxX, $bitmap.Width - 1) } else { $bitmap.Width - 1 }
    $scanMaxY = if ($MaxY -ge 0) { [Math]::Min($MaxY, $bitmap.Height - 1) } else { $bitmap.Height - 1 }
    for ($y = [Math]::Max(0, $MinY); $y -le $scanMaxY; $y++) {
      for ($x = [Math]::Max(0, $MinX); $x -le $scanMaxX; $x++) {
        $color = $bitmap.GetPixel($x, $y)
        if (& $Predicate $color) {
          if ($x -lt $foundMinX) { $foundMinX = $x }
          if ($y -lt $foundMinY) { $foundMinY = $y }
          if ($x -gt $foundMaxX) { $foundMaxX = $x }
          if ($y -gt $foundMaxY) { $foundMaxY = $y }
        }
      }
    }
    if ($foundMaxX -lt $foundMinX -or $foundMaxY -lt $foundMinY) { return $null }
    return [ordered]@{
      min_x = $foundMinX
      min_y = $foundMinY
      max_x = $foundMaxX
      max_y = $foundMaxY
      click_x = [int][Math]::Floor(($foundMinX + $foundMaxX) / 2)
      click_y = [int][Math]::Floor(($foundMinY + $foundMaxY) / 2)
    }
  } finally {
    $bitmap.Dispose()
  }
}

$server = $null
$browser = $null
$ready = $false
$firstWorked = $false
$secondWorked = $false
$reusedTargetWorked = $false
$failure = $null
$titles = [ordered]@{}
$firstTargetBounds = $null
$secondTargetBounds = $null
$serverSawOne = $false
$serverSawTwo = $false

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind",$Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "$origin/named-target-index.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "named target anchor server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","--screenshot_png",$screenshotPath,"$origin/named-target-index.html") -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd -eq [IntPtr]::Zero) { throw "named target anchor window handle not found" }
  Show-SmokeWindow $hwnd

  $titles.initial = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Named Anchor Start" -Attempts 40 -PollMilliseconds $PollMilliseconds
  if (-not $titles.initial) { throw "named target anchor initial title missing" }

  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    if (Test-Path $screenshotPath) { break }
  }
  if (-not (Test-Path $screenshotPath)) { throw "named target anchor screenshot missing" }

  $firstTargetBounds = Get-ColorBounds $screenshotPath { param($c) $c.R -gt 180 -and $c.B -gt 80 -and $c.G -lt 100 } 20 100
  if (-not $firstTargetBounds) { throw "named target anchor first target bounds missing" }
  $secondTargetBounds = Get-ColorBounds $screenshotPath { param($c) $c.R -gt 180 -and $c.G -gt 100 -and $c.B -lt 80 } 20 180
  if (-not $secondTargetBounds) { throw "named target anchor second target bounds missing" }

  [void](Invoke-SmokeClientClick $hwnd $firstTargetBounds.click_x $firstTargetBounds.click_y)
  $titles.first = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Named Anchor Result One" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $firstWorked = [bool]$titles.first
  if (-not $firstWorked) { throw "first named target anchor click did not open result one" }

  $sourceTabPoint = Get-TabClientPoint -TabIndex 0 -TabCount 2
  [void](Invoke-SmokeClientClick $hwnd $sourceTabPoint.X $sourceTabPoint.Y)
  $titles.returned = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Named Anchor Start" -Attempts 40 -PollMilliseconds $PollMilliseconds
  if (-not $titles.returned) { throw "named target probe did not return to launcher tab" }

  [void](Invoke-SmokeClientClick $hwnd $secondTargetBounds.click_x $secondTargetBounds.click_y)
  $titles.second = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Named Anchor Result Two" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $secondWorked = [bool]$titles.second
  if (-not $secondWorked) { throw "second named target anchor click did not open result two" }

  [void](Invoke-SmokeClientClick $hwnd $sourceTabPoint.X $sourceTabPoint.Y)
  $titles.returned_again = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Named Anchor Start" -Attempts 40 -PollMilliseconds $PollMilliseconds
  if (-not $titles.returned_again) { throw "named target probe did not return to launcher tab after second click" }

  Send-SmokeCtrlTab
  $titles.reused = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Named Anchor Result Two" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $reusedTargetWorked = [bool]$titles.reused
  if (-not $reusedTargetWorked) { throw "named target popup tab was not reused on second click" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
  if (Test-Path $serverErr) {
    $serverLog = Get-Content $serverErr -Raw
    $serverSawOne = $serverLog -match 'GET /named-target-one\.html'
    $serverSawTwo = $serverLog -match 'GET /named-target-two\.html'
  }
  if (-not $failure) {
    if (-not $serverSawOne) {
      $failure = "server did not observe named-target-one request"
    } elseif (-not $serverSawTwo) {
      $failure = "server did not observe named-target-two request"
    }
  }
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
    first_worked = $firstWorked
    second_worked = $secondWorked
    reused_target_worked = $reusedTargetWorked
    server_saw_one = $serverSawOne
    server_saw_two = $serverSawTwo
    first_target_bounds = $firstTargetBounds
    second_target_bounds = $secondTargetBounds
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
