#!/usr/bin/env python3
"""Check Linux prerequisites for local headed-mode validation."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tarfile
import zipfile
from pathlib import Path


EXPECTED_ARCHIVES = (
    (
        "rust-toolchain",
        "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
        "local Rust toolchain archive used by headed-mode builds",
        "tar",
    ),
    (
        "litefetch-html5ever-deps",
        "02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip",
        "cached litefetch/html5ever Linux dependency bundle",
        "zip",
    ),
    (
        "boringssl-zig-source",
        "03-boringssl-zig-main.zip",
        "saved BoringSSL Zig source bundle",
        "zip",
    ),
    (
        "zig-browser-depo",
        "04-zig-browser-depo.tar.zip",
        "saved Zig browser dependency archive",
        "zip",
    ),
)


def write_status(name: str, level: str, details: str) -> None:
    print(f"[{level}] {name} - {details}")


def command_version(command: str, args: list[str]) -> str | None:
    try:
        proc = subprocess.run(
            [command, *args],
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError:
        return None
    if proc.returncode != 0:
        return None
    output = (proc.stdout or proc.stderr).strip()
    if not output:
        return None
    return output.splitlines()[0].strip()


def check_command(name: str, command: str, args: list[str], failure_hint: str) -> bool:
    version = command_version(command, args)
    if version is None:
        write_status(name, "FAIL", failure_hint)
        return False
    write_status(name, "PASS", version)
    return True


def archive_is_readable(path: Path, archive_kind: str) -> bool:
    try:
        if archive_kind == "zip":
            return zipfile.is_zipfile(path)
        if archive_kind == "tar":
            return tarfile.is_tarfile(path)
    except OSError:
        return False
    raise ValueError(f"unsupported archive kind: {archive_kind}")


def check_dependency_archives(deps_root: Path) -> bool:
    all_ok = True
    for label, filename, description, archive_kind in EXPECTED_ARCHIVES:
        archive_path = deps_root / filename
        if not archive_path.exists():
            write_status(label, "FAIL", f"missing {filename} ({description})")
            all_ok = False
            continue
        size_bytes = archive_path.stat().st_size
        if not archive_is_readable(archive_path, archive_kind):
            write_status(label, "FAIL", f"{filename} exists but is not a readable {archive_kind} archive")
            all_ok = False
            continue
        mib = size_bytes / (1024 * 1024)
        write_status(label, "PASS", f"{filename} present and readable ({mib:.1f} MiB)")
    return all_ok


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Check Linux prerequisites for local headed-mode build and localhost "
            "validation workflows."
        )
    )
    parser.add_argument(
        "--deps-root",
        type=Path,
        default=None,
        help=(
            "Directory containing the saved dependency archives. If omitted, "
            "archive validation is skipped."
        ),
    )
    parser.add_argument(
        "--zig-archive",
        type=Path,
        default=None,
        help=(
            "Optional path to a fallback Zig archive. This helper verifies that "
            "the archive exists and is readable, but it does not unpack it."
        ),
    )
    args = parser.parse_args()

    all_ok = True

    write_status("python", "PASS", sys.version.splitlines()[0])

    all_ok &= check_command(
        "zig",
        "zig",
        ["version"],
        "zig not found in PATH; headed-mode builds and focused Zig tests will not run",
    )
    all_ok &= check_command(
        "tar",
        "tar",
        ["--version"],
        "tar not found in PATH; saved toolchain archives cannot be unpacked",
    )
    all_ok &= check_command(
        "unzip",
        "unzip",
        ["-v"],
        "unzip not found in PATH; saved dependency bundles cannot be unpacked",
    )

    python_http = shutil.which("python3") or shutil.which("python")
    if python_http is None:
        write_status(
            "localhost-server",
            "FAIL",
            "neither python3 nor python is available for python -m http.server style localhost hosting",
        )
        all_ok = False
    else:
        write_status(
            "localhost-server",
            "PASS",
            f"found {python_http} for local page hosting",
        )

    if args.deps_root is None:
        write_status(
            "dependency-archives",
            "WARN",
            "archive validation skipped; pass --deps-root to verify the saved headed-mode bundles",
        )
    else:
        deps_root = args.deps_root.expanduser().resolve()
        if not deps_root.exists():
            write_status("dependency-archives", "FAIL", f"{deps_root} does not exist")
            all_ok = False
        elif not deps_root.is_dir():
            write_status("dependency-archives", "FAIL", f"{deps_root} is not a directory")
            all_ok = False
        else:
            all_ok &= check_dependency_archives(deps_root)

    if args.zig_archive is None:
        write_status(
            "zig-archive",
            "WARN",
            "fallback Zig archive validation skipped; pass --zig-archive to verify a saved extractor toolchain",
        )
    else:
        zig_archive = args.zig_archive.expanduser().resolve()
        if not zig_archive.exists():
            write_status("zig-archive", "FAIL", f"{zig_archive} does not exist")
            all_ok = False
        elif not zig_archive.is_file():
            write_status("zig-archive", "FAIL", f"{zig_archive} is not a file")
            all_ok = False
        elif not tarfile.is_tarfile(zig_archive):
            write_status("zig-archive", "FAIL", f"{zig_archive.name} is not a readable tar archive")
            all_ok = False
        else:
            mib = zig_archive.stat().st_size / (1024 * 1024)
            write_status(
                "zig-archive",
                "PASS",
                f"{zig_archive.name} present and readable ({mib:.1f} MiB)",
            )

    write_status(
        "zig-toolchain-note",
        "WARN",
        "if focused Zig validation still fails in untouched source, confirm you are using the branch's normal build toolchain and not only a fallback extractor toolchain",
    )

    print()
    if all_ok:
        print(
            "Linux prerequisites look ready for local headed-mode archive prep and localhost validation."
        )
        return 0

    print("One or more required Linux prerequisites failed.")
    print("Resolve the FAIL lines above before running headed-mode build or localhost validation steps.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
