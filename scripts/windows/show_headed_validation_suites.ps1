[CmdletBinding(DefaultParameterSetName = "List")]
param(
    [Parameter(ParameterSetName = "List")]
    [switch]$List,

    [Parameter(ParameterSetName = "Suite")]
    [string]$SuiteName,

    [Parameter(ParameterSetName = "Change")]
    [ValidateSet("shell", "rendering", "input", "storage", "network", "downloads", "graphics", "google-input")]
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
        Path = "tmp-browser-smoke/form-controls"
        Purpose = "Label activation, focus, basic typing, and Enter-submit behavior."
        RecommendedWith = @("inline-flow", "find")
    }
    [pscustomobject]@{
        Name = "google-investigation-next"
        Category = "input"
        Path = "tmp-browser-smoke/google-investigation-next"
        Purpose = "Reduced Google-style localhost probes for focus churn, delayed readiness, correction, and Enter-submit ordering."
        RecommendedWith = @("form-controls", "inline-flow")
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
)

$changeRecommendations = @{
    shell = @("tabs", "browser-pages", "settings")
    rendering = @("layout-smoke", "flow-layout", "rendered-link-dom")
    input = @("form-controls", "inline-flow", "find")
    storage = @("cookie-persistence", "localstorage-persistence", "indexeddb-persistence")
    network = @("fetch-credentials", "fetch-abort", "websocket-smoke")
    downloads = @("file-upload", "downloads", "attachment-downloads")
    graphics = @("canvas-smoke", "multi-image", "layout-smoke")
    "google-input" = @("google-investigation-next", "form-controls", "inline-flow")
}

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
    exit 0
}

if ($PSCmdlet.ParameterSetName -eq "Change") {
    $names = $changeRecommendations[$ChangeArea]
    $items = foreach ($name in $names) {
        Get-SuiteRecord -Name $name
    }

    if ($Json) {
        $result = [pscustomobject]@{
            change_area = $ChangeArea
            suites = $items
            next_step = if ($ChangeArea -eq "google-input") {
                "Start with google-investigation-next, then run form-controls and inline-flow, and only then use the reduced homepage watcher or the smallest real Google manual check."
            } else {
                "Start with the narrowest suite, then add one nearby shared-behavior suite if the change crosses subsystems."
            }
        }
        $result | ConvertTo-Json -Depth 6
        exit 0
    }

    Write-Host ("Recommended suites for change area '{0}':" -f $ChangeArea)
    Write-Host (Format-SuiteList -Items $items)
    if ($ChangeArea -eq "google-input") {
        Write-Host "Next step: start with google-investigation-next, then run form-controls and inline-flow before the reduced homepage watcher or the smallest real Google manual pass."
    } else {
        Write-Host "Next step: start with the narrowest suite, then add one nearby shared-behavior suite if the change crosses subsystems."
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
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -SuiteName layout-smoke"
Write-Host "  .\\scripts\\windows\\show_headed_validation_suites.ps1 -ChangeArea google-input -Json"