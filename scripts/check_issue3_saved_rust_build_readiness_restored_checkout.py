#!/usr/bin/env python3

"""Check the saved-Rust build-readiness bridge surface in a restored checkout.

This helper is narrower than the broader saved-memory preflight. It focuses on
the issue #11 Rust bridge route files that future Linux or WSL re-entry runs
need after a saved browser snapshot has been restored into a reusable checkout.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest


REQUIRED_REPO_ROOT_FILE = "build.zig.zon"
DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"

RUST_BRIDGE_FILES: tuple[tuple[str, str], ...] = (
    (
        "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md",
        "saved-Rust build-readiness bridge note",
    ),
    (
        "docs/ISSUE3_SAVED_RUST_ARCHIVE_CANDIDATES_ROUTE.md",
        "saved Rust archive-candidate note",
    ),
    (
        "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
        "saved Rust toolchain route note",
    ),
    (
        "docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md",
        "Linux build-readiness route note",
    ),
    (
        "scripts/check_issue3_saved_rust_archive_candidates.py",
        "saved Rust archive-candidate helper",
    ),
    (
        "scripts/check_issue3_staged_rust_toolchain_candidates.py",
        "staged Rust toolchain-candidate helper",
    ),
    (
        "scripts/linux/check_issue3_saved_rust_build_readiness_route_surface.sh",
        "saved-Rust bridge surface checker",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
        "saved-Rust bridge route printer",
    ),
    (
        "scripts/linux/check_issue3_saved_rust_archive_candidates_route_surface.sh",
        "saved Rust archive-candidate surface checker",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_archive_candidates_route.sh",
        "saved Rust archive-candidate route printer",
    ),
    (
        "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
        "saved Rust toolchain surface checker",
    ),
    (
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
        "saved Rust toolchain route printer",
    ),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether a restored checkout still carries the saved-Rust "
            "build-readiness bridge surface needed for issue #11 re-entry."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the live browser helper checkout (default: current directory)",
    )
    parser.add_argument(
        "--restored-checkout-root",
        default=None,
        help=(
            "Path to the restored checkout to probe "
            f"(default: ../{DEFAULT_RESTORED_CHECKOUT_NAME} beside the repo root)"
        ),
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON instead of the human-readable summary",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused unit tests and exit",
    )
    return parser


def resolve_default_restored_checkout_root(repo_root: Path) -> Path:
    repo_root = repo_root.resolve()
    if (repo_root / REQUIRED_REPO_ROOT_FILE).is_file():
        return (repo_root.parent / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()
    return (repo_root / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()


def file_digest(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def collect_results(repo_root: Path, restored_checkout_root: Path) -> dict[str, object]:
    repo_root = repo_root.resolve()
    restored_checkout_root = restored_checkout_root.resolve()

    helper_root_ready = repo_root.is_dir() and (repo_root / REQUIRED_REPO_ROOT_FILE).is_file()
    restored_exists = restored_checkout_root.is_dir()
    restored_has_manifest = (restored_checkout_root / REQUIRED_REPO_ROOT_FILE).is_file()

    checked_files: list[dict[str, object]] = []
    drifted_files: list[str] = []
    missing_in_helper_root: list[str] = []
    missing_in_restored_checkout: list[str] = []

    for relative_path, label in RUST_BRIDGE_FILES:
        helper_path = repo_root / relative_path
        restored_path = restored_checkout_root / relative_path
        helper_exists = helper_path.is_file()
        restored_file_exists = restored_path.is_file()
        same_content = False
        if helper_exists and restored_file_exists:
            same_content = file_digest(helper_path) == file_digest(restored_path)
        if not helper_exists:
            missing_in_helper_root.append(relative_path)
        if not restored_file_exists:
            missing_in_restored_checkout.append(relative_path)
        if helper_exists and restored_file_exists and not same_content:
            drifted_files.append(relative_path)
        checked_files.append(
            {
                "label": label,
                "relative_path": relative_path,
                "helper_path": str(helper_path),
                "restored_path": str(restored_path),
                "helper_exists": helper_exists,
                "restored_exists": restored_file_exists,
                "same_content": same_content if helper_exists and restored_file_exists else None,
            }
        )

    ok = (
        helper_root_ready
        and restored_exists
        and restored_has_manifest
        and not missing_in_helper_root
        and not missing_in_restored_checkout
        and not drifted_files
    )

    if ok:
        status = "passed"
        next_step = None
    elif not helper_root_ready:
        status = "helper-root-invalid"
        next_step = "point --repo-root at a live browser checkout before trusting Rust bridge sync results"
    elif not restored_exists:
        status = "restored-checkout-missing"
        next_step = (
            "restore the saved browser snapshot before trusting the saved-Rust bridge route "
            f"inside {restored_checkout_root}"
        )
    elif not restored_has_manifest:
        status = "restored-checkout-invalid"
        next_step = "repair or replace the restored checkout before trusting its Rust bridge helper surface"
    elif missing_in_restored_checkout or drifted_files:
        status = "restored-checkout-out-of-sync"
        next_step = (
            "refresh the restored checkout helper surface with "
            "restore_saved_browser_snapshot.sh --sync-only before replaying the Rust bridge route"
        )
    else:
        status = "helper-root-out-of-contract"
        next_step = "repair the live helper checkout because one or more Rust bridge files are missing there"

    return {
        "status": status,
        "ok": ok,
        "repo_root": str(repo_root),
        "restored_checkout_root": str(restored_checkout_root),
        "helper_root_ready": helper_root_ready,
        "restored_checkout_exists": restored_exists,
        "restored_checkout_has_manifest": restored_has_manifest,
        "checked_files": checked_files,
        "missing_in_helper_root": missing_in_helper_root,
        "missing_in_restored_checkout": missing_in_restored_checkout,
        "drifted_files": drifted_files,
        "suggested_next_step": next_step,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Helper root: {result['repo_root']}")
    print(f"Restored checkout: {result['restored_checkout_root']}")
    print(
        "Status: "
        f"{result['status']} "
        f"[helper-root={'yes' if result['helper_root_ready'] else 'no'}, "
        f"restored={'yes' if result['restored_checkout_exists'] else 'no'}, "
        f"manifest={'yes' if result['restored_checkout_has_manifest'] else 'no'}]"
    )

    if result["missing_in_helper_root"]:
        print("Missing in helper root:")
        for relative_path in result["missing_in_helper_root"]:
            print(f"  - {relative_path}")

    if result["missing_in_restored_checkout"]:
        print("Missing in restored checkout:")
        for relative_path in result["missing_in_restored_checkout"]:
            print(f"  - {relative_path}")

    if result["drifted_files"]:
        print("Drifted files:")
        for relative_path in result["drifted_files"]:
            print(f"  - {relative_path}")

    if result["ok"]:
        print("Saved-Rust build-readiness bridge surface check passed.")
        return

    print("Saved-Rust build-readiness bridge surface check failed.", file=sys.stderr)
    if result["suggested_next_step"] is not None:
        print(f"Suggested next step: {result['suggested_next_step']}", file=sys.stderr)


class SavedRustBuildReadinessRestoredCheckoutTests(unittest.TestCase):
    def populate_surface(self, root: Path, content: str) -> None:
        (root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
        for relative_path, _label in RUST_BRIDGE_FILES:
            target = root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding="utf-8")

    def test_collect_results_passes_when_surface_is_synced(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "browser"
            restored_root = root / DEFAULT_RESTORED_CHECKOUT_NAME
            helper_root.mkdir()
            restored_root.mkdir()
            self.populate_surface(helper_root, "live")
            self.populate_surface(restored_root, "live")

            result = collect_results(helper_root, restored_root)

            self.assertTrue(result["ok"])
            self.assertEqual(result["status"], "passed")
            self.assertEqual(result["missing_in_restored_checkout"], [])
            self.assertEqual(result["drifted_files"], [])

    def test_collect_results_flags_missing_rust_bridge_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "browser"
            restored_root = root / DEFAULT_RESTORED_CHECKOUT_NAME
            helper_root.mkdir()
            restored_root.mkdir()
            self.populate_surface(helper_root, "live")
            (restored_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")

            keep_paths = {
                "docs/ISSUE3_SAVED_RUST_TOOLCHAIN_ROUTE.md",
                "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
            }
            for relative_path, _label in RUST_BRIDGE_FILES:
                if relative_path not in keep_paths:
                    continue
                target = restored_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("live", encoding="utf-8")

            result = collect_results(helper_root, restored_root)

            self.assertFalse(result["ok"])
            self.assertEqual(result["status"], "restored-checkout-out-of-sync")
            self.assertIn(
                "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md",
                result["missing_in_restored_checkout"],
            )
            self.assertIn(
                "scripts/check_issue3_saved_rust_archive_candidates.py",
                result["missing_in_restored_checkout"],
            )
            self.assertIn(
                "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
                result["missing_in_restored_checkout"],
            )

    def test_collect_results_flags_drifted_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "browser"
            restored_root = root / DEFAULT_RESTORED_CHECKOUT_NAME
            helper_root.mkdir()
            restored_root.mkdir()
            self.populate_surface(helper_root, "live")
            self.populate_surface(restored_root, "live")
            (
                restored_root / "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md"
            ).write_text("drifted", encoding="utf-8")

            result = collect_results(helper_root, restored_root)

            self.assertFalse(result["ok"])
            self.assertIn(
                "docs/ISSUE3_SAVED_RUST_BUILD_READINESS_ROUTE.md",
                result["drifted_files"],
            )

    def test_collect_results_flags_missing_restored_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "browser"
            helper_root.mkdir()
            self.populate_surface(helper_root, "live")

            result = collect_results(
                helper_root,
                root / DEFAULT_RESTORED_CHECKOUT_NAME,
            )

            self.assertFalse(result["ok"])
            self.assertEqual(result["status"], "restored-checkout-missing")

    def test_default_restored_checkout_root_uses_workspace_sibling(self) -> None:
        repo_root = Path("/tmp/workspace/browser")
        with tempfile.TemporaryDirectory() as tmpdir:
            rooted_repo = Path(tmpdir) / "workspace" / "browser"
            rooted_repo.mkdir(parents=True)
            (rooted_repo / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            self.assertEqual(
                resolve_default_restored_checkout_root(rooted_repo),
                rooted_repo.parent / DEFAULT_RESTORED_CHECKOUT_NAME,
            )

    def test_default_restored_checkout_root_nests_when_repo_manifest_is_missing(self) -> None:
        repo_root = Path("/tmp/workspace/browser")
        self.assertEqual(
            resolve_default_restored_checkout_root(repo_root),
            Path("/tmp/workspace/browser/browser-memory-snapshot"),
        )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedRustBuildReadinessRestoredCheckoutTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    restored_checkout_root = (
        Path(args.restored_checkout_root).resolve()
        if args.restored_checkout_root
        else resolve_default_restored_checkout_root(repo_root)
    )
    result = collect_results(repo_root, restored_checkout_root)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())