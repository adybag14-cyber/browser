[CmdletBinding(DefaultParameterSetName = "Auto")]
param(
    [Parameter(ParameterSetName = "InputPath")]
    [string[]]$InputPath,
    [string]$PreferredInitialPage,
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
    [switch]$RequireCompleteSidecars,
    [switch]$RequireCompleteAssets
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function Test-HtmlExportPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $extension = [System.IO.Path]::GetExtension($Path)
    return [string]::Equals($extension, ".html", [System.StringComparison]::OrdinalIgnoreCase) -or
        [string]::Equals($extension, ".htm", [System.StringComparison]::OrdinalIgnoreCase)
}

function Resolve-OrderedAttachedHtmlInputs {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$RawInputPath,
        [string]$PreferredPage
    )

    $resolvedInputs = New-Object System.Collections.Generic.List[string]
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($path in $RawInputPath) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        if (-not (Test-Path -LiteralPath $path)) {
            throw "Attached HTML input path not found: $path"
        }

        $item = Get-Item -LiteralPath $path -ErrorAction Stop
        if ($item.PSIsContainer) {
            $htmlFiles = Get-ChildItem -LiteralPath $item.FullName -Recurse -File |
                Where-Object { Test-HtmlExportPath -Path $_.FullName } |
                Sort-Object FullName
            foreach ($htmlFile in $htmlFiles) {
                if ($seen.Add($htmlFile.FullName)) {
                    $null = $resolvedInputs.Add($htmlFile.FullName)
                }
            }
            continue
        }

        if (-not (Test-HtmlExportPath -Path $item.FullName)) {
            throw "Attached HTML input is not an .html or .htm file: $($item.FullName)"
        }

        if ($seen.Add($item.FullName)) {
            $null = $resolvedInputs.Add($item.FullName)
        }
    }

    if ($resolvedInputs.Count -eq 0) {
        throw "No attached HTML inputs were provided for the catalog helper."
    }

    if ([string]::IsNullOrWhiteSpace($PreferredPage)) {
        return @($resolvedInputs.ToArray())
    }

    $preferredMatch = $null
    $resolvedPreferredPath = $null
    if (Test-Path -LiteralPath $PreferredPage) {
        $resolvedPreferredPath = (Resolve-Path -LiteralPath $PreferredPage).Path
    }

    foreach ($candidate in $resolvedInputs) {
        if ($resolvedPreferredPath -and [string]::Equals($candidate, $resolvedPreferredPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            $preferredMatch = $candidate
            break
        }

        $leafName = [System.IO.Path]::GetFileName($candidate)
        if ([string]::Equals($leafName, $PreferredPage, [System.StringComparison]::OrdinalIgnoreCase)) {
            $preferredMatch = $candidate
            break
        }

        if ($candidate.EndsWith($PreferredPage, [System.StringComparison]::OrdinalIgnoreCase)) {
            $preferredMatch = $candidate
            break
        }
    }

    if (-not $preferredMatch) {
        $availableNames = ($resolvedInputs | ForEach-Object { [System.IO.Path]::GetFileName($_) }) -join ", "
        throw "Preferred initial page '$PreferredPage' did not match any selected attached HTML file. Available files: $availableNames"
    }

    $orderedInputs = New-Object System.Collections.Generic.List[string]
    $null = $orderedInputs.Add($preferredMatch)
    foreach ($candidate in $resolvedInputs) {
        if (-not [string]::Equals($candidate, $preferredMatch, [System.StringComparison]::OrdinalIgnoreCase)) {
            $null = $orderedInputs.Add($candidate)
        }
    }

    return @($orderedInputs.ToArray())
}

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
if ($RequireCompleteAssets -and ($AuditAssets -or $AuditSidecars)) {
    throw "-RequireCompleteAssets is only supported with the catalog launch or -PrintManifest modes. Run the asset audit first, then rerun with -RequireCompleteAssets when you want the manifest or localhost server to fail fast on incomplete bundles."
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
    $orderedInputs = Resolve-OrderedAttachedHtmlInputs -RawInputPath $InputPath -PreferredPage $PreferredInitialPage
    foreach ($path in $orderedInputs) {
        $launcherArgs += @("--input", $path)
    }
}

if ($PreferredInitialPage) {
    $launcherArgs += @("--preferred-initial-page", $PreferredInitialPage)
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
if ($RequireCompleteAssets) {
    $launcherArgs += "--require-complete-assets"
}

& $resolvedPython @launcherArgs
exit $LASTEXITCODE