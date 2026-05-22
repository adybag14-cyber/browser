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

    return "powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$env:LIGHTPANDA_REPO_ROOT = $escapedRepoRoot; $command`""
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

$buildCommand = "zig build -Dtarget=x86_64-windows-msvc --summary all"

$route = [ordered]@{
    issue = "Google issue #3 Enter-submit runtime revalidation"
    purpose = "Keep the shared Enter-submit ladder, the reduced Google title probe, the branch-local runtime revalidation note, and the live Google fallback on one Windows-first helper surface."
    repo_root = $resolvedRepoRoot
    browser_exe = $resolvedBrowserExe
    note_path = "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
    target_files = @(
        "src/browser/Page.zig",
        "src/display/win32_backend.zig"
    )
    related_files = @(
        "tmp-browser-smoke/form-controls/enter-submit-probe.ps1",
        "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1",
        "src/browser/tests/page/google_home_title_probe.html",
        "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md",
        "docs/WINDOWS_FULL_USE.md"
    )
    commands = [ordered]@{
        surface_check = Format-RepoRootCommand -ScriptPath "scripts\windows\check_google_issue3_enter_submit_runtime_revalidation_surface.ps1"
        build = $buildCommand
        shared_enter_default = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Arguments $sharedBrowserArguments
        shared_enter_deferred = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Arguments $sharedBrowserArguments -Switches @("DeferredEnter")
        shared_enter_google = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Arguments $sharedBrowserArguments -Switches @("GoogleEnterOrder")
        shared_enter_google_click = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\form-controls\enter-submit-probe.ps1" -Arguments $sharedBrowserArguments -Switches @("GoogleEnterOrder", "ClickFocus")
        reduced_google_probe = Format-RepoRootCommand -ScriptPath "tmp-browser-smoke\google-investigation-next\chrome-google-home-title-probe.ps1" -Arguments $sharedBrowserArguments
        reduced_google_fixture = "& `"$resolvedBrowserExe`" browse --headed --window_width 1366 --window_height 900 `"http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1`""
        live_google = "& `"$resolvedBrowserExe`" browse --headed --window_width 1366 --window_height 900 `"https://www.google.com/`""
    }
    expected_signals = @(
        "Printable keydown and keypress leave text in the focused Google query input.",
        "Enter keydown alone does not force an early submit transition.",
        "Enter submit happens only after the later keypress-time DOM phase.",
        "Stale queued suppression entries do not drop real later text_input bytes."
    )
    notes = @(
        "Run surface_check first when branch state may have moved and you want the note, helper, and probe files checked before replay.",
        "Use shared_enter_default to confirm the baseline Enter-submit path still works before narrowing into the Google-shaped ordering slices.",
        "Use shared_enter_deferred after changes that touch delayed native Enter submit without reopening the full Google-shaped route yet.",
        "Use shared_enter_google when the keypress-before-submit ordering is the main question but click-first focus is not required yet.",
        "Use shared_enter_google_click when reproducing the click-first path that most closely matches the real homepage boundary from issue #3.",
        "Use reduced_google_probe before live Google whenever the runtime patch touched Page.zig or win32_backend.zig and you want trace-ready output on the reduced fixture first.",
        "Only jump to reduced_google_fixture or live_google after the shared Enter-order ladder and reduced Google probe agree on the same event ordering."
    )
}

if ($Json) {
    $route | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Google issue #3 Enter-submit runtime revalidation"
Write-Host ""
Write-Host ("Repo root:    {0}" -f $route.repo_root)
Write-Host ("Browser exe:  {0}" -f $route.browser_exe)
Write-Host ("Read first:   {0}" -f $route.note_path)
Write-Host ""
Write-Host "Target files"
Write-Host "============"
foreach ($path in $route.target_files) {
    Write-Host ("  {0}" -f $path)
}
Write-Host ""
Write-Host "Replay route"
Write-Host "============"
Write-Host ("  Surface check:            {0}" -f $route.commands.surface_check)
Write-Host ("  Windows build:            {0}" -f $route.commands.build)
Write-Host ("  Shared Enter baseline:    {0}" -f $route.commands.shared_enter_default)
Write-Host ("  Shared Enter deferred:    {0}" -f $route.commands.shared_enter_deferred)
Write-Host ("  Shared Google ordering:   {0}" -f $route.commands.shared_enter_google)
Write-Host ("  Shared click-first route: {0}" -f $route.commands.shared_enter_google_click)
Write-Host ("  Reduced Google probe:     {0}" -f $route.commands.reduced_google_probe)
Write-Host ("  Reduced Google fixture:   {0}" -f $route.commands.reduced_google_fixture)
Write-Host ("  Live Google:              {0}" -f $route.commands.live_google)
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
