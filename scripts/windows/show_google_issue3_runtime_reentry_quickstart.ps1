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

    return "powershell -NoProfile -ExecutionPolicy Bypass -Command ``\"`$env:LIGHTPANDA_REPO_ROOT = $escapedRepoRoot; $command``\""
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

$helper = [ordered]@{
    issue = "Google issue #3 runtime re-entry quickstart"
    purpose = "Print the shortest branch-local route back into the direct issue #3 Enter-submit runtime slice while keeping the gate note, runtime note, runtime surface checker, source contract checker, shared Enter-order ladders, reduced Google probe, and live Google fallback on one compact surface."
    repo_root = $resolvedRepoRoot
    browser_exe = $resolvedBrowserExe
    runtime_quickstart_note_path = "docs/ISSUE3_RUNTIME_REENTRY_QUICKSTART.md"
    runtime_reentry_gates_note_path = "docs/ISSUE3_RUNTIME_REENTRY_GATES.md"
    runtime_revalidation_note_path = "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
    windows_full_use_note_path = "docs/WINDOWS_FULL_USE.md"
    commands = [ordered]@{
        runtime_surface_check = Format-RepoRootCommand -ScriptPath "scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        runtime_helper = Format-RepoRootCommand -ScriptPath "scripts\windows\show_google_issue3_enter_submit_runtime_revalidation.ps1" -Arguments $sharedBrowserArguments
        runtime_contract_self_test = "python " +
            (ConvertTo-PowerShellSingleQuotedLiteral -Value $runtimeContractCheckerPath) +
            " --self-test"
        runtime_contract_check = "python " +
            (ConvertTo-PowerShellSingleQuotedLiteral -Value $runtimeContractCheckerPath) +
            " --page " +
            (ConvertTo-PowerShellSingleQuotedLiteral -Value $pageSourcePath) +
            " --win32 " +
            (ConvertTo-PowerShellSingleQuotedLiteral -Value $win32SourcePath)
        shared_enter_order = Format-RepoRootCommand -ScriptPath "scripts\windows\show_headed_validation_suites.ps1" -Arguments (@{
                ChangeArea = "google-shared-enter-order"
                BrowserExe = $resolvedBrowserExe
            })
        focused_enter_order = Format-RepoRootCommand -ScriptPath "scripts\windows\show_headed_validation_suites.ps1" -Arguments (@{
                ChangeArea = "google-form-controls-enter-order"
                BrowserExe = $resolvedBrowserExe
            })
        linux_build_readiness_skip_zig = "python " +
            (ConvertTo-PowerShellSingleQuotedLiteral -Value $linuxBuildReadinessScriptPath) +
            " --repo-root " +
            (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot) +
            " --skip-zig-check"
        linux_build_readiness = "python " +
            (ConvertTo-PowerShellSingleQuotedLiteral -Value $linuxBuildReadinessScriptPath) +
            " --repo-root " +
            (ConvertTo-PowerShellSingleQuotedLiteral -Value $resolvedRepoRoot)
        windows_build = "zig build -Dtarget=x86_64-windows-msvc --summary all"
        reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1" -Arguments $sharedBrowserArguments
        reduced_google_fixture = "& ``\"$resolvedBrowserExe``\" browse --headed --window_width 1366 --window_height 900 ``\"http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1``\""
        live_google = "& ``\"$resolvedBrowserExe``\" browse --headed --window_width 1366 --window_height 900 ``\"https://www.google.com/``\""
    }
    notes = @(
        "Run runtime_surface_check first after branch movement so missing notes, helper scripts, or reduced Google surfaces fail before replay decisions are made.",
        "Run runtime_helper second when you want the fuller Windows-first route, including focused Page.zig and win32_backend.zig test commands, reopened on the same branch-local surface.",
        "Run runtime_contract_self_test before runtime_contract_check when you want fast proof that the checker still distinguishes vulnerable and guarded samples before pointing it at the real branch files.",
        "Run shared_enter_order before focused_enter_order when the replay should reopen from the broader shared keypress-before-submit ladder before narrowing back down to the dedicated form-controls route.",
        "Run linux_build_readiness_skip_zig before trusting focused Zig output when Linux or WSL dependency staging still needs to be confirmed independently from the active Zig line.",
        "Only widen into windows_build, reduced_google_probe, reduced_google_fixture, or live_google after the gate note, the source contract check, and the shared Enter-order ladders agree on the same runtime boundary.",
        "If the publication path for Page.zig and win32_backend.zig is still brittle or the active Zig line still fails in untouched files first, stay on smaller docs, diagnostics, or validation work instead of retrying the direct runtime patch."
    )
}

$helper.recommended_next_key = "runtime_surface_check"
$helper.recommended_next_command = $helper.commands[$helper.recommended_next_key]
$helper.recommended_next_reason = "Fail fast on missing runtime notes, helper scripts, source-contract checker wiring, or reduced Google surfaces before reopening the direct Page.zig and win32_backend.zig route."

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host "Google issue #3 runtime re-entry quickstart"
Write-Host ""
Write-Host ("Repo root:   {0}" -f $helper.repo_root)
Write-Host ("Browser exe: {0}" -f $helper.browser_exe)
Write-Host ""
Write-Host ("Recommended next helper: {0}" -f $helper.recommended_next_command)
Write-Host ("Why:                    {0}" -f $helper.recommended_next_reason)
Write-Host ""
Write-Host "Read first"
Write-Host "=========="
Write-Host ("  {0}" -f $helper.runtime_quickstart_note_path)
Write-Host ("  {0}" -f $helper.runtime_reentry_gates_note_path)
Write-Host ("  {0}" -f $helper.runtime_revalidation_note_path)
Write-Host ("  {0}" -f $helper.windows_full_use_note_path)
Write-Host ""
Write-Host "Fast route"
Write-Host "=========="
Write-Host ("  Surface check:              {0}" -f $helper.commands.runtime_surface_check)
Write-Host ("  Runtime helper:             {0}" -f $helper.commands.runtime_helper)
Write-Host ("  Contract self-test:         {0}" -f $helper.commands.runtime_contract_self_test)
Write-Host ("  Contract check:             {0}" -f $helper.commands.runtime_contract_check)
Write-Host ("  Shared Enter-order ladder:  {0}" -f $helper.commands.shared_enter_order)
Write-Host ("  Focused Enter-order ladder: {0}" -f $helper.commands.focused_enter_order)
Write-Host ("  Linux readiness skip Zig:   {0}" -f $helper.commands.linux_build_readiness_skip_zig)
Write-Host ("  Linux readiness full:       {0}" -f $helper.commands.linux_build_readiness)
Write-Host ("  Windows build:              {0}" -f $helper.commands.windows_build)
Write-Host ("  Reduced Google probe:       {0}" -f $helper.commands.reduced_google_probe)
Write-Host ("  Reduced Google fixture:     {0}" -f $helper.commands.reduced_google_fixture)
Write-Host ("  Live Google:                {0}" -f $helper.commands.live_google)
Write-Host ""
Write-Host "Notes"
Write-Host "====="
foreach ($note in $helper.notes) {
    Write-Host ("  - {0}" -f $note)
}
