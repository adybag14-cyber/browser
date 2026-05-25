#!/usr/bin/env python3

"""Surface workspace-root-aware route commands for issue #3 Linux/WSL re-entry.

This helper complements the existing workspace-context route by bundling the
most common follow-up commands that issue #11 runs need after root discovery:
- the saved-Memory route surface check and route printer
- the restored-checkout re-entry surface check and route printer
- the issue #11 progress-tracker route printer
- the Linux build-readiness and Zig recovery route printers

It is intentionally lightweight and self-contained so scheduled runs can reuse
it even when the checkout is nested or restored somewhere unusual.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
DEFAULT_RESTORED_CHECKOUT_ROOT_NAME = "browser-memory-snapshot"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Surface workspace-aware route commands for issue #3 Linux/WSL re-entry."
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit path to the attached fallback Zig archive",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused unit tests and exit",
    )
    return parser


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


def infer_root(repo_root: Path, relative_path: str) -> tuple[Path, bool]:
    located = locate_first_existing(repo_root, relative_path)
    if located is not None:
        return located, True
    return (repo_root.parent / relative_path).resolve(), False


def infer_saved_archives_root(repo_root: Path) -> tuple[Path, bool]:
    located = locate_first_existing(repo_root, "memory/repo_archives/browser")
    if located is not None and located.is_dir():
        return located, True
    return (repo_root.parent / "memory" / "repo_archives" / "browser").resolve(), False


def infer_fallback_zig_archive(
    repo_root: Path, explicit_archive: Path | None
) -> tuple[Path | None, bool]:
    if explicit_archive is not None:
        archive = explicit_archive.resolve()
        return archive, archive.is_file()

    located = locate_first_existing(repo_root, f"agent_files/{DEFAULT_FALLBACK_ZIG_ARCHIVE}")
    if located is not None and located.is_file():
        return located, True

    agent_files_root, _ = infer_root(repo_root, "agent_files")
    fallback = (agent_files_root / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve()
    return fallback, fallback.is_file()


def build_command(script: str, args: list[tuple[str, str]]) -> list[str]:
    command = ["bash", script] if script.endswith(".sh") else ["python", script]
    for flag, value in args:
        command.extend((flag, value))
    return command


def collect_context(repo_root: Path, explicit_archive: Path | None) -> dict[str, object]:
    build_zon = repo_root / "build.zig.zon"
    memory_root, memory_found = infer_root(repo_root, "memory")
    toolchains_root, toolchains_found = infer_root(repo_root, "toolchains")
    offline_deps_root, offline_deps_found = infer_root(repo_root, "offline-deps")
    restored_checkout_root, restored_checkout_found = infer_root(
        repo_root, DEFAULT_RESTORED_CHECKOUT_ROOT_NAME
    )
    saved_archives_root, saved_archives_found = infer_saved_archives_root(repo_root)
    fallback_zig_archive, fallback_found = infer_fallback_zig_archive(repo_root, explicit_archive)
    rust_toolchain_dir = (toolchains_root / "rust-1.79.0").resolve()

    shared_args = [
        ("--repo-root", str(repo_root)),
        ("--memory-root", str(memory_root)),
        ("--restored-checkout-root", str(restored_checkout_root)),
        ("--saved-archives-root", str(saved_archives_root)),
        ("--toolchains-root", str(toolchains_root)),
        ("--offline-deps-root", str(offline_deps_root)),
    ]
    if fallback_zig_archive is not None:
        shared_args.append(("--fallback-zig-archive", str(fallback_zig_archive)))

    route_commands = {
        "saved_memory_surface": build_command(
            "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
            shared_args,
        ),
        "saved_memory_route": build_command(
            "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
            shared_args,
        ),
        "restored_checkout_surface": build_command(
            "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh",
            shared_args,
        ),
        "restored_checkout_route": build_command(
            "scripts/linux/show_issue3_restored_checkout_reentry_route.sh",
            shared_args,
        ),
        "progress_tracker_route": build_command(
            "scripts/linux/show_issue3_progress_tracker_route.sh",
            shared_args,
        ),
        "build_readiness_route": build_command(
            "scripts/linux/show_issue3_linux_build_readiness_route.sh",
            [
                ("--repo-root", str(repo_root)),
                ("--memory-root", str(memory_root)),
                ("--restored-checkout-root", str(restored_checkout_root)),
                ("--saved-archives-root", str(saved_archives_root)),
                ("--rust-toolchain-dir", str(rust_toolchain_dir)),
                ("--offline-deps-root", str(offline_deps_root)),
                *(
                    [("--fallback-zig-archive", str(fallback_zig_archive))]
                    if fallback_zig_archive is not None
                    else []
                ),
            ],
        ),
        "zig_recovery_route": build_command(
            "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            [
                ("--repo-root", str(repo_root)),
                ("--toolchains-root", str(toolchains_root)),
                ("--saved-archives-root", str(saved_archives_root)),
                ("--offline-deps-root", str(offline_deps_root)),
                *(
                    [("--fallback-zig-archive", str(fallback_zig_archive))]
                    if fallback_zig_archive is not None
                    else []
                ),
            ],
        ),
    }

    failures: list[str] = []
    if not build_zon.is_file():
        failures.append(f"build.zig.zon not found under {repo_root}")

    return {
        "status": "passed" if not failures else "failed",
        "repo_root": str(repo_root),
        "build_zig_zon_exists": build_zon.is_file(),
        "memory_root": str(memory_root),
        "memory_root_found": memory_found,
        "toolchains_root": str(toolchains_root),
        "toolchains_root_found": toolchains_found,
        "offline_deps_root": str(offline_deps_root),
        "offline_deps_root_found": offline_deps_found,
        "restored_checkout_root": str(restored_checkout_root),
        "restored_checkout_root_found": restored_checkout_found,
        "saved_archives_root": str(saved_archives_root),
        "saved_archives_root_found": saved_archives_found,
        "fallback_zig_archive": str(fallback_zig_archive) if fallback_zig_archive else None,
        "fallback_zig_archive_found": fallback_found,
        "route_commands": route_commands,
        "failures": failures,
    }


def emit_text(context: dict[str, object]) -> None:
    print(f"Repo root: {context['repo_root']}")
    print(f"build.zig.zon present: {'yes' if context['build_zig_zon_exists'] else 'no'}")
    print(
        f"Memory root: {context['memory_root']} "
        f"[{'found' if context['memory_root_found'] else 'defaulted'}]"
    )
    print(
        f"Toolchains root: {context['toolchains_root']} "
        f"[{'found' if context['toolchains_root_found'] else 'defaulted'}]"
    )
    print(
        f"Offline deps root: {context['offline_deps_root']} "
        f"[{'found' if context['offline_deps_root_found'] else 'defaulted'}]"
    )
    print(
        f"Restored checkout root: {context['restored_checkout_root']} "
        f"[{'found' if context['restored_checkout_root_found'] else 'defaulted'}]"
    )
    print(
        f"Saved archives root: {context['saved_archives_root']} "
        f"[{'found' if context['saved_archives_root_found'] else 'defaulted'}]"
    )
    print(
        f"Fallback Zig archive: {context['fallback_zig_archive']} "
        f"[{'found' if context['fallback_zig_archive_found'] else 'not found'}]"
    )
    print()
    print("Suggested route commands:")
    route_commands = context["route_commands"]
    assert isinstance(route_commands, dict)
    for label, command in route_commands.items():
        print(f"  {label}: {' '.join(command)}")

    failures = context["failures"]
    assert isinstance(failures, list)
    if failures:
        print("\nWorkspace re-entry route check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)


class WorkspaceReentryRouteTests(unittest.TestCase):
    def test_nested_checkout_keeps_shared_roots_in_route_commands(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            repo_root = base / "restored" / "browser-fork-headed-mode-foundation"
            repo_root.mkdir(parents=True)
            (repo_root / "build.zig.zon").write_text(
                '.minimum_zig_version = "0.15.2"', encoding="utf-8"
            )

            memory_root = base / "memory"
            memory_root.mkdir()
            toolchains_root = base / "toolchains"
            toolchains_root.mkdir()
            offline_deps_root = base / "offline-deps"
            offline_deps_root.mkdir()
            restored_checkout_root = base / DEFAULT_RESTORED_CHECKOUT_ROOT_NAME
            restored_checkout_root.mkdir()
            saved_archives_root = memory_root / "repo_archives" / "browser"
            saved_archives_root.mkdir(parents=True)
            agent_files_root = base / "agent_files"
            agent_files_root.mkdir()
            fallback = agent_files_root / DEFAULT_FALLBACK_ZIG_ARCHIVE
            fallback.write_text("zig", encoding="utf-8")

            context = collect_context(repo_root, None)

            self.assertEqual(context["status"], "passed")
            route_commands = context["route_commands"]
            assert isinstance(route_commands, dict)
            for label in (
                "saved_memory_surface",
                "saved_memory_route",
                "restored_checkout_surface",
                "restored_checkout_route",
                "progress_tracker_route",
            ):
                command = route_commands[label]
                self.assertIn(str(memory_root.resolve()), command)
                self.assertIn(str(restored_checkout_root.resolve()), command)
                self.assertIn(str(saved_archives_root.resolve()), command)
                self.assertIn(str(toolchains_root.resolve()), command)
                self.assertIn(str(offline_deps_root.resolve()), command)
                self.assertIn(str(fallback.resolve()), command)

    def test_explicit_fallback_archive_is_propagated(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            repo_root = base / "browser"
            repo_root.mkdir()
            (repo_root / "build.zig.zon").write_text(
                '.minimum_zig_version = "0.15.2"', encoding="utf-8"
            )
            explicit_archive = base / "custom-zig.tar.xz"
            explicit_archive.write_text("zig", encoding="utf-8")

            context = collect_context(repo_root, explicit_archive)

            self.assertEqual(context["fallback_zig_archive"], str(explicit_archive.resolve()))
            route_commands = context["route_commands"]
            assert isinstance(route_commands, dict)
            for command in route_commands.values():
                self.assertIn(str(explicit_archive.resolve()), command)

    def test_missing_build_manifest_fails_cleanly(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()

            context = collect_context(repo_root, None)

            self.assertEqual(context["status"], "failed")
            self.assertEqual(len(context["failures"]), 1)
            self.assertIn("build.zig.zon not found", context["failures"][0])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            WorkspaceReentryRouteTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    explicit_archive = (
        Path(args.fallback_zig_archive).resolve()
        if args.fallback_zig_archive
        else None
    )
    context = collect_context(repo_root, explicit_archive)
    if args.json:
        print(json.dumps(context, indent=2))
    else:
        emit_text(context)
    return 0 if context["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())