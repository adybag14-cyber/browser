[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$InputText = "n",
    [int]$Port = 9582,
    [int]$TimeoutSeconds = 90,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Format-PowerShellLiteral([string]$Value) {
    return "'" + $Value.Replace("'", "''") + "'"
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

if (-not $BrowserExe) {
    $BrowserExe = Join-Path $resolvedRepoRoot "zig-out\\bin\\lightpanda.exe"
}

$referenceNotePath = "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md"
$probeScriptPath = "tmp-browser-smoke/google-investigation-next/chrome-google-home-title-probe.ps1"
$fixturePath = "src/browser/tests/page/google_home_title_probe.html"
$runtimeFiles = @(
    "src/browser/Page.zig",
    "src/display/win32_backend.zig"
)

$quotedRepoRoot = Format-PowerShellLiteral $resolvedRepoRoot
$quotedBrowserExe = Format-PowerShellLiteral $BrowserExe
$quotedInputText = Format-PowerShellLiteral $InputText
$quotedFixtureUrl = Format-PowerShellLiteral (("http://127.0.0.1:{0}/{1}?google-home-probe=1") -f $Port, $fixturePath)
$quotedReadyUrl = Format-PowerShellLiteral (("http://127.0.0.1:{0}/{1}") -f $Port, $fixturePath)

$helper = [ordered]@{
    issue = "Google issue #3 Enter-submit runtime quickstart"
    purpose = "Print the smallest Windows replay ladder for the blocked Enter-submit runtime slice so the next writable checkout can restart the reduced Google probe, the direct local fixture, and the trace pickup without re-deriving the same order."
    repo_root = $resolvedRepoRoot
    browser_exe = $BrowserExe
    input_text = $InputText
    port = $Port
    timeout_seconds = $TimeoutSeconds
    reference_note_path = $referenceNotePath
    probe_script_path = $probeScriptPath
    fixture_path = $fixturePath
    target_runtime_files = $runtimeFiles
    commands = [ordered]@{
        build = "zig build -Dtarget=x86_64-windows-msvc --summary all"
        reduced_google_probe = "powershell -ExecutionPolicy Bypass -File .\\$probeScriptPath -RepoRoot $quotedRepoRoot -BrowserExe $quotedBrowserExe -InputText $quotedInputText -Port $Port -TimeoutSeconds $TimeoutSeconds"
        direct_fixture_server = "python -m http.server $Port --bind 127.0.0.1"
        direct_fixture_browse = "& $quotedBrowserExe browse --browser_mode headed $quotedFixtureUrl"
        direct_fixture_ready_check = "Invoke-WebRequest -UseBasicParsing -Uri $quotedReadyUrl -TimeoutSec 5"
        backend_logs = "Get-ChildItem -Path .\\tmp-browser-smoke\\google-investigation-next -Filter 'runtime-input-backend-*.log' -File | Sort-Object LastWriteTime -Desc | Select-Object -First 5 FullName, LastWriteTime"
        wndproc_logs = "Get-ChildItem -Path .\\tmp-browser-smoke\\google-investigation-next -Filter 'wndproc-input-*.log' -File | Sort-Object LastWriteTime -Desc | Select-Object -First 5 FullName, LastWriteTime"
    }
    expected_signals = @(
        "The reduced Google probe reaches a title marker that starts with FOCUSED or A=INPUT:q before typing.",
        (("Typed replay reaches TYPED:{0} before Enter is sent.") -f $InputText),
        (("Submit replay reaches SUBMIT:{0} after the Enter path instead of on the first native keydown.") -f $InputText),
        "The latest runtime-input-backend and wndproc-input traces agree on the Enter ordering instead of showing stale text-input suppression."
    )
    notes = @(
        "Start with the reduced Google probe before jumping back to the real homepage. It starts its own localhost server, clears prior runtime-input traces in tmp-browser-smoke/google-investigation-next, and emits a JSON summary when it finishes.",
        "Use the direct fixture server plus direct fixture browse commands only when you need to watch the local title-probe page manually after the reduced probe already narrowed the failure.",
        "Keep docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md open beside this helper. That note holds the exact Page.zig and win32_backend.zig change shape for the deferred Enter-submit path and the byte-matched text-input suppression queue.",
        "The only direct runtime code targets for this blocked slice remain src/browser/Page.zig and src/display/win32_backend.zig.",
        "Prefer a branch-compatible Zig toolchain before retrying focused zig test work for this slice. The attached Zig 0.17 fallback has already failed in untouched branch files before reaching the narrowed runtime tests."
    )
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host "Google issue #3 Enter-submit runtime quickstart"
Write-Host ""
Write-Host (("Repo root:      {0}") -f $helper.repo_root)
Write-Host (("Browser exe:    {0}") -f $helper.browser_exe)
Write-Host (("Input text:     {0}") -f $helper.input_text)
Write-Host (("Probe port:     {0}") -f $helper.port)
Write-Host (("Timeout:        {0}s") -f $helper.timeout_seconds)
Write-Host (("Reference note: {0}") -f $helper.reference_note_path)
Write-Host ""
Write-Host "Runtime files:"
foreach ($path in $helper.target_runtime_files) {
    Write-Host (("  - {0}") -f $path)
}
Write-Host ""
Write-Host "Commands:"
Write-Host (("  1. Build:              {0}") -f $helper.commands.build)
Write-Host (("  2. Reduced probe:      {0}") -f $helper.commands.reduced_google_probe)
Write-Host (("  3. Manual server:      {0}") -f $helper.commands.direct_fixture_server)
Write-Host (("  4. Ready check:        {0}") -f $helper.commands.direct_fixture_ready_check)
Write-Host (("  5. Direct fixture:     {0}") -f $helper.commands.direct_fixture_browse)
Write-Host (("  6. Backend trace list: {0}") -f $helper.commands.backend_logs)
Write-Host (("  7. WndProc trace list: {0}") -f $helper.commands.wndproc_logs)
Write-Host ""
Write-Host "Expected signals:"
foreach ($signal in $helper.expected_signals) {
    Write-Host (("  - {0}") -f $signal)
}
Write-Host ""
Write-Host "Notes:"
foreach ($note in $helper.notes) {
    Write-Host (("  - {0}") -f $note)
}
