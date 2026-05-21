[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
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

function Resolve-PreferredAttachedPage {
    param(
        [string[]]$Candidates,
        [string]$PreferredPage
    )

    if (-not [string]::IsNullOrWhiteSpace($PreferredPage)) {
        return $PreferredPage
    }
    if ($Candidates -and $Candidates.Count -gt 0) {
        return $Candidates[0]
    }
    return '<attached-html-path>'
}

function New-BrowseCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BrowserPath,
        [Parameter(Mandatory = $true)]
        [string]$Target
    )

    $browserLiteral = ConvertTo-PowerShellSingleQuotedLiteral -Value $BrowserPath
    $targetLiteral = ConvertTo-PowerShellSingleQuotedLiteral -Value $Target
    return "& $browserLiteral browse --browser_mode headed $targetLiteral"
}

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$resolvedBrowserExe = if ([string]::IsNullOrWhiteSpace($BrowserExe)) {
    '.\\zig-out\\bin\\lightpanda.exe'
} else {
    $BrowserExe
}

$resolvedInputPaths = if ($InputPath) { @($InputPath) } else { @() }
$preferredPage = Resolve-PreferredAttachedPage -Candidates $resolvedInputPaths -PreferredPage $PreferredInitialPage
$queryTarget = "$preferredPage?lp_probe=query"
$fragmentTarget = "$preferredPage#lp-probe-fragment"
$queryFragmentTarget = "$preferredPage?lp_probe=query#lp-probe-fragment"

$entrypoints = [ordered]@{
    issue = 'Attached HTML explicit browse entrypoints'
    purpose = 'Print explicit headed browse commands for local attached HTML targets so local validation can stay on the browse path even when the target includes query or fragment suffixes.'
    repo_root = $RepoRoot
    browser_exe = $resolvedBrowserExe
    preferred_initial_page = $preferredPage
    explicit_input_path_count = $resolvedInputPaths.Count
    commands = [ordered]@{
        plain = New-BrowseCommand -BrowserPath $resolvedBrowserExe -Target $preferredPage
        query = New-BrowseCommand -BrowserPath $resolvedBrowserExe -Target $queryTarget
        fragment = New-BrowseCommand -BrowserPath $resolvedBrowserExe -Target $fragmentTarget
        query_and_fragment = New-BrowseCommand -BrowserPath $resolvedBrowserExe -Target $queryFragmentTarget
    }
    all_input_paths = @($resolvedInputPaths)
    notes = @(
        'Use these commands when local attached HTML validation should bypass command-mode inference and go straight to the headed browse path.',
        'Pass -InputPath one or more times to keep the helper pinned to the current saved attached pages.',
        'Pass -PreferredInitialPage when the query or fragment probe should stay attached to a specific page from the bundle.',
        'Pass -BrowserExe when the replay should target a non-default headed binary.'
    )
}

if ($Json) {
    $entrypoints | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Attached HTML explicit browse entrypoints'
Write-Host ''
if ($entrypoints.repo_root) {
    Write-Host (("Repo root:      {0}") -f $entrypoints.repo_root)
}
Write-Host (("Browser exe:    {0}") -f $entrypoints.browser_exe)
Write-Host (("Preferred page: {0}") -f $entrypoints.preferred_initial_page)
Write-Host (("Input paths:    {0}") -f $entrypoints.explicit_input_path_count)
Write-Host ''
Write-Host 'Commands:'
Write-Host (("  Plain:              {0}") -f $entrypoints.commands.plain)
Write-Host (("  Query:              {0}") -f $entrypoints.commands.query)
Write-Host (("  Fragment:           {0}") -f $entrypoints.commands.fragment)
Write-Host (("  Query and fragment: {0}") -f $entrypoints.commands.query_and_fragment)
Write-Host ''
if ($entrypoints.all_input_paths.Count -gt 0) {
    Write-Host 'Pinned input paths:'
    foreach ($path in $entrypoints.all_input_paths) {
        Write-Host (("  - {0}") -f $path)
    }
    Write-Host ''
}
Write-Host 'Notes:'
foreach ($note in $entrypoints.notes) {
    Write-Host (("- {0}") -f $note)
}
