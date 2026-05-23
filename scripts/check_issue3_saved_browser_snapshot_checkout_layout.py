#!/usr/bin/env python3

"""Detect the real checkout root inside a restored saved browser snapshot."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"
EXPECTED_NESTED_DIR_NAME = "browser-fork-headed-mode-foundation"
REQUIRED_HELPER_PATHS: tuple[str, ...] = (
    "scripts/check_issue3_saved_memory_inputs.py",
    "scripts/check_linux_build_readiness.py",
    "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
    "scripts/linux/restore_saved_browser_snapshot.sh",
    "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
    "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
    "scripts/linux/show_issue3_linux_build_readiness_route.sh",
    "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
    "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Resolve the real checkout root inside a restored saved browser snapshot "
            "before running the Linux or WSL build-readiness helpers."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--restored-checkout-root",
        default=None,
        help=(
            "Path to the restored snapshot root to inspect "
            "(default: ../browser-memory-snapshot beside a live checkout, "
            "or ./browser-memory-snapshot from a plain workspace)"
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


def resolve_default_restored_checkout_root(repo_root: Path) -> Path:
    if (repo_root / "build.zig.zon").is_file():
        return (repo_root.parent / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()
    return (repo_root / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()


def detect_checkout_layout(restored_checkout_root: Path) -> tuple[Path, str]:
    if not restored_checkout_root.is_dir():
        return restored_checkout_root, "missing"
    if (restored_checkout_root / "build.zig.zon").is_file():
        return restored_checkout_root, "direct"

    child_dirs = sorted(path for path in restored_checkout_root.iterdir() if path.is_dir())
    if len(child_dirs) != 1:
        return restored_checkout_root, "unresolved"

    nested_root = child_dirs[0]
    if (nested_root / "build.zig.zon").is_file():
        if nested_root.name == EXPECTED_NESTED_DIR_NAME:
            return nested_root, "nested-archive-root"
        return nested_root, "nested-single-child"
    return restored_checkout_root, "unresolved"


def collect_result(restored_checkout_root: Path) -> dict[str, object]:
    resolved_checkout_root, layout = detect_checkout_layout(restored_checkout_root)
    exists = restored_checkout_root.is_dir()
    has_build_manifest = (resolved_checkout_root / "build.zig.zon").is_file()
    helper_checks = [
        {
            "path": relative_path,
            "exists": (resolved_checkout_root / relative_path).is_file(),
        }
        for relative_path in REQUIRED_HELPER_PATHS
    ]
    missing_helper_paths = [entry["path"] for entry in helper_checks if not entry["exists"]]
    has_helper_surface = exists and has_build_manifest and not missing_helper_paths

    if not exists:
        status = "missing"
    elif has_build_manifest and has_helper_surface:
        status = "ready"
    else:
        status = "incomplete"

    return {
        "requested_root": str(restored_checkout_root),
        "resolved_root": str(resolved_checkout_root),
        "layout": layout,
        "exists": exists,
        "has_build_manifest": has_build_manifest,
        "has_helper_surface": has_helper_surface,
        "helper_checks": helper_checks,
        "missing_helper_paths": missing_helper_paths,
        "status": status,
        "suggested_override": (
            f"--restored-checkout-root {resolved_checkout_root}" if exists and resolved_checkout_root != restored_checkout_root else None
        ),
    }


def emit_text(result: dict[str, object]) -> None:
    status_label = {
        "ready": "PASS",
        "incomplete": "WARN",
        "missing": "WARN",
    }[result["status"]]
    print(f"Requested snapshot root: {result['requested_root']}")
    print(f"Resolved checkout root:  {result['resolved_root']}")
    print(f"Layout:                  {result['layout']}")
    print(f"Build manifest:          {'yes' if result['has_build_manifest'] else 'no'}")
    print(f"Helper surface:          {'yes' if result['has_helper_surface'] else 'no'}")
    print(f"Snapshot status:         [{status_label}] {result['status']}")
    if result["suggested_override"]:
        print("")
        print("Suggested override:")
        print(f"  {result['suggested_override']}")
    if result["missing_helper_paths"]:
        print("")
        print("Missing helper paths:")
        for relative_path in result["missing_helper_paths"]:
            print(f"  - {relative_path}")
    if result["status"] == "ready":
        print("")
        print("Saved snapshot checkout layout looks ready.")
    elif result["layout"] == "nested-archive-root":
        print("")
        print(
            "The saved zip was extracted with its original top-level folder intact. "
            "Use the resolved checkout root above when calling the saved-memory and build-readiness helpers."
        )
    elif result["status"] == "missing":
        print("")
        print("Restore the saved browser snapshot before reopening the Linux or WSL build route.")


class SavedBrowserSnapshotCheckoutLayoutTests(unittest.TestCase):
    def test_missing_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir) / DEFAULT_RESTORED_CHECKOUT_NAME
            result = collect_result(root)
            self.assertEqual(result["layout"], "missing")
            self.assertEqual(result["status"], "missing")

    def test_direct_checkout_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir) / DEFAULT_RESTORED_CHECKOUT_NAME
            root.mkdir()
            (root / "build.zig.zon").write_text("{}", encoding="utf-8")
            for relative_path in REQUIRED_HELPER_PATHS:
                target = root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("pass", encoding="utf-8")
            result = collect_result(root)
            self.assertEqual(result["layout"], "direct")
            self.assertEqual(result["status"], "ready")
            self.assertIsNone(result["suggested_override"])

    def test_nested_archive_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir) / DEFAULT_RESTORED_CHECKOUT_NAME
            nested = root / EXPECTED_NESTED_DIR_NAME
            nested.mkdir(parents=True)
            (nested / "build.zig.zon").write_text("{}", encoding="utf-8")
            for relative_path in REQUIRED_HELPER_PATHS:
                target = nested / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("pass", encoding="utf-8")
            result = collect_result(root)
            self.assertEqual(result["layout"], "nested-archive-root")
            self.assertEqual(result["status"], "ready")
            self.assertEqual(result["resolved_root"], str(nested))
            self.assertEqual(result["suggested_override"], f"--restored-checkout-root {nested}")

    def test_nested_archive_root_can_still_be_incomplete(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir) / DEFAULT_RESTORED_CHECKOUT_NAME
            nested = root / EXPECTED_NESTED_DIR_NAME
            nested.mkdir(parents=True)
            (nested / "build.zig.zon").write_text("{}", encoding="utf-8")
            result = collect_result(root)
            self.assertEqual(result["layout"], "nested-archive-root")
            self.assertEqual(result["status"], "incomplete")
            self.assertTrue(result["missing_helper_paths"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            SavedBrowserSnapshotCheckoutLayoutTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    restored_checkout_root = (
        Path(args.restored_checkout_root).resolve()
        if args.restored_checkout_root
        else resolve_default_restored_checkout_root(repo_root)
    )
    result = collect_result(restored_checkout_root)
    if args.json:
        print(json.dumps({"profile": "issue3-saved-browser-snapshot-checkout-layout", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["status"] == "ready" else 1


if __name__ == "__main__":
    sys.exit(main())
