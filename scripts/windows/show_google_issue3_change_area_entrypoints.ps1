[CmdletBinding()]
param(
    [ValidateSet(
        'title',
        'quick',
        'home',
        'homepage-fixture',
        'home-keypress-submit',
        'submit-path',
        'submit-timing',
        'form-controls-enter-order',
        'shared-enter-order',
        'live-trace',
        'saved-html',
        'attached-html',
        'attached-html-target-bundle'
    )]
    [string]$ChangeArea = 'title',
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

function Add-SharedPathArrayArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string[]]$Values
    )

    if (-not $Values -or $Values.Count -eq 0) {
        return
    }

    $Arguments.Add("-$Name")
    foreach ($value in $Values) {
        $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $value))
    }
}

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [System.Collections.Generic.List[string]]$Arguments,
        [string[]]$Switches = @()
    )

    $command = ".\\scripts\\windows\\$ScriptName"
    if ($Arguments -and $Arguments.Count -gt 0) {
        $command += ' ' + ($Arguments -join ' ')
    }
    foreach ($switchName in $Switches) {
        if ([string]::IsNullOrWhiteSpace($switchName)) {
            continue
        }

        $command += " -$switchName"
    }

    return "powershell -ExecutionPolicy Bypass -File $command"
}

function Format-HelperCommandWithRepoRootEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [hashtable]$Arguments = @{},
        [string[]]$Switches = @(),
        [string]$RepoRootOverride
    )

    if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        $fallbackArguments = [System.Collections.Generic.List[string]]::new()
        foreach ($entry in $Arguments.GetEnumerator()) {
            $value = $entry.Value
            if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
                Add-SharedPathArrayArgument -Arguments $fallbackArguments -Name $entry.Key -Values @($value)
            } else {
                Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $value
            }
        }
        return Format-HelperCommand -ScriptName $ScriptName -Arguments $fallbackArguments -Switches $Switches
    }

    $command = "& '.\\scripts\\windows\\$ScriptName'"
    foreach ($entry in $Arguments.GetEnumerator()) {
        $value = $entry.Value
        if ($null -eq $value) {
            continue
        }
        if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            continue
        }
        if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
            $valueList = @($value | Where-Object {
                if ($_ -is [string]) {
                    -not [string]::IsNullOrWhiteSpace($_)
                } else {
                    $null -ne $_
                }
            })
            if ($valueList.Count -eq 0) {
                continue
            }

            $command += " -$($entry.Key)"
            foreach ($item in $valueList) {
                $escapedItem = ("$item") -replace "'", "''"
                $command += " '$escapedItem'"
            }
            continue
        }

        $escapedValue = ("$value") -replace "'", "''"
        $command += (" -{0} '{1}'" -f $entry.Key, $escapedValue)
    }

    foreach ($switchName in $Switches) {
        if ([string]::IsNullOrWhiteSpace($switchName)) {
            continue
        }

        $command += " -$switchName"
    }

    $escapedRepoRoot = ("$RepoRootOverride") -replace "'", "''"
    return "powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$env:LIGHTPANDA_REPO_ROOT = '$escapedRepoRoot'; $command`""
}

function Format-ChangeAreaEntrypointCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetChangeArea
    )

    $arguments = [System.Collections.Generic.List[string]]::new()
    Add-SharedArgument -Arguments $arguments -Name ChangeArea -Value $TargetChangeArea
    Add-SharedArgument -Arguments $arguments -Name RepoRoot -Value $RepoRoot
    Add-SharedArgument -Arguments $arguments -Name SummaryPath -Value $SummaryPath
    Add-SharedPathArrayArgument -Arguments $arguments -Name InputPath -Values $InputPath
    return Format-HelperCommand -ScriptName 'show_google_issue3_change_area_entrypoints.ps1' -Arguments $arguments
}

function New-PhaseEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Summary,
        [Parameter(Mandatory = $true)]
        [string]$RouterCommand,
        [string]$SuiteCommand,
        [string]$SurfaceCheckCommand,
        [string]$FlowCommand,
        [string]$RunnerCommand,
        [string[]]$CompanionCommands = @(),
        [string[]]$NextWhenGreen = @()
    )

    return [ordered]@{
        change_area = $ChangeArea
        summary = $Summary
        router_command = $RouterCommand
        suite_command = $SuiteCommand
        surface_check_command = $SurfaceCheckCommand
        flow_command = $FlowCommand
        runner_command = $RunnerCommand
        companion_commands = $CompanionCommands
        next_when_green = $NextWhenGreen
    }
}

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$replayContextArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $replayContextArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $replayContextArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $replayContextArguments -Name InputPath -Values $InputPath

$savedHtmlSurfaceArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $savedHtmlSurfaceArguments -Name RepoRoot -Value $RepoRoot

$savedHtmlFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $savedHtmlFlowArguments -Name RepoRoot -Value $RepoRoot
if ($InputPath -and $InputPath.Count -gt 0) {
    Add-SharedPathArrayArgument -Arguments $savedHtmlFlowArguments -Name InputPath -Values $InputPath
} else {
    $savedHtmlFlowArguments.Add('-InputPath')
    $savedHtmlFlowArguments.Add("'<saved-html-or-folder>'")
}

$localhostRunnerArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $localhostRunnerArguments -Name RepoRoot -Value $RepoRoot
if ($InputPath -and $InputPath.Count -gt 0) {
    Add-SharedPathArrayArgument -Arguments $localhostRunnerArguments -Name InputPath -Values $InputPath
}

$attachedHtmlSurfaceArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $attachedHtmlSurfaceArguments -Name RepoRoot -Value $RepoRoot

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath -and $InputPath.Count -gt 0) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$attachedHtmlRunnerArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $attachedHtmlRunnerArguments -Name RepoRoot -Value $RepoRoot
if ($InputPath -and $InputPath.Count -gt 0) {
    Add-SharedPathArrayArgument -Arguments $attachedHtmlRunnerArguments -Name InputPath -Values $InputPath
}

$attachedBundleSurfaceArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $attachedBundleSurfaceArguments -Name RepoRoot -Value $RepoRoot

$attachedBundleFlowArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $attachedBundleFlowArguments -Name RepoRoot -Value $RepoRoot
if ($InputPath -and $InputPath.Count -gt 0) {
    Add-SharedPathArrayArgument -Arguments $attachedBundleFlowArguments -Name InputPath -Values $InputPath
}

$attachedBundleRunnerArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $attachedBundleRunnerArguments -Name RepoRoot -Value $RepoRoot
if ($InputPath -and $InputPath.Count -gt 0) {
    Add-SharedPathArrayArgument -Arguments $attachedBundleRunnerArguments -Name InputPath -Values $InputPath
}

$phaseMap = @{
    'title' = (New-PhaseEntry `
        -Summary 'Narrowest real-surface title, focus, typing, and Enter-submit checkpoint before the broader reduced-home or later submit-path ladders.' `
        -RouterCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-input' }) -RepoRootOverride $RepoRoot) `
        -SuiteCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ SuiteName = 'google-title' }) -RepoRootOverride $RepoRoot) `
        -SurfaceCheckCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_title_validation_surface.ps1' `
        -FlowCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_validation_flow.ps1' `
        -RunnerCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_title_validation.ps1' `
        -CompanionCommands @(
            'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_title_probe_trace_guide.ps1'
        ) `
        -NextWhenGreen @(
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'quick'),
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'home')
        ))
    'quick' = (New-PhaseEntry `
        -Summary 'Fast title-plus-watch pass when the title checkpoint is already wired and you want a short rerun before widening into the reduced homepage or later timing slices.' `
        -RouterCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-input' }) -RepoRootOverride $RepoRoot) `
        -SuiteCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ SuiteName = 'google-quick' }) -RepoRootOverride $RepoRoot) `
        -SurfaceCheckCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_recommended_validation_surface.ps1' `
        -FlowCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_quick_validation_flow.ps1' `
        -RunnerCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_quick_validation.ps1' `
        -NextWhenGreen @(
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'home'),
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'homepage-fixture')
        ))
    'home' = (New-PhaseEntry `
        -Summary 'Reduced homepage focus, typing, keydown, and Enter-submit pass on the real headed surface after the localhost investigation probes are green.' `
        -RouterCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-input' }) -RepoRootOverride $RepoRoot) `
        -SuiteCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ SuiteName = 'google-home' }) -RepoRootOverride $RepoRoot) `
        -SurfaceCheckCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_issue3_recommended_validation_surface.ps1' `
        -FlowCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_input_validation_flow.ps1' `
        -RunnerCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_validation.ps1' `
        -NextWhenGreen @(
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'homepage-fixture'),
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'submit-timing')
        ))
    'homepage-fixture' = (New-PhaseEntry `
        -Summary 'Saved localhost Google homepage fixture checkpoint for focus, typed text, and Enter submit before the later Enter-order and submit-path wrappers.' `
        -RouterCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-submit-path' }) -RepoRootOverride $RepoRoot) `
        -SuiteCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ SuiteName = 'google-homepage-fixture' }) -RepoRootOverride $RepoRoot) `
        -SurfaceCheckCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_homepage_fixture_validation_surface.ps1' `
        -FlowCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_homepage_fixture_validation_flow.ps1' `
        -RunnerCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_homepage_fixture_validation.ps1' `
        -NextWhenGreen @(
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'home-keypress-submit'),
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'submit-path')
        ))
    'home-keypress-submit' = (New-PhaseEntry `
        -Summary 'Reduced-home keypress-before-submit bridge between the saved homepage fixture checkpoint and the broader submit-path or submit-timing ladders.' `
        -RouterCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-submit-path' }) -RepoRootOverride $RepoRoot) `
        -SuiteCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ SuiteName = 'google-home-keypress-submit' }) -RepoRootOverride $RepoRoot) `
        -SurfaceCheckCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_home_keypress_submit_validation_surface.ps1' `
        -FlowCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_home_keypress_submit_validation_flow.ps1' `
        -RunnerCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_home_keypress_submit_validation.ps1' `
        -NextWhenGreen @(
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'submit-path'),
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'submit-timing')
        ))
    'submit-path' = (New-PhaseEntry `
        -Summary 'Later-stage saved-homepage-fixture, reduced Enter-trace, submit-timing, and shared Enter-order ladder when the earlier title and reduced-home checkpoints are already green.' `
        -RouterCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-submit-path' }) -RepoRootOverride $RepoRoot) `
        -SuiteCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ SuiteName = 'google-submit-path' }) -RepoRootOverride $RepoRoot) `
        -SurfaceCheckCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_submit_path_validation_surface.ps1' `
        -FlowCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_validation_flow.ps1' `
        -RunnerCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_issue3_submit_path_validation.ps1' `
        -CompanionCommands @(
            'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_trace_guide.ps1',
            'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_path_handoff.ps1'
        ) `
        -NextWhenGreen @(
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'submit-timing'),
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'shared-enter-order')
        ))
    'submit-timing' = (New-PhaseEntry `
        -Summary 'Bounded keydown, keypress, and submit-ordering slice before the stricter shared Enter-order ladder or the live-trace handoff.' `
        -RouterCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-submit-path' }) -RepoRootOverride $RepoRoot) `
        -SuiteCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ SuiteName = 'google-submit-timing' }) -RepoRootOverride $RepoRoot) `
        -SurfaceCheckCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_submit_timing_validation_surface.ps1' `
        -FlowCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_submit_timing_validation_flow.ps1' `
        -RunnerCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_submit_timing_validation.ps1' `
        -NextWhenGreen @(
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'form-controls-enter-order'),
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'shared-enter-order')
        ))
    'form-controls-enter-order' = (New-PhaseEntry `
        -Summary 'Smallest shared form-controls keypress-before-submit gate before widening into the broader shared Enter-order stack.' `
        -RouterCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-form-controls-enter-order' }) -RepoRootOverride $RepoRoot) `
        -SuiteCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ SuiteName = 'google-form-controls-enter-order' }) -RepoRootOverride $RepoRoot) `
        -SurfaceCheckCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_form_controls_enter_order_validation_surface.ps1' `
        -FlowCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_validation_flow.ps1' `
        -RunnerCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_form_controls_enter_order_validation.ps1' `
        -CompanionCommands @(
            'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_form_controls_enter_order_trace_guide.ps1'
        ) `
        -NextWhenGreen @(
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'shared-enter-order')
        ))
    'shared-enter-order' = (New-PhaseEntry `
        -Summary 'Shared Enter-order ladder that combines label-click baseline, shared submit gates, reduced Google-home form coverage, and the stricter localhost keypress-before-submit wrapper.' `
        -RouterCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-form-controls-enter-order' }) -RepoRootOverride $RepoRoot) `
        -SuiteCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ SuiteName = 'google-shared-enter-order' }) -RepoRootOverride $RepoRoot) `
        -SurfaceCheckCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_shared_enter_order_validation_surface.ps1' `
        -FlowCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_shared_enter_order_validation_flow.ps1' `
        -RunnerCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_google_shared_enter_order_validation.ps1' `
        -NextWhenGreen @(
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'live-trace'),
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'saved-html')
        ))
    'live-trace' = (New-PhaseEntry `
        -Summary 'Read-first reduced-home and live Google trace-capture handoff once the bounded timing and shared Enter-order gates are green but the real homepage still diverges.' `
        -RouterCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-live-trace' }) -RepoRootOverride $RepoRoot) `
        -SuiteCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ SuiteName = 'google-live-trace' }) -RepoRootOverride $RepoRoot) `
        -SurfaceCheckCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_google_trace_validation_surface.ps1' `
        -FlowCommand 'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_trace_validation_flow.ps1' `
        -RunnerCommand '' `
        -NextWhenGreen @(
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'saved-html'),
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'attached-html')
        ))
    'saved-html' = (New-PhaseEntry `
        -Summary 'Saved-page localhost Google-style follow-up once the bounded issue #3 gates are green and you want the same command chain applied to exported or staged HTML pages.' `
        -RouterCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-saved-html' }) -RepoRootOverride $RepoRoot) `
        -SuiteCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ SuiteName = 'google-saved-html' }) -RepoRootOverride $RepoRoot) `
        -SurfaceCheckCommand (Format-HelperCommand -ScriptName 'check_saved_page_localhost_validation_surface.ps1' -Arguments $savedHtmlSurfaceArguments) `
        -FlowCommand (Format-HelperCommand -ScriptName 'show_saved_page_google_validation_flow.ps1' -Arguments $savedHtmlFlowArguments) `
        -RunnerCommand (Format-HelperCommand -ScriptName 'run_localhost_html_validation_recommended.ps1' -Arguments $localhostRunnerArguments -Switches @('Wait')) `
        -NextWhenGreen @(
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'attached-html'),
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'attached-html-target-bundle')
        ))
    'attached-html' = (New-PhaseEntry `
        -Summary 'Google-style attached-page localhost follow-up for current-run HTML after the bounded issue #3 gates are green.' `
        -RouterCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-attached-html' }) -RepoRootOverride $RepoRoot) `
        -SuiteCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ SuiteName = 'google-attached-html' }) -RepoRootOverride $RepoRoot) `
        -SurfaceCheckCommand (Format-HelperCommand -ScriptName 'check_google_attached_html_validation_surface.ps1' -Arguments $attachedHtmlSurfaceArguments) `
        -FlowCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot) `
        -RunnerCommand (Format-HelperCommand -ScriptName 'run_google_attached_html_validation.ps1' -Arguments $attachedHtmlRunnerArguments -Switches @('Wait')) `
        -CompanionCommands @(
            (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'attached-html' }) -RepoRootOverride $RepoRoot),
            (Format-HelperCommand -ScriptName 'show_google_issue3_top_level_attached_html_entrypoint.ps1' -Arguments $replayContextArguments),
            (Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $replayContextArguments)
        ) `
        -NextWhenGreen @(
            (Format-ChangeAreaEntrypointCommand -TargetChangeArea 'attached-html-target-bundle')
        ))
    'attached-html-target-bundle' = (New-PhaseEntry `
        -Summary 'Pinned three-page attached-HTML compatibility route when the current follow-up inputs are still the known bundle and you want the fail-fast bundle checker plus the delegated localhost runner.' `
        -RouterCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'attached-html-target-bundle' }) -RepoRootOverride $RepoRoot) `
        -SuiteCommand (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ SuiteName = 'attached-html-target-bundle' }) -RepoRootOverride $RepoRoot) `
        -SurfaceCheckCommand (Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $attachedBundleSurfaceArguments) `
        -FlowCommand (Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $attachedBundleFlowArguments) `
        -RunnerCommand (Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $attachedBundleRunnerArguments -Switches @('Wait')) `
        -CompanionCommands @(
            (Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $replayContextArguments),
            (Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'attached-html' }) -RepoRootOverride $RepoRoot)
        ) `
        -NextWhenGreen @(
            'Use the saved screenshots, titles, and localhost summaries to choose the next shared engine fix or the next narrower bundle-specific regression probe.'
        ))
}

$entry = $phaseMap[$ChangeArea]
if (-not $entry) {
    throw "Unknown issue #3 change area: $ChangeArea"
}

$entry['repo_root'] = $RepoRoot
$entry['summary_path'] = $SummaryPath
$entry['explicit_input_path_count'] = if ($InputPath) { @($InputPath).Count } else { 0 }
if ($InputPath -and $InputPath.Count -gt 0) {
    $entry['input_path'] = @($InputPath)
}

if ($Json) {
    $entry | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Issue #3 change-area entrypoints'
Write-Host ''
if ($entry.repo_root) {
    Write-Host ("Repo root:   {0}" -f $entry.repo_root)
}
if ($entry.summary_path) {
    Write-Host ("Summary path:{0}" -f (" $($entry.summary_path)"))
}
if ($entry.explicit_input_path_count -gt 0) {
    Write-Host ("Input paths: {0}" -f $entry.explicit_input_path_count)
}
if ($entry.repo_root -or $entry.summary_path -or $entry.explicit_input_path_count -gt 0) {
    Write-Host ''
}
Write-Host ("Change area: {0}" -f $ChangeArea)
Write-Host ("Summary: {0}" -f $entry.summary)
Write-Host ''
Write-Host ("Shared router: {0}" -f $entry.router_command)
if ($entry.suite_command) {
    Write-Host ("Suite route: {0}" -f $entry.suite_command)
}
if ($entry.surface_check_command) {
    Write-Host ("Surface check: {0}" -f $entry.surface_check_command)
}
if ($entry.flow_command) {
    Write-Host ("Flow helper: {0}" -f $entry.flow_command)
}
if ($entry.runner_command) {
    Write-Host ("Runner: {0}" -f $entry.runner_command)
}
if ($entry.companion_commands.Count -gt 0) {
    Write-Host ''
    Write-Host 'Companion commands:'
    foreach ($command in $entry.companion_commands) {
        Write-Host ("- {0}" -f $command)
    }
}
if ($entry.next_when_green.Count -gt 0) {
    Write-Host ''
    Write-Host 'Next when green:'
    foreach ($next in $entry.next_when_green) {
        Write-Host ("- {0}" -f $next)
    }
}
