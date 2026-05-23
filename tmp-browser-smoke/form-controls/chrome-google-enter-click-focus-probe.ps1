[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$BrowserExe,
  [string]$Host = "127.0.0.1",
  [int]$Port = 8154,
  [string]$InputText = "lightpanda",
  [int]$ServerReadyTimeoutSeconds = 15,
  [int]$WindowReadyAttempts = 60,
  [int]$TitleWaitAttempts = 80,
  [int]$PollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$sharedProbe = Join-Path $PSScriptRoot "enter-submit-probe.ps1"
if (-not (Test-Path -LiteralPath $sharedProbe)) {
  throw "shared enter-submit probe not found: $sharedProbe"
}

$invokeArgs = @{
  GoogleEnterOrder = $true
  ClickFocus = $true
  Host = $Host
  Port = $Port
  InputText = $InputText
  ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
  WindowReadyAttempts = $WindowReadyAttempts
  TitleWaitAttempts = $TitleWaitAttempts
  PollMilliseconds = $PollMilliseconds
}
if ($PSBoundParameters.ContainsKey('RepoRoot')) { $invokeArgs.RepoRoot = $RepoRoot }
if ($PSBoundParameters.ContainsKey('BrowserExe')) { $invokeArgs.BrowserExe = $BrowserExe }

& $sharedProbe @invokeArgs
exit $LASTEXITCODE
