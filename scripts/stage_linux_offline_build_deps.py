#!/usr/bin/env python3

"""Stage the saved offline Linux build archives into the branch layout.

This helper is meant for runs that have the browser checkout plus the archived
dependency bundles nearby, but not a ready-to-build sibling workspace yet.
"""

from __future__ import annotations

import argparse
import pathlib
import re
import shutil
import sys
import tarfile
import tempfile
import zipfile


MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')
PATH_VALUE_RE = re.compile(r'\.path\s*=\s*"([^"]+)"')
URL_VALUE_RE = re.compile(r'\.url\s*=\s*"([^"]+)"')

BUNDLE_ARCHIVE_GLOBS = ("*zig-browser-depo*.zip",)
BORINGSSL_ARCHIVE_GLOBS = ("*boringssl-zig*.zip",)

V8_TARBALL_RE = re.compile(r"(^|/)zig-v8-fork-.*\.tar\.gz$")
PREBUILT_V8_RE = re.compile(r"(^|/)libc_v8_.*\.a$")
URL_TARBALL_PATTERNS = {
    "brotli": re.compile(r"(^|/)brotli-.*\.tar\.gz$"),
    "zlib": re.compile(r"(^|/)zlib-.*\.tar\.gz$"),
    "nghttp2": re.compile(r"(^|/)nghttp2-.*\.tar\.gz$"),
    "curl": re.compile(r"(^|/)curl-.*\.tar\.gz$"),
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
        match = re.search(
            r'\.(?P<name>@?"[^"]+"|[A-Za-z0-9_]+)\s*=\s*\.\{',
            dependencies_block[cursor:],
        )
        if match is None:
            break

        raw_name = match.group("name")
        relative_start = cursor + match.start()
        body_open = dependencies_block.find("{", relative_start)
        body = extract_braced_block(dependencies_block, body_open)
        entries.append((normalize_name(raw_name), body))
        cursor = body_open + len(body)

    return entries


def load_build_metadata(repo_root: pathlib.Path) -> tuple[str, dict[str, pathlib.Path], list[str]]:
    zon_path = repo_root / "build.zig.zon"
    text = zon_path.read_text(encoding="utf-8")

    minimum_match = MINIMUM_ZIG_RE.search(text)
    if minimum_match is None:
        raise ValueError(f"Could not find minimum_zig_version in {zon_path}")

    path_deps: dict[str, pathlib.Path] = {}
    url_deps: list[str] = []
    for name, body in parse_dependency_blocks(text):
        path_match = PATH_VALUE_RE.search(body)
        if path_match is not None:
            path_deps[name] = (repo_root / path_match.group(1)).resolve()
            continue

        url_match = URL_VALUE_RE.search(body)
        if url_match is not None:
            url_deps.append(name)

    return minimum_match.group(1), path_deps, url_deps


def find_first_archive(archives_dir: pathlib.Path, globs: tuple[str, ...]) -> pathlib.Path:
    matches: list[pathlib.Path] = []
    for pattern in globs:
        matches.extend(sorted(archives_dir.glob(pattern)))
    if not matches:
        raise FileNotFoundError(
            f"Could not find an archive matching {', '.join(globs)} in {archives_dir}"
        )
    return matches[0]


def choose_member(names: list[str], pattern: re.Pattern[str], label: str) -> str:
    for name in names:
        if pattern.search(name):
            return name
    raise FileNotFoundError(f"Could not find {label} inside the bundle archive")


def ensure_parent(path: pathlib.Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def remove_existing(path: pathlib.Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def prepare_destination(path: pathlib.Path, force: bool) -> None:
    if not path.exists():
        ensure_parent(path)
        return
    if not force:
        raise FileExistsError(f"{path} already exists; rerun with --force to replace it")
    remove_existing(path)
    ensure_parent(path)


def assert_relative_member(name: str) -> None:
    member_path = pathlib.PurePosixPath(name)
    if member_path.is_absolute() or ".." in member_path.parts:
        raise ValueError(f"Unsafe archive member path: {name}")


def copy_zip_member(zip_path: pathlib.Path, member_name: str, output_path: pathlib.Path) -> None:
    prepare_destination(output_path, force=True)
    ensure_parent(output_path)
    with zipfile.ZipFile(zip_path) as archive:
        with archive.open(member_name) as src, output_path.open("wb") as dst:
            shutil.copyfileobj(src, dst)


def extract_top_level_zip_tree(zip_path: pathlib.Path, destination: pathlib.Path, force: bool) -> str:
    with zipfile.ZipFile(zip_path) as archive:
        file_names = [name for name in archive.namelist() if name and not name.endswith("/")]
        if not file_names:
            raise ValueError(f"{zip_path} does not contain files")
        for name in file_names:
            assert_relative_member(name)

        top_levels = {pathlib.PurePosixPath(name).parts[0] for name in file_names}
        if len(top_levels) != 1:
            raise ValueError(
                f"{zip_path} should contain exactly one top-level folder, found {sorted(top_levels)}"
            )

        top_level = next(iter(top_levels))
        prepare_destination(destination, force)
        with tempfile.TemporaryDirectory(prefix="stage-boringssl-", dir=str(destination.parent)) as temp_dir:
            temp_root = pathlib.Path(temp_dir)
            archive.extractall(temp_root)
            extracted = temp_root / top_level
            shutil.move(str(extracted), str(destination))
        return top_level


def extract_top_level_tar_tree(tar_path: pathlib.Path, destination: pathlib.Path, force: bool) -> str:
    with tarfile.open(tar_path, "r:*") as archive:
        members = archive.getmembers()
        file_members = [member for member in members if member.name and member.isfile()]
        if not file_members:
            raise ValueError(f"{tar_path} does not contain files")
        for member in members:
            if member.name:
                assert_relative_member(member.name)

        top_levels = {pathlib.PurePosixPath(member.name).parts[0] for member in file_members}
        if len(top_levels) != 1:
            raise ValueError(
                f"{tar_path} should contain exactly one top-level folder, found {sorted(top_levels)}"
            )

        top_level = next(iter(top_levels))
        prepare_destination(destination, force)
        with tempfile.TemporaryDirectory(prefix="stage-v8-", dir=str(destination.parent)) as temp_dir:
            temp_root = pathlib.Path(temp_dir)
            try:
                archive.extractall(temp_root, filter="data")
            except TypeError:
                archive.extractall(temp_root)
            extracted = temp_root / top_level
            shutil.move(str(extracted), str(destination))
        return top_level


def copy_named_members(
    zip_path: pathlib.Path,
    members: dict[str, str],
    cache_dir: pathlib.Path,
    force: bool,
) -> dict[str, pathlib.Path]:
    cache_dir.mkdir(parents=True, exist_ok=True)
    staged: dict[str, pathlib.Path] = {}
    with zipfile.ZipFile(zip_path) as archive:
        for label, member_name in members.items():
            output_path = cache_dir / pathlib.PurePosixPath(member_name).name
            if output_path.exists() and not force:
                raise FileExistsError(
                    f"{output_path} already exists; rerun with --force to replace it"
                )
            if output_path.exists():
                remove_existing(output_path)
            with archive.open(member_name) as src, output_path.open("wb") as dst:
                shutil.copyfileobj(src, dst)
            staged[label] = output_path
    return staged


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Stage offline Linux build archives into the sibling layout expected by this branch."
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--archives-dir",
        required=True,
        help="Directory that holds the saved dependency archives",
    )
    parser.add_argument(
        "--cache-dir",
        default=None,
        help="Directory for cached URL-backed tarballs and the prebuilt V8 archive (default: <repo-root-parent>/.offline-zig-deps)",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Perform extraction and copying. Without this flag the helper prints a dry-run plan only.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Replace existing staged directories or files when applying.",
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()

    repo_root = pathlib.Path(args.repo_root).resolve()
    archives_dir = pathlib.Path(args.archives_dir).resolve()
    cache_dir = pathlib.Path(args.cache_dir).resolve() if args.cache_dir else repo_root.parent / ".offline-zig-deps"

    zon_path = repo_root / "build.zig.zon"
    if not zon_path.is_file():
        print(f"ERROR: {zon_path} not found", file=sys.stderr)
        return 2
    if not archives_dir.is_dir():
        print(f"ERROR: {archives_dir} not found", file=sys.stderr)
        return 2

    minimum_zig, path_deps, url_deps = load_build_metadata(repo_root)
    bundle_archive = find_first_archive(archives_dir, BUNDLE_ARCHIVE_GLOBS)
    boringssl_archive = find_first_archive(archives_dir, BORINGSSL_ARCHIVE_GLOBS)

    with zipfile.ZipFile(bundle_archive) as bundle:
        bundle_names = [name for name in bundle.namelist() if name and not name.endswith("/")]

    v8_tarball_member = choose_member(bundle_names, V8_TARBALL_RE, "zig-v8 tarball")
    prebuilt_v8_member = choose_member(bundle_names, PREBUILT_V8_RE, "prebuilt V8 library")
    url_members = {
        name: choose_member(bundle_names, URL_TARBALL_PATTERNS[name], f"{name} tarball")
        for name in url_deps
        if name in URL_TARBALL_PATTERNS
    }

    missing_url_members = [name for name in url_deps if name not in url_members]
    if missing_url_members:
        print(
            "ERROR: The bundle archive is missing expected URL-backed tarballs for: "
            + ", ".join(sorted(missing_url_members)),
            file=sys.stderr,
        )
        return 1

    print(f"Repo root: {repo_root}")
    print(f"Archives dir: {archives_dir}")
    print(f"Offline cache dir: {cache_dir}")
    print(f"Minimum Zig from build.zig.zon: {minimum_zig}")
    print(f"Bundle archive: {bundle_archive.name}")
    print(f"BoringSSL archive: {boringssl_archive.name}")
    print("Planned sibling staging:")
    for dep_name, dep_path in sorted(path_deps.items()):
        state = "present" if dep_path.exists() else "missing"
        print(f"  - {dep_name}: {dep_path} [{state}]")

    print("Planned bundle members:")
    print(f"  - v8 source tarball: {pathlib.PurePosixPath(v8_tarball_member).name}")
    print(f"  - prebuilt V8 archive: {pathlib.PurePosixPath(prebuilt_v8_member).name}")
    for dep_name in sorted(url_members):
        print(f"  - {dep_name}: {pathlib.PurePosixPath(url_members[dep_name]).name}")

    if not args.apply:
        print("\nDry run only. Re-run with --apply to stage the archives.")
        print(
            "Suggested next step: after staging, run `python scripts/check_linux_build_readiness.py --repo-root . --skip-zig-check` from the browser checkout."
        )
        return 0

    boringssl_dest = path_deps.get("boringssl-zig")
    v8_dest = path_deps.get("v8")
    if boringssl_dest is None or v8_dest is None:
        print(
            "ERROR: build.zig.zon no longer declares both boringssl-zig and v8 sibling paths",
            file=sys.stderr,
        )
        return 1

    staged_url_files = copy_named_members(
        bundle_archive,
        {**url_members, "prebuilt_v8": prebuilt_v8_member},
        cache_dir,
        args.force,
    )
    top_level_boringssl = extract_top_level_zip_tree(
        boringssl_archive, boringssl_dest, args.force
    )

    with tempfile.TemporaryDirectory(prefix="stage-v8-tar-", dir=str(cache_dir)) as temp_dir:
        temp_tarball = pathlib.Path(temp_dir) / pathlib.PurePosixPath(v8_tarball_member).name
        copy_zip_member(bundle_archive, v8_tarball_member, temp_tarball)
        top_level_v8 = extract_top_level_tar_tree(temp_tarball, v8_dest, args.force)

    print("\nStaging complete.")
    print(f"  - boringssl-zig extracted from {top_level_boringssl} -> {boringssl_dest}")
    print(f"  - v8 extracted from {top_level_v8} -> {v8_dest}")
    print(f"  - offline cache files staged under {cache_dir}")
    print(f"  - prebuilt V8 path: {staged_url_files['prebuilt_v8']}")
    print(
        "\nSuggested next steps:\n"
        f"  1. Run `python scripts/check_linux_build_readiness.py --repo-root {repo_root} --skip-zig-check`\n"
        f"  2. Retry Zig with an actual {minimum_zig} toolchain and `-Dprebuilt_v8_path={staged_url_files['prebuilt_v8']}`"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())