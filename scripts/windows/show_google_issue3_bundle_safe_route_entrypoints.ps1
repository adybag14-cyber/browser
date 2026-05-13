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
        [string[]]$Switches = @(),
        [System.Collections.Generic.List[string]]$Arguments
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

$bundleArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $bundleArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $bundleArguments -Name InputPath -Values $InputPath

$safeRouteArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $safeRouteArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $safeRouteArguments -Name SummaryPath -Value $SummaryPath

$entrypoints = [ordered]@{
    issue = 'Google issue #3 bundle safe-route entrypoints'
    purpose = 'Print the pinned three-page compatibility bundle-first helper and the broader issue #3 safe-route entrypoints together so Windows replay can stay on the current bounded path before widening.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    suite_router_command = '.\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html-target-bundle'
    bundle_first_entrypoint_command = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments
    safe_route_entrypoints_command = Format-HelperCommand -ScriptName 'show_google_issue3_safe_route_entrypoints.ps1' -Arguments $safeRouteArguments
    validation_chain_note_path = 'docs/ISSUE3_WINDOWS_VALIDATION_CHAIN.md'
    quickstart_note_path = 'docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md'
    notes = @(
        'Use this helper when the current saved or attached pages are still the known three-page compatibility bundle but you also want the return to the broader issue #3 safe-route printed in the same place.',
        'Pass -RepoRoot and -SummaryPath when the replay is running from a non-default checkout and the later safe-route commands must preserve that same context.',
        'Pass -InputPath when the bundle replay should stay pinned to an explicit saved-page set instead of auto-discovery.',
        'Run the bundle-first helper first, then reopen the broader safe-route entrypoints only after the attached bundle replay clarifies the next Google-style input, submit, or runner-output state.'
    )
}

if ($Json) {
    $entrypoints | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 bundle safe-route entrypoints'
Write-Host ''
if ($entrypoints.repo_root) {
    Write-Host ("Repo root:   {0}" -f $entrypoints.repo_root)
}
if ($entrypoints.summary_path) {
    Write-Host ("Summary path:{0}" -f " $($entrypoints.summary_path)")
}
if ($entrypoints.explicit_input_path_count -gt 0) {
    Write-Host ("Input paths: {0}" -f $entrypoints.explicit_input_path_count)
}
Write-Host ''
Write-Host 'Pinned bundle route:'
Write-Host ("  Suite router:          {0}" -f $entrypoints.suite_router_command)
Write-Host ("  Bundle-first helper:   {0}" -f $entrypoints.bundle_first_entrypoint_command)
Write-Host ''
Write-Host 'Return to broader issue #3 replay:'
Write-Host ("  Safe-route entrypoints:{0}" -f " $($entrypoints.safe_route_entrypoints_command)")
Write-Host ''
Write-Host ("Validation chain note: {0}" -f $entrypoints.validation_chain_note_path)
Write-Host ("Quickstart note:       {0}" -f $entrypoints.quickstart_note_path)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $entrypoints.notes) {
    Write-Host ("- {0}" -f $note)
}
