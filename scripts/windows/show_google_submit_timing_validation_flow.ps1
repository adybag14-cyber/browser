[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$SubmitTimingPort = 8181,
    [string]$InputText = "QZ"
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

$surfaceCheck = '.\\scripts\\windows\\check_google_submit_timing_validation_surface.ps1'
$wrapperRunner = '.\\scripts\\windows\\run_google_submit_timing_validation.ps1'
$directProbe = '.\\tmp-browser-smoke\\layout-smoke\\chrome-google-submit-timing-probe.ps1'
$homePhaseRunner = '.\\scripts\\windows\\run_google_input_validation.ps1'
$sharedEnterOrderFlow = '.\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1'
$traceFlow = '.\\scripts\\windows\\show_google_trace_validation_flow.ps1'
$replayShortcuts = '.\\scripts\\windows\\show_google_issue3_replay_shortcuts.ps1'

$surfaceCheckArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $surfaceCheckArgs -Name RepoRoot -Value $RepoRoot

$wrapperArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $wrapperArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $wrapperArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $wrapperArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $wrapperArgs -Name SubmitTimingPort -Value $SubmitTimingPort
Add-SharedArgument -Arguments $wrapperArgs -Name InputText -Value $InputText

$directProbeArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $directProbeArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $directProbeArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $directProbeArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $directProbeArgs -Name Port -Value $SubmitTimingPort
Add-SharedArgument -Arguments $directProbeArgs -Name InputText -Value $InputText

$homePhaseArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $homePhaseArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $homePhaseArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $homePhaseArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $homePhaseArgs -Name Phase -Value 'home'
Add-SharedArgument -Arguments $homePhaseArgs -Name InputText -Value $InputText

$sharedEnterOrderFlowArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedEnterOrderFlowArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedEnterOrderFlowArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $sharedEnterOrderFlowArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $sharedEnterOrderFlowArgs -Name SharedInputText -Value $InputText

$traceFlowArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $traceFlowArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $traceFlowArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $traceFlowArgs -Name InputText -Value $InputText

$replayShortcutsArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $replayShortcutsArgs -Name RepoRoot -Value $RepoRoot

$flow = [ordered]@{
    issue = "Headed Windows Google submit-timing validation flow"
    focus = "Bounded Google-shaped keydown, keypress, and submit ordering on the real headed surface before the broader shared Enter-order or live Google passes."
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the bounded submit-timing guide, helper, wrapper, or raw probe drifted before you trust this narrower issue #3 timing slice."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $surfaceCheck, $(if ($surfaceCheckArgs.Count -gt 0) { " " + ($surfaceCheckArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "wrapper"
            goal = "Run the dedicated submit-timing wrapper first so the bounded timing slice stays on the same reusable command surface as the other issue #3 Windows helpers."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $wrapperRunner, $(if ($wrapperArgs.Count -gt 0) { " " + ($wrapperArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "direct-probe"
            goal = "Run the raw submit-timing probe only when you need to narrow a wrapper failure to the underlying Google-shaped headed click, type, and Enter-order path."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $directProbe, $(if ($directProbeArgs.Count -gt 0) { " " + ($directProbeArgs -join " ") } else { "" }))
        }
    )
    next_steps = @(
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} before this wrapper when you want the reduced headed homepage pass first." -f $homePhaseRunner, $(if ($homePhaseArgs.Count -gt 0) { " " + ($homePhaseArgs -join " ") } else { "" })),
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} after this wrapper is green when you want the stricter shared Enter-order stack printed with the same repo-root, browser, host, and input context." -f $sharedEnterOrderFlow, $(if ($sharedEnterOrderFlowArgs.Count -gt 0) { " " + ($sharedEnterOrderFlowArgs -join " ") } else { "" })),
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} when this bounded timing slice is green but the live Google homepage still diverges." -f $traceFlow, $(if ($traceFlowArgs.Count -gt 0) { " " + ($traceFlowArgs -join " ") } else { "" })),
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} when you want the compact issue #3 replay helper map reopened from this bounded timing slice before switching into attached-page, Windows replay, or safe-route follow-up." -f $replayShortcuts, $(if ($replayShortcutsArgs.Count -gt 0) { " " + ($replayShortcutsArgs -join " ") } else { "" }))
    )
    notes = @(
        "Start with the surface check when you want the bounded submit-timing slice to fail fast on missing guide, helper, wrapper, or raw-probe drift before the broader issue #3 ladder.",
        "Start with the wrapper unless you already know you need the direct probe output files from tmp-browser-smoke/layout-smoke.",
        "Keep the same host, port, and input text here when you want the submit-timing slice aligned with the broader issue #3 flow.",
        "Treat this as the bounded bridge between the reduced homepage pass and the stricter shared Enter-order stack.",
        "The printed handoff commands now preserve the current repo root, custom browser path, host, and input text so the next replay step stays on the same headed-run context.",
        "The printed handoff commands now also preserve the current repo root for the compact replay-shortcuts surface when you need to widen beyond submit timing without rebuilding the issue #3 route by hand."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google submit-timing validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
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
