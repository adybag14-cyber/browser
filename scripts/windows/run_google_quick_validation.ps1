[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$InputText = "QZ",
    [int]$TitlePort = 9582,
    [int]$WatchPort = 9582,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 60,
    [int]$HomeTitleWaitAttempts = 80,
    [int]$HomePollMilliseconds = 250,
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

$surfaceCheck = Join-Path $PSScriptRoot "check_google_quick_validation_surface.ps1"
$runner = Join-Path $PSScriptRoot "run_google_input_validation.ps1"
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw "Google input validation runner not found: $runner"
}
if (-not (Test-Path -LiteralPath $surfaceCheck -PathType Leaf)) {
    throw "Google quick validation surface checker not found: $surfaceCheck"
}

Write-Host "Google quick validation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ""
Write-Host "=== google-quick-surface ==="
Write-Host ("Script: {0}" -f $surfaceCheck)
& $surfaceCheck -RepoRoot $RepoRoot
Write-Host ""

$arguments = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Phase = "quick"
    Host = $Host
    InputText = $InputText
    TitlePort = $TitlePort
    WatchPort = $WatchPort
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    HomeWindowReadyAttempts = $HomeWindowReadyAttempts
    HomeTitleWaitAttempts = $HomeTitleWaitAttempts
    HomePollMilliseconds = $HomePollMilliseconds
    WatchTimeoutSeconds = $WatchTimeoutSeconds
    WatchPollMilliseconds = $WatchPollMilliseconds
}
if ($LeaveOpen) {
    $arguments.LeaveOpen = $true
}

& $runner @arguments
