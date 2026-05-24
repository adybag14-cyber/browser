#!/usr/bin/env python3

"""Show workspace-aware companion roots for the issue #3 recovery helpers.

This helper gives the saved-memory, archive-integrity, and Linux build-readiness
routes one small place to resolve the "workspace companion" paths that can vary
between a repo checkout rooted at ``/workspace/browser`` and a helper checkout
that lives directly at ``/workspace``.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shlex
import tempfile
import unittest


WORKSPACE_MARKER_NAMES: tuple[str, ...] = ("memory", "agent_files", "toolchains")
DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Resolve workspace-aware companion roots for the issue #3 saved "
            "Memory and Linux re-entry helper chain."
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
        help=(
            "Optional live helper checkout root to use in suggested commands "
            "(default: same as --repo-root)"
        ),
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of a text summary",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def find_workspace_anchor(repo_root: Path) -> Path:
    current = repo_root.resolve()
    while True:
        if current.name == "workspace":
            return current
        if any((current / marker).exists() for marker in WORKSPACE_MARKER_NAMES):
            return current
        parent = current.parent
        if parent == current:
            return repo_root.resolve().parent
        current = parent


def resolve_workspace_companion_path(repo_root: Path, name: str) -> Path:
    return (find_workspace_anchor(repo_root) / name).resolve()


def collect_results(repo_root: Path, helper_root: Path) -> dict[str, object]:
    workspace_anchor = find_workspace_anchor(repo_root)
    memory_root = resolve_workspace_companion_path(repo_root, "memory")
    agent_files_root = resolve_workspace_companion_path(repo_root, "agent_files")
    toolchains_root = resolve_workspace_companion_path(repo_root, "toolchains")
    offline_deps_root = resolve_workspace_companion_path(repo_root, "offline-deps")
    restored_checkout_root = resolve_workspace_companion_path(
        repo_root, DEFAULT_RESTORED_CHECKOUT_NAME
    )
    saved_archives_root = (memory_root / "repo_archives" / "browser").resolve()

    commands = {
        "saved_memory_inputs": [
            "python",
            str(helper_root / "scripts" / "check_issue3_saved_memory_inputs.py"),
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
        ],
        "saved_archive_integrity": [
            "python",
            str(helper_root / "scripts" / "check_issue3_saved_archive_integrity.py"),
            "--repo-root",
            str(repo_root),
            "--memory-root",
            str(memory_root),
            "--agent-files-root",
            str(agent_files_root),
        ],
        "linux_build_readiness": [
            "python",
            str(helper_root / "scripts" / "check_linux_build_readiness.py"),
            "--repo-root",
            str(repo_root),
            "--toolchains-root",
            str(toolchains_root),
            "--saved-archives-root",
            str(saved_archives_root),
            "--offline-deps-root",
            str(offline_deps_root),
            "--expect-saved-archives",
        ],
    }

    paths = {
        "workspace_anchor": workspace_anchor,
        "repo_root": repo_root.resolve(),
        "helper_root": helper_root.resolve(),
        "memory_root": memory_root,
        "agent_files_root": agent_files_root,
        "toolchains_root": toolchains_root,
        "offline_deps_root": offline_deps_root,
        "saved_archives_root": saved_archives_root,
        "restored_checkout_root": restored_checkout_root,
    }

    path_entries = [
        {
            "name": name,
            "path": str(path),
            "exists": path.exists(),
            "is_dir": path.is_dir(),
        }
        for name, path in paths.items()
    ]

    return {
        "repo_root": str(repo_root.resolve()),
        "helper_root": str(helper_root.resolve()),
        "workspace_anchor": str(workspace_anchor),
        "paths": path_entries,
        "commands": {
            name: {
                "argv": argv,
                "shell": format_shell_command(argv),
            }
            for name, argv in commands.items()
        },
    }


def format_shell_command(argv: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in argv)


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Helper root: {result['helper_root']}")
    print(f"Workspace anchor: {result['workspace_anchor']}")
    print("Resolved companion paths:")
    for entry in result["paths"]:
        status = "PASS" if entry["exists"] else "WARN"
        kind = "dir" if entry["is_dir"] else "missing"
        print(f"  [{status}] {entry['name']}: {entry['path']} [{kind}]")
    print("Suggested explicit helper commands:")
    for name, command in result["commands"].items():
        print(f"  - {name}:")
        print(f"    {command['shell']}")


class WorkspaceCompanionRootsTests(unittest.TestCase):
    def test_find_workspace_anchor_prefers_workspace_dir(self) -> None:
        repo_root = Path("/tmp/workspace/browser")
        self.assertEqual(find_workspace_anchor(repo_root), Path("/tmp/workspace"))

    def test_find_workspace_anchor_prefers_marker_dirs(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            workspace_like = root / "custom-root"
            repo_root = workspace_like / "browser"
            repo_root.mkdir(parents=True)
            (workspace_like / "memory").mkdir()
            self.assertEqual(find_workspace_anchor(repo_root), workspace_like)

    def test_find_workspace_anchor_falls_back_to_parent(self) -> None:
        repo_root = Path("/tmp/browser")
        self.assertEqual(find_workspace_anchor(repo_root), Path("/tmp"))

    def test_collect_results_uses_workspace_anchor_for_all_companions(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = Path(tmpdir) / "workspace"
            repo_root = workspace_root / "browser"
            helper_root = repo_root
            repo_root.mkdir(parents=True)
            for name in ("memory", "agent_files", "toolchains", "offline-deps"):
                (workspace_root / name).mkdir()

            result = collect_results(repo_root, helper_root)

            by_name = {entry["name"]: entry for entry in result["paths"]}
            self.assertEqual(by_name["workspace_anchor"]["path"], str(workspace_root))
            self.assertEqual(
                by_name["memory_root"]["path"], str((workspace_root / "memory").resolve())
            )
            self.assertEqual(
                by_name["saved_archives_root"]["path"],
                str((workspace_root / "memory" / "repo_archives" / "browser").resolve()),
            )
            self.assertIn("--saved-archives-root", result["commands"]["linux_build_readiness"]["argv"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            WorkspaceCompanionRootsTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    helper_root = Path(args.helper_root).resolve() if args.helper_root else repo_root
    result = collect_results(repo_root, helper_root)
    if args.json:
        print(json.dumps({"profile": "issue3-workspace-companion-roots", **result}, indent=2))
    else:
        emit_text(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
