[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
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

function Format-RepoRootCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [hashtable]$Arguments = @{},
        [string[]]$Switches = @()
    )

    $escapedRepoRoot = ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot
    $command = "& '.\\$ScriptPath'"
    foreach ($entry in $Arguments.GetEnumerator()) {
        $value = $entry.Value
        if ($null -eq $value) {
            continue
        }
        if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        $command += " -$($entry.Key)"
        if ($value -is [string]) {
            $command += " " + (ConvertTo-PowerShellSingleQuotedLiteral -Value $value)
        } else {
            $command += " $value"
        }
    }

    foreach ($switchName in $Switches) {
        if ([string]::IsNullOrWhiteSpace($switchName)) {
            continue
        }
        $command += " -$switchName"
    }

    return "powershell -NoProfile -ExecutionPolicy Bypass -Command ``"`$env:LIGHTPANDA_REPO_ROOT = $escapedRepoRoot; $command``""
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$resolvedBrowserExe = if ($BrowserExe) {
    $BrowserExe
} elseif (-not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_BROWSER_EXE)) {
    $env:LIGHTPANDA_BROWSER_EXE
} else {
    Join-Path $resolvedRepoRoot 'zig-out\bin\lightpanda.exe'
}

$sharedBrowserArguments = @{}
if (-not [string]::IsNullOrWhiteSpace($resolvedBrowserExe)) {
    $sharedBrowserArguments['BrowserExe'] = $resolvedBrowserExe
}

$runtimeContractCheckerPath = Join-Path $resolvedRepoRoot 'tmp-browser-smoke\google-investigation-next\check_issue3_enter_submit_runtime_contract.py'
$pageSourcePath = Join-Path $resolvedRepoRoot 'src\browser\Page.zig'
$win32SourcePath = Join-Path $resolvedRepoRoot 'src\display\win32_backend.zig'

$buildCommand = 'zig build -Dtarget=x86_64-windows-msvc --summary all'
$focusedPageTestsCommand = 'zig test src/browser/Page.zig'
$focusedWin32TestsCommand = 'zig test src/display/win32_backend.zig -target x86_64-windows-gnu'
$runtimeContractCheckCommand = 'python ' +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $runtimeContractCheckerPath) +
    ' --page ' +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $pageSourcePath) +
    ' --win32 ' +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $win32SourcePath)

$bridge = [ordered]@{
    issue = 'Google issue #3 Windows full-use Enter-submit runtime bridge'
    purpose = 'Keep the Windows-first route, the shared Enter-order ladder, the runtime revalidation helper, the fail-fast surface checker, the source-based runtime contract checker, the reduced Google probe, and the live-homepage fallback on one smaller helper surface.'
    repo_root = $resolvedRepoRoot
    browser_exe = $resolvedBrowserExe
    note_paths = [ordered]@{
        windows_full_use = 'docs/WINDOWS_FULL_USE.md'
        bridge = 'docs/ISSUE3_WINDOWS_FULL_USE_ENTER_SUBMIT_RUNTIME_BRIDGE.md'
        runtime_revalidation = 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md'
        execution_guide = 'docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md'
    }
    commands = [ordered]@{
        runtime_surface_check = Format-RepoRootCommand -ScriptPath 'scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1'
        runtime_helper = Format-RepoRootCommand -ScriptPath 'scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1' -Arguments $sharedBrowserArguments
        google_form_controls_change_area = Format-RepoRootCommand -ScriptPath 'scripts\windows\show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-form-controls-enter-order' })
        google_shared_enter_change_area = Format-RepoRootCommand -ScriptPath 'scripts\windows\show_headed_validation_suites.ps1' -Arguments ([ordered]@{ ChangeArea = 'google-shared-enter-order' })
        shared_enter_google = Format-RepoRootCommand -ScriptPath 'tmp-browser-smoke\form-controls\enter-submit-probe.ps1' -Arguments $sharedBrowserArguments -Switches @('GoogleEnterOrder')
        shared_enter_google_click = Format-RepoRootCommand -ScriptPath 'tmp-browser-smoke\form-controls\enter-submit-probe.ps1' -Arguments $sharedBrowserArguments -Switches @('GoogleEnterOrder', 'ClickFocus')
        runtime_contract_check = $runtimeContractCheckCommand
        reduced_google_probe = Format-RepoRootCommand -ScriptPath 'tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1' -Arguments $sharedBrowserArguments
        reduced_google_fixture = '& ``"' + $resolvedBrowserExe + '``" browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1'
        focused_page_tests = $focusedPageTestsCommand
        focused_win32_tests = $focusedWin32TestsCommand
        build = $buildCommand
        live_google = '& ``"' + $resolvedBrowserExe + '``" browse --browser_mode headed https://www.google.com/'
    }
    notes = @(
        'Start with runtime_surface_check when branch state may have moved and you want the helper, checker, probe, and note surfaces verified before replay.',
        'Use runtime_helper as the default next step from the Windows full-use route because it keeps the direct Page.zig and win32_backend.zig boundary, the focused Zig commands, the shared Enter-order ladder, and the reduced Google probe on one surface.',
        'Use google_form_controls_change_area and google_shared_enter_change_area when the current question still belongs on the named validation-router ladders before reopening the direct runtime helper.',
        'Use runtime_contract_check before build or replay when you need a thin source-based answer about whether the current branch already contains the direct runtime markers.',
        'Use shared_enter_google before shared_enter_google_click when click-first focus is not yet required.',
        'Use reduced_google_probe before reduced_google_fixture or live_google whenever the runtime patch touched Page.zig or win32_backend.zig.',
        'Run focused_page_tests and focused_win32_tests only when the current checkout already has a branch-compatible Zig toolchain; the attached Zig 0.17 dev fallback can fail in untouched branch files before the focused assertions run.',
        'Keep build nearby when the narrowed route is ready to widen back out to the normal headed Windows binary.'
    )
    recommended_next_key = 'runtime_helper'
}

$bridge.recommended_next_command = $bridge.commands[$bridge.recommended_next_key]
$bridge.recommended_next_reason = 'The replay is already narrowed to the Windows full-use Enter-submit boundary, so reopen the direct runtime helper first and keep the surface checker, router ladders, contract check, reduced Google probe, and live fallback nearby.'

if ($Json) {
    $bridge | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host 'Google issue #3 Windows full-use Enter-submit runtime bridge'
Write-Host ''
Write-Host (("Repo root:   {0}") -f $bridge.repo_root)
Write-Host (("Browser exe: {0}") -f $bridge.browser_exe)
Write-Host ''
Write-Host (("Recommended next helper: {0}") -f $bridge.recommended_next_command)
Write-Host (("Why:                    {0}") -f $bridge.recommended_next_reason)
Write-Host ''
Write-Host 'Read-first route:'
Write-Host (("  Windows runbook:           {0}") -f $bridge.note_paths.windows_full_use)
Write-Host (("  Bridge note:               {0}") -f $bridge.note_paths.bridge)
Write-Host (("  Runtime revalidation note: {0}") -f $bridge.note_paths.runtime_revalidation)
Write-Host (("  Execution guide:           {0}") -f $bridge.note_paths.execution_guide)
Write-Host ''
Write-Host 'Replay route:'
Write-Host (("  Surface check:             {0}") -f $bridge.commands.runtime_surface_check)
Write-Host (("  Runtime helper:            {0}") -f $bridge.commands.runtime_helper)
Write-Host (("  Form-controls change area: {0}") -f $bridge.commands.google_form_controls_change_area)
Write-Host (("  Shared-enter change area:  {0}") -f $bridge.commands.google_shared_enter_change_area)
Write-Host (("  Shared Google ordering:    {0}") -f $bridge.commands.shared_enter_google)
Write-Host (("  Shared click-first route:  {0}") -f $bridge.commands.shared_enter_google_click)
Write-Host (("  Runtime contract check:    {0}") -f $bridge.commands.runtime_contract_check)
Write-Host (("  Reduced Google probe:      {0}") -f $bridge.commands.reduced_google_probe)
Write-Host (("  Reduced Google fixture:    {0}") -f $bridge.commands.reduced_google_fixture)
Write-Host (("  Focused Page.zig tests:    {0}") -f $bridge.commands.focused_page_tests)
Write-Host (("  Focused Win32 tests:       {0}") -f $bridge.commands.focused_win32_tests)
Write-Host (("  Windows build:             {0}") -f $bridge.commands.build)
Write-Host (("  Live Google:               {0}") -f $bridge.commands.live_google)
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $bridge.notes) {
    Write-Host (("- {0}") -f $note)
}
