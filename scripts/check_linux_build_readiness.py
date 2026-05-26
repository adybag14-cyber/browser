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
import json
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


def ancestor_chain(start: pathlib.Path) -> list[pathlib.Path]:
    chain: list[pathlib.Path] = []
    current = start.resolve()
    while True:
        chain.append(current)
        if current.parent == current:
            break
        current = current.parent
    return chain


def locate_first_existing(start: pathlib.Path, relative_path: str) -> pathlib.Path | None:
    for ancestor in ancestor_chain(start):
        candidate = ancestor / relative_path
        if candidate.exists():
            return candidate.resolve()
    return None


def resolve_default_agent_files_root(repo_root: pathlib.Path) -> pathlib.Path:
    located = locate_first_existing(repo_root, "agent_files")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "agent_files").resolve()


def resolve_default_toolchains_root(repo_root: pathlib.Path) -> pathlib.Path:
    located = locate_first_existing(repo_root, "toolchains")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "toolchains").resolve()


def resolve_default_memory_root(repo_root: pathlib.Path) -> pathlib.Path:
    located = locate_first_existing(repo_root, "memory")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "memory").resolve()


def resolve_default_offline_deps_root(repo_root: pathlib.Path) -> pathlib.Path:
    located = locate_first_existing(repo_root, "offline-deps")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "offline-deps").resolve()


def resolve_default_saved_archives_root(repo_root: pathlib.Path) -> pathlib.Path:
    return (resolve_default_memory_root(repo_root) / "repo_archives" / "browser").resolve()


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


def normalize_saved_archives_root(saved_archives_root: pathlib.Path) -> pathlib.Path:
    dependencies_root = saved_archives_root / "dependencies"
    if dependencies_root.is_dir():
        return dependencies_root.resolve()
    return saved_archives_root.resolve()


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


def serialize_readiness_value(value: object) -> object:
    if isinstance(value, pathlib.Path):
        return str(value)
    if isinstance(value, dict):
        return {str(key): serialize_readiness_value(inner_value) for key, inner_value in value.items()}
    if isinstance(value, (list, tuple)):
        return [serialize_readiness_value(item) for item in value]
    return value


def build_readiness_report(
    *,
    repo_root: pathlib.Path,
    minimum_zig: str,
    zig_version: str | None,
    rust_versions: dict[str, str],
    path_deps: list[tuple[str, pathlib.Path]],
    discovered_zig_candidates: list[dict[str, pathlib.Path | str | None]],
    matching_zig_candidates: list[pathlib.Path],
    toolchains_root: pathlib.Path,
    offline_deps_root: pathlib.Path | None,
    staged_offline_dirs: list[tuple[str, pathlib.Path]],
    prebuilt_archives: list[pathlib.Path],
    saved_archives_root: pathlib.Path | None,
    discovered_saved_archives: dict[str, pathlib.Path],
    suggested_prepare_command: list[str] | None,
    fallback_zig_archive: pathlib.Path | None,
    fallback_zig_version: str | None,
    fallback_zig_status: str | None,
    url_deps: list[str],
    failures: list[str],
    suggested_next_step: str | None,
) -> dict[str, object]:
    return {
        "status": "failed" if failures else "passed",
        "repo_root": repo_root,
        "minimum_zig": minimum_zig,
        "installed_zig": zig_version,
        "rust_versions": rust_versions,
        "path_dependencies": [{"name": name, "path": dep_path} for name, dep_path in path_deps],
        "toolchains_root": toolchains_root,
        "zig_candidates": discovered_zig_candidates,
        "matching_zig_candidates": matching_zig_candidates,
        "offline_deps_root": offline_deps_root,
        "offline_dependency_dirs": [{"name": name, "path": dep_path} for name, dep_path in staged_offline_dirs],
        "prebuilt_v8_archives": prebuilt_archives,
        "saved_archives_root": saved_archives_root,
        "saved_archives": discovered_saved_archives,
        "suggested_prepare_command": suggested_prepare_command,
        "fallback_zig_archive": fallback_zig_archive,
        "fallback_zig_version": fallback_zig_version,
        "fallback_zig_status": fallback_zig_status,
        "url_dependencies": url_deps,
        "failures": failures,
        "suggested_next_step": suggested_next_step,
    }


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
        help":"rustc executable to probe (default: rustc on PATH)"
    )