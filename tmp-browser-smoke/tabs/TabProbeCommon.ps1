[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\ProbeRuntime.ps1")
. (Join-Path (Split-Path $PSScriptRoot -Parent) "common\Win32Input.ps1")

function Resolve-TabProbeConfig {
  param(
    [Parameter(Mandatory = $true)]
    [string]$StartPath,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$ProfileName = ""
  )

  $resolvedRepoRoot = if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    Resolve-LightpandaRepoRoot $StartPath
  } else {
    $RepoRoot
  }
  $smokeRoot = Join-Path $resolvedRepoRoot "tmp-browser-smoke\tabs"

  return @{
    RepoRoot = $resolvedRepoRoot
    SmokeRoot = $smokeRoot
    BrowserExe = Resolve-LightpandaBrowserExe $resolvedRepoRoot $BrowserExe
    ProfileRoot = if ([string]::IsNullOrWhiteSpace($ProfileName)) { $null } else { Join-Path $smokeRoot $ProfileName }
  }
}

function Reset-TabProbeProfile([string]$ProfileRoot) {
  if ([string]::IsNullOrWhiteSpace($ProfileRoot)) {
    return
  }

  if (Test-Path -LiteralPath $ProfileRoot) {
    Remove-Item -LiteralPath $ProfileRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
  New-Item -ItemType Directory -Force -Path $ProfileRoot | Out-Null
}

function Set-TabProbeProfileEnvironment([string]$ProfileRoot) {
  if ([string]::IsNullOrWhiteSpace($ProfileRoot)) {
    return
  }

  $env:APPDATA = $ProfileRoot
  $env:LOCALAPPDATA = $ProfileRoot
}

function Wait-TabWindowHandle([int]$ProcessId, [int]$Attempts = 60, [int]$PollMilliseconds = 250) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $hwnd = Get-TabWindowHandle $ProcessId
    if ($hwnd -ne [IntPtr]::Zero) {
      return $hwnd
    }
  }
  return [IntPtr]::Zero
}

function Get-TabWindowHandle([int]$ProcessId) {
  $proc = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
  if ($proc -and $proc.MainWindowHandle -ne 0) {
    return [IntPtr]$proc.MainWindowHandle
  }
  return [IntPtr]::Zero
}

function Wait-TabTitle([int]$ProcessId, [string]$Needle, [int]$Attempts = 40, [int]$PollMilliseconds = 250) {
  for ($i = 0; $i -lt $Attempts; $i++) {
    Start-Sleep -Milliseconds $PollMilliseconds
    $proc = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if (-not $proc -or $proc.MainWindowHandle -eq 0) { continue }
    $title = Get-SmokeWindowTitle ([IntPtr]$proc.MainWindowHandle)
    if ($title -like "*$Needle*") {
      return $title
    }
  }
  return $null
}

function Get-TabClientPoint([int]$TabIndex, [int]$TabCount = 2, [switch]$Close, [switch]$New) {
  $clientWidth = 960
  $presentationMargin = 12
  $findWidth = 300
  $tabGap = 4
  $tabNewWidth = 22
  $tabMaxWidth = 180
  $findLeft = [Math]::Max($presentationMargin + 120, ($clientWidth - $presentationMargin) - $findWidth)
  $tabNewRight = $findLeft - $tabGap
  $tabNewLeft = [Math]::Max($presentationMargin, $tabNewRight - $tabNewWidth)
  if ($New) {
    return @{
      X = $tabNewLeft + 10
      Y = 14
    }
  }

  $gaps = ([Math]::Max($TabCount, 1) - 1) * $tabGap
  $availableRight = $tabNewLeft - $tabGap
  $availableWidth = [Math]::Max(1, $availableRight - $presentationMargin - $gaps)
  $tabWidth = [Math]::Max(1, [Math]::Min($tabMaxWidth, [int][Math]::Truncate($availableWidth / [Math]::Max($TabCount, 1))))
  $left = $presentationMargin + ($TabIndex * ($tabWidth + $tabGap))
  if ($Close) {
    return @{
      X = $left + $tabWidth - 13
      Y = 14
    }
  }
  return @{
    X = $left + [int][Math]::Max(8, [Math]::Min(36, [Math]::Floor($tabWidth / 2)))
    Y = 14
  }
}

function Stop-OwnedProbeProcess([System.Diagnostics.Process]$Process) {
  return Stop-LightpandaOwnedProbeProcess $Process
}
