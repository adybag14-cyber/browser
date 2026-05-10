$ErrorActionPreference = "Stop"

$root = "C:\Users\adyba\src\lightpanda-browser\tmp-browser-smoke\layout-smoke"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$serverScript = Join-Path $root "layout_server.py"
$common = Join-Path $root "LayoutProbeCommon.ps1"
. $common
. "$PSScriptRoot\..\common\Win32Input.ps1"

$port = 8181
$pageUrl = "http://127.0.0.1:$port/legacy-table.html"
$submittedQuery = "headedQZ"
$outPng = Join-Path $root "legacy-table-enter-submit.png"
$browserOut = Join-Path $root "legacy-table-enter-submit.browser.stdout.txt"
$browserErr = Join-Path $root "legacy-table-enter-submit.browser.stderr.txt"
$serverOut = Join-Path $root "legacy-table-enter-submit.server.stdout.txt"
$serverErr = Join-Path $root "legacy-table-enter-submit.server.stderr.txt"
$profileRoot = Join-Path $root "profile-legacy-table-enter-submit"

Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Reset-ProfileRoot $profileRoot

$server = $null
$browser = $null
$pngReady = $false
$hwnd = [IntPtr]::Zero
$shellBounds = $null
$clickPoint = $null
$submitWorked = $false
$failure = $null

try {
  $server = Start-Process -FilePath "python" -ArgumentList $serverScript,$port -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  if (-not (Wait-HttpReady $pageUrl)) { throw "legacy table enter-submit server did not become ready" }

  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse",$pageUrl,"--window_width","960","--window_height","540","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  if (-not (Wait-Screenshot $outPng)) { throw "legacy table enter-submit screenshot did not become ready" }
  $pngReady = $true

  $shellBounds = Find-ColorBoundsRegion $outPng { param($c) ($c.R -ge 195 -and $c.R -le 215) -and ($c.G -ge 195 -and $c.G -le 215) -and ($c.B -ge 195 -and $c.B -le 215) } 180 220 780 340

  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "legacy table enter-submit window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $clickX = [int][Math]::Floor(($shellBounds.left + $shellBounds.right) / 2)
  $clickY = [int][Math]::Floor(($shellBounds.top + $shellBounds.bottom) / 2)
  $clickPoint = Invoke-SmokeClientClick $hwnd $clickX $clickY
  Start-Sleep -Milliseconds 150
  Send-SmokeText $submittedQuery
  Start-Sleep -Milliseconds 150
  Send-SmokeEnter

  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 200
    if (Test-Path $serverErr) {
      $serverLog = Get-Content $serverErr -Raw
      if ($serverLog -match ('GET /legacy-table\.html\?q=' + [regex]::Escape($submittedQuery) + ' HTTP/1\.1" 200')) {
        $submitWorked = $true
        break
      }
    }
  }
  if (-not $submitWorked) {
    throw "legacy table enter-submit probe did not observe the submitted query in the server log"
  }

  [ordered]@{
    ready = $true
    screenshot_ready = $pngReady
    shell_bounds = $shellBounds
    click_screen = if ($null -ne $clickPoint) { [ordered]@{ x = $clickPoint.X; y = $clickPoint.Y } } else { $null }
    submitted_query = $submittedQuery
    submit_worked = $submitWorked
  } | ConvertTo-Json -Depth 6
}
catch {
  $failure = $_.Exception.Message
}
finally {
  if ($browser) {
    Stop-VerifiedProcess $browser.Id
    for ($i = 0; $i -lt 20; $i++) {
      if (-not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue)) { break }
      Start-Sleep -Milliseconds 100
    }
  }
  if ($server) {
    Stop-VerifiedProcess $server.Id
    for ($i = 0; $i -lt 20; $i++) {
      if (-not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue)) { break }
      Start-Sleep -Milliseconds 100
    }
  }
}

if ($failure) {
  throw $failure
}
