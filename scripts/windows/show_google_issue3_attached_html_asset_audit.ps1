[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string[]]$InputPath,
    [switch]$GoogleStyle,
    [switch]$AllowMissingAssets,
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
        if (-not [string]::IsNullOrWhiteSpace($switchName)) {
            $command += " -$switchName"
        }
    }

    return $command
}

function Format-PythonAuditCommand {
    param(
        [string]$RepoRoot,
        [string[]]$InputPath,
        [switch]$AllowMissingAssets
    )

    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add("python .\\tmp-browser-smoke\\attached-pages\\attached_pages_server.py")
    if ($InputPath -and $InputPath.Count -gt 0) {
        foreach ($path in $InputPath) {
            $parts.Add("--input")
            $parts.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $path))
        }
    } else {
        $parts.Add("--input")
        $parts.Add("'<bundle-html-or-folder>'")
    }
    $parts.Add("--audit-assets")
    if ($AllowMissingAssets) {
        $parts.Add("--allow-missing-assets")
    }

    return $parts -join ' '
}

$bundleArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $bundleArgs -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $bundleArgs -Name InputPath -Values $InputPath

$auditArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $auditArgs -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $auditArgs -Name InputPath -Values $InputPath
if ($GoogleStyle) {
    $auditArgs.Add('-GoogleStyle')
}

$degradedAuditArgs = [System.Collections.Generic.List[string]]::new()
foreach ($entry in $auditArgs) {
    $degradedAuditArgs.Add($entry)
}
if ($AllowMissingAssets) {
    $degradedAuditArgs.Add('-AllowMissingAssets')
}

$runnerArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $runnerArgs -Name RepoRoot -Value $RepoRoot
Add-SharedPathArrayArgument -Arguments $runnerArgs -Name InputPath -Values $InputPath
if ($AllowMissingAssets) {
    $runnerArgs.Add('-AllowMissingLocalAssets')
}

$payload = [ordered]@{
    issue = 'Google issue #3 attached HTML asset audit'
    purpose = 'Print the shortest read-first asset-closure commands for the pinned attached-page compatibility bundle before headed localhost replay starts.'
    repo_root = $RepoRoot
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    google_style = [bool]$GoogleStyle
    allow_missing_assets = [bool]$AllowMissingAssets
    known_degraded_bundle_note = 'The current UAP export is known to be missing its sibling _files directory; the recursive audit previously reported 69 missing local assets.'
    steps = @(
        [ordered]@{
            name = 'bundle-surface-check'
            command = Format-PowerShellFileCommand -RelativePath 'scripts\windows\check_attached_html_target_bundle_validation_surface.ps1' -Arguments $bundleArgs
            goal = 'Fail fast if the pinned attached-bundle route drifted before replay starts.'
        },
        [ordered]@{
            name = 'bundle-check'
            command = Format-PowerShellFileCommand -RelativePath 'scripts\windows\check_attached_html_target_bundle.ps1' -Arguments $bundleArgs
            goal = 'Confirm the current inputs still match the known three-page compatibility bundle.'
        },
        [ordered]@{
            name = 'powershell-asset-audit'
            command = Format-PowerShellFileCommand -RelativePath 'scripts\windows\check_attached_html_local_asset_closure.ps1' -Arguments $degradedAuditArgs
            goal = 'Recursively inspect HTML, CSS, and module-script references before headed localhost launch.'
        },
        [ordered]@{
            name = 'python-asset-audit'
            command = Format-PythonAuditCommand -RepoRoot $RepoRoot -InputPath $InputPath -AllowMissingAssets:$AllowMissingAssets
            goal = 'Run the shell-agnostic attached-pages Python audit for the same input set.'
        },
        [ordered]@{
            name = 'bundle-runner'
            command = Format-PowerShellFileCommand -RelativePath 'scripts\windows\run_attached_html_target_bundle_validation.ps1' -Arguments $runnerArgs -Switches @('Wait')
            goal = 'Replay the bundle only after the asset-closure result is understood.'
        }
    )
}

if ($Json) {
    $payload | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Issue #3 attached HTML asset audit'
Write-Host ''
Write-Host 'Use this helper when the current headed localhost replay is already narrowed to the attached-page compatibility bundle and you want missing sidecar assets surfaced before launch.'
Write-Host ''
Write-Host 'Known degraded bundle note:'
Write-Host '- The UAP export is currently known to be missing its sibling _files directory.'
Write-Host '- The recursive audit previously reported 69 missing local assets for that page.'
Write-Host ''
foreach ($step in $payload.steps) {
    Write-Host ($step.command)
}
Write-Host ''
Write-Host 'Only use the AllowMissingAssets forms when the missing sidecars are already understood and you intentionally want a degraded replay.'
