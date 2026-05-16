[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
    [string[]]$FixturePath,
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

function Format-ScriptCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [System.Collections.Generic.List[string]]$Arguments,
        [string[]]$Switches = @()
    )

    $command = "powershell -ExecutionPolicy Bypass -File $ScriptPath"
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

function Format-ScriptCommandWithRepoRootEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
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

        return Format-ScriptCommand -ScriptPath $ScriptPath -Arguments $fallbackArguments -Switches $Switches
    }

    $command = "& '$ScriptPath'"
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

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $InputPath

$fixtureProbeArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedPathArrayArgument -Arguments $fixtureProbeArguments -Name FixturePaths -Values $FixturePath

$attachedHelperArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $attachedHelperArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $attachedHelperArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $attachedHelperArguments -Name InputPath -Values $InputPath

$bundleRunnerArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleRunnerArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleRunnerArguments -Name InputPath -Values $InputPath

$helper = [ordered]@{
    issue = 'Google issue #3 local HTML fixtures quickstart'
    purpose = 'Print the shortest issue #3 bridge from the reusable local-html-fixtures validation route into the fixed three-page compatibility bundle and the attached-html helper chain.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    explicit_fixture_path_count = if ($FixturePath) { @($FixturePath).Count } else { 0 }
    windows_full_use_note_path = 'docs/WINDOWS_FULL_USE.md'
    attached_html_change_area_note_path = 'docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md'
    top_level_attached_html_quickstart_note_path = 'docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_QUICKSTART.md'
    commands = [ordered]@{
        local_html_fixtures_change_area = Format-ScriptCommandWithRepoRootEnv -ScriptPath '.\scripts\windows\show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'local-html-fixtures'
        }) -RepoRootOverride $RepoRoot
        local_html_fixtures_surface_check = Format-ScriptCommandWithRepoRootEnv -ScriptPath '.\scripts\windows\check_local_html_fixture_validation_surface.ps1' -RepoRootOverride $RepoRoot
        local_html_fixtures_probe = Format-ScriptCommandWithRepoRootEnv -ScriptPath '.\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1' -Arguments ([ordered]@{
            FixturePaths = @($FixturePath)
        }) -RepoRootOverride $RepoRoot
        attached_bundle_change_area = Format-ScriptCommandWithRepoRootEnv -ScriptPath '.\scripts\windows\show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'attached-html-target-bundle'
        }) -RepoRootOverride $RepoRoot
        attached_bundle_first = Format-ScriptCommand -ScriptPath '.\scripts\windows\show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $attachedHelperArguments
        attached_bundle_runner = Format-ScriptCommand -ScriptPath '.\scripts\windows\run_attached_html_target_bundle_validation.ps1' -Arguments $bundleRunnerArguments -Switches @('Wait')
        attached_html_change_area_quickstart = Format-ScriptCommand -ScriptPath '.\scripts\windows\show_google_issue3_attached_html_change_area_quickstart.ps1' -Arguments $attachedHelperArguments
        top_level_attached_html_quickstart = Format-ScriptCommand -ScriptPath '.\scripts\windows\show_google_issue3_top_level_attached_html_quickstart.ps1' -Arguments $attachedHelperArguments
        replay_shortcuts = Format-ScriptCommand -ScriptPath '.\scripts\windows\show_google_issue3_replay_shortcuts.ps1' -Arguments $attachedHelperArguments
        safe_route_entrypoints = Format-ScriptCommand -ScriptPath '.\scripts\windows\show_google_issue3_safe_route_entrypoints.ps1' -Arguments $attachedHelperArguments
    }
    notes = @(
        'Start with local_html_fixtures_change_area when the shared validation router already narrowed the replay to the reusable fixed-list localhost fixture path.',
        'Run local_html_fixtures_surface_check first after branch updates so the reusable fixture probe chain fails fast before you stage the three saved compatibility pages behind localhost.',
        'Use local_html_fixtures_probe when the current replay should stay on the fixed three-page fixture list for screenshot and title proof before you widen into the broader issue #3 helper chain.',
        'Use attached_bundle_change_area and attached_bundle_first when the same three saved pages need the tighter issue #3 bundle-first route after the generic fixture replay is green or when you want the pinned bundle guide reprinted before rerunning attached-html follow-up.',
        'Use attached_bundle_runner when the current inputs are already pinned through InputPath and you want the delegated attached-html bundle route to execute directly.',
        'Use attached_html_change_area_quickstart when the broader fixture replay already proved the three-page bundle is the next useful issue #3 branch and you want the shorter attached-page bridge reprinted before dropping deeper into the helper chain.',
        'Use top_level_attached_html_quickstart when the replay is already narrowed enough that the compact top-level attached-page route is the next best helper after the generic fixture pass.',
        'Use replay_shortcuts only after the fixed-list fixture replay or the bundle-first route makes the next issue #3 failure state clear.',
        'Use safe_route_entrypoints only after the route is already narrow enough that the wrapper-heavy issue #3 command surface is the next useful layer.',
        'Keep WINDOWS_FULL_USE.md nearby when reopening the broader Windows-first localhost validation runbook before or after this compact fixture route.'
    )
}

$helper.recommended_next_key = if ($helper.explicit_fixture_path_count -gt 0) {
    'local_html_fixtures_probe'
} elseif ($helper.explicit_input_path_count -gt 0) {
    'attached_bundle_first'
} else {
    'local_html_fixtures_surface_check'
}
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = if ($helper.recommended_next_key -eq 'local_html_fixtures_probe') {
    'Explicit fixture paths are already in play, so go straight from the reusable surface check to the fixed-list localhost probe before widening into the issue #3 attached-html helpers.'
} elseif ($helper.recommended_next_key -eq 'attached_bundle_first') {
    'Explicit input paths are already pinned, so stay on the tighter bundle-first issue #3 route instead of reopening the generic fixture path first.'
} else {
    'No fixture list or pinned bundle input is attached yet, so start with the reusable fixture surface check and let that route fail fast before you decide whether the next step should stay generic or narrow into the issue #3 attached-page helpers.'
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 local HTML fixtures quickstart'
Write-Host ''
if ($helper.repo_root) {
    Write-Host (("Repo root:   {0}") -f $helper.repo_root)
}
if ($helper.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($helper.summary_path)"))
}
if ($helper.explicit_fixture_path_count -gt 0) {
    Write-Host (("Fixture paths: {0}") -f $helper.explicit_fixture_path_count)
}
if ($helper.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths:   {0}") -f $helper.explicit_input_path_count)
}
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $helper.recommended_next_command)
Write-Host (("Why:                    {0}") -f $helper.recommended_next_reason)
Write-Host ''
Write-Host 'Reusable local-fixture route:'
Write-Host (("  Change area:    {0}") -f $helper.commands.local_html_fixtures_change_area)
Write-Host (("  Surface check:  {0}") -f $helper.commands.local_html_fixtures_surface_check)
Write-Host (("  Fixture probe:  {0}") -f $helper.commands.local_html_fixtures_probe)
Write-Host ''
Write-Host 'Issue #3 attached-page follow-up:'
Write-Host (("  Bundle change area:   {0}") -f $helper.commands.attached_bundle_change_area)
Write-Host (("  Bundle-first helper:  {0}") -f $helper.commands.attached_bundle_first)
Write-Host (("  Bundle runner:        {0}") -f $helper.commands.attached_bundle_runner)
Write-Host (("  Change-area quick:    {0}") -f $helper.commands.attached_html_change_area_quickstart)
Write-Host (("  Top-level quick:      {0}") -f $helper.commands.top_level_attached_html_quickstart)
Write-Host (("  Replay shortcuts:     {0}") -f $helper.commands.replay_shortcuts)
Write-Host (("  Safe-route map:       {0}") -f $helper.commands.safe_route_entrypoints)
Write-Host ''
Write-Host (("Windows runbook note:   {0}") -f (' ' + $helper.windows_full_use_note_path))
Write-Host (("Attached-html note:     {0}") -f (' ' + $helper.attached_html_change_area_note_path))
Write-Host (("Top-level quickstart:   {0}") -f (' ' + $helper.top_level_attached_html_quickstart_note_path))
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $helper.notes) {
    Write-Host (("- {0}") -f $note)
}
