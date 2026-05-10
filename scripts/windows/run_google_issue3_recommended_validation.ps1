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
    [string[]]$ManualInputPath,
    [string]$ManualInitialPage,
    [int]$ManualPort = 8123,
    [switch]$ManualGoogleStyle,
    [switch]$LeaveOpen,
    [switch]$SkipAutoAttachedHtml
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

function Test-GoogleStyleAttachedHtmlAvailable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot)
    if ($searchRoots.Count -eq 0) {
        return $false
    }

    $googleFixture = Get-AttachedHtmlCandidates -RepoRoot $RepoRoot |
        Where-Object { Test-GoogleStyleFixture $_ } |
        Select-Object -First 1

    return [bool]$googleFixture
}

function Resolve-GoogleStyleAttachedHtmlSelection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $resolvedInputPath = @(Get-DefaultAttachedHtmlInputPath -RepoRoot $RepoRoot -GoogleStyle)
    if ($resolvedInputPath.Count -eq 0) {
        return $null
    }

    $resolvedInitialPage = Select-GoogleStyleInitialPage -ResolvedInputPath $resolvedInputPath
    return [ordered]@{
        InputPath = $resolvedInputPath
        InitialPage = $resolvedInitialPage
    }
}

$runner = Join-Path $PSScriptRoot "run_google_input_validation.ps1"
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw "Google input validation runner not found: $runner"
}

$autoAttachedHtml = $false
$autoAttachedSelection = $null
if (-not $SkipAutoAttachedHtml -and -not $ManualGoogleStyle -and -not ($ManualInputPath -and $ManualInputPath.Count -gt 0)) {
    $autoAttachedHtml = Test-GoogleStyleAttachedHtmlAvailable -RepoRoot $RepoRoot
    if ($autoAttachedHtml) {
        $autoAttachedSelection = Resolve-GoogleStyleAttachedHtmlSelection -RepoRoot $RepoRoot
    }
}

$arguments = @{
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
}

if ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
    $arguments.ManualInputPath = $ManualInputPath
}
if ($ManualInitialPage) {
    $arguments.ManualInitialPage = $ManualInitialPage
}
if ($ManualGoogleStyle -or $autoAttachedHtml) {
    $arguments.ManualGoogleStyle = $true
}
if ($autoAttachedSelection) {
    $arguments.ManualInputPath = $autoAttachedSelection.InputPath
    if (-not $ManualInitialPage -and $autoAttachedSelection.InitialPage) {
        $arguments.ManualInitialPage = $autoAttachedSelection.InitialPage
    }
}
if ($LeaveOpen) {
    $arguments.LeaveOpen = $true
}

if ($autoAttachedSelection) {
    Write-Host ("Issue #3 recommended runner: Google-style attached HTML files were detected in the current search roots, so the Google-style manual localhost follow-up will run automatically with {0} locked fixture(s)." -f $autoAttachedSelection.InputPath.Count)
    if ($autoAttachedSelection.InitialPage) {
        Write-Host ("Issue #3 recommended runner: Preferred auto-selected Google-style initial page: {0}" -f $autoAttachedSelection.InitialPage)
    }
}

& $runner @arguments
