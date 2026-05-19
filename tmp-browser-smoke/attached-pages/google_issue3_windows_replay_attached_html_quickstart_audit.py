import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "purpose": "The replay-attached quickstart keeps the replay-side surface checker visible before the narrower attached-page ladder starts.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1",
        "purpose": "The replay-attached quickstart keeps the broader Windows route-level surface checker visible before the ladder narrows.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "- `docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md`",
        "purpose": "The replay-attached quickstart keeps the pinned bundle proof companion note visible.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "purpose": "The replay-attached quickstart keeps the launcher companion surface checker visible before the sidecar-first route is reused.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -InputPath '<attached-html-root>'",
        "purpose": "The replay-attached quickstart keeps the launcher companion helper visible with an attached-page input path.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'",
        "purpose": "The replay-attached quickstart keeps the launcher companion helper visible when repo-root-preserving replay context is already pinned.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1",
        "purpose": "The replay-attached quickstart keeps the issue-specific Google attached-html entrypoint visible before the bundle suite and narrower shortcuts take over.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1",
        "purpose": "The replay-attached quickstart keeps the proof-entrypoint surface checker visible before the proof-only follow-up is trusted.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "purpose": "The replay-attached quickstart keeps the proof-entrypoint helper visible beside the compact bundle route.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "purpose": "The replay-attached quickstart keeps the narrower replay-route shortcut bridge visible before the helper chain collapses into shorter replay follow-up.",
    },
    {
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\start_attached_pages_catalog.ps1 -InputPath '<attached-html-root>' -GoogleStyle -AuditSidecars",
        "purpose": "The narrower Google entrypoint note keeps the wrapper-backed sidecar audit visible before the deeper Google-only checks.",
    },
    {
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1",
        "purpose": "The narrower Google entrypoint note keeps the broader Google attached-html surface checker visible before the route narrows.",
    },
    {
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle",
        "purpose": "The narrower Google entrypoint note keeps the deeper asset-closure audit visible before shortcut follow-up begins.",
    },
    {
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1",
        "purpose": "The narrower Google entrypoint note keeps the issue-specific surface checker visible before the compact helper chain is trusted.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1",
        "purpose": "The replay-route shortcut bridge note keeps its own fail-fast checker visible before the compact replay route is trusted.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "purpose": "The replay-route shortcut bridge note keeps the compact replay-route helper visible before the replay narrows into the shorter bridge-only follow-up.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1",
        "purpose": "The replay-route shortcut bridge note keeps the replay-shortcuts-to-Windows-replay bridge visible before the route narrows again.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "windows_replay_attached_html_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "purpose": "The replay-attached helper keeps the replay-side surface checker wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "windows_full_use_attached_html_route_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "purpose": "The replay-attached helper keeps the broader Windows route-level surface checker wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "suite_catalog_entrypoints = Format-HelperCommand -ScriptName 'show_google_issue3_suite_catalog_entrypoints.ps1' -Arguments $sharedArguments",
        "purpose": "The replay-attached helper keeps the suite-catalog helper wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $sharedArguments",
        "purpose": "The replay-attached helper keeps the issue-specific Google attached-html entrypoint wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $sharedArguments",
        "purpose": "The replay-attached helper keeps the compact bundle-suite surface wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "attached_bundle_proof_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "purpose": "The replay-attached helper keeps the proof-entrypoint surface checker wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "attached_bundle_proof_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1' -Arguments $sharedArguments",
        "purpose": "The replay-attached helper keeps the proof-entrypoint helper wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "attached_pages_launcher_companion_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "purpose": "The replay-attached helper keeps the launcher companion surface checker wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments",
        "purpose": "The replay-attached helper keeps the launcher companion helper wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $sharedArguments",
        "purpose": "The replay-attached helper keeps the replay-route shortcut bridge wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": 'Write-Host (("  Replay surface check:    {0}") -f $helper.commands.windows_replay_attached_html_surface_check)',
        "purpose": "The replay-attached helper prints the replay-side surface checker on the surfaced route guard.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": 'Write-Host (("  Route surface check:     {0}") -f $helper.commands.windows_full_use_attached_html_route_surface_check)',
        "purpose": "The replay-attached helper prints the broader Windows route-level surface checker on the surfaced route guard.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": 'Write-Host (("  Suite-catalog guide:      {0}") -f $helper.commands.suite_catalog_entrypoints)',
        "purpose": "The replay-attached helper prints the suite-catalog helper on the surfaced ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": 'Write-Host (("  Google issue bridge:      {0}") -f $helper.commands.google_attached_html_entrypoint)',
        "purpose": "The replay-attached helper prints the issue-specific Google attached-html entrypoint in its attached-page ladder output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": 'Write-Host (("  Bundle suite surface:     {0}") -f $helper.commands.attached_bundle_suite_surface)',
        "purpose": "The replay-attached helper prints the compact bundle-suite surface before the route narrows into bundle-first follow-up.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": 'Write-Host (("  Bundle proof check:       {0}") -f $helper.commands.attached_bundle_proof_surface_check)',
        "purpose": "The replay-attached helper prints the proof-entrypoint surface checker in its attached-page ladder output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": 'Write-Host (("  Bundle proof entry:      {0}") -f $helper.commands.attached_bundle_proof_entrypoint)',
        "purpose": "The replay-attached helper prints the proof-entrypoint helper in its attached-page ladder output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": 'Write-Host (("  Launcher surface check:   {0}") -f $helper.commands.attached_pages_launcher_companion_surface_check)',
        "purpose": "The replay-attached helper prints the launcher companion surface checker in its attached-page ladder output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": 'Write-Host (("  Launcher companion:       {0}") -f $helper.commands.attached_pages_launcher_companion)',
        "purpose": "The replay-attached helper prints the launcher companion helper in its attached-page ladder output.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": 'Write-Host (("  Replay-route shortcut:    {0}") -f $helper.commands.replay_route_shortcut)',
        "purpose": "The replay-attached helper prints the replay-route shortcut bridge before the route narrows into replay-only follow-up.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "Use suite_catalog_entrypoints when you want the wider suite-catalog route map reprinted before the replay falls back into the narrower attached-page bridge.",
        "purpose": "The replay-attached helper notes preserve when to widen back into the suite-catalog route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "Use google_attached_html_entrypoint when the replay already needs the issue-specific Google attached-html bridge kept visible after the dedicated Google attached-page flow and before the compact bundle suite or the narrower shortcuts take over.",
        "purpose": "The replay-attached helper notes preserve when to prefer the issue-specific Google attached-html bridge before bundle-only or shortcut follow-up.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "Use attached_bundle_suite_surface when the replay is already close to the known three-page compatibility bundle but you still want the compact suite-level surface printed before the narrower bundle-first helper or the delegated bundle flow takes over.",
        "purpose": "The replay-attached helper notes preserve when to prefer the compact bundle-suite surface before the narrower bundle-first branch.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "Use attached_bundle_proof_entrypoint when the replay is already pinned to the known three-page compatibility bundle and you want the proof-only follow-up helper kept visible beside the proof surface checker before the route widens again.",
        "purpose": "The replay-attached helper notes preserve when to prefer the proof-entrypoint helper beside the pinned bundle route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "snippet": "Use replay_route_shortcut after the top-level shortcut bridge, the attached-page shortcut, or replay_shortcuts when you want the narrower replay-route companion surfaced before the route drops into the attached-page shortcut, replay shortcuts, contextual flow, bundle-first reuse, or the safe-route map.",
        "purpose": "The replay-attached helper notes preserve when to reopen the narrower replay-route shortcut bridge from the attached-page ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "google_attached_html_sidecar_audit = $googleAttachedHtmlSidecarAuditCommand",
        "purpose": "The narrower Google entrypoint helper keeps the wrapper-backed sidecar audit wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "broader_google_attached_html_surface_check = Format-HelperCommand -ScriptName 'check_google_attached_html_validation_surface.ps1' -Arguments $googleAttachedHtmlSurfaceCheckArguments",
        "purpose": "The narrower Google entrypoint helper keeps the broader Google attached-html surface checker wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "google_attached_html_asset_closure = Format-HelperCommand -ScriptName 'check_attached_html_local_asset_closure.ps1' -Arguments $googleAttachedHtmlAssetAuditArguments -Switches @('GoogleStyle')",
        "purpose": "The narrower Google entrypoint helper keeps the deeper asset-closure audit wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "google_attached_html_surface_check = Format-HelperCommandWithRepoRootEnv -ScriptName 'check_google_issue3_google_attached_html_entrypoint_validation_surface.ps1' -RepoRootOverride $RepoRoot",
        "purpose": "The narrower Google entrypoint helper keeps the issue-specific surface checker wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "google_attached_html_validation_flow = Format-HelperCommand -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $googleAttachedHtmlFlowArguments",
        "purpose": "The narrower Google entrypoint helper keeps the broader Google attached-html flow helper wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "attached_bundle_suite_surface = Format-HelperCommand -ScriptName 'show_google_issue3_attached_html_target_bundle_suite_surface.ps1' -Arguments $bundleArguments",
        "purpose": "The narrower Google entrypoint helper keeps the compact bundle-suite helper wired into its command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host (("  6. Sidecar audit:        {0}") -f $entrypoint.helper_commands.google_attached_html_sidecar_audit)',
        "purpose": "The narrower Google entrypoint helper prints the wrapper-backed sidecar audit on its surfaced ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host (("  7. Broader surface:      {0}") -f $entrypoint.helper_commands.broader_google_attached_html_surface_check)',
        "purpose": "The narrower Google entrypoint helper prints the broader Google attached-html surface checker on its surfaced ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host (("  8. Asset closure:        {0}") -f $entrypoint.helper_commands.google_attached_html_asset_closure)',
        "purpose": "The narrower Google entrypoint helper prints the deeper asset-closure audit on its surfaced ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host (("  9. Issue-specific check: {0}") -f $entrypoint.helper_commands.google_attached_html_surface_check)',
        "purpose": "The narrower Google entrypoint helper prints the issue-specific surface checker on its surfaced ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host (("  Sidecar audit:         {0}") -f $entrypoint.helper_commands.google_attached_html_sidecar_audit)',
        "purpose": "The narrower Google entrypoint helper prints the wrapper-backed sidecar audit in its companion helper section.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host (("  Broader surface check: {0}") -f $entrypoint.helper_commands.broader_google_attached_html_surface_check)',
        "purpose": "The narrower Google entrypoint helper prints the broader Google attached-html surface checker in its companion helper section.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": 'Write-Host (("  Asset closure audit:   {0}") -f $entrypoint.helper_commands.google_attached_html_asset_closure)',
        "purpose": "The narrower Google entrypoint helper prints the deeper asset-closure audit in its companion helper section.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "Use google_attached_html_sidecar_audit when the current saved export may be missing its whole sibling `_files` bundle and you want that simpler failure mode ruled in or out before the broader surface check or the deeper asset audit.",
        "purpose": "The narrower Google entrypoint helper notes preserve when to rerun the wrapper-backed sidecar audit first.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "Use broader_google_attached_html_surface_check when the replay is already narrowed to the Google-shaped attached-page route and you want the wider fail-fast helper surface reprinted after the sidecar audit but before the deeper asset audit or the narrower issue-specific checker.",
        "purpose": "The narrower Google entrypoint helper notes preserve when to rerun the broader Google attached-html surface checker before the route narrows.",
    },
    {
        "path": "scripts/windows/show_google_issue3_google_attached_html_entrypoint.ps1",
        "snippet": "Use google_attached_html_asset_closure when local asset drift might explain the current Google-shaped attached-page failure and you want the deeper asset audit reprinted after the sidecar audit and broader surface check but before the route narrows into the issue-specific checker or shortcut ladder.",
        "purpose": "The narrower Google entrypoint helper notes preserve when to rerun the deeper asset-closure audit before shortcut follow-up.",
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
        "snippet": 'Write-Host (("  Surface check:      {0}") -f $helper.helper_commands.proof_surface_check)',
        "purpose": "The launcher companion helper prints the pinned proof-entrypoint surface checker once sidecar and asset preflight finishes.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": 'Write-Host (("  Proof entrypoint:   {0}") -f $helper.helper_commands.proof_entrypoint)',
        "purpose": "The launcher companion helper prints the pinned proof-entrypoint helper once sidecar and asset preflight finishes.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "snippet": "Use proof_surface_check and proof_entrypoint when the current attached-page replay is already pinned to the known three-page compatibility bundle and you want the proof-only checker and helper pair reprinted directly from the launcher-companion surface before widening back into the broader replay helper chain.",
        "purpose": "The launcher companion helper notes preserve when to bridge directly from launcher preflight into the pinned proof route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "snippet": "replay_shortcuts_windows_replay_attached_html_bridge = $replayShortcutsWindowsReplayAttachedHtmlBridgeCommand",
        "purpose": "The replay-route shortcut helper keeps the replay-shortcuts-to-Windows-replay bridge wired into its compact command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "snippet": 'Write-Host (("  Replay-to-Windows:    {0}") -f $entrypoint.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)',
        "purpose": "The replay-route shortcut helper prints the replay-shortcuts-to-Windows-replay bridge before it narrows back into shorter replay follow-up.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "snippet": "Use replay_shortcuts_windows_replay_attached_html_bridge when the replay-route shortcut still needs the replay-side surface check, the Windows replay attached-page quickstart, and the broader Windows-first bridge kept visible before the route collapses back to the shorter attached-page helper chain.",
        "purpose": "The replay-route shortcut helper notes preserve when to widen into the replay-shortcuts-to-Windows-replay bridge from the compact replay route.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_replay_attached_quickstart_audit(repo_root: Path) -> dict[str, object]:
    results: list[dict[str, object]] = []
    missing_count = 0

    for expectation in EXPECTATIONS:
        full_path = repo_root / expectation["path"]
        if not full_path.is_file():
            exists = False
        else:
            exists = expectation["snippet"] in full_path.read_text(
                encoding="utf-8", errors="ignore"
            )

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
        "Google Issue #3 Windows Replay Attached HTML Quickstart Audit",
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
        description=(
            "Audit the replay-attached quickstart note plus the downstream Google-entrypoint, "
            "replay-route shortcut bridge, launcher-companion, and bundle-proof helper contracts for drift."
        )
    )
    parser.add_argument(
        "--repo-root",
        help="Lightpanda repo root to inspect. Defaults to the current directory.",
    )
    parser.add_argument(
        "--json", action="store_true", help="Print structured JSON instead of text."
    )
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_replay_attached_quickstart_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
