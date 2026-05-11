[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$LocalhostPort = 8176,
    [int]$CorrectionPort = 8177,
    [int]$DelayedReadyPort = 8178,
    [int]$EnterOrderPort = 8180,
    [int]$ReducedHomeTracePort = 8164,
    [string]$InputText = "Q",
    [string]$CorrectionInputText = "QZ",
    [string]$DelayedReadyInputText = "Q",
    [string]$TraceInputText = "lightpanda"
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

$surfaceCheck = '.\\scripts\\windows\\check_google_investigation_next_validation_surface.ps1'
$basicProbe = '.\\tmp-browser-smoke\\google-investigation-next\\google-style-localhost-probe.ps1'
$correctionProbe = '.\\tmp-browser-smoke\\google-investigation-next\\google-style-correction-localhost-probe.ps1'
$enterOrderProbe = '.\\tmp-browser-smoke\\google-investigation-next\\google-enter-order-localhost-probe.ps1'
$delayedReadyProbe = '.\\tmp-browser-smoke\\google-investigation-next\\google-style-delayed-ready-localhost-probe.ps1'
$reducedHomeTraceProbe = '.\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-enter-trace-probe.ps1'
$liveHomeTraceProbe = '.\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-input-probe.ps1'

$commonArguments = ""
if ($RepoRoot) {
    $commonArguments += " -RepoRoot $(ConvertTo-PowerShellSingleQuotedLiteral -Value $RepoRoot)"
}
if ($BrowserExe) {
    $commonArguments += " -BrowserExe $(ConvertTo-PowerShellSingleQuotedLiteral -Value $BrowserExe)"
}
if ($Host) {
    $commonArguments += " -Host $(ConvertTo-PowerShellSingleQuotedLiteral -Value $Host)"
}

$basicArguments = "$commonArguments -Port $LocalhostPort -InputText $(ConvertTo-PowerShellSingleQuotedLiteral -Value $InputText)"
$correctionArguments = "$commonArguments -Port $CorrectionPort -InputText $(ConvertTo-PowerShellSingleQuotedLiteral -Value $CorrectionInputText)"
$enterOrderArguments = "$commonArguments -Port $EnterOrderPort -InputText $(ConvertTo-PowerShellSingleQuotedLiteral -Value $InputText)"
$delayedReadyArguments = "$commonArguments -Port $DelayedReadyPort -InputText $(ConvertTo-PowerShellSingleQuotedLiteral -Value $DelayedReadyInputText)"
$reducedTraceArguments = "$commonArguments -Port $ReducedHomeTracePort -InputText $(ConvertTo-PowerShellSingleQuotedLiteral -Value $TraceInputText)"
$liveTraceArguments = "$commonArguments -InputText $(ConvertTo-PowerShellSingleQuotedLiteral -Value $TraceInputText)"

$flow = [ordered]@{
    issue = "Headed Windows google-investigation-next validation flow"
    focus = "Reduced localhost Google-style probes first, then the smaller real-surface trace checkpoints, before the broader issue #3 title, shared Enter-order, attached-HTML, or live Google follow-up."
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the reduced Google investigation guide, helper, probe, or fixture set drifted before you trust this bounded localhost suite."
            command = "powershell -ExecutionPolicy Bypass -File $surfaceCheck"
        }
        [ordered]@{
            name = "basic-localhost"
            goal = "Verify the baseline Google-style named-form focus churn, typed text, and Enter submit path on localhost first."
            command = "powershell -ExecutionPolicy Bypass -File $basicProbe$basicArguments"
        }
        [ordered]@{
            name = "correction-localhost"
            goal = "Verify multi-character entry, correction, and Enter submit survive the same Google-style focus churn path."
            command = "powershell -ExecutionPolicy Bypass -File $correctionProbe$correctionArguments"
        }
        [ordered]@{
            name = "enter-order-localhost"
            goal = "Verify the bounded localhost form waits for the keypress-phase mutation before submit so keydown-submit regressions stay isolated."
            command = "powershell -ExecutionPolicy Bypass -File $enterOrderProbe$enterOrderArguments"
        }
        [ordered]@{
            name = "delayed-ready-localhost"
            goal = "Verify the headed path can survive a delayed readiness gate before typing and submit."
            command = "powershell -ExecutionPolicy Bypass -File $delayedReadyProbe$delayedReadyArguments"
        }
        [ordered]@{
            name = "reduced-home-trace"
            goal = "Capture the reduced homepage real-surface trace after the localhost probes are green but before widening to the live homepage."
            command = "powershell -ExecutionPolicy Bypass -File $reducedHomeTraceProbe$reducedTraceArguments"
        }
        [ordered]@{
            name = "live-home-trace"
            goal = "Capture the live Google homepage trace only after the reduced localhost and reduced-home checkpoints are green."
            command = "powershell -ExecutionPolicy Bypass -File $liveHomeTraceProbe$liveTraceArguments"
        }
    )
    next_steps = @(
        "Use .\\scripts\\windows\\show_google_title_validation_flow.ps1 when you want the narrower title-wrapper ladder printed before you widen into the title checkpoint.",
        "Use .\\scripts\\windows\\run_google_issue3_recommended_validation.ps1 when you want the same reduced localhost suite plus the title, reduced-homepage, saved-homepage, submit-timing, shared Enter-order, and watch phases on one runner.",
        "Use .\\scripts\\windows\\show_google_trace_validation_flow.ps1 when the reduced-home trace is green and you want the later live Google trace handoff printed before another capture."
    )
    notes = @(
        "Start with the surface check whenever the branch moved recently and you want the reduced Google investigation suite to fail fast on missing helpers or fixtures.",
        "Keep the same host and ports here when you want the bounded localhost probes aligned with the broader issue #3 runner and its follow-up trace helpers.",
        "Use reduced-home-trace before live-home-trace so the smaller real-surface checkpoint still exists if the live Google homepage adds timing noise or challenge-page divergence.",
        "Treat this suite as the smallest reusable Google-style localhost gate before the title wrapper, submit-timing slice, shared Enter-order ladder, attached-page follow-up, or live homepage investigation."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows google-investigation-next validation flow"
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
