#!/usr/bin/env python3

"""Check whether the issue #3 offline dependency staging layout is ready.

This helper sits after `prepare_offline_build_inputs.sh` and before the broader
Linux build-readiness helper. It verifies that the saved offline dependency
route actually produced the sibling layout and build.zig.zon rewrites that the
headed-mode recovery path expects.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest


PATH_BLOCK_RE_TEMPLATE = r'(?ms)^\s*\.{name}\s*=\s*\.\{{\n\s*\.path = "(?P<path>[^"]+)",\n\s*}},'
PREBUILT_V8_GLOB = "libc_v8_*.a"
OFFLINE_DEP_NAMES = ("brotli", "zlib", "nghttp2", "curl")
SIBLING_DEPENDENCIES: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("zig-v8-fork", ("build.zig", "build.zig.zon", "src/v8.zig")),
    ("boringssl-zig", ("build.zig", "README.md", "generated")),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the issue #3 offline dependency route produced the "
            "expected sibling layout and local build.zig.zon dependency paths."
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
        help="Path to the offline dependency root (default: ../offline-deps beside the repo)",
    )
    parser.add_argument(
        "--expect-prebuilt-v8",
        action="store_true",
        help="Require a prebuilt libc_v8_*.a archive under the offline dependency root",
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


def resolve_default_offline_deps_root(repo_root: Path) -> Path:
    return (repo_root.parent / "offline-deps").resolve()


def extract_local_dependency_paths(build_zon_text: str) -> dict[str, str]:
    paths: dict[str, str] = {}
    for dep_name in OFFLINE_DEP_NAMES:
        match = re.search(PATH_BLOCK_RE_TEMPLATE.format(name=re.escape(dep_name)), build_zon_text)
        if match is not None:
            paths[dep_name] = match.group("path")
    return paths


def expected_dependency_paths(repo_root: Path, offline_deps_root: Path) -> dict[str, str]:
    import os

    return {
        dep_name: os.path.relpath(offline_deps_root / dep_name, repo_root)
        for dep_name in OFFLINE_DEP_NAMES
    }


def collect_results(
    repo_root: Path,
    offline_deps_root: Path,
    *,
    expect_prebuilt_v8: bool,
) -> dict[str, object]:
    build_zon_path = repo_root / "build.zig.zon"
    results: dict[str, object] = {
        "repo_root": str(repo_root),
        "offline_deps_root": str(offline_deps_root),
        "build_zig_zon_path": str(build_zon_path),
        "ok": True,
    }

    failures: list[str] = []

    if not build_zon_path.is_file():
        failures.append(f"missing build.zig.zon: {build_zon_path}")
        results["failures"] = failures
        results["ok"] = False
        return results

    build_zon_text = build_zon_path.read_text(encoding="utf-8")
    local_paths = extract_local_dependency_paths(build_zon_text)
    expected_paths = expected_dependency_paths(repo_root, offline_deps_root)

    path_results: list[dict[str, object]] = []
    for dep_name in OFFLINE_DEP_NAMES:
        actual_path = local_paths.get(dep_name)
        expected_path = expected_paths[dep_name]
        matches = actual_path == expected_path
        if actual_path is None:
            failures.append(
                f"build.zig.zon does not point {dep_name} at a local .path dependency"
            )
        elif not matches:
            failures.append(
                f"build.zig.zon points {dep_name} at {actual_path}, expected {expected_path}"
            )
        path_results.append(
            {
                "dependency": dep_name,
                "expected_path": expected_path,
                "actual_path": actual_path,
                "matches_expected_path": matches,
            }
        )

    sibling_results: list[dict[str, object]] = []
    for dep_name, markers in SIBLING_DEPENDENCIES:
        dep_root = (repo_root.parent / dep_name).resolve()
        exists = dep_root.is_dir()
        missing_markers = [
            marker for marker in markers if not (dep_root / marker).exists()
        ] if exists else list(markers)
        if not exists:
            failures.append(f"missing sibling dependency directory: {dep_root}")
        elif missing_markers:
            failures.append(
                f"sibling dependency {dep_name} is incomplete; missing markers: {', '.join(missing_markers)}"
            )
        sibling_results.append(
            {
                "dependency": dep_name,
                "path": str(dep_root),
                "exists": exists,
                "missing_markers": missing_markers,
            }
        )

    offline_dir_results: list[dict[str, object]] = []
    if not offline_deps_root.is_dir():
        failures.append(f"offline dependency root is missing: {offline_deps_root}")
    for dep_name in OFFLINE_DEP_NAMES:
        dep_root = offline_deps_root / dep_name
        exists = dep_root.is_dir()
        non_empty = exists and any(dep_root.iterdir())
        if not exists:
            failures.append(f"missing offline dependency directory: {dep_root}")
        elif not non_empty:
            failures.append(f"offline dependency directory is empty: {dep_root}")
        offline_dir_results.append(
            {
                "dependency": dep_name,
                "path": str(dep_root),
                "exists": exists,
                "non_empty": non_empty,
            }
        )

    prebuilt_archives = sorted(str(path) for path in offline_deps_root.glob(PREBUILT_V8_GLOB))
    if expect_prebuilt_v8 and not prebuilt_archives:
        failures.append(
            f"missing prebuilt V8 archive under {offline_deps_root} (expected {PREBUILT_V8_GLOB})"
        )

    results.update(
        {
            "expected_dependency_paths": expected_paths,
            "build_zig_zon_local_paths": path_results,
            "sibling_dependencies": sibling_results,
            "offline_dependency_directories": offline_dir_results,
            "prebuilt_v8_archives": prebuilt_archives,
            "failures": failures,
            "ok": not failures,
        }
    )
    return results


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Offline dependency root: {result['offline_deps_root']}")
    print(f"build.zig.zon: {result['build_zig_zon_path']}")
    print("Local build.zig.zon dependency paths:")
    for entry in result["build_zig_zon_local_paths"]:
        status = "PASS" if entry["matches_expected_path"] else "FAIL"
        print(
            f"  [{status}] {entry['dependency']}: actual={entry['actual_path']!r} expected={entry['expected_path']!r}"
        )
    print("Sibling dependency directories:")
    for entry in result["sibling_dependencies"]:
        status = "PASS" if entry["exists"] and not entry["missing_markers"] else "FAIL"
        print(f"  [{status}] {entry['dependency']}: {entry['path']}")
        if entry["missing_markers"]:
            print(f"         missing markers: {', '.join(entry['missing_markers'])}")
    print("Offline dependency directories:")
    for entry in result["offline_dependency_directories"]:
        status = "PASS" if entry["exists"] and entry["non_empty"] else "FAIL"
        print(f"  [{status}] {entry['dependency']}: {entry['path']}")
    if result["prebuilt_v8_archives"]:
        print("Prebuilt V8 archives:")
        for archive in result["prebuilt_v8_archives"]:
            print(f"  - {archive}")
    else:
        print("Prebuilt V8 archives: none found")

    if result["ok"]:
        print("\nOffline dependency stage check passed.")
    else:
        print("\nOffline dependency stage check failed.", file=sys.stderr)
        for failure in result["failures"]:
            print(f"  - {failure}", file=sys.stderr)
        print(
            "\nSuggested next step: rerun scripts/linux/prepare_offline_build_inputs.sh and then retry this focused checker before the broader Linux build-readiness helper.",
            file=sys.stderr,
        )


class OfflineDependencyStageTests(unittest.TestCase):
    def write_build_zon(self, repo_root: Path, offline_deps_root: Path) -> None:
        import os

        relative_root = {
            dep_name: os.path.relpath(offline_deps_root / dep_name, repo_root)
            for dep_name in OFFLINE_DEP_NAMES
        }
        lines = [
            ".{",
            "    .dependencies = .{",
        ]
        for dep_name in OFFLINE_DEP_NAMES:
            lines.extend(
                [
                    f"        .{dep_name} = .{{",
                    f'            .path = "{relative_root[dep_name]}",',
                    "        },",
                ]
            )
        lines.extend(["    },", "}"])
        (repo_root / "build.zig.zon").write_text("\n".join(lines), encoding="utf-8")

    def test_collect_results_passes_for_staged_layout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            offline_root = root / "offline-deps"
            repo_root.mkdir()
            offline_root.mkdir()

            self.write_build_zon(repo_root, offline_root)

            for dep_name, markers in SIBLING_DEPENDENCIES:
                dep_root = root / dep_name
                dep_root.mkdir()
                for marker in markers:
                    target = dep_root / marker
                    target.parent.mkdir(parents=True, exist_ok=True)
                    if marker.endswith("generated"):
                        target.mkdir(exist_ok=True)
                    else:
                        target.write_text("ok", encoding="utf-8")

            for dep_name in OFFLINE_DEP_NAMES:
                dep_root = offline_root / dep_name
                dep_root.mkdir()
                (dep_root / "marker.txt").write_text(dep_name, encoding="utf-8")
            (offline_root / "libc_v8_14.0.365.4_linux_x86_64.a").write_text("v8", encoding="utf-8")

            result = collect_results(repo_root, offline_root, expect_prebuilt_v8=True)

            self.assertTrue(result["ok"])
            self.assertEqual(result["failures"], [])

    def test_collect_results_fails_for_missing_local_path_rewrites(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            offline_root = root / "offline-deps"
            repo_root.mkdir()
            offline_root.mkdir()
            (repo_root / "build.zig.zon").write_text(".{}", encoding="utf-8")

            result = collect_results(repo_root, offline_root, expect_prebuilt_v8=False)

            self.assertFalse(result["ok"])
            self.assertIn(
                "build.zig.zon does not point brotli at a local .path dependency",
                result["failures"],
            )

    def test_collect_results_fails_for_empty_offline_directory(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            offline_root = root / "offline-deps"
            repo_root.mkdir()
            offline_root.mkdir()
            self.write_build_zon(repo_root, offline_root)

            for dep_name, markers in SIBLING_DEPENDENCIES:
                dep_root = root / dep_name
                dep_root.mkdir()
                for marker in markers:
                    target = dep_root / marker
                    target.parent.mkdir(parents=True, exist_ok=True)
                    if marker.endswith("generated"):
                        target.mkdir(exist_ok=True)
                    else:
                        target.write_text("ok", encoding="utf-8")

            for dep_name in OFFLINE_DEP_NAMES:
                (offline_root / dep_name).mkdir()

            result = collect_results(repo_root, offline_root, expect_prebuilt_v8=False)

            self.assertFalse(result["ok"])
            self.assertIn(
                f"offline dependency directory is empty: {offline_root / 'brotli'}",
                result["failures"],
            )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(OfflineDependencyStageTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    offline_deps_root = (
        Path(args.offline_deps_root).resolve()
        if args.offline_deps_root
        else resolve_default_offline_deps_root(repo_root)
    )
    result = collect_results(
        repo_root,
        offline_deps_root,
        expect_prebuilt_v8=args.expect_prebuilt_v8,
    )
    if args.json:
        print(json.dumps({"profile": "issue3-offline-dependency-stage", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
