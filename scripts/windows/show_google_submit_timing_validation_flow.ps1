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

$surfaceCheck = '.\\scripts\\windows\\check_google_submit_timing_validation_surface.ps1'
$wrapperRunner = '.\\scripts\\windows\\run_google_submit_timing_validation.ps1'
$directProbe = '.\\tmp-browser-smoke\\layout-smoke\\chrome-google-submit-timing-probe.ps1'

$wrapperArguments = ""
$directProbeArguments = ""
if ($RepoRoot) {
    $quotedRepoRoot = ConvertTo-PowerShellSingleQuotedLiteral -Value $RepoRoot
    $wrapperArguments += " -RepoRoot $quotedRepoRoot"
    $directProbeArguments += " -RepoRoot $quotedRepoRoot"
}
if ($BrowserExe) {
    $quotedBrowserExe = ConvertTo-PowerShellSingleQuotedLiteral -Value $BrowserExe
    $wrapperArguments += " -BrowserExe $quotedBrowserExe"
    $directProbeArguments += " -BrowserExe $quotedBrowserExe"
}
if ($Host) {
    $quotedHost = ConvertTo-PowerShellSingleQuotedLiteral -Value $Host
    $wrapperArguments += " -Host $quotedHost"
    $directProbeArguments += " -Host $quotedHost"
}
if ($SubmitTimingPort) {
    $wrapperArguments += " -SubmitTimingPort $SubmitTimingPort"
    $directProbeArguments += " -Port $SubmitTimingPort"
}
if ($InputText) {
    $quotedInputText = ConvertTo-PowerShellSingleQuotedLiteral -Value $InputText
    $wrapperArguments += " -InputText $quotedInputText"
    $directProbeArguments += " -InputText $quotedInputText"
}

$flow = [ordered]@{
    issue = "Headed Windows Google submit-timing validation flow"
    focus = "Bounded Google-shaped keydown, keypress, and submit ordering on the real headed surface before the broader shared Enter-order or live Google passes."
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the bounded submit-timing guide, helper, wrapper, or raw probe drifted before you trust this narrower issue #3 timing slice."
            command = "powershell -ExecutionPolicy Bypass -File $surfaceCheck"
        }
        [ordered]@{
            name = "wrapper"
            goal = "Run the dedicated submit-timing wrapper first so the bounded timing slice stays on the same reusable command surface as the other issue #3 Windows helpers."
            command = "powershell -ExecutionPolicy Bypass -File $wrapperRunner$wrapperArguments"
        }
        [ordered]@{
            name = "direct-probe"
            goal = "Run the raw submit-timing probe only when you need to narrow a wrapper failure to the underlying Google-shaped headed click, type, and Enter-order path."
            command = "powershell -ExecutionPolicy Bypass -File $directProbe$directProbeArguments"
        }
    )
    next_steps = @(
        "Use .\\scripts\\windows\\run_google_input_validation.ps1 -Phase home before this wrapper when you want the reduced headed homepage pass first.",
        "Use .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1 after this wrapper is green when you want the stricter shared Enter-order stack printed before you run it.",
        "Use .\\scripts\\windows\\run_google_input_validation.ps1 -Phase trace when this bounded timing slice is green but the live Google homepage still diverges."
    )
    notes = @(
        "Start with the surface check when you want the bounded submit-timing slice to fail fast on missing guide, helper, wrapper, or raw-probe drift before the broader issue #3 ladder.",
        "Start with the wrapper unless you already know you need the direct probe output files from tmp-browser-smoke/layout-smoke.",
        "Keep the same host, port, and input text here when you want the submit-timing slice aligned with the broader issue #3 flow.",
        "Treat this as the bounded bridge between the reduced homepage pass and the stricter shared Enter-order stack."
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
