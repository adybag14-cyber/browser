#!/usr/bin/env python3

"""Surface the practical workspace roots for issue #3 Linux/WSL recovery.

This helper is intentionally small and create-only so scheduled runs can answer:
- where the nearest shared toolchains directory lives
- where the nearest shared hidden .toolchains directory lives when that is the staged toolchain surface
- where the saved Memory browser archives live
- where the attached fallback Zig archive is visible from this checkout
- where the nearest shared offline dependency root and Memory root live
- which saved-snapshot, saved-memory, saved-Rust, build-readiness, and issue #11 progress-
  tracker route commands already match those roots

It is useful when a restored checkout sits deeper than the default sibling
layout assumed by the existing route notes.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest


DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
DEFAULT_RESTORED_CHECKOUT_ROOT_NAME = "browser-memory-snapshot"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Surface workspace roots for issue #3 Linux/WSL recovery helpers."
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


def path_has_live_helper_surface(path: Path) -> bool:
    return (
        path.is_dir()
        and (path / "build.zig.zon").is_file()
        and (path / "scripts" / "check_issue3_saved_memory_inputs.py").is_file()
        and (path / "scripts" / "linux" / "show_issue3_progress_tracker_route.sh").is_file()
    )


def infer_toolchains_root(repo_root: Path) -> tuple[Path, bool]:
    for relative_path in (".toolchains", "toolchains"):
        located = locate_first_existing(repo_root, relative_path)
        if located is not None and located.is_dir():
            return located, True
    return (repo_root.parent / "toolchains").resolve(), False


def infer_memory_root(repo_root: Path) -> tuple[Path, bool]:
    located = locate_first_existing(repo_root, "memory")
    if located is not None and located.is_dir():
        return located, True
    return (repo_root.parent / "memory").resolve(), False


def infer_saved_archives_root(repo_root: Path) -> tuple[Path, bool]:
    located = locate_first_existing(repo_root, "memory/repo_archives/browser")
    if located is not None and located.is_dir():
        return located, True
    return (repo_root.parent / "memory" / "repo_archives" / "browser").resolve(), False


def infer_agent_files_root(repo_root: Path) -> tuple[Path, bool]:
    located = locate_first_existing(repo_root, "agent_files")
    if located is not None and located.is_dir():
        return located, True
    return (repo_root.parent / "agent_files").resolve(), False


def infer_offline_deps_root(repo_root: Path) -> tuple[Path, bool]:
    located = locate_first_existing(repo_root, "offline-deps")
    if located is not None and located.is_dir():
        return located, True
    return (repo_root.parent / "offline-deps").resolve(), False


def infer_restored_checkout_root(repo_root: Path) -> tuple[Path, bool]:
    located = locate_first_existing(repo_root, DEFAULT_RESTORED_CHECKOUT_ROOT_NAME)
    if located is not None and located.is_dir():
        return located, True
    return (repo_root.parent / DEFAULT_RESTORED_CHECKOUT_ROOT_NAME).resolve(), False


def infer_helper_root(repo_root: Path, restored_checkout_root: Path) -> tuple[Path, bool]:
    cwd = Path.cwd().resolve()
    repo_root = repo_root.resolve()
    restored_checkout_root = restored_checkout_root.resolve()

    if cwd != repo_root and path_has_live_helper_surface(cwd):
        if repo_root == restored_checkout_root or restored_checkout_root in repo_root.parents:
            return cwd, True

    if path_has_live_helper_surface(repo_root):
        return repo_root, True
    return repo_root, False


def infer_fallback_zig_archive(
    repo_root: Path, explicit_archive: Path | None
) -> tuple[Path | None, bool]:
    if explicit_archive is not None:
        archive = explicit_archive.resolve()
        return (archive if archive.is_file() else archive, archive.is_file())

    located = locate_first_existing(repo_root, f"agent_files/{DEFAULT_FALLBACK_ZIG_ARCHIVE}")
    if located is not None and located.is_file():
        return located, True

    agent_files_root, _found = infer_agent_files_root(repo_root)
    return (agent_files_root / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve(), False


def collect_context(repo_root: Path, explicit_archive: Path | None) -> dict[str, object]:
    build_zon = repo_root / "build.zig.zon"
    toolchains_root, toolchains_found = infer_toolchains_root(repo_root)
    memory_root, memory_found = infer_memory_root(repo_root)
    saved_archives_root, saved_archives_found = infer_saved_archives_root(repo_root)
    agent_files_root, agent_files_found = infer_agent_files_root(repo_root)
    offline_deps_root, offline_deps_found = infer_offline_deps_root(repo_root)
    restored_checkout_root, restored_checkout_found = infer_restored_checkout_root(repo_root)
    helper_root, helper_root_found = infer_helper_root(repo_root, restored_checkout_root)
    fallback_zig_archive, fallback_found = infer_fallback_zig_archive(repo_root, explicit_archive)
    rust_toolchain_dir = (toolchains_root / "rust-1.79.0").resolve()

    readiness_command = [
        "python",
        "scripts/check_linux_build_readiness.py",
        "--repo-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--offline-deps-root",
        str(offline_deps_root),
        "--expect-saved-archives",
        "--expect-offline-deps",
        "--require-prebuilt-v8",
    ]
    saved_memory_preflight_command = [
        "python",
        "scripts/check_issue3_saved_memory_inputs.py",
        "--repo-root",
        str(repo_root),
        "--helper-root",
        str(helper_root),
        "--memory-root",
        str(memory_root),
        "--agent-files-root",
        str(agent_files_root),
        "--restored-checkout-root",
        str(restored_checkout_root),
    ]
    quick_saved_memory_preflight_command = [*saved_memory_preflight_command, "--skip-archive-integrity-check"]
    progress_tracker_route_command = [
        "bash",
        "scripts/linux/show_issue3_progress_tracker_route.sh",
        "--repo-root",
        str(repo_root),
        "--helper-root",
        str(helper_root),
        "--memory-root",
        str(memory_root),
        "--restored-checkout-root",
        str(restored_checkout_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--toolchains-root",
        str(toolchains_root),
        "--offline-deps-root",
        str(offline_deps_root),
    ]
    build_readiness_route_command = [
        "bash",
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "--repo-root",
        str(repo_root),
        "--memory-root",
        str(memory_root),
        "--restored-checkout-root",
        str(restored_checkout_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--rust-toolchain-dir",
        str(rust_toolchain_dir),
        "--offline-deps-root",
        str(offline_deps_root),
    ]
    saved_snapshot_route_command = [
        "bash",
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "--repo-root",
        str(repo_root),
        "--helper-root",
        str(helper_root),
        "--memory-root",
        str(memory_root),
        "--destination",
        str(restored_checkout_root),
        "--sync-helper-surface",
    ]
    saved_rust_route_command = [
        "bash",
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
        "--browser-root",
        str(repo_root),
        "--dependencies-root",
        str(saved_archives_root),
        "--toolchain-root",
        str(rust_toolchain_dir),
    ]
    saved_rust_archive_candidates_command = [
        "python",
        "scripts/check_issue3_saved_rust_archive_candidates.py",
        "--repo-root",
        str(repo_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--toolchains-root",
        str(toolchains_root),
    ]
    staged_rust_toolchain_candidates_command = [
        "python",
        "scripts/check_issue3_staged_rust_toolchain_candidates.py",
        "--repo-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
    ]
    zig_recovery_route_command = [
        "bash",
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        "--repo-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--offline-deps-root",
        str(offline_deps_root),
    ]
    zig_match_command = [
        "bash",
        "scripts/linux/check_issue3_zig_toolchain_match.sh",
        "--repo-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
        "--saved-archives-root",
        str(saved_archives_root),
    ]
    saved_zig_archive_candidates_command = [
        "python",
        "scripts/check_issue3_saved_zig_archive_candidates.py",
        "--repo-root",
        str(repo_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--toolchains-root",
        str(toolchains_root),
    ]
    if fallback_zig_archive is not None:
        readiness_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
        saved_memory_preflight_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
        quick_saved_memory_preflight_command = [*saved_memory_preflight_command, "--skip-archive-integrity-check"]
        progress_tracker_route_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
        build_readiness_route_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
        saved_snapshot_route_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
        zig_recovery_route_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
        zig_match_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
        saved_zig_archive_candidates_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))

    status = "passed" if build_zon.is_file() else "failed"
    failures: list[str] = []
    if not build_zon.is_file():
        failures.append(f"build.zig.zon not found under {repo_root}")

    return {
        "status": status,
        "repo_root": str(repo_root),
        "build_zig_zon_exists": build_zon.is_file(),
        "helper_root": str(helper_root),
        "helper_root_found": helper_root_found,
        "toolchains_root": str(toolchains_root),
        "toolchains_root_found": toolchains_found,
        "memory_root": str(memory_root),
        "memory_root_found": memory_found,
        "saved_archives_root": str(saved_archives_root),
        "saved_archives_root_found": saved_archives_found,
        "agent_files_root": str(agent_files_root),
        "agent_files_root_found": agent_files_found,
        "offline_deps_root": str(offline_deps_root),
        "offline_deps_root_found": offline_deps_found,
        "restored_checkout_root": str(restored_checkout_root),
        "restored_checkout_root_found": restored_checkout_found,
        "fallback_zig_archive": str(fallback_zig_archive) if fallback_zig_archive else None,
        "fallback_zig_archive_found": fallback_found,
        "suggested_readiness_command": readiness_command,
        "suggested_saved_memory_preflight_command": saved_memory_preflight_command,
        "suggested_quick_saved_memory_preflight_command": quick_saved_memory_preflight_command,
        "suggested_progress_tracker_route_command": progress_tracker_route_command,
        "suggested_build_readiness_route_command": build_readiness_route_command,
        "suggested_saved_snapshot_route_command": saved_snapshot_route_command,
        "suggested_saved_rust_route_command": saved_rust_route_command,
        "suggested_saved_rust_archive_candidates_command": saved_rust_archive_candidates_command,
        "suggested_staged_rust_toolchain_candidates_command": staged_rust_toolchain_candidates_command,
        "suggested_zig_recovery_route_command": zig_recovery_route_command,
        "suggested_zig_match_command": zig_match_command,
        "suggested_saved_zig_archive_candidates_command": saved_zig_archive_candidates_command,
        "failures": failures,
    }


def emit_text(context: dict[str, object]) -> None:
    print(f"Repo root: {context['repo_root']}")
    print(f"build.zig.zon present: {'yes' if context['build_zig_zon_exists'] else 'no'}")
    print(
        f"Helper root: {context['helper_root']} "
        f"[{'found' if context['helper_root_found'] else 'defaulted'}]"
    )
    print(
        f"Toolchains root: {context['toolchains_root']} "
        f"[{'found' if context['toolchains_root_found'] else 'defaulted'}]"
    )
    print(
        f"Memory root: {context['memory_root']} "
        f"[{'found' if context['memory_root_found'] else 'defaulted'}]"
    )
    print(
        f"Saved archives root: {context['saved_archives_root']} "
        f"[{'found' if context['saved_archives_root_found'] else 'defaulted'}]"
    )
    print(
        f"Agent files root: {context['agent_files_root']} "
        f"[{'found' if context['agent_files_root_found'] else 'defaulted'}]"
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
        f"Fallback Zig archive: {context['fallback_zig_archive']} "
        f"[{'found' if context['fallback_zig_archive_found'] else 'not found'}]"
    )
    print("Suggested readiness command:")
    print("  " + " ".join(context["suggested_readiness_command"]))
    print("Suggested saved-memory preflight command:")
    print("  " + " ".join(context["suggested_saved_memory_preflight_command"]))
    print("Suggested quick saved-memory preflight command:")
    print("  " + " ".join(context["suggested_quick_saved_memory_preflight_command"]))
    print("Suggested issue #11 progress-tracker route command:")
    print("  " + " ".join(context["suggested_progress_tracker_route_command"]))
    print("Suggested build-readiness route command:")
    print("  " + " ".join(context["suggested_build_readiness_route_command"]))
    print("Suggested synced saved-snapshot route command:")
    print("  " + " ".join(context["suggested_saved_snapshot_route_command"]))
    print("Suggested saved Rust route command:")
    print("  " + " ".join(context["suggested_saved_rust_route_command"]))
    print("Suggested saved Rust archive candidates command:")
    print("  " + " ".join(context["suggested_saved_rust_archive_candidates_command"]))
    print("Suggested staged Rust toolchain candidates command:")
    print("  " + " ".join(context["suggested_staged_rust_toolchain_candidates_command"]))
    print("Suggested Zig recovery route command:")
    print("  " + " ".join(context["suggested_zig_recovery_route_command"]))
    print("Suggested Zig matching-line gate command:")
    print("  " + " ".join(context["suggested_zig_match_command"]))
    print("Suggested saved Zig archive candidates command:")
    print("  " + " ".join(context["suggested_saved_zig_archive_candidates_command"]))
    if context["failures"]:
        print("\nWorkspace-context check failed:", file=sys.stderr)
        for failure in context["failures"]:
            print(f"  - {failure}", file=sys.stderr)


class WorkspaceContextTests(unittest.TestCase):
    def test_locates_roots_above_nested_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            repo_root = base / "restored" / "browser-fork-headed-mode-foundation"
            repo_root.mkdir(parents=True)
            (repo_root / "build.zig.zon").write_text(".minimum_zig_version = \"0.15.2\"", encoding="utf-8")
            (repo_root / "scripts" / "check_issue3_saved_memory_inputs.py").parent.mkdir(parents=True)
            (repo_root / "scripts" / "check_issue3_saved_memory_inputs.py").write_text("pass", encoding="utf-8")
            (repo_root / "scripts" / "linux").mkdir(parents=True)
            (repo_root / "scripts" / "linux" / "show_issue3_progress_tracker_route.sh").write_text(
                "pass", encoding="utf-8"
            )

            toolchains_root = base / "toolchains"
            toolchains_root.mkdir()
            memory_root = base / "memory"
            memory_root.mkdir()
            saved_archives_root = memory_root / "repo_archives" / "browser"
            saved_archives_root.mkdir(parents=True)
            agent_files_root = base / "agent_files"
            agent_files_root.mkdir()
            offline_deps_root = base / "offline-deps"
            offline_deps_root.mkdir()
            restored_checkout_root = base / DEFAULT_RESTORED_CHECKOUT_ROOT_NAME
            restored_checkout_root.mkdir()
            fallback = agent_files_root / DEFAULT_FALLBACK_ZIG_ARCHIVE
            fallback.write_text("zig", encoding="utf-8")

            context = collect_context(repo_root, None)

            self.assertEqual(context["status"], "passed")
            self.assertEqual(context["helper_root"], str(repo_root.resolve()))
            self.assertTrue(context["helper_root_found"])
            self.assertEqual(context["toolchains_root"], str(toolchains_root.resolve()))
            self.assertEqual(context["memory_root"], str(memory_root.resolve()))
            self.assertEqual(context["saved_archives_root"], str(saved_archives_root.resolve()))
            self.assertEqual(context["agent_files_root"], str(agent_files_root.resolve()))
            self.assertEqual(context["offline_deps_root"], str(offline_deps_root.resolve()))
            self.assertEqual(context["restored_checkout_root"], str(restored_checkout_root.resolve()))
            self.assertEqual(context["fallback_zig_archive"], str(fallback.resolve()))
            self.assertTrue(context["fallback_zig_archive_found"])
            self.assertIn("--offline-deps-root", context["suggested_readiness_command"])
            self.assertIn("--expect-saved-archives", context["suggested_readiness_command"])
            self.assertIn("--expect-offline-deps", context["suggested_readiness_command"])
            self.assertIn("--require-prebuilt-v8", context["suggested_readiness_command"])
            self.assertIn(
                "scripts/check_issue3_saved_memory_inputs.py",
                context["suggested_saved_memory_preflight_command"],
            )
            self.assertIn("--helper-root", context["suggested_saved_memory_preflight_command"])
            self.assertIn(str(repo_root.resolve()), context["suggested_saved_memory_preflight_command"])
            self.assertIn(str(memory_root.resolve()), context["suggested_saved_memory_preflight_command"])
            self.assertIn(str(agent_files_root.resolve()), context["suggested_saved_memory_preflight_command"])
            self.assertIn(str(restored_checkout_root.resolve()), context["suggested_saved_memory_preflight_command"])
            self.assertIn("--skip-archive-integrity-check", context["suggested_quick_saved_memory_preflight_command"])
            self.assertIn(
                "scripts/linux/show_issue3_progress_tracker_route.sh",
                context["suggested_progress_tracker_route_command"],
            )
            self.assertIn("--helper-root", context["suggested_progress_tracker_route_command"])
            self.assertIn(str(repo_root.resolve()), context["suggested_progress_tracker_route_command"])
            self.assertIn(str(memory_root.resolve()), context["suggested_progress_tracker_route_command"])
            self.assertIn(str(restored_checkout_root.resolve()), context["suggested_progress_tracker_route_command"])
            self.assertIn(str(toolchains_root.resolve()), context["suggested_progress_tracker_route_command"])
            self.assertIn(str(offline_deps_root.resolve()), context["suggested_progress_tracker_route_command"])
            self.assertIn(
                "scripts/linux/show_issue3_linux_build_readiness_route.sh",
                context["suggested_build_readiness_route_command"],
            )
            self.assertIn("--helper-root", context["suggested_saved_snapshot_route_command"])
            self.assertIn(str(repo_root.resolve()), context["suggested_saved_snapshot_route_command"])
            self.assertIn("--sync-helper-surface", context["suggested_saved_snapshot_route_command"])
            self.assertIn("--destination", context["suggested_saved_snapshot_route_command"])
            self.assertNotIn("--restored-checkout-root", context["suggested_saved_snapshot_route_command"])
            self.assertIn(
                "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
                context["suggested_saved_rust_route_command"],
            )
            self.assertIn(str(saved_archives_root.resolve()), context["suggested_saved_rust_route_command"])
            self.assertIn(
                str((toolchains_root / "rust-1.79.0").resolve()),
                context["suggested_saved_rust_route_command"],
            )
            self.assertIn(
                "scripts/check_issue3_saved_rust_archive_candidates.py",
                context["suggested_saved_rust_archive_candidates_command"],
            )
            self.assertIn(
                "scripts/check_issue3_staged_rust_toolchain_candidates.py",
                context["suggested_staged_rust_toolchain_candidates_command"],
            )
            self.assertIn(
                "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
                context["suggested_zig_recovery_route_command"],
            )
            self.assertIn(str(saved_archives_root.resolve()), context["suggested_zig_recovery_route_command"])
            self.assertIn(str(offline_deps_root.resolve()), context["suggested_zig_recovery_route_command"])
            self.assertIn(
                "scripts/linux/check_issue3_zig_toolchain_match.sh",
                context["suggested_zig_match_command"],
            )
            self.assertIn(
                "scripts/check_issue3_saved_zig_archive_candidates.py",
                context["suggested_saved_zig_archive_candidates_command"]
            )

    def test_locates_hidden_toolchains_root_above_nested_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            repo_root = base / "restored" / "browser-fork-headed-mode-foundation"
            repo_root.mkdir(parents=True)
            (repo_root / "build.zig.zon").write_text(".minimum_zig_version = \"0.15.2\"", encoding="utf-8")

            hidden_toolchains_root = base / ".toolchains"
            hidden_toolchains_root.mkdir()

            context = collect_context(repo_root, None)

            self.assertEqual(context["status"], "passed")
            self.assertEqual(context["toolchains_root"], str(hidden_toolchains_root.resolve()))
            self.assertTrue(context["toolchains_root_found"])
            self.assertIn(str(hidden_toolchains_root.resolve()), context["suggested_readiness_command"])
            self.assertIn(str(hidden_toolchains_root.resolve()), context["suggested_progress_tracker_route_command"])
            self.assertIn(str(hidden_toolchains_root.resolve()), context["suggested_build_readiness_route_command"])
            self.assertIn(str(hidden_toolchains_root.resolve()), context["suggested_saved_rust_archive_candidates_command"])
            self.assertIn(str(hidden_toolchains_root.resolve()), context["suggested_staged_rust_toolchain_candidates_command"])
            self.assertIn(str(hidden_toolchains_root.resolve()), context["suggested_zig_recovery_route_command"])
            self.assertIn(str(hidden_toolchains_root.resolve()), context["suggested_zig_match_command"])
            self.assertIn(str(hidden_toolchains_root.resolve()), context["suggested_saved_zig_archive_candidates_command"])

    def test_defaults_when_ancestor_roots_are_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            (repo_root / "build.zig.zon").write_text(".minimum_zig_version = \"0.15.2\"", encoding="utf-8")

            context = collect_context(repo_root, None)

            self.assertEqual(context["status"], "passed")
            self.assertFalse(context["helper_root_found"])
            self.assertFalse(context["toolchains_root_found"])
            self.assertFalse(context["memory_root_found"])
            self.assertFalse(context["saved_archives_root_found"])
            self.assertFalse(context["agent_files_root_found"])
            self.assertFalse(context["offline_deps_root_found"])
            self.assertFalse(context["restored_checkout_root_found"])
            self.assertFalse(context["fallback_zig_archive_found"])
            self.assertIn(
                "scripts/check_issue3_saved_memory_inputs.py",
                context["suggested_saved_memory_preflight_command"],
            )
            self.assertIn("--helper-root", context["suggested_saved_memory_preflight_command"])
            self.assertIn("--memory-root", context["suggested_saved_memory_preflight_command"])
            self.assertIn("--agent-files-root", context["suggested_saved_memory_preflight_command"])
            self.assertIn("--restored-checkout-root", context["suggested_saved_memory_preflight_command"])
            self.assertIn("--skip-archive-integrity-check", context["suggested_quick_saved_memory_preflight_command"])
            self.assertIn("--expect-saved-archives", context["suggested_readiness_command"])
            self.assertIn("--expect-offline-deps", context["suggested_readiness_command"])
            self.assertIn("--require-prebuilt-v8", context["suggested_readiness_command"])
            self.assertIn(
                "scripts/linux/show_issue3_progress_tracker_route.sh",
                context["suggested_progress_tracker_route_command"]
            )
            self.assertIn("--helper-root", context["suggested_progress_tracker_route_command"])
            self.assertIn("--memory-root", context["suggested_progress_tracker_route_command"])
            self.assertIn("--saved-archives-root", context["suggested_progress_tracker_route_command"])
            self.assertIn(
                "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
                context["suggested_saved_rust_route_command"]
            )
            self.assertIn(
                "scripts/check_issue3_saved_rust_archive_candidates.py",
                context["suggested_saved_rust_archive_candidates_command"]
            )
            self.assertIn(
                "scripts/check_issue3_staged_rust_toolchain_candidates.py",
                context["suggested_staged_rust_toolchain_candidates_command"]
            )
            self.assertIn(
                "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
                context["suggested_zig_recovery_route_command"]
            )
            self.assertIn(
                "scripts/linux/check_issue3_zig_toolchain_match.sh",
                context["suggested_zig_match_command"]
            )
            self.assertIn("--helper-root", context["suggested_saved_snapshot_route_command"])
            self.assertIn(str(repo_root.resolve()), context["suggested_saved_snapshot_route_command"])
            self.assertIn("--destination", context["suggested_saved_snapshot_route_command"])

    def test_nested_restored_checkout_prefers_live_helper_root_from_cwd(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            live_root = base / "browser"
            live_root.mkdir()
            (live_root / "build.zig.zon").write_text(".minimum_zig_version = \"0.15.2\"", encoding="utf-8")
            (live_root / "scripts" / "check_issue3_saved_memory_inputs.py").parent.mkdir(parents=True)
            (live_root / "scripts" / "check_issue3_saved_memory_inputs.py").write_text("pass", encoding="utf-8")
            (live_root / "scripts" / "linux").mkdir(parents=True)
            (live_root / "scripts" / "linux" / "show_issue3_progress_tracker_route.sh").write_text(
                "pass", encoding="utf-8"
            )

            restored_root = base / DEFAULT_RESTORED_CHECKOUT_ROOT_NAME
            repo_root = restored_root / "browser"
            repo_root.mkdir(parents=True)
            (repo_root / "build.zig.zon").write_text(".minimum_zig_version = \"0.15.2\"", encoding="utf-8")

            original_cwd = Path.cwd()
            try:
                os.chdir(live_root)
                context = collect_context(repo_root, None)
            finally:
                os.chdir(original_cwd)

            self.assertEqual(context["helper_root"], str(live_root.resolve()))
            self.assertTrue(context["helper_root_found"])
            self.assertIn("--helper-root", context["suggested_saved_memory_preflight_command"])
            self.assertIn(str(live_root.resolve()), context["suggested_saved_memory_preflight_command"])
            self.assertIn("--helper-root", context["suggested_progress_tracker_route_command"])
            self.assertIn(str(live_root.resolve()), context["suggested_progress_tracker_route_command"])
            self.assertIn("--helper-root", context["suggested_saved_snapshot_route_command"])
            self.assertIn(str(live_root.resolve()), context["suggested_saved_snapshot_route_command"])

    def test_explicit_fallback_archive_overrides_search(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            repo_root = base / "browser"
            repo_root.mkdir()
            (repo_root / "build.zig.zon").write_text(".minimum_zig_version = \"0.15.2\"", encoding="utf-8")
            explicit_archive = base / "custom-zig.tar.xz"
            explicit_archive.write_text("zig", encoding="utf-8")

            context = collect_context(repo_root, explicit_archive)

            self.assertEqual(context["fallback_zig_archive"], str(explicit_archive.resolve()))
            self.assertTrue(context["fallback_zig_archive_found"])
            self.assertIn(str(explicit_archive.resolve()), context["suggested_saved_memory_preflight_command"])
            self.assertIn(str(explicit_archive.resolve()), context["suggested_quick_saved_memory_preflight_command"])
            self.assertIn(str(explicit_archive.resolve()), context["suggested_saved_snapshot_route_command"])
            self.assertIn("--destination", context["suggested_saved_snapshot_route_command"])
            self.assertIn(str(explicit_archive.resolve()), context["suggested_zig_recovery_route_command"])
            self.assertIn(str(explicit_archive.resolve()), context["suggested_zig_match_command"])
            self.assertIn(
                str(explicit_archive.resolve()),
                context["suggested_saved_zig_archive_candidates_command"]
            )
            self.assertIn(
                str(explicit_archive.resolve()),
                context["suggested_progress_tracker_route_command"]
            )
            self.assertIn(
                str(explicit_archive.resolve()),
                context["suggested_readiness_command"]
            )

    def test_missing_build_zon_fails_cleanly(self) -> None:
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
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(WorkspaceContextTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    explicit_archive = Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None
    context = collect_context(repo_root, explicit_archive)
    if args.json:
        print(json.dumps(context, indent=2))
    else:
        emit_text(context)
    return 0 if context["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())