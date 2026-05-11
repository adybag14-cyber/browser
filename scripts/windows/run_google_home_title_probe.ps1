[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 9582,
  [int]$WindowWidth = 1366,
  [int]$WindowHeight = 768,
  [string]$ProbeDir,
  [string]$ProfileRoot,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$TitleWaitAttempts = 50,
  [int]$PollMilliseconds = 200,
  [string]$InputText = "QZ",
  [switch]$LeaveOpen,
  [switch]$SkipLocalServer
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if (-not $RepoRoot) {
  $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
  $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}
if (-not $ProbeDir) {
  $ProbeDir = Join-Path $RepoRoot "tmp-browser-smoke\page"
}
if (-not $ProfileRoot) {
  $ProfileRoot = Join-Path $ProbeDir "profile-google-home-title"
}

$fixtureRelativePath = "src/browser/tests/page/google_home_title_probe.html"
$probeUrl = "http://$Host`:$Port/$fixtureRelativePath"
$serverStdout = Join-Path $ProbeDir "google-home-title.server.stdout.txt"
$serverStderr = Join-Path $ProbeDir "google-home-title.server.stderr.txt"
$browserStdout = Join-Path $ProbeDir "google-home-title.browser.stdout.txt"
$browserStderr = Join-Path $ProbeDir "google-home-title.browser.stderr.txt"
$summaryPath = Join-Path $ProbeDir "google-home-title.summary.json"
$win32InputPath = Join-Path $RepoRoot "tmp-browser-smoke\common\Win32Input.ps1"

if (-not (Test-Path -LiteralPath $win32InputPath -PathType Leaf)) {
  throw "Win32 input helper not found: $win32InputPath"
}
. $win32InputPath

function Resolve-PythonCommand {
  if (Get-Command python -ErrorAction SilentlyContinue) {
    return @{ FileName = "python"; Arguments = @("-m", "http.server") }
  }
  if (Get-Command py -ErrorAction SilentlyContinue) {
    return @{ FileName = "py"; Arguments = @("-3", "-m", "http.server") }
  }
  throw "Python was not found in PATH. Install Python or re-run with -SkipLocalServer and an already running localhost server."
}

function Wait-HttpReady {
  param(
    [string]$Url,
    [int]$TimeoutSeconds
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    try {
      $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2
      if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
        return
      }
    } catch {
    }
    Start-Sleep -Milliseconds 250
  } while ((Get-Date) -lt $deadline)

  throw "Timed out waiting for probe server at $Url"
}

function Remove-ArtifactIfPresent {
  param([string]$Path)
  if (Test-Path -LiteralPath $Path) {
    Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
  }
}

function Get-ArtifactRecord {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    return [ordered]@{
      path = $Path
      exists = $false
      size = 0
    }
  }

  $item = Get-Item -LiteralPath $Path
  return [ordered]@{
    path = $Path
    exists = $true
    size = if ($item.PSIsContainer) { 0 } else { $item.Length }
  }
}

function ConvertTo-ProcessArgumentString {
  param([string[]]$Arguments)

  $escaped = foreach ($argument in $Arguments) {
    if ($null -eq $argument) {
      '""'
      continue
    }
    $value = [string]$argument
    if ($value -eq "") {
      '""'
      continue
    }
    if ($value -match '[\s"]') {
      '"' + ($value -replace '(\\*)"','$1$1\"' -replace '(\\+)$','$1$1') + '"'
      continue
    }
    $value
  }
  return ($escaped -join " ")
}

function Start-RedirectedProcess {
  param(
    [string]$FilePath,
    [string[]]$Arguments,
    [string]$WorkingDirectory,
    [string]$StdoutPath,
    [string]$StderrPath,
    [hashtable]$EnvironmentOverrides
  )

  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $FilePath
  $psi.Arguments = ConvertTo-ProcessArgumentString -Arguments $Arguments
  $psi.WorkingDirectory = $WorkingDirectory
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.CreateNoWindow = $false
  if ($EnvironmentOverrides) {
    foreach ($entry in $EnvironmentOverrides.GetEnumerator()) {
      $psi.EnvironmentVariables[[string]$entry.Key] = [string]$entry.Value
    }
  }

  $process = New-Object System.Diagnostics.Process
  $process.StartInfo = $psi
  $process.Start() | Out-Null

  return [ordered]@{
    process = $process
    stdout_task = $process.StandardOutput.ReadToEndAsync()
    stderr_task = $process.StandardError.ReadToEndAsync()
  }
}

function Complete-RedirectedProcess {
  param(
    $Launch,
    [string]$StdoutPath,
    [string]$StderrPath
  )

  if (-not $Launch) {
    return
  }
  $Launch.stdout_task.Wait()
  $Launch.stderr_task.Wait()
  $Launch.stdout_task.Result | Set-Content -Path $StdoutPath -Encoding Ascii
  $Launch.stderr_task.Result | Set-Content -Path $StderrPath -Encoding Ascii
}

function Wait-ForTitleMatch {
  param(
    [IntPtr]$Hwnd,
    [scriptblock]$Predicate,
    [int]$Attempts = 40,
    [int]$SleepMs = 200
  )

  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $title = Get-SmokeWindowTitle $Hwnd
    if (& $Predicate $title) {
      return $title
    }
  }
  return $null
}

function Wait-ForTitleLike {
  param(
    [IntPtr]$Hwnd,
    [string]$Pattern,
    [int]$Attempts = 40,
    [int]$SleepMs = 200
  )

  return Wait-ForTitleMatch -Hwnd $Hwnd -Predicate { param($Title) $Title -like $Pattern } -Attempts $Attempts -SleepMs $SleepMs
}

function Focus-GoogleQuery {
  param(
    [IntPtr]$Hwnd,
    [int]$Attempts,
    [int]$SleepMs
  )

  $focusedTitle = Wait-ForTitleMatch -Hwnd $Hwnd -Predicate {
    param($Title)
    $Title -match 'A=INPUT:q:[^|]*\|Q=INPUT:q:'
  } -Attempts 6 -SleepMs ([Math]::Max($SleepMs, 200))
  if ($focusedTitle) {
    return $focusedTitle
  }

  for ($i = 0; $i -lt $Attempts; $i++) {
    Send-SmokeTab
    $focusedTitle = Wait-ForTitleMatch -Hwnd $Hwnd -Predicate {
      param($Title)
      $Title -match 'A=INPUT:q:[^|]*\|Q=INPUT:q:'
    } -Attempts 6 -SleepMs ([Math]::Max($SleepMs, 150))
    if ($focusedTitle) {
      return $focusedTitle
    }
  }

  return $null
}

New-Item -ItemType Directory -Force -Path $ProbeDir | Out-Null
foreach ($path in @($serverStdout, $serverStderr, $browserStdout, $browserStderr, $summaryPath)) {
  Remove-ArtifactIfPresent -Path $path
}

if (-not (Test-Path -LiteralPath $BrowserExe -PathType Leaf)) {
  throw "Lightpanda binary not found: $BrowserExe"
}

if (Test-Path -LiteralPath $ProfileRoot) {
  Remove-Item -LiteralPath $ProfileRoot -Recurse -Force -ErrorAction SilentlyContinue
}
$appDataRoot = Join-Path $ProfileRoot "lightpanda"
New-Item -ItemType Directory -Force -Path $appDataRoot | Out-Null
@"
lightpanda-browse-settings-v1
restore_previous_session	0
allow_script_popups	0
default_zoom_percent	100
homepage_url	
"@ | Set-Content -Path (Join-Path $appDataRoot "browse-settings-v1.txt") -NoNewline

$serverLaunch = $null
$browserLaunch = $null
$browserProcess = $null
$ready = $false
$boundTitle = $null
$focusedTitle = $null
$titleAfterType = $null
$titleAfterSubmit = $null
$typedWorked = $false
$submittedWorked = $false
$submitAfterKeypress = $false
$failure = $null

try {
  if (-not $SkipLocalServer) {
    $python = Resolve-PythonCommand
    $serverLaunch = Start-RedirectedProcess `
      -FilePath $python.FileName `
      -Arguments ($python.Arguments + @($Port, "--bind", $Host)) `
      -WorkingDirectory $RepoRoot `
      -StdoutPath $serverStdout `
      -StderrPath $serverStderr
    Wait-HttpReady -Url $probeUrl -TimeoutSeconds $ServerReadyTimeoutSeconds
    $ready = $true
  } else {
    Wait-HttpReady -Url $probeUrl -TimeoutSeconds $ServerReadyTimeoutSeconds
    $ready = $true
  }

  $browserLaunch = Start-RedirectedProcess `
    -FilePath $BrowserExe `
    -Arguments @(
      "browse",
      "--browser_mode", "headed",
      "--window_width", $WindowWidth,
      "--window_height", $WindowHeight,
      $probeUrl
    ) `
    -WorkingDirectory $RepoRoot `
    -StdoutPath $browserStdout `
    -StderrPath $browserStderr `
    -EnvironmentOverrides @{
      "APPDATA" = $ProfileRoot
      "LOCALAPPDATA" = $ProfileRoot
    }
  $browserProcess = $browserLaunch.process

  $hwnd = [IntPtr]::Zero
  for ($i = 0; $i -lt $WindowReadyAttempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $proc = Get-Process -Id $browserProcess.Id -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      $hwnd = [IntPtr]$proc.MainWindowHandle
      break
    }
  }
  if ($hwnd -eq [IntPtr]::Zero) {
    throw "google home title probe window handle not found"
  }

  Show-SmokeWindow $hwnd
  Start-Sleep -Milliseconds $PollMilliseconds

  $boundTitle = Wait-ForTitleMatch -Hwnd $hwnd -Predicate {
    param($Title)
    $Title -like "*Q=INPUT:q*"
  } -Attempts $TitleWaitAttempts -SleepMs $PollMilliseconds
  if (-not $boundTitle) {
    throw "google home title probe never bound the query input"
  }

  $focusedTitle = Focus-GoogleQuery -Hwnd $hwnd -Attempts 6 -SleepMs $PollMilliseconds
  if (-not $focusedTitle) {
    throw "google home title probe could not focus the query input"
  }

  Send-SmokeAsciiText $InputText
  $typePattern = "*|V=$InputText|*"
  $titleAfterType = Wait-ForTitleMatch -Hwnd $hwnd -Predicate {
    param($Title)
    ($Title -like $typePattern) -and ($Title -like "*Q=INPUT:q*")
  } -Attempts $TitleWaitAttempts -SleepMs $PollMilliseconds
  $typedWorked = $null -ne $titleAfterType
  if (-not $typedWorked) {
    throw "google home title probe did not observe typed query text"
  }

  Send-SmokeEnter
  $submitPattern = "SUBMIT:$InputText*|V=$InputText*"
  $titleAfterSubmit = Wait-ForTitleLike -Hwnd $hwnd -Pattern $submitPattern -Attempts $TitleWaitAttempts -SleepMs $PollMilliseconds
  $submittedWorked = $null -ne $titleAfterSubmit
  if (-not $submittedWorked) {
    throw "google home title probe did not observe query submit"
  }

  $submitAfterKeypress = $titleAfterSubmit -match '\|E=KP:'
  if (-not $submitAfterKeypress) {
    throw "google home title probe submit did not preserve keypress ordering"
  }
} catch {
  $failure = $_.Exception.Message
} finally {
  if ($browserProcess -and -not $LeaveOpen) {
    Stop-Process -Id $browserProcess.Id -Force -ErrorAction SilentlyContinue
  }
  if ($browserLaunch) {
    if ($browserLaunch.process -and -not $browserLaunch.process.HasExited -and -not $LeaveOpen) {
      $browserLaunch.process.WaitForExit()
    }
    if ($browserLaunch.process.HasExited -or -not $LeaveOpen) {
      Complete-RedirectedProcess -Launch $browserLaunch -StdoutPath $browserStdout -StderrPath $browserStderr
    }
  }

  if ($serverLaunch) {
    if (-not $serverLaunch.process.HasExited) {
      Stop-Process -Id $serverLaunch.process.Id -Force -ErrorAction SilentlyContinue
      $serverLaunch.process.WaitForExit()
    }
    Complete-RedirectedProcess -Launch $serverLaunch -StdoutPath $serverStdout -StderrPath $serverStderr
  }

  $summary = [ordered]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    repo_root = $RepoRoot
    browser_exe = $BrowserExe
    probe_url = $probeUrl
    probe_dir = $ProbeDir
    profile_root = $ProfileRoot
    local_server_started = (-not $SkipLocalServer)
    left_open = [bool]$LeaveOpen
    ready = $ready
    bound_title = $boundTitle
    focused_title = $focusedTitle
    title_after_type = $titleAfterType
    title_after_submit = $titleAfterSubmit
    typed_worked = $typedWorked
    submitted_worked = $submittedWorked
    submit_after_keypress = $submitAfterKeypress
    browser_stdout = Get-ArtifactRecord -Path $browserStdout
    browser_stderr = Get-ArtifactRecord -Path $browserStderr
    server_stdout = Get-ArtifactRecord -Path $serverStdout
    server_stderr = Get-ArtifactRecord -Path $serverStderr
    error = $failure
  }

  $summary | ConvertTo-Json -Depth 6 | Set-Content -Path $summaryPath -Encoding Ascii
  $summary | ConvertTo-Json -Depth 6
}

if ($failure) {
  exit 1
}
