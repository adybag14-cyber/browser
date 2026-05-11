[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$LocalhostPort = 8176,
    [string]$InputText = "QZ",
    [string]$SharedInputText = "Q",
    [string]$EnterMutationSuffix = "!",
    [string]$TraceInputText = "lightpanda",
    [int]$TitlePort = 9582,
    [int]$TitleProbePort = 8159,
    [int]$HomePort = 8168,
    [int]$HomepageFixturePort = 8155,
    [int]$WatchPort = 9582,
    [int]$SharedLabelPort = 8153,
    [int]$SharedDefaultPort = 8154,
    [int]$SharedDeferredPort = 8155,
    [int]$InlineFlowPort = 8148,
    [int]$SharedReducedGooglePort = 8156,
    [int]$SharedEnterOrderPort = 8157,
    [int]$ReducedHomeKeypressPort = 8167,
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

function ConvertTo-PowerShellSingleQuotedLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Add-ArgumentText {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        $Value
    )

    if ($null -eq $Value) {
        return
    }
    if ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    $Arguments.Add("-$Name")
    if ($Value -is [string]) {
        $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $Value))
    } elseif ($Value -is [System.Array]) {
        foreach ($entry in $Value) {
            $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value ([string]$entry)))
        }
    } else {
        $Arguments.Add([string]$Value)
    }
}

$surfaceCheck = '.\scripts\windows\check_google_issue3_recommended_validation_surface.ps1'
$recommendedRunner = '.\scripts\windows\run_google_issue3_recommended_validation.ps1'
$titleFlow = '.\scripts\windows\show_google_title_validation_flow.ps1'
$quickFlow = '.\scripts\windows\show_google_quick_validation_flow.ps1'
$homepageFixtureFlow = '.\scripts\windows\show_google_homepage_fixture_validation_flow.ps1'
$submitTimingFlow = '.\scripts\windows\show_google_submit_timing_validation_flow.ps1'
$sharedEnterOrderFlow = '.\scripts\windows\show_google_shared_enter_order_validation_flow.ps1'
$traceFlow = '.\scripts\windows\show_google_trace_validation_flow.ps1'
$attachedHtmlFlow = '.\scripts\windows\show_google_attached_html_validation_flow.ps1'

$runnerArgs = [System.Collections.Generic.List[string]]::new()
Add-ArgumentText -Arguments $runnerArgs -Name RepoRoot -Value $RepoRoot
Add-ArgumentText -Arguments $runnerArgs -Name BrowserExe -Value $BrowserExe
Add-ArgumentText -Arguments $runnerArgs -Name Host -Value $Host
Add-ArgumentText -Arguments $runnerArgs -Name LocalhostPort -Value $LocalhostPort
Add-ArgumentText -Arguments $runnerArgs -Name InputText -Value $InputText
Add-ArgumentText -Arguments $runnerArgs -Name SharedInputText -Value $SharedInputText
Add-ArgumentText -Arguments $runnerArgs -Name EnterMutationSuffix -Value $EnterMutationSuffix
Add-ArgumentText -Arguments $runnerArgs -Name TraceInputText -Value $TraceInputText
Add-ArgumentText -Arguments $runnerArgs -Name TitlePort -Value $TitlePort
Add-ArgumentText -Arguments $runnerArgs -Name TitleProbePort -Value $TitleProbePort
Add-ArgumentText -Arguments $runnerArgs -Name HomePort -Value $HomePort
Add-ArgumentText -Arguments $runnerArgs -Name HomepageFixturePort -Value $HomepageFixturePort
Add-ArgumentText -Arguments $runnerArgs -Name WatchPort -Value $WatchPort
Add-ArgumentText -Arguments $runnerArgs -Name SharedLabelPort -Value $SharedLabelPort
Add-ArgumentText -Arguments $runnerArgs -Name SharedDefaultPort -Value $SharedDefaultPort
Add-ArgumentText -Arguments $runnerArgs -Name SharedDeferredPort -Value $SharedDeferredPort
Add-ArgumentText -Arguments $runnerArgs -Name InlineFlowPort -Value $InlineFlowPort
Add-ArgumentText -Arguments $runnerArgs -Name SharedReducedGooglePort -Value $SharedReducedGooglePort
Add-ArgumentText -Arguments $runnerArgs -Name SharedEnterOrderPort -Value $SharedEnterOrderPort
Add-ArgumentText -Arguments $runnerArgs -Name ReducedHomeKeypressPort -Value $ReducedHomeKeypressPort
Add-ArgumentText -Arguments $runnerArgs -Name SubmitTimingPort -Value $SubmitTimingPort
Add-ArgumentText -Arguments $runnerArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-ArgumentText -Arguments $runnerArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-ArgumentText -Arguments $runnerArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-ArgumentText -Arguments $runnerArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds
Add-ArgumentText -Arguments $runnerArgs -Name TraceWindowReadyAttempts -Value $TraceWindowReadyAttempts
Add-ArgumentText -Arguments $runnerArgs -Name TracePollMilliseconds -Value $TracePollMilliseconds
Add-ArgumentText -Arguments $runnerArgs -Name WatchTimeoutSeconds -Value $WatchTimeoutSeconds
Add-ArgumentText -Arguments $runnerArgs -Name WatchPollMilliseconds -Value $WatchPollMilliseconds
Add-ArgumentText -Arguments $runnerArgs -Name ManualPort -Value $ManualPort
if ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
    Add-ArgumentText -Arguments $runnerArgs -Name ManualInputPath -Value $ManualInputPath
}
Add-ArgumentText -Arguments $runnerArgs -Name ManualInitialPage -Value $ManualInitialPage
if ($ManualGoogleStyle) { $runnerArgs.Add("-ManualGoogleStyle") }
if ($LeaveOpen) { $runnerArgs.Add("-LeaveOpen") }
if ($SkipAutoAttachedHtml) { $runnerArgs.Add("-SkipAutoAttachedHtml") }

$manualFlowArgs = [System.Collections.Generic.List[string]]::new()
if ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
    Add-ArgumentText -Arguments $manualFlowArgs -Name InputPath -Value $ManualInputPath
}
Add-ArgumentText -Arguments $manualFlowArgs -Name PreferredInitialPage -Value $ManualInitialPage
Add-ArgumentText -Arguments $manualFlowArgs -Name Port -Value $ManualPort
if ($ManualGoogleStyle) { $manualFlowArgs.Add("-ManualGoogleStyle") }
if ($LeaveOpen) { $manualFlowArgs.Add("-LeaveOpen") }

$flow = [ordered]@{
    issue = "Headed Windows issue #3 recommended validation flow"
    focus = "Read-first helper for the one-command localhost-first runner that chains the bounded localhost, quick title-plus-watch, reduced home, saved-homepage fixture, reduced-home input-phase, submit-timing, shared Enter-order, and optional attached-HTML follow-up before any live Google trace work."
    host = $Host
    input_text = $InputText
    shared_input_text = $SharedInputText
    trace_input_text = $TraceInputText
    leave_open = [bool]$LeaveOpen
    manual_google_style = [bool]$ManualGoogleStyle
    skip_auto_attached_html = [bool]$SkipAutoAttachedHtml
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the recommended runner, its narrower flow helpers, or the attached-HTML follow-up surface drifted before you trust the one-command issue #3 stack."
            command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $surfaceCheck)
        }
        [ordered]@{
            name = "recommended"
            goal = "Run the full localhost-first issue #3 stack in the intended order, including the quick title-plus-watch gate before the reduced homepage ladder and the optional attached-HTML manual follow-up when fixtures are supplied or auto-discovered."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $recommendedRunner, $(if ($runnerArgs.Count -gt 0) { " " + ($runnerArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "title-flow"
            goal = "Print the narrower title flow first when you only need the bounded readiness, click-focus, typed-text, and Enter-submit slice explained before the quick or full recommended stack."
            command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $titleFlow)
        }
        [ordered]@{
            name = "quick-flow"
            goal = "Print the bounded title-plus-watch gate when you want the fast first pass spelled out before the reduced homepage ladder or the full recommended runner."
            command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $quickFlow)
        }
        [ordered]@{
            name = "homepage-fixture-flow"
            goal = "Print the bounded saved-homepage fixture handoff before you rerun only that middle slice."
            command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $homepageFixtureFlow)
        }
        [ordered]@{
            name = "submit-timing-flow"
            goal = "Print the bounded keydown, keypress, and submit-ordering ladder before rerunning only the submit-timing slice."
            command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $submitTimingFlow)
        }
        [ordered]@{
            name = "shared-enter-order-flow"
            goal = "Print the shared Enter-order ladder before rerunning only the stricter shared gates."
            command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $sharedEnterOrderFlow)
        }
        [ordered]@{
            name = "attached-html-flow"
            goal = "Print the Google-style attached-HTML follow-up when the bounded localhost ladder is already green and the next question is how the saved or attached pages diverge."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $attachedHtmlFlow, $(if ($manualFlowArgs.Count -gt 0) { " " + ($manualFlowArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "trace-flow"
            goal = "Print the later live Google trace handoff only after the recommended localhost-first stack is green."
            command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $traceFlow)
        }
    )
    next_steps = @(
        "Start with the recommended runner when you want one command to prove the bounded localhost-first issue #3 ladder before any real Google capture.",
        "Use the quick flow after the surface check when you want the early title-plus-watch gate spelled out before the reduced homepage pass.",
        "Use the attached-HTML flow after the recommended runner is green when the next question is whether the current saved or attached pages diverge before live Google does.",
        "Use the trace flow only after the bounded localhost, quick, saved-homepage fixture, reduced-home input-phase, submit-timing, and shared Enter-order slices are all green together."
    )
    notes = @(
        "This helper exists to make the one-command recommended runner inspectable before execution, not to replace the narrower flow helpers.",
        "The recommended runner now begins with its own dedicated surface-check and then folds the quick title-plus-watch gate in before the reduced homepage pass so the scripted sequence matches the surrounding docs and helper text.",
        "Keep SharedInputText aligned across the reduced home, shared Enter-order, and saved-homepage fixture slices so the manual follow-up has the same expectation.",
        "ManualInputPath and ManualInitialPage are forwarded into the printed attached-HTML flow when they are already known, so the saved-page handoff stays reproducible.",
        "LeaveOpen is only for the phases where visual inspection after automation matters; keep it off for routine preflight checks."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows issue #3 recommended validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Host: {0}" -f $flow.host)
Write-Host ("Input text: {0}" -f $flow.input_text)
Write-Host ("Shared input text: {0}" -f $flow.shared_input_text)
Write-Host ("Trace input text: {0}" -f $flow.trace_input_text)
Write-Host ("Leave open after bounded phases: {0}" -f ([bool]$LeaveOpen))
Write-Host ("Manual Google-style attached follow-up: {0}" -f ([bool]$ManualGoogleStyle))
Write-Host ("Skip auto attached HTML discovery: {0}" -f ([bool]$SkipAutoAttachedHtml))
Write-Host ""
foreach ($step in $flow.steps) {
    Write-Host ("[{0}] {1}" -f $step.name, $step.goal)
    Write-Host ("  {0}" -f $step.command)
    Write-Host ""
}
Write-Host "Next steps:"
foreach ($step in $flow.next_steps) {
    Write-Host ("- {0}" -f $step)
}
Write-Host ""
Write-Host "Notes:"
foreach ($note in $flow.notes) {
    Write-Host ("- {0}" -f $note)
}