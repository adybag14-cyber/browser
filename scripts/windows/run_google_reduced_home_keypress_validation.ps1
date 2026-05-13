[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$ReducedHomeKeypressPort = 8167,
    [string]$SharedInputText = "Q",
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 60,
    [int]$HomeTitleWaitAttempts = 80,
    [int]$HomePollMilliseconds = 250,
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

$surfaceCheck = Join-Path $PSScriptRoot "check_google_reduced_home_keypress_validation_surface.ps1"
$runner = Join-Path $RepoRoot "tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1"
if (-not (Test-Path -LiteralPath $surfaceCheck -PathType Leaf)) {
    throw "Google reduced-home keypress validation surface checker not found: $surfaceCheck"
}
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw "Reduced-home keypress probe not found: $runner"
}

$surfaceCheckArgs = @{
    RepoRoot = $RepoRoot
}

$arguments = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    Port = $ReducedHomeKeypressPort
    InputText = $SharedInputText
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    WindowReadyAttempts = $HomeWindowReadyAttempts
    TitleWaitAttempts = $HomeTitleWaitAttempts
    PollMilliseconds = $HomePollMilliseconds
}
if ($LeaveOpen) {
    $arguments.LeaveOpen = $true
}

Write-Host "Google reduced-home keypress validation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Host: {0}" -f $Host)
Write-Host ("Shared input text: {0}" -f $SharedInputText)
Write-Host ("Reduced-home keypress port: {0}" -f $ReducedHomeKeypressPort)
Write-Host ""
Write-Host "=== google-reduced-home-keypress-surface ==="
Write-Host ("Script: {0}" -f $surfaceCheck)
& $surfaceCheck @surfaceCheckArgs

Write-Host ""
Write-Host "=== google-reduced-home-keypress ==="
Write-Host ("Script: {0}" -f $runner)
& $runner @arguments
