import argparse
import importlib
import json
import os
import sys
from pathlib import Path

def normalize_candidate_paths(paths: list[str]) -> list[str]:
    seen: set[str] = set()
    normalized: list[str] = []
    for raw_path in paths:
        candidate = raw_path.strip().replace("\\", "/").lstrip("./")
        if not candidate or candidate in seen:
            continue
        seen.add(candidate)
        normalized.append(candidate)
    return normalized


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


def load_known_surfaces() -> tuple[dict[str, object], ...]:
    try:
        module = importlib.import_module("google_issue3_attached_pages_live_surface_inventory")
    except ModuleNotFoundError:
        return ()
    surfaces = getattr(module, "SURFACES", ())
    return tuple(surface for surface in surfaces if isinstance(surface, dict))


def index_known_surfaces() -> dict[str, dict[str, str]]:
    return {
        str(surface["path"]): {
            "group": str(surface["group"]),
            "kind": str(surface["kind"]),
            "purpose": str(surface["purpose"]),
        }
        for surface in load_known_surfaces()
    }


def inspect_candidate_paths(repo_root: Path, candidate_paths: list[str]) -> dict[str, object]:
    known_surfaces = index_known_surfaces()
    collisions: list[dict[str, object]] = []
    for relative_path in normalize_candidate_paths(candidate_paths):
        full_path = repo_root / relative_path
        known_surface = known_surfaces.get(relative_path)
        exists = full_path.exists()
        entry: dict[str, object] = {
            "path": relative_path,
            "exists": exists,
            "is_known_surface": known_surface is not None,
            "kind": "file" if full_path.is_file() else "directory" if full_path.is_dir() else None,
            "group": None if known_surface is None else known_surface["group"],
            "purpose": None if known_surface is None else known_surface["purpose"],
        }
        if exists:
            collisions.append(entry)

    return {
        "repo_root": str(repo_root),
        "candidate_count": len(normalize_candidate_paths(candidate_paths)),
        "collision_count": len(collisions),
        "collisions": collisions,
    }


def render_text_report(result: dict[str, object]) -> str:
    lines = [
        "Issue #3 attached-pages branch-collision preflight",
        "",
        f"Repo root: {result['repo_root']}",
        f"Candidate paths: {result['candidate_count']}",
        f"Collisions: {result['collision_count']}",
        "",
    ]

    collisions = result.get("collisions", []) or []
    if not collisions:
        lines.append(
            "No candidate path already exists in this checkout. A create-only slice is still possible, but re-fetch the live branch before publishing."
        )
        return "\n".join(lines).rstrip() + "\n"

    lines.append("Existing paths:")
    for collision in collisions:
        kind = collision.get("kind") or "path"
        lines.append(f"- {collision['path']} [{kind}]")
        if collision.get("group"):
            lines.append(f"  Known surface group: {collision['group']}")
        if collision.get("purpose"):
            lines.append(f"  Purpose: {collision['purpose']}")

    lines.extend(
        [
            "",
            "Use an existing-file diff or pick a different candidate path before drafting a create-only helper.",
        ]
    )
    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether one or more issue #3 attached-pages candidate helper paths "
            "already exist in the current checkout before drafting a create-only slice."
        )
    )
    parser.add_argument("--repo-root", help="Explicit Lightpanda checkout root.")
    parser.add_argument(
        "--path",
        action="append",
        default=[],
        help="Candidate relative path to check. Repeat for multiple paths.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of text.",
    )
    args = parser.parse_args(argv)

    candidate_paths = normalize_candidate_paths(args.path)
    if not candidate_paths:
        parser.error("at least one --path value is required")

    try:
        repo_root = resolve_repo_root(Path(__file__), args.repo_root)
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        return 2

    result = inspect_candidate_paths(repo_root, candidate_paths)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(render_text_report(result), end="")
    return 1 if result["collision_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
