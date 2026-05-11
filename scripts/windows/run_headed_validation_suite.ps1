[CmdletBinding(DefaultParameterSetName = "Suite")]
param(
    [Parameter(Mandatory = $true, ParameterSetName = "Suite")]
    [string]$SuiteName,

    [Parameter(Mandatory = $true, ParameterSetName = "Change")]
    [ValidateSet("shell", "rendering", "input", "storage", "network", "downloads", "graphics", "google-input", "google-submit-path", "google-live-trace", "google-saved-html", "google-attached-html", "manual-html", "attached-html")]
    [string]$ChangeArea,

    [switch]$ListOnly,
    [switch]$ContinueOnFailure,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

$repoRoot = Resolve-LightpandaRepoRoot $PSScriptRoot
$suiteGuide = Join-Path $PSScriptRoot "show_headed_validation_suites.ps1"
$parameterSetName = $PSCmdlet.ParameterSetName
if (-not (Test-Path -LiteralPath $suiteGuide -PathType Leaf)) {
    throw "validation suite guide not found: $suiteGuide"
}

function Resolve-SuiteCatalogSelection {
    if ($parameterSetName -eq "Change") {
        $selection = & $suiteGuide -ChangeArea $ChangeArea -Json | ConvertFrom-Json
        return [pscustomobject]@{
            Mode = "change-area"
            Label = $ChangeArea
            Suites = @($selection.suites)
            NextStep = $selection.next_step
            FlowCommand = $selection.flow_command
        }
    }

    $suite = & $suiteGuide -SuiteName $SuiteName -Json | ConvertFrom-Json
    return [pscustomobject]@{
        Mode = "suite"
        Label = $SuiteName
        Suites = @($suite)
        NextStep = $null
        FlowCommand = $null
    }
}

function Resolve-SuiteCommands {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Suite
    )

    $targetPath = Join-Path $repoRoot ($Suite.Path -replace "/", "\")
    if (-not (Test-Path -LiteralPath $targetPath)) {
        throw "suite path not found for '$($Suite.Name)': $targetPath"
    }

    $item = Get-Item -LiteralPath $targetPath -ErrorAction Stop
    if (-not $item.PSIsContainer) {
        return @(
            [pscustomobject]@{
                SuiteName = $Suite.Name
                Category = $Suite.Category
                Path = $item.FullName
                DisplayPath = Convert-ToDisplayPath -Path $item.FullName -RepoRoot $repoRoot
                Command = @("powershell", "-ExecutionPolicy", "Bypass", "-File", $item.FullName)
            }
        )
    }

    $scripts = @(Get-ChildItem -LiteralPath $item.FullName -File -Filter "*.ps1" |
        Where-Object {
            $_.Name -notlike "*Common.ps1" -and
            $_.Name -ne "Win32Input.ps1"
        } |
        Sort-Object Name)
    if ($scripts.Count -eq 0) {
        throw "suite directory for '$($Suite.Name)' does not contain runnable probe scripts: $($item.FullName)"
    }

    return @(
        $scripts | ForEach-Object {
            [pscustomobject]@{
                SuiteName = $Suite.Name
                Category = $Suite.Category
                Path = $_.FullName
                DisplayPath = Convert-ToDisplayPath -Path $_.FullName -RepoRoot $repoRoot
                Command = @("powershell", "-ExecutionPolicy", "Bypass", "-File", $_.FullName)
            }
        }
    )
}

function Invoke-ValidationCommand {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Entry
    )

    Write-Host ""
    Write-Host ("=== {0} :: {1} ===" -f $Entry.SuiteName, $Entry.DisplayPath)
    $runner = $Entry.Command[0]
    $arguments = if ($Entry.Command.Count -gt 1) { $Entry.Command[1..($Entry.Command.Count - 1)] } else { @() }
    & $runner @arguments
    return $LASTEXITCODE
}

$selection = Resolve-SuiteCatalogSelection
$entries = New-Object System.Collections.Generic.List[object]
foreach ($suite in $selection.Suites) {
    foreach ($entry in (Resolve-SuiteCommands -Suite $suite)) {
        $entries.Add($entry)
    }
}

$result = [ordered]@{
    mode = $selection.Mode
    label = $selection.Label
    repo_root = $repoRoot
    continue_on_failure = [bool]$ContinueOnFailure
    list_only = [bool]$ListOnly
    next_step = $selection.NextStep
    flow_command = $selection.FlowCommand
    entries = @(
        $entries | ForEach-Object {
            [ordered]@{
                suite = $_.SuiteName
                category = $_.Category
                path = $_.DisplayPath
                command = ("powershell -ExecutionPolicy Bypass -File " + (Format-PowerShellLiteral $_.Path))
            }
        }
    )
}

if ($Json) {
    $result | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed validation suite runner"
Write-Host (("Mode: {0}" -f $selection.Mode))
Write-Host (("Selection: {0}" -f $selection.Label))
Write-Host (("Repo root: {0}" -f $repoRoot))
Write-Host (("Runnables: {0}" -f $entries.Count))
if ($selection.NextStep) {
    Write-Host (("Guide note: {0}" -f $selection.NextStep))
}
if ($selection.FlowCommand) {
    Write-Host (("Flow helper: {0}" -f $selection.FlowCommand))
}
Write-Host ""
foreach ($entry in $result.entries) {
    Write-Host (("- [{0}] {1}" -f $entry.suite, $entry.path))
    Write-Host (("  {0}" -f $entry.command))
}

if ($ListOnly) {
    exit 0
}

$failures = New-Object System.Collections.Generic.List[object]
foreach ($entry in $entries) {
    $exitCode = Invoke-ValidationCommand -Entry $entry
    if ($exitCode -ne 0) {
        $failures.Add([pscustomobject]@{
            SuiteName = $entry.SuiteName
            Path = $entry.DisplayPath
            ExitCode = $exitCode
        })
        if (-not $ContinueOnFailure) {
            break
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "Validation runner stopped with failures:"
    foreach ($failure in $failures) {
        Write-Host (("- [{0}] {1} (exit {2})" -f $failure.SuiteName, $failure.Path, $failure.ExitCode))
    }
    exit 1
}

Write-Host ""
Write-Host "Validation runner finished successfully."
