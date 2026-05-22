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

$pageUrl = "http://$Host`:$Port/selector-forgiving.html"
$outPng = Join-Path $root "selector-forgiving.png"
$browserOut = Join-Path $root "selector-forgiving.browser.stdout.txt"
$browserErr = Join-Path $root "selector-forgiving.browser.stderr.txt"
$serverOut = Join-Path $root "selector-forgiving.server.stdout.txt"
$serverErr = Join-Path $root "selector-forgiving.server.stderr.txt"
$profileRoot = Join-Path $root "profile-selector-forgiving"

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
  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed",$pageUrl,"--window_width","520","--window_height","320","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  try {
    if (-not (Wait-Screenshot $outPng)) { throw "selector forgiving screenshot did not become ready" }
    $red = Find-ColorBounds $outPng { param($c) $c.R -ge 180 -and $c.G -le 90 -and $c.B -le 90 }
    $blueFound = $true
    try {
      $null = Find-ColorBounds $outPng { param($c) $c.B -ge 180 -and $c.R -le 90 -and $c.G -le 150 }
    } catch {
      $blueFound = $false
    }

    $result = [ordered]@{
      red = $red
      red_visible = $red.width -ge 160
      duplicate_hidden = -not $blueFound
    }
    $result.selector_forgiving_worked = $result.red_visible -and $result.duplicate_hidden
    if (-not $result.selector_forgiving_worked) {
      throw "selector forgiving probe did not preserve the valid branch while hiding the duplicate"
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
