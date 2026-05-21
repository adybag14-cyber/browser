[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'HeadedValidationHelpers.ps1')

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$diagnostics = [ordered]@{
    issue = 'Google issue #3 attached trace diagnostics'
    purpose = 'Show the quickest current route to inspect headed issue #3 trace artifacts for the localhost attached-page bundle, while calling out that the session wait trace already covers those pages but the Win32 input, browse render, and page presentation gates are still narrower on the live branch.'
    repo_root = $resolvedRepoRoot
    attached_pages = @(
        'Control your online safety and privacy – Google Safety Centre (09_05_2026 21：23：40).html'
        'Job Application for [Expression of Interest] Research Manager, Interpretability at Anthropic (09_05_2026 21：25：29).html'
        'Presidential Unsealing and Reporting System for UAP Encounters _ U.S. Department of War.html'
    )
    localhost_probes = @(
        'google_home_title_probe.html'
        'body_onload_keyboard_input.html'
        'mouse_down_focus_input.html'
    )
    trace_files = [ordered]@{
        session_wait = 'tmp-browser-smoke/google-investigation-next/session-wait.log'
        runtime_input_backend = 'tmp-browser-smoke/google-investigation-next/runtime-input-backend-<pid>.log'
        wndproc_input = 'tmp-browser-smoke/google-investigation-next/wndproc-input-<pid>.log'
        browse_render = 'tmp-browser-smoke/google-investigation-next/browse-render.log'
    }
    live_trace_gates = [ordered]@{
        session_wait = 'src/browser/Session.zig'
        runtime_input_backend = 'src/display/win32_backend.zig'
        wndproc_input = 'src/display/win32_backend.zig'
        browse_render = 'src/lightpanda.zig'
        page_presentation = 'src/browser/Page.zig'
    }
    live_status = @(
        'session-wait traces already cover the three localhost probes and the three saved attached export names on the live branch'
        'win32 input traces still only auto-enable for google-home-* and google.com on the live branch'
        'browse render traces still only auto-enable for google-home-* and google.com on the live branch'
        'page presentation traces still only auto-enable for google-home-* and google.com on the live branch'
    )
    recommended_steps = @(
        'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_windows_replay_attached_html_quickstart.ps1'
        'powershell -ExecutionPolicy Bypass -File .\scripts\windows\show_google_issue3_attached_html_target_bundle_suite_surface.ps1'
        'Get-ChildItem .\tmp-browser-smoke\google-investigation-next\session-wait.log'
        'Get-ChildItem .\tmp-browser-smoke\google-investigation-next\runtime-input-backend-*.log'
        'Get-ChildItem .\tmp-browser-smoke\google-investigation-next\wndproc-input-*.log'
        'Get-ChildItem .\tmp-browser-smoke\google-investigation-next\browse-render.log'
    )
    notes = @(
        'Use this helper when the replay is already focused on issue #3 and you want a compact reminder of which traces are expected to fire today for the attached-page bundle.'
        'Treat session-wait.log as the broadest current live signal for the attached-page bundle because its gate in src/browser/Session.zig already includes the three localhost probes and the saved attached export names.'
        'If session-wait.log moves but runtime-input-backend, wndproc-input, or browse-render stay quiet for the same attached-page replay, that is still consistent with the current live branch and points back to the narrower gates in src/display/win32_backend.zig, src/lightpanda.zig, and src/browser/Page.zig.'
        'Keep this helper beside the replay attached-html quickstart when comparing the Google homepage path against the localhost attached-page path so the current diagnostics gap stays visible.'
    )
}

if ($Json) {
    $diagnostics | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host 'Google issue #3 attached trace diagnostics'
Write-Host ''
Write-Host ("Repo root: {0}" -f $diagnostics.repo_root)
Write-Host ''
Write-Host 'Attached-page bundle:'
foreach ($page in $diagnostics.attached_pages) {
    Write-Host ("  - {0}" -f $page)
}
Write-Host ''
Write-Host 'Localhost probes:'
foreach ($probe in $diagnostics.localhost_probes) {
    Write-Host ("  - {0}" -f $probe)
}
Write-Host ''
Write-Host 'Trace files to inspect:'
Write-Host ("  Session wait:          {0}" -f $diagnostics.trace_files.session_wait)
Write-Host ("  Runtime input backend: {0}" -f $diagnostics.trace_files.runtime_input_backend)
Write-Host ("  WndProc input:         {0}" -f $diagnostics.trace_files.wndproc_input)
Write-Host ("  Browse render:         {0}" -f $diagnostics.trace_files.browse_render)
Write-Host ''
Write-Host 'Live trace-gate source files:'
Write-Host ("  Session wait:          {0}" -f $diagnostics.live_trace_gates.session_wait)
Write-Host ("  Runtime input backend: {0}" -f $diagnostics.live_trace_gates.runtime_input_backend)
Write-Host ("  WndProc input:         {0}" -f $diagnostics.live_trace_gates.wndproc_input)
Write-Host ("  Browse render:         {0}" -f $diagnostics.live_trace_gates.browse_render)
Write-Host ("  Page presentation:     {0}" -f $diagnostics.live_trace_gates.page_presentation)
Write-Host ''
Write-Host 'Current live status:'
foreach ($line in $diagnostics.live_status) {
    Write-Host ("  - {0}" -f $line)
}
Write-Host ''
Write-Host 'Recommended commands:'
foreach ($step in $diagnostics.recommended_steps) {
    Write-Host ("  - {0}" -f $step)
}
Write-Host ''
Write-Host 'Notes:'
foreach ($note in $diagnostics.notes) {
    Write-Host ("  - {0}" -f $note)
}
