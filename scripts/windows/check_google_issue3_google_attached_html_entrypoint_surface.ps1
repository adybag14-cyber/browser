[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$validationSurfacePath = Join-Path $PSScriptRoot "check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1"
& $validationSurfacePath @PSBoundParameters
exit $LASTEXITCODE
