[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "InputPath")]
    [string[]]$InputPath,
    [string]$RepoRoot,
    [string]$PythonExe = "python",
    [string]$Bind = "127.0.0.1",
    [int]$Port = 8235,
    [string]$StagingRoot,
    [switch]$GoogleStyle,
    [switch]$PrintManifest,
    [switch]$AuditAssets,
    [switch]$AuditAssetsJson,
    [switch]$AllowMissingAssets,
    [switch]$AuditSidecars,
    [switch]$AuditSidecarsJson,
    [switch]$AllowMissingSidecars,
    [switch]$RequireCompleteSidecars
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

if ($PrintManifest -and ($AuditAssets -or $AuditSidecars)) {
    throw "Choose either -PrintManifest, -AuditAssets, or -AuditSidecars. The attached-pages helper cannot combine manifest and audit modes in the same invocation."
}
if ($AuditAssets -and $AuditSidecars) {
    throw "Choose either -AuditAssets or -AuditSidecars. The attached-pages helper can only run one audit mode per invocation."
}
if ($AuditAssetsJson -and -not $AuditAssets) {
    throw "-AuditAssetsJson requires -AuditAssets."
}
if ($AllowMissingAssets -and -not $AuditAssets) {
    throw "-AllowMissingAssets is only supported with -AuditAssets."
}
if ($AuditSidecarsJson -and -not $AuditSidecars) {
    throw "-AuditSidecarsJson requires -AuditSidecars."
}
if ($AllowMissingSidecars -and -not $AuditSidecars) {
    throw "-AllowMissingSidecars is only supported with -AuditSidecars."
}
if ($RequireCompleteSidecars -and ($AuditAssets -or $AuditSidecars)) {
    throw "-RequireCompleteSidecars is only supported with the catalog launch or -PrintManifest modes. Run the sidecar audit first, then rerun with -RequireCompleteSidecars when you want the manifest or localhost server to fail fast on incomplete bundles."
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$launcherPath = Join-Path $resolvedRepoRoot "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py"
if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) {
    throw "attached pages catalog launcher not found: $launcherPath"
}

$resolvedPython = (Get-Command $PythonExe -ErrorAction Stop).Source

$launcherArgs = @($launcherPath, "--repo-root", $resolvedRepoRoot)

if ($PSCmdlet.ParameterSetName -eq "InputPath") {
    foreach ($path in $InputPath) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }
        $launcherArgs += @("--input", $path)
    }
    if ($launcherArgs.Count -le 3) {
        throw "No attached HTML inputs were provided for the catalog helper."
    }
}

if ($GoogleStyle) {
    $launcherArgs += "--google-style"
}

if (-not [string]::IsNullOrWhiteSpace($StagingRoot)) {
    $launcherArgs += @("--staging-root", $StagingRoot)
}

if ($PrintManifest) {
    $launcherArgs += "--print-manifest"
} elseif ($AuditAssets) {
    $launcherArgs += "--audit-assets"
    if ($AuditAssetsJson) {
        $launcherArgs += "--audit-assets-json"
    }
    if ($AllowMissingAssets) {
        $launcherArgs += "--allow-missing-assets"
    }
} elseif ($AuditSidecars) {
    $launcherArgs += "--audit-sidecars"
    if ($AuditSidecarsJson) {
        $launcherArgs += "--audit-sidecars-json"
    }
    if ($AllowMissingSidecars) {
        $launcherArgs += "--allow-missing-sidecars"
    }
} else {
    $launcherArgs += @("--bind", $Bind, "--port", "$Port")
}

if ($RequireCompleteSidecars) {
    $launcherArgs += "--require-complete-sidecars"
}

& $resolvedPython @launcherArgs
exit $LASTEXITCODE
