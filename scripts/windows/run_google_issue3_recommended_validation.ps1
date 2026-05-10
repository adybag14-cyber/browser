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

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

function Get-AttachedHtmlSearchRoots {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $candidateRoots = New-Object System.Collections.Generic.List[string]
    $candidateRoots.Add((Join-Path $RepoRoot "user_files"))
    $candidateRoots.Add((Join-Path $RepoRoot "agent_files"))

    $repoParent = Split-Path $RepoRoot -Parent
    if (-not [string]::IsNullOrWhiteSpace($repoParent) -and $repoParent -ne $RepoRoot) {
        $candidateRoots.Add((Join-Path $repoParent "user_files"))
        $candidateRoots.Add((Join-Path $repoParent "agent_files"))
    }

    $currentRoot = (Get-Location).Path
    if (-not [string]::IsNullOrWhiteSpace($currentRoot)) {
        $candidateRoots.Add((Join-Path $currentRoot "user_files"))
        $candidateRoots.Add((Join-Path $currentRoot "agent_files"))
    }

    return $candidateRoots |
        Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
        Select-Object -Unique
}

function Test-AttachedHtmlAvailable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $searchRoots = @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot)

    foreach ($root in $searchRoots) {
        $match = Get-ChildItem -LiteralPath $root -Recurse -File |
            Where-Object { $_.Extension -in @(".html", ".htm") } |
            Select-Object -First 1
        if ($match) {
            return $true
        }
    }

    return $false
}

$runner = Join-Path $PSScriptRoot "run_google_input_validation.ps1"
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
    throw "Google input validation runner not found: $runner"
}

$autoAttachedHtml = $false
if (-not $SkipAutoAttachedHtml -and -not $ManualGoogleStyle -and -not ($ManualInputPath -and $ManualInputPath.Count -gt 0)) {
    $autoAttachedHtml = Test-AttachedHtmlAvailable -RepoRoot $RepoRoot
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
if ($LeaveOpen) {
    $arguments.LeaveOpen = $true
}

if ($autoAttachedHtml) {
    Write-Host "Issue #3 recommended runner: attached HTML files were detected in the current search roots, so the Google-style manual localhost follow-up will run automatically."
}

& $runner @arguments
