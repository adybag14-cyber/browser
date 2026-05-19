import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_shortcut_first_entrypoint_validation_surface.ps1",
        "purpose": "The replay quickstart keeps the shortcut-first fail-fast checker visible before the narrower route is trusted.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "purpose": "The replay quickstart keeps the shortcut-first helper visible in the Google-shaped attached-page narrowing path.",
    },
    {
        "path": "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_suite_router_shortcut_first_entrypoint_validation_surface.ps1",
        "purpose": "The suite-router shortcut bridge keeps the shortcut-first checker visible beside the compact bridge.",
    },
    {
        "path": "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "purpose": "The suite-router shortcut bridge keeps the shortcut-first helper visible as the shortest issue #3 bridge.",
    },
    {
        "path": "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_attached_html_validation_surface.ps1",
        "purpose": "The suite-router shortcut bridge keeps the broader Google attached HTML checker visible beside the compact route.",
    },
    {
        "path": "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_attached_html_local_asset_closure.ps1 -GoogleStyle",
        "purpose": "The suite-router shortcut bridge keeps the deeper Google-style asset audit visible before the narrower issue-specific bridge takes over.",
    },
    {
        "path": "docs/ISSUE3_SUITE_ROUTER_SHORTCUT_BRIDGE.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_google_attached_html_entrypoint.ps1",
        "purpose": "The suite-router shortcut bridge keeps the issue-specific Google attached HTML bridge visible beside the compact route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "snippet": "suite_router_shortcut_surface_check = $suiteRouterShortcutSurfaceCheckCommand",
        "purpose": "The shortcut-first helper keeps its dedicated surface checker wired into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "snippet": "suite_router_attached_html_surface_check = $suiteRouterAttachedHtmlSurfaceCheckCommand",
        "purpose": "The shortcut-first helper keeps the attached HTML quickstart checker wired beside the compact route.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "snippet": "google_attached_html_surface_check = $googleAttachedHtmlSurfaceCheckCommand",
        "purpose": "The shortcut-first helper keeps the broader Google attached HTML checker wired into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "snippet": "google_attached_html_asset_audit = $googleAttachedHtmlAssetClosureCommand",
        "purpose": "The shortcut-first helper keeps the deeper Google-style asset audit wired into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "snippet": "google_issue3_attached_html_surface_check = $googleIssue3AttachedHtmlSurfaceCheckCommand",
        "purpose": "The shortcut-first helper keeps the issue-specific Google attached HTML checker wired into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "snippet": "google_attached_html_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_google_attached_html_entrypoint.ps1' -Arguments $bundleArguments",
        "purpose": "The shortcut-first helper keeps the issue-specific Google attached HTML bridge wired into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "snippet": "replay_route_shortcut = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $bundleArguments",
        "purpose": "The shortcut-first helper keeps the narrower replay-route shortcut bridge wired into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "snippet": 'Write-Host ((\"  7. Shortcut surface:       {0}\") -f $entrypoint.helper_commands.suite_router_shortcut_surface_check)',
        "purpose": "The surfaced shortcut-first ladder prints the dedicated surface checker.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "snippet": 'Write-Host ((\" 12. Google surface check:   {0}\") -f $entrypoint.helper_commands.google_attached_html_surface_check)',
        "purpose": "The surfaced shortcut-first ladder prints the broader Google attached HTML checker.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "snippet": 'Write-Host ((\" 13. Google asset audit:     {0}\") -f $entrypoint.helper_commands.google_attached_html_asset_audit)',
        "purpose": "The surfaced shortcut-first ladder prints the deeper Google-style asset audit.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "snippet": 'Write-Host ((\" 14. Issue-specific check:   {0}\") -f $entrypoint.helper_commands.google_issue3_attached_html_surface_check)',
        "purpose": "The surfaced shortcut-first ladder prints the issue-specific Google attached HTML checker.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "snippet": 'Write-Host ((\" 15. Google entrypoint:      {0}\") -f $entrypoint.helper_commands.google_attached_html_entrypoint)',
        "purpose": "The surfaced shortcut-first ladder prints the issue-specific Google attached HTML bridge.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "snippet": 'Write-Host ((\" 18. Replay-route shortcut:  {0}\") -f $entrypoint.helper_commands.replay_route_shortcut)',
        "purpose": "The surfaced shortcut-first ladder prints the narrower replay-route shortcut bridge.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "snippet": "Use google_attached_html_asset_audit when missing sidecars or local asset drift might explain the current Google-shaped attached-page failure and you want the deeper audit reprinted before the narrower issue-specific checker or bridge takes over.",
        "purpose": "The shortcut-first helper notes preserve when to reopen the deeper Google-style asset audit.",
    },
    {
        "path": "scripts/windows/show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "snippet": "Use replay_shortcuts as the default next helper when no pinned bundle inputs, saved summary, or non-default repo root need to stay visible first.",
        "purpose": "The shortcut-first helper notes preserve the default narrowing path into replay shortcuts.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_shortcut_first_audit(repo_root: Path) -> dict[str, object]:
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
        "Google Issue #3 Suite-Router Shortcut-First Entrypoint Audit",
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
            "Audit the issue #3 suite-router shortcut-first note and helper "
            "surface for Linux-runnable contract drift."
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
    audit = build_shortcut_first_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())