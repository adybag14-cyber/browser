[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$LocalhostPort = 8176,
    [string]$InputText = "QZ",
    [string]$SharedInputText = "Q",
    [string]$TraceInputText = "lightpanda",
    [int]$TitlePort = 9582,
    [int]$HomePort = 8168,
    [int]$WatchPort = 9582,
    [int]$SharedLabelPort = 8153,
    [int]$SharedDefaultPort = 8154,
    [int]$SharedDeferredPort = 8155,
    [int]$InlineFlowPort = 8148,
    [int]$SharedReducedGooglePort = 8156,
    [int]$SharedEnterOrderPort = 8157,
    [int]$SubmitTimingPort = 8181,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 60,
    [int]$HomeTitleWaitAttempts = 80,
    [int]$HomePollMilliseconds = 250,
    [int]$TraceWindowReadyAttempts = 80,
    [int]$TracePollMilliseconds = 250,
    [int]$WatchTimeoutSeconds = 90,
    [int]$WatchPollMilliseconds = 250,
    [string]$PageRoot,
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
    [int]$ManualPort = 8123,
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

if ($PageRoot -and $InputPath -and $InputPath.Count -gt 0) {
    throw "provide either PageRoot or InputPath, not both"
}
if (-not $PageRoot -and (-not $InputPath -or $InputPath.Count -eq 0)) {
    throw "either PageRoot or InputPath is required"
}

$summaryHelper = Join-Path $PSScriptRoot "summarize_localhost_html_pages.ps1"
$runner = Join-Path $PSScriptRoot "run_google_input_validation.ps1"
foreach ($requiredScript in @($summaryHelper, $runner)) {
    if (-not (Test-Path -LiteralPath $requiredScript -PathType Leaf)) {
        throw "required script not found: $requiredScript"
    }
}

$manualInputPath = if ($InputPath -and $InputPath.Count -gt 0) {
    @($InputPath)
} else {
    @($PageRoot)
}

$summaryArgs = @{
    RepoRoot = $RepoRoot
    Port = $ManualPort
}
if ($InputPath -and $InputPath.Count -gt 0) {
    $summaryArgs.InputPath = $InputPath
} else {
    $summaryArgs.PageRoot = $PageRoot
}
if ($PreferredInitialPage) {
    $summaryArgs.PreferredInitialPage = $PreferredInitialPage
}

Write-Host ""
Write-Host "=== saved-page-summary ==="
& $summaryHelper @summaryArgs

$runnerArgs = @{
    RepoRoot = $RepoRoot
    BrowserExe = $BrowserExe
    Phase = "all"
    IncludeTitleProbe = $true
    IncludeSharedEnterOrder = $true
    IncludeWatch = $true
    Host = $Host
    LocalhostPort = $LocalhostPort
    InputText = $InputText
    SharedInputText = $SharedInputText
    TraceInputText = $TraceInputText
    TitlePort = $TitlePort
    HomePort = $HomePort
    WatchPort = $WatchPort
    SharedLabelPort = $SharedLabelPort
    SharedDefaultPort = $SharedDefaultPort
    SharedDeferredPort = $SharedDeferredPort
    InlineFlowPort = $InlineFlowPort
    SharedReducedGooglePort = $SharedReducedGooglePort
    SharedEnterOrderPort = $SharedEnterOrderPort
    SubmitTimingPort = $SubmitTimingPort
    ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    HomeWindowReadyAttempts = $HomeWindowReadyAttempts
    HomeTitleWaitAttempts = $HomeTitleWaitAttempts
    HomePollMilliseconds = $HomePollMilliseconds
    TraceWindowReadyAttempts = $TraceWindowReadyAttempts
    TracePollMilliseconds = $TracePollMilliseconds
    WatchTimeoutSeconds = $WatchTimeoutSeconds
    WatchPollMilliseconds = $WatchPollMilliseconds
    ManualPort = $ManualPort
    ManualInputPath = $manualInputPath
}
if ($PreferredInitialPage) {
    $runnerArgs.ManualInitialPage = $PreferredInitialPage
}
if ($LeaveOpen) {
    $runnerArgs.LeaveOpen = $true
}

& $runner @runnerArgs
