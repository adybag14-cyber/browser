[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$SharedInputText = "Q",
    [string]$EnterMutationSuffix = "!",
    [int]$SharedDefaultPort = 8154,
    [int]$SharedDeferredPort = 8155,
    [int]$SharedReducedGooglePort = 8156,
    [int]$SharedEnterOrderPort = 8157,
    [int]$SharedLabelPort = 8153,
    [int]$InlineFlowPort = 8148,
    [int]$ReducedHomeKeypressPort = 8167,
    [int]$TitleProbePort = 8159,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 60,
    [int]$HomeTitleWaitAttempts = 80,
    [int]$HomePollMilliseconds = 250
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

function Add-SharedArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        $Value
    )

    if ($null -eq $Value) {
        return
    }
    if ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    $Arguments.Add("-$Name")
    if ($Value -is [string]) {
        $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $Value))
    } else {
        $Arguments.Add([string]$Value)
    }
}

$surfaceCheck = '.\scripts\windows\check_google_shared_enter_order_validation_surface.ps1'
$runner = '.\scripts\windows\run_google_shared_enter_order_validation.ps1'
$sharedRunner = '.\scripts\windows\run_google_input_validation.ps1'
$googleTitleProbe = '.\tmp-browser-smoke\google-investigation-next\chrome-google-title-probe.ps1'
$reducedHomeProbe = '.\tmp-browser-smoke\google-home\chrome-google-home-keypress-submit-probe.ps1'
$localhostProbe = '.\tmp-browser-smoke\google-investigation-next\google-enter-order-localhost-probe.ps1'
$sharedClickFocusProbe = '.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1'
$formControlsRunner = '.\scripts\windows\run_google_form_controls_enter_order_validation.ps1'
$formControlsFlow = '.\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1'
$formControlsTraceGuide = '.\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1'
$recommendedValidation = '.\scripts\windows\run_google_issue3_recommended_validation.ps1'
$suiteRouterNextSteps = '.\scripts\windows\show_google_issue3_suite_router_next_steps.ps1'
$replayRoute = '.\scripts\windows\show_google_issue3_replay_route.ps1'
$traceFlow = '.\scripts\windows\show_google_trace_validation_flow.ps1'

$surfaceCheckArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $surfaceCheckArgs -Name RepoRoot -Value $RepoRoot

$runnerArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $runnerArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $runnerArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $runnerArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $runnerArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $runnerArgs -Name EnterMutationSuffix -Value $EnterMutationSuffix
Add-SharedArgument -Arguments $runnerArgs -Name SharedLabelPort -Value $SharedLabelPort
Add-SharedArgument -Arguments $runnerArgs -Name SharedDefaultPort -Value $SharedDefaultPort
Add-SharedArgument -Arguments $runnerArgs -Name SharedDeferredPort -Value $SharedDeferredPort
Add-SharedArgument -Arguments $runnerArgs -Name SharedReducedGooglePort -Value $SharedReducedGooglePort
Add-SharedArgument -Arguments $runnerArgs -Name SharedEnterOrderPort -Value $SharedEnterOrderPort
Add-SharedArgument -Arguments $runnerArgs -Name InlineFlowPort -Value $InlineFlowPort
Add-SharedArgument -Arguments $runnerArgs -Name ReducedHomeKeypressPort -Value $ReducedHomeKeypressPort
Add-SharedArgument -Arguments $runnerArgs -Name TitleProbePort -Value $TitleProbePort
Add-SharedArgument -Arguments $runnerArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $runnerArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $runnerArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $runnerArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds

$commonProbeArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $commonProbeArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $commonProbeArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $commonProbeArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $commonProbeArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $commonProbeArgs -Name WindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $commonProbeArgs -Name TitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $commonProbeArgs -Name PollMilliseconds -Value $HomePollMilliseconds

$sharedOnlyArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedOnlyArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedOnlyArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $sharedOnlyArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $sharedOnlyArgs -Name Phase -Value "shared"
Add-SharedArgument -Arguments $sharedOnlyArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $sharedOnlyArgs -Name SharedLabelPort -Value $SharedLabelPort
Add-SharedArgument -Arguments $sharedOnlyArgs -Name SharedDefaultPort -Value $SharedDefaultPort
Add-SharedArgument -Arguments $sharedOnlyArgs -Name SharedDeferredPort -Value $SharedDeferredPort
Add-SharedArgument -Arguments $sharedOnlyArgs -Name SharedReducedGooglePort -Value $SharedReducedGooglePort
Add-SharedArgument -Arguments $sharedOnlyArgs -Name InlineFlowPort -Value $InlineFlowPort
Add-SharedArgument -Arguments $sharedOnlyArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $sharedOnlyArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $sharedOnlyArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $sharedOnlyArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds

$formControlsGuideArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $formControlsGuideArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $formControlsGuideArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $formControlsGuideArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $formControlsGuideArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $formControlsGuideArgs -Name SharedEnterOrderPort -Value $SharedEnterOrderPort
Add-SharedArgument -Arguments $formControlsGuideArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $formControlsGuideArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $formControlsGuideArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $formControlsGuideArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds

$recommendedValidationArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $recommendedValidationArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $recommendedValidationArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $recommendedValidationArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $recommendedValidationArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $recommendedValidationArgs -Name EnterMutationSuffix -Value $EnterMutationSuffix
Add-SharedArgument -Arguments $recommendedValidationArgs -Name TitleProbePort -Value $TitleProbePort
Add-SharedArgument -Arguments $recommendedValidationArgs -Name SharedLabelPort -Value $SharedLabelPort
Add-SharedArgument -Arguments $recommendedValidationArgs -Name SharedDefaultPort -Value $SharedDefaultPort
Add-SharedArgument -Arguments $recommendedValidationArgs -Name SharedDeferredPort -Value $SharedDeferredPort
Add-SharedArgument -Arguments $recommendedValidationArgs -Name InlineFlowPort -Value $InlineFlowPort
Add-SharedArgument -Arguments $recommendedValidationArgs -Name SharedReducedGooglePort -Value $SharedReducedGooglePort
Add-SharedArgument -Arguments $recommendedValidationArgs -Name SharedEnterOrderPort -Value $SharedEnterOrderPort
Add-SharedArgument -Arguments $recommendedValidationArgs -Name ReducedHomeKeypressPort -Value $ReducedHomeKeypressPort
Add-SharedArgument -Arguments $recommendedValidationArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $recommendedValidationArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $recommendedValidationArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $recommendedValidationArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds

$suiteRouterArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $suiteRouterArgs -Name RepoRoot -Value $RepoRoot

$replayRouteArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $replayRouteArgs -Name RepoRoot -Value $RepoRoot

$traceFlowArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $traceFlowArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $traceFlowArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $traceFlowArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $traceFlowArgs -Name InputText -Value $SharedInputText
Add-SharedArgument -Arguments $traceFlowArgs -Name WindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $traceFlowArgs -Name PollMilliseconds -Value $HomePollMilliseconds

$flow = [ordered]@{
    issue = "Headed Windows Google shared Enter-order validation flow"
    focus = "Run the shared form-controls baseline, the localhost Google title probe, the reduced Google homepage keypress probe, the reusable click-first shared page probe, the localhost Enter-order wrapper, and the dedicated shared Enter-order gate in the same order before a live Google manual pass."
    shared_input_text = $SharedInputText
    enter_mutation_suffix = $EnterMutationSuffix
    host = $Host
    title_probe_port = $TitleProbePort
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the shared Enter-order guide, helpers, or probes drifted before you trust this narrower issue #3 ladder."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $surfaceCheck, $(if ($surfaceCheckArgs.Count -gt 0) { " " + ($surfaceCheckArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "recommended"
            goal = "Run the full shared Enter-order stack in the intended order and keep one command for issue #3 handoff."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $runner, $(if ($runnerArgs.Count -gt 0) { " " + ($runnerArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "shared-only"
            goal = "Narrow failures to the shared label, immediate Enter, deferred Enter, reduced Google-home, and inline-flow gates before the stricter headed probes."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $sharedRunner, $(if ($sharedOnlyArgs.Count -gt 0) { " " + ($sharedOnlyArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "google-title-localhost"
            goal = "Verify the dedicated localhost Google-style title probe still reaches click focus, typed text visibility, and Enter submit on the headed surface."
            command = ("powershell -ExecutionPolicy Bypass -File {0} -InputText {1} -Port {2}{3}" -f $googleTitleProbe, (ConvertTo-PowerShellSingleQuotedLiteral -Value $SharedInputText), $TitleProbePort, $(if ($commonProbeArgs.Count -gt 0) { " " + ($commonProbeArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "reduced-home-keypress"
            goal = "Check the reduced Google homepage keypress-before-submit path in isolation once the shared baseline and localhost title probe are green."
            command = ("powershell -ExecutionPolicy Bypass -File {0} -InputText {1} -Port {2}{3}" -f $reducedHomeProbe, (ConvertTo-PowerShellSingleQuotedLiteral -Value $SharedInputText), $ReducedHomeKeypressPort, $(if ($commonProbeArgs.Count -gt 0) { " " + ($commonProbeArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "localhost-enter-order"
            goal = "Verify the reduced localhost Google-style wrapper still mutates at Enter keypress before submit completes."
            command = ("powershell -ExecutionPolicy Bypass -File {0} -InputText {1} -EnterMutationSuffix {2} -Port {3}{4}" -f $localhostProbe, (ConvertTo-PowerShellSingleQuotedLiteral -Value $SharedInputText), (ConvertTo-PowerShellSingleQuotedLiteral -Value $EnterMutationSuffix), $SharedEnterOrderPort, $(if ($commonProbeArgs.Count -gt 0) { " " + ($commonProbeArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "shared-click-focus-fallback"
            goal = "Replay the reusable shared page in click-first mode when you want the same Google-shaped focus and Enter path available before the dedicated form-controls gate."
            command = ("powershell -ExecutionPolicy Bypass -File {0} -GoogleEnterOrder -ClickFocus -InputText {1} -Port {2}{3}" -f $sharedClickFocusProbe, (ConvertTo-PowerShellSingleQuotedLiteral -Value $SharedInputText), $SharedEnterOrderPort, $(if ($commonProbeArgs.Count -gt 0) { " " + ($commonProbeArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "form-controls-flow"
            goal = "Print the narrowed dedicated form-controls Enter-order ladder with the same repo-root, browser, and host context before you jump to the last shared gate."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $formControlsFlow, $(if ($formControlsGuideArgs.Count -gt 0) { " " + ($formControlsGuideArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "form-controls-enter-order"
            goal = "Verify the dedicated shared form-controls Google-style gate still records submit after Enter keypress on the headed surface."
            command = ("powershell -ExecutionPolicy Bypass -File {0} -SharedInputText {1} -SharedEnterOrderPort {2} -Host {3} -ServerReadyTimeoutSeconds {4} -HomeWindowReadyAttempts {5} -HomeTitleWaitAttempts {6} -HomePollMilliseconds {7}{8}" -f $formControlsRunner, (ConvertTo-PowerShellSingleQuotedLiteral -Value $SharedInputText), $SharedEnterOrderPort, (ConvertTo-PowerShellSingleQuotedLiteral -Value $Host), $ServerReadyTimeoutSeconds, $HomeWindowReadyAttempts, $HomeTitleWaitAttempts, $HomePollMilliseconds, $(if ($RepoRoot) { " -RepoRoot " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $RepoRoot) } else { "" }) + $(if ($BrowserExe) { " -BrowserExe " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $BrowserExe) } else { "" }))
        }
        [ordered]@{
            name = "form-controls-trace-guide"
            goal = "Translate the dedicated form-controls gate markers into quick failure stages before you rerun it or widen back out to the broader shared ladder."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $formControlsTraceGuide, $(if ($formControlsGuideArgs.Count -gt 0) { " " + ($formControlsGuideArgs -join " ") } else { "" }))
        }
    )
    next_steps = @(
        ("Use powershell -ExecutionPolicy Bypass -File {0} -GoogleEnterOrder -ClickFocus -InputText {1} -Port {2}{3} when you want the reusable shared page to replay the same click-first Google-shaped path before you hand off to the dedicated form-controls ladder." -f $sharedClickFocusProbe, (ConvertTo-PowerShellSingleQuotedLiteral -Value $SharedInputText), $SharedEnterOrderPort, $(if ($commonProbeArgs.Count -gt 0) { " " + ($commonProbeArgs -join " ") } else { "" })),
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} when you want only the dedicated shared form-controls gate printed with the same repo-root, browser, host, shared input, and timing context before you run it." -f $formControlsFlow, $(if ($formControlsGuideArgs.Count -gt 0) { " " + ($formControlsGuideArgs -join " ") } else { "" })),
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} when you want the dedicated gate markers translated into click-focus, typed-text, keypress, and submit failure stages without reconstructing the current shared Enter-order context by hand." -f $formControlsTraceGuide, $(if ($formControlsGuideArgs.Count -gt 0) { " " + ($formControlsGuideArgs -join " ") } else { "" })),
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} when you want this stack folded back into the broader localhost-first issue #3 flow with the same repo-root, browser, host, shared input, Enter mutation, and timing settings." -f $recommendedValidation, $(if ($recommendedValidationArgs.Count -gt 0) { " " + ($recommendedValidationArgs -join " ") } else { "" })),
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} when you want the later live-trace handoff reopened with the same repo-root, browser, host, shared input, and bounded wait settings before the next real Google capture." -f $traceFlow, $(if ($traceFlowArgs.Count -gt 0) { " " + ($traceFlowArgs -join " ") } else { "" })),
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} when you want the higher-level issue #3 next-step matrix reopened with the same repo-root context before choosing between replay shortcuts, the attached bundle branch, or the safe-route wrapper chain." -f $suiteRouterNextSteps, $(if ($suiteRouterArgs.Count -gt 0) { " " + ($suiteRouterArgs -join " ") } else { "" })),
        ("Use powershell -ExecutionPolicy Bypass -File {0}{1} when you want the broader issue #3 replay bridge reopened with the same repo-root context before you widen back out from the shared Enter-order slice." -f $replayRoute, $(if ($replayRouteArgs.Count -gt 0) { " " + ($replayRouteArgs -join " ") } else { "" })),
        "Move on to the smallest live Google manual pass only after the localhost title probe, reduced-home keypress probe, shared click-first fallback, and both Enter-order probes stay green together.",
        "Use .\scripts\windows\show_google_attached_html_validation_flow.ps1 before the saved-page localhost follow-up when the shared Enter-order stack is already green."
    )
    notes = @(
        "Run the shared Enter-order surface checker first so missing docs, wrapper scripts, or probe files fail before the narrower ladder looks trustworthy.",
        "Start with the recommended runner unless you are already narrowing a known failing step.",
        "Keep the same SharedInputText across the whole stack so the localhost title probe, reduced-home probe, shared click-first fallback, localhost wrapper, and dedicated form-controls gate all report the same expected value.",
        "The localhost wrapper, the shared click-first fallback, and the dedicated form-controls probe all default to the shared Enter-order port on purpose so one port override keeps the whole Enter-order slice aligned.",
        "Use the shared click-first fallback when you want to compare the reusable Google-shaped page against the dedicated form-controls gate before widening back to the broader shared Enter-order ladder.",
        "Use the dedicated form-controls flow helper when you only need the last shared keypress-before-submit gate without printing the wider shared Enter-order ladder.",
        "Use the form-controls trace guide when you want a quick explanation of whether the remaining failure stayed before click focus, before visible text commit, or before keypress reached submit.",
        "The printed next-step commands now preserve the current repo root, custom browser path, host, shared input, Enter mutation, and timing settings where those later helpers support them, including the live-trace handoff, and they reopen the higher-level issue #3 route helpers with the same repo-root context when you need to widen back out."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google shared Enter-order validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Host: {0}" -f $flow.host)
Write-Host ("Shared input text: {0}" -f $flow.shared_input_text)
Write-Host ("Enter mutation suffix: {0}" -f $flow.enter_mutation_suffix)
Write-Host ("Google title probe port: {0}" -f $flow.title_probe_port)
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
