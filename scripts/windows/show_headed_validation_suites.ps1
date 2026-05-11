[CmdletBinding(DefaultParameterSetName = "List")]
param(
    [Parameter(ParameterSetName = "List")]
    [switch]$List,

    [Parameter(ParameterSetName = "Suite")]
    [string]$SuiteName,

    [Parameter(ParameterSetName = "Change")]
    [ValidateSet("shell", "rendering", "input", "storage", "network", "downloads", "graphics", "google-input", "google-submit-path", "google-form-controls-enter-order", "google-live-trace", "google-saved-html", "google-attached-html", "manual-html", "attached-html")]
    [string]$ChangeArea,

    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$suiteCatalog = @(
    [pscustomobject]@{
        Name = "tabs"
        Category = "shell"
        Path = "tmp-browser-smoke/tabs"
        Purpose = "Tab strip, reopen, startup shell, and session restore behavior."
        RecommendedWith = @("browser-pages", "settings")
    }
    [pscustomobject]@{
        Name = "browser-pages"
        Category = "shell"
        Path = "tmp-browser-smoke/browser-pages"
        Purpose = "browser:// pages, shell actions, and browser-page navigation flows."
        RecommendedWith = @("tabs", "settings")
    }
    [pscustomobject]@{
        Name = "settings"
        Category = "shell"
        Path = "tmp-browser-smoke/settings"
        Purpose = "Settings interactions and persistence-adjacent shell checks."
        RecommendedWith = @("browser-pages", "tabs")
    }
    [pscustomobject]@{
        Name = "popup"
        Category = "shell"
        Path = "tmp-browser-smoke/popup"
        Purpose = "Popup policy, opener behavior, and new-window routing."
        RecommendedWith = @("tabs", "browser-pages")
    }
    [pscustomobject]@{
        Name = "wrapped-link"
        Category = "shell"
        Path = "tmp-browser-smoke/wrapped-link"
        Purpose = "Wrapped inline hit testing and navigation behavior."
        RecommendedWith = @("rendered-link-dom", "layout-smoke")
    }
    [pscustomobject]@{
        Name = "stop-loading"
        Category = "shell"
        Path = "tmp-browser-smoke/stop-loading"
        Purpose = "Stop, reload recovery, and committed-page restore flows."
        RecommendedWith = @("tabs", "browser-pages")
    }
    [pscustomobject]@{
        Name = "bookmarks"
        Category = "shell"
        Path = "tmp-browser-smoke/bookmarks"
        Purpose = "Bookmark toggles, deletion flows, and keyboard paths."
        RecommendedWith = @("browser-pages", "tabs")
    }
    [pscustomobject]@{
        Name = "layout-smoke"
        Category = "rendering"
        Path = "tmp-browser-smoke/layout-smoke"
        Purpose = "General layout, clipping, screenshots, and visual regression pages."
        RecommendedWith = @("flow-layout", "rendered-link-dom")
    }
    [pscustomobject]@{
        Name = "inline-flow"
        Category = "rendering"
        Path = "tmp-browser-smoke/inline-flow"
        Purpose = "Wrapped inline layout plus mixed controls, links, focus, and submit behavior."
        RecommendedWith = @("form-controls", "layout-smoke")
    }
    [pscustomobject]@{
        Name = "flow-layout"
        Category = "rendering"
        Path = "tmp-browser-smoke/flow-layout"
        Purpose = "Shared block and image flow behavior."
        RecommendedWith = @("layout-smoke", "image-smoke")
    }
    [pscustomobject]@{
        Name = "rendered-link-dom"
        Category = "rendering"
        Path = "tmp-browser-smoke/rendered-link-dom"
        Purpose = "Rendered link boxes, hit targets, and DOM-visible link behavior."
        RecommendedWith = @("wrapped-link", "layout-smoke")
    }
    [pscustomobject]@{
        Name = "font-render"
        Category = "rendering"
        Path = "tmp-browser-smoke/font-render"
        Purpose = "Font loading, fallback, text metrics, and button layout behavior."
        RecommendedWith = @("font-smoke", "zoom")
    }
    [pscustomobject]@{
        Name = "font-smoke"
        Category = "rendering"
        Path = "tmp-browser-smoke/font-smoke"
        Purpose = "Authenticated and anonymous font request policy."
        RecommendedWith = @("font-render", "stylesheet-smoke")
    }
    [pscustomobject]@{
        Name = "image-smoke"
        Category = "rendering"
        Path = "tmp-browser-smoke/image-smoke"
        Purpose = "Runtime image, script, and module fetch behavior on the shared request path."
        RecommendedWith = @("flow-layout", "stylesheet-smoke")
    }
    [pscustomobject]@{
        Name = "stylesheet-smoke"
        Category = "rendering"
        Path = "tmp-browser-smoke/stylesheet-smoke"
        Purpose = "Stylesheet loading, import handling, and CSS policy."
        RecommendedWith = @("image-smoke", "font-smoke")
    }
    [pscustomobject]@{
        Name = "zoom"
        Category = "rendering"
        Path = "tmp-browser-smoke/zoom"
        Purpose = "Headed zoom behavior against shared layout and text paths."
        RecommendedWith = @("font-render", "layout-smoke")
    }
    [pscustomobject]@{
        Name = "form-controls"
        Category = "input"
        Path = "scripts/windows/run_form_controls_validation.ps1"
        Purpose = "One-command shared label-click, immediate Enter-submit, deferred Enter-submit, reduced Google-home submit, and stricter localhost enter-order validation runner for the headed input baseline."
        RecommendedWith = @("inline-flow", "google-shared-enter-order")
    }
    [pscustomobject]@{
        Name = "google-investigation-next"
        Category = "input"
        Path = "tmp-browser-smoke/google-investigation-next"
        Purpose = "Reduced Google-style localhost probes for focus churn, delayed readiness, correction, and Enter-submit ordering."
        RecommendedWith = @("google-recommended", "google-title")
    }
    [pscustomobject]@{
        Name = "google-recommended"
        Category = "input"
        Path = "scripts/windows/run_google_issue3_recommended_validation.ps1"
        Purpose = "One-command localhost-first issue #3 runner that includes the bounded title pass, reduced homepage pass, submit-timing check, the shared Enter-order wrapper with the reduced-home keypress-before-submit probe, the watch phase, and optional saved-page follow-up."
        RecommendedWith = @("google-investigation-next", "google-title")
    }
    [pscustomobject]@{
        Name = "google-title"
        Category = "input"
        Path = "scripts/windows/run_google_home_title_probe.ps1"
        Purpose = "Bounded reduced-homepage title, focus, typing, and Enter-submit ordering probe on the real headed surface before the broader Google-home or shared Enter-order passes."
        RecommendedWith = @("google-quick", "google-home")
    }
    [pscustomobject]@{
        Name = "google-quick"
        Category = "input"
        Path = "scripts/windows/run_google_quick_validation.ps1"
        Purpose = "One-command fast title-plus-watch first pass on the real headed surface before the reduced homepage, submit-timing, or shared Enter-order phases."
        RecommendedWith = @("google-title", "google-home")
    }
    [pscustomobject]@{
        Name = "google-home"
        Category = "input"
        Path = "scripts/windows/run_google_home_validation.ps1"
        Purpose = "One-command reduced homepage focus, typing, keydown, and Enter-submit probe on the real headed surface after the localhost Google-style probes are green."
        RecommendedWith = @("google-title", "google-submit-timing")
    }
    [pscustomobject]@{
        Name = "google-homepage-fixture"
        Category = "input"
        Path = "scripts/windows/run_google_homepage_fixture_validation.ps1"
        Purpose = "One-command bounded saved Google homepage fixture probe that serves the saved localhost page and separately checks focus, typed text, and Enter submit on the real headed surface."
        RecommendedWith = @("google-home", "google-submit-timing")
    }
    [pscustomobject]@{
        Name = "google-submit-path"
        Category = "input"
        Path = "scripts/windows/run_google_issue3_submit_path_validation.ps1"
        Purpose = "One-command issue #3 submit-path runner that jumps straight from the earlier title gates into the saved homepage fixture, submit-timing, and shared Enter-order slices."
        RecommendedWith = @("google-homepage-fixture", "google-submit-timing")
    }
    [pscustomobject]@{
        Name = "google-submit-timing"
        Category = "input"
        Path = "scripts/windows/run_google_submit_timing_validation.ps1"
        Purpose = "One-command wrapper for the bounded Google-shaped keydown, keypress, and submit-ordering probe on the real headed surface before the broader shared gates or manual Google pass. Use the dedicated flow helper when you want that read-first handoff printed before execution."
        RecommendedWith = @("google-title", "google-shared-enter-order")
    }
    [pscustomobject]@{
        Name = "google-form-controls-enter-order"
        Category = "input"
        Path = "scripts/windows/run_google_form_controls_enter_order_validation.ps1"
        Purpose = "Dedicated shared form-controls Enter-order runner that narrows issue #3 to the smallest real-surface keypress-before-submit gate before widening into the broader shared Enter-order ladder."
        RecommendedWith = @("google-shared-enter-order", "form-controls")
    }
    [pscustomobject]@{
        Name = "google-shared-enter-order"
        Category = "input"
        Path = "scripts/windows/run_google_shared_enter_order_validation.ps1"
        Purpose = "Shared label-click baseline plus shared submit gates, reduced Google-home form coverage, the reusable reduced-home keypress-before-submit probe, inline-flow submit coverage, and the stricter localhost keypress-before-submit wrapper through one runner entrypoint."
        RecommendedWith = @("google-submit-timing", "google-live-trace")
    }
    [pscustomobject]@{
        Name = "google-live-trace"
        Category = "input"
        Path = "scripts/windows/show_google_trace_validation_flow.ps1"
        Purpose = "Read-first reduced-home and live Google trace-capture handoff after the bounded localhost, submit-timing, shared Enter-order, and attached-page phases are green."
        RecommendedWith = @("google-submit-timing", "google-shared-enter-order")
    }
    [pscustomobject]@{
        Name = "google-saved-html"
        Category = "input"
        Path = "scripts/windows/show_saved_page_google_validation_flow.ps1"
        Purpose = "Saved-page Google-style localhost follow-up that keeps the localhost, title, reduced homepage, bounded submit-timing, shared Enter-order, and manual issue #3 flow on one printed path."
        RecommendedWith = @("google-recommended", "manual-user")
    }
    [pscustomobject]@{
        Name = "google-attached-html"
        Category = "input"
        Path = "scripts/windows/show_google_attached_html_validation_flow.ps1"
        Purpose = "Attached-page Google-style localhost follow-up that auto-discovers current-run HTML and routes it through the same issue #3 bounded flow before manual headed replay."
        RecommendedWith = @("google-saved-html", "manual-user")
    }
    [pscustomobject]@{
        Name = "find"
        Category = "input"
        Path = "tmp-browser-smoke/find"
        Purpose = "Find-in-page surface behavior."
        RecommendedWith = @("form-controls", "inline-flow")
    }
    [pscustomobject]@{
        Name = "file-upload"
        Category = "downloads"
        Path = "tmp-browser-smoke/file-upload"
        Purpose = "Chooser flows, replacement, cancel, and multipart submit behavior."
        RecommendedWith = @("downloads", "attachment-downloads")
    }
    [pscustomobject]@{
        Name = "downloads"
        Category = "downloads"
        Path = "tmp-browser-smoke/downloads"
        Purpose = "Normal download create, open, and delete shell flows."
        RecommendedWith = @("attachment-downloads", "browser-pages")
    }
    [pscustomobject]@{
        Name = "attachment-downloads"
        Category = "downloads"
        Path = "tmp-browser-smoke/attachment-downloads"
        Purpose = "Attachment navigation and download promotion flows."
        RecommendedWith = @("downloads", "file-upload")
    }
    [pscustomobject]@{
        Name = "cookie-persistence"
        Category = "storage"
        Path = "tmp-browser-smoke/cookie-persistence"
        Purpose = "Cookie clear, cross-tab, and restart behavior."
        RecommendedWith = @("browser-pages", "tabs")
    }
    [pscustomobject]@{
        Name = "localstorage-persistence"
        Category = "storage"
        Path = "tmp-browser-smoke/localstorage-persistence"
        Purpose = "localStorage same-tab, cross-tab, and restart behavior."
        RecommendedWith = @("tabs", "browser-pages")
    }
    [pscustomobject]@{
        Name = "indexeddb-persistence"
        Category = "storage"
        Path = "tmp-browser-smoke/indexeddb-persistence"
        Purpose = "IndexedDB clear, cursor, index, transaction, and restart behavior."
        RecommendedWith = @("tabs", "browser-pages")
    }
    [pscustomobject]@{
        Name = "sessionstorage-scope"
        Category = "storage"
        Path = "tmp-browser-smoke/sessionstorage-scope"
        Purpose = "same-tab versus new-tab sessionStorage scoping."
        RecommendedWith = @("tabs", "browser-pages")
    }
    [pscustomobject]@{
        Name = "fetch-abort"
        Category = "network"
        Path = "tmp-browser-smoke/fetch-abort"
        Purpose = "Abort propagation on in-flight requests."
        RecommendedWith = @("fetch-credentials", "websocket-smoke")
    }
    [pscustomobject]@{
        Name = "fetch-credentials"
        Category = "network"
        Path = "tmp-browser-smoke/fetch-credentials"
        Purpose = "Credentialed fetch and cookie policy behavior."
        RecommendedWith = @("fetch-abort", "cookie-persistence")
    }
    [pscustomobject]@{
        Name = "websocket-smoke"
        Category = "network"
        Path = "tmp-browser-smoke/websocket-smoke"
        Purpose = "WebSocket connection, close, and protocol behavior."
        RecommendedWith = @("fetch-abort", "fetch-credentials")
    }
    [pscustomobject]@{
        Name = "canvas-smoke"
        Category = "graphics"
        Path = "tmp-browser-smoke/canvas-smoke"
        Purpose = "Canvas 2D, drawImage, text metrics, and early WebGL probes."
        RecommendedWith = @("multi-image", "layout-smoke")
    }
    [pscustomobject]@{
        Name = "multi-image"
        Category = "graphics"
        Path = "tmp-browser-smoke/multi-image"
        Purpose = "Multiple image placement checks."
        RecommendedWith = @("canvas-smoke", "image-smoke")
    }
    [pscustomobject]@{
        Name = "bare-metal-release"
        Category = "graphics"
        Path = "tmp-browser-smoke/bare-metal-release"
        Purpose = "Packaged-image and bare-metal release validation."
        RecommendedWith = @("tabs", "browser-pages")
    }
    [pscustomobject]@{
        Name = "manual-user"
        Category = "manual-html"
        Path = "tmp-browser-smoke/manual-user"
        Purpose = "Manual headed validation helpers for saved or attached localhost HTML pages after the bounded suite is green, including attached-page discovery and flow printing helpers."
        RecommendedWith = @("form-controls", "google-investigation-next")
    }
)

$changeRecommendations = @{
    shell = @("tabs", "browser-pages", "settings")
    rendering = @("layout-smoke", "flow-layout", "rendered-link-dom")
    input = @("form-controls", "inline-flow", "find")
    storage = @("cookie-persistence", "localstorage-persistence", "indexeddb-persistence")
    network = @("fetch-credentials", "fetch-abort", "websocket-smoke")
    downloads = @("file-upload", "downloads", "attachment-downloads")
    graphics = @("canvas-smoke", "multi-image", "layout-smoke")
    "google-input" = @("google-investigation-next", "google-recommended", "google-title", "google-quick", "google-home", "google-homepage-fixture", "google-submit-path", "google-submit-timing", "google-form-controls-enter-order", "google-shared-enter-order", "google-live-trace", "manual-user")
    "google-submit-path" = @("google-homepage-fixture", "google-submit-path", "google-submit-timing", "google-form-controls-enter-order", "google-shared-enter-order", "google-live-trace")
    "google-form-controls-enter-order" = @("google-form-controls-enter-order", "google-shared-enter-order", "google-submit-timing")
    "google-live-trace" = @("google-submit-timing", "google-shared-enter-order", "google-live-trace", "manual-user")
    "google-saved-html" = @("manual-user", "google-investigation-next", "google-recommended", "google-shared-enter-order")
    "google-attached-html" = @("manual-user", "google-recommended", "google-shared-enter-order")
    "manual-html" = @("manual-user", "form-controls", "layout-smoke")
    "attached-html" = @("manual-user", "form-controls", "layout-smoke")
}

$googleFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_input_validation_flow.ps1"
$googleTitleGuideCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_title_probe_trace_guide.ps1"
$googleTitleFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_title_validation_flow.ps1"
$googleHomepageFixtureFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1"
$googleSubmitPathSurfaceCheckCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_submit_path_validation_surface.ps1"
$googleSubmitPathFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_path_validation_flow.ps1"
$googleSubmitPathRunnerCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_submit_path_validation.ps1"
$googleSubmitTimingFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1"
$googleFormControlsEnterOrderGuideCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_trace_guide.ps1"
$googleFormControlsEnterOrderFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_validation_flow.ps1"
$googleFormControlsEnterOrderRunnerCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_form_controls_enter_order_validation.ps1"
$googleSharedEnterOrderFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1"
$googleLiveTraceFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_trace_validation_flow.ps1"
$googleSavedHtmlFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_saved_page_google_validation_flow.ps1 -InputPath '<saved-html-or-folder>'"
$googleAttachedHtmlFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1"
$manualHtmlFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_localhost_html_validation_recommended.ps1 -Wait"
$attachedHtmlFlowCommand = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1"

function Get-SuiteRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return $suiteCatalog | Where-Object { $_.Name -eq $Name }
}

function Format-SuiteList {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Items
    )

    $Items |
        Sort-Object Category, Name |
        Select-Object Name, Category, Path, Purpose |
        Format-Table -Wrap -AutoSize |
        Out-String -Width 220
}

if ($PSCmdlet.ParameterSetName -eq "Suite") {
    $suite = Get-SuiteRecord -Name $SuiteName
    if (-not $suite) {
        throw "Unknown suite name: $SuiteName"
    }

    if ($Json) {
        $suite | ConvertTo-Json -Depth 5
        exit 0
    }

    Write-Host ("Suite: {0}" -f $suite.Name)
    Write-Host ("Category: {0}" -f $suite.Category)
    Write-Host ("Path: {0}" -f $suite.Path)
    Write-Host ("Purpose: {0}" -f $suite.Purpose)
    Write-Host ("Recommended with: {0}" -f ($suite.RecommendedWith -join ", "))
    if ($suite.Name -eq "google-recommended") {
        Write-Host ("Flow helper: {0}" -f $googleFlowCommand)
    }
    if ($suite.Name -eq "google-title") {
        Write-Host ("Marker guide: {0}" -f $googleTitleGuideCommand)
        Write-Host ("Flow helper: {0}" -f $googleTitleFlowCommand)
    }
    if ($suite.Name -eq "google-homepage-fixture") {
        Write-Host ("Flow helper: {0}" -f $googleHomepageFixtureFlowCommand)
    }
    if ($suite.Name -eq "google-submit-path") {
        Write-Host ("Surface checker: {0}" -f $googleSubmitPathSurfaceCheckCommand)
        Write-Host ("Flow helper: {0}" -f $googleSubmitPathFlowCommand)
        Write-Host ("Runner: {0}" -f $googleSubmitPathRunnerCommand)
    }
    if ($suite.Name -eq "google-submit-timing") {
        Write-Host ("Flow helper: {0}" -f $googleSubmitTimingFlowCommand)
    }
    if ($suite.Name -eq "google-form-controls-enter-order") {
        Write-Host ("Marker guide: {0}" -f $googleFormControlsEnterOrderGuideCommand)
        Write-Host ("Flow helper: {0}" -f $googleFormControlsEnterOrderFlowCommand)
        Write-Host ("Runner: {0}" -f $googleFormControlsEnterOrderRunnerCommand)
    }
    if ($suite.Name -eq "google-shared-enter-order") {
        Write-Host ("Flow helper: {0}" -f $googleSharedEnterOrderFlowCommand)
    }
    if ($suite.Name -eq "google-live-trace") {
        Write-Host ("Flow helper: {0}" -f $googleLiveTraceFlowCommand)
    }
    if ($suite.Name -eq "google-saved-html") {
        Write-Host ("Flow helper: {0}" -f $googleSavedHtmlFlowCommand)
    }
    if ($suite.Name -eq "google-attached-html") {
        Write-Host ("Flow helper: {0}" -f $googleAttachedHtmlFlowCommand)
    }
    exit 0
}

if ($PSCmdlet.ParameterSetName -eq "Change") {
    $names = $changeRecommendations[$ChangeArea]
    $items = foreach ($name in $names) {
        Get-SuiteRecord -Name $name
    }

    $nextStep = if ($ChangeArea -eq "google-input") {
        "Start with the dedicated Google-input flow helper, then read the reduced title marker guide and title flow helper before widening into google-investigation-next, google-title, google-quick, google-home, google-homepage-fixture, google-submit-path, google-submit-timing, the dedicated form-controls Enter-order gate, the broader shared Enter-order stack, and the dedicated live trace helper. Use .\\scripts\\windows\\run_google_issue3_submit_path_validation.ps1 when the earlier title gates are already green and you want the later saved-homepage-fixture, submit-timing, and shared Enter-order slices in one narrower command before the live trace helper."
    } elseif ($ChangeArea -eq "google-submit-path") {
        "Start with the dedicated submit-path surface checker so the later note, helper, and bounded probes fail fast if one was renamed or removed, then print the flow helper so the saved homepage fixture, submit-timing slice, the dedicated form-controls Enter-order gate, and the shared Enter-order ladder stay in order before you decide whether to run the one-command submit-path runner or isolate one later-stage slice by itself."
    } elseif ($ChangeArea -eq "google-form-controls-enter-order") {
        "Start with the dedicated form-controls Enter-order flow helper so the narrowest shared keypress-before-submit gate is printed in order before you run the dedicated wrapper, inspect the dedicated marker guide, or widen into the broader shared Enter-order ladder."
    } elseif ($ChangeArea -eq "google-live-trace") {
        "Start with the dedicated live trace flow helper so the reduced-home and live Google capture path stays ordered after the bounded localhost, submit-timing, and shared Enter-order gates, then keep manual follow-up scoped to the smallest remaining divergence."
    } elseif ($ChangeArea -eq "google-saved-html") {
        "Start with the dedicated saved-page Google flow helper so the localhost, quick, reduced homepage, submit-timing, shared Enter-order, and manual follow-up stay in one stable issue #3 order."
    } elseif ($ChangeArea -eq "google-attached-html") {
        "Start with the dedicated attached-HTML Google flow helper so auto-discovered saved pages stay on the same localhost-first issue #3 order before the manual follow-up or the smallest live Google retest."
    } elseif ($ChangeArea -eq "manual-html") {
        "Start with the matching bounded suite, then use the one-command recommended localhost HTML runner to auto-route attached or saved pages into the right helper before dropping to the printed flow map."
    } elseif ($ChangeArea -eq "attached-html") {
        "Start with the attached-page flow helper so the current workspace snapshots auto-discover, summarize, and route into the right localhost or Google-style follow-up without restating each file path by hand."
    } else {
        "Start with the narrowest suite, then add one nearby shared-behavior suite if the change crosses subsystems."
    }

    $flowCommand = if ($ChangeArea -eq "google-input") {
        $googleFlowCommand
    } elseif ($ChangeArea -eq "google-submit-path") {
        $googleSubmitPathFlowCommand
    } elseif ($ChangeArea -eq "google-form-controls-enter-order") {
        $googleFormControlsEnterOrderFlowCommand
    } elseif ($ChangeArea -eq "google-live-trace") {
        $googleLiveTraceFlowCommand
    } elseif ($ChangeArea -eq "google-saved-html") {
        $googleSavedHtmlFlowCommand
    } elseif ($ChangeArea -eq "google-attached-html") {
        $googleAttachedHtmlFlowCommand
    } elseif ($ChangeArea -eq "manual-html") {
        $manualHtmlFlowCommand
    } elseif ($ChangeArea -eq "attached-html") {
        $attachedHtmlFlowCommand
    } else {
        $null
    }

    if ($Json) {
        $result = [pscustomobject]@{
            change_area = $ChangeArea
            suites = $items
            next_step = $nextStep
            flow_command = $flowCommand
        }
        $result | ConvertTo-Json -Depth 6
        exit 0
    }

    Write-Host ("Recommended suites for change area '{0}':" -f $ChangeArea)
    Write-Host (Format-SuiteList -Items $items)
    Write-Host ("Next step: {0}" -f $nextStep)
    if ($ChangeArea -eq "google-submit-path") {
        Write-Host ("Surface checker: {0}" -f $googleSubmitPathSurfaceCheckCommand)
    }
    if ($flowCommand) {
        Write-Host ("Flow helper: {0}" -f $flowCommand)
    }
    exit 0
}

if ($Json) {
    $suiteCatalog | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host "Headed validation suites"
Write-Host ""
Write-Host (Format-SuiteList -Items $suiteCatalog)
Write-Host "Examples:"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea input"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName form-controls"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName layout-smoke"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-recommended"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_input_validation_flow.ps1"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-title"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_title_probe_trace_guide.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_title_validation_flow.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_title_validation.ps1"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-quick"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_quick_validation.ps1"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-home"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_home_validation.ps1"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-homepage-fixture"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_homepage_fixture_validation.ps1"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-submit-path"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_submit_path_validation_surface.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_path_validation_flow.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_issue3_submit_path_validation.ps1"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-submit-timing"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_timing_validation_flow.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_submit_timing_validation.ps1"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-form-controls-enter-order"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_trace_guide.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_validation_flow.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_form_controls_enter_order_validation.ps1"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-shared-enter-order"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-live-trace"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_trace_validation_flow.ps1"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-saved-html"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName google-attached-html"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input -Json"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-submit-path"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-form-controls-enter-order"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-live-trace"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-saved-html"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-attached-html"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea manual-html"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea attached-html"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_input_validation_flow.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_homepage_fixture_validation_flow.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_submit_path_validation_flow.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_form_controls_enter_order_validation_flow.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_shared_enter_order_validation_flow.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_saved_page_google_validation_flow.ps1 -InputPath '<saved-html-or-folder>'"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_google_attached_html_validation.ps1 -Wait"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1"
Write-Host "  powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\run_localhost_html_validation_recommended.ps1 -Wait"
