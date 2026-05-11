[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$SharedInputText = "Q",
    [string]$SubmitTimingInputText = "QZ",
    [string]$EnterMutationSuffix = "!",
    [int]$HomepageFixturePort = 8155,
    [int]$SubmitTimingPort = 8181,
    [int]$SharedEnterOrderPort = 8157,
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

$surfaceCheck = '.\\scripts\\windows\\check_google_submit_path_validation_surface.ps1'
$runner = '.\\scripts\\windows\\run_google_issue3_submit_path_validation.ps1'
$traceGuide = '.\\scripts\\windows\\show_google_submit_path_trace_guide.ps1'
$homepageFixtureFlow = '.\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1'
$homepageFixtureRunner = '.\\scripts\\windows\\run_google_homepage_fixture_validation.ps1'
$submitTimingFlow = '.\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1'
$submitTimingRunner = '.\\scripts\\windows\\run_google_submit_timing_validation.ps1'
$sharedEnterOrderFlow = '.\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1'
$sharedEnterOrderRunner = '.\\scripts\\windows\\run_google_shared_enter_order_validation.ps1'

$runnerArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $runnerArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $runnerArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $runnerArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $runnerArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $runnerArgs -Name SubmitTimingInputText -Value $SubmitTimingInputText
Add-SharedArgument -Arguments $runnerArgs -Name EnterMutationSuffix -Value $EnterMutationSuffix
Add-SharedArgument -Arguments $runnerArgs -Name HomepageFixturePort -Value $HomepageFixturePort
Add-SharedArgument -Arguments $runnerArgs -Name SubmitTimingPort -Value $SubmitTimingPort
Add-SharedArgument -Arguments $runnerArgs -Name SharedEnterOrderPort -Value $SharedEnterOrderPort
Add-SharedArgument -Arguments $runnerArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $runnerArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $runnerArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $runnerArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds
if ($LeaveOpen) {
    $runnerArgs.Add('-LeaveOpen')
}

$homepageFixtureArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $homepageFixtureArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $homepageFixtureArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $homepageFixtureArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $homepageFixtureArgs -Name FixturePort -Value $HomepageFixturePort
Add-SharedArgument -Arguments $homepageFixtureArgs -Name InputText -Value $SharedInputText
Add-SharedArgument -Arguments $homepageFixtureArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $homepageFixtureArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $homepageFixtureArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $homepageFixtureArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds
if ($LeaveOpen) {
    $homepageFixtureArgs.Add('-LeaveOpen')
}

$submitTimingArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $submitTimingArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $submitTimingArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $submitTimingArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $submitTimingArgs -Name SubmitTimingPort -Value $SubmitTimingPort
Add-SharedArgument -Arguments $submitTimingArgs -Name InputText -Value $SubmitTimingInputText

$sharedEnterOrderArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name EnterMutationSuffix -Value $EnterMutationSuffix
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name SharedEnterOrderPort -Value $SharedEnterOrderPort
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $sharedEnterOrderArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds

$flow = [ordered]@{
    issue = "Headed Windows Google submit-path validation flow"
    focus = "Print the later-stage issue #3 command ladder in one place once the earlier title and reduced-homepage gates are already green: saved homepage fixture, bounded submit timing, the stricter shared Enter-order stack, and the read-first trace helper that explains where the later submit path diverged."
    host = $Host
    shared_input_text = $SharedInputText
    submit_timing_input_text = $SubmitTimingInputText
    enter_mutation_suffix = $EnterMutationSuffix
    homepage_fixture_port = $HomepageFixturePort
    submit_timing_port = $SubmitTimingPort
    shared_enter_order_port = $SharedEnterOrderPort
    steps = @(
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the submit-path note, trace guide, runners, or bounded probe files drifted before you trust this later issue #3 ladder."
            command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $surfaceCheck)
        }
        [ordered]@{
            name = "submit-path-runner"
            goal = "Run the one-command issue #3 submit-path runner when you want the saved homepage fixture, submit-timing, and shared Enter-order slices executed in the intended order."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $runner, $(if ($runnerArgs.Count -gt 0) { " " + ($runnerArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "trace-guide"
            goal = "Translate the saved homepage fixture, submit-timing, and shared Enter-order outputs into the next narrowing step before you widen back out again."
            command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $traceGuide)
        }
        [ordered]@{
            name = "homepage-fixture-flow"
            goal = "Print the saved homepage fixture flow first when you want the localhost Google-style checkpoint explained before execution."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $homepageFixtureFlow, $(if ($homepageFixtureArgs.Count -gt 0) { " " + ($homepageFixtureArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "homepage-fixture-runner"
            goal = "Run the saved homepage fixture slice directly when you need to isolate focus, typed text, and Enter submit before the later timing gates."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $homepageFixtureRunner, $(if ($homepageFixtureArgs.Count -gt 0) { " " + ($homepageFixtureArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "submit-timing-flow"
            goal = "Print the bounded Google-shaped keydown, keypress, and submit-ordering slice before running it."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $submitTimingFlow, $(if ($submitTimingArgs.Count -gt 0) { " " + ($submitTimingArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "submit-timing-runner"
            goal = "Run the bounded submit-timing slice directly when you need the smaller issue #3 timing proof without the rest of the stack."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $submitTimingRunner, $(if ($submitTimingArgs.Count -gt 0) { " " + ($submitTimingArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "shared-enter-order-flow"
            goal = "Print the stricter shared Enter-order ladder before running it once the saved homepage fixture and submit-timing slices agree."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $sharedEnterOrderFlow, $(if ($sharedEnterOrderArgs.Count -gt 0) { " " + ($sharedEnterOrderArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "shared-enter-order-runner"
            goal = "Run the stricter shared Enter-order ladder directly when you need the last bounded submit-order proof before attached HTML or live Google replay."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $sharedEnterOrderRunner, $(if ($sharedEnterOrderArgs.Count -gt 0) { " " + ($sharedEnterOrderArgs -join " ") } else { "" }))
        }
    )
    next_steps = @(
        "Use .\\scripts\\windows\\show_google_submit_path_trace_guide.ps1 after a failing bounded step when you want the later submit-path outputs translated into the next smaller checkpoint before you rerun anything.",
        "Use .\\scripts\\windows\\run_google_issue3_recommended_validation.ps1 when the earlier title or reduced-homepage gates are not green yet and you want the full localhost-first issue #3 ladder.",
        "Use .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1 after this slice is green when the current run has Google-like attached HTML snapshots to replay.",
        "Use .\\scripts\\windows\\show_google_trace_validation_flow.ps1 only after the saved homepage fixture, submit-timing, and shared Enter-order slices stay green together but the live homepage still diverges."
    )
    notes = @(
        "Start with the submit-path surface check so missing notes, trace helpers, wrappers, or probes fail fast before the later issue #3 ladder looks trustworthy.",
        "Start with the one-command submit-path runner unless you already know which later-stage slice is diverging.",
        "Keep the same host, shared input text, submit-timing input text, and port overrides here when you want the later submit-path checkpoints aligned with the broader issue #3 flow.",
        "Use the trace guide after a failing bounded slice when you need the quickest explanation of whether the remaining gap stayed in the saved homepage fixture, the Google-shaped submit-timing probe, or the stricter shared Enter-order ladder.",
        "Use -LeaveOpen only on the saved homepage fixture slice or the one-command runner when you want the headed browser left open for live inspection after the bounded phases finish."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows Google submit-path validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Host: {0}" -f $flow.host)
Write-Host ("Shared input text: {0}" -f $flow.shared_input_text)
Write-Host ("Submit-timing input text: {0}" -f $flow.submit_timing_input_text)
Write-Host ("Enter mutation suffix: {0}" -f $flow.enter_mutation_suffix)
Write-Host ("Homepage fixture port: {0}" -f $flow.homepage_fixture_port)
Write-Host ("Submit-timing port: {0}" -f $flow.submit_timing_port)
Write-Host ("Shared Enter-order port: {0}" -f $flow.shared_enter_order_port)
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
