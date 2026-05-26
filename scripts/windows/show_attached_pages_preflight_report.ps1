[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "InputPath")]
    [string[]]$InputPath,
    [switch]$UseWorkspaceAgentFiles,
    [string]$PreferredInitialPage,
    [string]$RepoRoot,
    [string]$PythonExe = "python",
    [string]$Bind = "127.0.0.1",
    [int]$Port = 8235,
    [switch]$GoogleStyle,
    [switch]$Json,
    [switch]$AllowMissingSidecars,
    [switch]$AllowMissingAssets
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Resolve-WorkspaceAgentFilesPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $cursor = Get-Item -LiteralPath $RepoRoot -ErrorAction Stop
    while ($null -ne $cursor) {
        $candidate = Join-Path $cursor.FullName "agent_files"
        if (Test-Path -LiteralPath $candidate -PathType Container) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
        $cursor = $cursor.Parent
    }

    throw "workspace agent_files folder not found from repo root: $RepoRoot"
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

if ($UseWorkspaceAgentFiles -and $PSCmdlet.ParameterSetName -eq "InputPath") {
    throw "Choose either -InputPath or -UseWorkspaceAgentFiles. The attached-pages preflight wrapper only accepts one explicit input source per invocation."
}

$reportPath = Join-Path $resolvedRepoRoot "tmp-browser-smoke/attached-pages/attached_pages_preflight_report.py"
if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
    throw "attached pages preflight report not found: $reportPath"
}

$resolvedPython = (Get-Command $PythonExe -ErrorAction Stop).Source

$reportArgs = @($reportPath, "--repo-root", $resolvedRepoRoot, "--bind", $Bind, "--port", "$Port")

if ($UseWorkspaceAgentFiles) {
    $workspaceAgentFilesPath = Resolve-WorkspaceAgentFilesPath -RepoRoot $resolvedRepoRoot
    $reportArgs += @("--input", $workspaceAgentFilesPath)
} elseif ($PSCmdlet.ParameterSetName -eq "InputPath") {
    foreach ($path in $InputPath) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }
        $reportArgs += @("--input", $path)
    }
    if ($reportArgs.Count -le 7) {
        throw "No attached HTML inputs were provided for the preflight report helper."
    }
}

if (-not [string]::IsNullOrWhiteSpace($PreferredInitialPage)) {
    $reportArgs += @("--preferred-initial-page", $PreferredInitialPage)
}
if ($GoogleStyle) {
    $reportArgs += "--google-style"
}
if ($Json) {
    $reportArgs += "--json"
}
if ($AllowMissingSidecars) {
    $reportArgs += "--allow-missing-sidecars"
}
if ($AllowMissingAssets) {
    $reportArgs += "--allow-missing-assets"
}

& $resolvedPython @reportArgs
exit $LASTEXITCODE
