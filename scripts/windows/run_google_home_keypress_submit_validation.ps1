[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$ReducedHomeKeypressPort = 8167,
    [string]$InputText = "lightpanda",
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$WindowReadyAttempts = 60,
    [int]$TitleWaitAttempts = 80,
    [int]$PollMilliseconds = 250,
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

$probe = Join-Path $RepoRoot "tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1"
if (-not (Test-Path -LiteralPath $probe -PathType Leaf)) {
    throw "Google home keypress-submit probe not found: $probe"
}

$arguments = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    Port = $ReducedHomeKeypressPort
    InputText = $InputText
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    WindowReadyAttempts = $WindowReadyAttempts
    TitleWaitAttempts = $TitleWaitAttempts
    PollMilliseconds = $PollMilliseconds
}
if ($LeaveOpen) {
    $arguments.LeaveOpen = $true
}

& $probe @arguments
