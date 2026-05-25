#!/usr/bin/env python3

"""Surface the shared offline-deps root for nested issue #3 reruns.

This helper gives Linux/WSL re-entry runs a branch-local way to rediscover the
shared `offline-deps` staging directory when a checkout has been restored into a
deeper workspace path.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import tempfile
import unittest


OFFLINE_DEP_NAMES = ("brotli", "zlib", "nghttp2", "curl")
PREBUILT_V8_GLOB = "libc_v8_*.a"


def ancestor_chain(start: Path) -> list[Path]:
    chain: list[Path] = []
    current = start.resolve()
    while True:
        chain.append(current)
        if current.parent == current:
            break
        current = current.parent
    return chain


def locate_first_existing(start: Path, relative_path: str) -> Path | None:
    for ancestor in ancestor_chain(start):
        candidate = ancestor / relative_path
        if candidate.exists():
            return candidate.resolve()
    return None


def resolve_default_offline_deps_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "offline-deps")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "offline-deps").resolve()


def collect_offline_deps_report(repo_root: Path, offline_deps_root: Path | None) -> dict[str, object]:
    resolved_root = offline_deps_root.resolve() if offline_deps_root is not None else resolve_default_offline_deps_root(repo_root)
    dependency_dirs = []
    for dep_name in OFFLINE_DEP_NAMES:
        dep_path = resolved_root / dep_name
        dependency_dirs.append(
            {
                "name": dep_name,
                "path": str(dep_path),
                "exists": dep_path.is_dir(),
                "nonempty": dep_path.is_dir() and any(dep_path.iterdir()),
            }
        )

    prebuilt_archives = [str(path.resolve()) for path in sorted(resolved_root.glob(PREBUILT_V8_GLOB))]
    exists = resolved_root.exists()
    is_dir = resolved_root.is_dir()
    dependency_dirs_present = all(entry["exists"] for entry in dependency_dirs)
    diagnosis = "ready"
    if not exists:
        diagnosis = "missing-offline-deps-root"
    elif not is_dir:
        diagnosis = "offline-deps-root-not-directory"
    elif not dependency_dirs_present:
        diagnosis = "missing-offline-dependency-directories"
    elif not prebuilt_archives:
        diagnosis = "missing-prebuilt-v8-archive"

    return {
        "profile": "issue3-offline-deps-workspace-root",
        "repo_root": str(repo_root.resolve()),
        "resolved_offline_deps_root": str(resolved_root),
        "exists": exists,
        "is_directory": is_dir,
        "dependency_dirs": dependency_dirs,
        "prebuilt_v8_archives": prebuilt_archives,
        "diagnosis": diagnosis,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Surface the shared offline-deps staging root for nested or restored "
            "issue #3 Linux/WSL checkouts."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--offline-deps-root",
        default=None,
        help="Optional explicit offline-deps root override",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of a text summary",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run the helper's focused unit tests and exit",
    )
    return parser


def emit_text(report: dict[str, object]) -> None:
    print(f"Repo root: {report['repo_root']}")
    print(f"Resolved offline-deps root: {report['resolved_offline_deps_root']}")
    print(f"Diagnosis: {report['diagnosis']}")
    print("Dependency directories:")
    for entry in report["dependency_dirs"]:
        state = "ok" if entry["exists"] and entry["nonempty"] else "missing or empty"
        print(f"  - {entry['name']}: {entry['path']} [{state}]")
    if report["prebuilt_v8_archives"]:
        print("Prebuilt V8 archives:")
        for archive_path in report["prebuilt_v8_archives"]:
            print(f"  - {archive_path}")
    else:
        print("Prebuilt V8 archives: none found")


class OfflineDepsWorkspaceRootTests(unittest.TestCase):
    def test_default_root_follows_simple_workspace_layout(self) -> None:
        repo_root = Path("/tmp/workspace/browser")
        self.assertEqual(
            resolve_default_offline_deps_root(repo_root),
            Path("/tmp/workspace/offline-deps"),
        )

    def test_default_root_discovers_ancestor_workspace_layout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = Path(tmpdir)
            repo_root = workspace_root / "restored" / "browser-memory-snapshot" / "browser"
            repo_root.mkdir(parents=True)
            offline_deps_root = workspace_root / "offline-deps"
            offline_deps_root.mkdir()

            self.assertEqual(
                resolve_default_offline_deps_root(repo_root),
                offline_deps_root.resolve(),
            )

    def test_collect_report_surfaces_ready_layout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = Path(tmpdir)
            repo_root = workspace_root / "browser"
            repo_root.mkdir()
            offline_deps_root = workspace_root / "offline-deps"
            offline_deps_root.mkdir()
            for dep_name in OFFLINE_DEP_NAMES:
                dep_dir = offline_deps_root / dep_name
                dep_dir.mkdir()
                (dep_dir / "marker.txt").write_text(dep_name, encoding="utf-8")
            prebuilt_archive = offline_deps_root / "libc_v8_14.0.365.4_linux_x86_64.a"
            prebuilt_archive.write_text("archive", encoding="utf-8")

            report = collect_offline_deps_report(repo_root, None)

            self.assertEqual(report["diagnosis"], "ready")
            self.assertEqual(report["resolved_offline_deps_root"], str(offline_deps_root.resolve()))
            self.assertEqual(len(report["prebuilt_v8_archives"]), 1)

    def test_collect_report_flags_missing_dependency_dirs(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = Path(tmpdir)
            repo_root = workspace_root / "browser"
            repo_root.mkdir()
            offline_deps_root = workspace_root / "offline-deps"
            offline_deps_root.mkdir()
            (offline_deps_root / "brotli").mkdir()

            report = collect_offline_deps_report(repo_root, None)

            self.assertEqual(report["diagnosis"], "missing-offline-dependency-directories")


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(OfflineDepsWorkspaceRootTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    offline_deps_root = Path(args.offline_deps_root).resolve() if args.offline_deps_root else None
    report = collect_offline_deps_report(repo_root, offline_deps_root)

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 0 if report["diagnosis"] == "ready" else 1


if __name__ == "__main__":
    raise SystemExit(main())
