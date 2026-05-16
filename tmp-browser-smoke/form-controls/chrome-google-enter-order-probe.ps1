[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8157,
  [string]$InputText = "Q",
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$TitleWaitAttempts = 80,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$canonicalProbe = Join-Path $PSScriptRoot "google-enter-order-probe.ps1"
if (-not (Test-Path -LiteralPath $canonicalProbe -PathType Leaf)) {
  throw "Canonical Google Enter-order probe not found: $canonicalProbe"
}

& $canonicalProbe @PSBoundParameters
exit $LASTEXITCODE
