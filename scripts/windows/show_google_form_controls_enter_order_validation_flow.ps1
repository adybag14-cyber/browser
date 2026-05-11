[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$SharedInputText = "Q",
    [int]$SharedEnterOrderPort = 8157,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 60,
    [int]$HomeTitleWaitAttempts = 80,
    [int]$HomePollMilliseconds = 250
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

$surfaceCheck = '.\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1'
$traceGuide = '.\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1'
$runner = '.\scripts\windows\run_google_form_controls_enter_order_validation.ps1'
$rawProbe = '.\tmp-browser-smoke\form-controls\google-enter-order-probe.ps1'

$surfaceCheckArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $surfaceCheckArgs -Name RepoRoot -Value $RepoRoot

$traceGuideArgs = [System.Collections.Generic.List[string]]::new()

$runnerArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $runnerArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $runnerArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $runnerArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $runnerArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $runnerArgs -Name SharedEnterOrderPort -Value $SharedEnterOrderPort
Add-SharedArgument -Arguments $runnerArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $runnerArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $runnerArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $runnerArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds

$rawProbeArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $rawProbeArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $rawProbeArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $rawProbeArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $rawProbeArgs -Name InputText -Value $SharedInputText
Add-SharedArgument -Arguments $rawProbeArgs -Name Port -Value $SharedEnterOrderPort
Add-SharedArgument -Arguments $rawProbeArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $rawProbeArgs -Name WindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $rawProbeArgs -Name TitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $rawProbeArgs -Name PollMilliseconds -Value $HomePollMilliseconds

$flow = [ordered]@{
    issue = "Headed Windows Google form-controls Enter-order validation flow"
    focus = "Print the narrowest shared form-controls issue #3 command surface for confirming that Enter submit reaches the page after keypress on the headed Win32 path."
    shared_input_text = $SharedInputText
    shared_enter_order_port = $SharedEnterOrderPort
    host = $Host
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Run the dedicated fail-fast checker first so missing docs, helper scripts, or the raw form-controls probe are caught before the smallest shared Enter-order gate starts."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $surfaceCheck, $(if ($surfaceCheckArgs.Count -gt 0) { " " + ($surfaceCheckArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "trace-guide"
            goal = "Print the quick diagnosis guide so the dedicated Enter-order gate's focus, typed-text, keydown, keypress, and submit markers are easy to interpret before or after a rerun."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $traceGuide, $(if ($traceGuideArgs.Count -gt 0) { " " + ($traceGuideArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "recommended"
            goal = "Run the dedicated wrapper so the Google-style shared form-controls Enter-order gate stays on one stable command surface."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $runner, $(if ($runnerArgs.Count -gt 0) { " " + ($runnerArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "raw-probe"
            goal = "Run the underlying probe directly when you need the exact headed localhost script without the wrapper layer."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $rawProbe, $(if ($rawProbeArgs.Count -gt 0) { " " + ($rawProbeArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "broader-stack"
            goal = "Escalate to the wider shared Enter-order ladder only after the dedicated form-controls gate is green or when you need the reduced homepage and localhost wrappers in the same pass."
            command = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1"
        }
    )
    notes = @(
        "Run the dedicated surface check before the wrapper when you want missing docs, scripts, or raw probe drift to fail fast.",
        "Use the trace guide when you need a quick read on whether the failure stayed before focus, before typed text became visible, or before keypress reached submit.",
        "Keep SharedInputText aligned with the broader issue #3 shared probes so the dedicated form-controls gate reports the same expected query string.",
        "Port 8157 is shared on purpose with the broader Enter-order helpers, so one override keeps the dedicated gate and the wider stack in sync.",
        "Use the raw probe command only when you need the direct script surface; otherwise prefer the dedicated wrapper so the runbook and issue comments stay consistent."
    )
    next_steps = @(
        "Use .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1 when you want the dedicated probe markers translated into quick failure stages before widening again.",
        "Use .\scripts\windows\run_google_form_controls_enter_order_validation.ps1 when you want to execute the dedicated gate directly after the surface check passes.",
        "Use .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1 when the dedicated gate is green and you want the reduced homepage, localhost wrapper, and shared Enter-order ladder printed together.",
        "Move on to the smallest live Google manual pass only after the dedicated form-controls gate and the broader shared Enter-order stack stay green together."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google form-controls Enter-order validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Host: {0}" -f $flow.host)
Write-Host ("Shared input text: {0}" -f $flow.shared_input_text)
Write-Host ("Shared Enter-order port: {0}" -f $flow.shared_enter_order_port)
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
Write-Host ""
Write-Host "Next steps:"
foreach ($step in $flow.next_steps) {
    Write-Host ("- {0}" -f $step)
}
