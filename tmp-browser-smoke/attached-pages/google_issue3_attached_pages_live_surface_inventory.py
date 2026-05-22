import argparse
import json
import os
import sys
from pathlib import Path


SURFACES = (
    {
        "group": "attached-pages-catalog",
        "kind": "file",
        "path": "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py",
        "purpose": "Cross-platform launcher for attached-page localhost replay.",
    },
    {
        "group": "attached-pages-catalog",
        "kind": "file",
        "path": "tmp-browser-smoke/attached-pages/README.md",
        "purpose": "Attached-pages launcher usage and preflight guidance.",
    },
    {
        "group": "attached-pages-catalog",
        "kind": "file",
        "path": "scripts/windows/start_attached_pages_catalog.ps1",
        "purpose": "Windows wrapper for the attached-pages launcher.",
    },
    {
        "group": "validation-router",
        "kind": "file",
        "path": "scripts/windows/show_headed_validation_suites.ps1",
        "purpose": "Top-level headed validation router.",
    },
    {
        "group": "launcher-companion",
        "kind": "file",
        "path": "scripts/windows/check_google_issue3_attached_pages_launcher_companion_validation_surface.ps1",
        "purpose": "Fail-fast checker for the attached-pages launcher companion surface.",
    },
    {
        "group": "launcher-companion",
        "kind": "file",
        "path": "scripts/windows/show_google_issue3_attached_pages_launcher_companion.ps1",
        "purpose": "Narrow launcher companion helper for issue #3 attached-page replay.",
    },
    {
        "group": "launcher-companion",
        "kind": "file",
        "path": "docs/ISSUE3_WINDOWS_FULL_USE_ATTACHED_HTML_CATALOG_QUICKSTART.md",
        "purpose": "Windows catalog quickstart note paired with launcher preflight.",
    },
    {
        "group": "replay-route",
        "kind": "file",
        "path": "scripts/windows/check_google_issue3_windows_replay_attached_html_quickstart_validation_surface.ps1",
        "purpose": "Fail-fast checker for the Windows replay attached-html quickstart.",
    },
    {
        "group": "replay-route",
        "kind": "file",
        "path": "scripts/windows/show_google_issue3_windows_replay_attached_html_quickstart.ps1",
        "purpose": "Windows replay quickstart helper for attached-page re-entry.",
    },
    {
        "group": "replay-route",
        "kind": "file",
        "path": "scripts/windows/show_google_issue3_replay_route_shortcut_entrypoint.ps1",
        "purpose": "Shorter replay-route helper after launcher preflight narrows the lane.",
    },
    {
        "group": "replay-route",
        "kind": "file",
        "path": "docs/ISSUE3_WINDOWS_REPLAY_ATTACHED_HTML_QUICKSTART.md",
        "purpose": "Replay quickstart note for the attached-page route.",
    },
    {
        "group": "replay-route",
        "kind": "file",
        "path": "docs/ISSUE3_REPLAY_ROUTE_SHORTCUT_BRIDGE.md",
        "purpose": "Bridge note for replay-route shortcut re-entry.",
    },
    {
        "group": "google-attached-html",
        "kind": "file",
        "path": "scripts/windows/check_google_issue3_validation_router_attached_html_quickstart_surface.ps1",
        "purpose": "Router-specific checker for the issue #3 attached-html quickstart surface.",
    },
    {
        "group": "google-attached-html",
        "kind": "file",
        "path": "scripts/windows/show_google_issue3_attached_html_change_area_quickstart.ps1",
        "purpose": "Change-area helper for the narrower issue #3 attached-html route.",
    },
    {
        "group": "google-attached-html",
        "kind": "file",
        "path": "scripts/windows/show_google_issue3_top_level_attached_html_quickstart.ps1",
        "purpose": "Top-level helper for the broader issue #3 attached-html ladder.",
    },
    {
        "group": "google-attached-html",
        "kind": "file",
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_VALIDATION_FLOW.md",
        "purpose": "Read-first note for the Google-shaped attached-html flow.",
    },
    {
        "group": "google-attached-html",
        "kind": "file",
        "path": "docs/ISSUE3_GOOGLE_ATTACHED_HTML_ENTRYPOINT.md",
        "purpose": "Entry-point note for the issue-specific Google attached-html ladder.",
    },
    {
        "group": "proof-route",
        "kind": "file",
        "path": "scripts/windows/check_google_issue3_attached_html_target_bundle_proof_entrypoint_validation_surface.ps1",
        "purpose": "Fail-fast checker for the pinned three-page proof route.",
    },
    {
        "group": "proof-route",
        "kind": "file",
        "path": "scripts/windows/show_google_issue3_attached_html_target_bundle_proof_entrypoint.ps1",
        "purpose": "Pinned proof-entrypoint helper for the known compatibility bundle.",
    },
    {
        "group": "proof-route",
        "kind": "file",
        "path": "docs/ISSUE3_ATTACHED_HTML_TARGET_BUNDLE_PROOF_ENTRYPOINT.md",
        "purpose": "Pinned proof-route note for the three-page compatibility bundle.",
    },
)


def resolve_repo_root(start_path: Path, explicit_root: str | None) -> Path:
    if explicit_root:
        candidate = Path(explicit_root).expanduser().resolve()
        if (candidate / "build.zig").is_file():
            return candidate
        raise FileNotFoundError(
            f"explicit repo root does not look like a Lightpanda checkout: {candidate}"
        )

    override = os.environ.get("LIGHTPANDA_REPO_ROOT", "").strip()
    if override:
        return resolve_repo_root(start_path, override)

    cursor = start_path.expanduser().resolve()
    if cursor.is_file():
        cursor = cursor.parent

    while True:
        if (cursor / "build.zig").is_file():
            return cursor
        parent = cursor.parent
        if parent == cursor:
            raise FileNotFoundError(
                f"could not resolve the Lightpanda repo root from {start_path}"
            )
        cursor = parent


def build_inventory(repo_root: Path, group_filter: set[str]) -> list[dict[str, object]]:
    inventory: list[dict[str, object]] = []
    for surface in SURFACES:
        if group_filter and surface["group"] not in group_filter:
            continue
        relative_path = surface["path"]
        full_path = repo_root / relative_path
        expected_file = surface["kind"] == "file"
        exists = full_path.is_file() if expected_file else full_path.is_dir()
        inventory.append(
            {
                "group": surface["group"],
                "kind": surface["kind"],
                "path": relative_path,
                "purpose": surface["purpose"],
                "exists": exists,
            }
        )
    return inventory


def render_text_report(repo_root: Path, inventory: list[dict[str, object]], missing_only: bool) -> int:
    visible_rows = [row for row in inventory if row["exists"] or not missing_only]
    grouped: dict[str, list[dict[str, object]]] = {}
    for row in visible_rows:
        grouped.setdefault(str(row["group"]), []).append(row)

    total = len(inventory)
    present = sum(1 for row in inventory if row["exists"])
    missing = total - present

    print("Issue #3 attached-pages live-surface inventory")
    print("")
    print(f"Repo root: {repo_root}")
    print(f"Present: {present}/{total}")
    print(f"Missing: {missing}/{total}")
    print("")

    for group in sorted(grouped):
        rows = grouped[group]
        print(group)
        print("-" * len(group))
        for row in rows:
            status = "PASS" if row["exists"] else "MISS"
            print(f"[{status}] {row['path']}")
            print(f"  {row['purpose']}")
        print("")

    if missing == 0:
        print(
            "All known issue #3 attached-pages surfaces are already present in this checkout. "
            "Prefer an existing-file diff or a different lane instead of drafting a create-only helper from older notes."
        )
    else:
        print(
            "Use the missing paths above as the honest create-only candidates. "
            "If the surface you want is already present here, re-fetch the live file before planning edits."
        )

    return 1 if missing_only and not visible_rows else 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Inventory the known issue #3 attached-pages validation surfaces in a local checkout "
            "so future runs can confirm whether a helper path is truly missing before drafting a create-only slice."
        )
    )
    parser.add_argument("--repo-root", help="Explicit Lightpanda checkout root.")
    parser.add_argument(
        "--group",
        action="append",
        default=[],
        help="Limit output to one or more groups such as launcher-companion or proof-route.",
    )
    parser.add_argument(
        "--missing-only",
        action="store_true",
        help="Show only missing paths in text mode.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of text.",
    )
    parser.add_argument(
        "--require-complete",
        action="store_true",
        help="Exit with code 1 when any known path is missing.",
    )
    args = parser.parse_args()

    try:
        repo_root = resolve_repo_root(Path(__file__), args.repo_root)
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        return 2

    group_filter = {group.strip() for group in args.group if group.strip()}
    inventory = build_inventory(repo_root, group_filter)
    missing = [row for row in inventory if not row["exists"]]

    if args.json:
        payload = {
            "profile": "issue3-attached-pages-live-surface-inventory",
            "repo_root": str(repo_root),
            "group_filter": sorted(group_filter),
            "total_count": len(inventory),
            "missing_count": len(missing),
            "surfaces": inventory,
        }
        print(json.dumps(payload, indent=2))
    else:
        render_text_report(repo_root, inventory, args.missing_only)

    if args.require_complete and missing:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
