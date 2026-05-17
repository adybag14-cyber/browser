[CmdletBinding()]
param(
  [string]$RepoRoot,
  [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function New-PortabilityCheck {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$Purpose
  )

  return [pscustomobject]@{
    Path = $Path
    Purpose = $Purpose
  }
}

function New-ContentExpectation {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$Snippet,
    [Parameter(Mandatory = $true)]
    [string]$Purpose
  )

  return [pscustomobject]@{
    Path = $Path
    Snippet = $Snippet
    Purpose = $Purpose
  }
}

$resolvedRepoRoot = if ($RepoRoot) {
  (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
  Resolve-LightpandaRepoRoot $PSScriptRoot
}

$probeChecks = @(
  (New-PortabilityCheck -Path "tmp-browser-smoke/wrapped-link/chrome-history-probe.ps1" -Purpose "Surfaced navigation history probe should stay portable."),
  (New-PortabilityCheck -Path "tmp-browser-smoke/wrapped-link/chrome-reload-probe.ps1" -Purpose "Surfaced navigation reload probe should stay portable."),
  (New-PortabilityCheck -Path "tmp-browser-smoke/stop-loading/chrome-stop-probe.ps1" -Purpose "Surfaced stop-loading recovery probe should stay portable."),
  (New-PortabilityCheck -Path "tmp-browser-smoke/stop-loading/chrome-stop-input-probe.ps1" -Purpose "Surfaced stop-loading restored-input probe should stay portable."),
  (New-PortabilityCheck -Path "tmp-browser-smoke/form-controls/enter-submit-probe.ps1" -Purpose "Surfaced input submit probe should stay portable."),
  (New-PortabilityCheck -Path "tmp-browser-smoke/form-controls/label-click-probe.ps1" -Purpose "Surfaced input label-click probe should stay portable.")
)

$routerExpectations = @(
  (New-ContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet ".\\tmp-browser-smoke\\wrapped-link\\chrome-history-probe.ps1" -Purpose "Router still surfaces the bounded navigation history probe."),
  (New-ContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet ".\\tmp-browser-smoke\\wrapped-link\\chrome-reload-probe.ps1" -Purpose "Router still surfaces the bounded navigation reload probe."),
  (New-ContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet ".\\tmp-browser-smoke\\stop-loading\\chrome-stop-probe.ps1" -Purpose "Router still surfaces the bounded stop-loading recovery probe."),
  (New-ContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet ".\\tmp-browser-smoke\\stop-loading\\chrome-stop-input-probe.ps1" -Purpose "Router still surfaces the bounded stop-loading restored-input probe."),
  (New-ContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet ".\\tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1" -Purpose "Router still surfaces the bounded input submit probe."),
  (New-ContentExpectation -Path "scripts/windows/show_headed_validation_suites.ps1" -Snippet ".\\tmp-browser-smoke\\form-controls\\label-click-probe.ps1" -Purpose "Router still surfaces the bounded input label-click probe.")
)

$contentChecks = @()
$contentCache = @{}

foreach ($probe in $probeChecks) {
  $fullPath = Join-Path $resolvedRepoRoot $probe.Path
  $exists = Test-Path -LiteralPath $fullPath -PathType Leaf

  $contentChecks += [pscustomobject]@{
    CheckType = "reference"
    Path = $probe.Path
    Purpose = $probe.Purpose
    Exists = [bool]$exists
  }

  if (-not $exists) {
    continue
  }

  if (-not $contentCache.ContainsKey($fullPath)) {
    $contentCache[$fullPath] = Get-Content -LiteralPath $fullPath -Raw
  }
  $content = $contentCache[$fullPath]

  $contentChecks += [pscustomobject]@{
    CheckType = "content"
    Path = $probe.Path
    Purpose = "Probe resolves the repo root dynamically."
    Exists = [bool]($content.Contains("Resolve-LightpandaRepoRoot") -or $content.Contains("function Resolve-RepoRoot"))
    Snippet = "Resolve-LightpandaRepoRoot | function Resolve-RepoRoot"
  }

  $contentChecks += [pscustomobject]@{
    CheckType = "content"
    Path = $probe.Path
    Purpose = "Probe resolves the browser executable dynamically."
    Exists = [bool]($content.Contains("Resolve-LightpandaBrowserExe") -or $content.Contains("function Resolve-BrowserExe"))
    Snippet = "Resolve-LightpandaBrowserExe | function Resolve-BrowserExe"
  }

  $contentChecks += [pscustomobject]@{
    CheckType = "content"
    Path = $probe.Path
    Purpose = "Probe no longer hard-codes the original Windows checkout path."
    Exists = [bool](-not $content.Contains("C:\Users\adyba\src\lightpanda-browser"))
    Snippet = "no C:\\Users\\adyba\\src\\lightpanda-browser literal"
  }
}

foreach ($expectation in $routerExpectations) {
  $fullPath = Join-Path $resolvedRepoRoot $expectation.Path
  $exists = Test-Path -LiteralPath $fullPath -PathType Leaf
  if (-not $exists) {
    $contentChecks += [pscustomobject]@{
      CheckType = "content"
      Path = $expectation.Path
      Purpose = $expectation.Purpose
      Exists = $false
      Snippet = $expectation.Snippet
    }
    continue
  }

  if (-not $contentCache.ContainsKey($fullPath)) {
    $contentCache[$fullPath] = Get-Content -LiteralPath $fullPath -Raw
  }

  $contentChecks += [pscustomobject]@{
    CheckType = "content"
    Path = $expectation.Path
    Purpose = $expectation.Purpose
    Exists = [bool]$contentCache[$fullPath].Contains($expectation.Snippet)
    Snippet = $expectation.Snippet
  }
}

$missing = @($contentChecks | Where-Object { -not $_.Exists })

if ($Json) {
  [ordered]@{
    profile = "headed-validation-probe-portability"
    repo_root = $resolvedRepoRoot
    checked_count = @($contentChecks).Count
    missing_count = @($missing).Count
    checks = @($contentChecks)
  } | ConvertTo-Json -Depth 6

  if ($missing.Count -gt 0) {
    exit 1
  }

  exit 0
}

Write-Host "Headed validation probe portability check"
Write-Host ""
Write-Host ((("Repo root: {0}") -f $resolvedRepoRoot))
Write-Host ""

foreach ($check in $contentChecks) {
  $status = if ($check.Exists) { "PASS" } else { "FAIL" }
  Write-Host ((("[{0}] {1}") -f $status, $check.Path))
  Write-Host ((("  {0}") -f $check.Purpose))
}

Write-Host ""
if ($missing.Count -eq 0) {
  Write-Host "Surfaced headed validation probes remain portable."
  exit 0
}

Write-Host ((("Missing {0} headed validation portability check(s).") -f $missing.Count))
Write-Host "Repair the surfaced probe runtime helpers or router mappings before trusting the bounded Windows headed validation entrypoints."
exit 1