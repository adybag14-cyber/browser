[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8180,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-LightpandaRepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\layout-smoke"
$browserExe = Resolve-LightpandaBrowserExe $repo $BrowserExe
$serverScript = Join-Path $root "layout_server.py"
$common = Join-Path $root "LayoutProbeCommon.ps1"
. $common

$pageUrl = "http://$Host`:$Port/delayed-screenshot.html"
$outPng = Join-Path $root "delayed-screenshot.png"
$browserOut = Join-Path $root "delayed-screenshot.browser.stdout.txt"
$browserErr = Join-Path $root "delayed-screenshot.browser.stderr.txt"
$serverOut = Join-Path $root "delayed-screenshot.server.stdout.txt"
$serverErr = Join-Path $root "delayed-screenshot.server.stderr.txt"
$profileRoot = Join-Path $root "profile-delayed-screenshot"

Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Reset-ProfileRoot $profileRoot

$server = $null
$browser = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }
  if (-not (Test-Path -LiteralPath $serverScript)) { throw "layout smoke server script not found: $serverScript" }

  $python = Resolve-LightpandaPythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  if (-not (Wait-LightpandaHttpReady -Url $pageUrl -TimeoutSeconds $ServerReadyTimeoutSeconds -PollMilliseconds $PollMilliseconds)) {
    throw "layout smoke server did not become ready"
  }

  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  $started = Get-Date
  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed",$pageUrl,"--window_width","420","--window_height","320","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  try {
    if (-not (Wait-Screenshot $outPng)) { throw "delayed screenshot did not become ready" }
    $elapsedMs = [int]((Get-Date) - $started).TotalMilliseconds
    $red = Find-ColorBounds $outPng { param($c) $c.R -ge 180 -and $c.G -le 90 -and $c.B -le 90 }
    $result = [ordered]@{
      red = $red
      elapsed_ms = $elapsedMs
      delayed_content_visible = ($red.width -ge 160) -and ($red.height -ge 24)
      capture_waited = ($elapsedMs -ge 500)
    }
    $result.delayed_screenshot_worked = $result.delayed_content_visible -and $result.capture_waited
    if (-not $result.delayed_screenshot_worked) {
      throw "delayed screenshot probe captured before delayed content was painted"
    }
    $result | ConvertTo-Json -Depth 6
  }
  finally {
    $null = Stop-LightpandaOwnedProbeProcess $browser
    for ($i = 0; $i -lt 20; $i++) {
      if (-not $browser -or -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue)) { break }
      Start-Sleep -Milliseconds 100
    }
  }
}
finally {
  $null = Stop-LightpandaOwnedProbeProcess $server
  for ($i = 0; $i -lt 20; $i++) {
    if (-not $server -or -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue)) { break }
    Start-Sleep -Milliseconds 100
  }
}
