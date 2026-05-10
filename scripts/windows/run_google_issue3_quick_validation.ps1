[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$TitlePort = 9582,
    [int]$WatchPort = 9582,
    [string]$InputText = "QZ",
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$WatchTimeoutSeconds = 90,
    [int]$WatchPollMilliseconds = 250,
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

$runner = Join-Path $PSScriptRoot "run_google_input_validation.ps1"
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw "Google input validation runner not found: $runner"
}

$arguments = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Phase = "quick"
    Host = $Host
    TitlePort = $TitlePort
    WatchPort = $WatchPort
    InputText = $InputText
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    WatchTimeoutSeconds = $WatchTimeoutSeconds
    WatchPollMilliseconds = $WatchPollMilliseconds
}

if ($LeaveOpen) {
    $arguments.LeaveOpen = $true
}

& $runner @arguments
