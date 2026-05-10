[CmdletBinding()]
param(
    [string]$PageRoot,
    [string[]]$InputPath,
    [int]$Port = 8123,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$summaryHelper = '.\\scripts\\windows\\summarize_localhost_html_pages.ps1'
$directHelper = '.\\scripts\\windows\\start_localhost_html_validation.ps1'
$stagedHelper = '.\\scripts\\windows\\start_staged_localhost_html_validation.ps1'
$googleFlowHelper = '.\\scripts\\windows\\show_google_input_validation_flow.ps1'
$googleRunner = '.\\scripts\\windows\\run_google_input_validation.ps1'
$traceCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase trace"

if ($PageRoot) {
    $summaryCommand = "powershell -ExecutionPolicy Bypass -File $summaryHelper -PageRoot '$PageRoot' -Port $Port"
    $directCommand = "powershell -ExecutionPolicy Bypass -File $directHelper -PageRoot '$PageRoot' -Port $Port -LaunchBrowser -Wait"
} else {
    $summaryCommand = "powershell -ExecutionPolicy Bypass -File $summaryHelper -PageRoot '<saved-page-dir>' -Port $Port"
    $directCommand = "powershell -ExecutionPolicy Bypass -File $directHelper -PageRoot '<saved-page-dir>' -Port $Port -LaunchBrowser -Wait"
}

if ($InputPath -and $InputPath.Count -gt 0) {
    $quotedPaths = $InputPath | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }
    $joinedPaths = $quotedPaths -join ", "
    $stagedCommand = "powershell -ExecutionPolicy Bypass -File $stagedHelper -InputPath $joinedPaths -Port $Port -LaunchBrowser -Wait"
    $manualCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase manual -ManualPort $Port -ManualInputPath $joinedPaths"
} else {
    $stagedCommand = "powershell -ExecutionPolicy Bypass -File $stagedHelper -InputPath '<saved-html-or-folder>' -Port $Port -LaunchBrowser -Wait"
    $manualCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase manual -ManualPort $Port -ManualInputPath '<saved-html-or-folder>'"
}

$flow = [ordered]@{
    issue = "Google-style saved page follow-up"
    focus = "Route saved or attached localhost HTML pages through the bounded Google headed-input gates before the manual headed pass, then expose the live trace path when real Google still diverges."
    steps = @(
        [ordered]@{
            name = "inventory"
            goal = "Summarize the saved page set, surface the likely bounded suites, and pick the first page to open."
            command = $summaryCommand
        }
        [ordered]@{
            name = "google-localhost"
            goal = "Run the reduced localhost Google-style probes before any saved-page manual pass."
            command = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase localhost"
        }
        [ordered]@{
            name = "google-shared"
            goal = "Run the nearest shared submit and Enter-order gates before the saved-page manual follow-up."
            command = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase shared-enter-order"
        }
        [ordered]@{
            name = "google-manual"
            goal = "Stage or reuse the saved pages and drive them through the Google runner's manual phase."
            command = $manualCommand
        }
        [ordered]@{
            name = "google-trace"
            goal = "Capture the live Google homepage trace after the saved-page manual pass when the bounded phases are green but the real homepage still diverges."
            command = $traceCommand
        }
        [ordered]@{
            name = "direct-headed"
            goal = "Open a single saved-page directory directly in the headed browser when you want a plain manual browse after the bounded gates are green."
            command = $directCommand
        }
        [ordered]@{
            name = "staged-headed"
            goal = "Stage mixed standalone HTML files and folders into one localhost session for the same follow-up."
            command = $stagedCommand
        }
        [ordered]@{
            name = "flow-map"
            goal = "Print the broader Google validation flow when you need the full localhost, reduced-homepage, watch, and trace sequence."
            command = "powershell -ExecutionPolicy Bypass -File $googleFlowHelper"
        }
    )
    notes = @(
        "Use this helper when the saved or attached HTML pages look like search-box, delayed-readiness, or Enter-submit investigations related to headed Google-style behavior.",
        "Run the reduced localhost and shared Enter-order phases before treating a saved-page manual pass as evidence for issue #3.",
        "Use google-trace after google-manual when the saved pages behave but the real Google homepage still diverges, so the next evidence comes from the live headed path instead of another saved-page rerun.",
        "Use direct-headed when the saved pages already live in one clean directory, and staged-headed when they are spread across standalone files or folders."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Google-style saved page follow-up"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
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
