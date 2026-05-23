#!/usr/bin/env python3

"""Compare a restored issue #3 snapshot checkout with a live helper surface.

The saved browser snapshot can lag the current branch-local issue #3 route
helpers. This checker gives Linux/WSL restore flows one fast way to decide
whether it is safe to switch follow-up commands into the restored checkout, or
whether they should stay anchored to the live helper root until the helper
surface is synced.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest


DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"
HELPER_SURFACE_PATHS: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry gate note"),
    ("docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md", "saved snapshot restore note"),
    ("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness note"),
    ("scripts/check_issue3_saved_memory_inputs.py", "saved-Memory preflight helper"),
    ("scripts/check_issue3_saved_archive_integrity.py", "saved-archive integrity helper"),
    ("scripts/check_linux_build_readiness.py", "Linux build-readiness helper"),
    (
        "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "saved snapshot route surface checker",
    ),
    ("scripts/linux/restore_saved_browser_snapshot.sh", "saved snapshot restore helper"),
    ("scripts/linux/show_issue3_saved_browser_snapshot_route.sh", "saved snapshot route printer"),
    (
        "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "Linux build-readiness surface checker",
    ),
    (
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "Linux build-readiness route printer",
    ),
    (
        "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
        "runtime re-entry surface checker",
    ),
    (
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
        "runtime re-entry route printer",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Compare the restored issue #3 snapshot helper surface against a live "
            "browser checkout before switching Linux/WSL follow-up commands into "
            "the restored checkout."
        )
    )
    parser.add_argument(
        "--helper-root",
        default=".",
        help="Path to the live helper root checkout (default: current directory)",
    )
    parser.add_argument(
        "--restored-root",
        default=None,
        help=(
            "Path to the restored snapshot checkout "
            "(default: ../browser-memory-snapshot beside the helper root)"
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


def resolve_default_restored_root(helper_root: Path) -> Path:
    return (helper_root.parent / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()


def sha256_for_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_file_result(helper_root: Path, restored_root: Path, relative_path: str, label: str) -> dict[str, object]:
    helper_path = (helper_root / relative_path).resolve()
    restored_path = (restored_root / relative_path).resolve()
    helper_exists = helper_path.is_file()
    restored_exists = restored_path.is_file()
    helper_sha = sha256_for_file(helper_path) if helper_exists else None
    restored_sha = sha256_for_file(restored_path) if restored_exists else None

    if helper_exists and restored_exists and helper_sha == restored_sha:
        status = "match"
    elif helper_exists and restored_exists:
        status = "drift"
    elif helper_exists:
        status = "missing-from-restored"
    elif restored_exists:
        status = "missing-from-helper-root"
    else:
        status = "missing-from-both"

    return {
        "relative_path": relative_path,
        "label": label,
        "helper_path": str(helper_path),
        "restored_path": str(restored_path),
        "helper_exists": helper_exists,
        "restored_exists": restored_exists,
        "helper_sha256": helper_sha,
        "restored_sha256": restored_sha,
        "status": status,
    }


def collect_results(helper_root: Path, restored_root: Path) -> dict[str, object]:
    file_results = [
        build_file_result(helper_root, restored_root, relative_path, label)
        for relative_path, label in HELPER_SURFACE_PATHS
    ]

    drifted_files = [entry["relative_path"] for entry in file_results if entry["status"] == "drift"]
    missing_from_restored = [
        entry["relative_path"] for entry in file_results if entry["status"] == "missing-from-restored"
    ]
    missing_from_helper_root = [
        entry["relative_path"] for entry in file_results if entry["status"] == "missing-from-helper-root"
    ]
    missing_from_both = [entry["relative_path"] for entry in file_results if entry["status"] == "missing-from-both"]

    helper_root_ready = helper_root.is_dir()
    restored_root_ready = restored_root.is_dir() and (restored_root / "build.zig.zon").is_file()
    helper_surface_match = not drifted_files and not missing_from_restored and not missing_from_helper_root

    ok = helper_root_ready and restored_root_ready and helper_surface_match and not missing_from_both

    if not helper_root_ready:
        summary = "live helper root is missing"
    elif not restored_root.is_dir():
        summary = "restored checkout is missing"
    elif not (restored_root / "build.zig.zon").is_file():
        summary = "restored checkout exists but is missing build.zig.zon"
    elif helper_surface_match:
        summary = "restored helper surface matches the live helper root"
    else:
        summary = "restored helper surface differs from the live helper root"

    return {
        "ok": ok,
        "helper_root": str(helper_root),
        "restored_root": str(restored_root),
        "helper_root_ready": helper_root_ready,
        "restored_root_ready": restored_root_ready,
        "helper_surface_match": helper_surface_match,
        "drifted_files": drifted_files,
        "missing_from_restored": missing_from_restored,
        "missing_from_helper_root": missing_from_helper_root,
        "missing_from_both": missing_from_both,
        "summary": summary,
        "file_results": file_results,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Live helper root: {result['helper_root']}")
    print(f"Restored root:    {result['restored_root']}")
    print(f"Summary:          {result['summary']}")
    print("")
    print("Helper surface comparison:")
    for entry in result["file_results"]:
        status = {
            "match": "PASS",
            "drift": "WARN",
            "missing-from-restored": "WARN",
            "missing-from-helper-root": "WARN",
            "missing-from-both": "FAIL",
        }[entry["status"]]
        print(f"  [{status}] {entry['relative_path']}")
        print(f"         {entry['label']}")

    if result["ok"]:
        print("\nRestored helper surface drift check passed.")
        return

    print("\nRestored helper surface drift check found follow-up risk.", file=sys.stderr)
    print(
        "Suggested next step: keep follow-up helpers anchored to the live helper root "
        "or rerun the restore with --sync-helper-surface before switching into the "
        "restored checkout.",
        file=sys.stderr,
    )


class RestoredHelperSurfaceDriftTests(unittest.TestCase):
    def _write_helper_surface(self, root: Path, *, suffix: str = "") -> None:
        (root / "build.zig.zon").write_text("{}", encoding="utf-8")
        for relative_path, _label in HELPER_SURFACE_PATHS:
            target = root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(f"{relative_path}{suffix}", encoding="utf-8")

    def test_collect_results_passes_when_surfaces_match(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace = Path(tmpdir)
            helper_root = workspace / "browser"
            restored_root = workspace / DEFAULT_RESTORED_CHECKOUT_NAME
            helper_root.mkdir()
            restored_root.mkdir()
            self._write_helper_surface(helper_root)
            self._write_helper_surface(restored_root)

            result = collect_results(helper_root, restored_root)

            self.assertTrue(result["ok"])
            self.assertTrue(result["helper_surface_match"])
            self.assertEqual(result["drifted_files"], [])

    def test_collect_results_flags_drift_and_missing_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace = Path(tmpdir)
            helper_root = workspace / "browser"
            restored_root = workspace / DEFAULT_RESTORED_CHECKOUT_NAME
            helper_root.mkdir()
            restored_root.mkdir()
            self._write_helper_surface(helper_root)
            self._write_helper_surface(restored_root)

            drift_target = restored_root / HELPER_SURFACE_PATHS[0][0]
            drift_target.write_text("drifted", encoding="utf-8")
            missing_target = restored_root / HELPER_SURFACE_PATHS[1][0]
            missing_target.unlink()

            result = collect_results(helper_root, restored_root)

            self.assertFalse(result["ok"])
            self.assertIn(HELPER_SURFACE_PATHS[0][0], result["drifted_files"])
            self.assertIn(HELPER_SURFACE_PATHS[1][0], result["missing_from_restored"])
            self.assertFalse(result["helper_surface_match"])

    def test_collect_results_requires_restored_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace = Path(tmpdir)
            helper_root = workspace / "browser"
            restored_root = workspace / DEFAULT_RESTORED_CHECKOUT_NAME
            helper_root.mkdir()
            restored_root.mkdir()
            self._write_helper_surface(helper_root)
            self._write_helper_surface(restored_root)
            (restored_root / "build.zig.zon").unlink()

            result = collect_results(helper_root, restored_root)

            self.assertFalse(result["ok"])
            self.assertFalse(result["restored_root_ready"])
            self.assertEqual(result["summary"], "restored checkout exists but is missing build.zig.zon")


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(RestoredHelperSurfaceDriftTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    helper_root = Path(args.helper_root).resolve()
    restored_root = (
        Path(args.restored_root).resolve() if args.restored_root else resolve_default_restored_root(helper_root)
    )

    result = collect_results(helper_root, restored_root)
    if args.json:
        print(json.dumps({"profile": "issue3-restored-helper-surface-drift", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
