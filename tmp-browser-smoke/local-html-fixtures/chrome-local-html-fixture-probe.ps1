[CmdletBinding(DefaultParameterSetName = "ByPaths")]
param(
  [Parameter(Mandatory = $true, ParameterSetName = "ByPaths")]
  [string[]]$FixturePaths,
  [Parameter(Mandatory = $true, ParameterSetName = "ByRoot")]
  [string]$FixtureRoot,
  [Parameter(ParameterSetName = "ByRoot")]
  [string]$PreferredInitialPage,
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8168,
  [int]$WindowWidth = 1366,
  [int]$WindowHeight = 900,
  [int]$ServerReadyAttempts = 40,
  [int]$WindowReadyAttempts = 80,
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
    return @{ FileName = "python"; Arguments = @() }
  }
  if (Get-Command py -ErrorAction SilentlyContinue) {
    return @{ FileName = "py"; Arguments = @("-3") }
  }
  throw "Python was not found in PATH. Install Python or start a local Python launcher before running the local HTML fixture probe."
}

function Remove-TreeIfPresent([string]$Path) {
  if (Test-Path -LiteralPath $Path) {
    cmd /c "rmdir /s /q `"$Path`"" | Out-Null
  }
}

function Get-HtmlTitle([string]$Path) {
  $raw = Get-Content -LiteralPath $Path -Raw
  $match = [regex]::Match($raw, '(?is)<title[^>]*>(.*?)</title>')
  if (-not $match.Success) {
    return ""
  }
  return ([regex]::Replace($match.Groups[1].Value, '\s+', ' ')).Trim()
}

function Wait-HttpReady([string]$Url, [int]$Attempts, [int]$SleepMs) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    try {
      $resp = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
      if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) {
        return $true
      }
    } catch {
    }
  }
  return $false
}

function Wait-ForScreenshot([string]$Path, [int]$Attempts, [int]$SleepMs) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $SleepMs
    if ((Test-Path -LiteralPath $Path) -and ((Get-Item -LiteralPath $Path).Length -gt 0)) {
      return $true
    }
  }
  return $false
}

function Copy-FixtureAssets([System.IO.FileInfo]$Fixture, [string]$TargetDir) {
  $assetDir = Join-Path $Fixture.DirectoryName ($Fixture.BaseName + "_files")
  if (Test-Path -LiteralPath $assetDir) {
    Copy-Item -Recurse -Force -Path $assetDir -Destination (Join-Path $TargetDir (Split-Path $assetDir -Leaf))
  }
}

function Add-UniqueString {
  param(
    [Parameter(Mandatory = $true)]
    [System.Collections.Generic.List[string]]$List,
    [Parameter(Mandatory = $true)]
    [string]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return
  }

  if (-not $List.Contains($Value)) {
    $List.Add($Value) | Out-Null
  }
}

function Test-IgnoredLocalAssetReference([string]$Reference) {
  if ([string]::IsNullOrWhiteSpace($Reference)) {
    return $true
  }

  $trimmed = [System.Net.WebUtility]::HtmlDecode($Reference).Trim()
  if ([string]::IsNullOrWhiteSpace($trimmed)) {
    return $true
  }

  if ($trimmed.StartsWith("#") -or $trimmed.StartsWith("/")) {
    return $true
  }

  if ($trimmed -match '^(?i)([a-z][a-z0-9+.-]*:|//)') {
    return $true
  }

  return $false
}

function Get-LocalReferenceCandidates([string]$Content) {
  $candidates = [System.Collections.Generic.List[string]]::new()
  $patterns = @(
    '\b(?:src|href|poster)\s*=\s*["'']([^"'']+)["'']',
    '\bsrcset\s*=\s*["'']([^"'']+)["'']'
  )

  foreach ($pattern in $patterns) {
    foreach ($match in [System.Text.RegularExpressions.Regex]::Matches($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
      $value = $match.Groups[1].Value
      if ($pattern -like '*srcset*') {
        foreach ($entry in ($value -split ',')) {
          $srcsetCandidate = ($entry.Trim() -split '\s+')[0]
          if (-not [string]::IsNullOrWhiteSpace($srcsetCandidate)) {
            Add-UniqueString -List $candidates -Value $srcsetCandidate
          }
        }
      } else {
        Add-UniqueString -List $candidates -Value $value
      }
    }
  }

  return @($candidates)
}

function Resolve-LocalFixtureReferencePath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FixturePath,
    [Parameter(Mandatory = $true)]
    [string]$Reference
  )

  if (Test-IgnoredLocalAssetReference $Reference) {
    return $null
  }

  $decoded = [System.Net.WebUtility]::HtmlDecode($Reference).Trim()
  $relativeReference = (($decoded -split '#', 2)[0] -split '\?', 2)[0]
  if ([string]::IsNullOrWhiteSpace($relativeReference)) {
    return $null
  }

  $fixtureDir = Split-Path -Parent $FixturePath
  $fullFixtureDir = [System.IO.Path]::GetFullPath($fixtureDir).TrimEnd('\', '/')
  $combined = Join-Path $fixtureDir ($relativeReference -replace '/', [System.IO.Path]::DirectorySeparatorChar)
  $resolved = [System.IO.Path]::GetFullPath($combined)
  $directoryPrefix = $fullFixtureDir + [System.IO.Path]::DirectorySeparatorChar
  if (-not $resolved.StartsWith($directoryPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $null
  }

  $displayPath = ($relativeReference -replace '\\', '/').TrimStart('./')
  return [pscustomobject]@{
    full_path = $resolved
    display_path = $displayPath
  }
}

function Get-MissingLocalFixtureAssets([string]$FixturePath) {
  $content = Get-Content -LiteralPath $FixturePath -Raw
  $missing = [System.Collections.Generic.List[string]]::new()

  foreach ($reference in (Get-LocalReferenceCandidates -Content $content)) {
    $resolved = Resolve-LocalFixtureReferencePath -FixturePath $FixturePath -Reference $reference
    if (-not $resolved) {
      continue
    }

    if (-not (Test-Path -LiteralPath $resolved.full_path)) {
      Add-UniqueString -List $missing -Value $resolved.display_path
    }
  }

  return @($missing)
}

function Resolve-FixtureFiles {
  if ($PSCmdlet.ParameterSetName -eq "ByPaths") {
    $resolved = @()
    foreach ($path in $FixturePaths) {
      if (-not (Test-Path -LiteralPath $path)) {
        throw "fixture path not found: $path"
      }
      $item = Get-Item -LiteralPath $path
      if ($item.PSIsContainer) {
        $resolved += Get-ChildItem -LiteralPath $item.FullName -Recurse -File -Filter *.html | Sort-Object FullName
      } else {
        $resolved += $item
      }
    }
    return @($resolved)
  }

  $root = [System.IO.Path]::GetFullPath($FixtureRoot)
  if (-not (Test-Path -LiteralPath $root)) {
    throw "fixture root not found: $root"
  }
  $resolved = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter *.html | Sort-Object FullName)
  if (-not $resolved) {
    throw "fixture root does not contain any .html files: $root"
  }
  if (-not [string]::IsNullOrWhiteSpace($PreferredInitialPage)) {
    $preferredFullPath = [System.IO.Path]::GetFullPath((Join-Path $root $PreferredInitialPage))
    $preferred = $resolved | Where-Object { $_.FullName -eq $preferredFullPath } | Select-Object -First 1
    if (-not $preferred) {
      throw "preferred initial page was not found under fixture root: $PreferredInitialPage"
    }
    $remaining = $resolved | Where-Object { $_.FullName -ne $preferredFullPath }
    return @($preferred) + @($remaining)
  }
  return $resolved
}

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

. (Join-Path $repo "tmp-browser-smoke\common\Win32Input.ps1")
. (Join-Path $repo "tmp-browser-smoke\tabs\TabProbeCommon.ps1")

$root = Join-Path $repo "tmp-browser-smoke\local-html-fixtures"
$stageRoot = Join-Path $root "staged-fixtures"
$outputRoot = Join-Path $root "output"
$serverOut = Join-Path $outputRoot "server.stdout.txt"
$serverErr = Join-Path $outputRoot "server.stderr.txt"
$resultPath = Join-Path $outputRoot "fixture-results.json"

Remove-TreeIfPresent $stageRoot
Remove-TreeIfPresent $outputRoot
New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
Remove-Item -LiteralPath $serverOut,$serverErr,$resultPath -Force -ErrorAction SilentlyContinue

$fixtureFiles = Resolve-FixtureFiles
$fixtureSpecs = @()
for ($i = 0; $i -lt $fixtureFiles.Count; $i++) {
  $fixture = $fixtureFiles[$i]
  $slug = "fixture-{0:d2}" -f ($i + 1)
  $fixtureDir = Join-Path $stageRoot $slug
  New-Item -ItemType Directory -Force -Path $fixtureDir | Out-Null
  Copy-Item -Force -LiteralPath $fixture.FullName -Destination (Join-Path $fixtureDir "index.html")
  Copy-FixtureAssets $fixture $fixtureDir
  $missingLocalAssets = @(Get-MissingLocalFixtureAssets -FixturePath $fixture.FullName)

  $fixtureSpecs += [ordered]@{
    name = $fixture.Name
    slug = $slug
    source_path = $fixture.FullName
    expected_title = Get-HtmlTitle $fixture.FullName
    url = "http://$Host`:$Port/$slug/index.html"
    screenshot_path = Join-Path $outputRoot ($slug + ".png")
    missing_local_assets = $missingLocalAssets
    missing_local_asset_count = $missingLocalAssets.Count
  }
}

$server = $null
$results = @()
$python = Resolve-PythonCommand

try {
  $server = Start-Process -FilePath $python.FileName -ArgumentList ($python.Arguments + @("-m", "http.server", $Port, "--bind", $Host)) -WorkingDirectory $stageRoot -PassThru -RedirectStandardOutput $serverOut -RedirectStandardError $serverErr
  if (-not (Wait-HttpReady -Url "http://$Host`:$Port/" -Attempts $ServerReadyAttempts -SleepMs $PollMilliseconds)) {
    throw "local fixture probe server did not become ready"
  }

  foreach ($fixture in $fixtureSpecs) {
    Remove-Item -LiteralPath $fixture.screenshot_path -Force -ErrorAction SilentlyContinue
    $browserOut = Join-Path $outputRoot ($fixture.slug + ".browser.stdout.txt")
    $browserErr = Join-Path $outputRoot ($fixture.slug + ".browser.stderr.txt")
    Remove-Item -LiteralPath $browserOut,$browserErr -Force -ErrorAction SilentlyContinue

    $browser = $null
    $failure = $null
    $windowTitle = $null
    $titleMatched = $false
    $screenshotReady = $false
    $missingLocalAssets = @($fixture.missing_local_assets)

    try {
      if ($fixture.missing_local_asset_count -gt 0) {
        $missingPreview = ($missingLocalAssets | Select-Object -First 8) -join ", "
        throw "fixture references missing local assets: $missingPreview"
      }

      $browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", $WindowWidth, "--window_height", $WindowHeight, "--screenshot_png", $fixture.screenshot_path, $fixture.url) -WorkingDirectory $repo -PassThru -RedirectStandardOutput $browserOut -RedirectStandardError $browserErr
      $screenshotReady = Wait-ForScreenshot -Path $fixture.screenshot_path -Attempts $WindowReadyAttempts -SleepMs $PollMilliseconds
      if (-not $screenshotReady) {
        throw "screenshot did not become ready"
      }

      $hwnd = Wait-TabWindowHandle -ProcessId $browser.Id -Attempts $WindowReadyAttempts
      if ($hwnd -eq [IntPtr]::Zero) {
        throw "browser window handle not found"
      }

      Show-SmokeWindow $hwnd
      Start-Sleep -Milliseconds $PollMilliseconds
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
      $browserMeta = Stop-OwnedProbeProcess $browser
      Start-Sleep -Milliseconds $PollMilliseconds
      $results += [ordered]@{
        name = $fixture.name
        source_path = $fixture.source_path
        url = $fixture.url
        expected_title = $fixture.expected_title
        window_title = $windowTitle
        screenshot_path = $fixture.screenshot_path
        screenshot_ready = $screenshotReady
        title_matched = $titleMatched
        missing_local_assets = $missingLocalAssets
        missing_local_asset_count = $fixture.missing_local_asset_count
        error = $failure
        browser_meta = $browserMeta
      }
    }
  }
} finally {
  $serverMeta = Stop-OwnedProbeProcess $server
}

$summary = [ordered]@{
  parameter_set = $PSCmdlet.ParameterSetName
  repo_root = $repo
  browser_exe = $browserExe
  host = $Host
  port = $Port
  stage_root = $stageRoot
  output_root = $outputRoot
  server_stdout = $serverOut
  server_stderr = $serverErr
  fixtures = $results
  fixture_count = $results.Count
  fixtures_with_missing_local_assets = @($results | Where-Object { $_.missing_local_asset_count -gt 0 }).Count
  server_meta = $serverMeta
}

$summary | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $resultPath -NoNewline
$summary | ConvertTo-Json -Depth 7

if ($results | Where-Object { -not $_.screenshot_ready -or -not $_.title_matched -or $_.error }) {
  exit 1
}
