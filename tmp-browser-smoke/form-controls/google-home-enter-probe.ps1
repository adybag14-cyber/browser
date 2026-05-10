[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8157,
  [int]$WindowWidth = 1440,
  [int]$WindowHeight = 900,
  [string]$FixturePath = "/src/browser/tests/page/google_home_title_probe.html",
  [string]$ProbeDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
  $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
  $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}
if (-not $ProbeDir) {
  $ProbeDir = Join-Path $RepoRoot "tmp-browser-smoke\form-controls"
}

$root = $ProbeDir
$probeUrl = "http://$Host`:$Port$FixturePath"
$fixtureLocalPath = Join-Path $RepoRoot (($FixturePath.TrimStart('/')) -replace '/', '\')
$browserOut = Join-Path $root "google-home-enter.browser.stdout.txt"
$browserErr = Join-Path $root "google-home-enter.browser.stderr.txt"
$serverOut = Join-Path $root "google-home-enter.server.stdout.txt"
$serverErr = Join-Path $root "google-home-enter.server.stderr.txt"
$pngPath = Join-Path $root "google-home-enter.before.png"
$win32InputPath = Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1"

if (-not (Test-Path -LiteralPath $BrowserExe -PathType Leaf)) {
  throw "Lightpanda binary not found: $BrowserExe"
}
if (-not (Test-Path -LiteralPath $fixtureLocalPath -PathType Leaf)) {
  throw "Google home probe fixture not found: $fixtureLocalPath"
}
if (-not (Test-Path -LiteralPath $win32InputPath -PathType Leaf)) {
  throw "Win32 input helper not found: $win32InputPath"
}

New-Item -ItemType Directory -Force -Path $root | Out-Null
Remove-Item $browserOut,$browserErr,$serverOut,$serverErr,$pngPath -Force -ErrorAction SilentlyContinue

. $win32InputPath

function Resolve-PythonCommand {
  if (Get-Command python -ErrorAction SilentlyContinue) {
    return @{ FileName = "python"; Arguments = @("-m", "http.server") }
  }
  if (Get-Command py -ErrorAction SilentlyContinue) {
    return @{ FileName = "py"; Arguments = @("-3", "-m", "http.server") }
  }
  throw "Python was not found in PATH."
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
$titleBefore = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$typedWorked = $false
$submittedWorked = $false
$failure = $null

try {
  $python = Resolve-PythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($Port, "--bind", $Host)) -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 250
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $probeUrl -TimeoutSec 2
      if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "google home probe server did not become ready" }

  $browser = Start-Process -FilePath $BrowserExe -ArgumentList "browse",$probeUrl,"--window_width",$WindowWidth,"--window_height",$WindowHeight,"--screenshot_png",$pngPath -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    if ((Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) { $pngReady = $true; break }
  }
  if (-not $pngReady) { throw "google home probe screenshot did not become ready" }

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 250
    $proc = Get-Process -Id $browser.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw "google home probe window handle not found" }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds 250
  $titleBefore = Get-SmokeWindowTitle $hwnd

  Send-SmokeText "n"
  $titleAfterType = Wait-ForTitleLike $hwnd "*TYPED:n*"
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) { throw "google home probe did not observe typed text in the query box" }

  Send-SmokeEnter
  $titleAfterSubmit = Wait-ForTitleLike $hwnd "*SUBMIT:n*"
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) { throw "google home probe did not observe Enter-driven form submit" }
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
    repo_root = $RepoRoot
    browser_exe = $BrowserExe
    probe_dir = $root
    probe_url = $probeUrl
    fixture_path = $FixturePath
    server_pid = if ($server) { $server.Id } else { 0 }
    browser_pid = if ($browser) { $browser.Id } else { 0 }
    ready = $ready
    screenshot_ready = $pngReady
    title_before = $titleBefore
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
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
