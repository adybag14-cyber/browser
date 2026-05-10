[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8148,
    [string]$InputText = "Q",
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$WindowReadyAttempts = 60,
    [int]$TitleWaitAttempts = 80,
    [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot([string]$StartPath) {
  if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    return $env:LIGHTPANDA_REPO_ROOT
  }

  $cursor = [System.IO.Path]::GetFullPath($StartPath)
  while ($true) {
    if (Test-Path (Join-Path $cursor "build.zig")) {
      return $cursor
    }

    $parent = Split-Path $cursor -Parent
    if ([string]::IsNullOrEmpty($parent) -or $parent -eq $cursor) {
      throw "Could not resolve the Lightpanda repo root from $StartPath. Set LIGHTPANDA_REPO_ROOT to override."
    }
    $cursor = $parent
  }
}

function Resolve-PythonCommand {
  if (Get-Command python -ErrorAction SilentlyContinue) {
    return @{ FileName = "python"; Arguments = @("-m", "http.server") }
  }
  if (Get-Command py -ErrorAction SilentlyContinue) {
    return @{ FileName = "py"; Arguments = @("-3", "-m", "http.server") }
  }
  throw "Python was not found in PATH. Install Python or start the inline-flow probe server separately."
}

$root = $PSScriptRoot
$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-RepoRoot $PSScriptRoot }
$browserExe = if ($BrowserExe) {
  $BrowserExe
} elseif (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_BROWSER_EXE)) {
  $env:LIGHTPANDA_BROWSER_EXE
} else {
  Join-Path $repo "zig-out\bin\lightpanda.exe"
}
if (-not (Test-Path -LiteralPath $browserExe)) {
  throw "headed browser binary not found: $browserExe"
}

$probeUrl = "http://$Host`:$Port/input-break-submit.html"
$escapedInputText = [System.Management.Automation.WildcardPattern]::Escape($InputText)
$serverSubmitPattern = 'GET /submitted\.html\?entry=' + [regex]::Escape($InputText) + ' HTTP/1\.1" 200'

$outPng = Join-Path $root "break-input-submit.png"
$browserOut = Join-Path $root "break-input-submit.browser.stdout.txt"
$browserErr = Join-Path $root "break-input-submit.browser.stderr.txt"
$serverOut = Join-Path $root "break-input-submit.server.stdout.txt"
$serverErr = Join-Path $root "break-input-submit.server.stderr.txt"
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

function Wait-HttpReady {
  param(
    [string]$Url,
    [int]$TimeoutSeconds
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
      if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) {
        return
      }
    } catch {}
    Start-Sleep -Milliseconds $PollMilliseconds
  } while ((Get-Date) -lt $deadline)

  throw "inline break input submit probe server did not become ready at $Url"
}

$server = $null
$browser = $null
$ready = $false
$pngReady = $false
$hwnd = [IntPtr]::Zero
$input = $null
$titleBefore = $null
$titleAfterType = $null
$titleAfterEnter = $null
$submitWorked = $false
$serverSawSubmit = $false
$failure = $null
$clickClientX = $null
$clickClientY = $null
$clickPoint = $null
$originalAppData = $env:APPDATA
$originalLocalAppData = $env:LOCALAPPDATA

try {
  $python = Resolve-PythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($Port, "--bind", $Host)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  Wait-HttpReady -Url $probeUrl -TimeoutSeconds $ServerReadyTimeoutSeconds
  $ready = $true

  $profileRoot = Join-Path $root "profile-inline-break-submit"
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

  $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "820", "--window_height", "520", "--screenshot_png", $outPng, $probeUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    if ((Test-Path $outPng) -and ((Get-Item $outPng).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "inline break input submit screenshot did not become ready" }

  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "inline break input submit window handle not found" }

  $bmp = [System.Drawing.Bitmap]::new($outPng)
  try {
    $input = [ordered]@{min_x=$null; min_y=$null; max_x=$null; max_y=$null; count=0}
    for ($y = 0; $y -lt $bmp.Height; $y++) {
      for ($x = 0; $x -lt $bmp.Width; $x++) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.R -ge 15 -and $c.R -le 45 -and $c.G -ge 170 -and $c.G -le 195 -and $c.B -ge 195 -and $c.B -le 220) {
          Add-Pixel $input $x $y
        }
      }
    }
  } finally {
    $bmp.Dispose()
  }

  if ($null -eq $input.min_y) { throw "inline break input submit probe did not isolate the input control" }

  $clickClientX = [int][Math]::Floor(($input.min_x + $input.max_x) / 2)
  $clickClientY = [int][Math]::Floor(($input.min_y + $input.max_y) / 2)
  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $titleBefore = Get-SmokeWindowTitle $hwnd
  $clickPoint = Invoke-SmokeClientClick $hwnd $clickClientX $clickClientY
  Start-Sleep -Milliseconds 120
  Send-SmokeText $InputText

  $titleAfterType = $titleBefore
  for ($i = 0; $i -lt $TitleWaitAttempts; $i++) {
    Start-Sleep -Milliseconds 150
    $titleAfterType = Get-SmokeWindowTitle $hwnd
    if ($titleAfterType -like "Inline Input $escapedInputText*") { break }
  }
  if ($titleAfterType -notlike "Inline Input $escapedInputText*") { throw "inline break input did not update title after typing" }

  Send-SmokeEnter
  $titleAfterEnter = $titleAfterType
  for ($i = 0; $i -lt $TitleWaitAttempts; $i++) {
    Start-Sleep -Milliseconds 150
    $titleAfterEnter = Get-SmokeWindowTitle $hwnd
    if ($titleAfterEnter -like "Inline Break Submitted*") {
      $submitWorked = $true
      break
    }
  }
  if (-not $submitWorked -and (Test-Path $serverErr)) {
    $serverLog = Get-Content $serverErr -Raw
    $serverSawSubmit = $serverLog -match $serverSubmitPattern
    if ($serverSawSubmit) {
      $submitWorked = $true
    }
  }
} catch {
  $failure = $_.Exception.Message
} finally {
  $env:APPDATA = $originalAppData
  $env:LOCALAPPDATA = $originalLocalAppData
  $serverMeta = if ($server) { Get-CimInstance Win32_Process -Filter "ProcessId=$($server.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  $browserMeta = if ($browser) { Get-CimInstance Win32_Process -Filter "ProcessId=$($browser.Id)" | Select-Object Name,ProcessId,CommandLine,CreationDate } else { $null }
  if ($browserMeta -and $browserMeta.CommandLine -and $browserMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-VerifiedProcess $browser.Id }
  if ($serverMeta -and $serverMeta.CommandLine -and $serverMeta.CommandLine -notmatch "codex\\.js|@openai/codex") { Stop-VerifiedProcess $server.Id }
  Start-Sleep -Milliseconds 200
  $browserGone = if ($browser) { -not (Get-Process -Id $browser.Id -ErrorAction SilentlyContinue) } else { $true }
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    repo_root = $repo
    browser_exe = $browserExe
    host = $Host
    port = $port
    probe_url = $probeUrl
    input_text = $InputText
    server_ready_timeout_seconds = $ServerReadyTimeoutSeconds
    window_ready_attempts = $WindowReadyAttempts
    title_wait_attempts = $TitleWaitAttempts
    poll_milliseconds = $PollMilliseconds
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    input_bounds = $input
    click_client = if ($null -ne $clickClientX) { [ordered]@{ x = $clickClientX; y = $clickClientY } } else { $null }
    click_screen = if ($null -ne $clickPoint) { [ordered]@{ x = $clickPoint.X; y = $clickPoint.Y } } else { $null }
    title_before = $titleBefore
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
