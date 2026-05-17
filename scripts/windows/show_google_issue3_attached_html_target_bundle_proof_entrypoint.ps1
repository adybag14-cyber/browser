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

function Format-PowerShellFileCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [System.Collections.Generic.List[string]]$Arguments,
        [string[]]$Switches = @()
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\\$RelativePath"
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
            if ($entry.Value -is [System.Array]) {
                Add-SharedPathArrayArgument -Arguments $fallbackArguments -Name $entry.Key -Values $entry.Value
            } else {
                Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $entry.Value
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
        if ($value -is [System.Array]) {
            $command += " -$($entry.Key)"
            foreach ($item in $value) {
                $escapedItem = ("$item") -replace "'", "''"
                $command += " '$escapedItem'"
            }
            continue
        }

        $escapedValue = ("$value") -replace "'", "''"
        $command += " -$($entry.Key) '$escapedValue'"
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

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$fixtureSurfaceArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $fixtureSurfaceArguments -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $fixtureSurfaceArguments -Name InputPath -Values $InputPath

$fixtureProbeArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $fixtureProbeArguments -Name RepoRoot -Value $RepoRoot
if ($InputPath -and $InputPath.Count -gt 0) {
    Add-SharedPathArrayArgument -Arguments $fixtureProbeArguments -Name FixturePaths -Values $InputPath
} else {
    $fixtureProbeArguments.Add('-FixturePaths')
    $fixtureProbeArguments.Add("'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html'")
    $fixtureProbeArguments.Add("'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html'")
    $fixtureProbeArguments.Add("'Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html'")
}

$attachedHtmlFlowArguments = [ordered]@{}
if ($InputPath -and $InputPath.Count -gt 0) {
    $attachedHtmlFlowArguments['InputPath'] = @($InputPath)
}

$entrypoint = [ordered]@{
    issue = 'Google issue #3 attached-html target-bundle proof entrypoint'
    purpose = 'Print the shortest read-first follow-up after the pinned three-page bundle replay so the fixed-list screenshot-and-title proof stays attached to the same bundle inputs before the route widens back into the broader attached-page helper chain.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    bundle_surface_check_command = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle_validation_surface.ps1' -Arguments $bundleArguments
    bundle_check_command = Format-HelperCommand -ScriptName 'check_attached_html_target_bundle.ps1' -Arguments $bundleArguments
    bundle_flow_command = Format-HelperCommand -ScriptName 'show_attached_html_target_bundle_validation_flow.ps1' -Arguments $bundleArguments
    bundle_runner_command = Format-HelperCommand -ScriptName 'run_attached_html_target_bundle_validation.ps1' -Arguments $bundleArguments -Switches @('Wait')
    local_html_fixture_surface_check_command = Format-HelperCommand -ScriptName 'check_local_html_fixture_validation_surface.ps1' -Arguments $fixtureSurfaceArguments
    local_html_fixture_probe_command = Format-PowerShellFileCommand -RelativePath 'tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1' -Arguments $fixtureProbeArguments
    broader_attached_html_flow_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
    google_attached_html_flow_command = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot
    bundle_suite_surface_command = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $bundleArguments
    bundle_first_entrypoint_command = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
    checklist_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_CHECKLIST.md'
    reference_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_REFERENCE.md'
    quickstart_note_path = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_QUICKSTART.md'
    google_attached_html_flow_note_path = 'docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md'
    notes = @(
        'Use this helper only after the pinned bundle route is already the right next step or after the delegated bundle runner has already turned green for the same three-page compatibility set.',
        'Run bundle_surface_check_command and bundle_check_command first when you want one last fail-fast confirmation that the current pages still match the known three-page compatibility bundle before you collect proof.',
        'Use bundle_flow_command and bundle_runner_command when the delegated localhost replay still needs to run before the fixed-list screenshot-and-title proof.',
        'Use local_html_fixture_surface_check_command and local_html_fixture_probe_command immediately after the bundle replay when you want tighter evidence for the same pinned inputs without reopening the broader attached-page wrapper flow.',
        'Keep broader_attached_html_flow_command and google_attached_html_flow_command nearby when the proof pass makes it clear that the next replay should widen back into the broader attached-page route or the dedicated Google-shaped attached-page lane.',
        'When explicit InputPath values are already pinned, this helper preserves the same repeated paths on the bundle check, bundle runner, and fixed-list proof commands so the proof pass stays on the exact same three inputs.',
        'When explicit InputPath values are not pinned yet, the fixed-list proof command prints the exact saved filenames from the known three-page compatibility bundle so the narrower screenshot-and-title pass can be replayed without re-deriving placeholder names from the reference note.',
        'Keep the checklist, reference, and quickstart notes nearby when you want the page-by-page manual checks and bundle-first bridge visible beside this proof-only follow-up.'
    )
}

if ($Json) {
    $entrypoint | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 attached-html target-bundle proof entrypoint'
Write-Host ''
if ($entrypoint.repo_root) {
    Write-Host (("Repo root:   {0}") -f $entrypoint.repo_root)
}
if ($entrypoint.summary_path) {
    Write-Host (("Summary path:{0}") -f (" $($entrypoint.summary_path)"))
}
if ($entrypoint.explicit_input_path_count -gt 0) {
    Write-Host (("Input paths: {0}") -f $entrypoint.explicit_input_path_count)
}
Write-Host ''
Write-Host 'Bundle replay before proof:'
Write-Host (("  Surface check: {0}") -f $entrypoint.bundle_surface_check_command)
Write-Host (("  Bundle check:  {0}") -f $entrypoint.bundle_check_command)
Write-Host (("  Flow helper:   {0}") -f $entrypoint.bundle_flow_command)
Write-Host (("  Runner:        {0}") -f $entrypoint.bundle_runner_command)
Write-Host ''
Write-Host 'Fixed-list proof:'
Write-Host (("  Surface check: {0}") -f $entrypoint.local_html_fixture_surface_check_command)
Write-Host (("  Probe:         {0}") -f $entrypoint.local_html_fixture_probe_command)
Write-Host ''
Write-Host 'Widen back out when needed:'
Write-Host (("  Broader flow:  {0}") -f $entrypoint.broader_attached_html_flow_command)
Write-Host (("  Google flow:   {0}") -f $entrypoint.google_attached_html_flow_command)
Write-Host ''
Write-Host 'Related bundle re-entry:'
Write-Host (("  Suite surface: {0}") -f $entrypoint.bundle_suite_surface_command)
Write-Host (("  Bundle-first:  {0}") -f $entrypoint.bundle_first_entrypoint_command)
Write-Host ''
Write-Host (("Checklist note:  {0}") -f $entrypoint.checklist_note_path)
Write-Host (("Reference note:  {0}") -f $entrypoint.reference_note_path)
Write-Host (("Quickstart note: {0}") -f $entrypoint.quickstart_note_path)
Write-Host (("Google flow:     {0}") -f $entrypoint.google_attached_html_flow_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoint.notes) {
    Write-Host (("- {0}") -f $note)
}
