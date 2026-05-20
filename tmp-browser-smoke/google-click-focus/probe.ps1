$ErrorActionPreference = "Stop"
$repoRoot = "C:\Users\adyba\src\lightpanda-browser"
$root = Join-Path $repoRoot "tmp-browser-smoke\google-click-focus"
$port = 8151
$url = "http://127.0.0.1:$port/tmp-browser-smoke/google-click-focus/index.html"
$browserExe = Join-Path $repoRoot "zig-out\bin\lightpanda.exe"
$browserOut = Join-Path $root "google-click.browser.stdout.txt"
$browserErr = Join-Path $root "google-click.browser.stderr.txt"
$serverOut = Join-Path $root "google-click.server.stdout.txt"
$serverErr = Join-Path $root "google-click.server.stderr.txt"
$screenshot = Join-Path $root "google-click.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$screenshot -Force -ErrorAction SilentlyContinue

Add-Type -AssemblyName System.Drawing
. "$PSScriptRoot\..\common\Win32Input.ps1"

function Get-HighlightBounds([System.Drawing.Bitmap]$Bitmap) {
  $bounds = [ordered]@{min_x=$null; min_y=$null; max_x=$null; max_y=$null; count=0}
  for ($y = 0; $y -lt $Bitmap.Height; $y++) {
    for ($x = 0; $x -lt $Bitmap.Width; $x++) {
      $c = $Bitmap.GetPixel($x, $y)
      if ($c.R -ge 230 -and $c.G -ge 190 -and $c.B -le 120) {
        if ($null -eq $bounds.min_x -or $x -lt $bounds.min_x) { $bounds.min_x = $x }
        if ($null -eq $bounds.min_y -or $y -lt $bounds.min_y) { $bounds.min_y = $y }
        if ($null -eq $bounds.max_x -or $x -gt $bounds.max_x) { $bounds.max_x = $x }
        if ($null -eq $bounds.max_y -or $y -gt $bounds.max_y) { $bounds.max_y = $y }
        $bounds.count++
      }
    }
  }
  return $bounds
}

$server = $null
$browser = $null
$ready = $false
$screenshotReady = $false
$focused = $false
$typed = $false
$submitted = $false
$failure = $null
$bounds = $null
$clickClientX = $null
$clickClientY = $null
$clickPoint = $null
$titleAfterClick = $null
$titleAfterType = $null
$titleAfterSubmit = $null

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $repoRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google click-focus probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse",$url,"--window_width","720","--window_height","620","--screenshot_png",$screenshot -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $screenshot) -and ((Get-Item $screenshot).Length -gt 0)) { $screenshotReady = $true; break }
  }
  if (-not $screenshotReady) { throw "google click-focus screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google click-focus window handle not found" }

  $bmp = [System.Drawing.Bitmap]::new($screenshot)
  try {
    $bounds = Get-HighlightBounds $bmp
  } finally {
    $bmp.Dispose()
  }
  if ($null -eq $bounds.min_x -or $bounds.count -lt 5000) {
    throw "google click-focus fixture highlight not found in screenshot"
  }

  $clickClientX = [int][Math]::Floor(($bounds.min_x + $bounds.max_x) / 2)
  $clickClientY = [int][Math]::Floor(($bounds.min_y + $bounds.max_y) / 2)

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $clickPoint = Invoke-SmokeClientClick $hwnd $clickClientX $clickClientY

  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 150
    $titleAfterClick = Get-SmokeWindowTitle $hwnd
    if ($titleAfterClick -eq "FOCUSED") {
      $focused = $true
      break
    }
  }
  if (-not $focused) { throw "google click-focus fixture did not focus after click" }

  Send-SmokeAsciiText "n"
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 150
    $titleAfterType = Get-SmokeWindowTitle $hwnd
    if ($titleAfterType -eq "IN:n") {
      $typed = $true
      break
    }
  }
  if (-not $typed) { throw "google click-focus fixture did not report typed input" }

  Send-SmokeEnter
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 150
    $titleAfterSubmit = Get-SmokeWindowTitle $hwnd
    if ($titleAfterSubmit -like "SUBMIT:n|*") {
      $submitted = $true
      break
    }
  }
  if (-not $submitted) { throw "google click-focus fixture did not report Enter submit" }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = if ($server) { Get-CimInstance Win32_Process -Filter "ProcessId=$($server.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  $browserMeta = if ($browser) { Get-CimInstance Win32_Process -Filter "ProcessId=$($browser.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  if ($browserMeta -and $browserMeta.CommandLine -and $browserMeta.CommandLine -notmatch "codex\.js|@openai/codex") { Stop-Process -Id $browser.Id -Force -ErrorAction SilentlyContinue }
  if ($serverMeta -and $serverMeta.CommandLine -and $serverMeta.CommandLine -notmatch "codex\.js|@openai/codex") { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $screenshotReady
    highlight_bounds = $bounds
    click_client = if ($null -ne $clickClientX) { [ordered]@{ x = $clickClientX; y = $clickClientY } } else { $null }
    click_screen = if ($clickPoint) { [ordered]@{ x = $clickPoint.X; y = $clickPoint.Y } } else { $null }
    focused = $focused
    typed = $typed
    submitted = $submitted
    title_after_click = $titleAfterClick
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
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
