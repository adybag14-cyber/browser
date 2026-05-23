#!/usr/bin/env python3

"""Check whether this checkout is ready for Linux/WSL Zig validation.

This helper is intentionally lightweight:
- reads build.zig.zon to discover the pinned Zig line and sibling path deps
- checks an installed Zig version unless told to skip it
- checks Rust tool availability unless told to skip it
- verifies the sibling checkout layout required by this fork
- can verify the offline dependency layout and prebuilt V8 archive staging
"""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys
import tempfile
import unittest


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
PATH_VALUE_RE = re.compile(r'\.path\s*=\s*"([^"]+)"')
URL_VALUE_RE = re.compile(r'\.url\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)")
OFFLINE_DEP_NAMES = ("brotli", "zlib", "nghttp2", "curl")
PREBUILT_V8_GLOB = "libc_v8_*.a"

DEPENDENCY_MARKERS: dict[str, tuple[str, ...]] = {
    "v8": ("build.zig", "build.zig.zon", "src/v8.zig"),
    "boringssl-zig": ("build.zig", "README.md", "generated"),
}


def normalize_name(raw: str) -> str:
    return raw.replace("@", "").strip('"')


def extract_braced_block(text: str, start_index: int) -> str:
    depth = 0
    for index in range(start_index, len(text)):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[start_index : index + 1]
    raise ValueError("Could not find the end of the requested braced block")


def parse_dependency_blocks(text: str) -> list[tuple[str, str]]:
    marker = ".dependencies = .{"
    marker_index = text.find(marker)
    if marker_index == -1:
        raise ValueError("Could not find the dependencies block in build.zig.zon")

    block_start = text.find("{", marker_index)
    dependencies_block = extract_braced_block(text, block_start)

    entries: list[tuple[str, str]] = []
    cursor = 0
    while True:
        name_match = re.search(
            r'\.(?P<name>@?"[^"]+"|[A-Za-z0-9_]+)\s*=\s*\.\{',
            dependencies_block[cursor:],
        )
        if name_match is None:
            break

        raw_name = name_match.group("name")
        relative_start = cursor + name_match.start()
        body_open = dependencies_block.find("{", relative_start)
        body = extract_braced_block(dependencies_block, body_open)
        entries.append((normalize_name(raw_name), body))
        cursor = body_open + len(body)

    return entries


def parse_semver(version_text: str) -> tuple[int, int, int]:
    match = SEMVER_RE.match(version_text)
    if not match:
        raise ValueError(f"Could not parse semantic version from {version_text!r}")
    return tuple(int(part) for part in match.groups())


def load_build_metadata(repo_root: pathlib.Path) -> tuple[str, list[tuple[str, pathlib.Path]], list[str]]:
    zon_path = repo_root / "build.zig.zon"
    text = zon_path.read_text(encoding="utf-8")

    minimum_match = MINIMUM_ZIG_RE.search(text)
    if minimum_match is None:
        raise ValueError(f"Could not find minimum_zig_version in {zon_path}")

    path_deps: list[tuple[str, pathlib.Path]] = []
    url_deps: list[str] = []
    for name, body in parse_dependency_blocks(text):
        path_match = PATH_VALUE_RE.search(body)
        if path_match is not None:
            path_deps.append((name, (repo_root / path_match.group(1)).resolve()))
            continue

        url_match = URL_VALUE_RE.search(body)
        if url_match is not None:
            url_deps.append(name)
    return minimum_match.group(1), path_deps, url_deps


def run_version_command(command: str, version_args: list[str], label: str) -> tuple[list[str], str | None]:
    failures: list[str] = []
    try:
        completed = subprocess.run(
            [command, *version_args],
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        failures.append(f"{label} not found on PATH (expected `{command}` or an explicit override)")
        return failures, None
    except subprocess.CalledProcessError as exc:
        failures.append(f"{label} version probe failed with exit code {exc.returncode}")
        return failures, None

    output = completed.stdout.strip() or completed.stderr.strip()
    return failures, output or None


def check_zig_version(minimum_zig: str, zig_cmd: str) -> tuple[list[str], str | None]:
    failures, installed = run_version_command(zig_cmd, ["version"], "zig")
    if failures or installed is None:
        return failures, installed

    minimum_parts = parse_semver(minimum_zig)
    installed_parts = parse_semver(installed)
    if installed_parts < minimum_parts:
        failures.append(f"zig {installed} is older than the branch minimum {minimum_zig}")
        return failures, installed

    if installed_parts[:2] != minimum_parts[:2]:
        failures.append(
            f"zig {installed} does not match the branch's expected {minimum_parts[0]}.{minimum_parts[1]}.x line"
        )
    return failures, installed


def check_rust_tools(cargo_cmd: str, rustc_cmd: str) -> tuple[list[str], dict[str, str]]:
    failures: list[str] = []
    versions: dict[str, str] = {}

    for label, command in (("cargo", cargo_cmd), ("rustc", rustc_cmd)):
        probe_failures, version_output = run_version_command(command, ["--version"], label)
        failures.extend(probe_failures)
        if version_output is not None:
            versions[label] = version_output

    return failures, versions


def find_missing_markers(dep_name: str, dep_path: pathlib.Path) -> list[str]:
    markers = DEPENDENCY_MARKERS.get(dep_name, ())
    missing: list[str] = []
    for marker in markers:
        if not (dep_path / marker).exists():
            missing.append(marker)
    return missing


def check_path_dependencies(path_deps: list[tuple[str, pathlib.Path]]) -> list[str]:
    failures: list[str] = []
    for name, dep_path in path_deps:
        if not dep_path.exists():
            failures.append(f"missing sibling dependency {name}: expected {dep_path}")
            continue
        if not dep_path.is_dir():
            failures.append(f"sibling dependency {name} is not a directory: {dep_path}")
            continue

        missing_markers = find_missing_markers(name, dep_path)
        if missing_markers:
            joined_markers = ", ".join(missing_markers)
            failures.append(
                f"sibling dependency {name} at {dep_path} is incomplete; missing expected markers: {joined_markers}"
            )
    return failures


def check_offline_deps_root(
    offline_deps_root: pathlib.Path,
    require_prebuilt_v8: bool,
) -> tuple[list[str], list[tuple[str, pathlib.Path]], list[pathlib.Path]]:
    failures: list[str] = []
    staged_dirs: list[tuple[str, pathlib.Path]] = []

    if not offline_deps_root.exists():
        failures.append(
            f"offline dependency root is missing: expected {offline_deps_root} (run scripts/linux/prepare_offline_build_inputs.sh first)"
        )
        return failures, staged_dirs, []
    if not offline_deps_root.is_dir():
        failures.append(f"offline dependency root is not a directory: {offline_deps_root}")
        return failures, staged_dirs, []

    for dep_name in OFFLINE_DEP_NAMES:
        dep_path = offline_deps_root / dep_name
        staged_dirs.append((dep_name, dep_path))
        if not dep_path.exists():
            failures.append(f"missing offline dependency directory {dep_name}: expected {dep_path}")
        elif not dep_path.is_dir():
            failures.append(f"offline dependency path for {dep_name} is not a directory: {dep_path}")
        elif not any(dep_path.iterdir()):
            failures.append(f"offline dependency directory {dep_name} is empty: {dep_path}")

    prebuilt_archives = sorted(offline_deps_root.glob(PREBUILT_V8_GLOB))
    if require_prebuilt_v8 and not prebuilt_archives:
        failures.append(
            f"missing prebuilt V8 archive under {offline_deps_root} (expected a {PREBUILT_V8_GLOB} file)"
        )

    return failures, staged_dirs, prebuilt_archives


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Check Zig toolchain, Rust tools, and dependency staging for Linux/WSL validation."
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--zig",
        default="zig",
        help="Zig executable to probe (default: zig on PATH)",
    )
    parser.add_argument(
        "--cargo",
        default="cargo",
        help="Cargo executable to probe (default: cargo on PATH)",
    )
    parser.add_argument(
        "--rustc",
        default="rustc",
        help="rustc executable to probe (default: rustc on PATH)",
    )
    parser.add_argument(
        "--skip-zig-check",
        action="store_true",
        help="Skip calling `zig version` and only validate the repo layout",
    )
    parser.add_argument(
        "--skip-rust-check",
        action="store_true",
        help="Skip probing cargo/rustc and only validate Zig plus dependency staging",
    )
    parser.add_argument(
        "--expect-offline-deps",
        action="store_true",
        help="Verify ../offline-deps staging from prepare_offline_build_inputs.sh",
    )
    parser.add_argument(
        "--offline-deps-root",
        default=None,
        help="Path to the offline dependency root (default: ../offline-deps beside the repo)",
    )
    parser.add_argument(
        "--require-prebuilt-v8",
        action="store_true",
        help="Require a prebuilt libc_v8_*.a archive under the offline dependency root",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run the helper's focused unit tests and exit",
    )
    return parser


class ReadinessHelperTests(unittest.TestCase):
    def test_placeholder_dependency_dirs_fail_marker_checks(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = pathlib.Path(tmpdir)
            v8_path = tmp_path / "zig-v8-fork"
            boring_path = tmp_path / "boringssl-zig"
            v8_path.mkdir()
            boring_path.mkdir()

            failures = check_path_dependencies(
                [
                    ("v8", v8_path),
                    ("boringssl-zig", boring_path),
                ]
            )

            self.assertEqual(len(failures), 2)
            self.assertIn("missing expected markers", failures[0])
            self.assertIn("missing expected markers", failures[1])

    def test_dependency_marker_checks_pass_for_expected_layout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = pathlib.Path(tmpdir)
            v8_path = tmp_path / "zig-v8-fork"
            boring_path = tmp_path / "boringssl-zig"
            (v8_path / "src").mkdir(parents=True)
            (boring_path / "generated").mkdir(parents=True)
            for path in (
                v8_path / "build.zig",
                v8_path / "build.zig.zon",
                v8_path / "src" / "v8.zig",
                boring_path / "build.zig",
                boring_path / "README.md",
            ):
                path.write_text("", encoding="utf-8")

            failures = check_path_dependencies(
                [
                    ("v8", v8_path),
                    ("boringssl-zig", boring_path),
                ]
            )

            self.assertEqual(failures, [])

    def test_missing_offline_dependency_root_fails_cleanly(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            missing_root = pathlib.Path(tmpdir) / "offline-deps"
            failures, staged_dirs, prebuilt_archives = check_offline_deps_root(
                missing_root,
                require_prebuilt_v8=True,
            )

            self.assertEqual(staged_dirs, [])
            self.assertEqual(prebuilt_archives, [])
            self.assertEqual(len(failures), 1)
            self.assertIn("run scripts/linux/prepare_offline_build_inputs.sh first", failures[0])

    def test_offline_dependency_root_and_prebuilt_v8_pass(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            offline_root = pathlib.Path(tmpdir) / "offline-deps"
            offline_root.mkdir()
            for dep_name in OFFLINE_DEP_NAMES:
                dep_dir = offline_root / dep_name
                dep_dir.mkdir()
                (dep_dir / "marker.txt").write_text(dep_name, encoding="utf-8")
            prebuilt_archive = offline_root / "libc_v8_14.0.365.4_linux_x86_64.a"
            prebuilt_archive.write_text("archive", encoding="utf-8")

            failures, staged_dirs, prebuilt_archives = check_offline_deps_root(
                offline_root,
                require_prebuilt_v8=True,
            )

            self.assertEqual(failures, [])
            self.assertEqual([name for name, _ in staged_dirs], list(OFFLINE_DEP_NAMES))
            self.assertEqual(prebuilt_archives, [prebuilt_archive])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ReadinessHelperTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    zon_path = repo_root / "build.zig.zon"
    if not zon_path.is_file():
        print(f"ERROR: {zon_path} not found", file=sys.stderr)
        return 2

    minimum_zig, path_deps, url_deps = load_build_metadata(repo_root)
    failures: list[str] = []

    zig_version: str | None = None
    if not args.skip_zig_check:
        zig_failures, zig_version = check_zig_version(minimum_zig, args.zig)
        failures.extend(zig_failures)

    rust_versions: dict[str, str] = {}
    if not args.skip_rust_check:
        rust_failures, rust_versions = check_rust_tools(args.cargo, args.rustc)
        failures.extend(rust_failures)

    failures.extend(check_path_dependencies(path_deps))

    offline_deps_root = None
    staged_offline_dirs: list[tuple[str, pathlib.Path]] = []
    prebuilt_archives: list[pathlib.Path] = []
    if args.expect_offline_deps or args.require_prebuilt_v8:
        offline_deps_root = pathlib.Path(args.offline_deps_root).resolve() if args.offline_deps_root else (
            repo_root.parent / "offline-deps"
        ).resolve()
        offline_failures, staged_offline_dirs, prebuilt_archives = check_offline_deps_root(
            offline_deps_root,
            require_prebuilt_v8=args.require_prebuilt_v8,
        )
        failures.extend(offline_failures)

    print(f"Repo root: {repo_root}")
    print(f"Minimum Zig from build.zig.zon: {minimum_zig}")
    if zig_version is not None:
        print(f"Installed zig: {zig_version}")
    if rust_versions:
        for label in ("cargo", "rustc"):
            if label in rust_versions:
                print(f"Installed {label}: {rust_versions[label]}")

    if path_deps:
        print("Sibling path dependencies:")
        for name, dep_path in path_deps:
            state = "ok"
            if not dep_path.exists():
                state = "missing"
            elif find_missing_markers(name, dep_path):
                state = "incomplete"
            print(f"  - {name}: {dep_path} [{state}]")

    if offline_deps_root is not None:
        print(f"Offline dependency root: {offline_deps_root}")
        for name, dep_path in staged_offline_dirs:
            state = "ok"
            if not dep_path.exists():
                state = "missing"
            elif not dep_path.is_dir() or not any(dep_path.iterdir()):
                state = "incomplete"
            print(f"  - {name}: {dep_path} [{state}]")
        if prebuilt_archives:
            print("Prebuilt V8 archives:")
            for archive_path in prebuilt_archives:
                print(f"  - {archive_path}")
        elif args.require_prebuilt_v8:
            print("Prebuilt V8 archives: none found")

    if url_deps:
        print("URL-backed dependencies still need network access or an offline cache:")
        for name in url_deps:
            print(f"  - {name}")

    if failures:
        print("\nReadiness check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        print(
            "\nSuggested next step: stage sibling dependencies plus ../offline-deps with scripts/linux/prepare_offline_build_inputs.sh, use the saved Rust toolchain, and retry `zig build` with a Zig 0.15.2 toolchain.",
            file=sys.stderr,
        )
        return 1

    print("\nReadiness check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
