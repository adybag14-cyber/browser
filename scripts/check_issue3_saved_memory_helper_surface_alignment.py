#!/usr/bin/env python3

"""Compare the saved-memory helper surface with the restore helper surface."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
import sys
import tempfile
import textwrap
import unittest


SAVED_MEMORY_HELPER = "scripts/check_issue3_saved_memory_inputs.py"
RESTORE_HELPER = "scripts/linux/restore_saved_browser_snapshot.sh"

SAVED_MEMORY_BLOCK_RE = re.compile(
    r"REQUIRED_RESTORED_HELPER_FILES:\s*tuple\[tuple\[str, str\], \.\.\.\]\s*=\s*\((?P<body>.*?)\n\)",
    re.DOTALL,
)
RESTORE_HELPER_BLOCK_RE = re.compile(
    r"declare -a HELPER_SURFACE_PATHS=\((?P<body>.*?)\n\)",
    re.DOTALL,
)
PATH_ENTRY_RE = re.compile(r'"([^"\n]+)"')


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Compare the saved-memory helper inventory against the synced "
            "restore-helper surface for issue #3 Linux/WSL re-entry work."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Browser repo root that contains the compared helper files.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit a JSON report instead of line-oriented text.",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused parser tests and exit.",
    )
    return parser.parse_args()


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as exc:
        raise ValueError(f"Could not read {path}: {exc}") from exc


def extract_saved_memory_paths(path: Path) -> list[str]:
    match = SAVED_MEMORY_BLOCK_RE.search(read_text(path))
    if match is None:
        raise ValueError(f"Could not find REQUIRED_RESTORED_HELPER_FILES in {path}")
    return [
        value
        for value in PATH_ENTRY_RE.findall(match.group("body"))
        if "/" in value
    ]


def extract_restore_helper_paths(path: Path) -> list[str]:
    match = RESTORE_HELPER_BLOCK_RE.search(read_text(path))
    if match is None:
        raise ValueError(f"Could not find HELPER_SURFACE_PATHS in {path}")
    return [
        value
        for value in PATH_ENTRY_RE.findall(match.group("body"))
        if "/" in value
    ]


def build_report(repo_root: Path) -> dict[str, object]:
    saved_memory_path = repo_root / SAVED_MEMORY_HELPER
    restore_helper_path = repo_root / RESTORE_HELPER

    saved_memory_paths = extract_saved_memory_paths(saved_memory_path)
    restore_helper_paths = extract_restore_helper_paths(restore_helper_path)

    saved_memory_only = sorted(set(saved_memory_paths) - set(restore_helper_paths))
    restore_helper_only = sorted(set(restore_helper_paths) - set(saved_memory_paths))

    return {
        "profile": "issue3-saved-memory-helper-surface-alignment",
        "repo_root": str(repo_root),
        "saved_memory_helper": str(saved_memory_path),
        "restore_helper": str(restore_helper_path),
        "saved_memory_count": len(saved_memory_paths),
        "restore_helper_count": len(restore_helper_paths),
        "saved_memory_only": saved_memory_only,
        "restore_helper_only": restore_helper_only,
        "ok": not saved_memory_only and not restore_helper_only,
    }


def emit_text(report: dict[str, object]) -> None:
    print("Issue #3 saved-memory helper surface alignment")
    print()
    print(f"Repo root:            {report['repo_root']}")
    print(f"Saved-memory helper:  {report['saved_memory_helper']}")
    print(f"Restore helper:       {report['restore_helper']}")
    print(
        f"Inventory sizes:      saved-memory={report['saved_memory_count']}, "
        f"restore-helper={report['restore_helper_count']}"
    )

    if report["saved_memory_only"]:
        print("\nOnly in saved-memory helper:")
        for value in report["saved_memory_only"]:
            print(f"  - {value}")

    if report["restore_helper_only"]:
        print("\nOnly in restore helper:")
        for value in report["restore_helper_only"]:
            print(f"  - {value}")

    if report["ok"]:
        print("\nHelper inventories are aligned.")
    else:
        print(
            "\nHelper inventories are not aligned.",
            file=sys.stderr,
        )
        print(
            "Suggested next step: update the saved-memory helper surface or the "
            "restore helper surface so restored-checkout preflight and sync "
            "logic agree before the next Linux/WSL replay.",
            file=sys.stderr,
        )


class SavedMemoryHelperSurfaceAlignmentTests(unittest.TestCase):
    def test_reports_restore_only_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            scripts = root / "scripts"
            linux_scripts = scripts / "linux"
            linux_scripts.mkdir(parents=True, exist_ok=True)

            (scripts / "check_issue3_saved_memory_inputs.py").write_text(
                textwrap.dedent(
                    """
                    REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
                        ("docs/A.md", "A"),
                        ("scripts/B.py", "B"),
                    )
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )
            (linux_scripts / "restore_saved_browser_snapshot.sh").write_text(
                textwrap.dedent(
                    """
                    declare -a HELPER_SURFACE_PATHS=(
                        "docs/A.md"
                        "scripts/B.py"
                        "docs/C.md"
                    )
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )

            report = build_report(root)

            self.assertFalse(report["ok"])
            self.assertEqual(report["saved_memory_only"], [])
            self.assertEqual(report["restore_helper_only"], ["docs/C.md"])

    def test_reports_aligned_inventories(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            scripts = root / "scripts"
            linux_scripts = scripts / "linux"
            linux_scripts.mkdir(parents=True, exist_ok=True)

            (scripts / "check_issue3_saved_memory_inputs.py").write_text(
                textwrap.dedent(
                    """
                    REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
                        ("docs/A.md", "A"),
                        ("scripts/B.py", "B"),
                    )
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )
            (linux_scripts / "restore_saved_browser_snapshot.sh").write_text(
                textwrap.dedent(
                    """
                    declare -a HELPER_SURFACE_PATHS=(
                        "docs/A.md"
                        "scripts/B.py"
                    )
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )

            report = build_report(root)

            self.assertTrue(report["ok"])
            self.assertEqual(report["saved_memory_only"], [])
            self.assertEqual(report["restore_helper_only"], [])



def main() -> int:
    args = parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedMemoryHelperSurfaceAlignmentTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    try:
        report = build_report(repo_root)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
