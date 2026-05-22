import argparse
import json
from pathlib import Path


DEFAULT_TARGETS = (
    {
        "path": "docs/WINDOWS_FULL_USE.md",
        "purpose": "Windows runbook anchor for attached-pages localhost replay.",
    },
    {
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md",
        "purpose": "Google attached HTML validation flow note.",
    },
    {
        "path": "docs/ISSUE3_TOP_LEVEL_ATTACHED_HTML_BRIDGE.md",
        "purpose": "Top-level attached HTML bridge note.",
    },
    {
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_ROUTE.md",
        "purpose": "Windows full-use attached HTML route note.",
    },
    {
        "path": "scripts/windows/start_attached_pages_catalog.ps1",
        "purpose": "Attached-pages catalog entrypoint and sidecar audit wrapper.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "purpose": "Short replay-attached helper route.",
    },
    {
        "path": "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "purpose": "Replay-attached fail-fast validation surface.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_attached_html_route.ps1",
        "purpose": "Windows full-use attached HTML route helper ladder.",
    },
    {
        "path": "scripts/windows/show_google_issue3_windows_full_use_validation_router_attached_html_bridge.ps1",
        "purpose": "Windows full-use to validation-router bridge.",
    },
    {
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "purpose": "Launcher-companion helper surface.",
    },
    {
        "path": "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "purpose": "Launcher-companion fail-fast validation surface.",
    },
    {
        "path": "tmp-browser-smoke/attached-pages/google_issue3_windows_full_use_attached_html_route_audit.py",
        "purpose": "Route audit helper for the Windows full-use attached HTML lane.",
    },
    {
        "path": "tmp-browser-smoke/attached-pages/test_google_issue3_windows_full_use_attached_html_route_audit.py",
        "purpose": "Regression coverage for the Windows full-use attached HTML route audit.",
    },
)


def resolve_repo_root(root: str | None) -> Path:
    candidate = Path.cwd() if root is None else Path(root)
    resolved = candidate.expanduser().resolve()
    if not resolved.is_dir():
        raise FileNotFoundError(f"repo root does not exist: {resolved}")
    return resolved


def build_repo_root_error_inventory(root: str | None, message: str) -> dict[str, object]:
    repo_root = str(Path.cwd()) if root is None else str(Path(root).expanduser())
    return {
        "repo_root": repo_root,
        "target_count": len(DEFAULT_TARGETS),
        "existing_count": None,
        "missing_count": None,
        "results": [],
        "error_type": "repo_root_not_found",
        "error": message,
    }


def build_inventory(repo_root: Path, targets: list[dict[str, str]]) -> dict[str, object]:
    results: list[dict[str, object]] = []
    existing_count = 0
    missing_count = 0

    for target in targets:
        full_path = repo_root / target["path"]
        exists = full_path.exists()
        result = {
            "path": target["path"],
            "purpose": target["purpose"],
            "exists": exists,
            "kind": "file" if full_path.is_file() else ("directory" if full_path.is_dir() else "missing"),
        }
        results.append(result)
        if exists:
            existing_count += 1
        else:
            missing_count += 1

    return {
        "repo_root": str(repo_root),
        "target_count": len(results),
        "existing_count": existing_count,
        "missing_count": missing_count,
        "results": results,
    }


def parse_targets(paths: list[str], include_defaults: bool) -> list[dict[str, str]]:
    targets = [dict(target) for target in DEFAULT_TARGETS] if include_defaults else []
    for path in paths:
        targets.append(
            {
                "path": path,
                "purpose": "User-supplied path probe.",
            }
        )
    return targets


def render_text_report(inventory: dict[str, object]) -> str:
    lines = [
        "Google Issue #3 Attached-Pages Branch Inventory Audit",
        "",
        f"Repo root: {inventory['repo_root']}",
    ]

    if inventory.get("error_type"):
        lines.extend(
            [
                f"Error: {inventory['error']}",
                "",
            ]
        )
        return "\n".join(lines).rstrip() + "\n"

    lines.extend(
        [
            f"Targets checked: {inventory['target_count']}",
            f"Existing: {inventory['existing_count']}",
            f"Missing: {inventory['missing_count']}",
            "",
        ]
    )

    if inventory["results"]:
        lines.append("Results:")
        for result in inventory["results"]:
            status = "present" if result["exists"] else "missing"
            lines.append(f"- {status}: {result['path']}")
            lines.append(f"  Purpose: {result['purpose']}")
            lines.append(f"  Kind: {result['kind']}")
    else:
        lines.append("No targets selected.")

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Audit known issue #3 attached-pages helper surfaces and optional "
            "candidate paths before choosing a create-only slice."
        )
    )
    parser.add_argument(
        "--repo-root",
        help="Path to the repository root. Defaults to the current working directory.",
    )
    parser.add_argument(
        "--path",
        action="append",
        default=[],
        help="Additional path to probe. Repeat to check multiple candidate paths.",
    )
    parser.add_argument(
        "--only-paths",
        action="store_true",
        help="Probe only user-supplied --path values instead of the default attached-pages surface set.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print JSON instead of the text report.",
    )
    args = parser.parse_args()

    targets = parse_targets(args.path, include_defaults=not args.only_paths)

    try:
        repo_root = resolve_repo_root(args.repo_root)
    except FileNotFoundError as err:
        inventory = build_repo_root_error_inventory(args.repo_root, str(err))
    else:
        inventory = build_inventory(repo_root, targets)

    if args.json:
        print(json.dumps(inventory, indent=2))
    else:
        print(render_text_report(inventory), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())