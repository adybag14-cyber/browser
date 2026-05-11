[CmdletBinding()]
param(
    [switch]$Json,
    [string]$RepoRoot,
    [string]$BrowserExe,
    [string]$Host = "127.0.0.1",
    [string]$InputText = "Q",
    [int]$DeferredEnterPort = 8155,
    [int]$ServerReadyTimeoutSeconds = 15,
    [int]$HomeWindowReadyAttempts = 60,
    [int]$HomeTitleWaitAttempts = 80,
    [int]$HomePollMilliseconds = 250
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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
        [Parameter(Mandatory = $true)]
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

$guide = '.\docs\FORM_CONTROLS_DEFERRED_ENTER_VALIDATION.md'
$chromeProbe = '.\tmp-browser-smoke\form-controls\chrome-deferred-enter-submit-probe.ps1'
$canonicalProbe = '.\tmp-browser-smoke\form-controls\deferred-enter-submit-probe.ps1'
$sharedProbe = '.\tmp-browser-smoke\form-controls\enter-submit-probe.ps1'
$broaderFlow = '.\scripts\windows\show_google_shared_enter_order_validation_flow.ps1'

$probeArgs = [System.Collections.Generic.List[string]]::new()
Add-SharedArgument -Arguments $probeArgs -Name RepoRoot -Value $RepoRoot
Add-SharedArgument -Arguments $probeArgs -Name BrowserExe -Value $BrowserExe
Add-SharedArgument -Arguments $probeArgs -Name Host -Value $Host
Add-SharedArgument -Arguments $probeArgs -Name InputText -Value $InputText
Add-SharedArgument -Arguments $probeArgs -Name Port -Value $DeferredEnterPort
Add-SharedArgument -Arguments $probeArgs -Name ServerReadyTimeoutSeconds -Value $ServerReadyTimeoutSeconds
Add-SharedArgument -Arguments $probeArgs -Name WindowReadyAttempts -Value $HomeWindowReadyAttempts
Add-SharedArgument -Arguments $probeArgs -Name TitleWaitAttempts -Value $HomeTitleWaitAttempts
Add-SharedArgument -Arguments $probeArgs -Name PollMilliseconds -Value $HomePollMilliseconds

$flow = [ordered]@{
    issue = "Headed Windows form-controls deferred Enter validation flow"
    focus = "Print the smallest shared deferred-submit checkpoint before widening back out to the Google Enter-order ladder."
    input_text = $InputText
    deferred_enter_port = $DeferredEnterPort
    host = $Host
    steps = @(
        [ordered]@{
            name = "guide"
            goal = "Read the dedicated deferred-submit guide so the pending-title checkpoint and expected markers are in front of you before execution."
            command = $guide
        }
        [ordered]@{
            name = "chrome-wrapper"
            goal = "Run the compatibility wrapper when you want a stable named probe entrypoint for issue comments, docs, and validation notes."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $chromeProbe, $(if ($probeArgs.Count -gt 0) { " " + ($probeArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "canonical-probe"
            goal = "Run the dedicated deferred-submit probe directly when you want the narrowest raw form-controls script."
            command = ("powershell -ExecutionPolicy Bypass -File {0}{1}" -f $canonicalProbe, $(if ($probeArgs.Count -gt 0) { " " + ($probeArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "shared-switch"
            goal = "Use the original shared runner surface when you want the deferred phase without changing your existing enter-submit command habits."
            command = ("powershell -ExecutionPolicy Bypass -File {0} -DeferredEnter{1}" -f $sharedProbe, $(if ($probeArgs.Count -gt 0) { " " + ($probeArgs -join " ") } else { "" }))
        }
        [ordered]@{
            name = "broader-google-stack"
            goal = "Widen back out to the shared Google Enter-order ladder only after the deferred checkpoint stays green."
            command = ("powershell -ExecutionPolicy Bypass -File {0}" -f $broaderFlow)
        }
    )
}

if ($Json) {
    $flow | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Headed Windows form-controls deferred Enter validation flow"
Write-Host ""
Write-Host ("Focus: {0}" -f $flow.focus)
Write-Host ("Host: {0}" -f $flow.host)
Write-Host ("Input text: {0}" -f $flow.input_text)
Write-Host ("Deferred Enter port: {0}" -f $flow.deferred_enter_port)
Write-Host ""
foreach ($step in $flow.steps) {
    Write-Host ("[{0}] {1}" -f $step.name, $step.goal)
    Write-Host ("  {0}" -f $step.command)
    Write-Host ""
}
