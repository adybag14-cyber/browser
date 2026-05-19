import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "purpose": "The replay-attached quickstart keeps the launcher companion checker visible before the helper is trusted.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'",
        "purpose": "The replay-attached quickstart keeps the launcher companion helper visible with an attached-page input path.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'",
        "purpose": "The replay-attached quickstart keeps the repo-root-preserving launcher companion helper visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
        "purpose": "The replay-attached quickstart keeps the validation-router attached-html surface checker visible before the launcher companion handoff.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1",
        "purpose": "The replay-attached quickstart keeps the validation-router attached-html helper visible before the launcher companion handoff.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "docs/ISSUE3_VALIDATION_ROUTER_ATTACHED_HTML_QUICKSTART.md",
        "purpose": "The replay-attached quickstart keeps the validation-router attached-html note visible beside the launcher companion route.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_change_area_quickstart.ps1",
        "purpose": "The replay-attached quickstart keeps the attached-html change-area helper visible before the launcher companion handoff.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "docs/ISSUE3_ATTACHED_HTML_CHANGE_AREA_QUICKSTART.md",
        "purpose": "The replay-attached quickstart keeps the attached-html change-area note visible beside the launcher companion route.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1",
        "purpose": "The replay-attached quickstart keeps the issue-specific Google attached-html entrypoint helper visible after the launcher companion handoff.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "purpose": "The replay-attached quickstart keeps the issue-specific Google attached-html entrypoint note visible beside the launcher companion route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "surface_check_command = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $surfaceCheckArguments",
        "purpose": "The launcher companion helper wires its dedicated fail-fast checker into the surfaced command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "launcher_companion_surface_check = 'scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1'",
        "purpose": "The launcher companion helper keeps the checker path visible in its companion paths map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "wrapper_strict_bundle = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('RequireCompleteSidecars', 'RequireCompleteAssets')",
        "purpose": "The launcher companion helper surfaces the strict sidecar-plus-asset wrapper path.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "wrapper_google_strict_bundle = Format-HelperCommand -ScriptName 'start_attached_pages_catalog.ps1' -Arguments $wrapperArguments -Switches @('GoogleStyle', 'RequireCompleteSidecars', 'RequireCompleteAssets')",
        "purpose": "The launcher companion helper surfaces the strict Google-style wrapper path.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $surfaceCheckArguments",
        "purpose": "The launcher companion helper keeps the pinned proof-entrypoint surface checker wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $wrapperArguments",
        "purpose": "The launcher companion helper keeps the pinned proof-entrypoint helper wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "attached_html_target_bundle_proof_entrypoint_note = 'docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md'",
        "purpose": "The launcher companion helper keeps the pinned bundle proof note visible in its companion paths map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "windows_replay_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $wrapperArguments",
        "purpose": "The launcher companion helper keeps the replay-attached Windows quickstart wired into its command map for direct re-entry after preflight.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $wrapperArguments",
        "purpose": "The launcher companion helper keeps the compact replay-route shortcut helper wired into its command map for direct re-entry after preflight.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "python_sidecar_audit = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--audit-sidecars')",
        "purpose": "The launcher companion helper preserves the preferred first page through the Python sidecar audit path.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "python_google_sidecar_audit = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--google-style', '--audit-sidecars')",
        "purpose": "The launcher companion helper preserves the preferred first page through the Google-style Python sidecar audit path.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "python_strict_bundle = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--require-complete-sidecars', '--require-complete-assets')",
        "purpose": "The launcher companion helper surfaces the strict sidecar-plus-asset Python path while preserving the preferred first page.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "python_google_strict_bundle = Format-PythonLauncherCommand -RepoRootOverride $resolvedRepoRoot -InputValues $InputPath -PreferredInitialPage $PreferredInitialPage -Flags @('--google-style', '--require-complete-sidecars', '--require-complete-assets')",
        "purpose": "The launcher companion helper surfaces the strict Google-style Python path while preserving the preferred first page.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "windows_full_use_attached_html_catalog_quickstart_note = 'docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md'",
        "purpose": "The launcher companion helper keeps the Windows full-use attached-html catalog quickstart note visible beside the replay companion paths.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host ((\"  6. Strict bundle:      {0}\") -f $helper.helper_commands.wrapper_strict_bundle)",
        "purpose": "The launcher companion helper prints the strict wrapper bundle route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host ((\"  10. Google strict:     {0}\") -f $helper.helper_commands.wrapper_google_strict_bundle)",
        "purpose": "The launcher companion helper prints the strict Google-style wrapper route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host ((\"  6. Strict bundle:      {0}\") -f $helper.helper_commands.python_strict_bundle)",
        "purpose": "The launcher companion helper prints the strict Python bundle route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host ((\"  10. Google strict:     {0}\") -f $helper.helper_commands.python_google_strict_bundle)",
        "purpose": "The launcher companion helper prints the strict Google-style Python route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host 'Pinned bundle proof follow-up:'",
        "purpose": "The launcher companion helper prints a dedicated proof follow-up section header before the proof-only helper pair.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host ((\"  Surface check:      {0}\") -f $helper.helper_commands.proof_surface_check)",
        "purpose": "The launcher companion helper prints the pinned proof-entrypoint surface checker.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host ((\"  Proof entrypoint:   {0}\") -f $helper.helper_commands.proof_entrypoint)",
        "purpose": "The launcher companion helper prints the pinned proof-entrypoint helper.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host ((\"Launcher surface check: {0}\") -f $helper.companion_paths.launcher_companion_surface_check)",
        "purpose": "The launcher companion helper prints the checker path again with the companion paths.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host ((\"Bundle proof note:       {0}\") -f $helper.companion_paths.attached_html_target_bundle_proof_entrypoint_note)",
        "purpose": "The launcher companion helper prints the pinned bundle proof note beside the companion paths.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host 'Replay re-entry helpers:'",
        "purpose": "The launcher companion helper prints a dedicated replay re-entry section after proof-only follow-up.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host ((\"  Windows replay quick: {0}\") -f $helper.helper_commands.windows_replay_quickstart)",
        "purpose": "The launcher companion helper prints the replay-attached Windows quickstart command for direct re-entry after preflight.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host ((\"  Replay-route helper: {0}\") -f $helper.helper_commands.replay_route_shortcut)",
        "purpose": "The launcher companion helper prints the compact replay-route shortcut command for direct re-entry after preflight.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host ((\"Windows catalog note:    {0}\") -f $helper.companion_paths.windows_full_use_attached_html_catalog_quickstart_note)",
        "purpose": "The launcher companion helper prints the Windows full-use attached-html catalog quickstart note beside the replay companion notes.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Write-Host ((\"Replay-route note:       {0}\") -f $helper.companion_paths.replay_route_shortcut_bridge_note)",
        "purpose": "The launcher companion helper prints the replay-route bridge note beside the other companion notes.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Use the strict bundle commands when both sidecars and referenced local assets must be complete before a manifest print or localhost launch is trusted.",
        "purpose": "The launcher companion helper explains when to prefer the strict bundle commands.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Use proof_surface_check and proof_entrypoint when the current attached-page replay is already pinned to the known three-page compatibility bundle and you want the proof-only checker and helper pair reprinted directly from the launcher-companion surface before widening back into the broader replay helper chain.",
        "purpose": "The launcher companion helper explains when to bridge from launcher preflight into the pinned proof route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Use windows_replay_quickstart after launcher-side sidecar, asset, or proof preflight when the next honest step is to re-enter the replay-attached Windows ladder without reopening the broader route map first.",
        "purpose": "The launcher companion helper explains when to re-enter the replay-attached Windows quickstart directly from preflight.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Use replay_route_shortcut when the preflight already narrowed the problem and you want the shorter replay-route companion visible before the route drops into the attached-page shortcut, replay shortcuts, contextual flow, bundle-first reuse, or the safe-route map.",
        "purpose": "The launcher companion helper explains when to re-enter the shorter replay-route companion directly from preflight.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "The lower-level Python launcher ladder shown here now preserves the same preferred-first-page override, so cross-platform reruns can keep the pinned bundle order without hand-editing each command.",
        "purpose": "The launcher companion helper keeps the cross-platform preferred-first-page support visible after the Python ladder gains parity with the wrapper.",
    },
    {
        "path": "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "snippet": "(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet \"Write-Host 'Pinned bundle proof follow-up:'\"",
        "purpose": "The Windows checker keeps guarding the proof follow-up section header on the helper surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "snippet": "(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\\\"  Surface check:      {0}\\\") -f $helper.helper_commands.proof_surface_check)'",
        "purpose": "The Windows checker keeps guarding the proof surface-check output on the helper surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "snippet": "(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\\\"  Proof entrypoint:   {0}\\\") -f $helper.helper_commands.proof_entrypoint)'",
        "purpose": "The Windows checker keeps guarding the proof entrypoint output on the helper surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "snippet": "(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\\\"Bundle proof note:       {0}\\\") -f $helper.companion_paths.attached_html_target_bundle_proof_entrypoint_note)'",
        "purpose": "The Windows checker keeps guarding the pinned bundle proof note output on the helper surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "snippet": "(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Use proof_surface_check and proof_entrypoint when the current attached-page replay is already pinned to the known three-page compatibility bundle",
        "purpose": "The Windows checker keeps guarding the proof follow-up guidance on the helper surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "snippet": "(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet \"windows_replay_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $wrapperArguments\"",
        "purpose": "The Windows checker keeps guarding the replay quickstart helper wiring on the helper surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "snippet": "(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet \"replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $wrapperArguments\"",
        "purpose": "The Windows checker keeps guarding the replay-route helper wiring on the helper surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "snippet": "(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet \"Write-Host 'Replay re-entry helpers:'\"",
        "purpose": "The Windows checker keeps guarding the replay re-entry section header on the helper surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "snippet": "(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\\\"  Windows replay quick: {0}\\\") -f $helper.helper_commands.windows_replay_quickstart)'",
        "purpose": "The Windows checker keeps guarding the replay quickstart output on the helper surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "snippet": "(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Write-Host ((\\\"  Replay-route helper: {0}\\\") -f $helper.helper_commands.replay_route_shortcut)'",
        "purpose": "The Windows checker keeps guarding the replay-route output on the helper surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "snippet": "(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Use windows_replay_quickstart after launcher-side sidecar, asset, or proof preflight",
        "purpose": "The Windows checker keeps guarding the replay quickstart guidance on the helper surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "snippet": "(New-ValidationContentExpectation -Path 'scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1' -Snippet 'Use replay_route_shortcut when the preflight already narrowed the problem",
        "purpose": "The Windows checker keeps guarding the replay-route guidance on the helper surface.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_catalog_quickstart_validation_surface.ps1",
        "purpose": "The Windows full-use attached-html catalog quickstart note keeps its dedicated surface checker visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "purpose": "The Windows full-use attached-html catalog quickstart note keeps its dedicated helper visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -RequireCompleteAssets -PrintManifest",
        "purpose": "The Windows full-use attached-html catalog quickstart note keeps the strict asset-gated manifest step visible before replay.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1",
        "purpose": "The replay-route bridge note keeps its dedicated fail-fast checker visible.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "purpose": "The replay-route bridge note keeps its compact replay helper visible.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1 -RepoRoot '<repo-root>' -SummaryPath '<saved-summary-path>' -InputPath '<bundle-html-or-folder>'",
        "purpose": "The replay-route bridge note keeps the preserved-context replay helper visible for non-default repo roots, saved summaries, and pinned bundle inputs.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1",
        "snippet": "(New-ValidationContentExpectation -Path \"docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md\" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\start_attached_pages_catalog.ps1 -InputPath ''<attached-html-root>'' -AuditSidecars'",
        "purpose": "The Windows full-use route checker keeps guarding the wrapper-backed sidecar audit on the broader route note.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1",
        "snippet": "(New-ValidationContentExpectation -Path \"docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md\" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\show_google_issue3_windows_replay_attached_html_quickstart.ps1'",
        "purpose": "The Windows full-use route checker keeps guarding the replay-attached quickstart handoff on the broader route note.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1",
        "snippet": "(New-ValidationContentExpectation -Path \"docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md\" -Snippet 'powershell -ExecutionPolicy Bypass -File .\\\\scripts\\\\windows\\\\show_google_issue3_attached_html_target_bundle_suite_surface.ps1 -InputPath ''<bundle-html-or-folder>'''",
        "purpose": "The Windows full-use route checker keeps guarding the compact bundle-suite handoff on the broader route note.",
    },
    {
        "path": "tmp-browser-smoke/attached-pages/README.md",
        "snippet": "scripts/windows/start_attached_pages_catalog.ps1",
        "purpose": "The attached-pages README keeps the Windows wrapper visible.",
    },
    {
        "path": "tmp-browser-smoke/attached-pages/README.md",
        "snippet": "--audit-sidecars",
        "purpose": "The attached-pages README keeps the sidecar-audit mode visible.",
    },
    {
        "path": "tmp-browser-smoke/attached-pages/README.md",
        "snippet": "--require-complete-sidecars \\
  --require-complete-assets",
        "purpose": "The attached-pages README keeps the strict sidecar-plus-asset mode visible.",
    },
    {
        "path": "scripts/windows/start_attached_pages_catalog.ps1",
        "snippet": "$launcherArgs += \"--audit-sidecars\"",
        "purpose": "The Windows wrapper still forwards the sidecar-audit mode.",
    },
    {
        "path": "scripts/windows/start_attached_pages_catalog.ps1",
        "snippet": "$launcherArgs += \"--require-complete-sidecars\"",
        "purpose": "The Windows wrapper still forwards the strict sidecar gate.",
    },
    {
        "path": "scripts/windows/start_attached_pages_catalog.ps1",
        "snippet": "$launcherArgs += \"--require-complete-assets\"",
        "purpose": "The Windows wrapper still forwards the strict asset gate.",
    },
    {
        "path": "scripts/windows/start_attached_pages_catalog.ps1",
        "snippet": "[string]$PreferredInitialPage,",
        "purpose": "The Windows wrapper still accepts the preferred-first-page override that the launcher companion promises across its surfaced ladder.",
    },
    {
        "path": "scripts/windows/start_attached_pages_catalog.ps1",
        "snippet": "$orderedInputs = Resolve-OrderedAttachedHtmlInputs -RawInputPath $InputPath -PreferredPage $PreferredInitialPage",
        "purpose": "The Windows wrapper still reorders explicit attached-page inputs through the preferred-first-page helper before printing the manifest or starting localhost replay.",
    },
    {
        "path": "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py",
        "snippet": "--preferred-initial-page",
        "purpose": "The cross-platform attached-pages launcher still accepts the preferred-first-page override that the launcher companion promises for Linux reruns.",
    },
    {
        "path": "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py",
        "snippet": "preferred_initial_page=args.preferred_initial_page,",
        "purpose": "The cross-platform attached-pages launcher still threads the preferred-first-page override into fixture selection before manifest generation and localhost startup.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_launcher_companion_audit(repo_root: Path) -> dict[str, object]:
    results: list[dict[str, object]] = []
    missing_count = 0

    for expectation in EXPECTATIONS:
        full_path = repo_root / expectation["path"]
        if not full_path.is_file():
            exists = False
        else:
            exists = expectation["snippet"] in full_path.read_text(encoding="utf-8", errors="ignore")

        if not exists:
            missing_count += 1

        results.append(
            {
                "path": expectation["path"],
                "purpose": expectation["purpose"],
                "exists": exists,
                "snippet": expectation["snippet"],
            }
        )

    return {
        "repo_root": str(repo_root),
        "expectation_count": len(results),
        "missing_count": missing_count,
        "results": results,
    }


def render_text_report(audit: dict[str, object]) -> str:
    lines = [
        "Google Issue #3 Attached-Pages Launcher Companion Audit",
        "",
        f"Repo root: {audit['repo_root']}",
        f"Expectations checked: {audit['expectation_count']}",
        f"Missing expectations: {audit['missing_count']}",
        "",
    ]

    for result in audit["results"]:
        status = "PASS" if result["exists"] else "FAIL"
        lines.append(f"[{status}] {result['path']}")
        lines.append(f"  {result['purpose']}")

    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Audit the issue #3 attached-pages launcher companion surface for Linux-side drift checks."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_launcher_companion_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())