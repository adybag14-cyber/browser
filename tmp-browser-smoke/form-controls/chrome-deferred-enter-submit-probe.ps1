[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8155,
  [string]$InputText = "Q",
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$TitleWaitAttempts = 80,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$canonicalProbe = Join-Path $PSScriptRoot "deferred-enter-submit-probe.ps1"
if (-not (Test-Path -LiteralPath $canonicalProbe -PathType Leaf)) {
  throw "Canonical deferred Enter-submit probe wrapper not found: $canonicalProbe"
}

& $canonicalProbe @PSBoundParameters
exit $LASTEXITCODE
