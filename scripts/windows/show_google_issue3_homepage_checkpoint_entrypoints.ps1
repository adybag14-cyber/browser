[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [int]$HomepageFixturePort = 8155,
    [int]$ReducedHomeKeypressPort = 8167,
    [int]$SubmitTimingPort = 8181,
    [int]$SharedEnterOrderPort = 8157,
    [string]$SharedInputText = "Q",
    [string]$SubmitTimingInputText = "QZ",
    [string]$EnterMutationSuffix = "!",
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

$homepageFixtureSurfaceCheck = '.\scripts\windows\check_google_homepage_fixture_validation_surface.ps1'
$homepageFixtureFlow = '.\scripts\windows\show_google_homepage_fixture_validation_flow.ps1'
$homepageFixtureRunner = '.\scripts\windows\run_google_homepage_fixture_validation.ps1'
$homeKeypressSurfaceCheck = '.\scripts\windows\check_google_home_keypress_submit_validation_surface.ps1'
$homeKeypressFlow = '.\scripts\windows\show_google_home_keypress_submit_validation_flow.ps1'
$homeKeypressRunner = '.\scripts\windows\run_google_home_keypress_submit_validation.ps1'
$submitPathSurfaceCheck = '.\scripts\windows\check_google_submit_path_validation_surface.ps1'
$submitPathFlow = '.\scripts\windows\show_google_submit_path_validation_flow.ps1'
$submitPathRunner = '.\scripts\windows\run_google_issue3_submit_path_validation.ps1'
$submitTimingFlow = '.\scripts\windows\show_google_submit_timing_validation_flow.ps1'
$submitTimingRunner = '.\scripts\windows\run_google_submit_timing_validation.ps1'
$formControlsEnterOrderSurfaceCheck = '.\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1'
$formControlsEnterOrderFlow = '.\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1'
$formControlsEnterOrderTraceGuide = '.\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1'
$formControlsEnterOrderRunner = '.\scripts\windows\run_google_form_controls_enter_order_validation.ps1'

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

$homeKeypressArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $homeKeypressArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $homeKeypressArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $homeKeypressArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $homeKeypressArgs -Name ReducedHomeKeypressPort -Value $ReducedHomeKeypressPort
Add-SharedArgument -Arguments $homeKeypressArgs -Name InputText -Value $SubmitTimingInputText
Add-SharedArgument -Arguments $homeKeypressArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $homeKeypressArgs -Name WindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $homeKeypressArgs -Name TitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $homeKeypressArgs -Name PollMilliseconds -Value $HomePollMilliseconds
if ($LeaveOpen) {
    $homeKeypressArgs.Add('-LeaveOpen')
}

$submitPathArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $submitPathArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $submitPathArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $submitPathArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $submitPathArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $submitPathArgs -Name SubmitTimingInputText -Value $SubmitTimingInputText
Add-SharedArgument -Arguments $submitPathArgs -Name EnterMutationSuffix -Value $EnterMutationSuffix
Add-SharedArgument -Arguments $submitPathArgs -Name HomepageFixturePort -Value $HomepageFixturePort
Add-SharedArgument -Arguments $submitPathArgs -Name SubmitTimingPort -Value $SubmitTimingPort
Add-SharedArgument -Arguments $submitPathArgs -Name SharedEnterOrderPort -Value $SharedEnterOrderPort
Add-SharedArgument -Arguments $submitPathArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $submitPathArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $submitPathArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $submitPathArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds
if ($LeaveOpen) {
    $submitPathArgs.Add('-LeaveOpen')
}

$submitTimingArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $submitTimingArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $submitTimingArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $submitTimingArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $submitTimingArgs -Name SubmitTimingPort -Value $SubmitTimingPort
Add-SharedArgument -Arguments $submitTimingArgs -Name InputText -Value $SubmitTimingInputText

$formControlsEnterOrderArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $formControlsEnterOrderArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $formControlsEnterOrderArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $formControlsEnterOrderArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $formControlsEnterOrderArgs -Name SharedInputText -Value $SharedInputText
Add-SharedArgument -Arguments $formControlsEnterOrderArgs -Name EnterMutationSuffix -Value $EnterMutationSuffix
Add-SharedArgument -Arguments $formControlsEnterOrderArgs -Name SharedEnterOrderPort -Value $SharedEnterOrderPort
Add-SharedArgument -Arguments $formControlsEnterOrderArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $formControlsEnterOrderArgs -Name HomeWindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $formControlsEnterOrderArgs -Name HomeTitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $formControlsEnterOrderArgs -Name HomePollMilliseconds -Value $HomePollMilliseconds

function Join-Command {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments
    )

    if ($Arguments.Count -eq 0) {
        return "powershell -ExecutionPolicy Bypass -File $ScriptPath"
    }

    return "powershell -ExecutionPolicy Bypass -File $ScriptPath $($Arguments -join ' ')"
}

$flow = [ordered]@{
    issue = "Issue #3 homepage checkpoint entrypoints"
    focus = "Compact command bridge from the saved homepage fixture checkpoint into the smaller real-surface keypress-before-submit proof and the broader later submit-path stack."
    leave_open = [bool]$LeaveOpen
    steps = @(
        [ordered]@{
            name = "homepage-fixture-surface-check"
            goal = "Fail fast if the saved homepage fixture checkpoint drifted before you depend on it."
            command = "powershell -ExecutionPolicy Bypass -File $homepageFixtureSurfaceCheck"
        }
        [ordered]@{
            name = "homepage-fixture-flow"
            goal = "Print the bounded saved-homepage checkpoint before running it."
            command = Join-Command -ScriptPath $homepageFixtureFlow -Arguments $homepageFixtureArgs
        }
        [ordered]@{
            name = "homepage-fixture-runner"
            goal = "Run the bounded saved-homepage checkpoint that proves focus, typed text, and Enter submit on localhost."
            command = Join-Command -ScriptPath $homepageFixtureRunner -Arguments $homepageFixtureArgs
        }
        [ordered]@{
            name = "home-keypress-surface-check"
            goal = "Fail fast if the smaller keypress-before-submit bridge drifted before you trust it."
            command = "powershell -ExecutionPolicy Bypass -File $homeKeypressSurfaceCheck"
        }
        [ordered]@{
            name = "home-keypress-flow"
            goal = "Print the reduced-home keypress-before-submit bridge before running it."
            command = Join-Command -ScriptPath $homeKeypressFlow -Arguments $homeKeypressArgs
        }
        [ordered]@{
            name = "home-keypress-runner"
            goal = "Run the smaller real-surface keypress-before-submit bridge between the fixture checkpoint and the later submit-path ladder."
            command = Join-Command -ScriptPath $homeKeypressRunner -Arguments $homeKeypressArgs
        }
        [ordered]@{
            name = "submit-path-surface-check"
            goal = "Fail fast if the broader later submit-path ladder drifted."
            command = "powershell -ExecutionPolicy Bypass -File $submitPathSurfaceCheck"
        }
        [ordered]@{
            name = "submit-path-flow"
            goal = "Print the later-stage submit-path ladder once the smaller checkpoints are green."
            command = Join-Command -ScriptPath $submitPathFlow -Arguments $submitPathArgs
        }
        [ordered]@{
            name = "submit-path-runner"
            goal = "Run the broader later submit-path ladder when you want the saved homepage fixture, submit timing, and shared Enter-order chain in one pass."
            command = Join-Command -ScriptPath $submitPathRunner -Arguments $submitPathArgs
        }
        [ordered]@{
            name = "submit-timing-flow"
            goal = "Print the narrower bounded timing slice when you want that step without the full later ladder."
            command = Join-Command -ScriptPath $submitTimingFlow -Arguments $submitTimingArgs
        }
        [ordered]@{
            name = "submit-timing-runner"
            goal = "Run the narrower bounded timing slice directly."
            command = Join-Command -ScriptPath $submitTimingRunner -Arguments $submitTimingArgs
        }
        [ordered]@{
            name = "form-controls-enter-order-surface-check"
            goal = "Fail fast if the smallest shared Enter-order checkpoint drifted."
            command = "powershell -ExecutionPolicy Bypass -File $formControlsEnterOrderSurfaceCheck"
        }
        [ordered]@{
            name = "form-controls-enter-order-flow"
            goal = "Print the smallest shared Enter-order checkpoint before running it."
            command = Join-Command -ScriptPath $formControlsEnterOrderFlow -Arguments $formControlsEnterOrderArgs
        }
        [ordered]@{
            name = "form-controls-enter-order-trace-guide"
            goal = "Translate the smallest shared checkpoint markers into the next narrowing step."
            command = "powershell -ExecutionPolicy Bypass -File $formControlsEnterOrderTraceGuide"
        }
        [ordered]@{
            name = "form-controls-enter-order-runner"
            goal = "Run the smallest shared Enter-order checkpoint directly."
            command = Join-Command -ScriptPath $formControlsEnterOrderRunner -Arguments $formControlsEnterOrderArgs
        }
    )
    notes = @(
        "Start with the homepage fixture checkpoint, then move to the reduced-home keypress-before-submit bridge before widening into the broader submit-path ladder.",
        "Use the submit-timing slice when you want the narrower timing proof without the full later-stage wrapper chain.",
        "Use the dedicated form-controls Enter-order checkpoint when the homepage-shaped gates are already green and you want the smallest shared proof before manual or attached-page replay.",
        "Keep the same repo root, browser path, host, ports, and input text across these commands when you want the checkpoints to stay comparable."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Issue #3 homepage checkpoint entrypoints"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Leave open after supported runners: {0}" -f $flow.leave_open)
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
