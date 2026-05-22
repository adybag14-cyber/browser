$ErrorActionPreference = "Stop"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$root = Join-Path $repo "tmp-browser-smoke\google-investigation-next"
$pageRoot = Join-Path $repo "src\browser\tests\page"
$profileRoot = Join-Path $root "profile-google-home-local-enter-order"
$port = 8169
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$browserOut = Join-Path $root "google-home-local-enter-order.browser.stdout.txt"
$browserErr = Join-Path $root "google-home-local-enter-order.browser.stderr.txt"
$serverOut = Join-Path $root "google-home-local-enter-order.server.stdout.txt"
$serverErr = Join-Path $root "google-home-local-enter-order.server.stderr.txt"
$pngPath = Join-Path $root "google-home-local-enter-order.png"

New-Item -ItemType Directory -Force -Path $root | Out-Null
cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

$env:APPDATA = $profileRoot
$env:LOCALAPPDATA = $profileRoot

. "$PSScriptRoot\..\tabs\TabProbeCommon.ps1"

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$queryFocused = $false
$typedWorked = $false
$enterKeydownSeen = $false
$enterKeypressSeen = $false
$submittedWorked = $false
$enterSequenceValid = $false
$failure = $null
$titles = [ordered]@{}
$enterTransitions = New-Object System.Collections.ArrayList
$sequenceIndexes = [ordered]@{
  keydown = -1
  keypress = -1
  submit = -1
}

function Wait-ForWindowTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 40, [int]$SleepMs = 250) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    if ($title -like $Pattern) {
      return $title
    }
  }
  return $null
}

function Try-FocusGoogleQuery([IntPtr]$Hwnd) {
  $candidatePoints = @(
    @{ X = 512; Y = 365 },
    @{ X = 512; Y = 350 },
    @{ X = 492; Y = 365 },
    @{ X = 532; Y = 365 }
  )

  foreach ($point in $candidatePoints) {
    Invoke-SmokeClientClick -Hwnd $Hwnd -X $point.X -Y $point.Y | Out-Null
    $focused = Wait-ForWindowTitleLike -Hwnd $Hwnd -Pattern "*A=INPUT:q:*" -Attempts 8 -SleepMs 150
    if ($focused) {
      return $focused
    }
  }

  return $null
}

function Get-SequenceFailure($Indexes) {
  if ($Indexes.keydown -lt 0) {
    return "google home local enter-order probe did not observe Enter keydown"
  }
  if ($Indexes.keypress -lt 0) {
    return "google home local enter-order probe did not observe Enter keypress"
  }
  if ($Indexes.submit -lt 0) {
    return "google home local enter-order probe did not observe Enter submission"
  }
  if ($Indexes.keydown -ge $Indexes.keypress) {
    return "google home local enter-order probe observed Enter keypress before Enter keydown"
  }
  if ($Indexes.keypress -ge $Indexes.submit) {
    return "google home local enter-order probe observed submission before Enter keypress"
  }
  return $null
}

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$port,"--bind","127.0.0.1" -WorkingDirectory $pageRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/google_home_title_probe.html" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google home local enter-order probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google_home_title_probe.html","--window_width","1024","--window_height","768","--screenshot_png",$pngPath -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  $hwnd = Wait-TabWindowHandle $browser.Id
  if ($hwnd -eq [IntPtr]::Zero) { throw "google home local enter-order probe window handle not found" }
  Show-SmokeWindow $hwnd

  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google home local enter-order probe screenshot did not become ready" }

  $titles.initial = Wait-ForWindowTitleLike -Hwnd $hwnd -Pattern "*Q=INPUT:q:*" -Attempts 60 -SleepMs 250
  if (-not $titles.initial) { throw "google home local enter-order probe did not bind the local query input" }

  $titles.focused = Try-FocusGoogleQuery -Hwnd $hwnd
  $queryFocused = [bool]$titles.focused
  if (-not $queryFocused) { throw "google home local enter-order probe did not focus the query input" }

  Send-SmokeAsciiText "zig headed"
  $titles.typed = Wait-ForWindowTitleLike -Hwnd $hwnd -Pattern "*V=zig headed*" -Attempts 20 -SleepMs 200
  $typedWorked = [bool]$titles.typed
  if (-not $typedWorked) { throw "google home local enter-order probe did not record typed text in the query input" }

  $enterTitleBaseline = Get-SmokeWindowTitle $hwnd
  Send-SmokeEnter

  $enterKeydownPattern = "KEYDOWN:zig headed:13:13"
  $enterKeypressPattern = "KEYPRESS:Enter:zig headed"
  $submitPattern = "SUBMIT:zig headed"

  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 150
    $title = Get-SmokeWindowTitle $hwnd
    if (-not $title) {
      continue
    }
    if ($title -eq $enterTitleBaseline) {
      continue
    }
    if ($enterTransitions.Count -eq 0 -or $enterTransitions[$enterTransitions.Count - 1] -ne $title) {
      [void]$enterTransitions.Add($title)
    }
    if (-not $enterKeydownSeen -and $title -like "*$enterKeydownPattern*") {
      $enterKeydownSeen = $true
      $sequenceIndexes.keydown = $enterTransitions.Count - 1
      $titles.enter_keydown = $title
    }
    if (-not $enterKeypressSeen -and $title -like "*$enterKeypressPattern*") {
      $enterKeypressSeen = $true
      $sequenceIndexes.keypress = $enterTransitions.Count - 1
      $titles.enter_keypress = $title
    }
    if (-not $submittedWorked -and $title -like "*$submitPattern*") {
      $submittedWorked = $true
      $sequenceIndexes.submit = $enterTransitions.Count - 1
      $titles.submitted = $title
    }
    if ($enterKeydownSeen -and $enterKeypressSeen -and $submittedWorked) {
      break
    }
  }

  $sequenceFailure = Get-SequenceFailure -Indexes $sequenceIndexes
  $enterSequenceValid = -not $sequenceFailure
  if (-not $enterSequenceValid) {
    throw $sequenceFailure
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
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    query_focused = $queryFocused
    typed_worked = $typedWorked
    enter_keydown_seen = $enterKeydownSeen
    enter_keypress_seen = $enterKeypressSeen
    submitted_worked = $submittedWorked
    enter_sequence_valid = $enterSequenceValid
    titles = $titles
    enter_transitions = @($enterTransitions)
    sequence_indexes = $sequenceIndexes
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
