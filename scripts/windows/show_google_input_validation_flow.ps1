[CmdletBinding()]
param(
    [switch]$Json,
    [string[]]$ManualInputPath,
    [int]$ManualPort = 8123
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$runner = '.\\scripts\\windows\\run_google_input_validation.ps1'
$localhostCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase localhost"
$titleCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase title"
$quickCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase quick"
$homeCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase home"
$sharedCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase shared"
$sharedEnterOrderCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase shared-enter-order"
$traceCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase trace"
$watchCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase watch"
$fullCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase all -IncludeTitleProbe -IncludeSharedEnterOrder -IncludeWatch"

$manualCommand = $null
if ($ManualInputPath -and $ManualInputPath.Count -gt 0) {
    $quotedPaths = $ManualInputPath | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }
    $manualCommand = "powershell -ExecutionPolicy Bypass -File $runner -Phase manual -ManualPort $ManualPort -ManualInputPath " + ($quotedPaths -join ", ")
}

$flow = [ordered]@{
    issue = "Headed Windows Google input validation flow"
    focus = "Issue #3 first-pass validation order for reduced localhost probes, title readiness, reduced homepage submit, the shared label-click baseline plus submit gates, the stricter shared Enter-order wrapper, live Google trace capture, watch mode, and saved-page localhost follow-up."
    steps = @(
        [ordered]@{
            name = "localhost"
            goal = "Run the reduced localhost Google-style probes before any real-surface homepage pass."
            command = $localhostCommand
        }
        [ordered]@{
            name = "title"
            goal = "Check bounded readiness and title updates on the reduced Google-style page."
            command = $titleCommand
        }
        [ordered]@{
            name = "quick"
            goal = "Run the fast first pass that combines the title probe and self-starting watch probe."
            command = $quickCommand
        }
        [ordered]@{
            name = "home"
            goal = "Run the reduced homepage Enter-submit pass on the headed surface."
            command = $homeCommand
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
            goal = "Run the localhost-first flow in one pass, then fold in the quick title, reduced homepage submit, shared label baseline, shared submit gates, stricter Enter-order wrapper, and watcher before the broader Google manual follow-up."
            command = $fullCommand
        }
    )
    saved_page_follow_up = if ($manualCommand) {
        [ordered]@{
            goal = "Compare the attached or saved localhost pages against the bounded Google and shared-input probes."
            command = $manualCommand
        }
    } else {
        [ordered]@{
            goal = "After the matching bounded suite is green, rerun with -ManualInputPath to stage the saved or attached localhost pages."
            command = "powershell -ExecutionPolicy Bypass -File $runner -Phase manual -ManualPort $ManualPort -ManualInputPath '<saved-html-or-folder>'"
        }
    }
    common_overrides = @(
        "-Host 127.0.0.1",
        "-LocalhostPort 8176",
        "-TitlePort 9582",
        "-HomePort 8168",
        "-WatchPort 9582",
        "-SharedLabelPort 8153",
        "-SharedDefaultPort 8154",
        "-SharedDeferredPort 8155",
        "-SharedReducedGooglePort 8156",
        "-SharedEnterOrderPort 8157",
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
        "Start with localhost before title or quick so the reduced Google-style probes stay the first bounded gate.",
        "Use shared before a live Google manual check when label activation, input, or submit behavior still looks suspicious.",
        "Use shared-enter-order when the shared gates are green and you want the stricter keypress-before-submit wrapper before the manual Google pass.",
        "Use trace when the bounded localhost, reduced homepage, and shared phases are green but the real Google homepage still diverges and you need the headed runtime input logs from that exact path.",
        "Use manual only after the closest bounded suite is already green.",
        "Use full when you want the runner's built-in localhost-first order plus the extra title, shared label baseline, shared Enter-order wrapper, and watch phases in one pass.",
        "Use the common overrides when you need to keep the localhost, title, home, watch, shared, shared-enter-order, trace, and manual probes aligned on the same host, ports, timing budget, or input text."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google input validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
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
