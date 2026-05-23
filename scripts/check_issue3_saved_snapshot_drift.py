#!/usr/bin/env python3

"""Detect whether the saved browser snapshot lags the live issue #3 helper surface."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest
import zipfile


DEFAULT_SNAPSHOT = "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip"
DEFAULT_RESTORED_CHECKOUT = "browser-memory-snapshot"
DEFAULT_RESTORE_HELPER = "scripts/linux/restore_saved_browser_snapshot.sh"
ZIP_PREFIX = "browser-fork-headed-mode-foundation/"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the saved browser snapshot or restored checkout is "
            "missing helper files that the live issue #3 restore route now expects."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the live browser repo root (default: current directory)",
    )
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Path to the workspace memory root (default: ../memory beside the repo root)",
    )
    parser.add_argument(
        "--snapshot-zip",
        default=None,
        help="Explicit path to the saved repo snapshot zip (default: derive from --memory-root)",
    )
    parser.add_argument(
        "--restored-checkout-root",
        default=None,
        help=(
            "Optional path to the restored checkout to compare against the live helper surface "
            "(default: ../browser-memory-snapshot beside the repo root)"
        ),
    )
    parser.add_argument(
        "--restore-helper",
        default=None,
        help=(
            "Optional path to the live restore helper script that declares HELPER_SURFACE_PATHS "
            f"(default: {DEFAULT_RESTORE_HELPER} under --repo-root)"
        ),
    )
    parser.add_argument(
        "--mode",
        choices=("snapshot", "checkout", "both"),
        default="both",
        help="Which target to compare against the live helper surface (default: both)",
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


def resolve_default_memory_root(repo_root: Path) -> Path:
    return (repo_root.parent / "memory").resolve()


def resolve_default_snapshot_zip(memory_root: Path) -> Path:
    return (memory_root / DEFAULT_SNAPSHOT).resolve()


def resolve_default_restored_checkout(repo_root: Path) -> Path:
    return (repo_root.parent / DEFAULT_RESTORED_CHECKOUT).resolve()


def resolve_default_restore_helper(repo_root: Path) -> Path:
    return (repo_root / DEFAULT_RESTORE_HELPER).resolve()


def parse_helper_surface_paths(script_text: str) -> list[str]:
    match = re.search(
        r"declare\s+-a\s+HELPER_SURFACE_PATHS=\(\n(?P<body>.*?)\n\)",
        script_text,
        re.DOTALL,
    )
    if not match:
        raise ValueError("could not locate HELPER_SURFACE_PATHS in restore helper")

    paths: list[str] = []
    for raw_line in match.group("body").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        quoted = re.fullmatch(r'"(?P<path>[^"]+)"', line)
        if not quoted:
            raise ValueError(f"unexpected HELPER_SURFACE_PATHS entry: {raw_line!r}")
        paths.append(quoted.group("path"))
    if not paths:
        raise ValueError("HELPER_SURFACE_PATHS was empty")
    return paths


def inspect_zip_paths(snapshot_zip: Path, helper_paths: list[str]) -> dict[str, object]:
    result: dict[str, object] = {
        "path": str(snapshot_zip),
        "exists": snapshot_zip.is_file(),
        "missing_paths": [],
        "present_paths": [],
        "error": None,
    }
    if not result["exists"]:
        return result

    try:
        with zipfile.ZipFile(snapshot_zip) as archive:
            names = set(archive.namelist())
        present = [path for path in helper_paths if ZIP_PREFIX + path in names]
        missing = [path for path in helper_paths if ZIP_PREFIX + path not in names]
        result["present_paths"] = present
        result["missing_paths"] = missing
        return result
    except (zipfile.BadZipFile, OSError) as exc:
        result["error"] = str(exc)
        return result



def inspect_checkout_paths(restored_checkout_root: Path, helper_paths: list[str]) -> dict[str, object]:
    result: dict[str, object] = {
        "path": str(restored_checkout_root),
        "exists": restored_checkout_root.is_dir(),
        "missing_paths": [],
        "present_paths": [],
    }
    if not result["exists"]:
        return result

    present = [path for path in helper_paths if (restored_checkout_root / path).is_file()]
    missing = [path for path in helper_paths if not (restored_checkout_root / path).is_file()]
    result["present_paths"] = present
    result["missing_paths"] = missing
    return result



def collect_results(
    *,
    repo_root: Path,
    snapshot_zip: Path,
    restored_checkout_root: Path,
    restore_helper: Path,
    mode: str,
) -> dict[str, object]:
    restore_helper_text = restore_helper.read_text(encoding="utf-8")
    helper_paths = parse_helper_surface_paths(restore_helper_text)
    result: dict[str, object] = {
        "repo_root": str(repo_root),
        "restore_helper": str(restore_helper),
        "helper_surface_count": len(helper_paths),
        "helper_surface_paths": helper_paths,
        "mode": mode,
        "snapshot": None,
        "restored_checkout": None,
    }

    ok = True
    if mode in {"snapshot", "both"}:
        snapshot_result = inspect_zip_paths(snapshot_zip, helper_paths)
        result["snapshot"] = snapshot_result
        if (not snapshot_result["exists"]) or snapshot_result.get("error") or snapshot_result["missing_paths"]:
            ok = False
    if mode in {"checkout", "both"}:
        checkout_result = inspect_checkout_paths(restored_checkout_root, helper_paths)
        result["restored_checkout"] = checkout_result
        if (not checkout_result["exists"]) or checkout_result["missing_paths"]:
            ok = False

    result["ok"] = ok
    return result



def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Restore helper: {result['restore_helper']}")
    print(f"Live helper surface paths: {result['helper_surface_count']}")

    snapshot = result.get("snapshot")
    if snapshot is not None:
        status = "PASS"
        if not snapshot["exists"] or snapshot.get("error") or snapshot["missing_paths"]:
            status = "FAIL"
        print(f"\nSaved snapshot: [{status}] {snapshot['path']}")
        if snapshot.get("error"):
            print(f"  error: {snapshot['error']}")
        elif not snapshot["exists"]:
            print("  missing: saved repo snapshot zip was not found")
        else:
            print(f"  present helper paths: {len(snapshot['present_paths'])}")
            print(f"  missing helper paths: {len(snapshot['missing_paths'])}")
            for path in snapshot["missing_paths"]:
                print(f"    - {path}")

    checkout = result.get("restored_checkout")
    if checkout is not None:
        status = "PASS"
        if not checkout["exists"] or checkout["missing_paths"]:
            status = "FAIL"
        print(f"\nRestored checkout: [{status}] {checkout['path']}")
        if not checkout["exists"]:
            print("  missing: restored checkout directory was not found")
        else:
            print(f"  present helper paths: {len(checkout['present_paths'])}")
            print(f"  missing helper paths: {len(checkout['missing_paths'])}")
            for path in checkout["missing_paths"]:
                print(f"    - {path}")

    if result["ok"]:
        print("\nSaved snapshot helper surface is aligned with the live restore route.")
    else:
        print("\nSaved snapshot helper surface is stale or incomplete.", file=sys.stderr)
        print(
            "Suggested next step: use the synced restore route before relying on the restored checkout as its own helper root.",
            file=sys.stderr,
        )


class SavedSnapshotDriftTests(unittest.TestCase):
    def test_parse_helper_surface_paths(self) -> None:
        script = """
declare -a HELPER_SURFACE_PATHS=(
    \"docs/one.md\"
    \"scripts/two.sh\"
)
"""
        self.assertEqual(
            parse_helper_surface_paths(script),
            ["docs/one.md", "scripts/two.sh"],
        )

    def test_collect_results_detects_stale_snapshot(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "repo"
            repo_root.mkdir()
            restore_helper = repo_root / DEFAULT_RESTORE_HELPER
            restore_helper.parent.mkdir(parents=True)
            restore_helper.write_text(
                'declare -a HELPER_SURFACE_PATHS=(\n    "docs/one.md"\n    "scripts/two.sh"\n)\n',
                encoding="utf-8",
            )
            memory_root = root / "memory"
            snapshot_zip = memory_root / DEFAULT_SNAPSHOT
            snapshot_zip.parent.mkdir(parents=True, exist_ok=True)
            with zipfile.ZipFile(snapshot_zip, "w") as archive:
                archive.writestr(ZIP_PREFIX + "docs/one.md", "one")

            result = collect_results(
                repo_root=repo_root,
                snapshot_zip=snapshot_zip,
                restored_checkout_root=root / DEFAULT_RESTORED_CHECKOUT,
                restore_helper=restore_helper,
                mode="snapshot",
            )

            self.assertFalse(result["ok"])
            self.assertEqual(result["snapshot"]["missing_paths"], ["scripts/two.sh"])

    def test_collect_results_passes_for_synced_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "repo"
            repo_root.mkdir()
            restore_helper = repo_root / DEFAULT_RESTORE_HELPER
            restore_helper.parent.mkdir(parents=True)
            restore_helper.write_text(
                'declare -a HELPER_SURFACE_PATHS=(\n    "docs/one.md"\n    "scripts/two.sh"\n)\n',
                encoding="utf-8",
            )
            checkout_root = root / DEFAULT_RESTORED_CHECKOUT
            (checkout_root / "docs").mkdir(parents=True)
            (checkout_root / "scripts").mkdir(parents=True)
            (checkout_root / "docs/one.md").write_text("one", encoding="utf-8")
            (checkout_root / "scripts/two.sh").write_text("two", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                snapshot_zip=root / "missing.zip",
                restored_checkout_root=checkout_root,
                restore_helper=restore_helper,
                mode="checkout",
            )

            self.assertTrue(result["ok"])
            self.assertEqual(result["restored_checkout"]["missing_paths"], [])



def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedSnapshotDriftTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    memory_root = Path(args.memory_root).resolve() if args.memory_root else resolve_default_memory_root(repo_root)
    snapshot_zip = Path(args.snapshot_zip).resolve() if args.snapshot_zip else resolve_default_snapshot_zip(memory_root)
    restored_checkout_root = (
        Path(args.restored_checkout_root).resolve()
        if args.restored_checkout_root
        else resolve_default_restored_checkout(repo_root)
    )
    restore_helper = (
        Path(args.restore_helper).resolve() if args.restore_helper else resolve_default_restore_helper(repo_root)
    )

    result = collect_results(
        repo_root=repo_root,
        snapshot_zip=snapshot_zip,
        restored_checkout_root=restored_checkout_root,
        restore_helper=restore_helper,
        mode=args.mode,
    )

    if args.json:
        print(json.dumps({"profile": "issue3-saved-snapshot-drift", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
