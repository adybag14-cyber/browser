[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Keep the older entrypoint checker name working while the branch converges on
# the shared replay-route shortcut surface check.
$forwardedArguments = @{}
if ($PSBoundParameters.ContainsKey("RepoRoot")) {
    $forwardedArguments["RepoRoot"] = $RepoRoot
}
if ($Json.IsPresent) {
    $forwardedArguments["Json"] = $true
}

& (Join-Path $PSScriptRoot "check_google_issue3_replay_route_shortcut_validation_surface.ps1") @forwardedArguments
