#!/usr/bin/env python3

"""Check whether a restored saved browser snapshot is fresh enough for issue #3 work."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


EXPECTED_REENTRY_FILES: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "issue #3 gate note"),
    ("docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md", "runtime revalidation note"),
    ("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness note"),
    ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved snapshot route note"),
    ("scripts/check_issue3_saved_memory_inputs.py", "saved Memory input preflight"),
    ("scripts/check_linux_build_readiness.py", "Linux build-readiness helper"),
    ("scripts/linux/restore_saved_browser_snapshot.sh", "saved snapshot restore helper"),
    (
        "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
        "Linux runtime re-entry surface checker",
    ),
    (
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
        "Linux runtime re-entry route printer",
    ),
    (
        "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "Linux build-readiness surface checker",
    ),
    (
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "Linux build-readiness route printer",
    ),
    (
        "scripts/windows/show_google_issue3_enter_submit_runtime_revalidation.ps1",
        "Windows runtime re-entry route printer",
    ),
)

CORE_BROWSER_FILES: tuple[tuple[str, str], ...] = (
    ("build.zig.zon", "build manifest"),
    ("src/browser/Page.zig", "Page runtime source"),
    ("src/display/win32_backend.zig", "Win32 runtime source"),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether a restored saved browser snapshot is fresh enough "
            "to trust for issue #3 route and runtime re-entry work."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the live browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--snapshot-root",
        default=None,
        help=(
            "Path to the restored saved browser snapshot "
            "(default: ../browser-memory-snapshot beside the repo workspace)"
        ),
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


def resolve_default_snapshot_root(repo_root: Path) -> Path:
    return (repo_root.parent / "browser-memory-snapshot").resolve()


def check_file(root: Path, relative_path: str, label: str) -> dict[str, object]:
    full_path = root / relative_path
    return {
        "label": label,
        "path": str(full_path),
        "relative_path": relative_path,
        "exists": full_path.is_file(),
    }


def collect_results(*, repo_root: Path, snapshot_root: Path) -> dict[str, object]:
    snapshot_exists = snapshot_root.is_dir()
    reentry_files = [
        check_file(snapshot_root, relative_path, label)
        for relative_path, label in EXPECTED_REENTRY_FILES
    ]
    core_files = [
        check_file(snapshot_root, relative_path, label)
        for relative_path, label in CORE_BROWSER_FILES
    ]
    missing_reentry = [entry for entry in reentry_files if not entry["exists"]]
    missing_core = [entry for entry in core_files if not entry["exists"]]
    return {
        "ok": snapshot_exists and not missing_reentry and not missing_core,
        "repo_root": str(repo_root),
        "snapshot_root": str(snapshot_root),
        "snapshot_exists": snapshot_exists,
        "reentry_files": reentry_files,
        "core_files": core_files,
        "missing_reentry_count": len(missing_reentry),
        "missing_core_count": len(missing_core),
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Snapshot root: {result['snapshot_root']}")

    if not result["snapshot_exists"]:
        print("\nSaved snapshot checkout is missing.", file=sys.stderr)
        print(
            "Suggested next step: restore the saved snapshot before using it for issue #3 route work.",
            file=sys.stderr,
        )
        return

    print("\nCore browser files:")
    for entry in result["core_files"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['label']}: {entry['relative_path']}")

    print("Issue #3 re-entry files:")
    for entry in result["reentry_files"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['label']}: {entry['relative_path']}")

    if result["ok"]:
        print("\nSaved snapshot surface check passed.")
        return

    print("\nSaved snapshot surface check failed.", file=sys.stderr)
    print(
        "Suggested next step: treat the restored snapshot as stale for issue #3 route inventory and use the live branch helpers instead.",
        file=sys.stderr,
    )


class SavedSnapshotSurfaceTests(unittest.TestCase):
    def test_default_snapshot_root_follows_workspace_layout(self) -> None:
        repo_root = Path("/tmp/workspace/browser")
        self.assertEqual(
            resolve_default_snapshot_root(repo_root),
            Path("/tmp/workspace/browser-memory-snapshot"),
        )

    def test_collect_results_passes_with_expected_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            snapshot_root = root / "browser-memory-snapshot"
            repo_root.mkdir()
            snapshot_root.mkdir()
            for relative_path, _label in EXPECTED_REENTRY_FILES + CORE_BROWSER_FILES:
                target = snapshot_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("x", encoding="utf-8")

            result = collect_results(repo_root=repo_root, snapshot_root=snapshot_root)

            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_reentry_count"], 0)
            self.assertEqual(result["missing_core_count"], 0)

    def test_collect_results_fails_when_snapshot_is_stale(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            snapshot_root = root / "browser-memory-snapshot"
            repo_root.mkdir()
            snapshot_root.mkdir()
            for relative_path, _label in CORE_BROWSER_FILES:
                target = snapshot_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("x", encoding="utf-8")

            result = collect_results(repo_root=repo_root, snapshot_root=snapshot_root)

            self.assertFalse(result["ok"])
            self.assertGreater(result["missing_reentry_count"], 0)

    def test_collect_results_fails_when_snapshot_root_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            snapshot_root = root / "browser-memory-snapshot"
            repo_root.mkdir()

            result = collect_results(repo_root=repo_root, snapshot_root=snapshot_root)

            self.assertFalse(result["ok"])
            self.assertFalse(result["snapshot_exists"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedSnapshotSurfaceTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    snapshot_root = Path(args.snapshot_root).resolve() if args.snapshot_root else resolve_default_snapshot_root(repo_root)

    result = collect_results(repo_root=repo_root, snapshot_root=snapshot_root)
    if args.json:
        print(json.dumps({"profile": "issue3-saved-snapshot-surface", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
