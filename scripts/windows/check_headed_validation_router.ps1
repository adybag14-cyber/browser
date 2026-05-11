[CmdletBinding()]
param(
    [ValidateSet("catalog", "change-areas", "all")]
    [string]$Profile = "all",
    [string]$RepoRoot,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HeadedValidationHelpers.ps1")

function New-RouterResult {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Scope,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Check,
        [Parameter(Mandatory = $true)]
        [bool]$Passed,
        [Parameter(Mandatory = $true)]
        [string]$Detail,
        [string]$Path = ""
    )

    return [pscustomobject]@{
        Scope = $Scope
        Name = $Name
        Check = $Check
        Path = $Path
        Passed = [bool]$Passed
        Detail = $Detail
    }
}

function Get-JsonFromScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [string[]]$Arguments = @()
    )

    $json = & $ScriptPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Script failed while gathering validation router metadata: $ScriptPath $($Arguments -join ' ')"
    }

    return (($json -join [Environment]::NewLine) | ConvertFrom-Json -Depth 12)
}

function Test-RepoRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $fullPath = Join-Path $RepoRoot $RelativePath
    $extension = [System.IO.Path]::GetExtension($RelativePath)
    if ([string]::IsNullOrWhiteSpace($extension)) {
        return Test-Path -LiteralPath $fullPath -PathType Container
    }

    return Test-Path -LiteralPath $fullPath -PathType Leaf
}

function Get-ReferencedScriptPaths {
    param(
        [string]$Command
    )

    if ([string]::IsNullOrWhiteSpace($Command)) {
        return @()
    }

    $results = New-Object System.Collections.Generic.List[string]
    $pattern = '((?:\.\\|\./)[^ ''"]+?\.ps1)'
    foreach ($match in [System.Text.RegularExpressions.Regex]::Matches($Command, $pattern)) {
        $relativePath = $match.Groups[1].Value -replace '^[.][\\/]', ''
        $relativePath = $relativePath -replace '\\', '/'
        Add-UniqueString -List $results -Value $relativePath
    }

    return @($results)
}

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
} else {
    Resolve-LightpandaRepoRoot $PSScriptRoot
}

$routerScript = Join-Path $resolvedRepoRoot "scripts/windows/show_headed_validation_suites.ps1"
if (-not (Test-Path -LiteralPath $routerScript -PathType Leaf)) {
    throw "Validation router script not found: $routerScript"
}

$catalog = @(Get-JsonFromScript -ScriptPath $routerScript -Arguments @("-Json"))
$suiteLookup = @{}
foreach ($suite in $catalog) {
    if ($null -ne $suite -and -not [string]::IsNullOrWhiteSpace($suite.Name)) {
        $suiteLookup[$suite.Name] = $suite
    }
}

$results = New-Object System.Collections.Generic.List[object]

if ($Profile -in @("catalog", "all")) {
    foreach ($suite in $catalog) {
        if ($null -eq $suite) {
            $results.Add((New-RouterResult -Scope "catalog" -Name "(null)" -Check "suite-record" -Passed $false -Detail "The suite catalog emitted a null suite entry.")) | Out-Null
            continue
        }

        $suitePath = [string]$suite.Path
        $suiteName = [string]$suite.Name
        $pathExists = Test-RepoRelativePath -RepoRoot $resolvedRepoRoot -RelativePath $suitePath
        $pathDetail = if ($pathExists) {
            "Catalog path exists."
        } else {
            "Catalog path is missing from the repo."
        }
        $results.Add((New-RouterResult -Scope "catalog" -Name $suiteName -Check "path-exists" -Passed $pathExists -Detail $pathDetail -Path $suitePath)) | Out-Null

        foreach ($recommendedName in @($suite.RecommendedWith)) {
            $targetExists = $suiteLookup.ContainsKey([string]$recommendedName)
            $recommendedDetail = if ($targetExists) {
                "Recommended suite resolves in the router catalog."
            } else {
                "Recommended suite is not present in the router catalog."
            }
            $results.Add((New-RouterResult -Scope "catalog" -Name $suiteName -Check ("recommended-with:{0}" -f $recommendedName) -Passed $targetExists -Detail $recommendedDetail -Path $suitePath)) | Out-Null
        }
    }
}

if ($Profile -in @("change-areas", "all")) {
    $changeAreas = @(
        "shell",
        "rendering",
        "input",
        "storage",
        "network",
        "downloads",
        "graphics",
        "google-input",
        "google-submit-path",
        "google-live-trace",
        "google-saved-html",
        "google-attached-html",
        "manual-html",
        "attached-html"
    )

    foreach ($changeArea in $changeAreas) {
        $changeRecord = Get-JsonFromScript -ScriptPath $routerScript -Arguments @("-ChangeArea", $changeArea, "-Json")
        $changeSuites = @($changeRecord.suites)
        $hasSuites = $changeSuites.Count -gt 0
        $suiteCountDetail = if ($hasSuites) {
            "Change area returned one or more suite recommendations."
        } else {
            "Change area returned no suite recommendations."
        }
        $results.Add((New-RouterResult -Scope "change-area" -Name $changeArea -Check "has-suites" -Passed $hasSuites -Detail $suiteCountDetail)) | Out-Null

        foreach ($suite in $changeSuites) {
            if ($null -eq $suite) {
                $results.Add((New-RouterResult -Scope "change-area" -Name $changeArea -Check "suite-record" -Passed $false -Detail "Change-area routing emitted a null suite record.")) | Out-Null
                continue
            }

            $suiteName = [string]$suite.Name
            $knownSuite = $suiteLookup.ContainsKey($suiteName)
            $knownDetail = if ($knownSuite) {
                "Change-area suite resolves in the router catalog."
            } else {
                "Change-area suite is not present in the router catalog."
            }
            $results.Add((New-RouterResult -Scope "change-area" -Name $changeArea -Check ("suite:{0}" -f $suiteName) -Passed $knownSuite -Detail $knownDetail -Path ([string]$suite.Path))) | Out-Null
        }

        foreach ($flowPath in @(Get-ReferencedScriptPaths -Command ([string]$changeRecord.flow_command))) {
            $flowExists = Test-RepoRelativePath -RepoRoot $resolvedRepoRoot -RelativePath $flowPath
            $flowDetail = if ($flowExists) {
                "Flow helper script exists."
            } else {
                "Flow helper script is missing from the repo."
            }
            $results.Add((New-RouterResult -Scope "change-area" -Name $changeArea -Check "flow-command" -Passed $flowExists -Detail $flowDetail -Path $flowPath)) | Out-Null
        }
    }
}

$failures = @($results | Where-Object { -not $_.Passed })

if ($Json) {
    [ordered]@{
        profile = $Profile
        repo_root = $resolvedRepoRoot
        checked_count = @($results).Count
        failure_count = @($failures).Count
        checks = @($results)
    } | ConvertTo-Json -Depth 10

    if ($failures.Count -gt 0) {
        exit 1
    }

    exit 0
}

Write-Host "Headed validation router check"
Write-Host ""
Write-Host ("Profile: {0}" -f $Profile)
Write-Host ("Repo root: {0}" -f $resolvedRepoRoot)
Write-Host ""

foreach ($result in $results) {
    $status = if ($result.Passed) { "PASS" } else { "FAIL" }
    if ([string]::IsNullOrWhiteSpace($result.Path)) {
        Write-Host ("[{0}] {1} :: {2}" -f $status, $result.Name, $result.Check)
    } else {
        Write-Host ("[{0}] {1} :: {2} :: {3}" -f $status, $result.Name, $result.Check, $result.Path)
    }
    Write-Host ("  {0}" -f $result.Detail)
}

Write-Host ""
if ($failures.Count -eq 0) {
    Write-Host "Validation router is internally consistent for this profile."
    exit 0
}

Write-Host ("Detected {0} validation router problem(s)." -f $failures.Count)
Write-Host "Repair the broken suite mapping before trusting the broader headed validation flow."
exit 1
