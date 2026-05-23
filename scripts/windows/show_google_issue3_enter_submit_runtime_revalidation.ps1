[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
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
    Join-Path $resolvedRepoRoot "zig-out\bin\lightpanda.exe"
}

$sharedBrowserArguments = @{}
if (-not [string]::IsNullOrWhiteSpace($resolvedBrowserExe)) {
    $sharedBrowserArguments["BrowserExe"] = $resolvedBrowserExe
}

$runtimeContractCheckerPath = Join-Path $resolvedRepoRoot "tmp-browser-smoke\google-investigation-next\check_issue3_enter_submit_runtime_contract.py"
$pageSourcePath = Join-Path $resolvedRepoRoot "src\browser\Page.zig"
$win32SourcePath = Join-Path $resolvedRepoRoot "src\display\win32_backend.zig"
$linuxBuildReadinessScriptPath = Join-Path $resolvedRepoRoot "scripts\check_linux_build_readiness.py"
$savedMemoryInputsScriptPath = Join-Path $resolvedRepoRoot "scripts\check_issue3_saved_memory_inputs.py"
$linuxRuntimeSurfaceScriptPath = Join-Path $resolvedRepoRoot "scripts\linux\check_issue3_enter_submit_runtime_revalidation_surface.sh"
$linuxRuntimeRouteScriptPath = Join-Path $resolvedRepoRoot "scripts\linux\show_issue3_enter_submit_runtime_revalidation_route.sh"
$savedBrowserSnapshotSurfaceScriptPath = Join-Path $resolvedRepoRoot "scripts\linux\check_issue3_saved_browser_snapshot_route_surface.sh"
$savedBrowserSnapshotRouteScriptPath = Join-Path $resolvedRepoRoot "scripts\linux\show_issue3_saved_browser_snapshot_route.sh"
$fallbackZigArchivePath = Join-Path (Split-Path -Parent $resolvedRepoRoot) "agent_files\zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
$resolvedFallbackZigArchive = if (Test-Path -LiteralPath $fallbackZigArchivePath -PathType Leaf) {
    $fallbackZigArchivePath
} else {
    ""
}

$buildCommand = "zig build -Dtarget=x86_64-windows-msvc --summary all"
$focusedPageTestsCommand = "zig test src/browser/Page.zig"
$focusedWin32TestsCommand = "zig test src/display/win32_backend.zig -target x86_64-windows-gnu"
$runtimeContractCheckCommand = "python " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $runtimeContractCheckerPath) +
    " --page " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $pageSourcePath) +
    " --win32 " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $win32SourcePath)
$runtimeContractSelfTestCommand = "python " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $runtimeContractCheckerPath) +
    " --self-test"
$savedMemoryPreflightCommand = "python " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $savedMemoryInputsScriptPath) +
    " --repo-root " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot)
$linuxRuntimeSurfaceCommand = "bash " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $linuxRuntimeSurfaceScriptPath) +
    " --repo-root " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot)
$linuxRuntimeRouteCommand = "bash " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $linuxRuntimeRouteScriptPath) +
    " --repo-root " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot) +
    " --browser-exe " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedBrowserExe)
$savedBrowserSnapshotSurfaceCommand = "bash " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $savedBrowserSnapshotSurfaceScriptPath) +
    " --repo-root " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot)
$savedBrowserSnapshotRouteCommand = "bash " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $savedBrowserSnapshotRouteScriptPath) +
    " --repo-root " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot)
$linuxBuildReadinessSkipZigCommand = "python " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $linuxBuildReadinessScriptPath) +
    " --repo-root " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot) +
    " --skip-zig-check"
$linuxBuildReadinessFullCommand = "python " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $linuxBuildReadinessScriptPath) +
    " --repo-root " +
    (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot)
if (-not [string]::IsNullOrWhiteSpace($resolvedFallbackZigArchive)) {
    $escapedFallbackZigArchive = ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedFallbackZigArchive
    $savedBrowserSnapshotRouteCommand += " --fallback-zig-archive " + $escapedFallbackZigArchive
    $savedMemoryPreflightCommand += " --fallback-zig-archive " + $escapedFallbackZigArchive
    $linuxRuntimeRouteCommand += " --fallback-zig-archive " + $escapedFallbackZigArchive
    $linuxBuildReadinessSkipZigCommand += " --fallback-zig-archive " + $escapedFallbackZigArchive
    $linuxBuildReadinessFullCommand += " --fallback-zig-archive " + $escapedFallbackZigArchive
}

$route = [ordered]@{
    issue = "Google issue #3 Enter-submit runtime revalidation"
    purpose = "Keep the runtime re-entry gates note, the saved-browser-snapshot restore route, the source-based runtime contract checker, the saved-memory preflight, the Linux re-entry helpers, the shared Enter-submit ladder, the focused file-level regression commands, the reduced Google title probe, the runtime-specific revalidation note, and the live Google fallback on one Windows-first helper surface."
    repo_root = $resolvedRepoRoot
    browser_exe = $resolvedBrowserExe
    fallback_zig_archive = if ([string]::IsNullOrWhiteSpace($resolvedFallbackZigArchive)) {
        "not found beside the repo workspace"
    } else {
        $resolvedFallbackZigArchive
    }
    read_first = @(
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md"
    )
    target_files = @(
        "src/browser/Page.zig",
        "src/display/win32_backend.zig"
    )
    related_files = @(
        "scripts/windows/check_google_issue3_enter_submit_runtime_revalidation_surface.ps1",
        "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
        "scripts/check_issue3_saved_memory_inputs.py",
        "tmp-browser-smoke/google-investigation-next/check_issue3_enter_submit_runtime_contract.py",
        "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
        "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "src/browser/tests/page/google_home_title_probe.html",
        "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md",
        "docs/WINDOWS_FULL_USE.md",
        "scripts/check_linux_build_readiness.py"
    )
    commands = [ordered]@{
        surface_check = Format-RepoRootCommand -ScriptPath "scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        saved_browser_snapshot_surface = $savedBrowserSnapshotSurfaceCommand
        saved_browser_snapshot_route = $savedBrowserSnapshotRouteCommand
        contract_check = $runtimeContractCheckCommand
        contract_self_test = $runtimeContractSelfTestCommand
        saved_memory_preflight = $savedMemoryPreflightCommand
        linux_runtime_surface = $linuxRuntimeSurfaceCommand
        linux_runtime_route = $linuxRuntimeRouteCommand
        linux_build_readiness_skip_zig = $linuxBuildReadinessSkipZigCommand
        linux_build_readiness = $linuxBuildReadinessFullCommand
        build = $buildCommand
        focused_page_tests = $focusedPageTestsCommand
        focused_win32_tests = $focusedWin32TestsCommand
        shared_enter_default = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Arguments $sharedBrowserArguments
        shared_enter_deferred = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Arguments $sharedBrowserArguments -Switches @("DeferredEnter")
        shared_enter_google = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Arguments $sharedBrowserArguments -Switches @("GoogleEnterOrder")
        shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Arguments $sharedBrowserArguments -Switches @("GoogleEnterOrder", "ClickFocus")
        reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1" -Arguments $sharedBrowserArguments
        reduced_google_fixture = "& ``"$resolvedBrowserExe``" browse --headed --window_width 1366 --window_height 900 ``"http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1``""
        live_google = "& ``"$resolvedBrowserExe``" browse --headed --window_width 1366 --window_height 900 ``"https://www.google.com/``""
    }
    expected_signals = @(
        "Printable keydown and keypress leave text in the focused Google query input.",
        "Enter keydown alone does not force an early submit transition.",
        "Enter submit happens only after the later keypress-time DOM phase.",
        "Stale queued suppression entries do not drop real later text_input bytes."
    )
    notes = @(
        "Read docs/ISSUE3_RUNTIME_REENTRY_GATES.md before docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md whenever the next run may reopen Page.zig or win32_backend.zig.",
        "Run surface_check first when branch state may have moved and you want the gate note, helper, and probe files checked before replay.",
        "If no reusable checkout exists yet, run saved_browser_snapshot_surface and then saved_browser_snapshot_route before trusting Linux or WSL follow-up helpers against a restored checkout.",
        "Run contract_check before build or replay when you need a thin, source-based yes-or-no answer about whether the direct Page.zig and win32_backend.zig bridge markers are present on the current branch.",
        "Run contract_self_test when you want to prove the checker itself still distinguishes vulnerable and guarded samples before pointing it at a real checkout.",
        "Run saved_memory_preflight before Linux or WSL build-readiness commands when the route depends on the saved Memory repo snapshot, dependency archives, and optional fallback Zig bundle.",
        "Run linux_runtime_surface and then linux_runtime_route when the direct issue #3 runtime patch is still blocked earlier on Linux or WSL saved-checkout staging or helper drift.",
        "Use linux_build_readiness_skip_zig when the re-entry depends on Linux or WSL dependency staging and you need to confirm the saved inputs before trusting focused Zig output.",
        "Use linux_build_readiness only after a matching Zig line is staged and you want the full readiness helper to confirm the branch-compatible build path before using focused Page.zig or win32_backend.zig tests as evidence.",
        "Use focused_page_tests and focused_win32_tests only when the current checkout already has a branch-compatible Zig toolchain; the attached Zig 0.17 dev fallback can fail in untouched branch files before these focused assertions run.",
        "Use shared_enter_default to confirm the baseline Enter-submit path still works before narrowing into the Google-shaped ordering slices.",
        "Use shared_enter_deferred after changes that touch delayed native Enter submit without reopening the full Google-shaped route yet.",
        "Use shared_enter_google when the keypress-before-submit ordering is the main question but click-first focus is not required yet.",
        "Use shared_enter_google_click when reproducing the click-first path that most closely matches the real homepage boundary from issue #3.",
        "Use reduced_google_probe before live Google whenever the runtime patch touched Page.zig or win32_backend.zig and you want trace-ready output on the reduced fixture first.",
        "If the focused Zig tests fail in untouched branch files before the new assertions run, fall back to contract_check, the saved-browser-snapshot route, saved_memory_preflight, the Linux re-entry helpers, the shared Enter-order ladder, and the reduced Google probe so the runtime boundary can still be narrowed honestly.",
        "Only jump to reduced_google_fixture or live_google after the source contract check, restored-checkout route, saved-memory preflight, Linux or WSL gating, shared Enter-order ladder, and reduced Google probe agree on the same event ordering."
    )
}

if ($Json) {
    $route | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Google issue #3 Enter-submit runtime revalidation"
Write-Host ""
Write-Host ("Repo root:             {0}" -f $route.repo_root)
Write-Host ("Browser exe:           {0}" -f $route.browser_exe)
Write-Host ("Fallback Zig archive:  {0}" -f $route.fallback_zig_archive)
Write-Host ""
Write-Host "Read first"
Write-Host "=========="
foreach ($path in $route.read_first) {
    Write-Host ("  {0}" -f $path)
}
Write-Host ""
Write-Host "Target files"
Write-Host "============"
foreach ($path in $route.target_files) {
    Write-Host ("  {0}" -f $path)
}
Write-Host ""
Write-Host "Replay route"
Write-Host "============"
Write-Host ("  Surface check:                  {0}" -f $route.commands.surface_check)
Write-Host ("  Saved snapshot surface:         {0}" -f $route.commands.saved_browser_snapshot_surface)
Write-Host ("  Saved snapshot route:           {0}" -f $route.commands.saved_browser_snapshot_route)
Write-Host ("  Source contract check:          {0}" -f $route.commands.contract_check)
Write-Host ("  Checker self-test:              {0}" -f $route.commands.contract_self_test)
Write-Host ("  Saved-memory preflight:         {0}" -f $route.commands.saved_memory_preflight)
Write-Host ("  Linux runtime surface:          {0}" -f $route.commands.linux_runtime_surface)
Write-Host ("  Linux runtime route:            {0}" -f $route.commands.linux_runtime_route)
Write-Host ("  Linux readiness (skip Zig):     {0}" -f $route.commands.linux_build_readiness_skip_zig)
Write-Host ("  Linux readiness (full):         {0}" -f $route.commands.linux_build_readiness)
Write-Host ("  Windows build:                  {0}" -f $route.commands.build)
Write-Host ("  Focused Page.zig tests:         {0}" -f $route.commands.focused_page_tests)
Write-Host ("  Focused Win32 tests:            {0}" -f $route.commands.focused_win32_tests)
Write-Host ("  Shared Enter baseline:          {0}" -f $route.commands.shared_enter_default)
Write-Host ("  Shared Enter deferred:          {0}" -f $route.commands.shared_enter_deferred)
Write-Host ("  Shared Google ordering:         {0}" -f $route.commands.shared_enter_google)
Write-Host ("  Shared click-first route:       {0}" -f $route.commands.shared_enter_google_click)
Write-Host ("  Reduced Google probe:           {0}" -f $route.commands.reduced_google_probe)
Write-Host ("  Reduced Google fixture:         {0}" -f $route.commands.reduced_google_fixture)
Write-Host ("  Live Google:                    {0}" -f $route.commands.live_google)
Write-Host ""
Write-Host "Expected signals"
Write-Host "================"
foreach ($signal in $route.expected_signals) {
    Write-Host ("  - {0}" -f $signal)
}
Write-Host ""
Write-Host "Companion files"
Write-Host "==============="
foreach ($path in $route.related_files) {
    Write-Host ("  {0}" -f $path)
}
Write-Host ""
Write-Host "Notes"
Write-Host "====="
foreach ($note in $route.notes) {
    Write-Host ("  - {0}" -f $note)
}