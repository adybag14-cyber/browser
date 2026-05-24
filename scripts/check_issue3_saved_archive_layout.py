#!/usr/bin/env python3

"""Explain the saved archive layout used by the issue #3 Linux helpers.

This helper exists for one narrow purpose: keep runs from mixing the browser
archive root with the dependency-archives root when they drop from the higher-
level route notes to the lower-level readiness helper.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shlex
import sys
import tempfile
import unittest


REQUIRED_BROWSER_ROOT_FILES: tuple[tuple[str, str], ...] = (
    ("01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot"),
    ("README.md", "saved repo notes"),
    ("blocker_intelligence.yaml", "blocker intelligence"),
)

OPTIONAL_BROWSER_ROOT_FILES: tuple[tuple[str, str], ...] = (
    ("session_entry_register.yaml", "session entry register"),
)

REQUIRED_DEPENDENCY_ARCHIVES: tuple[tuple[str, str], ...] = (
    ("01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz", "saved Rust toolchain archive"),
    ("03-boringssl-zig-main.zip", "saved BoringSSL archive"),
    ("04-zig-browser-depo.tar.zip", "saved browser dependency archive"),
)

OPTIONAL_DEPENDENCY_ARCHIVES: tuple[tuple[str, str], ...] = (
    ("02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip", "saved html5ever dependency archive"),
)

DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Show the saved archive layout for the blocked issue #3 Linux "
            "build-readiness route and print the exact dependency-archive root "
            "that should be passed to check_linux_build_readiness.py."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Path to the workspace memory root (default: ../memory beside the repo workspace)",
    )
    parser.add_argument(
        "--agent-files-root",
        default=None,
        help="Path to the builder-attached files root (default: ../agent_files beside the repo workspace)",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit path to the fallback Zig archive to surface in the printed commands",
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


def resolve_default_memory_root(repo_root: Path) -> Path:
    return (repo_root.parent / "memory").resolve()


def resolve_default_agent_files_root(repo_root: Path) -> Path:
    return (repo_root.parent / "agent_files").resolve()


def resolve_browser_archive_root(memory_root: Path) -> Path:
    return (memory_root / "repo_archives" / "browser").resolve()


def resolve_dependency_archives_root(memory_root: Path) -> Path:
    return (resolve_browser_archive_root(memory_root) / "dependencies").resolve()


def check_entries(root: Path, entries: tuple[tuple[str, str], ...]) -> list[dict[str, object]]:
    return [
        {
            "label": label,
            "path": str(root / relative_path),
            "exists": (root / relative_path).is_file(),
            "name": relative_path,
        }
        for relative_path, label in entries
    ]


def format_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def collect_results(
    *,
    repo_root: Path,
    memory_root: Path,
    agent_files_root: Path,
    fallback_zig_archive: Path | None,
) -> dict[str, object]:
    browser_archive_root = resolve_browser_archive_root(memory_root)
    dependency_archives_root = resolve_dependency_archives_root(memory_root)

    fallback_path = fallback_zig_archive
    if fallback_path is None:
        candidate = agent_files_root / DEFAULT_FALLBACK_ZIG
        fallback_path = candidate if candidate.is_file() else candidate

    browser_entries = check_entries(browser_archive_root, REQUIRED_BROWSER_ROOT_FILES)
    optional_browser_entries = check_entries(browser_archive_root, OPTIONAL_BROWSER_ROOT_FILES)
    dependency_entries = check_entries(dependency_archives_root, REQUIRED_DEPENDENCY_ARCHIVES)
    optional_dependency_entries = check_entries(
        dependency_archives_root, OPTIONAL_DEPENDENCY_ARCHIVES
    )

    commands = {
        "saved_memory_inputs": format_command(
            ["python", "scripts/check_issue3_saved_memory_inputs.py", "--repo-root", str(repo_root)]
        ),
        "saved_archive_integrity": format_command(
            ["python", "scripts/check_issue3_saved_archive_integrity.py", "--repo-root", str(repo_root)]
        ),
        "saved_archive_preflight": format_command(
            [
                "python",
                "scripts/check_linux_build_readiness.py",
                "--repo-root",
                str(repo_root),
                "--skip-zig-check",
                "--expect-saved-archives",
                "--saved-archives-root",
                str(dependency_archives_root),
            ]
        ),
    }

    if fallback_path.is_file():
        fallback_value = str(fallback_path)
        commands["saved_memory_inputs"] += " " + format_command(
            ["--fallback-zig-archive", fallback_value]
        )
        commands["saved_archive_integrity"] += " " + format_command(
            ["--fallback-zig-archive", fallback_value]
        )
        commands["saved_archive_preflight"] += " " + format_command(
            ["--fallback-zig-archive", fallback_value]
        )
    else:
        fallback_value = ""

    ok = all(entry["exists"] for entry in browser_entries) and all(
        entry["exists"] for entry in dependency_entries
    )

    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "memory_root": str(memory_root),
        "browser_archive_root": str(browser_archive_root),
        "dependency_archives_root": str(dependency_archives_root),
        "agent_files_root": str(agent_files_root),
        "fallback_zig_archive": fallback_value,
        "required_browser_root_entries": browser_entries,
        "optional_browser_root_entries": optional_browser_entries,
        "required_dependency_archives": dependency_entries,
        "optional_dependency_archives": optional_dependency_entries,
        "commands": commands,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Repo root: {result['repo_root']}")
    print(f"Memory root: {result['memory_root']}")
    print(f"Browser archive root: {result['browser_archive_root']}")
    print(f"Dependency archives root: {result['dependency_archives_root']}")
    print(
        "Fallback Zig archive: "
        + (result["fallback_zig_archive"] or "not found beside the repo workspace")
    )
    print()
    print("Browser archive root contents:")
    for entry in result["required_browser_root_entries"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['label']}: {entry['path']}")
    for entry in result["optional_browser_root_entries"]:
        status = "PASS" if entry["exists"] else "WARN"
        print(f"  [{status}] {entry['label']}: {entry['path']}")
    print()
    print("Dependency archives root contents:")
    for entry in result["required_dependency_archives"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['label']}: {entry['path']}")
    for entry in result["optional_dependency_archives"]:
        status = "PASS" if entry["exists"] else "WARN"
        print(f"  [{status}] {entry['label']}: {entry['path']}")
    print()
    print("Suggested commands:")
    print(f"  {result['commands']['saved_memory_inputs']}")
    print(f"  {result['commands']['saved_archive_integrity']}")
    print(f"  {result['commands']['saved_archive_preflight']}")
    if result["ok"]:
        print()
        print("Saved archive layout check passed.")
    else:
        print()
        print("Saved archive layout check failed.", file=sys.stderr)
        print(
            "Suggested next step: restore the missing browser-root notes or dependency archives before rerunning the saved-archive preflight.",
            file=sys.stderr,
        )


class SavedArchiveLayoutTests(unittest.TestCase):
    def test_default_roots_follow_workspace_layout(self) -> None:
        repo_root = Path("/tmp/workspace/browser")
        self.assertEqual(resolve_default_memory_root(repo_root), Path("/tmp/workspace/memory"))
        self.assertEqual(
            resolve_default_agent_files_root(repo_root), Path("/tmp/workspace/agent_files")
        )
        self.assertEqual(
            resolve_browser_archive_root(Path("/tmp/workspace/memory")),
            Path("/tmp/workspace/memory/repo_archives/browser"),
        )
        self.assertEqual(
            resolve_dependency_archives_root(Path("/tmp/workspace/memory")),
            Path("/tmp/workspace/memory/repo_archives/browser/dependencies"),
        )

    def test_collect_results_reports_split_roots_and_preflight_command(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            agent_files_root.mkdir()

            browser_root = resolve_browser_archive_root(memory_root)
            deps_root = resolve_dependency_archives_root(memory_root)
            browser_root.mkdir(parents=True)
            deps_root.mkdir(parents=True)

            for relative_path, _label in REQUIRED_BROWSER_ROOT_FILES:
                (browser_root / relative_path).write_text("x", encoding="utf-8")
            for relative_path, _label in OPTIONAL_BROWSER_ROOT_FILES:
                (browser_root / relative_path).write_text("x", encoding="utf-8")
            for relative_path, _label in REQUIRED_DEPENDENCY_ARCHIVES + OPTIONAL_DEPENDENCY_ARCHIVES:
                (deps_root / relative_path).write_text("x", encoding="utf-8")

            fallback = agent_files_root / DEFAULT_FALLBACK_ZIG
            fallback.write_text("zig", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                memory_root=memory_root,
                agent_files_root=agent_files_root,
                fallback_zig_archive=None,
            )

            self.assertTrue(result["ok"])
            self.assertEqual(
                result["browser_archive_root"],
                str(root / "memory" / "repo_archives" / "browser"),
            )
            self.assertEqual(
                result["dependency_archives_root"],
                str(root / "memory" / "repo_archives" / "browser" / "dependencies"),
            )
            self.assertIn(
                "--saved-archives-root "
                + shlex.quote(str(root / "memory" / "repo_archives" / "browser" / "dependencies")),
                result["commands"]["saved_archive_preflight"],
            )
            self.assertIn("--fallback-zig-archive", result["commands"]["saved_archive_preflight"])

    def test_collect_results_fails_when_dependency_archives_are_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            memory_root = root / "memory"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            agent_files_root.mkdir()

            browser_root = resolve_browser_archive_root(memory_root)
            browser_root.mkdir(parents=True)
            for relative_path, _label in REQUIRED_BROWSER_ROOT_FILES:
                (browser_root / relative_path).write_text("x", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                memory_root=memory_root,
                agent_files_root=agent_files_root,
                fallback_zig_archive=None,
            )

            self.assertFalse(result["ok"])
            missing = [entry for entry in result["required_dependency_archives"] if not entry["exists"]]
            self.assertEqual(len(missing), len(REQUIRED_DEPENDENCY_ARCHIVES))


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedArchiveLayoutTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    memory_root = Path(args.memory_root).resolve() if args.memory_root else resolve_default_memory_root(repo_root)
    agent_files_root = (
        Path(args.agent_files_root).resolve()
        if args.agent_files_root
        else resolve_default_agent_files_root(repo_root)
    )
    fallback_zig_archive = Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None

    result = collect_results(
        repo_root=repo_root,
        memory_root=memory_root,
        agent_files_root=agent_files_root,
        fallback_zig_archive=fallback_zig_archive,
    )
    if args.json:
        print(json.dumps({"profile": "issue3-saved-archive-layout", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
