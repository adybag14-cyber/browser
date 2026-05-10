$ErrorActionPreference = "Stop"

param(
  [Parameter(Mandatory = $true)]
  [string[]]$FixturePaths,
  [string]$RepoRoot = "C:\Users\adyba\src\lightpanda-browser",
  [string]$BrowserExe = "",
  [int]$Port = 8168,
  [int]$WindowWidth = 1366,
  [int]$WindowHeight = 900
)

$root = Join-Path $RepoRoot "tmp-browser-smoke\local-html-fixtures"
$stageRoot = Join-Path $root "staged-fixtures"
$outputRoot = Join-Path $root "output"
$serverOut = Join-Path $outputRoot "server.stdout.txt"
$serverErr = Join-Path $outputRoot "server.stderr.txt"
$resultPath = Join-Path $outputRoot "fixture-results.json"

if ([string]::IsNullOrWhiteSpace($BrowserExe)) {
  $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

. (Join-Path $RepoRoot "tmp-browser-smoke\common\Win32Input.ps1")

function Remove-TreeIfPresent([string]$Path) {
  if (Test-Path $Path) {
    cmd /c "rmdir /s /q `"$Path`"" | Out-Null
  }
}

function Get-HtmlTitle([string]$Path) {
  $raw = Get-Content -Path $Path -Raw
  $match = [regex]::Match($raw, '(?is)<title[^>]*>(.*?)</title>')
  if (-not $match.Success) {
    return ""
  }
  return ([regex]::Replace($match.Groups[1].Value, '\s+', ' ')).Trim()
}

function Wait-HttpReady([string]$Url, [int]$Attempts = 40, [int]$SleepMs = 250) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
      if ($resp.StatusCode -eq 200) {
        return $true
      }
    } catch {}
  }
  return $false
}

function Wait-ForMainWindow([int]$Pid, [int]$Attempts = 60, [int]$SleepMs = 250) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    $proc = Get-Process -Id $Pid -ErrorAction SilentlyContinue
    if ($proc -and $proc.MainWindowHandle -ne 0) {
      return [IntPtr]$proc.MainWindowHandle
    }
  }
  return [IntPtr]::Zero
}

function Wait-ForScreenshot([string]$Path, [int]$Attempts = 80, [int]$SleepMs = 250) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    if ((Test-Path $Path) -and ((Get-Item $Path).Length -gt 0)) {
      return $true
    }
  }
  return $false
}

function Stop-TrackedProcess($Process) {
  if (-not $Process) {
    return
  }
  $meta = Get-CimInstance Win32_Process -Filter "ProcessId=$($Process.Id)" -ErrorAction SilentlyContinue | Select-Object Name,ProcessId,CommandLine,CreationDate
  if ($meta -and $meta.CommandLine -and $meta.CommandLine -notmatch "codex\.js|@openai/codex") {
    Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
  }
}

function Copy-FixtureAssets($Fixture, [string]$TargetDir) {
  $assetDir = Join-Path $Fixture.DirectoryName ($Fixture.BaseName + "_files")
  if (Test-Path $assetDir) {
    Copy-Item -Recurse -Force -Path $assetDir -Destination (Join-Path $TargetDir (Split-Path $assetDir -Leaf))
  }
}

Remove-TreeIfPresent $stageRoot
Remove-TreeIfPresent $outputRoot
New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
Remove-Item $serverOut,$serverErr,$resultPath -Force -ErrorAction SilentlyContinue

$fixtureSpecs = @()
for ($i = 0; $i -lt $FixturePaths.Count; $i++) {
  $fixturePath = $FixturePaths[$i]
  if (-not (Test-Path $fixturePath)) {
    throw "fixture path not found: $fixturePath"
  }

  $fixture = Get-Item $fixturePath
  $slug = "fixture-{0:d2}" -f ($i + 1)
  $fixtureDir = Join-Path $stageRoot $slug
  New-Item -ItemType Directory -Force -Path $fixtureDir | Out-Null
  Copy-Item -Force -Path $fixture.FullName -Destination (Join-Path $fixtureDir "index.html")
  Copy-FixtureAssets $fixture $fixtureDir

  $fixtureSpecs += [ordered]@{
    name = $fixture.Name
    slug = $slug
    source_path = $fixture.FullName
    expected_title = Get-HtmlTitle $fixture.FullName
    url = "http://127.0.0.1:$Port/$slug/index.html"
    screenshot_path = Join-Path $outputRoot ($slug + ".png")
  }
}

$server = $null
$results = @()

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m","http.server",$Port,"--bind","127.0.0.1" -WorkingDirectory $stageRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  if (-not (Wait-HttpReady "http://127.0.0.1:$Port/")) {
    throw "local fixture probe server did not become ready"
  }

  foreach ($fixture in $fixtureSpecs) {
    Remove-Item $fixture.screenshot_path -Force -ErrorAction SilentlyContinue
    $browserOut = Join-Path $outputRoot ($fixture.slug + ".browser.stdout.txt")
    $browserErr = Join-Path $outputRoot ($fixture.slug + ".browser.stderr.txt")
    Remove-Item $browserOut,$browserErr -Force -ErrorAction SilentlyContinue

    $browser = $null
    $failure = $null
    $hwnd = [IntPtr]::Zero
    $windowTitle = $null
    $titleMatched = $false
    $screenshotReady = $false

    try {
      $browser = Start-Process -FilePath $BrowserExe -ArgumentList "browse",$fixture.url,"--window_width",$WindowWidth,"--window_height",$WindowHeight,"--screenshot_png",$fixture.screenshot_path -WorkingDirectory $RepoRoot -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
      $screenshotReady = Wait-ForScreenshot $fixture.screenshot_path
      if (-not $screenshotReady) {
        throw "screenshot did not become ready"
      }

      $hwnd = Wait-ForMainWindow $browser.Id
      if ($hwnd -eq [IntPtr]::Zero) {
        throw "browser window handle not found"
      }

      Show-SmokeWindow $hwnd
      Start-Sleep -Milliseconds 250
      $windowTitle = Get-SmokeWindowTitle $hwnd
      if ([string]::IsNullOrWhiteSpace($fixture.expected_title)) {
        $titleMatched = -not [string]::IsNullOrWhiteSpace($windowTitle)
      } else {
        $titleMatched = $windowTitle.IndexOf($fixture.expected_title, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
      }
      if (-not $titleMatched) {
        throw "window title did not match expected page title"
      }
    } catch {
      $failure = $_.Exception.Message
    } finally {
      Stop-TrackedProcess $browser
      Start-Sleep -Milliseconds 200
    }

    $results += [ordered]@{
      name = $fixture.name
      source_path = $fixture.source_path
      url = $fixture.url
      expected_title = $fixture.expected_title
      window_title = $windowTitle
      screenshot_path = $fixture.screenshot_path
      screenshot_ready = $screenshotReady
      title_matched = $titleMatched
      error = $failure
    }
  }
} finally {
  Stop-TrackedProcess $server
}

$summary = [ordered]@{
  port = $Port
  browser_exe = $BrowserExe
  stage_root = $stageRoot
  output_root = $outputRoot
  fixtures = $results
}

$summary | ConvertTo-Json -Depth 6 | Set-Content -Path $resultPath -NoNewline
$summary | ConvertTo-Json -Depth 6

if ($results | Where-Object { -not $_.screenshot_ready -or -not $_.title_matched -or $_.error }) {
  exit 1
}
