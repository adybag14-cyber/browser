[CmdletBinding()]
param(
    [ValidateSet("issue3", "title", "homepage-fixture", "submit-path", "shared-enter-order", "trace", "attached-html", "all")]
    [string]$Profile = "issue3",
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$profileToScript = @{
    issue3 = "check_headed_validation_surface.ps1"
    title = "check_google_title_validation_surface.ps1"
    "homepage-fixture" = "check_google_homepage_fixture_validation_surface.ps1"
    "submit-path" = "check_google_submit_path_validation_surface.ps1"
    "shared-enter-order" = "check_google_shared_enter_order_validation_surface.ps1"
    trace = "check_google_trace_validation_surface.ps1"
    "attached-html" = "check_google_attached_html_validation_surface.ps1"
    all = "check_headed_validation_surface.ps1"
}

$targetScript = $profileToScript[$Profile]
if (-not $targetScript) {
    throw "Unknown Google validation surface profile: $Profile"
}

$scriptArgs = @()
if ($targetScript -eq "check_headed_validation_surface.ps1") {
    $scriptArgs += @("-Profile", $Profile)
}
if ($RepoRoot) {
    $scriptArgs += @("-RepoRoot", $RepoRoot)
}
if ($Json) {
    $scriptArgs += "-Json"
}

& (Join-Path $PSScriptRoot $targetScript) @scriptArgs
exit $LASTEXITCODE