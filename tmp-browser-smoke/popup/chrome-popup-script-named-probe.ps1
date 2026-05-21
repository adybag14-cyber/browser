[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8172,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. "$PSScriptRoot\..\tabs\TabProbeCommon.ps1"

$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-script-named"
$repo = $config.RepoRoot
$root = Join-Path $repo "tmp-browser-smoke\popup"
$browserExe = $config.BrowserExe
$profileRoot = $config.ProfileRoot
$origin = "http://$Host`:$Port"
$browserOut = Join-Path $root "chrome-popup-script-named.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-popup-script-named.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-popup-script-named.server.stdout.txt"
$serverErr = Join-Path $root "chrome-popup-script-named.server.stderr.txt"

Reset-TabProbeProfile $profileRoot
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Set-TabProbeProfileEnvironment $profileRoot

$server = $null
$browser = $null
$ready = $false
$firstWorked = $false
$secondWorked = $false
$reusedTargetWorked = $false
$serverSawOne = $false
$serverSawTwo = $false
$failure = $null
$titles = [ordered]@{}

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind",$Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "$origin/script-popup-named-index.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "script named popup server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/script-popup-named-index.html") -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd -eq [IntPtr]::Zero) { throw "script named popup window handle not found" }
  Show-SmokeWindow $hwnd

  $titles.initial = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Script Named Start" -Attempts 6 -PollMilliseconds $PollMilliseconds
  Start-Sleep -Milliseconds 1300
  Send-SmokeCtrlDigit 2
  $titles.second = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Script Named Result Two" -Attempts 30 -PollMilliseconds $PollMilliseconds
  $secondWorked = [bool]$titles.second
  if (-not $secondWorked) { throw "script named popup did not open second result" }

  Send-SmokeCtrlDigit 1
  $titles.returned = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Script Named Start" -Attempts 12 -PollMilliseconds $PollMilliseconds
  if (-not $titles.returned) { throw "script named popup did not preserve launcher tab" }

  Send-SmokeCtrlDigit 2
  $titles.reused = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Script Named Result Two" -Attempts 12 -PollMilliseconds $PollMilliseconds
  $reusedTargetWorked = [bool]$titles.reused
  if (-not $reusedTargetWorked) { throw "script named popup target tab was not reused" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
  if (Test-Path $serverErr) {
    $serverLog = Get-Content $serverErr -Raw
    $serverSawOne = $serverLog -match 'GET /script-popup-named-one\.html'
    $serverSawTwo = $serverLog -match 'GET /script-popup-named-two\.html'
  }
  $firstWorked = $serverSawOne
  if (-not $failure) {
    if (-not $serverSawOne) {
      $failure = "server did not observe script named result one request"
    } elseif (-not $serverSawTwo) {
      $failure = "server did not observe script named result two request"
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
