#!/usr/bin/env python3

"""Check whether this checkout is ready for Linux/WSL Zig validation.

This helper is intentionally lightweight:
- reads build.zig.zon to discover the pinned Zig line and sibling path deps
- checks an installed Zig version unless told to skip it
- checks Rust tool availability unless told to skip it
- verifies the sibling checkout layout required by this fork
- can verify the offline dependency layout and prebuilt V8 archive staging
- can verify the saved archive bundle needed to restore offline build inputs
"""

from __future__ import annotations

import argparse
import os
import pathlib
import re
import shlex
import subprocess
import sys
import tempfile
import unittest


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
PATH_VALUE_RE = re.compile(r'\.path\s*=\s*"([^"]+)"')
URL_VALUE_RE = re.compile(r'\.url\s*=\s*"([^"]+)"')
SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)")
FALLBACK_ZIG_ARCHIVE_VERSION_RE = re.compile(r"(\d+\.\d+\.\d+)")
OFFLINE_DEP_NAMES = ("brotli", "zlib", "nghttp2", "curl")
PREBUILT_V8_GLOB = "libc_v8_*.a"
DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
DEFAULT_ZIG_TOOLCHAIN_GLOBS = (
    "zig*/zig",
    "zig*/bin/zig",
    "*/zig",
    "*/bin/zig",
    "zig",
)
SAVED_ARCHIVE_GLOBS: dict[str, str] = {
    "rust_toolchain": "01-rust-*.tar.xz",
    "html5ever": "02-litefetch-html5ever-*.zip",
    "boringssl": "03-boringssl-zig-main.zip",
    "browser_deps": "04-zig-browser-depo.tar.zip",
}
SAVED_ARCHIVE_LABELS: dict[str, str] = {
    "rust_toolchain": "saved Rust toolchain archive",
    "html5ever": "saved html5ever dependency archive",
    "boringssl": "saved BoringSSL archive",
    "browser_deps": "saved browser dependency archive",
}
REQUIRED_SAVED_ARCHIVE_KEYS = ("rust_toolchain", "boringssl", "browser_deps")
OPTIONAL_SAVED_ARCHIVE_KEYS = ("html5ever",)

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


def same_version_line(expected_version: str, actual_version: str) -> bool:
    expected_parts = parse_semver(expected_version)
    actual_parts = parse_semver(actual_version)
    return actual_parts[:2] == expected_parts[:2]


def infer_archive_semver(path: pathlib.Path) -> str | None:
    match = FALLBACK_ZIG_ARCHIVE_VERSION_RE.search(path.name)
    if match is None:
        return None
    return match.group(1)


def resolve_default_agent_files_root(repo_root: pathlib.Path) -> pathlib.Path:
    return (repo_root.parent / "agent_files").resolve()


def resolve_default_toolchains_root(repo_root: pathlib.Path) -> pathlib.Path:
    return (repo_root.parent / "toolchains").resolve()


def resolve_fallback_zig_archive(
    repo_root: pathlib.Path,
    fallback_zig_archive: pathlib.Path | None,
) -> pathlib.Path | None:
    if fallback_zig_archive is not None:
        return fallback_zig_archive

    candidate = resolve_default_agent_files_root(repo_root) / DEFAULT_FALLBACK_ZIG_ARCHIVE
    return candidate if candidate.is_file() else None


def discover_toolchain_zig_candidates(toolchains_root: pathlib.Path) -> list[pathlib.Path]:
    if not toolchains_root.exists() or not toolchains_root.is_dir():
        return []

    candidates: list[pathlib.Path] = []
    seen: set[pathlib.Path] = set()
    for pattern in DEFAULT_ZIG_TOOLCHAIN_GLOBS:
        for path in sorted(toolchains_root.glob(pattern)):
            if not path.is_file():
                continue
            resolved = path.resolve()
            if resolved in seen:
                continue
            seen.add(resolved)
            candidates.append(resolved)
    return candidates


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

    if not same_version_line(minimum_zig, installed):
        failures.append(
            f"zig {installed} does not match the branch's expected {minimum_parts[0]}.{minimum_parts[1]}.x line"
        )
    return failures, installed


def describe_zig_toolchain_candidate(
    minimum_zig: str,
    zig_path: pathlib.Path,
) -> tuple[list[str], str | None, str]:
    failures, installed = run_version_command(str(zig_path), ["version"], f"zig candidate {zig_path}")
    if failures or installed is None:
        return failures, None, "unusable"

    minimum_parts = parse_semver(minimum_zig)
    installed_parts = parse_semver(installed)
    if installed_parts < minimum_parts:
        return [], installed, "older than minimum"
    if same_version_line(minimum_zig, installed):
        return [], installed, f"matches expected {minimum_parts[0]}.{minimum_parts[1]}.x line"
    return [], installed, f"mismatched: expected {minimum_parts[0]}.{minimum_parts[1]}.x line"


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


def discover_saved_archives(saved_archives_root: pathlib.Path) -> dict[str, pathlib.Path]:
    discovered: dict[str, pathlib.Path] = {}
    for key, pattern in SAVED_ARCHIVE_GLOBS.items():
        matches = sorted(saved_archives_root.glob(pattern))
        if matches:
            discovered[key] = matches[0]
    return discovered


def check_saved_archives_root(saved_archives_root: pathlib.Path) -> tuple[list[str], dict[str, pathlib.Path]]:
    failures: list[str] = []

    if not saved_archives_root.exists():
        failures.append(f"saved archive root is missing: expected {saved_archives_root}")
        return failures, {}
    if not saved_archives_root.is_dir():
        failures.append(f"saved archive root is not a directory: {saved_archives_root}")
        return failures, {}

    discovered = discover_saved_archives(saved_archives_root)
    for key in REQUIRED_SAVED_ARCHIVE_KEYS:
        if key in discovered:
            continue
        failures.append(
            f"missing {SAVED_ARCHIVE_LABELS[key]} under {saved_archives_root} (expected {SAVED_ARCHIVE_GLOBS[key]})"
        )

    return failures, discovered


def check_optional_file(path: pathlib.Path, label: str) -> list[str]:
    if not path.exists():
        return [f"{label} does not exist: {path}"]
    if not path.is_file():
        return [f"{label} is not a file: {path}"]
    return []


def describe_fallback_zig_archive(
    minimum_zig: str,
    fallback_zig_archive: pathlib.Path,
) -> tuple[list[str], str | None, str]:
    failures = check_optional_file(fallback_zig_archive, "fallback Zig archive")
    if failures:
        return failures, None, "missing"

    inferred_version = infer_archive_semver(fallback_zig_archive)
    if inferred_version is None:
        return (
            [
                "could not infer a Zig semantic version from "
                f"fallback Zig archive name: {fallback_zig_archive.name}"
            ],
            None,
            "unknown version",
        )

    if same_version_line(minimum_zig, inferred_version):
        expected_parts = parse_semver(minimum_zig)
        return [], inferred_version, f"matches expected {expected_parts[0]}.{expected_parts[1]}.x line"

    expected_parts = parse_semver(minimum_zig)
    return (
        [],
        inferred_version,
        f"mismatched: expected {expected_parts[0]}.{expected_parts[1]}.x line",
    )


def build_prepare_offline_command(
    repo_root: pathlib.Path,
    saved_archives: dict[str, pathlib.Path],
) -> list[str]:
    command = [
        str(repo_root / "scripts" / "linux" / "prepare_offline_build_inputs.sh"),
        "--browser-root",
        str(repo_root),
        "--browser-deps-archive",
        str(saved_archives["browser_deps"]),
        "--boringssl-archive",
        str(saved_archives["boringssl"]),
    ]
    html5ever_archive = saved_archives.get("html5ever")
    if html5ever_archive is not None:
        command.extend(("--html5ever-archive", str(html5ever_archive)))
    command.append("--check-only")
    return command


def format_shell_command(command: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in command)


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
        "--expect-saved-archives",
        action="store_true",
        help="Verify the saved dependency archives needed for prepare_offline_build_inputs.sh",
    )
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help="Path to the saved archive root (default: ../memory/repo_archives/browser beside the repo workspace)",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional path to the surfaced fallback Zig archive used by the Linux issue #3 recovery route",
    )
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Path to a staged Zig toolchains root (default: ../toolchains beside the repo workspace)",
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

    def test_saved_archives_root_finds_required_archives(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            (root / "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz").write_text("rust", encoding="utf-8")
            html5ever = root / "02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"
            html5ever.write_text("html5ever", encoding="utf-8")
            boringssl = root / "03-boringssl-zig-main.zip"
            boringssl.write_text("boringssl", encoding="utf-8")
            browser_deps = root / "04-zig-browser-depo.tar.zip"
            browser_deps.write_text("browser-deps", encoding="utf-8")

            failures, discovered = check_saved_archives_root(root)

            self.assertEqual(failures, [])
            self.assertIn("rust_toolchain", discovered)
            self.assertEqual(discovered["html5ever"], html5ever)
            self.assertEqual(discovered["boringssl"], boringssl)
            self.assertEqual(discovered["browser_deps"], browser_deps)

    def test_saved_archives_root_reports_missing_required_archives(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            failures, discovered = check_saved_archives_root(root)

            self.assertEqual(discovered, {})
            self.assertEqual(len(failures), 3)
            self.assertIn("saved Rust toolchain archive", failures[0])
            self.assertIn("saved BoringSSL archive", failures[1])
            self.assertIn("saved browser dependency archive", failures[2])

    def test_prepare_command_includes_optional_html5ever_archive(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        saved_archives = {
            "browser_deps": pathlib.Path("/tmp/memory/repo_archives/browser/04-zig-browser-depo.tar.zip"),
            "boringssl": pathlib.Path("/tmp/memory/repo_archives/browser/03-boringssl-zig-main.zip"),
            "html5ever": pathlib.Path(
                "/tmp/memory/repo_archives/browser/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"
            ),
        }

        command = build_prepare_offline_command(repo_root, saved_archives)

        self.assertIn("--html5ever-archive", command)
        self.assertEqual(command[-1], "--check-only")

    def test_check_optional_file_reports_missing_path(self) -> None:
        missing_path = pathlib.Path("/tmp/missing-zig.tar.xz")

        failures = check_optional_file(missing_path, "fallback Zig archive")

        self.assertEqual(failures, [f"fallback Zig archive does not exist: {missing_path}"])

    def test_check_optional_file_accepts_existing_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            archive_path = pathlib.Path(tmpdir) / "zig.tar.xz"
            archive_path.write_text("zig", encoding="utf-8")

            failures = check_optional_file(archive_path, "fallback Zig archive")

            self.assertEqual(failures, [])

    def test_same_version_line_matches_major_minor_only(self) -> None:
        self.assertTrue(same_version_line("0.15.2", "0.15.7"))
        self.assertFalse(same_version_line("0.15.2", "0.17.0-dev.299+a76ce7710"))

    def test_infer_archive_semver_from_fallback_name(self) -> None:
        archive_path = pathlib.Path("/tmp/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz")
        self.assertEqual(infer_archive_semver(archive_path), "0.17.0")

    def test_describe_fallback_zig_archive_reports_mismatched_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            archive_path = pathlib.Path(tmpdir) / "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
            archive_path.write_text("zig", encoding="utf-8")

            failures, version, status = describe_fallback_zig_archive("0.15.2", archive_path)

            self.assertEqual(failures, [])
            self.assertEqual(version, "0.17.0")
            self.assertIn("mismatched", status)

    def test_describe_fallback_zig_archive_reports_matching_line(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            archive_path = pathlib.Path(tmpdir) / "zig-x86_64-linux-0.15.2.tar.xz"
            archive_path.write_text("zig", encoding="utf-8")

            failures, version, status = describe_fallback_zig_archive("0.15.2", archive_path)

            self.assertEqual(failures, [])
            self.assertEqual(version, "0.15.2")
            self.assertIn("matches expected 0.15.x line", status)

    def test_default_roots_follow_workspace_layout(self) -> None:
        repo_root = pathlib.Path("/tmp/workspace/browser")
        self.assertEqual(resolve_default_agent_files_root(repo_root), Path("/tmp/workspace/agent_files"))
        self.assertEqual(resolve_default_toolchains_root(repo_root), Path("/tmp/workspace/toolchains"))

    def test_resolve_fallback_zig_archive_prefers_default_agent_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            repo_root = root / "browser"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            agent_files_root.mkdir()
            fallback_archive = agent_files_root / DEFAULT_FALLBACK_ZIG_ARCHIVE
            fallback_archive.write_text("zig", encoding="utf-8")

            self.assertEqual(resolve_fallback_zig_archive(repo_root, None), fallback_archive)

    def test_discover_toolchain_zig_candidates_and_describe_versions(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            toolchains_root = pathlib.Path(tmpdir)
            matching_candidate = toolchains_root / "zig-0.15.7" / "zig"
            mismatched_candidate = toolchains_root / "zig-0.17.0" / "bin" / "zig"
            older_candidate = toolchains_root / "zig-0.14.1" / "zig"
            duplicate_candidate = toolchains_root / "zig"

            for candidate, version in (
                (matching_candidate, "0.15.7"),
                (mismatched_candidate, "0.17.0-dev.299+a76ce7710"),
                (older_candidate, "0.14.1"),
                (duplicate_candidate, "0.15.7"),
            ):
                candidate.parent.mkdir(parents=True, exist_ok=True)
                candidate.write_text(f"#!/usr/bin/env bash\necho {version}\n", encoding="utf-8")
                os.chmod(candidate, 0o755)

            candidates = discover_toolchain_zig_candidates(toolchains_root)

            self.assertEqual(len(candidates), 4)

            matching_failures, matching_version, matching_status = describe_zig_toolchain_candidate(
                "0.15.2",
                matching_candidate,
            )
            self.assertEqual(matching_failures, [])
            self.assertEqual(matching_version, "0.15.7")
            self.assertIn("matches expected 0.15.x line", matching_status)

            mismatched_failures, mismatched_version, mismatched_status = describe_zig_toolchain_candidate(
                "0.15.2",
                mismatched_candidate,
            )
            self.assertEqual(mismatched_failures, [])
            self.assertEqual(mismatched_version, "0.17.0-dev.299+a76ce7710")
            self.assertIn("mismatched", mismatched_status)

            older_failures, older_version, older_status = describe_zig_toolchain_candidate(
                "0.15.2",
                older_candidate,
            )
            self.assertEqual(older_failures, [])
            self.assertEqual(older_version, "0.14.1")
            self.assertEqual(older_status, "older than minimum")

    def test_parser_accepts_fallback_zig_archive(self) -> None:
        parser = build_parser()

        args = parser.parse_args([
            "--fallback-zig-archive",
            "/tmp/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
            "--skip-zig-check",
            "--skip-rust-check",
        ])

        self.assertEqual(
            args.fallback_zig_archive,
            "/tmp/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
        )


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

    toolchains_root = pathlib.Path(args.toolchains_root).resolve() if args.toolchains_root else resolve_default_toolchains_root(repo_root)
    discovered_zig_candidates = discover_toolchain_zig_candidates(toolchains_root)
    zig_candidate_reports: list[dict[str, pathlib.Path | str | None]] = []
    matching_zig_candidates: list[pathlib.Path] = []
    for candidate in discovered_zig_candidates:
        candidate_failures, candidate_version, candidate_status = describe_zig_toolchain_candidate(minimum_zig, candidate)
        failures.extend(candidate_failures)
        zig_candidate_reports.append(
            {
                "path": candidate,
                "version": candidate_version,
                "status": candidate_status,
            }
        )
        if candidate_version is not None and candidate_status.startswith("matches expected"):
            matching_zig_candidates.append(candidate)

    if (
        not args.skip_zig_check
        and matching_zig_candidates
        and (zig_version is None or not same_version_line(minimum_zig, zig_version))
    ):
        failures.append(
            "discovered a staged Zig candidate at "
            f"{matching_zig_candidates[0]}; rerun with `--zig {matching_zig_candidates[0]}` "
            "to use the branch-compatible toolchain"
        )

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

    saved_archives_root = None
    discovered_saved_archives: dict[str, pathlib.Path] = {}
    suggested_prepare_command = None
    if args.expect_saved_archives:
        saved_archives_root = pathlib.Path(args.saved_archives_root).resolve() if args.saved_archives_root else (
            repo_root.parent / "memory" / "repo_archives" / "browser"
        ).resolve()
        saved_archive_failures, discovered_saved_archives = check_saved_archives_root(saved_archives_root)
        failures.extend(saved_archive_failures)

        prepare_script_path = repo_root / "scripts" / "linux" / "prepare_offline_build_inputs.sh"
        if not prepare_script_path.is_file():
            failures.append(f"offline prepare script is missing: expected {prepare_script_path}")
        elif all(key in discovered_saved_archives for key in ("browser_deps", "boringssl")):
            suggested_prepare_command = build_prepare_offline_command(repo_root, discovered_saved_archives)

    fallback_zig_archive = pathlib.Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None
    fallback_zig_archive = resolve_fallback_zig_archive(repo_root, fallback_zig_archive)
    fallback_zig_version: str | None = None
    fallback_zig_status: str | None = None
    if fallback_zig_archive is not None:
        fallback_failures, fallback_zig_version, fallback_zig_status = describe_fallback_zig_archive(
            minimum_zig,
            fallback_zig_archive,
        )
        failures.extend(fallback_failures)
        if (
            not args.skip_zig_check
            and zig_version is None
            and fallback_zig_status is not None
            and fallback_zig_version is not None
            and fallback_zig_status.startswith("mismatched:")
        ):
            expected_parts = parse_semver(minimum_zig)
            failures.append(
                "fallback Zig archive "
                f"{fallback_zig_archive.name} surfaces Zig {fallback_zig_version}, "
                f"which does not match the branch's expected {expected_parts[0]}.{expected_parts[1]}.x line"
            )

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

    print(f"Toolchains root: {toolchains_root}")
    if zig_candidate_reports:
        print("Discovered Zig candidates:")
        for candidate_report in zig_candidate_reports:
            version_text = candidate_report["version"] or "unknown"
            print(
                f"  - {candidate_report['path']} [{version_text}; {candidate_report['status']}]"
            )
    else:
        print("Discovered Zig candidates: none")

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

    if saved_archives_root is not None:
        print(f"Saved archive root: {saved_archives_root}")
        for key in (*REQUIRED_SAVED_ARCHIVE_KEYS, *OPTIONAL_SAVED_ARCHIVE_KEYS):
            archive_path = discovered_saved_archives.get(key)
            state = "ok" if archive_path is not None else "optional missing" if key in OPTIONAL_SAVED_ARCHIVE_KEYS else "missing"
            location = str(archive_path) if archive_path is not None else SAVED_ARCHIVE_GLOBS[key]
            print(f"  - {SAVED_ARCHIVE_LABELS[key]}: {location} [{state}]")
        if suggested_prepare_command is not None:
            print("Suggested offline staging command:")
            print(f"  {format_shell_command(suggested_prepare_command)}")

    if fallback_zig_archive is not None:
        fallback_state = "ok" if fallback_zig_archive.is_file() else "missing"
        print(f"Fallback Zig archive: {fallback_zig_archive} [{fallback_state}]")
        if fallback_zig_version is not None and fallback_zig_status is not None:
            print(f"Fallback Zig archive version line: {fallback_zig_version} [{fallback_zig_status}]")

    if url_deps:
        print("URL-backed dependencies still need network access or an offline cache:")
        for name in url_deps:
            print(f"  - {name}")

    if failures:
        print("\nReadiness check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        next_step = (
            "run the saved-archive restore command above, use the saved Rust toolchain, and retry `zig build` with a Zig 0.15.2 toolchain."
            if suggested_prepare_command is not None
            else "stage sibling dependencies plus ../offline-deps with scripts/linux/prepare_offline_build_inputs.sh, use the saved Rust toolchain, and retry `zig build` with a Zig 0.15.2 toolchain."
        )
        print(f"\nSuggested next step: {next_step}", file=sys.stderr)
        return 1

    print("\nReadiness check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())