[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$LeaveOpen,
    [string[]]$ManualInputPath,
    [string]$ManualInitialPage,
    [int]$ManualPort = 8123,
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
$manualGoogleStyleArgument = if ($ManualGoogleStyle) { " -ManualGoogleStyle" } else { "" }

$runner = '.\\scripts\\windows\\run_google_input_validation.ps1'
$recommendedRunner = '.\\scripts\\windows\\run_google_issue3_recommended_validation.ps1'
$titleRunner = '.\\scripts\\windows\\run_google_title_validation.ps1'
$surfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_validation_surface.ps1"
$surfaceCheckAttachedCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_validation_surface.ps1 -Profile attached-html"
$titleFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_title_validation_flow.ps1"
$localhostCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase localhost"
$titleCommand = "powershell -ExecutionPolicy Bypass -File $titleRunner"
$quickFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_quick_validation_flow.ps1$leaveOpenArgument"
$quickCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_quick_validation.ps1$leaveOpenArgument"
$homeCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase home"
$homepageFixtureFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1$leaveOpenArgument"
$homepageFixtureCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_homepage_fixture_validation.ps1$leaveOpenArgument"
$submitPathCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_submit_path_validation.ps1"
$submitTimingFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1"
$submitTimingCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_submit_timing_validation.ps1"
$sharedCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase shared"
$sharedEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase shared-enter-order"
$traceCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase trace$leaveOpenArgument"
$watchCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase watch$leaveOpenArgument"
$fullCommand = "powershell -ExecutionPolicy Bypass -File $recommendedRunner$manualGoogleStyleArgument$leaveOpenArgument"

$quotedManualInitialPage = $null
$manualInitialPageArgument = ""
$attachedGoogleInitialPageArgument = ""
if ($ManualInitialPage) {
    $quotedManualInitialPage = ConvertTo-PowerShellSingleQuotedLiteral -Value $ManualInitialPage
    $manualInitialPageArgument = " -ManualInitialPage $quotedManualInitialPage"
    $attachedGoogleInitialPageArgument = " -PreferredInitialPage $quotedManualInitialPage"
}

$attachedGoogleFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1$attachedGoogleInitialPageArgument$leaveOpenArgument"
$attachedGoogleCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_attached_html_validation.ps1$attachedGoogleInitialPageArgument -Wait"

$manualCommand = $null
if ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
    $quotedPaths = $ManualInputPath | ForEach-Object { ConvertTo-PowerShellSingleQuotedLiteral -Value $_ }
    $manualPathsArgument = " -ManualInputPath " + ($quotedPaths -join ", ")
    $manualCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase manual -ManualPort $ManualPort$manualInitialPageArgument$manualPathsArgument$manualGoogleStyleArgument$leaveOpenArgument"
    $fullCommand = "powershell -ExecutionPolicy Bypass -File $recommendedRunner -ManualPort $ManualPort$manualInitialPageArgument$manualPathsArgument$manualGoogleStyleArgument$leaveOpenArgument"
} elseif ($ManualGoogleStyle) {
    $manualCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase manual -ManualPort $ManualPort$manualInitialPageArgument -ManualGoogleStyle$leaveOpenArgument"
    $fullCommand = "powershell -ExecutionPolicy Bypass -File $recommendedRunner -ManualPort $ManualPort$manualInitialPageArgument -ManualGoogleStyle$leaveOpenArgument"
}

$flow = [ordered]@{
    issue = "Headed Windows Google input validation flow"
    focus = "Issue #3 first-pass validation order for the validation-surface checker, reduced localhost probes, the narrower title-flow helper, title readiness, the dedicated quick-flow helper, the fast title-plus-watch pass, reduced homepage submit, the saved homepage fixture checkpoint, the dedicated later-stage submit-path runner, the dedicated submit-timing flow helper, the bounded Google-shaped submit-timing pass through its wrapper, the shared label-click baseline plus submit gates, the stricter shared Enter-order wrapper, the dedicated attached-Google flow and runner for current attached HTML pages, live Google trace capture, watch mode, and saved-page localhost follow-up."
    manual_initial_page = $ManualInitialPage
    manual_google_style = [bool]$ManualGoogleStyle
    leave_open = [bool]$LeaveOpen
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if a linked issue #3 guide or helper drifted out of sync before any broader validation pass."
            command = $surfaceCheckCommand
        }
        [ordered]@{
            name = "localhost"
            goal = "Run the reduced localhost Google-style probes before any real-surface homepage pass."
            command = $localhostCommand
        }
        [ordered]@{
            name = "title-flow"
            goal = "Print the narrower dedicated title wrapper flow when you want the bounded readiness, click-focus, typed-text, and Enter-submit path spelled out before you run it."
            command = $titleFlowCommand
        }
        [ordered]@{
            name = "title"
            goal = "Run the dedicated title wrapper so the bounded readiness, click-focus, typed-text, and Enter-submit markers stay on a smaller reusable validation surface."
            command = $titleCommand
        }
        [ordered]@{
            name = "quick-flow"
            goal = "Print the dedicated quick helper flow when you want the fast title-plus-watch stack spelled out before you run it."
            command = $quickFlowCommand
        }
        [ordered]@{
            name = "quick"
            goal = "Run the fast first pass through the dedicated quick wrapper so the title probe and self-starting watch phase stay on one reusable command surface."
            command = $quickCommand
        }
        [ordered]@{
            name = "home"
            goal = "Run the reduced homepage Enter-submit pass on the headed surface."
            command = $homeCommand
        }
        [ordered]@{
            name = "homepage-fixture-flow"
            goal = "Print the saved homepage fixture helper flow when you want the bounded localhost Google snapshot, focus, typed-text, and Enter-submit checkpoint spelled out before you run it."
            command = $homepageFixtureFlowCommand
        }
        [ordered]@{
            name = "homepage-fixture"
            goal = "Run the bounded saved Google homepage fixture wrapper so the recommended issue #3 flow gains one more controlled checkpoint between the reduced homepage pass and the broader submit-timing slice."
            command = $homepageFixtureCommand
        }
        [ordered]@{
            name = "submit-path"
            goal = "Run the dedicated later-stage issue #3 wrapper when the earlier title and reduced-homepage gates are already green and you want the saved homepage fixture, bounded submit-timing, and shared Enter-order slices on one narrower command surface."
            command = $submitPathCommand
        }
        [ordered]@{
            name = "submit-timing-flow"
            goal = "Print the dedicated submit-timing wrapper flow when you want the bounded Google-shaped keydown, keypress, and submit-ordering slice spelled out before you run it."
            command = $submitTimingFlowCommand
        }
        [ordered]@{
            name = "submit-timing"
            goal = "Run the bounded Google-shaped timing probe through the dedicated submit-timing wrapper so typed text plus keydown,keypress,submit ordering stay on one reusable command surface."
            command = $submitTimingCommand
        }
        [ordered]@{
            name = "shared"
            goal = "Run the shared label-click baseline plus the nearest shared submit gates before the stricter Enter-order wrapper or any live Google manual pass."
            command = $sharedCommand
        }
        [ordered]@{
            name = "shared-enter-order"
            goal = "Run the shared label baseline, submit gates, and the stricter localhost keypress-before-submit wrapper through the same main runner entrypoint."
            command = $sharedEnterOrderCommand
        }
        [ordered]@{
            name = "attached-google-flow"
            goal = "Print the attached Google-style helper flow when you want the current run's attached HTML pages auto-discovered and mapped onto the same localhost-first issue #3 order before the broader manual follow-up."
            command = $attachedGoogleFlowCommand
        }
        [ordered]@{
            name = "attached-google"
            goal = "Auto-discover current-run attached Google-like pages and launch them through the same Google-style localhost follow-up before the broader manual or live Google pass."
            command = $attachedGoogleCommand
        }
        [ordered]@{
            name = "trace"
            goal = "Capture the live Google homepage trace through the same runner once the bounded localhost phases are green but the real homepage still diverges."
            command = $traceCommand
        }
        [ordered]@{
            name = "watch"
            goal = "Re-run the self-starting watcher when you need live title-stream confirmation like SUBMIT:QZ."
            command = $watchCommand
        }
        [ordered]@{
            name = "full"
            goal = "Run the localhost-first issue #3 recommended runner in one pass so the reduced title phase, reduced homepage pass, saved homepage fixture checkpoint, dedicated submit-path stage, bounded submit-timing slice, shared label baseline, shared Enter-order wrapper, attached Google helper handoff, and watcher stay on one reusable command surface before the broader manual follow-up."
            command = $fullCommand
        }
    )
    saved_page_follow_up = if ($manualCommand) {
        [ordered]@{
            goal = if ($ManualGoogleStyle) {
                "Compare the attached or saved localhost pages against the bounded Google and shared-input probes, while preferring a Google-like attached page first."
            } else {
                "Compare the attached or saved localhost pages against the bounded Google and shared-input probes."
            }
            command = $manualCommand
        }
    } else {
        [ordered]@{
            goal = "After the matching bounded suite is green, rerun with -ManualInputPath to stage the saved or attached localhost pages, or use the dedicated attached-Google helper when you want current-run attached Google-like pages auto-discovered first."
            command = "powershell -ExecutionPolicy Bypass -File $runner -Phase manual -ManualPort $ManualPort -ManualInitialPage '<preferred-initial-page>' -ManualInputPath '<saved-html-or-folder>'$leaveOpenArgument"
        }
    }
    common_overrides = @(
        "-Host 127.0.0.1",
        "-LocalhostPort 8176",
        "-TitlePort 9582",
        "-HomePort 8168",
        "-HomepageFixturePort 8155",
        "-WatchPort 9582",
        "-SharedLabelPort 8153",
        "-SharedDefaultPort 8154",
        "-SharedDeferredPort 8155",
        "-SharedReducedGooglePort 8156",
        "-SharedEnterOrderPort 8157",
        "-SubmitTimingPort 8181",
        "-InlineFlowPort 8148",
        "-ManualPort 8123",
        "-InputText QZ",
        "-SharedInputText Q",
        "-TraceInputText lightpanda",
        "-ServerReadyTimeoutSeconds 15",
        "-HomeWindowReadyAttempts 60",
        "-HomeTitleWaitAttempts 80",
        "-HomePollMilliseconds 250",
        "-TraceWindowReadyAttempts 80",
        "-TracePollMilliseconds 250",
        "-WatchTimeoutSeconds 90",
        "-WatchPollMilliseconds 250"
    )
    notes = @(
        "Start with the validation-surface checker so guide or helper drift fails fast before localhost, title-flow, title, quick-flow, or quick.",
        "Use .\\scripts\\windows\\check_google_validation_surface.ps1 -Profile attached-html before attached or saved-page follow-up when the next slice depends on the saved-page or attached-page handoff staying intact.",
        "Start with localhost before title-flow, title, quick-flow, or quick so the reduced Google-style probes stay the first bounded gate.",
        "Use the title-flow step when you want the dedicated title wrapper and raw probe handoff printed before you run that narrower slice.",
        "Use the quick-flow step when you want the fast title-plus-watch stack printed before you execute the quick wrapper.",
        "Use the homepage-fixture-flow step after the reduced homepage pass when you want the saved homepage fixture checkpoint printed before execution.",
        "Use the homepage-fixture step after the reduced homepage pass when you want one extra bounded saved-page checkpoint before the submit-path runner, submit-timing slice, or the shared Enter-order stack.",
        "Use the submit-path step when the earlier title and reduced-homepage gates are already green and you want one later-stage command surface for the saved homepage fixture, submit-timing, and shared Enter-order slices before attached-page, manual, or live Google replay.",
        "Use submit-timing-flow after the homepage-fixture or submit-path pass when you want the bounded Google-shaped timing wrapper printed before you execute it.",
        "Use submit-timing after the homepage-fixture or submit-path pass when you want one extra Google-shaped headed check before the shared form-controls and inline-flow gates.",
        "Use shared before a live Google manual check when label activation, input, or submit behavior still looks suspicious.",
        "Use shared-enter-order when the shared gates are green and you want the stricter keypress-before-submit wrapper before the manual Google pass.",
        "Use .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1 when you want that shared Enter-order stack printed as its own narrower read-first handoff before you run it.",
        "Use attached-google-flow when you want the current run's attached Google-like HTML pages auto-discovered and the matching localhost-first issue #3 sequence printed before the broader manual follow-up.",
        "Use attached-google when you want the helper to auto-discover current-run attached Google-like HTML pages instead of restating ManualInputPath by hand.",
        "Use trace when the bounded localhost, reduced homepage, saved homepage fixture, submit-path, submit-timing, shared phases, and attached Google follow-up are green but the real Google homepage still diverges and you need the headed runtime input logs from that exact path.",
        "Use manual only after the closest bounded suite is already green.",
        "Use full when you want the recommended localhost-first issue #3 flow plus the extra title, saved homepage fixture, dedicated submit-path stage, bounded submit-timing, shared label baseline, shared Enter-order wrapper, attached Google helper handoff, and watch phases in one pass, and keep the same saved-page manual follow-up attached when ManualInputPath is already supplied.",
        "When ManualInitialPage is set, the printed attached-google-flow and attached-google commands keep that page preferred for the auto-discovered attached-page path, and the manual follow-up command keeps the same saved page first instead of falling back to a generated index or another arbitrary file.",
        "When ManualInputPath is provided, the printed full command also preserves the same manual port, optional initial page, and saved-page inputs for the one-shot validation rerun.",
        "When ManualGoogleStyle is set, the printed manual and full commands auto-discover current-run attached HTML under user_files first and then agent_files, and they prefer a Google-like attached page when ManualInitialPage is not set.",
        "When LeaveOpen is set, the printed quick-flow, quick, homepage-fixture-flow, homepage-fixture, watch, trace, manual, full, and attached-google-flow commands keep the headed follow-up state easier to inspect after the bounded automation phases finish.",
        "Use the common overrides when you need to keep the localhost, title, home, homepage fixture, submit-timing, watch, shared, shared-enter-order, trace, and manual probes aligned on the same host, ports, timing budget, or input text."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google input validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
if ($ManualInitialPage) {
    Write-Host ("Manual initial page: {0}" -f $ManualInitialPage)
}
Write-Host ("Manual Google-style attached follow-up: {0}" -f ([bool]$ManualGoogleStyle))
Write-Host ("Leave open after bounded phases: {0}" -f ([bool]$LeaveOpen))
Write-Host ""
foreach ($step in $flow.steps) {
    Write-Host ("[{0}] {1}" -f $step.name, $step.goal)
    Write-Host ("  {0}" -f $step.command)
    Write-Host ""
}
Write-Host "[manual] $($flow.saved_page_follow_up.goal)"
Write-Host ("  {0}" -f $flow.saved_page_follow_up.command)
Write-Host ""
Write-Host "Common overrides:"
foreach ($override in $flow.common_overrides) {
    Write-Host ("- {0}" -f $override)
}
Write-Host ""
Write-Host "Notes:"
foreach ($note in $flow.notes) {
    Write-Host ("- {0}" -f $note)
}
