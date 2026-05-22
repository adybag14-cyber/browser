[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'HeadedValidationHelpers.ps1')

function ConvertTo-PowerShellSingleQuotedLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Format-HelperCommandWithRepoRootEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [string]$RepoRootOverride
    )

    if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        return "powershell -ExecutionPolicy Bypass -File .\scripts\windows\$ScriptName"
    }

    $escapedRepoRoot = ("$RepoRootOverride") -replace "'", "''"
    return "powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$env:LIGHTPANDA_REPO_ROOT = '$escapedRepoRoot'; & '.\scripts\windows\$ScriptName'`""
}

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$resolvedRepoRoot = if ($RepoRoot) {
    try {
        (Resolve-Path -LiteralPath $RepoRoot).Path
    } catch {
        $RepoRoot
    }
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$buildCommand = 'zig build -Dtarget=x86_64-windows-msvc --summary all'
$titleProbeCommand = 'powershell -ExecutionPolicy Bypass -File .\tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1'
$fixtureReplayCommand = '.\zig-out\bin\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1'
$surfaceCheckCommand = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_enter_submit_runtime_revalidation_surface.ps1' -RepoRootOverride $RepoRoot

$helper = [ordered]@{
    issue = 'Google issue #3 Enter-submit runtime revalidation'
    purpose = 'Print the smallest honest runtime-first route for reopening the remaining Google headed Enter-submit failure from a writable checkout, with the exact target files, replay surfaces, and expected signal ordering in one place.'
    repo_root = $resolvedRepoRoot
    note_path = 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md'
    target_files = @(
        'src/browser/Page.zig',
        'src/display/win32_backend.zig'
    )
    related_files = @(
        'tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1',
        'src/browser/tests/page/google_home_title_probe.html',
        'docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md',
        'docs/WINDOWS_FULL_USE.md'
    )
    commands = [ordered]@{
        surface_check = $surfaceCheckCommand
        build = $buildCommand
        title_probe = $titleProbeCommand
        reduced_fixture_replay = $fixtureReplayCommand
    }
    expected_signals = @(
        'Printable keydown and keypress leave text in the focused Google query input.',
        'Enter keydown alone does not force an early submit transition.',
        'Enter submit happens only after the later keypress-time DOM phase.',
        'Stale queued suppression entries do not drop real later text_input bytes.'
    )
    notes = @(
        'Use the reduced Google fixture and the focused Win32 suppression tests before jumping back to the live Google homepage.',
        'Keep the change focused to src/browser/Page.zig and src/display/win32_backend.zig until the event ordering agrees across the reduced probe and the Win32 backend tests.',
        'If the current runtime cannot publish large existing-file edits safely, treat docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md as the branch-local re-entry note and replay the saved runtime patch in a writable checkout.'
    )
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 Enter-submit runtime revalidation'
Write-Host ''
Write-Host ('Repo root: {0}' -f $helper.repo_root)
Write-Host ('Read first: {0}' -f $helper.note_path)
Write-Host ''
Write-Host 'Target files'
Write-Host '============'
foreach ($path in $helper.target_files) {
    Write-Host ('  {0}' -f $path)
}

Write-Host ''
Write-Host 'Replay route'
Write-Host '============'
Write-Host ('  Surface check:        {0}' -f $helper.commands.surface_check)
Write-Host ('  Windows build:        {0}' -f $helper.commands.build)
Write-Host ('  Google title probe:   {0}' -f $helper.commands.title_probe)
Write-Host ('  Reduced fixture run:  {0}' -f $helper.commands.reduced_fixture_replay)

Write-Host ''
Write-Host 'Expected signals'
Write-Host '================'
foreach ($signal in $helper.expected_signals) {
    Write-Host ('  - {0}' -f $signal)
}

Write-Host ''
Write-Host 'Companion files'
Write-Host '==============='
foreach ($path in $helper.related_files) {
    Write-Host ('  {0}' -f $path)
}

Write-Host ''
Write-Host 'Notes'
Write-Host '====='
foreach ($note in $helper.notes) {
    Write-Host ('  - {0}' -f $note)
}
