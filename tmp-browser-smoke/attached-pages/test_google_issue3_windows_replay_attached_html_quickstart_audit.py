import contextlib
import io
import json
import tempfile
import unittest
from collections import defaultdict
from pathlib import Path

import google_issue3_windows_replay_attached_html_quickstart_audit as helper


def build_contract_map() -> dict[str, str]:
    grouped: dict[str, list[str]] = defaultdict(list)
    for expectation in helper.EXPECTATIONS:
        grouped[expectation["path"]].append(expectation["snippet"])
    return {path: "\n\n".join(snippets) + "\n" for path, snippets in grouped.items()}


DRIFT_CASES = (
    (
        "replay_surface_check_note",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "",
    ),
    (
        "validation_router_quickstart_note",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1",
        "",
    ),
    (
        "validation_router_quickstart_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $sharedArguments",
        "",
    ),
    (
        "validation_router_quickstart_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Validation-router quick:  {0}") -f $helper.commands.validation_router_attached_html_quickstart)',
        "",
    ),
    (
        "windows_full_use_route_note",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_route.ps1",
        "",
    ),
    (
        "windows_full_use_route_surface_check_note",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1",
        "",
    ),
    (
        "validation_bridge_note",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1",
        "",
    ),
    (
        "windows_catalog_quickstart_note",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "",
    ),
    (
        "windows_full_use_route_surface_check_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "windows_full_use_attached_html_route_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "",
    ),
    (
        "windows_full_use_route_surface_check_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Route surface check:     {0}") -f $helper.commands.windows_full_use_attached_html_route_surface_check)',
        "",
    ),
    (
        "replay_surface_check_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "windows_replay_attached_html_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "",
    ),
    (
        "windows_full_use_route_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "windows_full_use_attached_html_route = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_route.ps1' -Arguments $sharedArguments",
        "",
    ),
    (
        "windows_full_use_route_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Windows full route:      {0}") -f $helper.commands.windows_full_use_attached_html_route)',
        "",
    ),
    (
        "validation_bridge_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "windows_full_use_validation_router_attached_html_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $browserAwareSharedArguments",
        "",
    ),
    (
        "validation_bridge_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Validation bridge:        {0}") -f $helper.commands.windows_full_use_validation_router_attached_html_bridge)',
        "",
    ),
    (
        "google_surface_check_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_attached_html_validation_surface.ps1' -RepoRootOverride $RepoRoot",
        "",
    ),
    (
        "google_surface_check_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Google surface check:     {0}") -f $helper.commands.google_attached_html_surface_check)',
        "",
    ),
    (
        "google_attached_flow_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "google_attached_html_validation_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot",
        "",
    ),
    (
        "google_attached_flow_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Google attached flow:     {0}") -f $helper.commands.google_attached_html_validation_flow)',
        "",
    ),
    (
        "google_attached_flow_guidance",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "Use google_attached_html_validation_flow when the current attached inputs are already Google-shaped and you want the dedicated attached-page asset-closure and preferred-initial-page helper visible after the dedicated Google-shaped attached-page surface check and before the route narrows back into the suite-router sidecar or the shorter attached-page shortcut.",
        "drifted note",
    ),
    (
        "google_issue_bridge_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $sharedArguments",
        "",
    ),
    (
        "google_issue_bridge_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Google issue bridge:      {0}") -f $helper.commands.google_attached_html_entrypoint)',
        "",
    ),
    (
        "google_issue_bridge_guidance",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "Use google_attached_html_entrypoint when the replay already needs the issue-specific Google attached-html bridge kept visible after the dedicated Google attached-page flow and before the compact bundle suite or the narrower shortcuts take over.",
        "drifted note",
    ),
    (
        "google_surface_check_guidance",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "Use google_attached_html_surface_check when branch state may have moved and the replay should fail fast on the dedicated Google-shaped attached-page lane before reopening the narrower Google helper from this same replay ladder.",
        "drifted note",
    ),
    (
        "bundle_proof_note_reference",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`",
        "",
    ),
    (
        "bundle_proof_surface_check_note",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1",
        "",
    ),
    (
        "bundle_proof_entrypoint_note",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "",
    ),
    (
        "bundle_proof_surface_check_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "attached_bundle_proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "",
    ),
    (
        "bundle_proof_entrypoint_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "attached_bundle_proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $sharedArguments",
        "",
    ),
    (
        "bundle_proof_surface_check_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Bundle proof check:       {0}") -f $helper.commands.attached_bundle_proof_surface_check)',
        "",
    ),
    (
        "bundle_proof_entry_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Bundle proof entry:      {0}") -f $helper.commands.attached_bundle_proof_entrypoint)',
        "",
    ),
    (
        "replay_route_bundle_first_bridge_note_reference",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "docs/ISSUE3_REPLAY_ROUTE_BUNDLE_FIRST_BRIDGE.md",
        "",
    ),
    (
        "replay_route_shortcut_checker_bundle_proof_note",
        "scripts/windows/check_google_issue3_replay_route_shortcut_validation_surface.ps1",
        "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md",
        "",
    ),
    (
        "replay_route_shortcut_checker_replay_to_windows_bridge",
        "scripts/windows/check_google_issue3_replay_route_shortcut_validation_surface.ps1",
        "show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1",
        "",
    ),
    (
        "launcher_companion_surface_check_note",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "",
    ),
    (
        "launcher_companion_helper_note",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'",
        "",
    ),
    (
        "launcher_companion_context_note",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'",
        "",
    ),
    (
        "launcher_companion_surface_check_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "attached_pages_launcher_companion_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "",
    ),
    (
        "launcher_companion_helper_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments",
        "",
    ),
    (
        "launcher_companion_surface_check_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Launcher surface check:   {0}") -f $helper.commands.attached_pages_launcher_companion_surface_check)',
        "",
    ),
    (
        "launcher_companion_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Launcher companion:       {0}") -f $helper.commands.attached_pages_launcher_companion)',
        "",
    ),
    (
        "launcher_surface_check_output",
        "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        'Write-Host (("  Surface check:      {0}") -f $helper.helper_commands.proof_surface_check)',
        "",
    ),
    (
        "launcher_proof_entry_output",
        "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        'Write-Host (("  Proof entrypoint:   {0}") -f $helper.helper_commands.proof_entrypoint)',
        "",
    ),
    (
        "launcher_proof_surface_guidance",
        "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "Use proof_surface_check and proof_entrypoint when the current attached-page replay is already pinned to the known three-page compatibility bundle and you want the proof-only checker and helper pair reprinted directly from the launcher-companion surface before widening back into the broader replay helper chain.",
        "drifted note",
    ),
    (
        "launcher_windows_replay_wiring",
        "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "windows_replay_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $wrapperArguments",
        "",
    ),
    (
        "launcher_replay_route_guidance",
        "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "Use replay_route_shortcut when the preflight already narrowed the problem and you want the shorter replay-route companion visible before the route drops into the attached-page shortcut, replay shortcuts, contextual flow, bundle-first reuse, or the safe-route map.",
        "drifted note",
    ),
    (
        "windows_catalog_quickstart_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "windows_full_use_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments",
        "",
    ),
    (
        "windows_catalog_quickstart_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Catalog quickstart:       {0}") -f $helper.commands.windows_full_use_attached_html_catalog_quickstart)',
        "",
    ),
    (
        "suite_catalog_guide_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Suite-catalog guide:      {0}") -f $helper.commands.suite_catalog_entrypoints)',
        "",
    ),
    (
        "broader_attached_flow_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Broader attached flow:    {0}") -f $helper.commands.attached_html_validation_flow)',
        "",
    ),
    (
        "suite_router_sidecar_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Suite-router sidecar:     {0}") -f $helper.commands.suite_router_attached_html_quickstart)',
        "",
    ),
    (
        "top_level_shortcut_bridge_note_reference",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "- `docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md`",
        "",
    ),
    (
        "top_level_shortcut_bridge_helper_note",
        "docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_top_level_shortcut_first_entrypoint.ps1",
        "",
    ),
    (
        "top_level_shortcut_bridge_replay_route_note",
        "docs/ISSUE3_TOP_LEVEL_SHORTCUT_BRIDGE.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "",
    ),
    (
        "top_level_shortcut_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "top_level_shortcut_first = Format-HelperCommand -ScriptName 'show_google_issue3_top_level_shortcut_first_entrypoint.ps1' -Arguments $sharedArguments",
        "",
    ),
    (
        "top_level_shortcut_guidance",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "Use top_level_shortcut_first after the suite-router sidecar or the broader top-level attached-page bridge when you want the newer top-level shortcut bridge reprinted before the route collapses into the shorter attached-page shortcut surface.",
        "drifted note",
    ),
    (
        "top_level_shortcut_windows_replay_wiring",
        "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1",
        "windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $bundleArguments",
        "",
    ),
    (
        "top_level_shortcut_windows_replay_output",
        "scripts/windows/show_google_issue3_top_level_shortcut_first_entrypoint.ps1",
        'Write-Host (("  Windows replay quick:   {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)',
        "",
    ),
    (
        "attached_bundle_suite_surface_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedArguments",
        "",
    ),
    (
        "attached_bundle_suite_surface_guidance",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "Use attached_bundle_suite_surface when the replay is already close to the known three-page compatibility bundle but you still want the compact suite-level surface printed before the narrower bundle-first helper or the delegated bundle flow takes over.",
        "drifted note",
    ),
    (
        "attached_bundle_suite_surface_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Bundle suite surface:     {0}") -f $helper.commands.attached_bundle_suite_surface)',
        "",
    ),
    (
        "attached_html_change_area_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Attached HTML:          {0}") -f $helper.top_level_commands.attached_html_change_area)',
        "",
    ),
    (
        "google_attached_html_change_area_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Google attached HTML:   {0}") -f $helper.top_level_commands.google_attached_html_change_area)',
        "",
    ),
    (
        "attached_bundle_change_area_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Attached bundle:        {0}") -f $helper.top_level_commands.attached_bundle_change_area)',
        "",
    ),
    (
        "suite_catalog_guide_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $sharedArguments",
        "",
    ),
    (
        "suite_catalog_guidance",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "Use suite_catalog_entrypoints when you want the wider suite-catalog route map reprinted before the replay falls back into the narrower attached-page bridge.",
        "drifted note",
    ),
    (
        "suite_router_sidecar_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "suite_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_attached_html_quickstart.ps1' -Arguments $sharedArguments",
        "",
    ),
    (
        "suite_router_sidecar_guidance",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "Keep suite_router_attached_html_quickstart nearby as the sidecar helper when the route needs to widen back toward the suite-router surface instead of narrowing directly into the shorter attached-page bridge or the attached-page shortcut.",
        "drifted note",
    ),
    (
        "replay_route_shortcut_wiring",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $sharedArguments",
        "",
    ),
    (
        "replay_route_shortcut_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Replay-route shortcut:    {0}") -f $helper.commands.replay_route_shortcut)',
        "",
    ),
    (
        "replay_surface_check_output",
        "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        'Write-Host (("  Replay surface check:    {0}") -f $helper.commands.windows_replay_attached_html_surface_check)',
        "",
    ),
    (
        "replay_route_shortcut_surface_check_note",
        "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1",
        "",
    ),
    (
        "replay_route_shortcut_helper_note",
        "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "",
    ),
    (
        "replay_route_shortcut_replay_to_windows_note",
        "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1",
        "",
    ),
    (
        "replay_windows_bridge_surface_check_wiring",
        "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1",
        "windows_replay_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "",
    ),
    (
        "replay_to_windows_wiring",
        "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "replay_shortcuts_windows_replay_attached_html_bridge = $replayShortcutsWindowsReplayAttachedHtmlBridgeCommand",
        "",
    ),
    (
        "replay_to_windows_guidance",
        "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "Use replay_shortcuts_windows_replay_attached_html_bridge when the replay-route shortcut still needs the replay-side surface check, the Windows replay attached-page quickstart, and the broader Windows-first bridge kept visible before the route collapses back to the shorter attached-page helper chain.",
        "drifted note",
    ),
    (
        "replay_windows_bridge_check_output",
        "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1",
        'Write-Host (("  Replay quickstart check:  {0}") -f $bridge.commands.windows_replay_surface_check)',
        "",
    ),
    (
        "replay_windows_bridge_quickstart_output",
        "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1",
        'Write-Host (("  Windows replay quick:     {0}") -f $bridge.commands.windows_replay_quickstart)',
        "",
    ),
    (
        "replay_windows_bridge_default_handoff_guidance",
        "scripts/windows/show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1",
        "Use windows_replay_quickstart as the default next helper whenever no explicit bundle inputs, saved summary, or non-default repo root need to take precedence first.",
        "drifted note",
    ),
    (
        "replay_to_windows_numbered_output",
        "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        'Write-Host (("  8. Replay-to-Windows: {0}") -f $entrypoint.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)',
        "",
    ),
    (
        "replay_to_windows_numbered_bridge_check_output",
        "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        'Write-Host (("  9. Replay quick check:{0}") -f (\' \' + $entrypoint.helper_commands.windows_replay_attached_html_surface_check))',
        "",
    ),
    (
        "replay_to_windows_numbered_quickstart_output",
        "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        'Write-Host ((" 10. Windows replay:    {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)',
        "",
    ),
    (
        "replay_to_windows_bridge_check_companion_output",
        "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        'Write-Host (("  Replay bridge check:  {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_surface_check)',
        "",
    ),
    (
        "replay_to_windows_quickstart_companion_output",
        "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        'Write-Host (("  Windows replay quick: {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)',
        "",
    ),
    (
        "google_entrypoint_note_command",
        "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1",
        "",
    ),
    (
        "google_entrypoint_broader_surface_note",
        "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1",
        "",
    ),
    (
        "google_entrypoint_issue_specific_surface_note",
        "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1",
        "",
    ),
    (
        "google_entrypoint_sidecar_output",
        "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        'Write-Host (("  6. Sidecar audit:        {0}") -f $entrypoint.helper_commands.google_attached_html_sidecar_audit)',
        "",
    ),
    (
        "google_entrypoint_broader_surface_output",
        "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        'Write-Host (("  7. Broader surface:      {0}") -f $entrypoint.helper_commands.broader_google_attached_html_surface_check)',
        "",
    ),
    (
        "google_entrypoint_asset_closure_output",
        "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        'Write-Host (("  8. Asset closure:        {0}") -f $entrypoint.helper_commands.google_attached_html_asset_closure)',
        "",
    ),
    (
        "google_entrypoint_issue_specific_output",
        "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        'Write-Host (("  9. Issue-specific check: {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)',
        "",
    ),
    (
        "google_entrypoint_companion_flow_guidance",
        "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "Use google_attached_html_validation_flow when the broader Google-style attached-page flow helper still needs to stay visible after the sidecar audit, broader surface check, asset audit, and dedicated entrypoint surface check and before the route narrows into the shorter issue #3 shortcut-first, replay-shortcut, context-preserving, or bundle-aware branches.",
        "drifted note",
    ),
    (
        "google_entrypoint_companion_flow_output",
        "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        'Write-Host ((" 10. Google attached flow: {0}") -f $entrypoint.helper_commands.google_attached_html_validation_flow)',
        "",
    ),
)


class GoogleIssue3WindowsReplayAttachedHtmlQuickstartAuditTests(unittest.TestCase):
    maxDiff = None

    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    def write_contract_files(self, overrides: dict[str, str] | None = None) -> None:
        contract_map = build_contract_map()
        if overrides:
            contract_map.update(overrides)
        for rel_path, content in contract_map.items():
            path = self.root / rel_path
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")

    def test_build_audit_passes_when_contract_is_present(self) -> None:
        self.write_contract_files()
        audit = helper.build_replay_attached_quickstart_audit(self.root)
        self.assertEqual(0, audit["missing_count"])
        self.assertTrue(all(result["exists"] for result in audit["results"]))

    def test_build_audit_reports_selected_contract_drift_cases(self) -> None:
        contract_map = build_contract_map()

        for name, path, snippet, replacement in DRIFT_CASES:
            with self.subTest(name=name):
                self.write_contract_files(
                    {path: contract_map[path].replace(snippet, replacement)}
                )
                audit = helper.build_replay_attached_quickstart_audit(self.root)
                self.assertGreater(audit["missing_count"], 0)
                failing = [
                    result
                    for result in audit["results"]
                    if result["path"] == path and result["snippet"] == snippet
                ]
                self.assertEqual(1, len(failing))
                self.assertFalse(failing[0]["exists"])

    def test_build_audit_groups_multiple_missing_expectations_by_path(self) -> None:
        self.write_contract_files(
            {"docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md": "# drifted\n"}
        )

        audit = helper.build_replay_attached_quickstart_audit(self.root)

        summary = {entry["path"]: entry for entry in audit["missing_paths"]}
        self.assertIn("docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md", summary)
        self.assertEqual(1, audit["missing_path_count"])
        self.assertGreater(audit["missing_count"], 1)
        self.assertGreater(
            summary["docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md"][
                "missing_expectation_count"
            ],
            1,
        )
        self.assertIn(
            "replay-side surface checker visible",
            summary["docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md"][
                "first_missing_purpose"
            ],
        )
        self.assertIn(
            "check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
            summary["docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md"][
                "first_missing_snippet"
            ],
        )

    def test_main_outputs_json_and_nonzero_when_contract_drifts(self) -> None:
        self.write_contract_files(
            {"docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md": "# drifted\n"}
        )

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.main(["--repo-root", str(self.root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(output.getvalue())
        self.assertGreater(payload["missing_count"], 1)
        self.assertEqual(1, payload["missing_path_count"])
        self.assertEqual(
            "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
            payload["missing_paths"][0]["path"],
        )
        self.assertGreater(
            payload["missing_paths"][0]["missing_expectation_count"],
            1,
        )
        self.assertIn(
            "replay-side surface checker visible",
            payload["missing_paths"][0]["first_missing_purpose"],
        )
        self.assertIn(
            "check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
            payload["missing_paths"][0]["first_missing_snippet"],
        )

    def test_main_reports_missing_failures_in_text_output(self) -> None:
        self.write_contract_files(
            {"docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md": "# drifted\n"}
        )

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.main(["--repo-root", str(self.root)])

        self.assertEqual(1, exit_code)
        text = output.getvalue()
        self.assertIn("Missing paths:", text)
        self.assertIn(
            "- docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md (",
            text,
        )
        self.assertIn(
            "First snippet: powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
            text,
        )

    def test_main_reports_missing_repo_root_in_json(self) -> None:
        missing_root = self.root / "missing-repo-root"

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.main(["--repo-root", str(missing_root), "--json"])

        self.assertEqual(1, exit_code)
        payload = json.loads(output.getvalue())
        self.assertEqual("repo_root_not_found", payload["error_type"])
        self.assertEqual(str(missing_root), payload["repo_root"])
        self.assertIsNone(payload["missing_count"])
        self.assertIn("repo root does not exist:", payload["error"])

    def test_main_reports_missing_repo_root_in_text(self) -> None:
        missing_root = self.root / "missing-repo-root"

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = helper.main(["--repo-root", str(missing_root)])

        self.assertEqual(1, exit_code)
        text = output.getvalue()
        self.assertIn(
            "Google Issue #3 Windows Replay Attached HTML Quickstart Audit",
            text,
        )
        self.assertIn(f"Repo root: {missing_root}", text)
        self.assertIn("Error: repo root does not exist:", text)


if __name__ == "__main__":
    unittest.main()
