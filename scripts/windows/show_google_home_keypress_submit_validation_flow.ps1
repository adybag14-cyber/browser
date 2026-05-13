[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$ReducedHomeKeypressPort = 8167,
    [string]$InputText = "lightpanda",
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

$leaveOpenArgument = if ($LeaveOpen) { " -LeaveOpen" } else { "" }
$surfaceCheck = '.\\scripts\\windows\\check_google_home_keypress_submit_validation_surface.ps1'
$wrapperRunner = '.\\scripts\\windows\\run_google_home_keypress_submit_validation.ps1'
$directProbe = '.\\tmp-browser-smoke\\google-home\\chrome-google-home-keypress-submit-probe.ps1'

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
if ($ReducedHomeKeypressPort) {
    $wrapperArguments += " -ReducedHomeKeypressPort $ReducedHomeKeypressPort"
    $directProbeArguments += " -Port $ReducedHomeKeypressPort"
}
if ($InputText) {
    $quotedInputText = ConvertTo-PowerShellSingleQuotedLiteral -Value $InputText
    $wrapperArguments += " -InputText $quotedInputText"
    $directProbeArguments += " -InputText $quotedInputText"
}
if ($LeaveOpen) {
    $wrapperArguments += " -LeaveOpen"
    $directProbeArguments += " -LeaveOpen"
}

$flow = [ordered]@{
    issue = "Headed Windows Google home keypress-submit validation flow"
    focus = "Reduced-home real-surface keypress-before-submit checkpoint after the saved homepage-fixture gate and before the broader later submit-path wrappers."
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the reduced-home keypress-submit note, helper, wrapper, or raw probe drifted before you trust this narrower issue #3 checkpoint."
            command = "powershell -ExecutionPolicy Bypass -File $surfaceCheck"
        }
        [ordered]@{
            name = "wrapper"
            goal = "Run the dedicated reduced-home keypress-submit wrapper first so the real-surface keypress-before-submit checkpoint stays on the same reusable command surface as the neighboring issue #3 Windows helpers."
            command = "powershell -ExecutionPolicy Bypass -File $wrapperRunner$wrapperArguments"
        }
        [ordered]@{
            name = "direct-probe"
            goal = "Run the raw reduced-home keypress-submit probe only when you need to narrow a wrapper failure to the underlying Google-style headed click, type, and Enter-order path."
            command = "powershell -ExecutionPolicy Bypass -File $directProbe$directProbeArguments"
        }
    )
    next_steps = @(
        "Use .\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1 before this wrapper when you want the earlier saved-homepage checkpoint printed first.",
        "Use .\\scripts\\windows\\show_google_submit_path_validation_flow.ps1 after this wrapper is green when you want the broader later-stage saved-homepage, submit-timing, and shared Enter-order ladder printed before you run it.",
        "Use .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1 when you want the narrower bounded timing slice next instead of the full later submit-path ladder."
    )
    notes = @(
        "Start with the surface check when you want the reduced-home keypress-submit checkpoint to fail fast on missing guide, helper, wrapper, or raw-probe drift before the broader later issue #3 ladder.",
        "Start with the wrapper unless you already know you need the direct probe output files from tmp-browser-smoke/google-home.",
        "Keep the same host, port, and input text here when you want the reduced-home keypress-submit checkpoint aligned with the neighboring issue #3 flows.",
        "Treat this as the smaller real-surface bridge between the homepage-fixture checkpoint and the broader later submit-path wrappers."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google home keypress-submit validation flow"
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
