[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$SharedInputText = "Q",
    [string]$SubmitTimingInputText = "QZ",
    [string]$EnterMutationSuffix = "!",
    [int]$HomepageFixturePort = 8155,
    [int]$ReducedEnterTracePort = 8164,
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

$artifactRoot = Join-Path $RepoRoot "tmp-browser-smoke\headed-probe"
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
$reducedEnterTraceArtifactPath = Join-Path $artifactRoot "google-enter-trace-analysis.json"
$submitPathSurfaceCheck = Join-Path $PSScriptRoot "check_google_submit_path_validation_surface.ps1"
$submitPathTraceGuide = Join-Path $PSScriptRoot "show_google_submit_path_trace_guide.ps1"
$homepageFixtureRunner = Join-Path $PSScriptRoot "run_google_homepage_fixture_validation.ps1"
$submitTimingRunner = Join-Path $PSScriptRoot "run_google_submit_timing_validation.ps1"
$sharedEnterOrderRunner = Join-Path $PSScriptRoot "run_google_shared_enter_order_validation.ps1"
$reducedEnterTraceAnalyzer = Join-Path $RepoRoot "tmp-browser-smoke\google-investigation-next\analyze-google-enter-trace.ps1"

if (-not (Test-Path -LiteralPath $submitPathSurfaceCheck -PathType Leaf)) {
    throw "Google submit-path validation surface checker not found: $submitPathSurfaceCheck"
}
if (-not (Test-Path -LiteralPath $submitPathTraceGuide -PathType Leaf)) {
    throw "Google submit-path trace guide not found: $submitPathTraceGuide"
}
if (-not (Test-Path -LiteralPath $homepageFixtureRunner -PathType Leaf)) {
    throw "Google homepage fixture validation runner not found: $homepageFixtureRunner"
}
if (-not (Test-Path -LiteralPath $submitTimingRunner -PathType Leaf)) {
    throw "Google submit-timing validation runner not found: $submitTimingRunner"
}
if (-not (Test-Path -LiteralPath $sharedEnterOrderRunner -PathType Leaf)) {
    throw "Google shared Enter-order validation runner not found: $sharedEnterOrderRunner"
}
if (-not (Test-Path -LiteralPath $reducedEnterTraceAnalyzer -PathType Leaf)) {
    throw "Reduced Google Enter-trace analyzer not found: $reducedEnterTraceAnalyzer"
}

$submitPathSurfaceCheckArgs = @{
    RepoRoot = $RepoRoot
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

$reducedEnterTraceArgs = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Host = $Host
    Port = $ReducedEnterTracePort
    InputText = $SubmitTimingInputText
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    WindowReadyAttempts = $HomeWindowReadyAttempts
    TitleWaitAttempts = $HomeTitleWaitAttempts
    PollMilliseconds = $HomePollMilliseconds
    OutputPath = $reducedEnterTraceArtifactPath
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
Write-Host ("Reduced Enter-trace port: {0}" -f $ReducedEnterTracePort)
Write-Host ("Submit-timing port: {0}" -f $SubmitTimingPort)
Write-Host ("Shared Enter-order port: {0}" -f $SharedEnterOrderPort)
Write-Host ("Reduced Enter analysis JSON: {0}" -f $reducedEnterTraceArtifactPath)
Write-Host ""
Write-Host "This runner is for the stage after the bounded localhost title gates are already green."
Write-Host "It keeps the issue #3 focus on the real submit path: saved homepage fixture, reduced Enter-trace diagnosis, submit timing, and shared Enter-order."
Write-Host ("If one bounded step fails, use the read-first trace guide at {0} before widening back out." -f $submitPathTraceGuide)
Write-Host ""

Write-Host "=== google-submit-path-surface ==="
Write-Host ("Script: {0}" -f $submitPathSurfaceCheck)
& $submitPathSurfaceCheck @submitPathSurfaceCheckArgs

Write-Host ""
Write-Host "=== google-homepage-fixture ==="
Write-Host ("Script: {0}" -f $homepageFixtureRunner)
& $homepageFixtureRunner @homepageFixtureArgs

Write-Host ""
Write-Host "=== google-reduced-enter-trace-analysis ==="
Write-Host ("Script: {0}" -f $reducedEnterTraceAnalyzer)
if (Test-Path -LiteralPath $reducedEnterTraceArtifactPath) {
    Remove-Item -LiteralPath $reducedEnterTraceArtifactPath -Force
}
$null = & $reducedEnterTraceAnalyzer @reducedEnterTraceArgs
if (-not (Test-Path -LiteralPath $reducedEnterTraceArtifactPath -PathType Leaf)) {
    throw "Reduced Google Enter-trace analysis did not save its JSON artifact: $reducedEnterTraceArtifactPath"
}
try {
    $reducedEnterTraceRecord = Get-Content -LiteralPath $reducedEnterTraceArtifactPath -Raw | ConvertFrom-Json
} catch {
    throw "Reduced Google Enter-trace analysis returned non-JSON output. Artifact: $reducedEnterTraceArtifactPath"
}
Write-Host ("Analysis JSON: {0}" -f $reducedEnterTraceArtifactPath)
Write-Host ("Classification: {0}" -f $reducedEnterTraceRecord.classification)
if ($reducedEnterTraceRecord.failure_stage) {
    Write-Host ("Failure stage: {0}" -f $reducedEnterTraceRecord.failure_stage)
}
if ($reducedEnterTraceRecord.recommendation) {
    Write-Host ("Recommendation: {0}" -f $reducedEnterTraceRecord.recommendation)
}

Write-Host ""
Write-Host "=== google-submit-timing ==="
Write-Host ("Script: {0}" -f $submitTimingRunner)
& $submitTimingRunner @submitTimingArgs

Write-Host ""
Write-Host "=== google-shared-enter-order ==="
Write-Host ("Script: {0}" -f $sharedEnterOrderRunner)
& $sharedEnterOrderRunner @sharedEnterOrderArgs

Write-Host ""
Write-Host ("Next: open {0} first when the saved homepage fixture is green but later timing still feels ambiguous. If the saved homepage fixture, reduced Enter-trace analysis, submit-timing, and shared Enter-order slices stay green together, move on to the smallest live Google manual pass or trace capture. If they diverge, print {1} before the next rerun." -f $reducedEnterTraceArtifactPath, $submitPathTraceGuide)
