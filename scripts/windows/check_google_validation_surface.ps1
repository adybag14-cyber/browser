[CmdletBinding()]
param(
    [ValidateSet("issue3", "attached-html", "all")]
    [string]$Profile = "issue3",
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptArgs = @("-Profile", $Profile)
if ($RepoRoot) {
    $scriptArgs += @("-RepoRoot", $RepoRoot)
}
if ($Json) {
    $scriptArgs += "-Json"
}

& (Join-Path $PSScriptRoot "check_headed_validation_surface.ps1") @scriptArgs
exit $LASTEXITCODE