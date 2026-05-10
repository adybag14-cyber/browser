$ErrorActionPreference = "Stop"

$root = "C:\Users\adyba\src\lightpanda-browser\tmp-browser-smoke\layout-smoke"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$serverScript = Join-Path $root "layout_server.py"
$common = Join-Path $root "LayoutProbeCommon.ps1"
$win32Common = Join-Path $root "..\common\Win32Input.ps1"
. $common
. $win32Common

$port = 8181
$pageUrl = "http://127.0.0.1:$port/google-submit-timing.html"
$outPng = Join-Path $root "google-submit-timing.png"
$browserOut = Join-Path $root "google-submit-timing.browser.stdout.txt"
$browserErr = Join-Path $root "google-submit-timing.browser.stderr.txt"
$serverOut = Join-Path $root "google-submit-timing.server.stdout.txt"
$serverErr = Join-Path $root "google-submit-timing.server.stderr.txt"
$profileRoot = Join-Path $root "profile-google-submit-timing"

Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue
Reset-ProfileRoot $profileRoot

$server = Start-Process -FilePath "python" -ArgumentList $serverScript,$port -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
$browser = $null
$hwnd = [IntPtr]::Zero
$shellBounds = $null
$titleBefore = $null
$titleAfterType = $null
$titleAfterEnter = $null
$submitWorked = $false
$keypressBeforeSubmit = $false
$clickClientX = $null
$clickClientY = $null
$clickPoint = $null
$failure = $null

try {
  if (-not (Wait-HttpReady $pageUrl)) { throw "layout smoke server did not become ready" }

  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot
  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse",$pageUrl,"--window_width","960","--window_height","540","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr

  if (-not (Wait-Screenshot $outPng)) { throw "google submit timing screenshot did not become ready" }

  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google submit timing window handle not found" }

  $shellBounds = Find-ColorBoundsRegion $outPng { param($c) ($c.R -ge 195 -and $c.R -le 215) -and ($c.G -ge 195 -and $c.G -le 215) -and ($c.B -ge 195 -and $c.B -le 215) } 180 220 780 340
  $clickClientX = [int][Math]::Floor(($shellBounds.left + $shellBounds.right) / 2)
  $clickClientY = [int][Math]::Floor(($shellBounds.top + $shellBounds.bottom) / 2)

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $titleBefore = Get-SmokeWindowTitle $hwnd
  $clickPoint = Invoke-SmokeClientClick $hwnd $clickClientX $clickClientY
  Start-Sleep -Milliseconds 120
  Send-SmokeText "QZ"

  $titleAfterType = $titleBefore
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 150
    $titleAfterType = Get-SmokeWindowTitle $hwnd
    if ($titleAfterType -like "Google Timing Input QZ*") { break }
  }
  if ($titleAfterType -notlike "Google Timing Input QZ*") { throw "google submit timing probe did not observe text input after typing" }

  Send-SmokeEnter
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 150
    $titleAfterEnter = Get-SmokeWindowTitle $hwnd
    if ($titleAfterEnter -like "Google Timing Submitted*QZ*") {
      $submitWorked = $true
      $keypressBeforeSubmit = $titleAfterEnter -like "*keydown,keypress,submit*QZ*"
      break
    }
  }
  if (-not $submitWorked) { throw "google submit timing probe did not reach the submitted page" }
  if (-not $keypressBeforeSubmit) { throw "google submit timing probe did not preserve keypress before submit" }

  [ordered]@{
    shell_bounds = $shellBounds
    click_client = if ($null -ne $clickClientX) { [ordered]@{ x = $clickClientX; y = $clickClientY } } else { $null }
    click_screen = if ($null -ne $clickPoint) { [ordered]@{ x = $clickPoint.X; y = $clickPoint.Y } } else { $null }
    title_before = $titleBefore
    title_after_type = $titleAfterType
    title_after_enter = $titleAfterEnter
    submit_worked = $submitWorked
    keypress_before_submit = $keypressBeforeSubmit
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
  Stop-VerifiedProcess $server.Id
  for ($i = 0; $i -lt 20; $i++) {
    if (-not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue)) { break }
    Start-Sleep -Milliseconds 100
  }
}

if ($failure) {
  throw $failure
}
