[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$SharedInputText = "Q",
    [string]$EnterMutationSuffix = "!",
    [int]$SharedEnterOrderPort = 8157,
    [int]$ReducedHomeKeypressPort = 8167,
    [int]$TitleProbePort = 8159,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$WindowReadyAttempts = 60,
    [int]$TitleWaitAttempts = 80,
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

$sharedEnterOrderFlow = '.\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1'
$traceFlow = '.\\scripts\\windows\\show_google_trace_validation_flow.ps1'
$attachedHtmlFlow = '.\\scripts\\windows\\show_google_attached_html_validation_flow.ps1'
$suiteRouterNextSteps = '.\\scripts\\windows\\show_google_issue3_suite_router_next_steps.ps1'

$sharedEnterOrderArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name EnterMutationSuffix -Value $EnterMutationSuffix
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name SharedEnterOrderPort -Value $SharedEnterOrderPort
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name ReducedHomeKeypressPort -Value $ReducedHomeKeypressPort
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name TitleProbePort -Value $TitleProbePort
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name HomeWindowReadyAttempts -Value $WindowReadyAttempts
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name HomeTitleWaitAttempts -Value $TitleWaitAttempts
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name HomePollMilliseconds -Value $PollMilliseconds

$traceFlowArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $traceFlowArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $traceFlowArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $traceFlowArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $traceFlowArgs -Name InputText -Value $SharedInputText
Add-SharedArgument -Arguments $traceFlowArgs -Name WindowReadyAttempts -Value $WindowReadyAttempts
Add-SharedArgument -Arguments $traceFlowArgs -Name PollMilliseconds -Value $PollMilliseconds
if ($LeaveOpen) {
    $traceFlowArgs.Add('-LeaveOpen')
}

$attachedHtmlFlowArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $attachedHtmlFlowArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $attachedHtmlFlowArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $attachedHtmlFlowArgs -Name Host -Value $Host
if ($LeaveOpen) {
    $attachedHtmlFlowArgs.Add('-LeaveOpen')
}

$suiteRouterArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $suiteRouterArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $suiteRouterArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $suiteRouterArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $suiteRouterArgs -Name SubmitTimingInputText -Value $SharedInputText
Add-SharedArgument -Arguments $suiteRouterArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $suiteRouterArgs -Name TraceInputText -Value $SharedInputText

$flow = [ordered]@{
    issue = "Headed Windows shared Enter to trace handoff"
    focus = "Keep the current issue #3 repo, browser, host, input, and timing context intact when moving from the shared Enter-order ladder into live trace capture or attached-page follow-up."
    host = $Host
    shared_input_text = $SharedInputText
    leave_open = [bool]$LeaveOpen
    steps = @(
        [ordered]@{
            name = "shared-enter-order"
            goal = "Reprint the shared Enter-order ladder with the same narrowed context before you widen into later trace or replay work."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $sharedEnterOrderFlow, $(if ($sharedEnterOrderArgs.Count -gt 0) { " " + ($sharedEnterOrderArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "live-trace"
            goal = "Open the live trace handoff with the same repo-root, browser, host, shared input, and bounded wait settings."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $traceFlow, $(if ($traceFlowArgs.Count -gt 0) { " " + ($traceFlowArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "attached-html"
            goal = "Check the saved Google-shaped attached pages with the same repo-root, browser, and host context before blaming the live Google homepage path."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $attachedHtmlFlow, $(if ($attachedHtmlFlowArgs.Count -gt 0) { " " + ($attachedHtmlFlowArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "suite-router-next-steps"
            goal = "Reopen the higher-level issue #3 next-step matrix with the same repo-root, browser, host, and input context before choosing the next broader branch."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $suiteRouterNextSteps, $(if ($suiteRouterArgs.Count -gt 0) { " " + ($suiteRouterArgs -join " ") } else { "" }))
        }
    )
    notes = @(
        "Use this after the shared Enter-order stack is green but the next decision is whether to trace live Google or replay the saved attached pages first.",
        "The shared Enter-order and live trace commands intentionally reuse the same input text so comparisons stay easier across the narrower localhost gates and the later live capture.",
        "Use the attached-page route before the live Google homepage when you want to see whether the saved compatibility pages diverge earlier on the same headed binary.",
        "Use the higher-level suite router next-steps surface when the shared Enter-order slice is no longer the right level and you want the broader issue #3 ladder reopened without rebuilding the current context by hand.",
        "When LeaveOpen is set, the printed live trace and attached-page commands keep that inspection mode visible in the later handoff surfaces that support it."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows shared Enter to trace handoff"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Host: {0}" -f $flow.host)
Write-Host ("Shared input text: {0}" -f $flow.shared_input_text)
Write-Host ("Leave open after later capture: {0}" -f ([bool]$LeaveOpen))
Write-Host ""
foreach ($step in $flow.steps) {
    Write-Host ("[{0}] {1}" -f $step.name, $step.goal)
    Write-Host ("  {0}" -f $step.command)
    Write-Host ""
}
Write-Host "Notes:"
foreach ($note in $flow.notes) {
    Write-Host ("- {0}" -f $note)
}
