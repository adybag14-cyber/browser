#!/usr/bin/env python3

"""Surface saved-memory and archive-integrity preflights for issue #3 re-entry.

This helper complements the broader workspace-context and build-readiness
helpers. Its job is to answer one practical question for issue #11 reruns:
given the current checkout location, what are the exact saved-memory and saved-
archive commands that should run before Linux/WSL runtime re-entry is trusted?
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
        description=(
            "Surface saved-memory, restored-checkout, and saved-archive "
            "preflight commands for the issue #3 Linux/WSL re-entry lane."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--helper-root",
        default=None,
        help="Optional live helper checkout root (default: repo root)",
    )
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Optional workspace memory root override",
    )
    parser.add_argument(
        "--agent-files-root",
        default=None,
        help="Optional builder-attached files root override",
    )
    parser.add_argument(
        "--restored-checkout-root",
        default=None,
        help="Optional restored-checkout root override",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit fallback Zig archive path",
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


def resolve_default_memory_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "memory")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "memory").resolve()


def resolve_default_agent_files_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "agent_files")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "agent_files").resolve()


def resolve_default_restored_checkout_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, DEFAULT_RESTORED_CHECKOUT_ROOT_NAME)
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / DEFAULT_RESTORED_CHECKOUT_ROOT_NAME).resolve()


def resolve_default_fallback_archive(repo_root: Path) -> Path | None:
    located = locate_first_existing(
        repo_root, f"agent_files/{DEFAULT_FALLBACK_ZIG_ARCHIVE}"
    )
    if located is not None and located.is_file():
        return located
    candidate = (repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve()
    return candidate if candidate.is_file() else None


def collect_context(
    repo_root: Path,
    helper_root: Path | None,
    memory_root: Path | None,
    agent_files_root: Path | None,
    restored_checkout_root: Path | None,
    fallback_zig_archive: Path | None,
) -> dict[str, object]:
    build_zon = repo_root / "build.zig.zon"
    helper_root = helper_root.resolve() if helper_root is not None else repo_root
    memory_root = memory_root.resolve() if memory_root is not None else resolve_default_memory_root(repo_root)
    agent_files_root = (
        agent_files_root.resolve()
        if agent_files_root is not None
        else resolve_default_agent_files_root(repo_root)
    )
    restored_checkout_root = (
        restored_checkout_root.resolve()
        if restored_checkout_root is not None
        else resolve_default_restored_checkout_root(repo_root)
    )
    fallback_zig_archive = (
        fallback_zig_archive.resolve()
        if fallback_zig_archive is not None
        else resolve_default_fallback_archive(repo_root)
    )

    saved_memory_command = [
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
    saved_archive_integrity_command = [
        "python",
        "scripts/check_issue3_saved_archive_integrity.py",
        "--repo-root",
        str(repo_root),
        "--memory-root",
        str(memory_root),
        "--agent-files-root",
        str(agent_files_root),
    ]
    restored_checkout_command = [
        "python",
        "scripts/check_issue3_restored_checkout.py",
        "--repo-root",
        str(restored_checkout_root),
        "--helper-root",
        str(helper_root),
    ]

    if fallback_zig_archive is not None:
        saved_memory_command.extend(
            ("--fallback-zig-archive", str(fallback_zig_archive))
        )
        saved_archive_integrity_command.extend(
            ("--fallback-zig-archive", str(fallback_zig_archive))
        )

    failures: list[str] = []
    if not build_zon.is_file():
        failures.append(f"build.zig.zon not found under {repo_root}")

    return {
        "status": "failed" if failures else "passed",
        "repo_root": str(repo_root),
        "helper_root": str(helper_root),
        "memory_root": str(memory_root),
        "agent_files_root": str(agent_files_root),
        "restored_checkout_root": str(restored_checkout_root),
        "fallback_zig_archive": (
            str(fallback_zig_archive) if fallback_zig_archive is not None else None
        ),
        "saved_memory_command": saved_memory_command,
        "saved_archive_integrity_command": saved_archive_integrity_command,
        "restored_checkout_command": restored_checkout_command,
        "failures": failures,
    }


def emit_text(context: dict[str, object]) -> None:
    print(f"Repo root: {context['repo_root']}")
    print(f"Helper root: {context['helper_root']}")
    print(f"Memory root: {context['memory_root']}")
    print(f"Agent files root: {context['agent_files_root']}")
    print(f"Restored checkout root: {context['restored_checkout_root']}")
    print(
        "Fallback Zig archive: "
        f"{context['fallback_zig_archive'] or 'not found beside the repo workspace'}"
    )
    print("Suggested restored-checkout readiness command:")
    print("  " + " ".join(context["restored_checkout_command"]))
    print("Suggested saved-memory preflight command:")
    print("  " + " ".join(context["saved_memory_command"]))
    print("Suggested saved-archive integrity command:")
    print("  " + " ".join(context["saved_archive_integrity_command"]))
    if context["failures"]:
        print("\nWorkspace-context preflights check failed:", file=sys.stderr)
        for failure in context["failures"]:
            print(f"  - {failure}", file=sys.stderr)


class WorkspaceContextPreflightsTests(unittest.TestCase):
    def test_defaults_follow_workspace_ancestors(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = Path(tmpdir)
            repo_root = workspace_root / "restored" / "browser-memory-snapshot" / "browser"
            repo_root.mkdir(parents=True)
            (repo_root / "build.zig.zon").write_text(
                '.minimum_zig_version = "0.15.2"', encoding="utf-8"
            )
            memory_root = workspace_root / "memory"
            agent_files_root = workspace_root / "agent_files"
            restored_checkout_root = workspace_root / DEFAULT_RESTORED_CHECKOUT_ROOT_NAME
            fallback_archive = agent_files_root / DEFAULT_FALLBACK_ZIG_ARCHIVE
            memory_root.mkdir()
            agent_files_root.mkdir()
            restored_checkout_root.mkdir()
            fallback_archive.write_text("zig", encoding="utf-8")

            context = collect_context(
                repo_root,
                helper_root=None,
                memory_root=None,
                agent_files_root=None,
                restored_checkout_root=None,
                fallback_zig_archive=None,
            )

            self.assertEqual(context["status"], "passed")
            self.assertEqual(context["memory_root"], str(memory_root.resolve()))
            self.assertEqual(context["agent_files_root"], str(agent_files_root.resolve()))
            self.assertEqual(
                context["restored_checkout_root"],
                str((workspace_root / "restored" / DEFAULT_RESTORED_CHECKOUT_ROOT_NAME).resolve()),
            )
            self.assertEqual(
                context["fallback_zig_archive"], str(fallback_archive.resolve())
            )
            self.assertIn("--memory-root", context["saved_memory_command"])
            self.assertIn(
                str(memory_root.resolve()), context["saved_memory_command"]
            )
            self.assertIn(
                str(agent_files_root.resolve()),
                context["saved_archive_integrity_command"],
            )

    def test_explicit_overrides_are_used(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            helper_root = root / "helper"
            memory_root = root / "custom-memory"
            agent_files_root = root / "custom-agent-files"
            restored_checkout_root = root / "custom-restored"
            fallback_archive = root / "zig-custom.tar.xz"
            repo_root.mkdir()
            helper_root.mkdir()
            memory_root.mkdir()
            agent_files_root.mkdir()
            restored_checkout_root.mkdir()
            fallback_archive.write_text("zig", encoding="utf-8")
            (repo_root / "build.zig.zon").write_text(
                '.minimum_zig_version = "0.15.2"', encoding="utf-8"
            )

            context = collect_context(
                repo_root,
                helper_root=helper_root,
                memory_root=memory_root,
                agent_files_root=agent_files_root,
                restored_checkout_root=restored_checkout_root,
                fallback_zig_archive=fallback_archive,
            )

            self.assertEqual(context["helper_root"], str(helper_root.resolve()))
            self.assertEqual(context["memory_root"], str(memory_root.resolve()))
            self.assertEqual(
                context["agent_files_root"], str(agent_files_root.resolve())
            )
            self.assertEqual(
                context["restored_checkout_root"],
                str(restored_checkout_root.resolve()),
            )
            self.assertEqual(
                context["fallback_zig_archive"], str(fallback_archive.resolve())
            )
            self.assertIn(
                str(fallback_archive.resolve()), context["saved_memory_command"]
            )
            self.assertIn(
                str(fallback_archive.resolve()),
                context["saved_archive_integrity_command"],
            )

    def test_missing_build_manifest_fails_cleanly(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()

            context = collect_context(
                repo_root,
                helper_root=None,
                memory_root=None,
                agent_files_root=None,
                restored_checkout_root=None,
                fallback_zig_archive=None,
            )

            self.assertEqual(context["status"], "failed")
            self.assertEqual(len(context["failures"]), 1)
            self.assertIn("build.zig.zon not found", context["failures"][0])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            WorkspaceContextPreflightsTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    helper_root = Path(args.helper_root).resolve() if args.helper_root else None
    memory_root = Path(args.memory_root).resolve() if args.memory_root else None
    agent_files_root = (
        Path(args.agent_files_root).resolve() if args.agent_files_root else None
    )
    restored_checkout_root = (
        Path(args.restored_checkout_root).resolve()
        if args.restored_checkout_root
        else None
    )
    fallback_zig_archive = (
        Path(args.fallback_zig_archive).resolve()
        if args.fallback_zig_archive
        else None
    )

    context = collect_context(
        repo_root,
        helper_root=helper_root,
        memory_root=memory_root,
        agent_files_root=agent_files_root,
        restored_checkout_root=restored_checkout_root,
        fallback_zig_archive=fallback_zig_archive,
    )
    if args.json:
        print(json.dumps(context, indent=2))
    else:
        emit_text(context)
    return 0 if context["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())