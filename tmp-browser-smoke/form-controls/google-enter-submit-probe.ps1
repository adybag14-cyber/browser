$ErrorActionPreference = "Stop"
$root = "C:\Users\adyba\src\lightpanda-browser\tmp-browser-smoke\form-controls"
$repo = "C:\Users\adyba\src\lightpanda-browser"
$port = 8155
$browserExe = Join-Path $repo "zig-out\bin\lightpanda.exe"
$serverScript = Join-Path $root "google_probe_server.py"
$browserOut = Join-Path $root "google-enter-submit.browser.stdout.txt"
$browserErr = Join-Path $root "google-enter-submit.browser.stderr.txt"
$serverOut = Join-Path $root "google-enter-submit.server.stdout.txt"
$serverErr = Join-Path $root "google-enter-submit.server.stderr.txt"
$pngPath = Join-Path $root "google-enter-submit.before.png"
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$titleBefore = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$typedWorked = $false
$submittedWorked = $false
$submitAfterKeypress = $false
$failure = $null

function Wait-ForTitleLike([IntPtr]$Hwnd, [string]$Pattern, [int]$Attempts = 30, [int]$SleepMs = 200) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    if ($title -like $Pattern) {
      return $title
    }
  }
  return $null
}

function Require-Substring([string]$Haystack, [string]$Needle, [string]$Label) {
  if ($null -eq $Haystack -or $Haystack.IndexOf($Needle, [System.StringComparison]::Ordinal) -lt 0) {
    throw "$Label missing substring: $Needle"
  }
}

function Get-TitleEvents([string]$Title) {
  if ($null -eq $Title) {
    return @()
  }
  $parts = $Title.Split('|', 2)
  if ($parts.Length -lt 2) {
    return @()
  }
  return $parts[1].Split(',') | Where-Object { $_ -ne "" }
}

function Find-EventIndex([object[]]$Events, [string]$Prefix) {
  for ($i = 0; $i -lt $Events.Length; $i++) {
    if ([string]$Events[$i] -like "$Prefix*") {
      return $i
    }
  }
  return -1
}

try {
  $server = Start-Process -FilePath "python" -ArgumentList $serverScript,$port -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/ping" -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google enter submit probe server did not become ready" }

  $browser = Start-Process -FilePath $browserExe -ArgumentList "browse","http://127.0.0.1:$port/google-home.html","--window_width","920","--window_height","720","--screenshot_png",$pngPath -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google enter submit probe screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google enter submit probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $titleBefore = Get-SmokeWindowTitle $hwnd

  Send-SmokeText "n"
  $titleAfterType = Wait-ForTitleLike $hwnd "TYPE:n*"
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "google-like probe input did not receive typed text" }
  Require-Substring $titleAfterType "IN:n|0" "typed title"

  Send-SmokeEnter
  $titleAfterSubmit = Wait-ForTitleLike $hwnd "SUBMIT:n*"
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) { throw "google-like probe Enter did not submit the form" }

  $titleEvents = @(Get-TitleEvents $titleAfterSubmit)
  $keydownIndex = Find-EventIndex $titleEvents "KD:Enter|"
  $keypressIndex = Find-EventIndex $titleEvents "KP:Enter|"
  $submitIndex = Find-EventIndex $titleEvents "SU:n|1"

  if ($keydownIndex -lt 0) { throw "submit title missing Enter keydown event" }
  if ($keypressIndex -lt 0) { throw "submit title missing Enter keypress event" }
  if ($submitIndex -lt 0) { throw "submit title missing submit event marker" }
  if ($keypressIndex -le $keydownIndex) { throw "submit title recorded keypress before keydown ordering settled" }
  if ($submitIndex -le $keypressIndex) { throw "submit title recorded submit before Enter keypress completed" }

  $submitAfterKeypress = $true
} catch {
  $failure = $_.Exception.Message
} finally {
  $serverMeta = if ($server) { Get-CimInstance Win32_Process -Filter "ProcessId=$($server.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  $browserMeta = if ($browser) { Get-CimInstance Win32_Process -Filter "ProcessId=$($browser.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  if ($browserMeta -and $browserMeta.CommandLine -and $browserMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-Process -Id $browser.Id -Force -ErrorAction SilentlyContinue }
  if ($serverMeta -and $serverMeta.CommandLine -and $serverMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    title_before = $titleBefore
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    submit_after_keypress = $submitAfterKeypress
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
