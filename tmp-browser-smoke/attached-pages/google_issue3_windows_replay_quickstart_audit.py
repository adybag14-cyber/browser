import argparse
import json
from pathlib import Path


EXPECTATIONS = (
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "purpose": "The replay quickstart keeps the replay-attached fail-fast checker visible before the narrower attached-page ladder is trusted.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "purpose": "The replay quickstart keeps the narrower replay-attached helper visible once the route narrows into attached localhost follow-up.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "purpose": "The replay quickstart keeps the launcher-companion checker visible when the route needs the smaller wrapper-backed preflight surface.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1",
        "purpose": "The replay quickstart keeps the launcher-companion helper visible when the route needs the smaller wrapper-backed preflight surface.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_attached_pages_launcher_companion.ps1 -RepoRoot '<repo-root>' -InputPath '<bundle-html-or-folder>'",
        "purpose": "The replay quickstart keeps the repo-root-preserving launcher-companion helper visible when pinned bundle replay needs to preserve broader context.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_suite_router_shortcut_first_entrypoint.ps1",
        "purpose": "The replay quickstart keeps the suite-router shortcut bridge visible before the route collapses into replay shortcuts.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "purpose": "The replay quickstart keeps the replay-route shortcut bridge visible when the narrower replay follow-up is the next likely handoff.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_attached_html_validation_flow.ps1",
        "purpose": "The replay quickstart keeps the broader attached-page flow helper visible before the route collapses into the shorter issue #3 helpers.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_attached_html_validation_flow.ps1",
        "purpose": "The replay quickstart keeps the Google-shaped attached-page flow helper visible when the current inputs are already on that narrower branch.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1",
        "purpose": "The replay-attached quickstart keeps the broader Windows full-use route checker visible before the replay ladder is trusted.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1",
        "purpose": "The replay-attached quickstart keeps the Windows full-use validation-router bridge visible before the route narrows further.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1",
        "purpose": "The replay-attached quickstart keeps the Windows full-use attached-html catalog quickstart visible between the broader route and the narrower replay helper.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
        "purpose": "The replay-attached quickstart keeps the validation-router attached-html checker visible before its quickstart helper is trusted.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "snippet": "powershell -ExecutionPolicy Bypass -File .\\scripts\\windows\\show_google_issue3_validation_router_attached_html_quickstart.ps1",
        "purpose": "The replay-attached quickstart keeps the validation-router attached-html quickstart visible in the narrowed replay ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "windows_replay_attached_html_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "purpose": "The replay quickstart helper wires the replay-attached fail-fast checker into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "windows_full_use_attached_html_route_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_windows_full_use_attached_html_route_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "purpose": "The replay quickstart helper wires the broader Windows full-use route checker into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "windows_full_use_validation_router_attached_html_bridge = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1' -Arguments $sharedArguments",
        "purpose": "The replay quickstart helper wires the Windows full-use validation-router bridge into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "windows_full_use_attached_html_catalog_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_full_use_attached_html_catalog_quickstart.ps1' -Arguments $sharedArguments",
        "purpose": "The replay quickstart helper wires the Windows full-use attached-html catalog quickstart into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "validation_router_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_validation_router_attached_html_quickstart.ps1' -Arguments $sharedArguments",
        "purpose": "The replay quickstart helper wires the validation-router attached-html quickstart into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "windows_replay_attached_html_quickstart = Format-HelperCommand -ScriptName 'show_google_issue3_windows_replay_attached_html_quickstart.ps1' -Arguments $sharedArguments",
        "purpose": "The replay quickstart helper wires the narrower replay-attached helper into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "attached_pages_launcher_surface_check = Format-HelperCommand -ScriptName 'check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1' -Arguments $routeSurfaceArguments",
        "purpose": "The replay quickstart helper wires the launcher-companion checker into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "attached_pages_launcher_companion = Format-HelperCommand -ScriptName 'show_google_issue3_attached_pages_launcher_companion.ps1' -Arguments $sharedArguments",
        "purpose": "The replay quickstart helper wires the launcher-companion helper into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot",
        "purpose": "The replay quickstart helper wires the broader attached-page flow helper into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "google_attached_html_flow = Format-HelperCommandWithRepoRootEnv -ScriptName 'show_google_attached_html_validation_flow.ps1' -Arguments $attachedHtmlFlowArguments -RepoRootOverride $RepoRoot",
        "purpose": "The replay quickstart helper wires the Google-shaped attached-page flow helper into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "suite_router_shortcut_first = Format-HelperCommand -ScriptName 'show_google_issue3_suite_router_shortcut_first_entrypoint.ps1' -Arguments $sharedArguments",
        "purpose": "The replay quickstart helper wires the suite-router shortcut bridge into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "replay_route_shortcut_entrypoint = Format-HelperCommand -ScriptName 'show_google_issue3_replay_route_shortcut_entrypoint.ps1' -Arguments $sharedArguments",
        "purpose": "The replay quickstart helper wires the replay-route shortcut bridge into the command map.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "Treat replay_attached_html_note_path as the read-first written companion to windows_replay_attached_html_quickstart",
        "purpose": "The replay quickstart helper keeps the narrowed replay-attached note paired with its helper surface.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": "Use attached_pages_launcher_surface_check and attached_pages_launcher_companion when the replay has already narrowed into attached localhost follow-up",
        "purpose": "The replay quickstart helper explains when to switch to the smaller launcher-companion surface.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": 'Write-Host (("  Route surface check:       {0}") -f $helper.commands.windows_full_use_attached_html_route_surface_check)',
        "purpose": "The replay quickstart helper prints the broader Windows full-use route checker on the surfaced ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": 'Write-Host (("  Windows validation bridge: {0}") -f $helper.commands.windows_full_use_validation_router_attached_html_bridge)',
        "purpose": "The replay quickstart helper prints the Windows full-use validation-router bridge on the surfaced ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": 'Write-Host (("  Windows catalog quick:     {0}") -f $helper.commands.windows_full_use_attached_html_catalog_quickstart)',
        "purpose": "The replay quickstart helper prints the Windows full-use attached-html catalog quickstart on the surfaced ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": 'Write-Host (("  Validation-router quick:   {0}") -f $helper.commands.validation_router_attached_html_quickstart)',
        "purpose": "The replay quickstart helper prints the validation-router attached-html quickstart on the surfaced ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": 'Write-Host (("  Launcher surface check:    {0}") -f $helper.commands.attached_pages_launcher_surface_check)',
        "purpose": "The replay quickstart helper prints the launcher-companion checker on the surfaced ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": 'Write-Host (("  Launcher companion:        {0}") -f $helper.commands.attached_pages_launcher_companion)',
        "purpose": "The replay quickstart helper prints the launcher-companion helper on the surfaced ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": 'Write-Host (("  Attached-page flow:        {0}") -f $helper.commands.attached_html_flow)',
        "purpose": "The replay quickstart helper prints the broader attached-page flow helper on the surfaced ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": 'Write-Host (("  Google attached flow:      {0}") -f $helper.commands.google_attached_html_flow)',
        "purpose": "The replay quickstart helper prints the Google-shaped attached-page flow helper on the surfaced ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": 'Write-Host (("  Replay attached note:      {0}") -f $helper.replay_attached_html_note_path)',
        "purpose": "The replay quickstart helper prints the replay-attached companion note on the surfaced ladder so the written route stays paired with the narrower helper.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": 'Write-Host (("  Router shortcut:           {0}") -f $helper.commands.suite_router_shortcut_first)',
        "purpose": "The replay quickstart helper prints the suite-router shortcut bridge on the surfaced ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_quickstart.ps1",
        "snippet": 'Write-Host (("  Route shortcut:            {0}") -f $helper.commands.replay_route_shortcut_entrypoint)',
        "purpose": "The replay quickstart helper prints the replay-route shortcut bridge on the replay follow-up surface.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_repo_root_error_audit(root: str | None, message: str) -> dict[str, object]:
    repo_root = str(Path.cwd()) if root is None else str(Path(root).expanduser())
    return {
        "repo_root": repo_root,
        "expectation_count": len(EXPECTATIONS),
        "missing_count": None,
        "missing_path_count": None,
        "missing_paths": [],
        "results": [],
        "error_type": "repo_root_not_found",
        "error": message,
    }


def summarize_missing_paths(results: list[dict[str, object]]) -> list[dict[str, object]]:
    missing_by_path: dict[str, list[dict[str, object]]] = {}

    for result in results:
        if result["exists"]:
            continue
        missing_by_path.setdefault(result["path"], []).append(result)

    summary: list[dict[str, object]] = []
    for path in sorted(missing_by_path):
        entries = missing_by_path[path]
        summary.append(
            {
                "path": path,
                "missing_expectation_count": len(entries),
                "first_missing_purpose": entries[0]["purpose"],
                "first_missing_snippet": entries[0]["snippet"],
            }
        )

    return summary


def build_replay_quickstart_audit(repo_root: Path) -> dict[str, object]:
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

    missing_paths = summarize_missing_paths(results)
    return {
        "repo_root": str(repo_root),
        "expectation_count": len(results),
        "missing_count": missing_count,
        "missing_path_count": len(missing_paths),
        "missing_paths": missing_paths,
        "results": results,
    }


def render_text_report(audit: dict[str, object]) -> str:
    if audit.get("error"):
        return "\n".join(
            [
                "Google Issue #3 Windows Replay Quickstart Audit",
                "",
                f"Repo root: {audit['repo_root']}",
                f"Error: {audit['error']}",
                "",
            ]
        )

    lines = [
        "Google Issue #3 Windows Replay Quickstart Audit",
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

    missing_paths = audit.get("missing_paths", [])
    if missing_paths:
        lines.append("")
        lines.append("Missing path summary:")
        for entry in missing_paths:
            lines.append(
                f"- {entry['path']}: {entry['missing_expectation_count']} missing expectation(s)"
            )
            lines.append(f"  first gap: {entry['first_missing_purpose']}")
            lines.append(f"  first snippet: {entry['first_missing_snippet']}")

    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Audit the issue #3 Windows replay quickstart route for Linux-side drift checks."
    )
    parser.add_argument("--repo-root", help="Lightpanda repo root to inspect. Defaults to the current directory.")
    parser.add_argument("--json", action="store_true", help="Print structured JSON instead of text.")
    args = parser.parse_args(argv)

    try:
        repo_root = resolve_repo_root(args.repo_root)
    except FileNotFoundError as err:
        audit = build_repo_root_error_audit(args.repo_root, str(err))
        if args.json:
            print(json.dumps(audit, indent=2))
        else:
            print(render_text_report(audit), end="")
        return 1

    audit = build_replay_quickstart_audit(repo_root)

    if args.json:
        print(json.dumps(audit, indent=2))
    else:
        print(render_text_report(audit), end="")

    return 1 if audit["missing_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
