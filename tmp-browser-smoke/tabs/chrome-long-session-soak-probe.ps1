param(
  [int]$CycleCount = 12,
  [int]$RestartEvery = 3,
  [int]$PauseMs = 150,
  [int]$Port = 8154
)

$repo = "C:\Users\adyba\src\lightpanda-browser"
$root = Join-Path $repo "tmp-browser-smoke\tabs"
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$profileRoot = Join-Path $root "profile-long-session-soak"
$browserOut = Join-Path $root "chrome-long-session-soak.browser.stdout.txt"
$browserErr = Join-Path $root "chrome-long-session-soak.browser.stderr.txt"
$serverOut = Join-Path $root "chrome-long-session-soak.server.stdout.txt"
$serverErr = Join-Path $root "chrome-long-session-soak.server.stderr.txt"
$screenshotPrefix = Join-Path $root "chrome-long-session-soak"

cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,"$screenshotPrefix.*.png" -Force -ErrorAction SilentlyContinue

$env:APPDATA = $profileRoot
$env:LOCALAPPDATA = $profileRoot

. "$PSScriptRoot\TabProbeCommon.ps1"

function Wait-SoakScreenshot([string]$Path, [int]$Attempts = 60) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $Path) -and ((Get-Item $Path).Length -gt 0)) {
      return $true
    }
  }
  return $false
}

function Start-SoakBrowser([string]$Url, [string]$ScreenshotPath) {
  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse",$Url,"--window_width","960","--window_height","640","--screenshot_png",$ScreenshotPath -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  if (-not (Wait-SoakScreenshot $ScreenshotPath)) {
    throw "soak browser screenshot did not become ready for $ScreenshotPath"
  }
  $hwnd = Wait-TabWindowHandle $browser.Id
  if ($hwnd -eq [IntPtr]::Zero) {
    throw "soak browser window handle not found"
  }
  Show-SmokeWindow $hwnd
  return @{
    Process = $browser
    Hwnd = $hwnd
  }
}

function Invoke-SoakCycle([System.Diagnostics.Process]$Browser, [IntPtr]$Hwnd, [int]$CycleNumber, [string]$TargetUrl, [string]$TargetTitle) {
  $cycle = [ordered]@{
    cycle = $CycleNumber
    target_url = $TargetUrl
    target_title = $TargetTitle
    new_tab_worked = $false
    navigate_worked = $false
    reload_worked = $false
    back_tab_worked = $false
    forward_tab_worked = $false
    close_worked = $false
    reopen_worked = $false
    titles = [ordered]@{}
  }

  $newTabPoint = Get-TabClientPoint 0 -New
  [void](Invoke-SmokeClientClick $Hwnd $newTabPoint.X $newTabPoint.Y)
  $cycle.titles.new_tab = Wait-TabTitle $Browser.Id "New Tab"
  $cycle.new_tab_worked = [bool]$cycle.titles.new_tab
  if (-not $cycle.new_tab_worked) { throw "cycle $CycleNumber did not open a new tab" }

  [void](Invoke-SmokeClientClick $Hwnd 160 40)
  Start-Sleep -Milliseconds $PauseMs
  Send-SmokeText $TargetUrl
  Start-Sleep -Milliseconds 100
  Send-SmokeEnter
  $cycle.titles.navigated = Wait-TabTitle $Browser.Id $TargetTitle
  $cycle.navigate_worked = [bool]$cycle.titles.navigated
  if (-not $cycle.navigate_worked) { throw "cycle $CycleNumber did not navigate to $TargetTitle" }

  Start-Sleep -Milliseconds $PauseMs
  Send-SmokeF5
  $cycle.titles.reloaded = Wait-TabTitle $Browser.Id $TargetTitle
  $cycle.reload_worked = [bool]$cycle.titles.reloaded
  if (-not $cycle.reload_worked) { throw "cycle $CycleNumber reload did not preserve $TargetTitle" }

  Send-SmokeCtrlShiftTab
  $cycle.titles.back = Wait-TabTitle $Browser.Id "Tab One"
  $cycle.back_tab_worked = [bool]$cycle.titles.back
  if (-not $cycle.back_tab_worked) { throw "cycle $CycleNumber Ctrl+Shift+Tab did not return to Tab One" }

  Send-SmokeCtrlTab
  $cycle.titles.forward = Wait-TabTitle $Browser.Id $TargetTitle
  $cycle.forward_tab_worked = [bool]$cycle.titles.forward
  if (-not $cycle.forward_tab_worked) { throw "cycle $CycleNumber Ctrl+Tab did not return to $TargetTitle" }

  Send-SmokeCtrlW
  $cycle.titles.after_close = Wait-TabTitle $Browser.Id "Tab One"
  $cycle.close_worked = [bool]$cycle.titles.after_close
  if (-not $cycle.close_worked) { throw "cycle $CycleNumber Ctrl+W did not close the active tab" }

  Send-SmokeCtrlShiftT
  $cycle.titles.after_reopen = Wait-TabTitle $Browser.Id $TargetTitle
  $cycle.reopen_worked = [bool]$cycle.titles.after_reopen
  if (-not $cycle.reopen_worked) { throw "cycle $CycleNumber Ctrl+Shift+T did not reopen $TargetTitle" }

  return [pscustomobject]$cycle
}

$server = $null
$browser = $null
$hwnd = [IntPtr]::Zero
$ready = $false
$failure = $null
$cycles = @()
$restarts = @()
$targets = @(
  @{ url = "http://127.0.0.1:$Port/two.html"; title = "Tab Two" },
  @{ url = "http://127.0.0.1:$Port/duplicate-one.html"; title = "Duplicate One" },
  @{ url = "http://127.0.0.1:$Port/duplicate-two.html"; title = "Duplicate Two" }
)

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$Port,"--bind","127.0.0.1" -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$Port/index.html" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "long-session soak server did not become ready" }

  $launch = Start-SoakBrowser "http://127.0.0.1:$Port/index.html" "$screenshotPrefix.run0.png"
  $browser = $launch.Process
  $hwnd = $launch.Hwnd

  $initialTitle = Wait-TabTitle $browser.Id "Tab One"
  if (-not $initialTitle) { throw "soak initial tab title did not appear" }

  for ($cycleIndex = 0; $cycleIndex -lt $CycleCount; $cycleIndex++) {
    $cycleNumber = $cycleIndex + 1
    $target = $targets[$cycleIndex % $targets.Count]
    $cycles += Invoke-SoakCycle -Browser $browser -Hwnd $hwnd -CycleNumber $cycleNumber -TargetUrl $target.url -TargetTitle $target.title

    if ($RestartEvery -gt 0 -and ($cycleNumber % $RestartEvery) -eq 0 -and $cycleNumber -lt $CycleCount) {
      $savedTitle = $target.title
      $browserMeta = Stop-OwnedProbeProcess $browser
      Start-Sleep -Milliseconds 300
      if (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) {
        throw "soak browser restart after cycle $cycleNumber did not exit cleanly"
      }
      $restarts += [pscustomobject]@{
        cycle = $cycleNumber
        before_restart_title = $savedTitle
        browser_meta = $browserMeta
      }
      $launch = Start-SoakBrowser "http://127.0.0.1:$Port/index.html" "$screenshotPrefix.run$cycleNumber.png"
      $browser = $launch.Process
      $hwnd = $launch.Hwnd
      $restoredTitle = Wait-TabTitle $browser.Id $savedTitle
      if (-not $restoredTitle) { throw "soak restart after cycle $cycleNumber did not restore $savedTitle" }
      Send-SmokeCtrlShiftTab
      $restoredTabOne = Wait-TabTitle $browser.Id "Tab One"
      if (-not $restoredTabOne) { throw "soak restart after cycle $cycleNumber did not keep the earlier tab available" }
      Send-SmokeCtrlTab
      $restoredActive = Wait-TabTitle $browser.Id $savedTitle
      if (-not $restoredActive) { throw "soak restart after cycle $cycleNumber did not return to the restored active tab" }
    }
  }
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $browserMeta = Stop-OwnedProbeProcess $browser
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    cycle_count = $CycleCount
    restart_every = $RestartEvery
    pause_ms = $PauseMs
    port = $Port
    ready = $ready
    cycles = $cycles
    restarts = $restarts
    error = $failure
    server_meta = $serverMeta
    browser_meta = $browserMeta
    browser_gone = $browserGone
    server_gone = $serverGone
  } | ConvertTo-Json -Depth 8
}

if ($failure) {
  exit 1
}
