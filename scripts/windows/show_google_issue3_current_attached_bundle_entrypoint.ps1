[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Add-SingleArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    $Arguments.Add("-$Name")
    $Arguments.Add((Format-PowerShellLiteral $Value))
}

function Add-ArrayArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string[]]$Values
    )

    $items = @($Values | Where-Object { -not [string]::IsNullOrWhiteSpace("$_") })
    if ($items.Count -eq 0) {
        return
    }

    $Arguments.Add("-$Name")
    foreach ($item in $items) {
        $Arguments.Add((Format-PowerShellLiteral "$item"))
    }
}

function Format-ScriptCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [System.Collections.Generic.List[string]]$Arguments,
        [string[]]$Switches = @()
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\\$RelativePath"
    if ($Arguments -and $Arguments.Count -gt 0) {
        $command += " " + ($Arguments -join " ")
    }
    foreach ($switchName in $Switches) {
        if ([string]::IsNullOrWhiteSpace($switchName)) {
            continue
        }
        $command += " -$switchName"
    }

    return $command
}

$checkerPath = Join-Path $PSScriptRoot "check_attached_html_target_bundle.ps1"
if (-not (Test-Path -LiteralPath $checkerPath -PathType Leaf)) {
    throw "Attached HTML target bundle checker not found: $checkerPath"
}

$checkerArgs = @{ Json = $true }
if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
    $checkerArgs.RepoRoot = $RepoRoot
}
if ($InputPath -and $InputPath.Count -gt 0) {
    $checkerArgs.InputPath = $InputPath
}

$bundleJson = (& $checkerPath @checkerArgs) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$bundle = $bundleJson | ConvertFrom-Json -Depth 12
$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$resolvedTargets = @($bundle.targets | Where-Object { $_.status -eq "found" -and $_.path })
if ($resolvedTargets.Count -eq 0) {
    throw "The current issue #3 attached bundle could not be resolved. Run check_attached_html_target_bundle.ps1 first to inspect the missing targets."
}

$resolvedInputPath = @($resolvedTargets | ForEach-Object { $_.path })
$preferredInitialPage = if ($bundle.overall_recommendation.preferred_initial_page) {
    $bundle.overall_recommendation.preferred_initial_page
} else {
    $resolvedInputPath[0]
}

$bundleCheckArguments = [System.Collections.Generic.List[string]]::new()
Add-SingleArgument -Arguments $bundleCheckArguments -Name RepoRoot -Value $resolvedRepoRoot
Add-ArrayArgument -Arguments $bundleCheckArguments -Name InputPath -Values $resolvedInputPath

$bundleEntrypointArguments = [System.Collections.Generic.List[string]]::new()
Add-SingleArgument -Arguments $bundleEntrypointArguments -Name RepoRoot -Value $resolvedRepoRoot
Add-SingleArgument -Arguments $bundleEntrypointArguments -Name SummaryPath -Value $SummaryPath
Add-ArrayArgument -Arguments $bundleEntrypointArguments -Name InputPath -Values $resolvedInputPath

$bundleRunnerArguments = [System.Collections.Generic.List[string]]::new()
Add-SingleArgument -Arguments $bundleRunnerArguments -Name RepoRoot -Value $resolvedRepoRoot
Add-ArrayArgument -Arguments $bundleRunnerArguments -Name InputPath -Values $resolvedInputPath
Add-SingleArgument -Arguments $bundleRunnerArguments -Name PreferredInitialPage -Value $preferredInitialPage

$fixtureSurfaceArguments = [System.Collections.Generic.List[string]]::new()
Add-SingleArgument -Arguments $fixtureSurfaceArguments -Name RepoRoot -Value $resolvedRepoRoot

$fixtureProbeArguments = [System.Collections.Generic.List[string]]::new()
Add-SingleArgument -Arguments $fixtureProbeArguments -Name RepoRoot -Value $resolvedRepoRoot
Add-ArrayArgument -Arguments $fixtureProbeArguments -Name FixturePaths -Values $resolvedInputPath

$result = [ordered]@{
    issue = "Google issue #3 current attached bundle"
    repo_root = $resolvedRepoRoot
    validation_profile = $bundle.overall_recommendation.bundle_validation_profile
    bundle_locked_input_count = @($resolvedInputPath).Count
    preferred_initial_page = $preferredInitialPage
    preferred_initial_page_display_path = Convert-ToDisplayPath -Path $preferredInitialPage -RepoRoot $resolvedRepoRoot
    search_roots = @($bundle.search_roots)
    targets = @(
        $bundle.targets | ForEach-Object {
            [ordered]@{
                name = $_.name
                display_name = $_.display_name
                status = $_.status
                display_path = $_.display_path
                path = $_.path
                route_change_area = $_.route_change_area
                is_google_style = $_.is_google_style
            }
        }
    )
    bundle_check_command = Format-ScriptCommand -RelativePath "scripts/windows/check_attached_html_target_bundle.ps1" -Arguments $bundleCheckArguments
    bundle_entrypoint_command = Format-ScriptCommand -RelativePath "scripts/windows/show_google_issue3_attached_bundle_first_entrypoint.ps1" -Arguments $bundleEntrypointArguments
    bundle_runner_command = Format-ScriptCommand -RelativePath "scripts/windows/run_attached_html_target_bundle_validation.ps1" -Arguments $bundleRunnerArguments -Switches @("Wait")
    local_fixture_surface_check_command = Format-ScriptCommand -RelativePath "scripts/windows/check_local_html_fixture_validation_surface.ps1" -Arguments $fixtureSurfaceArguments
    local_fixture_probe_command = Format-ScriptCommand -RelativePath "tmp-browser-smoke/local-html-fixtures/chrome-local-html-fixture-probe.ps1" -Arguments $fixtureProbeArguments
}

if ($Json) {
    $result | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host "Google issue #3 current attached bundle"
Write-Host ""
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
Write-Host ("Validation profile: {0}" -f $result.validation_profile)
Write-Host ("Preferred initial page: {0}" -f $result.preferred_initial_page_display_path)
Write-Host ""
Write-Host "Resolved targets:"
foreach ($target in $resolvedTargets) {
    $displayPath = if ($target.display_path) { $target.display_path } else { Convert-ToDisplayPath -Path $target.path -RepoRoot $resolvedRepoRoot }
    $googleMarker = if ($target.is_google_style) { " [google-style]" } else { "" }
    Write-Host ("- {0}: {1}{2}" -f $target.display_name, $displayPath, $googleMarker)
}
Write-Host ""
Write-Host "Ready-to-run commands:"
Write-Host ("- Bundle check: {0}" -f $result.bundle_check_command)
Write-Host ("- Bundle-first route: {0}" -f $result.bundle_entrypoint_command)
Write-Host ("- Bundle runner: {0}" -f $result.bundle_runner_command)
Write-Host ("- Local fixture surface check: {0}" -f $result.local_fixture_surface_check_command)
Write-Host ("- Local fixture probe: {0}" -f $result.local_fixture_probe_command)
