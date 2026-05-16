[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$InputText = "lightpanda",
    [int]$WindowReadyAttempts = 80,
    [int]$PollMilliseconds = 250,
    [switch]$LeaveOpen
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

function Add-SharedArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
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
    } else {
        $Arguments.Add([string]$Value)
    }
}

$suiteRouterEntry = '.\\scripts\\windows\\show_headed_validation_suites.ps1'
$surfaceCheck = '.\\scripts\\windows\\check_google_trace_validation_surface.ps1'
$reducedTraceProbe = '.\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-enter-trace-probe.ps1'
$wrapperRunner = '.\\scripts\\windows\\run_google_input_validation.ps1'
$liveTraceProbe = '.\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-input-probe.ps1'
$artifactGuide = '.\\scripts\\windows\\show_google_trace_artifact_guide.ps1'
$submitTimingFlow = '.\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1'
$sharedEnterOrderFlow = '.\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1'
$attachedHtmlFlow = '.\\scripts\\windows\\show_google_attached_html_validation_flow.ps1'

$surfaceCheckArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $surfaceCheckArgs -Name RepoRoot -Value $RepoRoot

$reducedTraceArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $reducedTraceArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $reducedTraceArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $reducedTraceArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $reducedTraceArgs -Name InputText -Value $InputText
Add-SharedArgument -Arguments $reducedTraceArgs -Name WindowReadyAttempts -Value $WindowReadyAttempts
Add-SharedArgument -Arguments $reducedTraceArgs -Name PollMilliseconds -Value $PollMilliseconds
if ($LeaveOpen) {
    $reducedTraceArgs.Add('-LeaveOpen')
}

$wrapperArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $wrapperArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $wrapperArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $wrapperArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $wrapperArgs -Name Phase -Value 'trace'
Add-SharedArgument -Arguments $wrapperArgs -Name TraceInputText -Value $InputText
Add-SharedArgument -Arguments $wrapperArgs -Name TraceWindowReadyAttempts -Value $WindowReadyAttempts
Add-SharedArgument -Arguments $wrapperArgs -Name TracePollMilliseconds -Value $PollMilliseconds
if ($LeaveOpen) {
    $wrapperArgs.Add('-LeaveOpen')
}

$liveTraceArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $liveTraceArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $liveTraceArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $liveTraceArgs -Name InputText -Value $InputText
Add-SharedArgument -Arguments $liveTraceArgs -Name WindowReadyAttempts -Value $WindowReadyAttempts
Add-SharedArgument -Arguments $liveTraceArgs -Name PollMilliseconds -Value $PollMilliseconds
if ($LeaveOpen) {
    $liveTraceArgs.Add('-LeaveOpen')
}

$artifactGuideArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $artifactGuideArgs -Name RepoRoot -Value $RepoRoot

$submitTimingFlowArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $submitTimingFlowArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $submitTimingFlowArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $submitTimingFlowArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $submitTimingFlowArgs -Name InputText -Value $InputText

$sharedEnterOrderFlowArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedEnterOrderFlowArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedEnterOrderFlowArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $sharedEnterOrderFlowArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $sharedEnterOrderFlowArgs -Name SharedInputText -Value $InputText

$attachedHtmlFlowArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $attachedHtmlFlowArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $attachedHtmlFlowArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $attachedHtmlFlowArgs -Name Host -Value $Host
if ($LeaveOpen) {
    $attachedHtmlFlowArgs.Add('-LeaveOpen')
}

$flow = [ordered]@{
    issue = "Headed Windows Google live trace validation flow"
    focus = "Read-first handoff from the bounded localhost, reduced homepage, submit-timing, and shared Enter-order gates into the reduced-home trace capture and the real Google homepage trace path."
    host = $Host
    input_text = $InputText
    leave_open = [bool]$LeaveOpen
    steps = @(
        [ordered]@{
            name = "suite-router"
            goal = "Print the shared headed validation suite entry for the live-trace handoff before you narrow into the dedicated checker or later trace commands."
            command = ("powershell -ExecutionPolicy Bypass -File {0} -SuiteName google-live-trace" -f $suiteRouterEntry)
        }
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the later issue #3 trace handoff drifted before you trust a reduced-home or live Google capture."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $surfaceCheck, $(if ($surfaceCheckArgs.Count -gt 0) { " " + ($surfaceCheckArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "reduced-trace"
            goal = "Run the reduced-home trace probe first when you want the real headed surface plus the Google-specific runtime logs without jumping straight to live Google."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $reducedTraceProbe, $(if ($reducedTraceArgs.Count -gt 0) { " " + ($reducedTraceArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "wrapper"
            goal = "Run the live Google trace path through the shared issue #3 runner so the real-homepage capture stays on the same reusable command surface as the bounded phases."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $wrapperRunner, $(if ($wrapperArgs.Count -gt 0) { " " + ($wrapperArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "direct-live-probe"
            goal = "Run the raw live Google trace probe only when you need to narrow a wrapper failure to the underlying headed input and logging path."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $liveTraceProbe, $(if ($liveTraceArgs.Count -gt 0) { " " + ($liveTraceArgs -join " ") } else { "" }))
        }
    )
    next_steps = @(
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} after any reduced-home or live Google capture when you want the current trace files, their tails, and the closest follow-up helpers printed on one surface." -f $artifactGuide, $(if ($artifactGuideArgs.Count -gt 0) { " " + ($artifactGuideArgs -join " ") } else { "" })),
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} when you need to re-walk the bounded keydown, keypress, and submit ordering with the same repo-root, browser, host, and input context before another live capture." -f $submitTimingFlow, $(if ($submitTimingFlowArgs.Count -gt 0) { " " + ($submitTimingFlowArgs -join " ") } else { "" })),
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} when you want the stricter shared Enter-order stack printed with the same repo-root, browser, host, and input context before the next live trace rerun." -f $sharedEnterOrderFlow, $(if ($sharedEnterOrderFlowArgs.Count -gt 0) { " " + ($sharedEnterOrderFlowArgs -join " ") } else { "" })),
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} when the next question is whether the current attached or saved Google-style localhost pages diverge before the live Google homepage does." -f $attachedHtmlFlow, $(if ($attachedHtmlFlowArgs.Count -gt 0) { " " + ($attachedHtmlFlowArgs -join " ") } else { "" }))
    )
    notes = @(
        "Start with the shared suite-router entry when you need the live-trace lane, its neighboring suites, and the dedicated helper surface reintroduced before you dive into raw trace commands.",
        "Run the trace surface checker first so missing guides, runner wiring, or probe files fail before the later-stage capture looks trustworthy.",
        "After any capture, print the trace artifact guide so the reduced-home logs, live-home logs, and Google-focused runtime traces stay on one repeatable inspection surface.",
        "Treat this helper as a later-stage investigation handoff, not the first gate. Start with the reduced localhost probes and shared input stacks first.",
        "Use the wrapper unless you already know you need the raw direct probe outputs from tmp-browser-smoke/google-investigation-next.",
        "When LeaveOpen is set, the reduced and live trace commands keep the headed window open after capture so the real surface can be inspected before teardown.",
        "The printed handoff commands preserve the current repo root, browser path, host, input text, and LeaveOpen mode where those later helpers support them."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google live trace validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Bounded follow-up host: {0}" -f $flow.host)
Write-Host ("Input text: {0}" -f $flow.input_text)
Write-Host ("Leave open after trace capture: {0}" -f ([bool]$LeaveOpen))
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
