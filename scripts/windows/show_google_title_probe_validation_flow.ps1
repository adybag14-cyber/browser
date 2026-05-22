[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$SharedInputText = "Q",
    [int]$TitleProbePort = 8159,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 80,
    [int]$HomeTitleWaitAttempts = 30,
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

$runner = '.\scripts\windows\run_google_title_probe_validation.ps1'
$rawProbe = '.\tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1'
$sharedFlow = '.\scripts\windows\show_google_shared_enter_order_validation_flow.ps1'
$sharedRunner = '.\scripts\windows\run_google_shared_enter_order_validation.ps1'

$runnerArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $runnerArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $runnerArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $runnerArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $runnerArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $runnerArgs -Name TitleProbePort -Value $TitleProbePort
Add-SharedArgument -Arguments $runnerArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $runnerArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $runnerArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $runnerArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds

$rawProbeArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $rawProbeArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $rawProbeArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $rawProbeArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $rawProbeArgs -Name InputText -Value $SharedInputText
Add-SharedArgument -Arguments $rawProbeArgs -Name Port -Value $TitleProbePort
Add-SharedArgument -Arguments $rawProbeArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $rawProbeArgs -Name WindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $rawProbeArgs -Name TitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $rawProbeArgs -Name PollMilliseconds -Value $HomePollMilliseconds

$sharedFlowArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedFlowArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedFlowArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $sharedFlowArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $sharedFlowArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $sharedFlowArgs -Name TitleProbePort -Value $TitleProbePort
Add-SharedArgument -Arguments $sharedFlowArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $sharedFlowArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $sharedFlowArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $sharedFlowArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds

$sharedRunnerArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedRunnerArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedRunnerArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $sharedRunnerArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $sharedRunnerArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $sharedRunnerArgs -Name TitleProbePort -Value $TitleProbePort
Add-SharedArgument -Arguments $sharedRunnerArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $sharedRunnerArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $sharedRunnerArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $sharedRunnerArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds

$flow = [ordered]@{
    issue = "Headed Windows reduced Google title-probe validation flow"
    focus = "Reopen the smallest bounded Google-style headed check before the wider shared Enter-order ladder or a live Google manual pass."
    host = $Host
    shared_input_text = $SharedInputText
    title_probe_port = $TitleProbePort
    steps = @(
        [ordered]@{
            name = "recommended"
            goal = "Run the one-command wrapper for the reduced Google title probe with the current repo-root, browser path, host, shared input text, title-probe port, and timing settings."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $runner, $(if ($runnerArgs.Count -gt 0) { " " + ($runnerArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "raw-probe"
            goal = "Run the underlying reduced Google title probe directly when you need the exact headed localhost script without the wrapper layer."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $rawProbe, $(if ($rawProbeArgs.Count -gt 0) { " " + ($rawProbeArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "shared-enter-order-flow"
            goal = "Print the broader shared Enter-order ladder after the reduced title probe is green so the next bounded Google-style steps stay aligned with the same context."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $sharedFlow, $(if ($sharedFlowArgs.Count -gt 0) { " " + ($sharedFlowArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "shared-enter-order-runner"
            goal = "Execute the wider shared Enter-order stack once the reduced title probe is no longer the first failing boundary."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $sharedRunner, $(if ($sharedRunnerArgs.Count -gt 0) { " " + ($sharedRunnerArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "manual-google"
            goal = "Widen to the smallest live Google manual pass only after the reduced title probe and the broader shared Enter-order ladder stay green together."
            command = '& ".\zig-out\bin\lightpanda.exe" browse --headed "https://www.google.com/"'
        }
    )
    notes = @(
        "Use this route when issue #3 replay still needs the narrowest Google-style runtime-first checkpoint before the wider shared Enter-order ladder is worth reopening.",
        "Keep SharedInputText aligned with the later shared Enter-order helpers so the reduced title probe and the broader follow-up stack report the same expected query value.",
        "Keep TitleProbePort aligned with the later shared Enter-order flow so the reduced title probe route can be reopened without rebuilding the current bounded context by hand.",
        "Prefer the wrapper command unless you specifically need the raw probe surface for debugging or script-level edits.",
        "Move to the broader shared Enter-order flow before a live Google manual pass whenever the reduced title probe succeeds but the overall replay still needs a tighter failure boundary."
    )
    next_steps = @(
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} when you want the wider shared Enter-order ladder printed with the same repo-root, browser, host, shared input, title-probe port, and timing settings." -f $sharedFlow, $(if ($sharedFlowArgs.Count -gt 0) { " " + ($sharedFlowArgs -join " ") } else { "" })),
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} when you want to execute the wider shared Enter-order stack after the reduced title probe passes." -f $sharedRunner, $(if ($sharedRunnerArgs.Count -gt 0) { " " + ($sharedRunnerArgs -join " ") } else { "" })),
        "Only widen to live Google after both the reduced title probe and the broader shared Enter-order ladder stay green."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows reduced Google title-probe validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Host: {0}" -f $flow.host)
Write-Host ("Shared input text: {0}" -f $flow.shared_input_text)
Write-Host ("Title probe port: {0}" -f $flow.title_probe_port)
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
