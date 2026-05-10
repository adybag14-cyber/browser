[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [ValidateSet("localhost", "title", "home", "quick", "shared", "shared-enter-order", "trace", "watch", "manual", "all")]
    [string]$Phase = "all",
    [switch]$IncludeWatch,
    [switch]$IncludeSharedInput,
    [switch]$IncludeSharedEnterOrder,
    [switch]$IncludeTitleProbe,
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
    [switch]$LeaveOpen
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = $PSScriptRoot
if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path (Join-Path $scriptRoot "..\..")).Path
}
if (-not $BrowserExe) {
    $BrowserExe = Join-Path $RepoRoot "zig-out\bin\lightpanda.exe"
}

$probeRoot = Join-Path $RepoRoot "tmp-browser-smoke"
$googleLocalhostRoot = Join-Path $probeRoot "google-investigation-next"
$titleProbe = Join-Path $scriptRoot "run_google_home_title_probe.ps1"
$googleHomeProbe = Join-Path $probeRoot "google-home\chrome-google-home-enter-probe.ps1"
$formControlsLabelProbe = Join-Path $probeRoot "form-controls\label-click-probe.ps1"
$formControlsEnterProbe = Join-Path $probeRoot "form-controls\enter-submit-probe.ps1"
$formControlsReducedGoogleProbe = Join-Path $probeRoot "form-controls\chrome-google-home-enter-submit-probe.ps1"
$inlineFlowEnterProbe = Join-Path $probeRoot "inline-flow\chrome-inline-break-input-enter-submit-probe.ps1"
$watchProbe = Join-Path $scriptRoot "run_google_home_watch_probe.ps1"
$manualHtmlHelper = Join-Path $scriptRoot "start_staged_localhost_html_validation.ps1"
$sharedEnterOrderRunner = Join-Path $scriptRoot "run_google_shared_enter_order_validation.ps1"
$liveGoogleTraceProbe = Join-Path $googleLocalhostRoot "chrome-google-home-input-probe.ps1"

$localhostProbes = @(
    "google-style-localhost-probe.ps1",
    "google-style-correction-localhost-probe.ps1",
    "google-enter-order-localhost-probe.ps1",
    "google-style-delayed-ready-localhost-probe.ps1"
)

function Invoke-ProbeScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [hashtable]$Arguments
    )

    if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
        throw "Probe script not found: $ScriptPath"
    }

    Write-Host ""
    Write-Host ("=== {0} ===" -f $Label)
    Write-Host ("Script: {0}" -f $ScriptPath)

    if ($Arguments) {
        & $ScriptPath @Arguments
    } else {
        & $ScriptPath
    }
}

function Invoke-LocalhostSequence {
    foreach ($probeName in $localhostProbes) {
        $scriptPath = Join-Path $googleLocalhostRoot $probeName
        $args = @{
            RepoRoot = $RepoRoot
            BrowserExe = $BrowserExe
            Host = $Host
            Port = $LocalhostPort
            InputText = $InputText
            ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
            WindowReadyAttempts = $HomeWindowReadyAttempts
            TitleWaitAttempts = $HomeTitleWaitAttempts
            PollMilliseconds = $HomePollMilliseconds
        }
        Invoke-ProbeScript -Label $probeName -ScriptPath $scriptPath -Arguments $args
    }
}

function Invoke-TitleSequence {
    $args = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        Host = $Host
        Port = $TitlePort
        ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    }
    Invoke-ProbeScript -Label "google-home-title" -ScriptPath $titleProbe -Arguments $args
}

function Invoke-HomeSequence {
    $args = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        Host = $Host
        Port = $HomePort
        InputText = $InputText
        ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
        WindowReadyAttempts = $HomeWindowReadyAttempts
        TitleWaitAttempts = $HomeTitleWaitAttempts
        PollMilliseconds = $HomePollMilliseconds
    }
    if ($LeaveOpen) {
        $args.LeaveOpen = $true
    }
    Invoke-ProbeScript -Label "google-home" -ScriptPath $googleHomeProbe -Arguments $args
}

function Invoke-QuickSequence {
    Invoke-TitleSequence
    Invoke-WatchSequence
}

function Invoke-SharedInputSequence {
    $labelArgs = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        Host = $Host
        Port = $SharedLabelPort
        ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
        WindowReadyAttempts = $HomeWindowReadyAttempts
        TitleWaitAttempts = $HomeTitleWaitAttempts
        PollMilliseconds = $HomePollMilliseconds
    }
    Invoke-ProbeScript -Label "form-controls-label-click" -ScriptPath $formControlsLabelProbe -Arguments $labelArgs

    $commonArgs = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        Host = $Host
        InputText = $SharedInputText
        ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
        WindowReadyAttempts = $HomeWindowReadyAttempts
        TitleWaitAttempts = $HomeTitleWaitAttempts
        PollMilliseconds = $HomePollMilliseconds
    }

    $defaultArgs = $commonArgs.Clone()
    $defaultArgs.Port = $SharedDefaultPort
    Invoke-ProbeScript -Label "form-controls-enter-submit" -ScriptPath $formControlsEnterProbe -Arguments $defaultArgs

    $deferredArgs = $commonArgs.Clone()
    $deferredArgs.DeferredEnter = $true
    $deferredArgs.Port = $SharedDeferredPort
    Invoke-ProbeScript -Label "form-controls-deferred-enter-submit" -ScriptPath $formControlsEnterProbe -Arguments $deferredArgs

    $reducedGoogleArgs = $commonArgs.Clone()
    $reducedGoogleArgs.Port = $SharedReducedGooglePort
    Invoke-ProbeScript -Label "form-controls-google-home-enter-submit" -ScriptPath $formControlsReducedGoogleProbe -Arguments $reducedGoogleArgs

    $inlineArgs = $commonArgs.Clone()
    $inlineArgs.Port = $InlineFlowPort
    Invoke-ProbeScript -Label "inline-flow-enter-submit" -ScriptPath $inlineFlowEnterProbe -Arguments $inlineArgs
}

function Invoke-SharedEnterOrderSequence {
    $args = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        Host = $Host
        SharedInputText = $SharedInputText
        SharedLabelPort = $SharedLabelPort
        SharedDefaultPort = $SharedDefaultPort
        SharedDeferredPort = $SharedDeferredPort
        SharedReducedGooglePort = $SharedReducedGooglePort
        SharedEnterOrderPort = $SharedEnterOrderPort
        InlineFlowPort = $InlineFlowPort
        ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
        HomeWindowReadyAttempts = $HomeWindowReadyAttempts
        HomeTitleWaitAttempts = $HomeTitleWaitAttempts
        HomePollMilliseconds = $HomePollMilliseconds
    }
    Invoke-ProbeScript -Label "google-shared-enter-order" -ScriptPath $sharedEnterOrderRunner -Arguments $args
}

function Invoke-TraceSequence {
    $args = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        InputText = $TraceInputText
        WindowReadyAttempts = $TraceWindowReadyAttempts
        PollMilliseconds = $TracePollMilliseconds
    }
    if ($LeaveOpen) {
        $args.LeaveOpen = $true
    }
    Invoke-ProbeScript -Label "google-home-live-trace" -ScriptPath $liveGoogleTraceProbe -Arguments $args
}

function Invoke-WatchSequence {
    $args = @{
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        Host = $Host
        Port = $WatchPort
        InputText = $InputText
        TimeoutSeconds = $WatchTimeoutSeconds
        PollMilliseconds = $WatchPollMilliseconds
        SendEnter = $true
        ServerReadyTimeoutSeconds = $ServerReadyTimeoutSeconds
    }
    if ($LeaveOpen) {
        $args.LeaveOpen = $true
    }
    Invoke-ProbeScript -Label "google-home-watch" -ScriptPath $watchProbe -Arguments $args
}

function Invoke-ManualHtmlSequence {
    if (-not $ManualInputPath -or $ManualInputPath.Count -eq 0) {
        throw "ManualInputPath is required when running the manual localhost HTML follow-up."
    }

    $args = @{
        InputPath = $ManualInputPath
        RepoRoot = $RepoRoot
        BrowserExe = $BrowserExe
        Host = $Host
        Port = $ManualPort
        LaunchBrowser = $true
        Wait = $true
    }
    if ($ManualInitialPage) {
        $args.InitialPage = $ManualInitialPage
    }
    if ($LeaveOpen) {
        $args.LeaveServerRunning = $true
    }

    Invoke-ProbeScript -Label "manual-localhost-html" -ScriptPath $manualHtmlHelper -Arguments $args
}

Write-Host "Google headed-input validation runner"
Write-Host ("Repo root: {0}" -f $RepoRoot)
Write-Host ("Phase: {0}" -f $Phase)
Write-Host ("Host: {0}" -f $Host)
Write-Host ("Localhost probe port: {0}" -f $LocalhostPort)
Write-Host ("Primary input text: {0}" -f $InputText)
Write-Host ("Shared input text: {0}" -f $SharedInputText)
Write-Host ("Trace input text: {0}" -f $TraceInputText)
Write-Host ("Shared label port: {0}" -f $SharedLabelPort)
Write-Host ("Shared reduced Google port: {0}" -f $SharedReducedGooglePort)
Write-Host ("Shared enter-order port: {0}" -f $SharedEnterOrderPort)
if ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
    Write-Host ("Manual HTML follow-up: {0}" -f (($ManualInputPath | ForEach-Object { $_ }) -join ", "))
}

switch ($Phase) {
    "localhost" {
        Invoke-LocalhostSequence
    }
    "title" {
        Invoke-TitleSequence
    }
    "home" {
        Invoke-HomeSequence
    }
    "quick" {
        Invoke-QuickSequence
    }
    "shared" {
        Invoke-SharedInputSequence
    }
    "shared-enter-order" {
        Invoke-SharedEnterOrderSequence
    }
    "trace" {
        Invoke-TraceSequence
    }
    "watch" {
        Invoke-WatchSequence
    }
    "manual" {
        Invoke-ManualHtmlSequence
    }
    "all" {
        Invoke-LocalhostSequence
        if ($IncludeTitleProbe) {
            Invoke-TitleSequence
        }
        Invoke-HomeSequence
        if ($IncludeSharedEnterOrder) {
            Invoke-SharedEnterOrderSequence
        } elseif ($IncludeSharedInput) {
            Invoke-SharedInputSequence
        }
        if ($IncludeWatch) {
            Invoke-WatchSequence
        }
        if ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
            Invoke-ManualHtmlSequence
        }
    }
}

Write-Host ""
if ($Phase -eq "manual") {
    Write-Host "Next: compare any saved-page failures with the reduced localhost and bounded homepage probes before moving on to the smallest live Google manual pass."
} elseif ($Phase -eq "trace") {
    Write-Host "Next: inspect the captured real-Google trace tails, then compare them with the nearest bounded localhost or reduced-homepage phase before changing the headed input path."
} elseif ($Phase -eq "shared-enter-order") {
    Write-Host "Next: if the shared label baseline, submit gates, and stricter enter-order localhost probe stay green, move on to the smallest live Google manual pass."
} elseif ($Phase -eq "shared") {
    Write-Host "Next: return to -Phase home or -Phase watch once the label baseline, deferred/basic form-controls, reduced Google-home, and inline-flow probes are green, or use -Phase shared-enter-order for the stricter keypress-before-submit wrapper."
} elseif ($Phase -eq "title") {
    Write-Host "Next: use -Phase quick for the fast title-plus-watch first pass, use -Phase home for the reduced homepage Enter pass, use -Phase trace for live Google divergence capture, or run -Phase all -IncludeTitleProbe to put the quick headed title check at the front of the shared flow."
} elseif ($Phase -eq "quick") {
    Write-Host "Next: use -Phase home for the reduced homepage Enter pass, use -Phase trace when the bounded passes are green but real Google still diverges, or run -Phase all -IncludeTitleProbe -IncludeWatch to fold the same fast first pass into the broader validation flow."
} elseif ($Phase -eq "watch" -or $IncludeWatch) {
    if ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
        Write-Host "Next: use the saved-page localhost session to compare attached-page behavior with the reduced homepage watcher before the smallest live Google manual pass."
    } else {
        Write-Host "Next: move on to the smallest live Google manual pass once the self-starting watcher confirms SUBMIT:QZ, or use -Phase trace if the live homepage still needs trace capture."
    }
} elseif ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
    Write-Host "Next: use the saved-page localhost session to compare attached-page behavior with the reduced Google and shared-input probes before the smallest live Google manual pass."
} elseif ($IncludeSharedEnterOrder -and $IncludeTitleProbe) {
    Write-Host "Next: if the quick title probe, reduced Google pass, shared label baseline, shared submit gates, stricter enter-order wrapper, and watcher stay green, move on to the smallest live Google manual pass or use -Phase trace for real-Google divergence capture."
} elseif ($IncludeSharedEnterOrder) {
    Write-Host "Next: if the reduced Google pass, shared label baseline, shared submit gates, and stricter enter-order wrapper stay green, move on to the smallest live Google manual pass or use -Phase trace for real-Google divergence capture."
} elseif ($IncludeSharedInput -and $IncludeTitleProbe) {
    Write-Host "Next: if the quick title probe, reduced Google pass, shared label baseline, deferred/basic form-controls, reduced Google-home, and inline-flow probes stay green, move on to the smallest live Google manual pass or use -Phase trace for real-Google divergence capture."
} elseif ($IncludeSharedInput) {
    Write-Host "Next: if the reduced Google, shared label baseline, deferred/basic form-controls, reduced Google-home, and inline-flow probes stay green, use -IncludeSharedEnterOrder or move on to the smallest live Google manual pass, then use -Phase trace if the live homepage still diverges."
} elseif ($IncludeTitleProbe) {
    Write-Host "Next: if the quick title probe and reduced Google pass stay green, add -IncludeSharedEnterOrder or -IncludeSharedInput, or move on to the smallest live Google manual pass and -Phase trace if needed."
} else {
    Write-Host "Next: use -Phase quick for the fast title-plus-watch first pass, -IncludeTitleProbe for the quick headed title pass, -IncludeSharedInput for the label baseline plus deferred/basic form-controls, reduced Google-home, and inline-flow checks, -IncludeSharedEnterOrder to fold the stricter wrapper into the one-shot flow, -Phase shared-enter-order for the stricter wrapper by itself, -Phase trace for live Google trace capture after the bounded phases, -IncludeWatch for the self-starting title-stream pass, or -ManualInputPath for the saved localhost HTML follow-up before the smallest live Google manual check."
}
