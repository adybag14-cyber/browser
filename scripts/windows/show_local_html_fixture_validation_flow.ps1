[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string[]]$InputPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

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

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}
$resolvedInputPath = if ($InputPath -and $InputPath.Count -gt 0) {
    @($InputPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path })
} else {
    @()
}

$surfaceCheckArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $surfaceCheckArgs -Name RepoRoot -Value $resolvedRepoRoot
Add-SharedPathArrayArgument -Arguments $surfaceCheckArgs -Name InputPath -Values $resolvedInputPath
$surfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\check_local_html_fixture_validation_surface.ps1"
if ($surfaceCheckArgs.Count -gt 0) {
    $surfaceCheckCommand += " " + ($surfaceCheckArgs -join " ")
}

$probeArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $probeArgs -Name RepoRoot -Value $resolvedRepoRoot
if ($resolvedInputPath.Count -gt 0) {
    Add-SharedPathArrayArgument -Arguments $probeArgs -Name FixturePaths -Values $resolvedInputPath
}
$probeCommand = "powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\local-html-fixtures\chrome-local-html-fixture-probe.ps1"
if ($probeArgs.Count -gt 0) {
    $probeCommand += " " + ($probeArgs -join " ")
}

$suiteRouterCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea local-html-fixtures"
$broaderAttachedHtmlSuiteCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_headed_validation_suites.ps1 -ChangeArea attached-html"
$broaderAttachedHtmlFlowCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_attached_html_validation_flow.ps1"
$googleAttachedHtmlFlowCommand = "powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_attached_html_validation_flow.ps1"

$fixtureDisplayPaths = @($resolvedInputPath | ForEach-Object { Convert-ToDisplayPath -Path $_ -RepoRoot $resolvedRepoRoot })

$flow = [ordered]@{
    issue = "Local HTML fixture validation flow"
    focus = "Print the fixed-list localhost replay route for saved HTML pages so the reusable fixture surface check, the screenshot-and-title probe, and the broader attached-page fallbacks stay aligned."
    repo_root = $resolvedRepoRoot
    explicit_input_count = $resolvedInputPath.Count
    fixture_paths = $resolvedInputPath
    fixture_display_paths = $fixtureDisplayPaths
    suite_router_command = $suiteRouterCommand
    surface_check_command = $surfaceCheckCommand
    probe_command = $probeCommand
    broader_attached_html_suite_command = $broaderAttachedHtmlSuiteCommand
    broader_attached_html_flow_command = $broaderAttachedHtmlFlowCommand
    google_attached_html_flow_command = $googleAttachedHtmlFlowCommand
    outputs = @(
        "tmp-browser-smoke/local-html-fixtures/output/fixture-results.json",
        "tmp-browser-smoke/local-html-fixtures/output/*.png",
        "tmp-browser-smoke/local-html-fixtures/output/*.browser.stdout.txt",
        "tmp-browser-smoke/local-html-fixtures/output/*.browser.stderr.txt",
        "tmp-browser-smoke/local-html-fixtures/output/server.stdout.txt",
        "tmp-browser-smoke/local-html-fixtures/output/server.stderr.txt"
    )
    steps = @(
        [ordered]@{
            name = "suite-router"
            goal = "Reprint the shared headed validation catalog when you want the fixed-list saved-page route rediscovered from the main Windows validation map first."
            command = $suiteRouterCommand
        }
        [ordered]@{
            name = "surface-check"
            goal = "Fail fast if the local fixture guide, flow helper, probe, shared helpers, or broader saved-page localhost surfaces drifted before replay."
            command = $surfaceCheckCommand
        }
        [ordered]@{
            name = "fixture-probe"
            goal = "Stage the saved HTML files behind localhost, replay them through headed browse, capture screenshots, and prove the native window title matches each page title."
            command = $probeCommand
        }
        [ordered]@{
            name = "broader-attached-html-fallback"
            goal = "Reopen the broader attached-page helpers when the next failure needs the wider attached-HTML wrapper instead of the fixed-list replay."
            command = $broaderAttachedHtmlFlowCommand
        }
        [ordered]@{
            name = "google-attached-html-fallback"
            goal = "Reopen the Google-shaped attached-page helper when the saved-page replay should stay aligned with the issue #3 Google-style branch."
            command = $googleAttachedHtmlFlowCommand
        }
    )
    notes = @(
        "Use this helper when you already know which saved HTML pages you want to replay and you want the shortest read-first ladder before opening a headed window.",
        "Pass -InputPath with one or more saved HTML files or directories when you want both the surface check and the probe command to carry the same locked paths forward.",
        "The local fixture probe automatically stages sibling '<page-base>_files' asset directories beside copied HTML files when they exist.",
        "Keep tmp-browser-smoke/local-html-fixtures/README.md nearby for the concise probe contract, and keep docs/LOCAL_HTML_FIXTURE_VALIDATION_FLOW.md nearby for the longer read-first route note.",
        "Move back to the broader attached-page helpers only after the fixed-list replay makes the next failure state clear."
    )
    next_steps = @(
        "Run the surface-check command first after branch updates or helper renames.",
        "Run the probe command once the fixed-list surface is intact and the saved pages are the current best reproduction set.",
        "Use the broader attached-page flow helper when the saved pages stop being the right fixed list or the next failure needs the larger wrapper chain.",
        "Use the Google attached-page flow helper when the follow-up should stay aligned with the Google-style issue #3 branch."
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 8
    exit 0
}

Write-Host "Local HTML fixture validation flow"
Write-Host ""
Write-Host ( "Focus: {0}" -f $flow.focus )
Write-Host ( "Repo root: {0}" -f $flow.repo_root )
Write-Host ( "Explicit input count: {0}" -f $flow.explicit_input_count )
if ($fixtureDisplayPaths.Count -gt 0) {
    Write-Host "Locked fixture inputs:"
    foreach ($fixturePath in $fixtureDisplayPaths) {
        Write-Host ("- {0}" -f $fixturePath)
    }
} else {
    Write-Host "Locked fixture inputs: none yet"
    Write-Host "Pass -InputPath with one or more saved HTML files or directories to print a fully pinned replay command."
}
Write-Host ""
foreach ($step in $flow.steps) {
    Write-Host ( "[{0}] {1}" -f $step.name, $step.goal )
    Write-Host ( "  {0}" -f $step.command )
    Write-Host ""
}
Write-Host "Outputs:"
foreach ($outputPath in $flow.outputs) {
    Write-Host ("- {0}" -f $outputPath)
}
Write-Host ""
Write-Host "Notes:"
foreach ($note in $flow.notes) {
    Write-Host ("- {0}" -f $note)
}
Write-Host ""
Write-Host "Next steps:"
foreach ($step in $flow.next_steps) {
    Write-Host ("- {0}" -f $step)
}
