[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [int]$Port = 9582,
    [string]$InputText = "n",
    [switch]$LeaveOpen,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Add-QuotedArgument {
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

    $Arguments.Add("-$Name") | Out-Null
    $Arguments.Add((Format-PowerShellLiteral $Value)) | Out-Null
}

function Add-PlainArgument {
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

    $Arguments.Add("-$Name") | Out-Null
    $Arguments.Add($Value) | Out-Null
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$probeArguments = [System.Collections.Generic.List[string]]::new()
Add-QuotedArgument -Arguments $probeArguments -Name RepoRoot -Value $resolvedRepoRoot
Add-QuotedArgument -Arguments $probeArguments -Name BrowserExe -Value $BrowserExe
Add-PlainArgument -Arguments $probeArguments -Name Port -Value ([string]$Port)
Add-QuotedArgument -Arguments $probeArguments -Name InputText -Value $InputText
if ($LeaveOpen) {
    $probeArguments.Add("-LeaveOpen") | Out-Null
}

$probeCommand = "powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1"
if ($probeArguments.Count -gt 0) {
    $probeCommand += " " + ($probeArguments -join " ")
}

$probeUrl = "http://127.0.0.1:{0}/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1" -f $Port
$browseCommand = ".\\zig-out\\bin\\lightpanda.exe browse --browser_mode headed {0}" -f $probeUrl

$helper = [ordered]@{
    issue = "Google issue #3 Enter-submit runtime revalidation"
    purpose = "Print the smallest live-branch re-entry route for the current headed Windows Google Enter-submit gap so the runtime files, reduced probe, and direct replay command stay aligned."
    repo_root = $resolvedRepoRoot
    browser_exe = $BrowserExe
    port = $Port
    input_text = $InputText
    leave_open = [bool]$LeaveOpen
    note_paths = [ordered]@{
        runtime_revalidation = "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
        windows_full_use = "docs/WINDOWS_FULL_USE.md"
        execution_guide = "docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md"
    }
    target_files = [ordered]@{
        browser_runtime = "src/browser/Page.zig"
        win32_backend = "src/display/win32_backend.zig"
        reduced_probe = "src/browser/tests/page/google_home_title_probe.html"
        reduced_probe_runner = "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"
    }
    regression_anchors = [ordered]@{
        page = 'test "Page reduced Google fixture accepts focused keyboard text and Enter submit"'
        win32 = 'test "win32 dispatchInput suppresses later text_input after printable keydown across batches"'
    }
    commands = [ordered]@{
        build = "zig build -Dtarget=x86_64-windows-msvc --summary all"
        reduced_probe = $probeCommand
        direct_browse = $browseCommand
    }
    notes = @(
        "Use this helper when the headed issue #3 runtime slice is narrowed back to the native Enter-submit boundary between src/browser/Page.zig and src/display/win32_backend.zig.",
        "Run the Windows build first, then the reduced Google title probe, and only jump to the real Google homepage after the reduced probe shows typed text landing and Enter submit happening in the right order.",
        "The reduced probe is the honest re-entry point because the Linux Zig 0.17 fallback still fails in untouched branch code before the issue-specific assertions run.",
        "Keep docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md open beside the probe output so the deferred-submit and text-input suppression expectations stay visible while the runtime files are patched."
    )
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host "Google issue #3 Enter-submit runtime revalidation"
Write-Host ""
Write-Host ("Repo root:   {0}" -f $helper.repo_root)
if (-not [string]::IsNullOrWhiteSpace($helper.browser_exe)) {
    Write-Host ("Browser exe: {0}" -f $helper.browser_exe)
}
Write-Host ("Port:        {0}" -f $helper.port)
Write-Host ("Input text:  {0}" -f $helper.input_text)
Write-Host ""
Write-Host "Read-first notes:"
Write-Host ("  Runtime note:   {0}" -f $helper.note_paths.runtime_revalidation)
Write-Host ("  Windows runbook:{0}" -f (" " + $helper.note_paths.windows_full_use))
Write-Host ("  Exec guide:     {0}" -f $helper.note_paths.execution_guide)
Write-Host ""
Write-Host "Target files:"
Write-Host ("  Browser runtime: {0}" -f $helper.target_files.browser_runtime)
Write-Host ("  Win32 backend:   {0}" -f $helper.target_files.win32_backend)
Write-Host ("  Reduced probe:   {0}" -f $helper.target_files.reduced_probe)
Write-Host ("  Probe runner:    {0}" -f $helper.target_files.reduced_probe_runner)
Write-Host ""
Write-Host "Regression anchors:"
Write-Host ("  Page.zig:        {0}" -f $helper.regression_anchors.page)
Write-Host ("  win32_backend:   {0}" -f $helper.regression_anchors.win32)
Write-Host ""
Write-Host "Commands:"
Write-Host ("  Build:           {0}" -f $helper.commands.build)
Write-Host ("  Reduced probe:   {0}" -f $helper.commands.reduced_probe)
Write-Host ("  Direct browse:   {0}" -f $helper.commands.direct_browse)
Write-Host ""
Write-Host "Notes:"
foreach ($note in $helper.notes) {
    Write-Host ("- {0}" -f $note)
}
