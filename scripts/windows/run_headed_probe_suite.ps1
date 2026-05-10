$ErrorActionPreference = "Stop"

param(
  [string[]]$Suite,
  [string[]]$Probe,
  [switch]$List,
  [switch]$ContinueOnError,
  [switch]$PassThru
)

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$suitePatterns = [ordered]@{
  "browser-shell" = @(
    "tmp-browser-smoke\tabs\*probe.ps1",
    "tmp-browser-smoke\browser-pages\*probe.ps1",
    "tmp-browser-smoke\settings\*probe.ps1",
    "tmp-browser-smoke\wrapped-link\*probe.ps1",
    "tmp-browser-smoke\popup\*probe.ps1"
  )
  "phase1-rendering" = @(
    "tmp-browser-smoke\layout-smoke\*probe.ps1",
    "tmp-browser-smoke\inline-flow\*probe.ps1",
    "tmp-browser-smoke\flow-layout\*probe.ps1",
    "tmp-browser-smoke\rendered-link-dom\*probe.ps1",
    "tmp-browser-smoke\image-smoke\*probe.ps1",
    "tmp-browser-smoke\font-render\*probe.ps1"
  )
  "phase2-text-input" = @(
    "tmp-browser-smoke\form-controls\*probe.ps1",
    "tmp-browser-smoke\font-smoke\*probe.ps1",
    "tmp-browser-smoke\font-render\*probe.ps1",
    "tmp-browser-smoke\find\*probe.ps1",
    "tmp-browser-smoke\zoom\*probe.ps1"
  )
  "files-and-downloads" = @(
    "tmp-browser-smoke\file-upload\*probe.ps1",
    "tmp-browser-smoke\downloads\*probe.ps1",
    "tmp-browser-smoke\attachment-downloads\*probe.ps1"
  )
  "storage-and-session" = @(
    "tmp-browser-smoke\cookie-persistence\*probe.ps1",
    "tmp-browser-smoke\localstorage-persistence\*probe.ps1",
    "tmp-browser-smoke\indexeddb-persistence\*probe.ps1",
    "tmp-browser-smoke\sessionstorage-scope\*probe.ps1"
  )
  "network-runtime" = @(
    "tmp-browser-smoke\fetch-abort\*probe.ps1",
    "tmp-browser-smoke\fetch-credentials\*probe.ps1",
    "tmp-browser-smoke\websocket-smoke\*probe.ps1",
    "tmp-browser-smoke\stylesheet-smoke\*probe.ps1"
  )
  "graphics" = @(
    "tmp-browser-smoke\canvas-smoke\*probe.ps1"
  )
  "release-gates" = @(
    "tmp-browser-smoke\tabs\*probe.ps1",
    "tmp-browser-smoke\browser-pages\*probe.ps1",
    "tmp-browser-smoke\settings\*probe.ps1",
    "tmp-browser-smoke\wrapped-link\*probe.ps1",
    "tmp-browser-smoke\popup\*probe.ps1",
    "tmp-browser-smoke\layout-smoke\*probe.ps1",
    "tmp-browser-smoke\inline-flow\*probe.ps1",
    "tmp-browser-smoke\flow-layout\*probe.ps1",
    "tmp-browser-smoke\rendered-link-dom\*probe.ps1",
    "tmp-browser-smoke\image-smoke\*probe.ps1",
    "tmp-browser-smoke\font-render\*probe.ps1",
    "tmp-browser-smoke\form-controls\*probe.ps1",
    "tmp-browser-smoke\font-smoke\*probe.ps1",
    "tmp-browser-smoke\find\*probe.ps1",
    "tmp-browser-smoke\zoom\*probe.ps1",
    "tmp-browser-smoke\file-upload\*probe.ps1",
    "tmp-browser-smoke\downloads\*probe.ps1",
    "tmp-browser-smoke\attachment-downloads\*probe.ps1",
    "tmp-browser-smoke\cookie-persistence\*probe.ps1",
    "tmp-browser-smoke\localstorage-persistence\*probe.ps1",
    "tmp-browser-smoke\indexeddb-persistence\*probe.ps1",
    "tmp-browser-smoke\sessionstorage-scope\*probe.ps1",
    "tmp-browser-smoke\fetch-abort\*probe.ps1",
    "tmp-browser-smoke\fetch-credentials\*probe.ps1",
    "tmp-browser-smoke\websocket-smoke\*probe.ps1",
    "tmp-browser-smoke\stylesheet-smoke\*probe.ps1",
    "tmp-browser-smoke\canvas-smoke\*probe.ps1"
  )
  "bare-metal-release" = @(
    "tmp-browser-smoke\bare-metal-release\*probe.ps1"
  )
}

if ($List -or ((-not $Suite -or $Suite.Count -eq 0) -and (-not $Probe -or $Probe.Count -eq 0))) {
  [pscustomobject]@{
    repo_root = $repoRoot
    suites = @($suitePatterns.Keys)
  } | ConvertTo-Json -Depth 4
  return
}

function Resolve-ProbePatterns {
  param(
    [string[]]$Names,
    [string[]]$ExtraPatterns
  )

  $patterns = [System.Collections.Generic.List[string]]::new()
  foreach ($name in $Names) {
    if (-not $suitePatterns.ContainsKey($name)) {
      throw "Unknown suite '$name'. Use -List to inspect supported suite names."
    }
    foreach ($pattern in $suitePatterns[$name]) {
      [void]$patterns.Add($pattern)
    }
  }
  foreach ($pattern in $ExtraPatterns) {
    [void]$patterns.Add($pattern)
  }
  return ,$patterns
}

function Resolve-ProbeFiles {
  param([string[]]$Patterns)

  $resolved = [ordered]@{}
  foreach ($pattern in $Patterns) {
    $fullPattern = Join-Path $repoRoot $pattern
    $matches = @(Get-ChildItem -Path $fullPattern -File -ErrorAction SilentlyContinue | Sort-Object FullName)
    foreach ($match in $matches) {
      if (-not $resolved.ContainsKey($match.FullName)) {
        $resolved[$match.FullName] = [pscustomobject]@{
          path = $match.FullName
          relative_path = $match.FullName.Substring($repoRoot.Length + 1)
        }
      }
    }
  }
  return ,@($resolved.Values)
}

$patterns = Resolve-ProbePatterns -Names $Suite -ExtraPatterns $Probe
$probeFiles = Resolve-ProbeFiles -Patterns $patterns
if ($probeFiles.Count -eq 0) {
  throw "No probe scripts matched the requested suites/patterns."
}

$results = [System.Collections.Generic.List[object]]::new()
$hadFailure = $false

foreach ($probeFile in $probeFiles) {
  Write-Host ("==> " + $probeFile.relative_path)
  $started = Get-Date
  $outputLines = [System.Collections.Generic.List[string]]::new()
  $exitCode = 0

  try {
    & powershell -ExecutionPolicy Bypass -File $probeFile.path 2>&1 |
      ForEach-Object {
        $line = [string]$_
        [void]$outputLines.Add($line)
        Write-Host $line
      }
    if ($LASTEXITCODE) {
      $exitCode = $LASTEXITCODE
    }
  } catch {
    $exitCode = 1
    [void]$outputLines.Add($_.Exception.Message)
    Write-Host $_.Exception.Message
  }

  $durationMs = [int]((Get-Date) - $started).TotalMilliseconds
  $result = [pscustomobject]@{
    probe = $probeFile.relative_path
    exit_code = $exitCode
    duration_ms = $durationMs
    passed = ($exitCode -eq 0)
    output = @($outputLines)
  }
  [void]$results.Add($result)

  if ($exitCode -ne 0) {
    $hadFailure = $true
    if (-not $ContinueOnError) {
      break
    }
  }
}

if ($PassThru) {
  [pscustomobject]@{
    repo_root = $repoRoot
    requested_suites = @($Suite)
    requested_patterns = @($Probe)
    probe_count = $probeFiles.Count
    passed = (-not $hadFailure)
    results = @($results)
  } | ConvertTo-Json -Depth 6
}

if ($hadFailure) {
  exit 1
}
