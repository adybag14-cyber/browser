$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")

$repo = Resolve-LightpandaRepoRoot $PSScriptRoot
$port = 8137
$browserExe = Resolve-LightpandaBrowserExe $repo $null
$python = Resolve-LightpandaPythonCommand
$root = Join-Path $repo "tmp-browser-smoke\flow-layout"
$outPng = Join-Path $root "flow-layout.png"
$browserOut = Join-Path $root "browser.stdout.txt"
$browserErr = Join-Path $root "browser.stderr.txt"
$serverOut = Join-Path $root "server.stdout.txt"
$serverErr = Join-Path $root "server.stderr.txt"
$pageUrl = "http://127.0.0.1:$port/index.html"

Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$analysis = $null
$failure = $null

try {
  if (-not (Test-Path -LiteralPath $browserExe)) { throw "headed browser binary not found: $browserExe" }

  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m","http.server",$port,"--bind","127.0.0.1")) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  $ready = Wait-LightpandaHttpReady -Url $pageUrl -TimeoutSeconds 15 -PollMilliseconds 250
  if (-not $ready) { throw "localhost probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640","--screenshot_png",$outPng,$pageUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $pngReady = Wait-LightpandaFileReady -Path $outPng -Attempts 60 -PollMilliseconds 250
  if (-not $pngReady) { throw "flow layout screenshot did not become ready" }

  Add-Type -AssemblyName System.Drawing
  $bmp = [System.Drawing.Bitmap]::new($outPng)
  try {
    $red = [ordered]@{min_x=$null; min_y=$null; max_x=$null; max_y=$null; count=0}
    $green = [ordered]@{min_x=$null; min_y=$null; max_x=$null; max_y=$null; count=0}
    for ($y = 0; $y -lt $bmp.Height; $y++) {
      for ($x = 0; $x -lt $bmp.Width; $x++) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.R -ge 180 -and $c.G -le 90 -and $c.B -le 90) {
          if ($null -eq $red.min_x -or $x -lt $red.min_x) { $red.min_x = $x }
          if ($null -eq $red.min_y -or $y -lt $red.min_y) { $red.min_y = $y }
          if ($null -eq $red.max_x -or $x -gt $red.max_x) { $red.max_x = $x }
          if ($null -eq $red.max_y -or $y -gt $red.max_y) { $red.max_y = $y }
          $red.count++
        }
        if ($c.G -ge 100 -and $c.R -le 120 -and $c.B -le 120) {
          if ($null -eq $green.min_x -or $x -lt $green.min_x) { $green.min_x = $x }
          if ($null -eq $green.min_y -or $y -lt $green.min_y) { $green.min_y = $y }
          if ($null -eq $green.max_x -or $x -gt $green.max_x) { $green.max_x = $x }
          if ($null -eq $green.max_y -or $y -gt $green.max_y) { $green.max_y = $y }
          $green.count++
        }
      }
    }
    $analysis = [ordered]@{
      width = $bmp.Width
      height = $bmp.Height
      red = $red
      green = $green
      vertical_gap = if ($null -ne $red.max_y -and $null -ne $green.min_y) { $green.min_y - $red.max_y - 1 } else { $null }
      green_below_red = if ($null -ne $red.max_y -and $null -ne $green.min_y) { $green.min_y -gt $red.max_y } else { $false }
    }
  } finally {
    $bmp.Dispose()
  }
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
    page_url = $pageUrl
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    screenshot_path = $outPng
    screenshot_length = if (Test-Path $outPng) { (Get-Item $outPng).Length } else { 0 }
    analysis = $analysis
    error = $failure
    server_meta = $serverMeta
    browser_meta = $browserMeta
    browser_gone = $browserGone
    server_gone = $serverGone
  } | ConvertTo-Json -Depth 6
}

if ($failure) {
  exit 1
}
