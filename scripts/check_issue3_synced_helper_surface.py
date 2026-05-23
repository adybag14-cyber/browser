#!/usr/bin/env python3

"""Check whether a restored checkout has the synced issue #3 helper surface."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import tempfile
import unittest


SYNCED_HELPER_SURFACE_FILES: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "runtime re-entry gate note"),
    (
        "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        "runtime revalidation note",
    ),
    (
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "saved browser snapshot route note",
    ),
    (
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "Linux build-readiness route note",
    ),
    (
        "docs/ISSUE3_ZIG_TOOLCHAIN_RECOVERY_ROUTE.md",
        "Zig toolchain recovery route note",
    ),
    (
        "docs/ISSUE3_OFFLINE_BUILD_INPUTS_ROUTE.md",
        "offline build-inputs route note",
    ),
    (
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
        "saved Rust toolchain route note",
    ),
    (
        "scripts/check_issue3_saved_memory_inputs.py",
        "saved Memory input preflight helper",
    ),
    (
        "scripts/check_linux_build_readiness.py",
        "Linux build-readiness helper",
    ),
    (
        "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "saved-browser-snapshot surface checker",
    ),
    (
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "saved-browser-snapshot route printer",
    ),
    (
        "scripts/linux/restore_saved_browser_snapshot.sh",
        "saved-browser-snapshot restore helper",
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
        "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
        "runtime revalidation surface checker",
    ),
    (
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
        "runtime revalidation route printer",
    ),
    (
        "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
        "Zig recovery surface checker",
    ),
    (
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        "Zig recovery route printer",
    ),
    (
        "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
        "saved Rust surface checker",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
        "saved Rust route printer",
    ),
    (
        "scripts/linux/restore_saved_rust_toolchain.sh",
        "saved Rust restore helper",
    ),
    (
        "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
        "offline build-inputs surface checker",
    ),
    (
        "scripts/linux/show_issue3_offline_build_inputs_route.sh",
        "offline build-inputs route printer",
    ),
    (
        "scripts/linux/prepare_offline_build_inputs.sh",
        "offline build-inputs restore helper",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that a restored checkout already carries the full synced "
            "issue #3 helper surface before Linux/WSL recovery relies on it."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the restored browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--helper-root",
        default=None,
        help=(
            "Optional live helper-root checkout to compare against. When set, "
            "the checker also verifies that the synced helper files match the "
            "live helper surface byte-for-byte."
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


def collect_results(repo_root: Path, helper_root: Path | None = None) -> dict[str, object]:
    build_manifest = repo_root / "build.zig.zon"
    entries = []
    missing_paths: list[str] = []
    missing_helper_source_paths: list[str] = []
    mismatched_paths: list[str] = []

    for relative_path, label in SYNCED_HELPER_SURFACE_FILES:
        repo_path = repo_root / relative_path
        repo_exists = repo_path.is_file()
        helper_path = helper_root / relative_path if helper_root else None
        helper_exists = helper_path.is_file() if helper_path else None
        content_matches = None

        if not repo_exists:
            missing_paths.append(relative_path)

        if helper_path:
            if not helper_exists:
                missing_helper_source_paths.append(relative_path)
            elif repo_exists:
                content_matches = repo_path.read_bytes() == helper_path.read_bytes()
                if not content_matches:
                    mismatched_paths.append(relative_path)

        entries.append(
            {
                "label": label,
                "path": str(repo_path),
                "relative_path": relative_path,
                "exists": repo_exists,
                "helper_root_path": str(helper_path) if helper_path else None,
                "helper_root_exists": helper_exists,
                "matches_helper_root": content_matches,
            }
        )

    ok = build_manifest.is_file() and not missing_paths
    if helper_root is not None:
        ok = ok and not missing_helper_source_paths and not mismatched_paths

    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "helper_root": str(helper_root) if helper_root else None,
        "build_manifest": {
            "path": str(build_manifest),
            "exists": build_manifest.is_file(),
        },
        "expected_file_count": len(SYNCED_HELPER_SURFACE_FILES),
        "helper_surface_files": entries,
        "missing_helper_surface_files": missing_paths,
        "missing_helper_source_files": missing_helper_source_paths,
        "mismatched_helper_surface_files": mismatched_paths,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    if result["helper_root"]:
        print(f"Helper root: {result['helper_root']}")

    build_manifest = result["build_manifest"]
    build_status = "PASS" if build_manifest["exists"] else "FAIL"
    print(f"Build manifest: [{build_status}] {build_manifest['path']}")
    print("Synced helper surface:")
    for entry in result["helper_surface_files"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['relative_path']}")
        print(f"         {entry['label']}")
        if entry["helper_root_path"]:
            helper_status = "PASS" if entry["helper_root_exists"] else "FAIL"
            print(
                "         "
                f"live helper source [{helper_status}] {entry['helper_root_path']}"
            )
            if entry["helper_root_exists"] and entry["exists"]:
                compare_status = (
                    "PASS" if entry["matches_helper_root"] else "FAIL"
                )
                print(
                    "         "
                    f"synced content match [{compare_status}]"
                )

    if result["ok"]:
        print("\nIssue #3 synced helper surface check passed.")
        return

    print("\nIssue #3 synced helper surface check failed.")
    missing = ", ".join(result["missing_helper_surface_files"])
    if missing:
        print(f"Missing synced files: {missing}")
    missing_source = ", ".join(result["missing_helper_source_files"])
    if missing_source:
        print(f"Missing live helper files: {missing_source}")
    mismatched = ", ".join(result["mismatched_helper_surface_files"])
    if mismatched:
        print(f"Mismatched synced files: {mismatched}")


class SyncedHelperSurfaceTests(unittest.TestCase):
    def _populate_surface(self, root: Path, payload: str = "x") -> None:
        (root / "build.zig.zon").write_text("{}", encoding="utf-8")
        for relative_path, _label in SYNCED_HELPER_SURFACE_FILES:
            target = root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(f"{payload}:{relative_path}", encoding="utf-8")

    def test_collect_results_passes_when_all_surface_files_exist(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self._populate_surface(repo_root)

            result = collect_results(repo_root)

            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_helper_surface_files"], [])
            self.assertEqual(
                result["expected_file_count"],
                len(SYNCED_HELPER_SURFACE_FILES),
            )

    def test_collect_results_fails_when_helper_file_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self._populate_surface(repo_root)
            (repo_root / SYNCED_HELPER_SURFACE_FILES[0][0]).unlink()

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertEqual(
                result["missing_helper_surface_files"],
                [SYNCED_HELPER_SURFACE_FILES[0][0]],
            )

    def test_collect_results_fails_when_build_manifest_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            for relative_path, _label in SYNCED_HELPER_SURFACE_FILES:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("x", encoding="utf-8")

            result = collect_results(repo_root)

            self.assertFalse(result["ok"])
            self.assertTrue(result["build_manifest"]["path"].endswith("build.zig.zon"))

    def test_collect_results_passes_when_helper_root_matches(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "restored"
            helper_root = root / "live"
            repo_root.mkdir()
            helper_root.mkdir()
            self._populate_surface(repo_root, payload="shared")
            self._populate_surface(helper_root, payload="shared")

            result = collect_results(repo_root, helper_root)

            self.assertTrue(result["ok"])
            self.assertEqual(result["missing_helper_source_files"], [])
            self.assertEqual(result["mismatched_helper_surface_files"], [])

    def test_collect_results_fails_when_helper_root_file_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "restored"
            helper_root = root / "live"
            repo_root.mkdir()
            helper_root.mkdir()
            self._populate_surface(repo_root, payload="shared")
            self._populate_surface(helper_root, payload="shared")
            (helper_root / SYNCED_HELPER_SURFACE_FILES[1][0]).unlink()

            result = collect_results(repo_root, helper_root)

            self.assertFalse(result["ok"])
            self.assertEqual(
                result["missing_helper_source_files"],
                [SYNCED_HELPER_SURFACE_FILES[1][0]],
            )

    def test_collect_results_fails_when_helper_root_content_drifts(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "restored"
            helper_root = root / "live"
            repo_root.mkdir()
            helper_root.mkdir()
            self._populate_surface(repo_root, payload="shared")
            self._populate_surface(helper_root, payload="shared")
            drift_path = helper_root / SYNCED_HELPER_SURFACE_FILES[2][0]
            drift_path.write_text("drift", encoding="utf-8")

            result = collect_results(repo_root, helper_root)

            self.assertFalse(result["ok"])
            self.assertEqual(
                result["mismatched_helper_surface_files"],
                [SYNCED_HELPER_SURFACE_FILES[2][0]],
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SyncedHelperSurfaceTests
        )
        outcome = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if outcome.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    helper_root = Path(args.helper_root).resolve() if args.helper_root else None
    result = collect_results(repo_root, helper_root)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
