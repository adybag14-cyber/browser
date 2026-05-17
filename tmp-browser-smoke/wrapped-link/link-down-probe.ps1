[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8147,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

$repo = Resolve-LightpandaRepoRoot $PSScriptRoot
$root = Join-Path $repo "tmp-browser-smoke\wrapped-link"
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$browserOut = Join-Path $root "linkdown.browser.stdout.txt"
$browserErr = Join-Path $root "linkdown.browser.stderr.txt"
$serverOut = Join-Path $root "linkdown.server.stdout.txt"
$serverErr = Join-Path $root "linkdown.server.stderr.txt"
$png = Join-Path $root "linkdown.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$png -Force -ErrorAction SilentlyContinue

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$aliveAfterDown = $false
$failure = $null
$clickClientX = 133
$clickClientY = 186
$clickPoint = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind",$Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "http://$Host`:$Port/index.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "link-down probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/index.html","--window_width","240","--window_height","480","--screenshot_png",$png -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-LightpandaFileReady -Path $png -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $pngReady) { throw "link-down screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "link-down window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $clickPoint = New-Object SmokeProbeUser32+POINT
  $clickPoint.X = $clickClientX
  $clickPoint.Y = $clickClientY
  [void][SmokeProbeUser32]::ClientToScreen($hwnd, [ref]$clickPoint)
  [void][SmokeProbeUser32]::SetCursorPos($clickPoint.X, $clickPoint.Y)
  Start-Sleep -Milliseconds 100
  [SmokeProbeUser32]::SendLeftDown()
  Start-Sleep -Milliseconds 1500
  $aliveAfterDown = [bool](Get-Process -Id $browser.Id -ErrorAction SilentlyContinue)
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-LightpandaOwnedProbeProcess $server
  $browserMeta = Stop-LightpandaOwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    host = $Host
    port = $Port
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    click_client = [ordered]@{ x = $clickClientX; y = $clickClientY }
    click_screen = if ($clickPoint) { [ordered]@{ x = $clickPoint.X; y = $clickPoint.Y } } else { $null }
    alive_after_down = $aliveAfterDown
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
