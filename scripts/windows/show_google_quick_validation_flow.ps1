[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$InputText = "QZ",
    [int]$TitlePort = 9582,
    [int]$WatchPort = 9582,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 60,
    [int]$HomeTitleWaitAttempts = 80,
    [int]$HomePollMilliseconds = 250,
    [int]$WatchTimeoutSeconds = 90,
    [int]$WatchPollMilliseconds = 250
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

$surfaceCheck = '.\\scripts\\windows\\check_google_quick_validation_surface.ps1'
$titleFlow = '.\\scripts\\windows\\show_google_title_validation_flow.ps1'
$wrapperRunner = '.\\scripts\\windows\\run_google_quick_validation.ps1'
$directQuickRunner = '.\\scripts\\windows\\run_google_input_validation.ps1'
$watchRunner = '.\\scripts\\windows\\run_google_home_watch_probe.ps1'

$wrapperArguments = ""
$directQuickArguments = ""
$watchArguments = ""
if ($RepoRoot) {
    $quotedRepoRoot = ConvertTo-PowerShellSingleQuotedLiteral -Value $RepoRoot
    $wrapperArguments += " -RepoRoot $quotedRepoRoot"
    $directQuickArguments += " -RepoRoot $quotedRepoRoot"
    $watchArguments += " -RepoRoot $quotedRepoRoot"
}
if ($BrowserExe) {
    $quotedBrowserExe = ConvertTo-PowerShellSingleQuotedLiteral -Value $BrowserExe
    $wrapperArguments += " -BrowserExe $quotedBrowserExe"
    $directQuickArguments += " -BrowserExe $quotedBrowserExe"
    $watchArguments += " -BrowserExe $quotedBrowserExe"
}
if ($Host) {
    $quotedHost = ConvertTo-PowerShellSingleQuotedLiteral -Value $Host
    $wrapperArguments += " -Host $quotedHost"
    $directQuickArguments += " -Host $quotedHost"
    $watchArguments += " -Host $quotedHost"
}
if ($InputText) {
    $quotedInputText = ConvertTo-PowerShellSingleQuotedLiteral -Value $InputText
    $wrapperArguments += " -InputText $quotedInputText"
    $directQuickArguments += " -InputText $quotedInputText"
    $watchArguments += " -InputText $quotedInputText"
}
if ($TitlePort) {
    $wrapperArguments += " -TitlePort $TitlePort"
    $directQuickArguments += " -TitlePort $TitlePort"
}
if ($WatchPort) {
    $wrapperArguments += " -WatchPort $WatchPort"
    $directQuickArguments += " -WatchPort $WatchPort"
    $watchArguments += " -Port $WatchPort"
}
if ($ServerReadyTimeoutSeconds) {
    $wrapperArguments += " -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds"
    $directQuickArguments += " -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds"
    $watchArguments += " -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds"
}
if ($HomeWindowReadyAttempts) {
    $wrapperArguments += " -HomeWindowReadyAttempts $HomeWindowReadyAttempts"
}
if ($HomeTitleWaitAttempts) {
    $wrapperArguments += " -HomeTitleWaitAttempts $HomeTitleWaitAttempts"
}
if ($HomePollMilliseconds) {
    $wrapperArguments += " -HomePollMilliseconds $HomePollMilliseconds"
}
if ($WatchTimeoutSeconds) {
    $wrapperArguments += " -WatchTimeoutSeconds $WatchTimeoutSeconds"
    $directQuickArguments += " -WatchTimeoutSeconds $WatchTimeoutSeconds"
    $watchArguments += " -TimeoutSeconds $WatchTimeoutSeconds"
}
if ($WatchPollMilliseconds) {
    $wrapperArguments += " -WatchPollMilliseconds $WatchPollMilliseconds"
    $directQuickArguments += " -WatchPollMilliseconds $WatchPollMilliseconds"
    $watchArguments += " -PollMilliseconds $WatchPollMilliseconds"
}

$flow = [ordered]@{
    issue = "Headed Windows Google quick validation flow"
    focus = "Fast title-plus-watch validation on the real headed surface before the reduced homepage, saved-homepage, submit-timing, or shared Enter-order follow-up."
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the quick-validation note, title flow, wrapper, watch helper, or raw quick phase drifted before you trust the faster issue #3 checkpoint."
            command = "powershell -ExecutionPolicy Bypass -File $surfaceCheck"
        }
        [ordered]@{
            name = "title-flow"
            goal = "Print the narrower title flow first when you want the focus, visible text, and Enter markers mapped before the quick wrapper widens out to the watch phase."
            command = "powershell -ExecutionPolicy Bypass -File $titleFlow"
        }
        [ordered]@{
            name = "wrapper"
            goal = "Run the dedicated quick wrapper so the bounded title-plus-watch slice stays on the same reusable command surface as the neighboring issue #3 helpers."
            command = "powershell -ExecutionPolicy Bypass -File $wrapperRunner$wrapperArguments"
        }
        [ordered]@{
            name = "raw-quick-phase"
            goal = "Run the raw quick phase only when you need to narrow a wrapper failure to the underlying title probe plus watch handoff without the wrapper layer."
            command = "powershell -ExecutionPolicy Bypass -File $directQuickRunner -Phase quick$directQuickArguments"
        }
        [ordered]@{
            name = "watch-only"
            goal = "Run the standalone watch helper when the title pass is already known-good and you only need the shorter live title-stream confirmation."
            command = "powershell -ExecutionPolicy Bypass -File $watchRunner$watchArguments -SendEnter"
        }
    )
    next_steps = @(
        "Use .\\scripts\\windows\\show_google_home_validation_flow.ps1 after this quick slice is green when you want the reduced homepage gate printed before execution.",
        "Use .\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1 when the next question is whether the saved homepage fixture still agrees with the quick headed proof.",
        "Use .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1 when the title and watch phases are green but keydown, keypress, and submit ordering still need a narrower headed check."
    )
    notes = @(
        "Start with the surface check when you want the fast quick slice to fail fast on missing docs, helper scripts, or watch-probe drift before a longer manual run.",
        "Start with the title flow helper when you want the quick wrapper to inherit the same focus, typed-text, and Enter marker meanings as the bounded title checkpoint.",
        "Use the wrapper unless you already know you need the raw quick phase or watch helper by itself.",
        "Keep the same host, title port, input text, and watch timing overrides here when you want the quick slice aligned with the broader issue #3 runner.",
        "Treat this quick slice as the bridge between the bounded title checkpoint and the reduced homepage or saved-homepage follow-up, not as a replacement for those later gates."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google quick validation flow"
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
