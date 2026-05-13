[CmdletBinding()]
param(
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

    $command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\$ScriptName"
    if ($Arguments -and $Arguments.Count -gt 0) {
        $command += " " + ($Arguments -join ' ')
    }
    foreach ($switchName in $Switches) {
        if ([string]::IsNullOrWhiteSpace($switchName)) {
            continue
        }

        $command += " -$switchName"
    }

    return $command
}

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath

$bundleFirstArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleFirstArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleFirstArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleFirstArguments -Name InputPath -Values $InputPath

$bundleRouteArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleRouteArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleRouteArguments -Name InputPath -Values $InputPath

$shortcuts = [ordered]@{
    issue = 'Google issue #3 replay shortcuts'
    purpose = 'Keep the top-level issue #3 read-first commands, the narrower safe-route helper, and the attached three-page bundle route on one compact command surface.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    decision_table_note_path = 'docs/ISSUE3_RUNNER_PATCH_DECISION_TABLE.md'
    read_first_commands = [ordered]@{
        suite_router = '.\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-recommended'
        change_area = '.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input'
        google_flow = 'powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_input_validation_flow.ps1'
        attached_bundle_suite = '.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle'
    }
    helper_commands = [ordered]@{
        safe_route_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $sharedArguments
        attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleFirstArguments
        attached_bundle_flow = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleRouteArguments
        attached_bundle_runner = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleRouteArguments -Switches @('Wait')
        fresh_safe_route_replay = Format-HelperCommand -ScriptName 'run_google_issue3_recommended_validation_safe_route_runner_patch_handoff.ps1' -Arguments $sharedArguments
        reuse_current_outputs = Format-HelperCommand -ScriptName 'show_google_issue3_validation_safe_route_runner_patch_wrapper.ps1' -Arguments $sharedArguments
    }
    notes = @(
        'Start with suite_router when you want the higher-level catalog to surface the broader issue #3 runner first.',
        'Use change_area when you may need a narrower title, homepage-fixture, submit-path, shared Enter-order, attached-page, or live-trace branch instead of the broader recommended replay.',
        'Use google_flow when you want the current localhost-first issue #3 ladder printed before you choose between the narrower safe-route replay, the attached bundle route, or a later-stage Google slice.',
        'Use safe_route_entrypoints when outputs may already exist and you want the newest issue #3 wrapper commands, notes, and next-state helpers printed in one place.',
        'Use attached_bundle_first when the current saved or attached pages are the known three-page compatibility bundle and you want that route exercised before reopening the broader Google-only wrapper chain.',
        'Use fresh_safe_route_replay when current issue #3 outputs may be stale or missing. Use reuse_current_outputs only when the current saved outputs are already trusted.',
        'Keep quickstart_note_path open for the shortest current replay note, validation_chain_note_path for wrapper precedence, and decision_table_note_path when the runner patch handoff lands on ready-for-runner-patch, already-direct, or runner-already-wired-regenerate-outputs.'
    )
}

if ($Json) {
    $shortcuts | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 replay shortcuts'
Write-Host ''
if ($shortcuts.repo_root) {
    Write-Host ("Repo root:   {0}" -f $shortcuts.repo_root)
}
if ($shortcuts.summary_path) {
    Write-Host ("Summary path:{0}" -f " $($shortcuts.summary_path)")
}
if ($shortcuts.explicit_input_path_count -gt 0) {
    Write-Host ("Input paths: {0}" -f $shortcuts.explicit_input_path_count)
}
Write-Host ''
Write-Host 'Read-first discovery:'
Write-Host ("  Suite router:         {0}" -f $shortcuts.read_first_commands.suite_router)
Write-Host ("  Change-area view:     {0}" -f $shortcuts.read_first_commands.change_area)
Write-Host ("  Google flow helper:   {0}" -f $shortcuts.read_first_commands.google_flow)
Write-Host ("  Bundle suite route:   {0}" -f $shortcuts.read_first_commands.attached_bundle_suite)
Write-Host ''
Write-Host 'Shortcut helpers:'
Write-Host ("  Safe route entrypoints: {0}" -f $shortcuts.helper_commands.safe_route_entrypoints)
Write-Host ("  Bundle-first helper:    {0}" -f $shortcuts.helper_commands.attached_bundle_first)
Write-Host ("  Bundle flow helper:     {0}" -f $shortcuts.helper_commands.attached_bundle_flow)
Write-Host ("  Bundle runner:          {0}" -f $shortcuts.helper_commands.attached_bundle_runner)
Write-Host ("  Fresh safe replay:      {0}" -f $shortcuts.helper_commands.fresh_safe_route_replay)
Write-Host ("  Reuse current outputs:  {0}" -f $shortcuts.helper_commands.reuse_current_outputs)
Write-Host ''
Write-Host ("Quickstart note:       {0}" -f $shortcuts.quickstart_note_path)
Write-Host ("Validation chain note: {0}" -f $shortcuts.validation_chain_note_path)
Write-Host ("Decision table:        {0}" -f $shortcuts.decision_table_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $shortcuts.notes) {
    Write-Host ("- {0}" -f $note)
}
