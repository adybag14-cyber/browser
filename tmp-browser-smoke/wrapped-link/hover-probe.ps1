[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8148,
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
$browserOut = Join-Path $root "hover.browser.stdout.txt"
$browserErr = Join-Path $root "hover.browser.stderr.txt"
$serverOut = Join-Path $root "hover.server.stdout.txt"
$serverErr = Join-Path $root "hover.server.stderr.txt"
$png = Join-Path $root "hover.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$png -Force -ErrorAction SilentlyContinue

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$aliveAfterHover = $false
$failure = $null
$hoverClientX = 133
$hoverClientY = 186
$hoverPoint = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$Port,"--bind",$Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url "http://$Host`:$Port/index.html" -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds
  if (-not $ready) { throw "hover probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://$Host`:$Port/index.html","--window_width","240","--window_height","480","--screenshot_png",$png -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-LightpandaFileReady -Path $png -Attempts $WindowReadyAttempts -PollMilliseconds $PollMilliseconds
  if (-not $pngReady) { throw "hover screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "hover window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $hoverPoint = New-Object SmokeProbeUser32+POINT
  $hoverPoint.X = $hoverClientX
  $hoverPoint.Y = $hoverClientY
  [void][SmokeProbeUser32]::ClientToScreen($hwnd, [ref]$hoverPoint)
  [void][SmokeProbeUser32]::SetCursorPos($hoverPoint.X, $hoverPoint.Y)
  Start-Sleep -Milliseconds 1500
  $aliveAfterHover = [bool](Get-Process -Id $browser.Id -ErrorAction SilentlyContinue)
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
    hover_client = [ordered]@{ x = $hoverClientX; y = $hoverClientY }
    hover_screen = if ($hoverPoint) { [ordered]@{ x = $hoverPoint.X; y = $hoverPoint.Y } } else { $null }
    alive_after_hover = $aliveAfterHover
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
