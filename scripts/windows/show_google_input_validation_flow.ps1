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
$titleSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_title_validation_surface.ps1"
$surfaceCheckAttachedCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_validation_surface.ps1 -Profile attached-html"
$titleFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_title_validation_flow.ps1"
$localhostCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase localhost"
$titleCommand = "powershell -ExecutionPolicy Bypass -File $titleRunner"
$issue3SafeRouteEntrypointsCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_safe_route_entrypoints.ps1"
$issue3SafeRoutePatchHandoffCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1"
$issue3SafeRouteWrapperCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1"
$issue3AttachedBundleSuiteCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle"
$quickFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_quick_validation_flow.ps1$leaveOpenArgument"
$quickCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_quick_validation.ps1$leaveOpenArgument"
$homeCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase home"
$homepageFixtureSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_homepage_fixture_validation_surface.ps1"
$homepageFixtureFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1$leaveOpenArgument"
$homepageFixtureCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_homepage_fixture_validation.ps1$leaveOpenArgument"
$submitPathSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_submit_path_validation_surface.ps1"
$submitPathFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_path_validation_flow.ps1"
$submitPathCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_submit_path_validation.ps1"
$submitTimingFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1"
$submitTimingCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_submit_timing_validation.ps1"
$sharedCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase shared"
$sharedEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase shared-enter-order"
$formControlsEnterOrderSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_form_controls_enter_order_validation_surface.ps1"
$formControlsEnterOrderFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_validation_flow.ps1"
$formControlsEnterOrderTraceGuideCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_trace_guide.ps1"
$formControlsEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_form_controls_enter_order_validation.ps1"
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
$attachedBundleInputPathArgument = ""

$manualCommand = $null
if ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
    $quotedPaths = $ManualInputPath | ForEach-Object { ConvertTo-PowerShellSingleQuotedLiteral -Value $_ }
    $manualPathsArgument = " -ManualInputPath " + ($quotedPaths -join ", ")
    $attachedBundleInputPathArgument = " -InputPath " + ($quotedPaths -join ", ")
    $manualCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase manual -ManualPort $ManualPort$manualInitialPageArgument$manualPathsArgument$manualGoogleStyleArgument$leaveOpenArgument"
    $fullCommand = "powershell -ExecutionPolicy Bypass -File $recommendedRunner -ManualPort $ManualPort$manualInitialPageArgument$manualPathsArgument$manualGoogleStyleArgument$leaveOpenArgument"
} elseif ($ManualGoogleStyle) {
    $manualCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase manual -ManualPort $ManualPort$manualInitialPageArgument -ManualGoogleStyle$leaveOpenArgument"
    $fullCommand = "powershell -ExecutionPolicy Bypass -File $recommendedRunner -ManualPort $ManualPort$manualInitialPageArgument -ManualGoogleStyle$leaveOpenArgument"
}

$issue3AttachedBundleFirstEntrypointCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_bundle_first_entrypoint.ps1$attachedBundleInputPathArgument"
$issue3AttachedBundleFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_target_bundle_validation_flow.ps1$attachedBundleInputPathArgument"
$issue3AttachedBundleRunnerCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_target_bundle_validation.ps1$attachedBundleInputPathArgument -Wait"

$flow = [ordered]@{
    issue = "Headed Windows Google input validation flow"
    focus = "Issue #3 first-pass validation order for the validation-surface checker, reduced localhost probes, the narrower title-surface checker, the title-flow helper, title readiness, the dedicated quick-flow helper, the fast title-plus-watch pass, reduced homepage submit, the dedicated homepage-fixture surface checker and saved-homepage checkpoint, the dedicated later-stage submit-path surface checker and flow helper, the dedicated submit-path runner, the dedicated submit-timing flow helper, the bounded Google-shaped submit-timing pass through its wrapper, the shared label-click baseline plus submit gates, the stricter shared Enter-order wrapper, the dedicated form-controls Enter-order surface checker, flow helper, trace guide, and runner, the issue #3 safe-route entrypoints helper, the fresh safe-route runner-patch handoff entrypoint, the show-only safe-route wrapper for already-current outputs, the attached-bundle suite router, one-command bundle-first helper, dedicated bundle flow, the bundle runner for the pinned three-page compatibility set, the dedicated attached-Google flow and runner for current attached HTML pages, live Google trace capture, watch mode, and saved-page localhost follow-up."
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
            name = "title-surface-check"
            goal = "Fail fast if the dedicated bounded title-validation guide, helper, direct probe, or fixture drifted out of sync before you depend on the narrower issue #3 title ladder."
            command = $titleSurfaceCheckCommand
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
            name = "homepage-fixture-surface-check"
            goal = "Fail fast if the dedicated homepage-fixture note, helper, wrapper, or raw probe drifted before the later submit-path ladder depends on this saved-homepage checkpoint."
            command = $homepageFixtureSurfaceCheckCommand
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
            name = "submit-path-surface-check"
            goal = "Fail fast if the later issue #3 submit-path note, helper, trace guide, or bounded probes drifted out of sync before you depend on that later-stage ladder."
            command = $submitPathSurfaceCheckCommand
        }
        [ordered]@{
            name = "submit-path-flow"
            goal = "Print the later-stage saved homepage fixture, submit-timing, and shared Enter-order ladder when you want that narrower issue #3 slice spelled out before you run it."
            command = $submitPathFlowCommand
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
            goal = "Run the bounded Google-shaped timing probe through the dedicated submit-timing wrapper so typed text plus keydown, keypress, submit ordering stay on one reusable command surface."
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
            name = "form-controls-enter-order-surface-check"
            goal = "Fail fast if the dedicated shared form-controls Enter-order note, helper, trace guide, or smallest bounded probe drifted out of sync before you depend on that last shared checkpoint."
            command = $formControlsEnterOrderSurfaceCheckCommand
        }
        [ordered]@{
            name = "form-controls-enter-order-flow"
            goal = "Print the dedicated shared form-controls Enter-order ladder when you want the smallest real-surface keypress-before-submit gate spelled out before you run it."
            command = $formControlsEnterOrderFlowCommand
        }
        [ordered]@{
            name = "form-controls-enter-order-trace-guide"
            goal = "Read the dedicated shared form-controls Enter-order marker guide when you want the smallest later-stage shared checkpoint translated into the next narrowing step before rerunning it."
            command = $formControlsEnterOrderTraceGuideCommand
        }
        [ordered]@{
            name = "form-controls-enter-order"
            goal = "Run the dedicated shared form-controls Enter-order gate when you want the smallest later-stage keypress-before-submit proof before attached HTML or live Google replay."
            command = $formControlsEnterOrderCommand
        }
        [ordered]@{
            name = "issue3-safe-route-entrypoints"
            goal = "Print the current issue #3 safe-route entrypoints in one place so the fresh replay, reuse-current-outputs, refresh-status, handoff, summary-guide, and runner-wiring helpers stay aligned before you choose the next replay branch."
            command = $issue3SafeRouteEntrypointsCommand
        }
        [ordered]@{
            name = "issue3-safe-route-patch-handoff"
            goal = "Run the default fresh issue #3 safe-route replay entrypoint when current outputs may be stale or missing and you want the narrower runner-patch guidance preserved in one artifact before deciding between direct runner patch, already-direct, or output-regeneration follow-up."
            command = $issue3SafeRoutePatchHandoffCommand
        }
        [ordered]@{
            name = "issue3-safe-route-wrapper"
            goal = "Reopen the narrower safe-route plus runner-patch guidance when the current issue #3 outputs are already present and you want to reuse them without another broader regeneration first."
            command = $issue3SafeRouteWrapperCommand
        }
        [ordered]@{
            name = "issue3-attached-bundle-suite"
            goal = "Reopen the top-level suite router directly on the pinned attached three-page compatibility bundle when the current replay should stay on that narrower route before the broader attached-page follow-up."
            command = $issue3AttachedBundleSuiteCommand
        }
        [ordered]@{
            name = "issue3-attached-bundle-first"
            goal = "Print the one-command issue #3 bundle-first helper when the current saved or attached pages still match the known three-page compatibility set and you want the return to the broader safe-route helper preserved beside that bundle route."
            command = $issue3AttachedBundleFirstEntrypointCommand
        }
        [ordered]@{
            name = "issue3-attached-bundle-flow"
            goal = "Print the pinned bundle route so the bundle-aware surface check, bundle checker, bundle flow, and delegated localhost runner stay on one read-first command surface before execution."
            command = $issue3AttachedBundleFlowCommand
        }
        [ordered]@{
            name = "issue3-attached-bundle"
            goal = "Launch the headed localhost replay through the same bundle-pinned route when the current saved or attached pages are the known three-page compatibility set."
            command = $issue3AttachedBundleRunnerCommand
        }
        [ordered]@{
            name = "attached-google-flow"
            goal = "Print the attached Google-style helper flow when you want the current run's attached HTML pages auto-discovered and mapped onto the same localhost-first issue #3 sequence before the broader manual follow-up."
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
            goal = "Run the broader localhost-first issue #3 recommended runner in one pass so the reduced title phase, reduced homepage pass, saved homepage fixture checkpoint, dedicated submit-path stage, bounded submit-timing slice, shared label baseline, shared Enter-order wrapper, dedicated form-controls Enter-order gate, attached-bundle bridge, attached Google helper handoff, and watch phases stay on one reusable command surface before the broader manual follow-up."
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
        "Start with the validation-surface checker so guide or helper drift fails fast before localhost, title-surface-check, title-flow, title, quick-flow, or quick.",
        "Use .\\scripts\\windows\\check_google_validation_surface.ps1 -Profile attached-html before attached or saved-page follow-up when the next slice depends on the saved-page or attached-page handoff staying intact.",
        "Start with localhost before title-surface-check, title-flow, title, quick-flow, or quick so the reduced Google-style probes stay the first bounded gate.",
        "Use the title-surface-check step before title-flow or title when you want the narrower title guide, helper, direct-probe, and fixture chain to fail fast before you depend on that smaller issue #3 ladder.",
        "Use the title-flow step when you want the dedicated title wrapper and raw probe handoff printed before you run that narrower slice.",
        "Use the quick-flow step when you want the fast title-plus-watch stack printed before you execute the quick wrapper.",
        "Use the homepage-fixture-surface-check step before homepage-fixture-flow or homepage-fixture when you want the dedicated note, helper, wrapper, and raw probe chain to fail fast before you widen into the later submit-path ladder.",
        "Use the homepage-fixture-flow step after the reduced homepage pass when you want the saved homepage fixture checkpoint printed before execution.",
        "Use the homepage-fixture step after the reduced homepage pass when you want one extra bounded saved-page checkpoint before the submit-path surface-check, submit-path flow, submit-timing slice, or the shared Enter-order stack.",
        "Use the submit-path-surface-check step before submit-path-flow or submit-path when you want the later issue #3 note, helper, trace guide, and bounded probes to fail fast before you depend on that narrower ladder.",
        "Use the submit-path-flow step when the earlier title and reduced-homepage gates are already green and you want the later-stage saved homepage fixture, submit-timing, and shared Enter-order ladder printed before you run it.",
        "Use the submit-path step when the earlier title and reduced-homepage gates are already green and you want one later-stage command surface for the saved homepage fixture, submit-timing, and shared Enter-order slices before attached-page, manual, or live Google replay.",
        "Use submit-timing-flow after the homepage-fixture or submit-path pass when you want the bounded Google-shaped timing wrapper printed before you execute it.",
        "Use submit-timing after the homepage-fixture or submit-path pass when you want one extra Google-shaped headed check before the shared form-controls and inline-flow gates.",
        "Use shared before a live Google manual check when label activation, input, or submit behavior still looks suspicious.",
        "Use shared-enter-order when the shared gates are green and you want the stricter keypress-before-submit wrapper before the dedicated form-controls gate or the manual Google pass.",
        "Use the form-controls-enter-order-surface-check step before the dedicated form-controls flow, trace guide, or runner when you want the smallest shared later-stage note, helper, and bounded probe chain to fail fast.",
        "Use the form-controls-enter-order-flow step when you want that smallest shared keypress-before-submit gate printed as its own narrower handoff before you run it.",
        "Use the form-controls-enter-order-trace-guide step when you want the dedicated form-controls probe markers translated into quick failure stages without reopening the longer read-first markdown note.",
        "Use the form-controls-enter-order step when you want the smallest later-stage shared keypress-before-submit proof before attached-page, manual, or live Google replay.",
        "Use issue3-safe-route-entrypoints when you want the newest fresh replay, reuse-current-outputs, refresh-status, handoff-safe, summary-guide-safe, and runner-wiring-safe commands printed together before choosing the next narrower replay branch.",
        "When repo-root or saved-summary context matters, use issue3-safe-route-entrypoints first so the emitted safe-route commands preserve that same context through the newer wrappers.",
        "Use issue3-safe-route-patch-handoff when current issue #3 outputs may be stale or missing and you want the default fresh replay entrypoint that regenerates the recommended summary while preserving the narrowed runner-patch next step in one artifact.",
        "Use issue3-safe-route-wrapper only when the current issue #3 outputs are already present and you want to reopen the narrower safe-route plus runner-patch guidance without another broader replay first.",
        "Use issue3-attached-bundle-suite when the current replay should stay pinned to the known attached three-page compatibility set before you reopen the broader attached-page or safe-route ladders.",
        "Use issue3-attached-bundle-first when you want the pinned three-page bundle route plus the return-to-safe-route command printed together in one helper before you choose whether to widen back into the wrapper-heavy chain.",
        "Use issue3-attached-bundle-flow when you want the bundle-aware surface check, bundle checker, pinned flow, and delegated localhost runner printed together before execution.",
        "Use issue3-attached-bundle when the current saved or attached pages are still the known three-page compatibility bundle and you want to replay that locked input set before the broader attached-Google or manual follow-up.",
        "Keep docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md open for wrapper precedence and docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md open when the safe-route handoff artifact lands on ready-for-runner-patch, already-direct, or runner-already-wired-regenerate-outputs.",
        "Use attached-google-flow when you want the current run's attached Google-like HTML pages auto-discovered and the matching localhost-first issue #3 sequence printed before the broader manual follow-up.",
        "Use attached-google when you want the helper to auto-discover current-run attached Google-like HTML pages instead of restating ManualInputPath by hand.",
        "Use trace when the bounded localhost, reduced homepage, saved homepage fixture, submit-path, submit-timing, shared phases, dedicated form-controls gate, attached-bundle replay, attached Google follow-up, and safe-route replay entrypoints are green but the real Google homepage still diverges and you need the headed runtime input logs from that exact path.",
        "Use manual only after the closest bounded suite is already green.",
        "Use full when you intentionally want the broader localhost-first issue #3 flow plus the extra title, saved homepage fixture, dedicated submit-path stage, bounded submit-timing, shared label baseline, shared Enter-order wrapper, dedicated form-controls Enter-order gate, attached-bundle bridge, attached Google helper handoff, and watch phases in one pass, and keep the same saved-page manual follow-up attached when ManualInputPath is already supplied.",
        "When ManualInitialPage is set, the printed attached-google-flow and attached-google commands keep that page preferred for the auto-discovered attached-page path, and the manual follow-up command keeps the same saved page first instead of falling back to a generated index or another arbitrary file.",
        "When ManualInputPath is provided, the printed full command, issue3-attached-bundle-first helper, issue3-attached-bundle flow, and issue3-attached-bundle runner also preserve the same fixed input set for the bundle-first route instead of relying on auto-discovery.",
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
