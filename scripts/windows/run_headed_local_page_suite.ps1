[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$PagesRoot,
  [string]$PythonExe = "python",
  [int]$Port = 38421,
  [int]$WindowWidth = 1366,
  [int]$WindowHeight = 768,
  [int]$PageLoadTimeoutSec = 25,
  [int]$SettleMs = 1200,
  [string[]]$PageNames,
  [string]$OutputRoot
)

$ErrorActionPreference = 'Stop'

$scriptRoot = $PSScriptRoot
if (-not $RepoRoot) {
  $RepoRoot = (Resolve-Path (Join-Path $scriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
  $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}
if (-not $OutputRoot) {
  $OutputRoot = Join-Path $RepoRoot "tmp-browser-smoke\local-page-suite"
}

if (-not $PagesRoot) {
  throw "PagesRoot is required and should point at a directory that contains the local HTML compatibility pages."
}
if (-not (Test-Path $PagesRoot)) {
  throw "PagesRoot does not exist: $PagesRoot"
}
if (-not (Test-Path $BrowserExe)) {
  throw "Browser executable not found: $BrowserExe"
}

$resolvedPagesRoot = (Resolve-Path $PagesRoot).Path
$resolvedBrowserExe = (Resolve-Path $BrowserExe).Path
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$resolvedOutputRoot = (Resolve-Path $OutputRoot).Path

$pageFiles = Get-ChildItem -Path $resolvedPagesRoot -File -Filter *.html | Sort-Object Name
if ($PageNames -and $PageNames.Count -gt 0) {
  $selected = @()
  foreach ($pageName in $PageNames) {
    $match = $pageFiles | Where-Object { $_.Name -eq $pageName }
    if (-not $match) {
      throw "Requested page was not found under PagesRoot: $pageName"
    }
    $selected += $match
  }
  $pageFiles = $selected
}
if (-not $pageFiles -or $pageFiles.Count -eq 0) {
  throw "No .html files were found under PagesRoot: $resolvedPagesRoot"
}

$serverStdout = Join-Path $resolvedOutputRoot "server.stdout.txt"
$serverStderr = Join-Path $resolvedOutputRoot "server.stderr.txt"
if (Test-Path $serverStdout) { Remove-Item $serverStdout -Force }
if (Test-Path $serverStderr) { Remove-Item $serverStderr -Force }

$server = $null
try {
  $serverArgs = @(
    "-m",
    "http.server",
    $Port.ToString(),
    "--bind",
    "127.0.0.1",
    "--directory",
    $resolvedPagesRoot
  )
  $server = Start-Process -FilePath $PythonExe -ArgumentList $serverArgs -WorkingDirectory $resolvedPagesRoot -PassThru -RedirectStandardOutput $serverStdout -RedirectStandardError $serverStderr

  $readyUrl = "http://127.0.0.1:$Port/$($pageFiles[0].Name)"
  $serverReady = $false
  $serverDeadline = (Get-Date).AddSeconds(15)
  while ((Get-Date) -lt $serverDeadline) {
    try {
      $response = Invoke-WebRequest -UseBasicParsing -Uri $readyUrl -TimeoutSec 2
      if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
        $serverReady = $true
        break
      }
    } catch {
    }
    Start-Sleep -Milliseconds 250
  }

  if (-not $serverReady) {
    throw "Local HTML server did not become ready at $readyUrl"
  }

  $pageResults = @()
  foreach ($page in $pageFiles) {
    $pageDir = Join-Path $resolvedOutputRoot $page.BaseName
    New-Item -ItemType Directory -Force -Path $pageDir | Out-Null

    $stdoutPath = Join-Path $pageDir "browser.stdout.txt"
    $stderrPath = Join-Path $pageDir "browser.stderr.txt"
    $screenshotPath = Join-Path $pageDir "headed.png"
    $profileDir = Join-Path $pageDir "profile"
    $resultPath = Join-Path $pageDir "result.json"

    foreach ($path in @($stdoutPath, $stderrPath, $screenshotPath, $resultPath)) {
      if (Test-Path $path) { Remove-Item $path -Force }
    }
    if (Test-Path $profileDir) {
      Remove-Item $profileDir -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

    $url = "http://127.0.0.1:$Port/$($page.Name)"
    $browserArgs = @(
      "browse",
      "--headed",
      "--window_width",
      $WindowWidth.ToString(),
      "--window_height",
      $WindowHeight.ToString(),
      "--profile_dir",
      $profileDir,
      "--screenshot_png",
      $screenshotPath,
      $url
    )

    $browser = Start-Process -FilePath $resolvedBrowserExe -ArgumentList $browserArgs -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

    $pageDeadline = (Get-Date).AddSeconds($PageLoadTimeoutSec)
    $screenshotReady = $false
    $windowObserved = $false
    while ((Get-Date) -lt $pageDeadline) {
      $browser.Refresh()
      if ($browser.MainWindowHandle -ne 0) {
        $windowObserved = $true
      }
      if (Test-Path $screenshotPath) {
        $shot = Get-Item $screenshotPath
        if ($shot.Length -gt 0) {
          $screenshotReady = $true
          break
        }
      }
      if ($browser.HasExited) {
        break
      }
      Start-Sleep -Milliseconds 250
    }

    Start-Sleep -Milliseconds $SettleMs
    $browser.Refresh()
    $windowTitle = $browser.MainWindowTitle

    if (-not $browser.HasExited) {
      Stop-Process -Id $browser.Id -Force -ErrorAction SilentlyContinue
      $browser.WaitForExit()
    }

    $pageResult = [ordered]@{
      page = $page.Name
      url = $url
      browser_pid = $browser.Id
      exit_code = $browser.ExitCode
      window_observed = $windowObserved
      window_title = $windowTitle
      screenshot_ready = $screenshotReady
      screenshot_exists = (Test-Path $screenshotPath)
      screenshot_size = if (Test-Path $screenshotPath) { (Get-Item $screenshotPath).Length } else { 0 }
      stdout_path = $stdoutPath
      stderr_path = $stderrPath
      screenshot_path = $screenshotPath
      profile_dir = $profileDir
      success = ($windowObserved -or $screenshotReady)
    }

    $pageResult | ConvertTo-Json -Depth 4 | Set-Content -Path $resultPath -Encoding Ascii
    $pageResults += [pscustomobject]$pageResult
  }

  $suiteResult = [ordered]@{
    generated_utc = (Get-Date).ToUniversalTime().ToString("o")
    repo_root = $RepoRoot
    browser_exe = $resolvedBrowserExe
    pages_root = $resolvedPagesRoot
    output_root = $resolvedOutputRoot
    port = $Port
    page_count = $pageResults.Count
    success_count = @($pageResults | Where-Object { $_.success }).Count
    page_results = $pageResults
  }

  $suiteResultPath = Join-Path $resolvedOutputRoot "suite-result.json"
  $suiteResult | ConvertTo-Json -Depth 6 | Set-Content -Path $suiteResultPath -Encoding Ascii
  $suiteResult | ConvertTo-Json -Depth 6
}
finally {
  if ($server -and -not $server.HasExited) {
    Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
    $server.WaitForExit()
  }
}
