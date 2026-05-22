#!/usr/bin/env python3

"""Check whether this checkout is ready for Linux/WSL Zig validation.

This helper is intentionally lightweight:
- reads build.zig.zon to discover the pinned Zig line and sibling path deps
- checks an installed Zig version unless told to skip it
- verifies the sibling checkout layout required by this fork
- reminds the caller that URL-backed deps still need an offline cache or network
"""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
PATH_VALUE_RE = re.compile(r'\.path\s*=\s*"([^"]+)"')
URL_VALUE_RE = re.compile(r'\.url\s*=\s*"([^"]+)"')


def normalize_name(raw: str) -> str:
    return raw.replace('@', "").strip('"')


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
        name_match = re.search(r"\.(?P<name>@?\"[^\"]+\"|[A-Za-z0-9_]+)\s*=\s*\.\{", dependencies_block[cursor:])
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
    match = re.match(r"^(\d+)\.(\d+)\.(\d+)", version_text)
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


def check_zig_version(repo_root: pathlib.Path, minimum_zig: str, zig_cmd: str) -> list[str]:
    del repo_root
    failures: list[str] = []
    try:
        completed = subprocess.run(
            [zig_cmd, "version"],
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        failures.append(
            f"zig not found on PATH (expected a {minimum_zig} toolchain or an explicit --zig path)"
        )
        return failures
    except subprocess.CalledProcessError as exc:
        failures.append(f"zig version failed with exit code {exc.returncode}")
        return failures

    installed = completed.stdout.strip()
    minimum_parts = parse_semver(minimum_zig)
    installed_parts = parse_semver(installed)
    if installed_parts < minimum_parts:
        failures.append(
            f"zig {installed} is older than the branch minimum {minimum_zig}"
        )
        return failures

    if installed_parts[:2] != minimum_parts[:2]:
        failures.append(
            f"zig {installed} does not match the branch's expected {minimum_parts[0]}.{minimum_parts[1]}.x line"
        )
    return failures


def check_path_dependencies(path_deps: list[tuple[str, pathlib.Path]]) -> list[str]:
    failures: list[str] = []
    for name, dep_path in path_deps:
        if not dep_path.exists():
            failures.append(f"missing sibling dependency {name}: expected {dep_path}")
    return failures


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Check Zig toolchain and sibling dependency readiness for Linux/WSL validation."
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
        "--skip-zig-check",
        action="store_true",
        help="Skip calling `zig version` and only validate the repo layout",
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()
    repo_root = pathlib.Path(args.repo_root).resolve()
    zon_path = repo_root / "build.zig.zon"
    if not zon_path.is_file():
        print(f"ERROR: {zon_path} not found", file=sys.stderr)
        return 2

    minimum_zig, path_deps, url_deps = load_build_metadata(repo_root)
    failures: list[str] = []
    if not args.skip_zig_check:
        failures.extend(check_zig_version(repo_root, minimum_zig, args.zig))
    failures.extend(check_path_dependencies(path_deps))

    print(f"Repo root: {repo_root}")
    print(f"Minimum Zig from build.zig.zon: {minimum_zig}")
    if path_deps:
        print("Sibling path dependencies:")
        for name, dep_path in path_deps:
            state = "ok" if dep_path.exists() else "missing"
            print(f"  - {name}: {dep_path} [{state}]")

    if url_deps:
        print("URL-backed dependencies still need network access or an offline cache:")
        for name in url_deps:
            print(f"  - {name}")

    if failures:
        print("\nReadiness check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        print(
            "\nSuggested next step: use a Zig toolchain on the declared branch line and stage the sibling dependencies before retrying `zig build`.",
            file=sys.stderr,
        )
        return 1

    print("\nReadiness check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
