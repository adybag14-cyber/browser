[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8167,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. "$PSScriptRoot\..\tabs\TabProbeCommon.ps1"

$config = Resolve-TabProbeConfig -StartPath $PSScriptRoot -RepoRoot $RepoRoot -BrowserExe $BrowserExe -ProfileName "profile-form-post-official"
$repo = $config.RepoRoot
$root = Join-Path $repo "tmp-browser-smoke\popup"
$browserExe = $config.BrowserExe
$profileRoot = $config.ProfileRoot
$origin = "http://$Host`:$Port"
$serverScript = Join-Path $root "popup_form_server.py"
$browserOut = Join-Path $root "chrome-popup-form-post.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-popup-form-post.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-popup-form-post.server.stdout.txt"
$serverErr = Join-Path $root "chrome-popup-form-post.server.stderr.txt"

Reset-TabProbeProfile $profileRoot
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Set-TabProbeProfileEnvironment $profileRoot

$server = $null
$browser = $null
$ready = $false
$formWorked = $false
$serverSawPost = $false
$failure = $null
$titles = [ordered]@{}

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript,$Port)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "$origin/form-post-index.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "popup form post probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","$origin/form-post-index.html") -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if ($hwnd -eq [IntPtr]::Zero) { throw "popup form post probe window handle not found" }
  Show-SmokeWindow $hwnd

  $titles.initial = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Form Post Start" -Attempts 40 -PollMilliseconds $PollMilliseconds
  if (-not $titles.initial) { throw "popup form post probe initial title missing" }

  Send-SmokeSpace
  $titles.result = Wait-TabTitle -ProcessId $browser.Id -Needle "Popup Form Post Result popup-post" -Attempts 40 -PollMilliseconds $PollMilliseconds
  $formWorked = [bool]$titles.result
  if (-not $formWorked) { throw "popup form post probe did not open result tab" }

  if (Test-Path $serverErr) {
    $serverSawPost = Select-String -Path $serverErr -Pattern "POPUP_POST_BODY q=popup-post" -Quiet
  }
  if (-not $serverSawPost) { throw "popup form post probe server did not record POST body" }
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
    form_worked = $formWorked
    server_saw_post = $serverSawPost
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
