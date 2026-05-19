import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_replay_route_shortcut_validation_surface.ps1",
        "purpose": "The replay-route shortcut note keeps its dedicated fail-fast checker visible before the compact route is trusted.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1",
        "purpose": "The replay-route shortcut note keeps the broader attached-page localhost flow visible before the route narrows again.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1",
        "purpose": "The replay-route shortcut note keeps the dedicated Google-shaped attached-page flow visible before the route narrows again.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_shortcuts_windows_replay_attached_html_bridge.ps1",
        "purpose": "The replay-route shortcut note keeps the replay-shortcuts-to-Windows-replay bridge visible before the shorter helper chain takes over.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_bundle_first_bridge.ps1",
        "purpose": "The replay-route shortcut note keeps the replay-route bundle-first bridge visible for pinned bundle follow-up.",
    },
    {
        "path": "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "purpose": "The replay-route shortcut note keeps the narrower Windows replay attached-html quickstart visible as a bridge back into replay-side attached-page follow-up.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "snippet": "replay_route_shortcut_surface_check = $replayRouteShortcutSurfaceCheckCommand",
        "purpose": "The replay-route shortcut helper keeps its dedicated fail-fast checker wired into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "snippet": "attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot",
        "purpose": "The replay-route shortcut helper keeps the broader attached-page localhost flow wired into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "snippet": "google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot",
        "purpose": "The replay-route shortcut helper keeps the dedicated Google-shaped attached-page flow wired into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "snippet": "replay_shortcuts_windows_replay_attached_html_bridge = $replayShortcutsWindowsReplayAttachedHtmlBridgeCommand",
        "purpose": "The replay-route shortcut helper keeps the replay-shortcuts-to-Windows-replay bridge wired into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "snippet": "windows_replay_attached_html_quickstart = $windowsReplayAttachedHtmlQuickstartCommand",
        "purpose": "The replay-route shortcut helper keeps the narrower Windows replay attached-html quickstart wired into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "snippet": "attached_bundle_first = Format-HelperCommand -ScriptName 'show_google_issue3_attached_bundle_first_entrypoint.ps1' -Arguments $bundleArguments",
        "purpose": "The replay-route shortcut helper keeps the pinned bundle-first helper wired into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "snippet": 'Write-Host (("  Attached-page flow:   {0}") -f $entrypoint.helper_commands.attached_html_flow)',
        "purpose": "The replay-route shortcut helper prints the broader attached-page localhost flow in its companion helper block.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "snippet": 'Write-Host (("  Google attached flow: {0}") -f $entrypoint.helper_commands.google_attached_html_flow)',
        "purpose": "The replay-route shortcut helper prints the dedicated Google-shaped attached-page flow in its companion helper block.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "snippet": 'Write-Host (("  Replay-to-Windows:    {0}") -f $entrypoint.helper_commands.replay_shortcuts_windows_replay_attached_html_bridge)',
        "purpose": "The replay-route shortcut helper prints the replay-shortcuts-to-Windows-replay bridge in its companion helper block.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "snippet": 'Write-Host (("  Windows replay quick: {0}") -f $entrypoint.helper_commands.windows_replay_attached_html_quickstart)',
        "purpose": "The replay-route shortcut helper prints the narrower Windows replay attached-html quickstart in its companion helper block.",
    },
    {
        "path": "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "snippet": "Use google_attached_html_flow when the current attached inputs are already Google-shaped and you still want that narrower attached-page flow helper reprinted directly from the replay-route shortcut surface before deciding whether to narrow into the attached-page shortcut, replay shortcuts, the replay-shortcuts Windows replay attached-page bridge, the next-step matrix, contextual flow, the bundle-first branch, or the safe-route map.",
        "purpose": "The replay-route shortcut helper notes preserve when to prefer the dedicated Google-shaped attached-page flow before the narrower branches take over.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_replay_route_shortcut_audit(repo_root: Path) -> dict[str, object]:
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
        "Google Issue #3 Replay-Route Shortcut Audit",
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
        description="Audit the issue #3 replay-route shortcut note and helper for attached-page, Google-flow, and replay-bridge drift."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    repo_root = resolve_repo_root(args.repo_root)
    audit = build_replay_route_shortcut_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())