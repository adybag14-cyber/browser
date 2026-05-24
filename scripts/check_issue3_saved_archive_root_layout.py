#!/usr/bin/env python3

"""Check the saved dependency-archive root used by the issue #3 Linux route."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shlex
import unittest


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
DEFAULT_SAVED_ARCHIVES_SUBDIR = "dependencies"


def resolve_default_saved_archives_root(repo_root: Path) -> Path:
    return (
        repo_root.parent / "memory" / "repo_archives" / "browser" / DEFAULT_SAVED_ARCHIVES_SUBDIR
    ).resolve()


def discover_saved_archives(saved_archives_root: Path) -> dict[str, Path]:
    discovered: dict[str, Path] = {}
    for key, pattern in SAVED_ARCHIVE_GLOBS.items():
        matches = sorted(saved_archives_root.glob(pattern))
        if matches:
            discovered[key] = matches[0]
    return discovered


def format_shell_command(command: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in command)


def build_readiness_command(repo_root: Path, saved_archives_root: Path) -> list[str]:
    return [
        "python",
        str(repo_root / "scripts" / "check_linux_build_readiness.py"),
        "--repo-root",
        str(repo_root),
        "--skip-zig-check",
        "--skip-rust-check",
        "--expect-saved-archives",
        "--saved-archives-root",
        str(saved_archives_root),
    ]


def build_prepare_command(repo_root: Path, discovered_saved_archives: dict[str, Path]) -> list[str]:
    command = [
        "bash",
        str(repo_root / "scripts" / "linux" / "prepare_offline_build_inputs.sh"),
        "--browser-root",
        str(repo_root),
        "--browser-deps-archive",
        str(discovered_saved_archives["browser_deps"]),
        "--boringssl-archive",
        str(discovered_saved_archives["boringssl"]),
        "--check-only",
    ]
    html5ever_archive = discovered_saved_archives.get("html5ever")
    if html5ever_archive is not None:
        command[-1:-1] = ["--html5ever-archive", str(html5ever_archive)]
    return command


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check the saved dependency-archive root used by the issue #3 Linux "
            "or WSL recovery helpers and print the exact readiness command that "
            "targets it."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help=(
            "Path to the saved dependency-archive root "
            "(default: ../memory/repo_archives/browser/dependencies beside the repo workspace)"
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


class SavedArchiveRootLayoutTests(unittest.TestCase):
    def test_default_saved_archives_root_uses_dependencies_dir(self) -> None:
        repo_root = Path("/tmp/workspace/browser")
        expected = Path("/tmp/workspace/memory/repo_archives/browser/dependencies")
        self.assertEqual(resolve_default_saved_archives_root(repo_root), expected)

    def test_discover_saved_archives_finds_required_and_optional_files(self) -> None:
        with self.subTest("archive discovery"):
            from tempfile import TemporaryDirectory

            with TemporaryDirectory() as tmpdir:
                root = Path(tmpdir)
                (root / "01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz").write_text("rust", encoding="utf-8")
                (root / "02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip").write_text(
                    "html5ever",
                    encoding="utf-8",
                )
                (root / "03-boringssl-zig-main.zip").write_text("boringssl", encoding="utf-8")
                (root / "04-zig-browser-depo.tar.zip").write_text("browser-deps", encoding="utf-8")

                discovered = discover_saved_archives(root)

                self.assertEqual(set(discovered), set(SAVED_ARCHIVE_GLOBS))

    def test_prepare_command_includes_optional_html5ever_archive_before_check_only(self) -> None:
        repo_root = Path("/tmp/browser")
        discovered_saved_archives = {
            "browser_deps": Path("/tmp/memory/repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip"),
            "boringssl": Path("/tmp/memory/repo_archives/browser/dependencies/03-boringssl-zig-main.zip"),
            "html5ever": Path(
                "/tmp/memory/repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip"
            ),
        }

        command = build_prepare_command(repo_root, discovered_saved_archives)

        self.assertIn("--html5ever-archive", command)
        self.assertEqual(command[-1], "--check-only")


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedArchiveRootLayoutTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    saved_archives_root = (
        Path(args.saved_archives_root).resolve()
        if args.saved_archives_root
        else resolve_default_saved_archives_root(repo_root)
    )

    failures: list[str] = []
    discovered_saved_archives: dict[str, Path] = {}

    if not saved_archives_root.exists():
        failures.append(f"saved archive root is missing: expected {saved_archives_root}")
    elif not saved_archives_root.is_dir():
        failures.append(f"saved archive root is not a directory: {saved_archives_root}")
    else:
        discovered_saved_archives = discover_saved_archives(saved_archives_root)
        for key in REQUIRED_SAVED_ARCHIVE_KEYS:
            if key not in discovered_saved_archives:
                failures.append(
                    f"missing {SAVED_ARCHIVE_LABELS[key]} under {saved_archives_root} "
                    f"(expected {SAVED_ARCHIVE_GLOBS[key]})"
                )

    readiness_command = build_readiness_command(repo_root, saved_archives_root)
    prepare_command = None
    if all(key in discovered_saved_archives for key in ("browser_deps", "boringssl")):
        prepare_command = build_prepare_command(repo_root, discovered_saved_archives)

    if args.json:
        payload = {
            "repo_root": str(repo_root),
            "saved_archives_root": str(saved_archives_root),
            "archives": {
                key: {
                    "label": SAVED_ARCHIVE_LABELS[key],
                    "path": str(discovered_saved_archives[key]) if key in discovered_saved_archives else None,
                    "required": key in REQUIRED_SAVED_ARCHIVE_KEYS,
                }
                for key in (*REQUIRED_SAVED_ARCHIVE_KEYS, *OPTIONAL_SAVED_ARCHIVE_KEYS)
            },
            "readiness_command": format_shell_command(readiness_command),
            "prepare_command": format_shell_command(prepare_command) if prepare_command else None,
            "failures": failures,
        }
        print(json.dumps(payload, indent=2))
        return 0 if not failures else 1

    if failures:
        print("Saved archive dependency-root check failed:")
        for failure in failures:
            print(f"  - {failure}")
    else:
        print("Saved archive dependency-root check passed.")

    print(f"Repo root: {repo_root}")
    print(f"Saved archives root: {saved_archives_root}")
    for key in (*REQUIRED_SAVED_ARCHIVE_KEYS, *OPTIONAL_SAVED_ARCHIVE_KEYS):
        archive_path = discovered_saved_archives.get(key)
        state = "ok" if archive_path is not None else "optional missing" if key in OPTIONAL_SAVED_ARCHIVE_KEYS else "missing"
        location = str(archive_path) if archive_path is not None else SAVED_ARCHIVE_GLOBS[key]
        print(f"  - {SAVED_ARCHIVE_LABELS[key]}: {location} [{state}]")

    print("Suggested readiness probe:")
    print(f"  {format_shell_command(readiness_command)}")
    if prepare_command is not None:
        print("Suggested offline-input staging probe:")
        print(f"  {format_shell_command(prepare_command)}")

    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
