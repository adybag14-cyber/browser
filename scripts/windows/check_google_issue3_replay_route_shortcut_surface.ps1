[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$validationSurfacePath = Join-Path $PSScriptRoot "check_google_issue3_replay_route_shortcut_validation_surface.ps1"
& $validationSurfacePath @PSBoundParameters
exit $LASTEXITCODE
