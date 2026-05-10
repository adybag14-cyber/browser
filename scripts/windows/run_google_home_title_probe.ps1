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
  $ProbeDir = Join-Path $RepoRoot "tmp-browser-smoke\google-investigation-next"
}
if (-not $ProfileRoot) {
  $ProfileRoot = Join-Path $ProbeDir "profile"
}

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
  if (Test-Path $Path) {
    Remove-Item -Path $Path -Force -ErrorAction SilentlyContinue
  }
}

function Get-ArtifactRecord {
  param([string]$Path)
  if (-not (Test-Path $Path)) {
    return [ordered]@{
      path = $Path
      exists = $false
      size = 0
    }
  }

  $item = Get-Item $Path
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
      '"' + ($value -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
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

  $stdoutTask = $process.StandardOutput.ReadToEndAsync()
  $stderrTask = $process.StandardError.ReadToEndAsync()

  return [ordered]@{
    process = $process
    stdout_task = $stdoutTask
    stderr_task = $stderrTask
    stdout_path = $StdoutPath
    stderr_path = $StderrPath
  }
}

New-Item -ItemType Directory -Force -Path $ProbeDir, $ProfileRoot | Out-Null

$probeUrl = "http://$Host`:$Port/src/browser/tests/page/google_home_title_probe.html"
$serverStdout = Join-Path $ProbeDir "probe-server.stdout.txt"
$serverStderr = Join-Path $ProbeDir "probe-server.stderr.txt"
$browserStdout = Join-Path $ProbeDir "probe-browser.stdout.txt"
$browserStderr = Join-Path $ProbeDir "probe-browser.stderr.txt"
$summaryPath = Join-Path $ProbeDir "probe-summary.json"
$browseRenderLog = Join-Path $ProbeDir "browse-render.log"
$runtimeRendererLog = Join-Path $ProbeDir "runtime-renderer.log"
$sessionWaitLog = Join-Path $ProbeDir "session-wait.log"

foreach ($path in @(
  $serverStdout,
  $serverStderr,
  $browserStdout,
  $browserStderr,
  $summaryPath,
  $browseRenderLog,
  $runtimeRendererLog,
  $sessionWaitLog
)) {
  Remove-ArtifactIfPresent -Path $path
}

Get-ChildItem -Path $ProbeDir -Filter "runtime-input-backend-*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $ProbeDir -Filter "wndproc-input-*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

if (-not (Test-Path $BrowserExe)) {
  throw "Lightpanda binary not found: $BrowserExe"
}

$serverLaunch = $null
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

  Write-Host ""
  Write-Host "Google headed probe is live."
  Write-Host ("URL: {0}" -f $probeUrl)
  Write-Host ("Browser PID: {0}" -f $browserProcess.Id)
  Write-Host ("Artifacts: {0}" -f $ProbeDir)
  Write-Host "Close the browser window when you are done reproducing the issue."
  Write-Host ""

  Wait-Process -Id $browserProcess.Id
  $browserLaunch.stdout_task.Wait()
  $browserLaunch.stderr_task.Wait()
  $browserLaunch.stdout_task.Result | Set-Content -Path $browserStdout -Encoding Ascii
  $browserLaunch.stderr_task.Result | Set-Content -Path $browserStderr -Encoding Ascii

  $runtimeInputLogs = @(Get-ChildItem -Path $ProbeDir -Filter "runtime-input-backend-*.log" -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object { $_.FullName })
  $wndprocLogs = @(Get-ChildItem -Path $ProbeDir -Filter "wndproc-input-*.log" -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object { $_.FullName })

  $summary = [ordered]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    repo_root = $RepoRoot
    browser_exe = $BrowserExe
    probe_url = $probeUrl
    probe_dir = $ProbeDir
    profile_root = $ProfileRoot
    browser_exit_code = $browserProcess.ExitCode
    local_server_started = (-not $SkipLocalServer)
    browser_stdout = (Get-ArtifactRecord -Path $browserStdout)
    browser_stderr = (Get-ArtifactRecord -Path $browserStderr)
    server_stdout = (Get-ArtifactRecord -Path $serverStdout)
    server_stderr = (Get-ArtifactRecord -Path $serverStderr)
    browse_render_log = (Get-ArtifactRecord -Path $browseRenderLog)
    runtime_renderer_log = (Get-ArtifactRecord -Path $runtimeRendererLog)
    session_wait_log = (Get-ArtifactRecord -Path $sessionWaitLog)
    runtime_input_logs = $runtimeInputLogs
    wndproc_input_logs = $wndprocLogs
  }

  $summary | ConvertTo-Json -Depth 6 | Set-Content -Path $summaryPath -Encoding Ascii
  $summary | ConvertTo-Json -Depth 6
} finally {
  if ($serverLaunch) {
    if (-not $serverLaunch.process.HasExited) {
      Stop-Process -Id $serverLaunch.process.Id -Force -ErrorAction SilentlyContinue
      $serverLaunch.process.WaitForExit()
    }
    $serverLaunch.stdout_task.Wait()
    $serverLaunch.stderr_task.Wait()
    $serverLaunch.stdout_task.Result | Set-Content -Path $serverStdout -Encoding Ascii
    $serverLaunch.stderr_task.Result | Set-Content -Path $serverStderr -Encoding Ascii
  }
}