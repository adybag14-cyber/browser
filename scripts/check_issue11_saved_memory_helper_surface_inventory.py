#!/usr/bin/env python3

"""Check saved-memory helper inventory drift against the restore helper surface.

This helper is intentionally narrow. It compares the explicit helper inventory
inside `scripts/check_issue3_saved_memory_inputs.py` with the live
`HELPER_SURFACE_PATHS` declared by
`scripts/linux/restore_saved_browser_snapshot.sh`.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest


FILES = {
    "saved_memory_helper": "scripts/check_issue3_saved_memory_inputs.py",
    "restore_helper": "scripts/linux/restore_saved_browser_snapshot.sh",
}

ALLOWED_SAVED_MEMORY_ONLY = {
    "scripts/check_linux_build_readiness.py",
    "scripts/windows/HeadedValidationHelpers.ps1",
}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the issue #3 saved-memory preflight inventory still "
            "matches the restore helper surface."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser repo root (default: current directory)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def read_text(repo_root: Path, key: str) -> str:
    return (repo_root / FILES[key]).read_text(encoding="utf-8")


def extract_saved_memory_paths(text: str) -> list[str]:
    match = re.search(
        r"BASE_REQUIRED_RESTORED_HELPER_FILES:.*?= \(\n(.*?)\n\)\n\n\ndef build_parser",
        text,
        re.S,
    )
    if not match:
        raise ValueError("Could not find BASE_REQUIRED_RESTORED_HELPER_FILES")
    return re.findall(r'\("([^"]+)",', match.group(1))


def extract_restore_helper_paths(text: str) -> list[str]:
    match = re.search(r"declare -a HELPER_SURFACE_PATHS=\(\n(.*?)\n\)", text, re.S)
    if not match:
        raise ValueError("Could not find HELPER_SURFACE_PATHS")
    return re.findall(r'"([^"]+)"', match.group(1))


def collect_results(repo_root: Path) -> dict[str, object]:
    saved_memory_paths = extract_saved_memory_paths(read_text(repo_root, "saved_memory_helper"))
    restore_helper_paths = extract_restore_helper_paths(read_text(repo_root, "restore_helper"))

    saved_memory_set = set(saved_memory_paths)
    restore_helper_set = set(restore_helper_paths)

    missing_from_saved_memory = sorted(
        path for path in restore_helper_paths if path not in saved_memory_set
    )
    saved_memory_only = sorted(
        path
        for path in saved_memory_paths
        if path not in restore_helper_set and path not in ALLOWED_SAVED_MEMORY_ONLY
    )

    return {
        "ok": not missing_from_saved_memory and not saved_memory_only,
        "repo_root": str(repo_root),
        "saved_memory_helper": FILES["saved_memory_helper"],
        "restore_helper": FILES["restore_helper"],
        "saved_memory_path_count": len(saved_memory_paths),
        "restore_helper_path_count": len(restore_helper_paths),
        "missing_from_saved_memory": missing_from_saved_memory,
        "saved_memory_only": saved_memory_only,
        "allowed_saved_memory_only": sorted(ALLOWED_SAVED_MEMORY_ONLY),
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Saved-memory helper: {result['saved_memory_helper']}")
    print(f"Restore helper: {result['restore_helper']}")
    print(f"Saved-memory paths: {result['saved_memory_path_count']}")
    print(f"Restore-helper paths: {result['restore_helper_path_count']}")

    if result["missing_from_saved_memory"]:
        print("Missing from saved-memory helper:")
        for path in result["missing_from_saved_memory"]:
            print(f"  - {path}")

    if result["saved_memory_only"]:
        print("Saved-memory-only paths:")
        for path in result["saved_memory_only"]:
            print(f"  - {path}")

    if result["ok"]:
        print("Saved-memory helper surface inventory check passed.")
    else:
        print("Saved-memory helper surface inventory check failed.", file=sys.stderr)


def build_fixture_repo(
    *,
    saved_memory_paths: list[str],
    restore_helper_paths: list[str],
) -> Path:
    repo_root = Path(tempfile.mkdtemp(prefix="issue11-saved-memory-surface-"))
    for relative_path in FILES.values():
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        if relative_path.endswith(".py"):
            target.write_text(
                "BASE_REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (\n"
                + "".join(f'    ("{path}", "label"),\n' for path in saved_memory_paths)
                + ")\n\n\ndef build_parser() -> None:\n    pass\n",
                encoding="utf-8",
            )
        else:
            target.write_text(
                "#!/usr/bin/env bash\n\ndeclare -a HELPER_SURFACE_PATHS=(\n"
                + "".join(f'    "{path}"\n' for path in restore_helper_paths)
                + ")\n",
                encoding="utf-8",
            )
    return repo_root


class Issue11SavedMemoryHelperSurfaceInventoryTests(unittest.TestCase):
    def test_extract_saved_memory_paths(self) -> None:
        paths = extract_saved_memory_paths(
            'BASE_REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (\n'
            '    ("docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md", "label"),\n'
            '    ("scripts/check_issue3_saved_zig_archive_candidates.py", "label"),\n'
            ')\n\n\ndef build_parser() -> None:\n    pass\n'
        )
        self.assertEqual(
            paths,
            [
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "scripts/check_issue3_saved_zig_archive_candidates.py",
            ],
        )

    def test_extract_restore_helper_paths(self) -> None:
        paths = extract_restore_helper_paths(
            '#!/usr/bin/env bash\n\ndeclare -a HELPER_SURFACE_PATHS=(\n'
            '    "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md"\n'
            '    "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh"\n'
            ')\n'
        )
        self.assertEqual(
            paths,
            [
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
            ],
        )

    def test_flags_restore_helper_paths_missing_from_saved_memory(self) -> None:
        repo_root = build_fixture_repo(
            saved_memory_paths=[
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "scripts/check_issue3_saved_zig_archive_candidates.py",
            ],
            restore_helper_paths=[
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
                "scripts/check_issue3_saved_zig_archive_candidates.py",
                "scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh",
            ],
        )

        result = collect_results(repo_root)

        self.assertFalse(result["ok"])
        self.assertEqual(
            result["missing_from_saved_memory"],
            [
                "docs/ISSUE3_STAGED_ZIG_TOOLCHAIN_CANDIDATES_ROUTE.md",
                "scripts/linux/check_issue3_staged_rust_toolchain_candidates_route_surface.sh",
            ],
        )

    def test_ignores_expected_saved_memory_only_paths(self) -> None:
        repo_root = build_fixture_repo(
            saved_memory_paths=[
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
                "scripts/check_linux_build_readiness.py",
                "scripts/windows/HeadedValidationHelpers.ps1",
            ],
            restore_helper_paths=[
                "docs/ISSUE3_PROGRESS_TRACKER_ROUTE.md",
            ],
        )

        result = collect_results(repo_root)

        self.assertTrue(result["ok"])
        self.assertEqual(result["saved_memory_only"], [])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            Issue11SavedMemoryHelperSurfaceInventoryTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    try:
        result = collect_results(repo_root)
    except FileNotFoundError as exc:
        print(f"Required helper file is missing: {exc.filename}", file=sys.stderr)
        return 1
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())