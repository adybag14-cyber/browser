[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8180,
    [string]$InputText = "Q",
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$WindowReadyAttempts = 60,
    [int]$TitleWaitAttempts = 40,
    [int]$PollMilliseconds = 200
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

$probe = Join-Path $RepoRoot "tmp-browser-smoke\layout-smoke\chrome-layout-legacy-table-enter-probe.ps1"
if (-not (Test-Path -LiteralPath $probe -PathType Leaf)) {
    throw "Legacy-table headed probe not found: $probe"
}

$arguments = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    Port = $Port
    InputText = $InputText
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    WindowReadyAttempts = $WindowReadyAttempts
    TitleWaitAttempts = $TitleWaitAttempts
    PollMilliseconds = $PollMilliseconds
}

& $probe @arguments
