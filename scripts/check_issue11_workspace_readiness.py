#!/usr/bin/env python3

"""Surface a full issue #11 Linux/WSL readiness command for nested checkouts.

This helper exists for the Linux/WSL re-entry lane where a restored checkout or
nested repo path can see the right shared `memory`, `toolchains`, `agent_files`,
and `offline-deps` roots, but the next honest helper command is still awkward
to rebuild by hand.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Surface a workspace-aware issue #11 Linux/WSL readiness command "
            "for nested or restored browser checkouts."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit path to the fallback Zig archive",
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


def infer_named_root(repo_root: Path, relative_path: str) -> tuple[Path, bool]:
    located = locate_first_existing(repo_root, relative_path)
    if located is not None and located.is_dir():
        return located, True
    return (repo_root.parent / relative_path).resolve(), False


def infer_saved_archives_root(repo_root: Path) -> tuple[Path, bool]:
    located = locate_first_existing(repo_root, "memory/repo_archives/browser")
    if located is not None and located.is_dir():
        return normalize_saved_archives_root(located), True
    return normalize_saved_archives_root((repo_root.parent / "memory" / "repo_archives" / "browser").resolve()), False


def normalize_saved_archives_root(path: Path) -> Path:
    dependencies_root = path / "dependencies"
    if dependencies_root.is_dir():
        return dependencies_root.resolve()
    return path.resolve()


def infer_fallback_zig_archive(repo_root: Path, explicit_archive: Path | None) -> tuple[Path | None, bool]:
    if explicit_archive is not None:
        explicit_archive = explicit_archive.resolve()
        return explicit_archive, explicit_archive.is_file()

    located = locate_first_existing(repo_root, f"agent_files/{DEFAULT_FALLBACK_ZIG_ARCHIVE}")
    if located is not None and located.is_file():
        return located.resolve(), True

    agent_files_root, _ = infer_named_root(repo_root, "agent_files")
    fallback_archive = (agent_files_root / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve()
    return fallback_archive, fallback_archive.is_file()


def build_command(*parts: str) -> list[str]:
    return list(parts)


def repo_script(repo_root: Path, relative_path: str) -> str:
    return str((repo_root / relative_path).resolve())


def choose_next_step(
    *,
    build_zig_zon_exists: bool,
    saved_archives_root_found: bool,
    fallback_zig_archive_found: bool,
) -> str:
    if not build_zig_zon_exists:
        return "Point --repo-root at a real browser checkout before trusting any Linux or WSL readiness helper output."
    if saved_archives_root_found:
        return (
            "Run the saved-Zig route surface check and route printer first, then use the surfaced archive-selection "
            "command before the broader Linux or WSL readiness rerun."
        )
    if fallback_zig_archive_found:
        return (
            "Run the saved-archive preflight first, then reopen the saved-Zig route with the surfaced fallback "
            "archive path so the next run can confirm whether a real 0.15.x archive is available."
        )
    return (
        "Run the saved-archive preflight first, then surface the saved-Zig route with an explicit "
        "--fallback-zig-archive path before trusting the broader Linux or WSL readiness command."
    )


def collect_context(repo_root: Path, explicit_archive: Path | None) -> dict[str, object]:
    build_zig_zon = repo_root / "build.zig.zon"
    toolchains_root, toolchains_found = infer_named_root(repo_root, "toolchains")
    memory_root, memory_found = infer_named_root(repo_root, "memory")
    agent_files_root, agent_files_found = infer_named_root(repo_root, "agent_files")
    offline_deps_root, offline_deps_found = infer_named_root(repo_root, "offline-deps")
    saved_archives_root, saved_archives_found = infer_saved_archives_root(repo_root)
    fallback_zig_archive, fallback_found = infer_fallback_zig_archive(repo_root, explicit_archive)

    preflight_command = build_command(
        "python",
        repo_script(repo_root, "scripts/check_linux_build_readiness.py"),
        "--repo-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--offline-deps-root",
        str(offline_deps_root),
        "--expect-saved-archives",
        "--skip-zig-check",
        "--skip-rust-check",
    )
    full_readiness_command = build_command(
        "python",
        repo_script(repo_root, "scripts/check_linux_build_readiness.py"),
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
    )
    workspace_context_command = build_command(
        "python",
        repo_script(repo_root, "scripts/check_issue3_workspace_context.py"),
        "--repo-root",
        str(repo_root),
    )
    saved_zig_route_surface_command = build_command(
        "bash",
        repo_script(repo_root, "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh"),
        "--repo-root",
        str(repo_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--toolchains-root",
        str(toolchains_root),
    )
    saved_zig_route_command = build_command(
        "bash",
        repo_script(repo_root, "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh"),
        "--repo-root",
        str(repo_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--toolchains-root",
        str(toolchains_root),
    )

    if fallback_zig_archive is not None:
        preflight_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
        full_readiness_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
        workspace_context_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
        saved_zig_route_surface_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
        saved_zig_route_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))

    status = "passed" if build_zig_zon.is_file() else "failed"
    failures: list[str] = []
    if not build_zig_zon.is_file():
        failures.append(f"build.zig.zon not found under {repo_root}")

    next_step = choose_next_step(
        build_zig_zon_exists=build_zig_zon.is_file(),
        saved_archives_root_found=saved_archives_found,
        fallback_zig_archive_found=fallback_found,
    )

    return {
        "status": status,
        "repo_root": str(repo_root),
        "build_zig_zon_exists": build_zig_zon.is_file(),
        "toolchains_root": str(toolchains_root),
        "toolchains_root_found": toolchains_found,
        "memory_root": str(memory_root),
        "memory_root_found": memory_found,
        "agent_files_root": str(agent_files_root),
        "agent_files_root_found": agent_files_found,
        "offline_deps_root": str(offline_deps_root),
        "offline_deps_root_found": offline_deps_found,
        "saved_archives_root": str(saved_archives_root),
        "saved_archives_root_found": saved_archives_found,
        "fallback_zig_archive": str(fallback_zig_archive) if fallback_zig_archive else None,
        "fallback_zig_archive_found": fallback_found,
        "suggested_workspace_context_command": workspace_context_command,
        "suggested_preflight_command": preflight_command,
        "suggested_saved_zig_route_surface_command": saved_zig_route_surface_command,
        "suggested_saved_zig_route_command": saved_zig_route_command,
        "suggested_full_readiness_command": full_readiness_command,
        "suggested_next_step": next_step,
        "failures": failures,
    }


def emit_text(context: dict[str, object]) -> None:
    print(f"Repo root: {context['repo_root']}")
    print(f"build.zig.zon present: {'yes' if context['build_zig_zon_exists'] else 'no'}")
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
        f"Fallback Zig archive: {context['fallback_zig_archive']} "
        f"[{'found' if context['fallback_zig_archive_found'] else 'not found'}]"
    )
    print("Suggested workspace-context command:")
    print("  " + " ".join(context["suggested_workspace_context_command"]))
    print("Suggested saved-archive preflight command:")
    print("  " + " ".join(context["suggested_preflight_command"]))
    print("Suggested saved-Zig route surface command:")
    print("  " + " ".join(context["suggested_saved_zig_route_surface_command"]))
    print("Suggested saved-Zig route command:")
    print("  " + " ".join(context["suggested_saved_zig_route_command"]))
    print("Suggested full readiness command:")
    print("  " + " ".join(context["suggested_full_readiness_command"]))
    print(f"Suggested next step: {context['suggested_next_step']}")
    if context["failures"]:
        print("\nWorkspace-aware readiness helper failed:", file=sys.stderr)
        for failure in context["failures"]:
            print(f"  - {failure}", file=sys.stderr)


class WorkspaceReadinessTests(unittest.TestCase):
    def test_nested_checkout_discovers_shared_roots(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            repo_root = base / "restored" / "browser-fork-headed-mode-foundation"
            repo_root.mkdir(parents=True)
            (repo_root / "build.zig.zon").write_text('.minimum_zig_version = "0.15.2"', encoding="utf-8")
            (base / "toolchains").mkdir()
            (base / "memory" / "repo_archives" / "browser" / "dependencies").mkdir(parents=True)
            (base / "agent_files").mkdir()
            (base / "offline-deps").mkdir()
            fallback_archive = base / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE
            fallback_archive.write_text("zig", encoding="utf-8")

            context = collect_context(repo_root, None)

            self.assertEqual(context["status"], "passed")
            self.assertTrue(context["toolchains_root_found"])
            self.assertTrue(context["memory_root_found"])
            self.assertTrue(context["saved_archives_root_found"])
            self.assertTrue(context["agent_files_root_found"])
            self.assertTrue(context["offline_deps_root_found"])
            self.assertTrue(context["fallback_zig_archive_found"])
            self.assertEqual(
                context["saved_archives_root"],
                str((base / "memory" / "repo_archives" / "browser" / "dependencies").resolve()),
            )
            self.assertEqual(
                context["suggested_workspace_context_command"][1],
                str((repo_root / "scripts" / "check_issue3_workspace_context.py").resolve()),
            )
            self.assertEqual(
                context["suggested_preflight_command"][1],
                str((repo_root / "scripts" / "check_linux_build_readiness.py").resolve()),
            )
            self.assertIn("--expect-saved-archives", context["suggested_preflight_command"])
            self.assertIn("--expect-offline-deps", context["suggested_full_readiness_command"])
            self.assertIn("--require-prebuilt-v8", context["suggested_full_readiness_command"])
            self.assertEqual(
                context["suggested_saved_zig_route_surface_command"][1],
                str((repo_root / "scripts" / "linux" / "check_issue3_saved_zig_archive_candidates_route_surface.sh").resolve()),
            )
            self.assertEqual(
                context["suggested_saved_zig_route_command"][1],
                str((repo_root / "scripts" / "linux" / "show_issue3_saved_zig_archive_candidates_route.sh").resolve()),
            )
            self.assertIn("saved-Zig route", context["suggested_next_step"])

    def test_defaults_when_shared_roots_are_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            (repo_root / "build.zig.zon").write_text('.minimum_zig_version = "0.15.2"', encoding="utf-8")

            context = collect_context(repo_root, None)

            self.assertEqual(context["status"], "passed")
            self.assertFalse(context["toolchains_root_found"])
            self.assertFalse(context["memory_root_found"])
            self.assertFalse(context["saved_archives_root_found"])
            self.assertFalse(context["agent_files_root_found"])
            self.assertFalse(context["offline_deps_root_found"])
            self.assertFalse(context["fallback_zig_archive_found"])
            self.assertIn("explicit --fallback-zig-archive path", context["suggested_next_step"])
            self.assertEqual(
                context["suggested_preflight_command"][1],
                str((repo_root / "scripts" / "check_linux_build_readiness.py").resolve()),
            )

    def test_explicit_fallback_archive_is_threaded_into_commands(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            repo_root = base / "browser"
            repo_root.mkdir()
            (repo_root / "build.zig.zon").write_text('.minimum_zig_version = "0.15.2"', encoding="utf-8")
            explicit_archive = base / "custom-zig.tar.xz"
            explicit_archive.write_text("zig", encoding="utf-8")

            context = collect_context(repo_root, explicit_archive)

            self.assertTrue(context["fallback_zig_archive_found"])
            self.assertIn(str(explicit_archive.resolve()), context["suggested_workspace_context_command"])
            self.assertIn(str(explicit_archive.resolve()), context["suggested_preflight_command"])
            self.assertIn(str(explicit_archive.resolve()), context["suggested_full_readiness_command"])
            self.assertIn(str(explicit_archive.resolve()), context["suggested_saved_zig_route_surface_command"])
            self.assertIn(str(explicit_archive.resolve()), context["suggested_saved_zig_route_command"])

    def test_missing_build_manifest_fails_cleanly(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()

            context = collect_context(repo_root, None)

            self.assertEqual(context["status"], "failed")
            self.assertEqual(context["failures"], [f"build.zig.zon not found under {repo_root.resolve()}"])
            self.assertIn("Point --repo-root", context["suggested_next_step"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(WorkspaceReadinessTests)
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