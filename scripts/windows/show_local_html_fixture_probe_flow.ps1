[CmdletBinding()]
param(
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
    [int]$Port = 8123,
    [int]$ProbePort = 8168,
    [switch]$GoogleStyle,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Join-QuotedInputPaths {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    if (-not $Paths -or $Paths.Count -eq 0) {
        return ""
    }

    return (($Paths | ForEach-Object { Format-PowerShellLiteral $_ }) -join ", ")
}

function Get-InputPathArgument {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ResolvedInputPath
    )

    return "-InputPath " + (Join-QuotedInputPaths -Paths $ResolvedInputPath)
}

function Get-ProbeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ResolvedInputPath,
        [Parameter(Mandatory = $true)]
        [int]$ProbePort
    )

    return "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\local-html-fixtures\\chrome-local-html-fixture-probe.ps1 -FixturePaths @(" + (Join-QuotedInputPaths -Paths $ResolvedInputPath) + ") -Port $ProbePort"
}

function Get-FlowCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ResolvedInputPath,
        [Parameter(Mandatory = $true)]
        [int]$Port,
        [Parameter(Mandatory = $true)]
        [bool]$GoogleStyle,
        [string]$ResolvedPreferredInitialPage
    )

    $helper = if ($GoogleStyle) {
        ".\\scripts\\windows\\show_google_attached_html_validation_flow.ps1"
    } else {
        ".\\scripts\\windows\\show_attached_html_validation_flow.ps1"
    }

    $command = "powershell -ExecutionPolicy Bypass -File $helper " + (Get-InputPathArgument -ResolvedInputPath $ResolvedInputPath) + " -Port $Port"
    if ($ResolvedPreferredInitialPage) {
        $command += " -PreferredInitialPage " + (Format-PowerShellLiteral $ResolvedPreferredInitialPage)
    }

    return $command
}

function Get-RunCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ResolvedInputPath,
        [Parameter(Mandatory = $true)]
        [int]$Port,
        [Parameter(Mandatory = $true)]
        [bool]$GoogleStyle,
        [string]$ResolvedPreferredInitialPage
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_attached_html_localhost_validation.ps1 " + (Get-InputPathArgument -ResolvedInputPath $ResolvedInputPath) + " -Port $Port -Wait"
    if ($GoogleStyle) {
        $command += " -GoogleStyle"
    }
    if ($ResolvedPreferredInitialPage) {
        $command += " -PreferredInitialPage " + (Format-PowerShellLiteral $ResolvedPreferredInitialPage)
    }

    return $command
}

function Get-LocalHtmlFixtureProbeFlowMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [string[]]$ResolvedInputPath,
        [string]$PreferredInitialPage,
        [string]$ResolvedPreferredInitialPage,
        [Parameter(Mandatory = $true)]
        [bool]$UsingExplicitInputPath,
        [Parameter(Mandatory = $true)]
        [bool]$GoogleStyle,
        [Parameter(Mandatory = $true)]
        [int]$Port,
        [Parameter(Mandatory = $true)]
        [int]$ProbePort
    )

    $preferredInitialPageMode = if ($PreferredInitialPage) {
        "explicit"
    } elseif ($ResolvedPreferredInitialPage) {
        if ($GoogleStyle) { "google-style-auto" } else { "auto-selected" }
    } else {
        "saved-page-summary-auto"
    }

    return [ordered]@{
        input_mode = if ($UsingExplicitInputPath) { "explicit" } else { "auto-discovered attached HTML" }
        input_count = @($ResolvedInputPath).Count
        resolved_input_path = @($ResolvedInputPath)
        preferred_initial_page = $ResolvedPreferredInitialPage
        preferred_initial_page_mode = $preferredInitialPageMode
        validation_mode = if ($GoogleStyle) { "google-style" } else { "general" }
        port = $Port
        probe_port = $ProbePort
        search_roots = if ($UsingExplicitInputPath) { @() } else { @(Get-AttachedHtmlSearchRoots -RepoRoot $RepoRoot) }
    }
}

$repoRoot = Resolve-LightpandaRepoRoot $PSScriptRoot
$usingExplicitInputPath = $InputPath -and $InputPath.Count -gt 0
$resolvedInputPath = if ($usingExplicitInputPath) {
    @($InputPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path })
} else {
    Get-DefaultAttachedHtmlInputPath -RepoRoot $repoRoot -GoogleStyle:$GoogleStyle
}

$resolvedPreferredInitialPage = if ($PreferredInitialPage) {
    Resolve-AttachedPreferredInitialPage -ResolvedInputPath $resolvedInputPath -PreferredInitialPage $PreferredInitialPage
} elseif ($GoogleStyle) {
    Select-GoogleStyleInitialPage -ResolvedInputPath $resolvedInputPath
} else {
    $null
}

$probeCommand = Get-ProbeCommand -ResolvedInputPath $resolvedInputPath -ProbePort $ProbePort
$summaryCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\summarize_localhost_html_pages.ps1 " + (Get-InputPathArgument -ResolvedInputPath $resolvedInputPath) + " -Port $Port"
if ($resolvedPreferredInitialPage) {
    $summaryCommand += " -PreferredInitialPage " + (Format-PowerShellLiteral $resolvedPreferredInitialPage)
}
$flowCommand = Get-FlowCommand -ResolvedInputPath $resolvedInputPath -Port $Port -GoogleStyle ([bool]$GoogleStyle) -ResolvedPreferredInitialPage $resolvedPreferredInitialPage
$runCommand = Get-RunCommand -ResolvedInputPath $resolvedInputPath -Port $Port -GoogleStyle ([bool]$GoogleStyle) -ResolvedPreferredInitialPage $resolvedPreferredInitialPage

$metadata = Get-LocalHtmlFixtureProbeFlowMetadata `
    -RepoRoot $repoRoot `
    -ResolvedInputPath $resolvedInputPath `
    -PreferredInitialPage $PreferredInitialPage `
    -ResolvedPreferredInitialPage $resolvedPreferredInitialPage `
    -UsingExplicitInputPath ([bool]$usingExplicitInputPath) `
    -GoogleStyle ([bool]$GoogleStyle) `
    -Port $Port `
    -ProbePort $ProbePort

$result = [ordered]@{
    local_html_fixture_probe = $metadata
    summary_command = $summaryCommand
    probe_command = $probeCommand
    attached_flow_command = $flowCommand
    attached_run_command = $runCommand
    outputs = @(
        "tmp-browser-smoke/local-html-fixtures/output/fixture-results.json",
        "tmp-browser-smoke/local-html-fixtures/output/*.png",
        "tmp-browser-smoke/local-html-fixtures/output/*.stdout.txt",
        "tmp-browser-smoke/local-html-fixtures/output/*.stderr.txt"
    )
    next_step = "Run the summary first if you want the bounded-suite recommendation, then run the local HTML fixture probe for screenshot-plus-title capture, then move to the attached HTML localhost flow for deeper manual headed follow-up."
}

if ($Json) {
    $result | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host "Local HTML fixture probe flow"
Write-Host ""
Write-Host ("Inputs discovered: {0}" -f $metadata.input_count)
Write-Host ("Input mode: {0}" -f $metadata.input_mode)
Write-Host ("Validation mode: {0}" -f $metadata.validation_mode)
Write-Host ("Summary port: {0}" -f $Port)
Write-Host ("Fixture probe port: {0}" -f $ProbePort)
if ($metadata.search_roots.Count -gt 0) {
    Write-Host "Search roots:"
    foreach ($root in $metadata.search_roots) {
        Write-Host ("- {0}" -f (Convert-ToDisplayPath -Path $root -RepoRoot $repoRoot))
    }
    Write-Host ""
}

Show-FixtureSelectionSummary -FixturePaths $resolvedInputPath -RepoRoot $repoRoot
Write-Host ""
if ($resolvedPreferredInitialPage) {
    if ($PreferredInitialPage) {
        Write-Host ("Preferred initial page override: {0}" -f $resolvedPreferredInitialPage)
    } else {
        Write-Host ("Preferred initial page: {0}" -f $resolvedPreferredInitialPage)
    }
    Write-Host ""
}

Write-Host "Suggested command order:"
Write-Host ("1. Summary: {0}" -f $summaryCommand)
Write-Host ("2. Fixture probe: {0}" -f $probeCommand)
Write-Host ("3. Attached flow: {0}" -f $flowCommand)
Write-Host ("4. Attached runner: {0}" -f $runCommand)
Write-Host ""
Write-Host "Expected probe outputs:"
foreach ($output in $result.outputs) {
    Write-Host ("- {0}" -f $output)
}
Write-Host ""
Write-Host ("Next step: {0}" -f $result.next_step)
