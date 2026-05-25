#!/usr/bin/env python3

"""Check whether the saved-snapshot helper sync surface carries issue #11 helpers.

This helper focuses on the Linux/WSL re-entry lane that now depends on the
saved Zig archive candidate route and the saved Rust toolchain route. A synced
saved-browser-snapshot restore is only self-contained when these helper files
are both present on disk and listed in restore_saved_browser_snapshot.sh's
HELPER_SURFACE_PATHS.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import tempfile
import unittest


REQUIRED_HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
    (
        "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md",
        "saved Zig archive candidate route note",
    ),
    (
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
        "saved Rust toolchain route note",
    ),
    (
        "scripts/check_issue3_saved_zig_archive_candidates.py",
        "saved Zig archive candidate helper",
    ),
    (
        "scripts/check_issue3_saved_rust_archive_candidates.py",
        "saved Rust archive candidate helper",
    ),
    (
        "scripts/check_issue3_staged_rust_toolchain_candidates.py",
        "staged Rust toolchain candidate helper",
    ),
    (
        "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
        "saved Zig archive candidate route surface checker",
    ),
    (
        "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
        "saved Zig archive candidate route helper",
    ),
    (
        "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
        "saved Rust toolchain route surface checker",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
        "saved Rust toolchain route helper",
    ),
    (
        "scripts/linux/restore_saved_rust_toolchain.sh",
        "saved Rust toolchain restore helper",
    ),
)

RESTORE_HELPER_RELATIVE_PATH = "scripts/linux/restore_saved_browser_snapshot.sh"


def parse_helper_surface_paths(restore_helper_text: str) -> list[str]:
    marker = "declare -a HELPER_SURFACE_PATHS=("
    marker_index = restore_helper_text.find(marker)
    if marker_index == -1:
        raise ValueError("Could not find HELPER_SURFACE_PATHS in restore helper")

    parsed: list[str] = []
    in_block = False
    for raw_line in restore_helper_text.splitlines():
        line = raw_line.strip()
        if not in_block:
            if line == marker:
                in_block = True
            continue
        if line == ")":
            return parsed
        if line.startswith('"') and line.endswith('"'):
            parsed.append(line[1:-1])

    raise ValueError("Could not find the end of HELPER_SURFACE_PATHS")


def collect_surface_state(repo_root: Path) -> dict[str, object]:
    restore_helper = repo_root / RESTORE_HELPER_RELATIVE_PATH
    missing_files: list[dict[str, str]] = []
    missing_surface_paths: list[dict[str, str]] = []

    if not restore_helper.is_file():
        return {
            "repo_root": str(repo_root),
            "restore_helper": str(restore_helper),
            "missing_restore_helper": True,
            "parsed_helper_surface_count": 0,
            "missing_files": [
                {
                    "path": RESTORE_HELPER_RELATIVE_PATH,
                    "purpose": "saved-browser-snapshot restore helper",
                }
            ],
            "missing_surface_paths": [],
            "ok": False,
        }

    parsed_surface_paths = parse_helper_surface_paths(
        restore_helper.read_text(encoding="utf-8")
    )
    parsed_surface_path_set = set(parsed_surface_paths)

    for relative_path, purpose in REQUIRED_HELPER_SURFACE_PATHS:
        if not (repo_root / relative_path).is_file():
            missing_files.append({"path": relative_path, "purpose": purpose})
        if relative_path not in parsed_surface_path_set:
            missing_surface_paths.append({"path": relative_path, "purpose": purpose})

    return {
        "repo_root": str(repo_root),
        "restore_helper": str(restore_helper),
        "missing_restore_helper": False,
        "parsed_helper_surface_count": len(parsed_surface_paths),
        "missing_files": missing_files,
        "missing_surface_paths": missing_surface_paths,
        "ok": not missing_files and not missing_surface_paths,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether restore_saved_browser_snapshot.sh carries the newer "
            "issue #11 saved Zig and saved Rust helper surface needed for a "
            "self-contained synced restored checkout."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused self-tests and exit",
    )
    return parser


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Restore helper: {result['restore_helper']}")
    print(f"Parsed helper surface entries: {result['parsed_helper_surface_count']}")

    if result["missing_restore_helper"]:
        print()
        print("FAIL: restore_saved_browser_snapshot.sh is missing.")
        return

    missing_files = result["missing_files"]
    missing_surface_paths = result["missing_surface_paths"]

    if not missing_files and not missing_surface_paths:
        print()
        print(
            "Saved-snapshot helper surface covers the issue #11 Zig and Rust re-entry helpers."
        )
        return

    if missing_files:
        print()
        print("Missing helper files:")
        for entry in missing_files:
            print(f"  - {entry['path']} ({entry['purpose']})")

    if missing_surface_paths:
        print()
        print("Missing HELPER_SURFACE_PATHS entries:")
        for entry in missing_surface_paths:
            print(f"  - {entry['path']} ({entry['purpose']})")


def build_fixture_repo() -> Path:
    root = Path(tempfile.mkdtemp(prefix="lightpanda-saved-snapshot-surface-"))
    restore_helper = root / RESTORE_HELPER_RELATIVE_PATH
    restore_helper.parent.mkdir(parents=True, exist_ok=True)
    restore_helper.write_text(
        "\n".join(
            [
                "#!/usr/bin/env bash",
                'declare -a HELPER_SURFACE_PATHS=(',
                *[f'    "{path}"' for path, _purpose in REQUIRED_HELPER_SURFACE_PATHS],
                ")",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    for relative_path, _purpose in REQUIRED_HELPER_SURFACE_PATHS:
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("fixture\n", encoding="utf-8")

    return root


class SavedSnapshotHelperSurfaceTests(unittest.TestCase):
    def test_all_required_paths_present(self) -> None:
        repo_root = build_fixture_repo()
        result = collect_surface_state(repo_root)
        self.assertTrue(result["ok"])
        self.assertEqual(result["missing_files"], [])
        self.assertEqual(result["missing_surface_paths"], [])

    def test_missing_surface_entry_is_reported(self) -> None:
        repo_root = build_fixture_repo()
        restore_helper = repo_root / RESTORE_HELPER_RELATIVE_PATH
        restore_helper.write_text(
            "\n".join(
                [
                    "#!/usr/bin/env bash",
                    'declare -a HELPER_SURFACE_PATHS=(',
                    '    "docs/ISSUE3_SAVED_ZIG_ARCHIVE_CANDIDATES_ROUTE.md"',
                    ")",
                ]
            )
            + "\n",
            encoding="utf-8",
        )

        result = collect_surface_state(repo_root)

        self.assertFalse(result["ok"])
        missing_paths = {entry["path"] for entry in result["missing_surface_paths"]}
        self.assertIn(
            "scripts/check_issue3_saved_rust_archive_candidates.py", missing_paths
        )

    def test_missing_helper_file_is_reported(self) -> None:
        repo_root = build_fixture_repo()
        (repo_root / "scripts/check_issue3_staged_rust_toolchain_candidates.py").unlink()

        result = collect_surface_state(repo_root)

        self.assertFalse(result["ok"])
        missing_files = {entry["path"] for entry in result["missing_files"]}
        self.assertIn(
            "scripts/check_issue3_staged_rust_toolchain_candidates.py", missing_files
        )


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedSnapshotHelperSurfaceTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    result = collect_surface_state(repo_root)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
