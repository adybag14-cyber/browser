import argparse
import json
from pathlib import Path


HELPER_PREFIX = "google_issue3_"
TEST_PREFIX = "test_google_issue3_"
ATTACHED_PAGES_DIR = Path("tmp-browser-smoke") / "attached-pages"


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
        "attached_pages_dir": str(Path(repo_root) / ATTACHED_PAGES_DIR),
        "surface_count": 0,
        "paired_surface_count": 0,
        "missing_pair_count": 0,
        "create_only_safe_candidates": [],
        "surfaces": [],
        "error_type": "repo_root_not_found",
        "error": message,
    }


def classify_surface_name(file_name: str) -> tuple[str, str] | None:
    if not file_name.endswith(".py"):
        return None
    if file_name.startswith(TEST_PREFIX):
        return file_name[len(TEST_PREFIX) : -3], "test"
    if file_name.startswith(HELPER_PREFIX):
        return file_name[len(HELPER_PREFIX) : -3], "helper"
    return None


def build_attached_pages_surface_inventory(repo_root: Path) -> dict[str, object]:
    attached_pages_dir = repo_root / ATTACHED_PAGES_DIR
    surfaces: dict[str, dict[str, object]] = {}

    if attached_pages_dir.is_dir():
        for path in sorted(attached_pages_dir.iterdir()):
            classification = classify_surface_name(path.name)
            if classification is None:
                continue
            surface_name, kind = classification
            surface = surfaces.setdefault(
                surface_name,
                {
                    "name": surface_name,
                    "helper_present": False,
                    "helper_path": None,
                    "test_present": False,
                    "test_path": None,
                    "status": "missing_both",
                    "recommended_create_only_path": None,
                },
            )
            surface[f"{kind}_present"] = True
            surface[f"{kind}_path"] = str(path.relative_to(repo_root))

    ordered_surfaces: list[dict[str, object]] = []
    create_only_safe_candidates: list[str] = []
    paired_surface_count = 0
    missing_pair_count = 0

    for surface_name in sorted(surfaces):
        surface = surfaces[surface_name]
        helper_present = bool(surface["helper_present"])
        test_present = bool(surface["test_present"])
        if helper_present and test_present:
            surface["status"] = "paired"
            paired_surface_count += 1
        elif helper_present:
            surface["status"] = "missing_test"
            surface["recommended_create_only_path"] = str(
                ATTACHED_PAGES_DIR / f"{TEST_PREFIX}{surface_name}.py"
            )
            create_only_safe_candidates.append(str(surface["recommended_create_only_path"]))
            missing_pair_count += 1
        else:
            surface["status"] = "missing_helper"
            surface["recommended_create_only_path"] = str(
                ATTACHED_PAGES_DIR / f"{HELPER_PREFIX}{surface_name}.py"
            )
            create_only_safe_candidates.append(str(surface["recommended_create_only_path"]))
            missing_pair_count += 1
        ordered_surfaces.append(surface)

    return {
        "repo_root": str(repo_root),
        "attached_pages_dir": str(attached_pages_dir),
        "surface_count": len(ordered_surfaces),
        "paired_surface_count": paired_surface_count,
        "missing_pair_count": missing_pair_count,
        "create_only_safe_candidates": create_only_safe_candidates,
        "surfaces": ordered_surfaces,
    }


def render_text_report(inventory: dict[str, object]) -> str:
    lines = [
        "Google Issue #3 Attached-Pages Surface Inventory",
        "",
        f"Repo root: {inventory['repo_root']}",
        f"Attached pages dir: {inventory['attached_pages_dir']}",
    ]
    if inventory.get("error_type"):
        lines.extend([f"Error: {inventory['error']}", ""])
        return "\n".join(lines).rstrip() + "\n"

    lines.extend(
        [
            f"Tracked surfaces: {inventory['surface_count']}",
            f"Paired surfaces: {inventory['paired_surface_count']}",
            f"Missing counterpart surfaces: {inventory['missing_pair_count']}",
            "",
        ]
    )

    candidates = inventory.get("create_only_safe_candidates") or []
    if candidates:
        lines.append("Create-only safe candidates:")
        for candidate in candidates:
            lines.append(f"- {candidate}")
        lines.append("")

    for surface in inventory["surfaces"]:
        lines.append(f"[{surface['status'].upper()}] {surface['name']}")
        if surface.get("helper_path"):
            lines.append(f"  Helper: {surface['helper_path']}")
        if surface.get("test_path"):
            lines.append(f"  Test: {surface['test_path']}")
        if surface.get("recommended_create_only_path"):
            lines.append(f"  Next create-only path: {surface['recommended_create_only_path']}")

    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Inventory issue #3 attached-pages helper/test surfaces so future "
            "runs can avoid choosing filenames that already exist."
        )
    )
    parser.add_argument(
        "--repo-root",
        help="Lightpanda repo root to inspect. Defaults to the current directory.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print structured JSON instead of text.",
    )
    args = parser.parse_args(argv)

    try:
        repo_root = resolve_repo_root(args.repo_root)
        inventory = build_attached_pages_surface_inventory(repo_root)
    except FileNotFoundError as exc:
        inventory = build_repo_root_error_inventory(args.repo_root, str(exc))

    if args.json:
        print(json.dumps(inventory, indent=2))
    else:
        print(render_text_report(inventory), end="")

    return 0 if not inventory.get("error_type") else 1


if __name__ == "__main__":
    raise SystemExit(main())