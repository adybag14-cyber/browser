#!/usr/bin/env python3

"""Check that the saved-snapshot restore helper syncs the full issue #3 helper surface."""

from __future__ import annotations

import argparse
import ast
import json
from pathlib import Path
import re
import sys
import tempfile
import textwrap
import unittest


DEFAULT_MEMORY_INPUTS_SCRIPT = "scripts/check_issue3_saved_memory_inputs.py"
DEFAULT_RESTORE_SCRIPT = "scripts/linux/restore_saved_browser_snapshot.sh"
REPO_MARKER = "build.zig.zon"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that restore_saved_browser_snapshot.sh syncs every helper "
            "surface file required by check_issue3_saved_memory_inputs.py."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--memory-inputs-script",
        default=DEFAULT_MEMORY_INPUTS_SCRIPT,
        help="Path to the saved-memory preflight helper relative to --repo-root",
    )
    parser.add_argument(
        "--restore-script",
        default=DEFAULT_RESTORE_SCRIPT,
        help="Path to the saved-snapshot restore helper relative to --repo-root",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented output",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def resolve_script_path(repo_root: Path, relative_or_absolute: str) -> Path:
    candidate = Path(relative_or_absolute)
    return candidate.resolve() if candidate.is_absolute() else (repo_root / candidate).resolve()


def parse_required_restored_helper_files(script_path: Path) -> list[str]:
    content = script_path.read_text(encoding="utf-8")
    match = re.search(
        r"REQUIRED_RESTORED_HELPER_FILES:\s*tuple\[tuple\[str,\s*str\],\s*\.\.\.\]\s*=\s*\((.*?)\n\)",
        content,
        re.S,
    )
    if match is None:
        raise ValueError(f"Could not find REQUIRED_RESTORED_HELPER_FILES in {script_path}")
    literal = "(" + match.group(1) + "\n)"
    parsed = ast.literal_eval(literal)
    return [relative_path for relative_path, _label in parsed]


def parse_restore_helper_surface_paths(script_path: Path) -> list[str]:
    content = script_path.read_text(encoding="utf-8")
    match = re.search(
        r'declare -a HELPER_SURFACE_PATHS=\((.*?)\n\)',
        content,
        re.S,
    )
    if match is None:
        raise ValueError(f"Could not find HELPER_SURFACE_PATHS in {script_path}")
    return re.findall(r'"([^"]+)"', match.group(1))


def collect_results(
    repo_root: Path,
    memory_inputs_script: Path,
    restore_script: Path,
) -> dict[str, object]:
    repo_exists = repo_root.is_dir()
    repo_marker = repo_root / REPO_MARKER
    required_paths = parse_required_restored_helper_files(memory_inputs_script)
    restore_paths = parse_restore_helper_surface_paths(restore_script)
    required_set = set(required_paths)
    restore_set = set(restore_paths)
    missing_in_restore = sorted(required_set - restore_set)
    extra_in_restore = sorted(restore_set - required_set)

    return {
        "ok": repo_exists and repo_marker.is_file() and not missing_in_restore,
        "repo_root": str(repo_root),
        "repo_exists": repo_exists,
        "repo_marker": str(repo_marker),
        "repo_marker_exists": repo_marker.is_file(),
        "memory_inputs_script": str(memory_inputs_script),
        "restore_script": str(restore_script),
        "required_count": len(required_paths),
        "restore_count": len(restore_paths),
        "missing_in_restore": missing_in_restore,
        "extra_in_restore": extra_in_restore,
    }


def emit_text(result: dict[str, object]) -> None:
    status = "PASS" if result["ok"] else "FAIL"
    print(f"Saved snapshot helper surface sync: [{status}]")
    print(f"Repo root:             {result['repo_root']}")
    print(f"Saved-memory helper:   {result['memory_inputs_script']}")
    print(f"Snapshot restore:      {result['restore_script']}")
    print(f"Expected helper count: {result['required_count']}")
    print(f"Restore helper count:  {result['restore_count']}")
    if not result["repo_exists"]:
        print("Status detail: repo root is missing.")
    elif not result["repo_marker_exists"]:
        print(f"Status detail: expected repo marker is missing: {result['repo_marker']}")
    if result["missing_in_restore"]:
        print("Missing restore-sync paths:")
        for relative_path in result["missing_in_restore"]:
            print(f"  - {relative_path}")
    if result["extra_in_restore"]:
        print("Restore-only paths:")
        for relative_path in result["extra_in_restore"]:
            print(f"  - {relative_path}")
    if result["ok"]:
        print("Status detail: restore_saved_browser_snapshot.sh covers the full saved-memory helper surface.")


class SavedSnapshotHelperSurfaceTests(unittest.TestCase):
    def write_fixture_scripts(self, root: Path, *, missing_restore_entries: list[str] | None = None) -> tuple[Path, Path, Path]:
        repo_root = root / "browser"
        repo_root.mkdir()
        (repo_root / REPO_MARKER).write_text("{}", encoding="utf-8")

        memory_inputs_script = repo_root / DEFAULT_MEMORY_INPUTS_SCRIPT
        memory_inputs_script.parent.mkdir(parents=True, exist_ok=True)
        memory_inputs_script.write_text(
            textwrap.dedent(
                """
                REQUIRED_RESTORED_HELPER_FILES: tuple[tuple[str, str], ...] = (
                    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry guide"),
                    ("scripts/check_issue3_saved_memory_inputs.py", "saved-memory helper"),
                    ("scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh", "archive restore checker"),
                    ("tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py", "attached pages launcher"),
                )
                """
            ).strip()
            + "\n",
            encoding="utf-8",
        )

        restore_script = repo_root / DEFAULT_RESTORE_SCRIPT
        restore_script.parent.mkdir(parents=True, exist_ok=True)
        restore_entries = [
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "scripts/check_issue3_saved_memory_inputs.py",
            "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
            "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py",
        ]
        if missing_restore_entries:
            restore_entries = [entry for entry in restore_entries if entry not in missing_restore_entries]
        restore_script.write_text(
            "declare -a HELPER_SURFACE_PATHS=(\n"
            + "".join(f'    "{entry}"\n' for entry in restore_entries)
            + ")\n",
            encoding="utf-8",
        )
        return repo_root, memory_inputs_script, restore_script

    def test_collect_results_passes_when_sets_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root, memory_inputs_script, restore_script = self.write_fixture_scripts(Path(tmpdir))
            result = collect_results(repo_root, memory_inputs_script, restore_script)
            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_in_restore"], [])

    def test_collect_results_flags_missing_restore_entries(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root, memory_inputs_script, restore_script = self.write_fixture_scripts(
                Path(tmpdir),
                missing_restore_entries=[
                    "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
                    "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py",
                ],
            )
            result = collect_results(repo_root, memory_inputs_script, restore_script)
            self.assertFalse(result["ok"])
            self.assertEqual(
                result["missing_in_restore"],
                [
                    "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
                    "tmp-browser-smoke/attached-pages/start_attached_pages_catalog.py",
                ],
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedSnapshotHelperSurfaceTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    memory_inputs_script = resolve_script_path(repo_root, args.memory_inputs_script)
    restore_script = resolve_script_path(repo_root, args.restore_script)
    result = collect_results(repo_root, memory_inputs_script, restore_script)
    if args.json:
        print(json.dumps({"profile": "issue3-saved-snapshot-helper-surface", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
