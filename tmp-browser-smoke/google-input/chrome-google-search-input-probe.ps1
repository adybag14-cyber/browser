$ErrorActionPreference = "Stop"
$root = "C:\Users\adyba\src\lightpanda-browser\tmp-browser-smoke\google-input"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$port = 8158
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$outPng = Join-Path $root "google-search-input.png"
$browserOut = Join-Path $root "google-search-input.browser.stdout.txt"
$browserErr = Join-Path $root "google-search-input.browser.stderr.txt"
$serverOut = Join-Path $root "google-search-input.server.stdout.txt"
$serverErr = Join-Path $root "google-search-input.server.stderr.txt"
Remove-Item $outPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

Add-Type -AssemblyName System.Drawing
. "$PSScriptRoot\..\common\Win32Input.ps1"

function Get-ProcessCommandLine($TargetPid) {
  $meta = Get-CimInstance Win32_Process -Filter "ProcessId=$TargetPid" -ErrorAction SilentlyContinue |
    Select-Object Name,ProcessId,CommandLine,CreationDate
  if ($meta) { return [string]$meta.CommandLine }
  return ""
}

function Stop-VerifiedProcess($TargetPid) {
  $cmd = Get-ProcessCommandLine $TargetPid
  if ($cmd -and $cmd -notmatch "codex\.js|@openai/codex") {
    try {
      Stop-Process -Id $TargetPid -Force -ErrorAction Stop
    } catch {
      if (Get-Process -Id $TargetPid -ErrorAction SilentlyContinue) { throw }
    }
  }
}

function Add-Pixel($o, $x, $y) {
  if ($null -eq $o.min_x -or $x -lt $o.min_x) { $o.min_x = $x }
  if ($null -eq $o.min_y -or $y -lt $o.min_y) { $o.min_y = $y }
  if ($null -eq $o.max_x -or $x -gt $o.max_x) { $o.max_x = $x }
  if ($null -eq $o.max_y -or $y -gt $o.max_y) { $o.max_y = $y }
  $o.count++
}

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$hwnd = [IntPtr]::Zero
$input = $null
$titleBefore = $null
$titleAfterFocus = $null
$titleAfterType = $null
$titleAfterEnter = $null
$submitWorked = $false
$serverSawSubmit = $false
$failure = $null
$clickClientX = $null
$clickClientY = $null
$clickPoint = $null

try {
  $profileRoot = Join-Path $root "profile-google-search-input"
  $appDataRoot = Join-Path $profileRoot "lightpanda"
  cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
  New-Item -ItemType Directory -Force -Path $appDataRoot | Out-Null
@"
lightpanda-browse-settings-v1
restore_previous_session	0
allow_script_popups	0
default_zoom_percent	100
homepage_url	
"@ | Set-Content -Path (Join-Path $appDataRoot "browse-settings-v1.txt") -NoNewline
  $env:APPDATA = $profileRoot
  $env:LOCALAPPDATA = $profileRoot

  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/google-search-probe.html" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google search input probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google-search-probe.html","--window_width","960","--window_height","720","--screenshot_png",$outPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $outPng) -and ((Get-Item $outPng).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google search input probe screenshot did not become ready" }

  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google search input probe window handle not found" }

  $bmp = [System.Drawing.Bitmap]::new($outPng)
  try {
    $input = [ordered]@{min_x=$null; min_y=$null; max_x=$null; max_y=$null; count=0}
    for ($y = 0; $y -lt $bmp.Height; $y++) {
      for ($x = 0; $x -lt $bmp.Width; $x++) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.R -ge 215 -and $c.R -le 235 -and $c.G -ge 245 -and $c.G -le 255 -and $c.B -ge 250 -and $c.B -le 255) {
          Add-Pixel $input $x $y
        }
      }
    }
  } finally {
    $bmp.Dispose()
  }

  if ($null -eq $input.min_y) { throw "google search input probe did not isolate the search control" }

  $clickClientX = [int][Math]::Floor(($input.min_x + $input.max_x) / 2)
  $clickClientY = [int][Math]::Floor(($input.min_y + $input.max_y) / 2)
  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $titleBefore = Get-SmokeWindowTitle $hwnd
  $clickPoint = Invoke-SmokeClientClick $hwnd $clickClientX $clickClientY
  for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Milliseconds 120
    $titleAfterFocus = Get-SmokeWindowTitle $hwnd
    if ($titleAfterFocus -like "FOCUS*") { break }
  }
  if ($titleAfterFocus -notlike "FOCUS*") { throw "google search input did not focus after click" }

  Send-SmokeText "QZ"
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 120
    $titleAfterType = Get-SmokeWindowTitle $hwnd
    if ($titleAfterType -like "TYPE:QZ*") { break }
  }
  if ($titleAfterType -notlike "TYPE:QZ*") { throw "google search input did not update after typing" }

  Send-SmokeEnter
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 150
    $titleAfterEnter = Get-SmokeWindowTitle $hwnd
    if ($titleAfterEnter -like "SUBMIT:QZ*") {
      $submitWorked = $true
      break
    }
  }
  if (-not $submitWorked -and (Test-Path $serverErr)) {
    $serverLog = Get-Content $serverErr -Raw
    $serverSawSubmit = $serverLog -match 'GET /submitted\.html\?entry=QZ HTTP/1\.1" 200'
    if ($serverSawSubmit) {
      $submitWorked = $true
    }
  }
  if (-not $submitWorked) { throw "google search input did not submit on Enter" }
}
catch {
  $failure = $_.Exception.Message
}
finally {
  $serverMeta = if ($server) { Get-CimInstance Win32_Process -Filter "ProcessId=$($server.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  $browserMeta = if ($browser) { Get-CimInstance Win32_Process -Filter "ProcessId=$($browser.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  if ($browserMeta -and $browserMeta.CommandLine -and $browserMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-VerifiedProcess $browser.Id }
  if ($serverMeta -and $serverMeta.CommandLine -and $serverMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-VerifiedProcess $server.Id }
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    input_bounds = $input
    click_client = if ($null -ne $clickClientX) { [ordered]@{ x = $clickClientX; y = $clickClientY } } else { $null }
    click_screen = if ($null -ne $clickPoint) { [ordered]@{ x = $clickPoint.X; y = $clickPoint.Y } } else { $null }
    title_before = $titleBefore
    title_after_focus = $titleAfterFocus
    title_after_type = $titleAfterType
    title_after_enter = $titleAfterEnter
    submit_worked = $submitWorked
    server_saw_submit = $serverSawSubmit
    error = $failure
    browser_gone = $browserGone
    server_gone = $serverGone
  } | ConvertTo-Json -Depth 7
}

if ($failure) {
  exit 1
}
