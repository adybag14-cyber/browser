[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$FixturePort = 8155,
    [string]$InputText = "Q",
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 60,
    [int]$HomeTitleWaitAttempts = 80,
    [int]$HomePollMilliseconds = 250,
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

$wrapperRunner = '.\\scripts\\windows\\run_google_homepage_fixture_validation.ps1'
$directProbe = '.\\tmp-browser-smoke\\form-controls\\chrome-google-homepage-probe.ps1'

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
if ($FixturePort) {
    $wrapperArguments += " -FixturePort $FixturePort"
    $directProbeArguments += " -Port $FixturePort"
}
if ($InputText) {
    $quotedInputText = ConvertTo-PowerShellSingleQuotedLiteral -Value $InputText
    $wrapperArguments += " -InputText $quotedInputText"
    $directProbeArguments += " -InputText $quotedInputText"
}
if ($ServerReadyTimeoutSeconds) {
    $wrapperArguments += " -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds"
    $directProbeArguments += " -ServerReadyTimeoutSeconds $ServerReadyTimeoutSeconds"
}
if ($HomeWindowReadyAttempts) {
    $wrapperArguments += " -HomeWindowReadyAttempts $HomeWindowReadyAttempts"
    $directProbeArguments += " -HomeWindowReadyAttempts $HomeWindowReadyAttempts"
}
if ($HomeTitleWaitAttempts) {
    $wrapperArguments += " -HomeTitleWaitAttempts $HomeTitleWaitAttempts"
    $directProbeArguments += " -HomeTitleWaitAttempts $HomeTitleWaitAttempts"
}
if ($HomePollMilliseconds) {
    $wrapperArguments += " -HomePollMilliseconds $HomePollMilliseconds"
    $directProbeArguments += " -HomePollMilliseconds $HomePollMilliseconds"
}
if ($LeaveOpen) {
    $wrapperArguments += " -LeaveOpen"
}

$flow = [ordered]@{
    issue = "Headed Windows Google homepage fixture validation flow"
    focus = "Bounded saved Google homepage fixture validation on the real headed surface so issue #3 can reuse a localhost page that still proves focus, typed text, and Enter submit before broader manual replay."
    steps = @(
        [ordered]@{
            name = "wrapper"
            goal = "Run the dedicated homepage fixture wrapper first so the saved Google-style headed pass stays on the same reusable command surface as the other issue #3 Windows helpers."
            command = "powershell -ExecutionPolicy Bypass -File $wrapperRunner$wrapperArguments"
        }
        [ordered]@{
            name = "direct-probe"
            goal = "Run the raw saved homepage fixture probe only when you need to narrow a wrapper failure to the underlying localhost server, focus, type, and Enter-submit path."
            command = "powershell -ExecutionPolicy Bypass -File $directProbe$directProbeArguments"
        }
    )
    next_steps = @(
        "Use .\\scripts\\windows\\run_google_home_validation.ps1 before this helper when you want the reduced headed homepage pass first.",
        "Use .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1 after this helper is green when you want the bounded Google-shaped submit-ordering slice printed before you run it.",
        "Use .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1 after this helper is green when you want the stricter shared Enter-order stack printed before you run it."
    )
    notes = @(
        "Start with the wrapper unless you already know you need the direct probe output files from tmp-browser-smoke/form-controls.",
        "Keep the same host, fixture port, input text, and timing overrides here when you want the saved homepage fixture slice aligned with the broader issue #3 flow.",
        "Use -LeaveOpen when you want the wrapper to keep the headed browser open after the bounded phases finish so the live fixture state is easier to inspect."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google homepage fixture validation flow"
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
