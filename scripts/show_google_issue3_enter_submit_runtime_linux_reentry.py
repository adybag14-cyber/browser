#!/usr/bin/env python3
"""Print the Linux/offline re-entry commands for the issue #3 runtime slice."""

from __future__ import annotations

import argparse
import json
import pathlib
import shlex
import unittest
from unittest import mock


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

REQUIRED_ARCHIVE_KEYS = ("rust_toolchain", "boringssl", "browser_deps")
OPTIONAL_ARCHIVE_KEYS = ("html5ever",)


def quote_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def discover_saved_archives(saved_archives_root: pathlib.Path) -> dict[str, pathlib.Path]:
    discovered: dict[str, pathlib.Path] = {}
    for key, pattern in SAVED_ARCHIVE_GLOBS.items():
        matches = sorted(saved_archives_root.glob(pattern))
        if matches:
            discovered[key] = matches[0]
    return discovered


def build_readiness_command(
    repo_root: pathlib.Path,
    *,
    skip_zig_check: bool,
    expect_saved_archives: bool,
    expect_offline_deps: bool,
    require_prebuilt_v8: bool,
    saved_archives_root: pathlib.Path,
    offline_deps_root: pathlib.Path,
) -> list[str]:
    command = [
        "python",
        "scripts/check_linux_build_readiness.py",
        "--repo-root",
        str(repo_root),
    ]
    if skip_zig_check:
        command.append("--skip-zig-check")
    if expect_saved_archives:
        command.extend(["--expect-saved-archives", "--saved-archives-root", str(saved_archives_root)])
    if expect_offline_deps:
        command.extend(["--expect-offline-deps", "--offline-deps-root", str(offline_deps_root)])
    if require_prebuilt_v8:
        command.append("--require-prebuilt-v8")
    return command


def build_prepare_command(
    repo_root: pathlib.Path,
    saved_archives: dict[str, pathlib.Path],
    *,
    check_only: bool,
) -> list[str]:
    command = [
        "bash",
        "scripts/linux/prepare_offline_build_inputs.sh",
        "--browser-root",
        str(repo_root),
        "--browser-deps-archive",
        str(saved_archives["browser_deps"]),
        "--boringssl-archive",
        str(saved_archives["boringssl"]),
    ]
    html5ever_archive = saved_archives.get("html5ever")
    if html5ever_archive is not None:
        command.extend(["--html5ever-archive", str(html5ever_archive)])
    if check_only:
        command.append("--check-only")
    return command


def build_route(repo_root: pathlib.Path, saved_archives_root: pathlib.Path) -> dict[str, object]:
    offline_deps_root = (repo_root.parent / "offline-deps").resolve()
    discovered = discover_saved_archives(saved_archives_root)
    missing_required = [
        SAVED_ARCHIVE_LABELS[key]
        for key in REQUIRED_ARCHIVE_KEYS
        if key not in discovered
    ]
    missing_optional = [
        SAVED_ARCHIVE_LABELS[key]
        for key in OPTIONAL_ARCHIVE_KEYS
        if key not in discovered
    ]
    can_restore = not missing_required

    route: dict[str, object] = {
        "issue": "Google issue #3 Enter-submit runtime re-entry",
        "purpose": (
            "Print the saved-archive, offline-restore, and Linux readiness "
            "commands needed before reopening the direct Page.zig and "
            "win32_backend.zig runtime patch."
        ),
        "repo_root": str(repo_root),
        "saved_archives_root": str(saved_archives_root),
        "offline_deps_root": str(offline_deps_root),
        "read_first": [
            "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
            "docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md",
        ],
        "archive_status": [
            {
                "label": SAVED_ARCHIVE_LABELS[key],
                "path": str(discovered[key]) if key in discovered else SAVED_ARCHIVE_GLOBS[key],
                "required": key in REQUIRED_ARCHIVE_KEYS,
                "present": key in discovered,
            }
            for key in (*REQUIRED_ARCHIVE_KEYS, *OPTIONAL_ARCHIVE_KEYS)
        ],
        "missing_required_archives": missing_required,
        "missing_optional_archives": missing_optional,
        "commands": {
            "saved_archive_preflight": quote_command(
                build_readiness_command(
                    repo_root,
                    skip_zig_check=True,
                    expect_saved_archives=True,
                    expect_offline_deps=False,
                    require_prebuilt_v8=False,
                    saved_archives_root=saved_archives_root,
                    offline_deps_root=offline_deps_root,
                )
            ),
            "post_restore_skip_zig": quote_command(
                build_readiness_command(
                    repo_root,
                    skip_zig_check=True,
                    expect_saved_archives=True,
                    expect_offline_deps=True,
                    require_prebuilt_v8=True,
                    saved_archives_root=saved_archives_root,
                    offline_deps_root=offline_deps_root,
                )
            ),
            "post_restore_full": quote_command(
                build_readiness_command(
                    repo_root,
                    skip_zig_check=False,
                    expect_saved_archives=True,
                    expect_offline_deps=True,
                    require_prebuilt_v8=True,
                    saved_archives_root=saved_archives_root,
                    offline_deps_root=offline_deps_root,
                )
            ),
            "focused_page_tests": "zig test src/browser/Page.zig",
            "focused_win32_tests": "zig test src/display/win32_backend.zig -target x86_64-windows-gnu",
        },
        "notes": [
            "Run the saved-archive preflight before assuming the Zig/toolchain gate is the first failure.",
            "Run the restore check-only command before mutating build.zig.zon or sibling dependency paths.",
            "Only trust the focused Page.zig and win32_backend.zig tests after the post-restore full readiness command stops failing in untouched sources.",
        ],
    }

    if can_restore:
        route["commands"]["restore_check_only"] = quote_command(
            build_prepare_command(repo_root, discovered, check_only=True)
        )
        route["commands"]["restore"] = quote_command(
            build_prepare_command(repo_root, discovered, check_only=False)
        )
    else:
        route["commands"]["restore_check_only"] = "unavailable until the required saved archives are present"
        route["commands"]["restore"] = "unavailable until the required saved archives are present"

    return route


def render_text(route: dict[str, object]) -> str:
    lines: list[str] = []
    lines.append("Google issue #3 Enter-submit Linux/offline re-entry")
    lines.append("")
    lines.append(f"Repo root:           {route['repo_root']}")
    lines.append(f"Saved archives root: {route['saved_archives_root']}")
    lines.append(f"Offline deps root:   {route['offline_deps_root']}")
    lines.append("")
    lines.append("Read first")
    lines.append("==========")
    for item in route["read_first"]:
        lines.append(f"  {item}")
    lines.append("")
    lines.append("Saved archive status")
    lines.append("====================")
    for item in route["archive_status"]:
        status = "present" if item["present"] else "missing"
        required = "required" if item["required"] else "optional"
        lines.append(f"  - {item['label']}: {item['path']} [{required}; {status}]")
    lines.append("")
    lines.append("Commands")
    lines.append("========")
    for key, value in route["commands"].items():
        lines.append(f"  {key}: {value}")
    lines.append("")
    lines.append("Notes")
    lines.append("=====")
    for note in route["notes"]:
        lines.append(f"  - {note}")
    if route["missing_required_archives"]:
        lines.append("")
        lines.append("Missing required archives")
        lines.append("=========================")
        for item in route["missing_required_archives"]:
            lines.append(f"  - {item}")
    return "\n".join(lines)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Print the saved-archive and Linux/offline readiness commands for "
            "the issue #3 Enter-submit runtime re-entry path."
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
            "Path to the saved archive root "
            "(default: ../memory/repo_archives/browser/dependencies beside the repo root)"
        ),
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print the route as JSON instead of text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


class Issue3LinuxReentryHelperTests(unittest.TestCase):
    def test_build_prepare_command_includes_optional_html5ever(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        saved_archives = {
            "browser_deps": pathlib.Path("/tmp/memory/browser/04-zig-browser-depo.tar.zip"),
            "boringssl": pathlib.Path("/tmp/memory/browser/03-boringssl-zig-main.zip"),
            "html5ever": pathlib.Path("/tmp/memory/browser/02-litefetch-html5ever.zip"),
        }
        command = build_prepare_command(repo_root, saved_archives, check_only=True)
        self.assertIn("--html5ever-archive", command)
        self.assertEqual(command[-1], "--check-only")

    def test_route_marks_restore_unavailable_without_required_archives(self) -> None:
        with mock.patch(__name__ + ".discover_saved_archives", return_value={}):
            route = build_route(pathlib.Path("/tmp/browser"), pathlib.Path("/tmp/memory/repo_archives/browser"))
        self.assertIn("saved Rust toolchain archive", route["missing_required_archives"])
        self.assertEqual(
            route["commands"]["restore"],
            "unavailable until the required saved archives are present",
        )

    def test_route_builds_restore_commands_when_archives_exist(self) -> None:
        saved_archives = {
            "rust_toolchain": pathlib.Path("/tmp/memory/browser/01-rust.tar.xz"),
            "boringssl": pathlib.Path("/tmp/memory/browser/03-boringssl-zig-main.zip"),
            "browser_deps": pathlib.Path("/tmp/memory/browser/04-zig-browser-depo.tar.zip"),
        }
        with mock.patch(__name__ + ".discover_saved_archives", return_value=saved_archives):
            route = build_route(pathlib.Path("/tmp/browser"), pathlib.Path("/tmp/memory/repo_archives/browser"))
        self.assertIn("prepare_offline_build_inputs.sh", route["commands"]["restore"])
        self.assertIn("--check-only", route["commands"]["restore_check_only"])


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(Issue3LinuxReentryHelperTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    saved_archives_root = (
        pathlib.Path(args.saved_archives_root).resolve()
        if args.saved_archives_root
        else (repo_root.parent / "memory" / "repo_archives" / "browser" / "dependencies").resolve()
    )
    route = build_route(repo_root, saved_archives_root)

    if args.json:
        print(json.dumps(route, indent=2, sort_keys=False))
    else:
        print(render_text(route))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())