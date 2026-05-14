[CmdletBinding()]
param(
  [string]$ContentRoot,
  [string[]]$Pages = @(),
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8164,
  [int]$WindowWidth = 1366,
  [int]$WindowHeight = 900,
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 80,
  [int]$TitleWaitAttempts = 40,
  [int]$PollMilliseconds = 250,
  [int]$PageSettleMilliseconds = 1000
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
    return @{ FileName = "python"; Arguments = @() }
  }
  if (Get-Command py -ErrorAction SilentlyContinue) {
    return @{ FileName = "py"; Arguments = @("-3") }
  }
  throw "Python was not found in PATH. Install Python or start the local HTML compatibility server separately."
}

function Resolve-ContentRoot([string]$RequestedPath) {
  if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
    return (Resolve-Path -LiteralPath $RequestedPath).Path
  }
  if (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_COMPAT_HTML_ROOT)) {
    return (Resolve-Path -LiteralPath $env:LIGHTPANDA_COMPAT_HTML_ROOT).Path
  }
  throw "Provide -ContentRoot or set LIGHTPANDA_COMPAT_HTML_ROOT to the directory containing the local HTML pages."
}

function Get-RelativePagePath([string]$RootPath, [string]$FullPath) {
  $rootFull = (Resolve-Path -LiteralPath $RootPath).Path
  $pageFull = (Resolve-Path -LiteralPath $FullPath).Path
  $rootUri = New-Object System.Uri(($rootFull.TrimEnd('\') + '\'))
  $pageUri = New-Object System.Uri($pageFull)
  return [System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pageUri).ToString())
}

function Get-PageUrlPath([string]$RelativePath) {
  $segments = $RelativePath -split "[/\\]"
  return ($segments | ForEach-Object { [System.Uri]::EscapeDataString($_) }) -join "/"
}

function Wait-HttpReady([string]$Url, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
      if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) {
        return
      }
    } catch {
    }
    Start-Sleep -Milliseconds $PollMilliseconds
  } while ((Get-Date) -lt $deadline)

  throw "local HTML compatibility server did not become ready at $Url"
}

function Wait-FileReady([string]$Path, [int]$Attempts) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    if ((Test-Path -LiteralPath $Path) -and ((Get-Item -LiteralPath $Path).Length -gt 0)) {
      return $true
    }
  }
  return $false
}

function Wait-WindowTitle([IntPtr]$Hwnd, [int]$Attempts) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $title = Get-SmokeWindowTitle $Hwnd
    if (-not [string]::IsNullOrWhiteSpace($title)) {
      return $title
    }
  }
  return ""
}

function New-ArtifactSlug([string]$RelativePath) {
  $slug = ($RelativePath -replace "[/\\]", "__") -replace "[^A-Za-z0-9._-]", "-"
  if ([string]::IsNullOrWhiteSpace($slug)) {
    return "page"
  }
  return $slug
}

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "tabs\TabProbeCommon.ps1")

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-RepoRoot $PSScriptRoot }
$root = Join-Path $repo "tmp-browser-smoke\local-html-compat"
$artifactRoot = Join-Path $root "artifacts"
$browserExe = if ($BrowserExe) { $BrowserExe } elseif (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_BROWSER_EXE)) { $env:LIGHTPANDA_BROWSER_EXE } else { Join-Path $repo "zig-out\bin\lightpanda.exe" }
$serverScript = Join-Path $root "local_html_server.py"
$contentRoot = Resolve-ContentRoot $ContentRoot
$serverOut = Join-Path $artifactRoot "local-html-compat.server.stdout.txt"
$serverErr = Join-Path $artifactRoot "local-html-compat.server.stderr.txt"

if (-not (Test-Path -LiteralPath $browserExe)) {
  throw "headed browser binary not found: $browserExe"
}
if (-not (Test-Path -LiteralPath $serverScript)) {
  throw "local HTML compatibility server script not found: $serverScript"
}

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
Remove-Item -LiteralPath $serverOut,$serverErr -Force -ErrorAction SilentlyContinue

if ($Pages.Count -gt 0) {
  $pageFiles = foreach ($page in $Pages) {
    $candidate = Join-Path $contentRoot $page
    if (-not (Test-Path -LiteralPath $candidate)) {
      throw "Requested page was not found under $contentRoot: $page"
    }
    (Resolve-Path -LiteralPath $candidate).Path
  }
} else {
  $pageFiles = Get-ChildItem -LiteralPath $contentRoot -Recurse -File |
    Where-Object { $_.Extension -in @(".html", ".htm") } |
    Sort-Object FullName |
    ForEach-Object { $_.FullName }
}

if (-not $pageFiles -or $pageFiles.Count -eq 0) {
  throw "No HTML pages were found under $contentRoot"
}

$server = $null
$ready = $false
$overallFailure = $false
$results = New-Object System.Collections.Generic.List[object]
$originalAppData = $env:APPDATA
$originalLocalAppData = $env:LOCALAPPDATA

try {
  $python = Resolve-PythonCommand
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @($serverScript, $Port, $Host, $contentRoot)) -WorkingDirectory $root -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  Wait-HttpReady -Url "http://$Host`:$Port/ping" -TimeoutSeconds $ServerReadyTimeoutSeconds
  $ready = $true

  foreach ($pageFile in $pageFiles) {
    $relativePath = Get-RelativePagePath $contentRoot $pageFile
    $slug = New-ArtifactSlug $relativePath
    $pageUrl = "http://$Host`:$Port/$(Get-PageUrlPath $relativePath)"
    $profileRoot = Join-Path $artifactRoot ("profile-" + $slug)
    $browserOut = Join-Path $artifactRoot ($slug + ".browser.stdout.txt")
    $browserErr = Join-Path $artifactRoot ($slug + ".browser.stderr.txt")
    $pngPath = Join-Path $artifactRoot ($slug + ".png")
    $browser = $null
    $pngReady = $false
    $title = ""
    $failure = $null
    $browserMeta = $null

    Remove-Item -LiteralPath $browserOut,$browserErr,$pngPath -Force -ErrorAction SilentlyContinue
    cmd /c "rmdir /s /q `"$profileRoot`"" | Out-Null
    New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null

    try {
      $probeEnv = Get-TabProbeEnvironment $profileRoot
      $env:APPDATA = $probeEnv.APPDATA
      $env:LOCALAPPDATA = $probeEnv.LOCALAPPDATA

      $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "$WindowWidth", "--window_height", "$WindowHeight", "--screenshot_png", $pngPath, $pageUrl) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
      $pngReady = Wait-FileReady -Path $pngPath -Attempts $WindowReadyAttempts
      if (-not $pngReady) { throw "compatibility screenshot did not become ready" }

      $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts
      if ($hwnd -eq [IntPtr]::Zero) { throw "compatibility window handle not found" }

      Show-SmokeWindow $hwnd
      $title = Wait-WindowTitle -Hwnd $hwnd -Attempts $TitleWaitAttempts
      Start-Sleep -Milliseconds $PageSettleMilliseconds
      $settledTitle = Get-SmokeWindowTitle $hwnd
      if (-not [string]::IsNullOrWhiteSpace($settledTitle)) {
        $title = $settledTitle
      }
    } catch {
      $failure = $_.Exception.Message
      $overallFailure = $true
    } finally {
      $browserMeta = Stop-OwnedProbeProcess $browser
      $env:APPDATA = $originalAppData
      $env:LOCALAPPDATA = $originalLocalAppData
    }

    $results.Add([ordered]@{
      page = $relativePath
      url = $pageUrl
      screenshot_path = $pngPath
      browser_stdout_path = $browserOut
      browser_stderr_path = $browserErr
      screenshot_ready = $pngReady
      title = $title
      error = $failure
      browser_meta = $browserMeta
      success = ($null -eq $failure) -and $pngReady
    })
  }
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
  $env:APPDATA = $originalAppData
  $env:LOCALAPPDATA = $originalLocalAppData
  Start-Sleep -Milliseconds 200
  $serverGone = if ($server) { -not (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) } else { $true }

  [ordered]@{
    content_root = $contentRoot
    artifact_root = $artifactRoot
    browser_exe = $browserExe
    host = $Host
    port = $Port
    server_ready = $ready
    page_count = $pageFiles.Count
    server_stdout_path = $serverOut
    server_stderr_path = $serverErr
    results = $results
    server_meta = $serverMeta
    server_gone = $serverGone
  } | ConvertTo-Json -Depth 8
}

if ($overallFailure) {
  exit 1
}
