[CmdletBinding()]
param(
    [string]$PageRoot,
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
    [int]$Port = 8123,
    [switch]$Json,
    [switch]$LeaveOpen,
    [switch]$ManualGoogleStyle
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
$leaveServerRunningArgument = if ($LeaveOpen) { " -LeaveServerRunning" } else { "" }
$manualGoogleStyleArgument = if ($ManualGoogleStyle) { " -ManualGoogleStyle" } else { "" }

$summaryHelper = '.\\scripts\\windows\\summarize_localhost_html_pages.ps1'
$directHelper = '.\\scripts\\windows\\start_localhost_html_validation.ps1'
$stagedHelper = '.\\scripts\\windows\\start_staged_localhost_html_validation.ps1'
$googleFlowHelper = '.\\scripts\\windows\\show_google_input_validation_flow.ps1'
$googleRunner = '.\\scripts\\windows\\run_google_input_validation.ps1'
$titleFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_title_validation_flow.ps1"
$titleCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_title_validation.ps1"
$quickCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase quick"
$homeCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase home"
$homepageFixtureFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1"
$homepageFixtureCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_homepage_fixture_validation.ps1"
$submitTimingFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1"
$submitTimingCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase submit-timing"
$sharedEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase shared-enter-order"
$fullCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase all -IncludeTitleProbe -IncludeSharedEnterOrder -IncludeWatch$manualGoogleStyleArgument$leaveOpenArgument"
$traceCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase trace$leaveOpenArgument"
$preferredInitialPageArgument = ""
if ($PreferredInitialPage) {
    $quotedPreferredInitialPage = ConvertTo-PowerShellSingleQuotedLiteral -Value $PreferredInitialPage
    $preferredInitialPageArgument = " -PreferredInitialPage $quotedPreferredInitialPage"
}
$manualInitialPageArgument = if ($PreferredInitialPage) {
    " -ManualInitialPage $quotedPreferredInitialPage"
} else {
    ""
}
$launchInitialPageArgument = if ($PreferredInitialPage) {
    " -InitialPage $quotedPreferredInitialPage"
} else {
    ""
}

if ($PageRoot) {
    $quotedPageRoot = ConvertTo-PowerShellSingleQuotedLiteral -Value $PageRoot
    $summaryCommand = "powershell -ExecutionPolicy Bypass -File $summaryHelper -PageRoot $quotedPageRoot -Port $Port$preferredInitialPageArgument"
    $directCommand = "powershell -ExecutionPolicy Bypass -File $directHelper -PageRoot $quotedPageRoot -Port $Port$launchInitialPageArgument -LaunchBrowser -Wait$leaveServerRunningArgument"
} else {
    $summaryCommand = "powershell -ExecutionPolicy Bypass -File $summaryHelper -PageRoot '<saved-page-dir>' -Port $Port -PreferredInitialPage '<preferred-initial-page>'"
    $directCommand = "powershell -ExecutionPolicy Bypass -File $directHelper -PageRoot '<saved-page-dir>' -Port $Port -InitialPage '<preferred-initial-page>' -LaunchBrowser -Wait$leaveServerRunningArgument"
}

if ($InputPath -and $InputPath.Count -gt 0) {
    $quotedPaths = $InputPath | ForEach-Object { ConvertTo-PowerShellSingleQuotedLiteral -Value $_ }
    $joinedPaths = $quotedPaths -join ", "
    $summaryCommand = "powershell -ExecutionPolicy Bypass -File $summaryHelper -InputPath $joinedPaths -Port $Port$preferredInitialPageArgument"
    $stagedCommand = "powershell -ExecutionPolicy Bypass -File $stagedHelper -InputPath $joinedPaths -Port $Port$launchInitialPageArgument -LaunchBrowser -Wait$leaveServerRunningArgument"
    $manualCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase manual -ManualPort $Port$manualInitialPageArgument -ManualInputPath $joinedPaths$manualGoogleStyleArgument$leaveOpenArgument"
    $flowMapCommand = "powershell -ExecutionPolicy Bypass -File $googleFlowHelper -ManualPort $Port$manualInitialPageArgument -ManualInputPath $joinedPaths$manualGoogleStyleArgument$leaveOpenArgument"
    $fullCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase all -IncludeTitleProbe -IncludeSharedEnterOrder -IncludeWatch -ManualPort $Port$manualInitialPageArgument -ManualInputPath $joinedPaths$manualGoogleStyleArgument$leaveOpenArgument"
} elseif ($ManualGoogleStyle) {
    $stagedCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_localhost_validation.ps1 -Port $Port$preferredInitialPageArgument -GoogleStyle -Wait$leaveServerRunningArgument"
    $manualCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase manual -ManualPort $Port$manualInitialPageArgument -ManualGoogleStyle$leaveOpenArgument"
    $flowMapCommand = "powershell -ExecutionPolicy Bypass -File $googleFlowHelper -ManualPort $Port$manualInitialPageArgument -ManualGoogleStyle$leaveOpenArgument"
    $fullCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase all -IncludeTitleProbe -IncludeSharedEnterOrder -IncludeWatch -ManualPort $Port$manualInitialPageArgument -ManualGoogleStyle$leaveOpenArgument"
} else {
    $stagedCommand = "powershell -ExecutionPolicy Bypass -File $stagedHelper -InputPath '<saved-html-or-folder>' -Port $Port -InitialPage '<preferred-initial-page>' -LaunchBrowser -Wait$leaveServerRunningArgument"
    $manualCommand = "powershell -ExecutionPolicy Bypass -File $googleRunner -Phase manual -ManualPort $Port -ManualInitialPage '<preferred-initial-page>' -ManualInputPath '<saved-html-or-folder>'$leaveOpenArgument"
    $flowMapCommand = "powershell -ExecutionPolicy Bypass -File $googleFlowHelper -ManualPort $Port -ManualInitialPage '<preferred-initial-page>' -ManualInputPath '<saved-html-or-folder>'$leaveOpenArgument"
}

$flow = [ordered]@{
    issue = "Google-style saved page follow-up"
    focus = "Route saved or attached localhost HTML pages through the bounded Google headed-input gates before the manual headed pass, then expose the dedicated title flow, bounded title wrapper, fast quick pass, reduced homepage headed pass, saved homepage fixture pass, read-first submit-timing flow, bounded submit-timing pass, one-shot full pass, and live trace path when real Google still diverges."
    preferred_initial_page = $PreferredInitialPage
    manual_google_style = [bool]$ManualGoogleStyle
    leave_open = [bool]$LeaveOpen
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
            name = "google-title-flow"
            goal = "Print the dedicated title wrapper flow when you want the bounded readiness, click-focus, typed-text, and Enter-submit path spelled out before you run it."
            command = $titleFlowCommand
        }
        [ordered]@{
            name = "google-title"
            goal = "Run the dedicated title wrapper so the bounded readiness, click-focus, typed-text, and Enter-submit markers stay on a smaller reusable validation surface before the reduced homepage or saved-page manual follow-up."
            command = $titleCommand
        }
        [ordered]@{
            name = "google-quick"
            goal = "Run the fast title-plus-watch first pass before the reduced homepage or saved-page manual follow-up."
            command = $quickCommand
        }
        [ordered]@{
            name = "google-home"
            goal = "Run the reduced headed homepage Enter-submit pass before the saved homepage fixture, shared, or saved-page manual follow-up."
            command = $homeCommand
        }
        [ordered]@{
            name = "google-homepage-fixture-flow"
            goal = "Print the saved homepage fixture wrapper flow when you want the bounded localhost copy of the captured Google homepage spelled out before execution."
            command = $homepageFixtureFlowCommand
        }
        [ordered]@{
            name = "google-homepage-fixture"
            goal = "Run the saved homepage fixture wrapper before the shared gates or saved-page manual follow-up when you want the bounded localhost copy of the captured Google homepage in the same issue #3 order."
            command = $homepageFixtureCommand
        }
        [ordered]@{
            name = "google-submit-timing-flow"
            goal = "Print the bounded Google-shaped submit-timing wrapper flow when you want that keydown, keypress, and submit-ordering slice spelled out before execution."
            command = $submitTimingFlowCommand
        }
        [ordered]@{
            name = "google-submit-timing"
            goal = "Run the bounded Google-shaped submit-timing pass before the shared gates or saved-page manual follow-up."
            command = $submitTimingCommand
        }
        [ordered]@{
            name = "google-shared"
            goal = "Run the nearest shared submit and Enter-order gates before the saved-page manual follow-up."
            command = $sharedEnterOrderCommand
        }
        [ordered]@{
            name = "google-full"
            goal = "Run the one-shot localhost-first Google validation pass with the quick title, reduced homepage submit, bounded submit-timing, shared Enter-order, and watch phases folded in, and keep the same saved-page manual inputs when they are already supplied."
            command = $fullCommand
        }
        [ordered]@{
            name = "google-manual"
            goal = if ($ManualGoogleStyle) {
                "Stage or auto-discover attached Google-style pages and drive them through the Google runner's manual phase."
            } else {
                "Stage or reuse the saved pages and drive them through the Google runner's manual phase."
            }
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
            goal = if ($ManualGoogleStyle) {
                "Auto-discover attached Google-style pages for the same localhost follow-up when you want the helper to pick the first Google-like page for you."
            } else {
                "Stage mixed standalone HTML files and folders into one localhost session for the same follow-up."
            }
            command = $stagedCommand
        }
        [ordered]@{
            name = "flow-map"
            goal = "Print the broader Google validation flow when you need the full localhost, title, reduced-homepage, saved-homepage-fixture, submit-timing, watch, and trace sequence."
            command = $flowMapCommand
        }
    )
    notes = @(
        "Use this helper when the saved or attached HTML pages look like search-box, delayed-readiness, or Enter-submit investigations related to headed Google-style behavior.",
        "Run the reduced localhost, title, quick, reduced homepage, saved homepage fixture, and bounded submit-timing phases before treating a saved-page manual pass as evidence for issue #3.",
        "Use google-title-flow when you want the dedicated title wrapper and raw probe handoff printed before you run that narrower slice.",
        "Use google-home after google-quick when you want the bounded real-surface Enter path before the saved homepage fixture, submit-timing pass, shared gates, or saved-page manual pass.",
        "Use google-homepage-fixture-flow when the next question is whether the bounded localhost copy of the captured Google homepage still matches the reduced headed flow before you widen into broader saved-page or attached-page follow-up.",
        "Use google-submit-timing-flow when you want the bounded Google-shaped keydown, keypress, and submit-ordering wrapper printed before the shared or saved-page manual follow-up.",
        "Use google-shared for the stricter Enter-order wrapper when you want the shared label-click baseline and shared submit gates ahead of the saved-page manual pass.",
        "Use google-full when you want the runner's built-in localhost-first order, quick title pass, reduced homepage pass, bounded submit-timing pass, shared Enter-order wrapper, and watch phase in one command, and keep the same saved-page manual follow-up attached when InputPath is already supplied.",
        "Use google-trace after google-manual when the saved pages behave but the real Google homepage still diverges, so the next evidence comes from the live headed path instead of another saved-page rerun.",
        "When PreferredInitialPage is set, the inventory, direct, staged, Google manual, and broader flow-map commands keep that page as the first headed target instead of falling back to a generated index or another arbitrary file.",
        "When InputPath is provided, the broader flow-map command also preserves the same manual port, initial page, and saved-page inputs for the next printed handoff.",
        "When ManualGoogleStyle is set, the Google manual, Google full, staged-headed, and broader flow-map commands auto-discover current-run attached HTML under user_files first and then agent_files, and they prefer a Google-like attached page when PreferredInitialPage is not set.",
        "When LeaveOpen is set, the printed Google manual, Google full, Google trace, direct-headed, and staged-headed commands keep the browser or localhost session open so you can inspect the same headed state after the bounded automation phases finish.",
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
if ($PreferredInitialPage) {
    Write-Host ("Preferred initial page: {0}" -f $PreferredInitialPage)
}
Write-Host ("Manual Google-style attached follow-up: {0}" -f ([bool]$ManualGoogleStyle))
Write-Host ("Leave open after bounded phases: {0}" -f ([bool]$LeaveOpen))
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
