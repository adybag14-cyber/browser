#!/usr/bin/env python3

"""Check that issue #3 helper-surface definitions stay in sync."""

from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest


RESTORE_ARRAY_NAME = "HELPER_SURFACE_PATHS"
ARCHIVE_SENTINEL_PATHS = {"build.zig.zon"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Compare the issue #3 helper-surface path lists used by the restore, "
            "saved-memory, and saved-archive-surface helpers."
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
        help="Emit a JSON report instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser.parse_args()


def extract_restore_paths(script_text: str) -> set[str]:
    match = re.search(
        rf"declare -a {RESTORE_ARRAY_NAME}=\(\n(?P<body>.*?)\n\)",
        script_text,
        re.DOTALL,
    )
    if match is None:
        raise ValueError(f"Could not find {RESTORE_ARRAY_NAME} in restore helper")
    return set(re.findall(r'"([^"]+)"', match.group("body")))


def extract_python_path_list(source_text: str, constant_name: str) -> set[str]:
    module = ast.parse(source_text)
    for node in module.body:
        value = None
        if isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name) and node.target.id == constant_name:
            value = node.value
        elif isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name) and target.id == constant_name:
                    value = node.value
                    break
        if value is None:
            continue

        literal = ast.literal_eval(value)
        paths: set[str] = set()
        for entry in literal:
            if isinstance(entry, (list, tuple)) and entry and isinstance(entry[0], str):
                paths.add(entry[0])
        return paths
    raise ValueError(f"Could not find {constant_name} in Python helper")


def build_report(repo_root: Path) -> dict[str, object]:
    restore_paths = extract_restore_paths(
        (repo_root / "scripts/linux/restore_saved_browser_snapshot.sh").read_text(
            encoding="utf-8"
        )
    )
    saved_memory_paths = extract_python_path_list(
        (repo_root / "scripts/check_issue3_saved_memory_inputs.py").read_text(
            encoding="utf-8"
        ),
        "REQUIRED_RESTORED_HELPER_FILES",
    )
    archive_surface_paths = extract_python_path_list(
        (
            repo_root / "scripts/check_issue3_saved_browser_snapshot_archive_surface.py"
        ).read_text(encoding="utf-8"),
        "REQUIRED_PATHS",
    )

    archive_surface_helper_paths = archive_surface_paths - ARCHIVE_SENTINEL_PATHS

    pair_reports = []
    for left_name, left_paths, right_name, right_paths in (
        (
            "restore_saved_browser_snapshot.sh",
            restore_paths,
            "check_issue3_saved_memory_inputs.py",
            saved_memory_paths,
        ),
        (
            "restore_saved_browser_snapshot.sh",
            restore_paths,
            "check_issue3_saved_browser_snapshot_archive_surface.py",
            archive_surface_helper_paths,
        ),
        (
            "check_issue3_saved_memory_inputs.py",
            saved_memory_paths,
            "check_issue3_saved_browser_snapshot_archive_surface.py",
            archive_surface_helper_paths,
        ),
    ):
        left_only = sorted(left_paths - right_paths)
        right_only = sorted(right_paths - left_paths)
        pair_reports.append(
            {
                "left": left_name,
                "right": right_name,
                "left_only": left_only,
                "right_only": right_only,
                "matches": not left_only and not right_only,
            }
        )

    failures = [
        pair
        for pair in pair_reports
        if not pair["matches"]
    ]

    return {
        "status": "failed" if failures else "passed",
        "repo_root": str(repo_root),
        "restore_path_count": len(restore_paths),
        "saved_memory_path_count": len(saved_memory_paths),
        "archive_surface_path_count": len(archive_surface_helper_paths),
        "archive_surface_sentinel_paths": sorted(ARCHIVE_SENTINEL_PATHS & archive_surface_paths),
        "comparisons": pair_reports,
    }


def emit_text(report: dict[str, object]) -> None:
    print(f"Repo root: {report['repo_root']}")
    print(f"Restore helper paths: {report['restore_path_count']}")
    print(f"Saved-memory helper paths: {report['saved_memory_path_count']}")
    print(f"Archive-surface helper paths: {report['archive_surface_path_count']}")
    if report["archive_surface_sentinel_paths"]:
        print(
            "Archive-surface sentinels: "
            + ", ".join(report["archive_surface_sentinel_paths"])
        )
    for comparison in report["comparisons"]:
        status = "PASS" if comparison["matches"] else "FAIL"
        print(f"{comparison['left']} vs {comparison['right']}: [{status}]")
        if comparison["left_only"]:
            print("  left only: " + ", ".join(comparison["left_only"]))
        if comparison["right_only"]:
            print("  right only: " + ", ".join(comparison["right_only"]))
    if report["status"] == "passed":
        print("\nIssue #3 helper-surface contract check passed.")
    else:
        print("\nIssue #3 helper-surface contract check failed.", file=sys.stderr)
        print(
            "Suggested next step: add the missing helper paths to the drifting "
            "surface list before trusting restored-checkout or archive-surface "
            "preflights.",
            file=sys.stderr,
        )


class HelperSurfaceContractTests(unittest.TestCase):
    def write_fixture_files(
        self,
        root: Path,
        *,
        restore_paths: list[str],
        saved_memory_text: str,
        archive_surface_text: str,
    ) -> Path:
        repo_root = root / "browser"
        (repo_root / "scripts/linux").mkdir(parents=True)
        (repo_root / "scripts").mkdir(exist_ok=True)

        restore_text = "declare -a HELPER_SURFACE_PATHS=(\n" + "".join(
            f'    "{path}"\n' for path in restore_paths
        ) + ")\n"
        (repo_root / "scripts/linux/restore_saved_browser_snapshot.sh").write_text(
            restore_text,
            encoding="utf-8",
        )

        (repo_root / "scripts/check_issue3_saved_memory_inputs.py").write_text(
            saved_memory_text,
            encoding="utf-8",
        )

        (
            repo_root
            / "scripts/check_issue3_saved_browser_snapshot_archive_surface.py"
        ).write_text(archive_surface_text, encoding="utf-8")

        return repo_root

    def test_report_passes_when_lists_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = self.write_fixture_files(
                Path(tmpdir),
                restore_paths=["docs/A.md", "scripts/B.py"],
                saved_memory_text=
                    'REQUIRED_RESTORED_HELPER_FILES = (\n    ("docs/A.md", "label"),\n    ("scripts/B.py", "label"),\n)\n',
                archive_surface_text=
                    'REQUIRED_PATHS = [\n    ("build.zig.zon", "label"),\n    ("docs/A.md", "label"),\n    ("scripts/B.py", "label"),\n]\n',
            )
            report = build_report(repo_root)
            self.assertEqual(report["status"], "passed")
            self.assertEqual(report["archive_surface_sentinel_paths"], ["build.zig.zon"])
            self.assertTrue(all(pair["matches"] for pair in report["comparisons"]))

    def test_report_flags_missing_saved_memory_paths(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = self.write_fixture_files(
                Path(tmpdir),
                restore_paths=["docs/A.md", "scripts/B.py", "scripts/C.sh"],
                saved_memory_text=
                    'REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (\n    ("docs/A.md", "label"),\n    ("scripts/B.py", "label"),\n)\n',
                archive_surface_text=
                    'REQUIRED_PATHS = [\n    ("build.zig.zon", "label"),\n    ("docs/A.md", "label"),\n    ("scripts/B.py", "label"),\n    ("scripts/C.sh", "label"),\n]\n',
            )
            report = build_report(repo_root)
            self.assertEqual(report["status"], "failed")
            saved_memory_comparison = next(
                pair
                for pair in report["comparisons"]
                if pair["right"] == "check_issue3_saved_memory_inputs.py"
            )
            self.assertEqual(saved_memory_comparison["left_only"], ["scripts/C.sh"])
            self.assertEqual(saved_memory_comparison["right_only"], [])

    def test_extract_restore_paths_requires_array(self) -> None:
        with self.assertRaises(ValueError):
            extract_restore_paths("echo missing")

    def test_extract_python_path_list_supports_annotated_assignment(self) -> None:
        paths = extract_python_path_list(
            'REQUIRED_PATHS: tuple[tuple[str, str], ...] = (\n    ("docs/A.md", "A"),\n    ("scripts/B.py", "B"),\n)\n',
            "REQUIRED_PATHS",
        )
        self.assertEqual(paths, {"docs/A.md", "scripts/B.py"})

    def test_extract_python_path_list_requires_constant(self) -> None:
        with self.assertRaises(ValueError):
            extract_python_path_list("x = []", "REQUIRED_PATHS")


def main() -> int:
    args = parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            HelperSurfaceContractTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    report = build_report(repo_root)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
