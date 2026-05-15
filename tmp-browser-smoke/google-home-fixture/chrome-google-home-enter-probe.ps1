$repo = "C:\Users\adyba\src\lightpanda-browser"
$root = Join-Path $repo "tmp-browser-smoke\google-home-fixture"
$port = 8164
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$serverScript = Join-Path $root "google_home_server.py"
$readyPng = Join-Path $root "google-home.ready.png"
$browserOut = Join-Path $root "google-home.browser.stdout.txt"
$browserErr = Join-Path $root "google-home.browser.stderr.txt"
$serverOut = Join-Path $root "google-home.server.stdout.txt"
$serverErr = Join-Path $root "google-home.server.stderr.txt"
Remove-Item $readyPng,$browserOut,$browserErr,$serverOut,$serverErr -Force -ErrorAction SilentlyContinue

Add-Type -AssemblyName System.Drawing
. "$PSScriptRoot\..\common\Win32Input.ps1"

function Get-ColorBounds([System.Drawing.Bitmap]$Bitmap, [scriptblock]$Matcher) {
  $bounds = [ordered]@{min_x=$null; min_y=$null; max_x=$null; max_y=$null; count=0}
  for ($y = 0; $y -lt $Bitmap.Height; $y++) {
    for ($x = 0; $x -lt $Bitmap.Width; $x++) {
      $c = $Bitmap.GetPixel($x, $y)
      if (& $Matcher $c) {
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

function Count-Hits([string]$Pattern) {
  if (-not (Test-Path $serverErr)) { return 0 }
  return ([regex]::Matches((Get-Content $serverErr -Raw), $Pattern)).Count
}

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 20, [int]$SleepMs = 200) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    if ($title -like $Pattern) {
      return $title
    }
  }
  return $null
}

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$focusedWorked = $false
$typedWorked = $false
$submittedWorked = $false
$titleAfterFocus = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$serverSubmitHits = 0
$failure = $null

try {
  $server = Start-Process -FilePath "python" -ArgumentList $serverScript,$port -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/ping" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google home fixture probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google-home.html","--window_width","960","--window_height","720","--screenshot_png",$readyPng -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $readyPng) -and ((Get-Item $readyPng).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google home fixture screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google home fixture window handle not found" }

  $bmp = [System.Drawing.Bitmap]::new($readyPng)
  try {
    $searchShell = Get-ColorBounds $bmp { param($c) $c.G -ge 210 -and $c.R -ge 120 -and $c.R -le 170 -and $c.B -ge 180 -and $c.B -le 220 }
  } finally {
    $bmp.Dispose()
  }
  if ($null -eq $searchShell.min_x) { throw "google home fixture could not find the search shell in the screenshot" }

  $clickX = [int][Math]::Floor(($searchShell.min_x + $searchShell.max_x) / 2)
  $clickY = [int][Math]::Floor(($searchShell.min_y + $searchShell.max_y) / 2)

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  [void](Invoke-SmokeClientClick $hwnd $clickX $clickY)
  $titleAfterFocus = Wait-ForTitleLike $hwnd "Google Home Focused*"
  $focusedWorked = $null -ne $titleAfterFocus
  if (-not $focusedWorked) { throw "google home fixture click did not focus the search input" }

  Send-SmokeText "n"
  $titleAfterType = Wait-ForTitleLike $hwnd "Google Home Typed n*"
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "google home fixture did not receive typed text after focus" }

  Send-SmokeEnter
  $titleAfterSubmit = Wait-ForTitleLike $hwnd "Google Submit n*"
  $serverSubmitHits = Count-Hits 'FORM_SUBMIT /submitted\.html\?q=n'
  $submittedWorked = ($null -ne $titleAfterSubmit) -or ($serverSubmitHits -gt 0)
  if (-not $submittedWorked) { throw "google home fixture did not submit after Enter" }
} catch {
  $failure = $_.Exception.Message
} finally {
  if ($browser) { Stop-Process -Id $browser.Id -Force -ErrorAction SilentlyContinue }
  if ($server) { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Milliseconds 250

  [ordered]@{
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    focused_worked = $focusedWorked
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    title_after_focus = $titleAfterFocus
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    server_submit_hits = $serverSubmitHits
    error = $failure
    browser_gone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
    server_gone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }
  } | ConvertTo-Json -Depth 6
}

if ($failure) {
  exit 1
}
