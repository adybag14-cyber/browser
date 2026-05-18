[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$target = Join-Path $PSScriptRoot 'check_google_issue3_suite_router_attached_html_quickstart_validation_surface.ps1'
$forwardArgs = @()

if ($PSBoundParameters.ContainsKey('RepoRoot')) {
    $forwardArgs += @('-RepoRoot', $RepoRoot)
}
if ($Json) {
    $forwardArgs += '-Json'
}

& $target @forwardArgs

if ($null -ne $LASTEXITCODE) {
    exit $LASTEXITCODE
}
