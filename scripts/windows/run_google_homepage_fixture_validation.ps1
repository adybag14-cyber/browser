[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$FixturePort = 8155,
    [string]$InputText = "Q",
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

$surfaceCheck = Join-Path $PSScriptRoot "check_google_homepage_fixture_validation_surface.ps1"
if (-not (Test-Path -LiteralPath $surfaceCheck -PathType Leaf)) {
    throw "Google homepage fixture validation surface checker not found: $surfaceCheck"
}

Write-Host "Google homepage-fixture validation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ""
Write-Host "=== google-homepage-fixture-surface ==="
Write-Host ("Script: {0}" -f $surfaceCheck)
& $surfaceCheck -RepoRoot $RepoRoot
Write-Host ""

$probe = Join-Path $RepoRoot "tmp-browser-smoke\form-controls\chrome-google-homepage-probe.ps1"
if (-not (Test-Path -LiteralPath $probe -PathType Leaf)) {
    throw "Saved Google homepage fixture probe not found: $probe"
}

$arguments = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    Port = $FixturePort
    InputText = $InputText
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    HomeWindowReadyAttempts = $HomeWindowReadyAttempts
    HomeTitleWaitAttempts = $HomeTitleWaitAttempts
    HomePollMilliseconds = $HomePollMilliseconds
}
if ($LeaveOpen) {
    $arguments.LeaveOpen = $true
}

& $probe @arguments
