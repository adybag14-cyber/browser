[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$SharedInputText = "Q",
    [string]$SubmitTimingInputText = "QZ",
    [string]$EnterMutationSuffix = "!",
    [int]$HomepageFixturePort = 8155,
    [int]$SubmitTimingPort = 8181,
    [int]$SharedEnterOrderPort = 8157,
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

$homepageFixtureRunner = Join-Path $PSScriptRoot "run_google_homepage_fixture_validation.ps1"
$submitTimingRunner = Join-Path $PSScriptRoot "run_google_submit_timing_validation.ps1"
$sharedEnterOrderRunner = Join-Path $PSScriptRoot "run_google_shared_enter_order_validation.ps1"

if (-not (Test-Path -LiteralPath $homepageFixtureRunner -PathType Leaf)) {
    throw "Google homepage fixture validation runner not found: $homepageFixtureRunner"
}
if (-not (Test-Path -LiteralPath $submitTimingRunner -PathType Leaf)) {
    throw "Google submit-timing validation runner not found: $submitTimingRunner"
}
if (-not (Test-Path -LiteralPath $sharedEnterOrderRunner -PathType Leaf)) {
    throw "Google shared Enter-order validation runner not found: $sharedEnterOrderRunner"
}

$homepageFixtureArgs = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    FixturePort = $HomepageFixturePort
    InputText = $SharedInputText
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    HomeWindowReadyAttempts = $HomeWindowReadyAttempts
    HomeTitleWaitAttempts = $HomeTitleWaitAttempts
    HomePollMilliseconds = $HomePollMilliseconds
}
if ($LeaveOpen) {
    $homepageFixtureArgs.LeaveOpen = $true
}

$submitTimingArgs = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    SubmitTimingPort = $SubmitTimingPort
    InputText = $SubmitTimingInputText
}

$sharedEnterOrderArgs = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    SharedInputText = $SharedInputText
    EnterMutationSuffix = $EnterMutationSuffix
    SharedEnterOrderPort = $SharedEnterOrderPort
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    HomeWindowReadyAttempts = $HomeWindowReadyAttempts
    HomeTitleWaitAttempts = $HomeTitleWaitAttempts
    HomePollMilliseconds = $HomePollMilliseconds
}

Write-Host "Google issue #3 submit-path validation"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Host: {0}" -f $Host)
Write-Host ("Shared input text: {0}" -f $SharedInputText)
Write-Host ("Submit-timing input text: {0}" -f $SubmitTimingInputText)
Write-Host ("Homepage fixture port: {0}" -f $HomepageFixturePort)
Write-Host ("Submit-timing port: {0}" -f $SubmitTimingPort)
Write-Host ("Shared Enter-order port: {0}" -f $SharedEnterOrderPort)
Write-Host ""
Write-Host "This runner is for the stage after the bounded localhost title gates are already green."
Write-Host "It keeps the issue #3 focus on the real submit path: saved homepage fixture, submit timing, and shared Enter-order."
Write-Host ""

Write-Host "=== google-homepage-fixture ==="
Write-Host ("Script: {0}" -f $homepageFixtureRunner)
& $homepageFixtureRunner @homepageFixtureArgs

Write-Host ""
Write-Host "=== google-submit-timing ==="
Write-Host ("Script: {0}" -f $submitTimingRunner)
& $submitTimingRunner @submitTimingArgs

Write-Host ""
Write-Host "=== google-shared-enter-order ==="
Write-Host ("Script: {0}" -f $sharedEnterOrderRunner)
& $sharedEnterOrderRunner @sharedEnterOrderArgs

Write-Host ""
Write-Host "Next: if the saved homepage fixture, submit-timing, and shared Enter-order slices stay green together, move on to the smallest live Google manual pass or trace capture."
