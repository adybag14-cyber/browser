[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$SummaryPath,
    [string[]]$InputPath,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-PowerShellSingleQuotedLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Add-SharedArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        $Value
    )

    if ($null -eq $Value) {
        return
    }
    if ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    $Arguments.Add("-$Name")
    if ($Value -is [string]) {
        $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $Value))
    } else {
        $Arguments.Add([string]$Value)
    }
}

function Add-SharedPathArrayArgument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string[]]$Values
    )

    if (-not $Values -or $Values.Count -eq 0) {
        return
    }

    $Arguments.Add("-$Name")
    foreach ($value in $Values) {
        $Arguments.Add((ConvertTo-PowerShellSingleQuotedLiteral -Value $value))
    }
}

function Format-HelperCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [System.Collections.Generic.List[string]]$Arguments,
        [string[]]$Switches = @()
    )

    $command = "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\$ScriptName"
    if ($Arguments -and $Arguments.Count -gt 0) {
        $command += " " + ($Arguments -join ' ')
    }
    foreach ($switchName in $Switches) {
        if ([string]::IsNullOrWhiteSpace($switchName)) {
            continue
        }

        $command += " -$switchName"
    }

    return $command
}

function Format-HelperCommandWithRepoRootEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [hashtable]$Arguments = @{},
        [string[]]$Switches = @(),
        [string]$RepoRootOverride
    )

    if ([string]::IsNullOrWhiteSpace($RepoRootOverride)) {
        $fallbackArguments = [System.Collections.Generic.List[string]]::new()
        foreach ($entry in $Arguments.GetEnumerator()) {
            $value = $entry.Value
            if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
                Add-SharedPathArrayArgument -Arguments $fallbackArguments -Name $entry.Key -Values @($value)
            } else {
                Add-SharedArgument -Arguments $fallbackArguments -Name $entry.Key -Value $value
            }
        }
        return Format-HelperCommand -ScriptName $ScriptName -Arguments $fallbackArguments -Switches $Switches
    }

    $command = "& '.\\scripts\\windows\\$ScriptName'"
    foreach ($entry in $Arguments.GetEnumerator()) {
        $value = $entry.Value
        if ($null -eq $value) {
            continue
        }
        if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            continue
        }
        if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
            $valueList = @($value | Where-Object {
                if ($_ -is [string]) {
                    -not [string]::IsNullOrWhiteSpace($_)
                } else {
                    $null -ne $_
                }
            })
            if ($valueList.Count -eq 0) {
                continue
            }

            $command += " -$($entry.Key)"
            foreach ($item in $valueList) {
                $escapedItem = ("$item") -replace "'", "''"
                $command += " '$escapedItem'"
            }
            continue
        }

        $escapedValue = ("$value") -replace "'", "''"
        $command += (" -{0} '{1}'" -f $entry.Key, $escapedValue)
    }

    foreach ($switchName in $Switches) {
        if ([string]::IsNullOrWhiteSpace($switchName)) {
            continue
        }

        $command += " -$switchName"
    }

    $escapedRepoRoot = ("$RepoRootOverride") -replace "'", "''"
    return "powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$env:LIGHTPANDA_REPO_ROOT = '$escapedRepoRoot'; $command`""
}

function Write-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Host ""
    Write-Host $Title
    Write-Host ("=" * $Title.Length)
}

function Write-Commands {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Specialized.OrderedDictionary]$Commands
    )

    foreach ($entry in $Commands.GetEnumerator()) {
        Write-Host ("[{0}]" -f $entry.Key)
        Write-Host ("  {0}" -f $entry.Value)
    }
}

if (-not $RepoRoot -and -not [string]::IsNullOrWhiteSpace($env:LIGHTPANDA_REPO_ROOT)) {
    $RepoRoot = $env:LIGHTPANDA_REPO_ROOT
}

$sharedArguments = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $sharedArguments -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $sharedArguments -Name SummaryPath -Value $SummaryPath
Add-SharedPathArrayArgument -Arguments $sharedArguments -Name InputPath -Values $InputPath

$helper = [ordered]@{
    issue = 'Google issue #3 Enter-submit runtime replay'
    purpose = 'Print the smallest current Windows replay ladder for the blocked Enter-submit runtime slice so the next writable checkout can reopen the shared keypress-before-submit probes, the reduced Google title probe, and the final live Google repro without rediscovering the route.'
    repo_root = $RepoRoot
    summary_path = $SummaryPath
    explicit_input_path_count = if ($InputPath) { @($InputPath).Count } else { 0 }
    runtime_revalidation_note_path = 'docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md'
    windows_full_use_note_path = 'docs/WINDOWS_FULL_USE.md'
    production_execution_guide_path = 'docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md'
    commands = [ordered]@{
        google_shared_enter_order = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-shared-enter-order'
        }) -RepoRootOverride $RepoRoot
        google_form_controls_enter_order = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_headed_validation_suites.ps1' -Arguments ([ordered]@{
            ChangeArea = 'google-form-controls-enter-order'
        }) -RepoRootOverride $RepoRoot
        enter_submit_probe_default = 'powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1'
        enter_submit_probe_deferred = 'powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1 -DeferredEnter'
        enter_submit_probe_google = 'powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1 -GoogleEnterOrder'
        enter_submit_probe_google_click_focus = 'powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\form-controls\\enter-submit-probe.ps1 -GoogleEnterOrder -ClickFocus'
        reduced_google_title_probe = 'powershell -ExecutionPolicy Bypass -File .\\tmp-browser-smoke\\google-investigation-next\\chrome-google-home-title-probe.ps1'
        reduced_google_fixture_manual = '.\\zig-out\\bin\\lightpanda.exe browse --browser_mode headed http://127.0.0.1:8123/src/browser/tests/page/google_home_title_probe.html?google-home-probe=1'
        live_google_manual = '.\\zig-out\\bin\\lightpanda.exe browse --browser_mode headed https://www.google.com/'
    }
    notes = @(
        'Read docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md first. It names the exact Page.zig and win32_backend.zig slice and the regression expectations this replay is proving.',
        'Start with google_shared_enter_order when you want the router to reprint the bounded shared keypress-before-submit ladder before you drop into direct probe commands.',
        'Use google_form_controls_enter_order when the change is already narrowed to the stricter issue #3 Enter-order checkpoint and you want the router to keep that lane visible.',
        'Run enter_submit_probe_default first, then enter_submit_probe_deferred, then enter_submit_probe_google, then enter_submit_probe_google_click_focus. Treat that as the ordered narrowing ladder for the runtime slice.',
        'Run reduced_google_title_probe before live_google_manual so the reduced Google fixture proves KEYDOWN versus SUBMIT title ordering before the real homepage adds more moving parts.',
        'Use reduced_google_fixture_manual only when you already have the local Python server serving the test fixture and you want the direct headed browse route beside the probe script.',
        'Only use live_google_manual after the shared Enter-order probes and the reduced Google title probe agree on the same ordering, text commit, and submit behavior.',
        'Keep docs/WINDOWS_FULL_USE.md nearby when you need the broader validation catalog again, and keep docs/HEADED_MODE_PRODUCTION_EXECUTION_GUIDE.md nearby when the slice widens back into a larger headed validation pass.'
    )
    recommended_order = @(
        'google_shared_enter_order',
        'google_form_controls_enter_order',
        'enter_submit_probe_default',
        'enter_submit_probe_deferred',
        'enter_submit_probe_google',
        'enter_submit_probe_google_click_focus',
        'reduced_google_title_probe',
        'live_google_manual'
    )
}

if ($Json) {
    $helper | ConvertTo-Json -Depth 8
    exit 0
}

Write-Section -Title $helper.issue
Write-Host $helper.purpose
Write-Host ""
Write-Host ("runtime note: {0}" -f $helper.runtime_revalidation_note_path)
Write-Host ("windows note: {0}" -f $helper.windows_full_use_note_path)
Write-Host ("guide: {0}" -f $helper.production_execution_guide_path)
Write-Host ""
Write-Host "recommended order:"
foreach ($commandKey in $helper.recommended_order) {
    Write-Host ("  - {0}" -f $commandKey)
}
Write-Section -Title 'Commands'
Write-Commands -Commands $helper.commands
Write-Section -Title 'Notes'
foreach ($note in $helper.notes) {
    Write-Host ("- {0}" -f $note)
}
