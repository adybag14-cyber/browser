[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [switch]$SkipBaseline,
  [switch]$KeepGoing
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

function Resolve-PowerShellCommand {
  if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    return "pwsh"
  }
  if (Get-Command powershell -ErrorAction SilentlyContinue) {
    return "powershell"
  }
  throw "PowerShell executable was not found in PATH."
}

$repo = if ($RepoRoot) { $RepoRoot } else { Resolve-RepoRoot $PSScriptRoot }
$probeRoot = Join-Path $repo "tmp-browser-smoke\form-controls"
$scriptRoot = Join-Path $repo "scripts\windows"
$powerShellExe = Resolve-PowerShellCommand
$surfaceCheck = Join-Path $scriptRoot "check_form_controls_validation_surface.ps1"

$sharedArgs = @()
if ($RepoRoot) { $sharedArgs += @("-RepoRoot", $RepoRoot) }
if ($BrowserExe) { $sharedArgs += @("-BrowserExe", $BrowserExe) }
if ($Host) { $sharedArgs += @("-Host", $Host) }

$steps = @(
  [pscustomobject]@{
    Name = "form-controls-surface"
    Script = $surfaceCheck
    Arguments = @("-RepoRoot", $repo)
  }
)
if (-not $SkipBaseline) {
  $steps += [pscustomobject]@{
    Name = "baseline-enter-submit"
    Script = Join-Path $probeRoot "enter-submit-probe.ps1"
    Arguments = @() + $sharedArgs
  }
}
$steps += [pscustomobject]@{
  Name = "deferred-enter-submit"
  Script = Join-Path $probeRoot "deferred-enter-submit-probe.ps1"
  Arguments = @() + $sharedArgs
}
$steps += [pscustomobject]@{
  Name = "google-title"
  Script = Join-Path $scriptRoot "run_google_home_title_probe.ps1"
  Arguments = @() + $sharedArgs
}
$steps += [pscustomobject]@{
  Name = "reduced-google-home"
  Script = Join-Path $probeRoot "chrome-google-home-enter-submit-probe.ps1"
  Arguments = @() + $sharedArgs
}
$steps += [pscustomobject]@{
  Name = "google-enter-order"
  Script = Join-Path $scriptRoot "run_google_form_controls_enter_order_validation.ps1"
  Arguments = @() + $sharedArgs
}

$results = @()
foreach ($step in $steps) {
  if (-not (Test-Path -LiteralPath $step.Script)) {
    throw "required probe script not found: $($step.Script)"
  }

  $payload = $null
  $errorMessage = $null
  $exitCode = 0
  try {
    $payload = & $powerShellExe -ExecutionPolicy Bypass -File $step.Script @($step.Arguments) 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
  } catch {
    $errorMessage = $_.Exception.Message
  }
  if (-not $errorMessage -and $exitCode -ne 0) {
    $errorMessage = "probe exited with code $exitCode"
  }

  $parsed = $null
  if (-not [string]::IsNullOrWhiteSpace($payload)) {
    try {
      $parsed = $payload | ConvertFrom-Json -ErrorAction Stop
    } catch {
    }
  }

  $results += [pscustomobject]@{
    name = $step.Name
    script = $step.Script
    ok = [string]::IsNullOrWhiteSpace($errorMessage)
    error = $errorMessage
    result = $parsed
  }

  if ($errorMessage -and -not $KeepGoing) {
    break
  }
}

$summary = [ordered]@{
  repo_root = $repo
  browser_exe = $BrowserExe
  host = $Host
  skip_baseline = [bool]$SkipBaseline
  keep_going = [bool]$KeepGoing
  probes = $results
}

$summary | ConvertTo-Json -Depth 8

if ($results.Where({ -not $_.ok }).Count -gt 0) {
  exit 1
}
