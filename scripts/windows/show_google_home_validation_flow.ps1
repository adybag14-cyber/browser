[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$Port = 8168,
    [string]$InputText = "QZ",
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$WindowReadyAttempts = 60,
    [int]$TitleWaitAttempts = 80,
    [int]$PollMilliseconds = 250
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

$surfaceCheck = '.\\scripts\\windows\\check_google_home_validation_surface.ps1'
$quickFlow = '.\\scripts\\windows\\show_google_quick_validation_flow.ps1'
$wrapperRunner = '.\\scripts\\windows\\run_google_home_validation.ps1'
$directHomeRunner = '.\\scripts\\windows\\run_google_input_validation.ps1'
$directProbe = '.\\tmp-browser-smoke\\google-home\\chrome-google-home-enter-probe.ps1'
$readFirstGuide = 'docs/GOOGLE_HOME_VALIDATION.md'

$wrapperArguments = ""
$directHomeArguments = ""
$directProbeArguments = ""
if ($RepoRoot) {
    $quotedRepoRoot = ConvertTo-PowerShellSingleQuotedLiteral -Value $RepoRoot
    $wrapperArguments += " -RepoRoot $quotedRepoRoot"
    $directHomeArguments += " -RepoRoot $quotedRepoRoot"
    $directProbeArguments += " -RepoRoot $quotedRepoRoot"
}
if ($BrowserExe) {
    $quotedBrowserExe = ConvertTo-PowerShellSingleQuotedLiteral -Value $BrowserExe
    $wrapperArguments += " -BrowserExe $quotedBrowserExe"
    $directHomeArguments += " -BrowserExe $quotedBrowserExe"
    $directProbeArguments += " -BrowserExe $quotedBrowserExe"
}
if ($Host) {
    $quotedHost = ConvertTo-PowerShellSingleQuotedLiteral -Value $Host
    $wrapperArguments += " -Host $quotedHost"
    $directHomeArguments += " -Host $quotedHost"
    $directProbeArguments += " -Host $quotedHost"
}
if ($Port) {
    $wrapperArguments += " -Port $Port"
    $directHomeArguments += " -HomePort $Port"
    $directProbeArguments += " -Port $Port"
}
if ($InputText) {
    $quotedInputText = ConvertTo-PowerShellSingleQuotedLiteral -Value $InputText
    $wrapperArguments += " -InputText $quotedInputText"
    $directHomeArguments += " -InputText $quotedInputText"
    $directProbeArguments += " -InputText $quotedInputText"
}
if ($ServerReadyTimeoutSeconds) {
    $wrapperArguments += " -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds"
    $directHomeArguments += " -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds"
    $directProbeArguments += " -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds"
}
if ($WindowReadyAttempts) {
    $wrapperArguments += " -WindowReadyAttempts $WindowReadyAttempts"
    $directProbeArguments += " -WindowReadyAttempts $WindowReadyAttempts"
}
if ($TitleWaitAttempts) {
    $wrapperArguments += " -TitleWaitAttempts $TitleWaitAttempts"
    $directProbeArguments += " -TitleWaitAttempts $TitleWaitAttempts"
}
if ($PollMilliseconds) {
    $wrapperArguments += " -PollMilliseconds $PollMilliseconds"
    $directProbeArguments += " -PollMilliseconds $PollMilliseconds"
}

$flow = [ordered]@{
    issue = "Headed Windows Google reduced homepage validation flow"
    focus = "Smallest real-surface reduced homepage proof for issue #3 after the quicker title-plus-watch gate is green."
    read_first_guide = $readFirstGuide
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the reduced-homepage note, quick handoff, wrapper, or raw homepage probe drifted before you trust this headed checkpoint."
            command = "powershell -ExecutionPolicy Bypass -File $surfaceCheck"
        }
        [ordered]@{
            name = "quick-handoff"
            goal = "Print the quicker title-plus-watch flow first when you want the smaller headed checkpoint sequence laid out before the reduced homepage wrapper."
            command = "powershell -ExecutionPolicy Bypass -File $quickFlow"
        }
        [ordered]@{
            name = "wrapper"
            goal = "Run the dedicated reduced-homepage wrapper so the real-surface Google-home gate stays on the same reusable command surface as the other issue #3 helpers."
            command = "powershell -ExecutionPolicy Bypass -File $wrapperRunner$wrapperArguments"
        }
        [ordered]@{
            name = "raw-home-phase"
            goal = "Run the raw home phase only when you need to narrow a wrapper failure to the underlying reduced homepage phase inside the general issue #3 runner."
            command = "powershell -ExecutionPolicy Bypass -File $directHomeRunner -Phase home$directHomeArguments"
        }
        [ordered]@{
            name = "direct-probe"
            goal = "Run the raw reduced-homepage probe only when you need the exact headed fixture entrypoint without the wrapper or broader runner layer."
            command = "powershell -ExecutionPolicy Bypass -File $directProbe$directProbeArguments"
        }
    )
    next_steps = @(
        "Use .\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1 when this reduced homepage gate is green and the next question is whether the saved homepage fixture still agrees.",
        "Use .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1 when this gate is green but keydown, keypress, and submit ordering still need a tighter headed check.",
        "Use .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1 when the reduced homepage gate is green and you want the stricter shared Enter-order ladder printed before you run it."
    )
    notes = @(
        "Start with the surface check when you want the reduced-homepage gate to fail fast on missing notes, helper scripts, or raw probe drift before manual or live replay.",
        "Use the quick-handoff helper when you want the faster title-plus-watch gate printed in front of this real-surface homepage checkpoint.",
        "Use the wrapper unless you already know you need the raw home phase or the direct raw probe by itself.",
        "Keep the same host, port, input text, and timing overrides here when you want the reduced-homepage gate aligned with the broader issue #3 runner.",
        "Treat this as the smallest real-surface homepage proof before widening to the saved homepage fixture, submit timing, shared Enter order, attached HTML, or live Google follow-up."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google reduced homepage validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Guide: {0}" -f $flow.read_first_guide)
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
