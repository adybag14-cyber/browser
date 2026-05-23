#!/usr/bin/env python3

"""Check whether a restored checkout is ready for issue #3 re-entry work.

This helper is meant to run from a newer branch checkout while inspecting a
restored browser snapshot extracted from Memory. It answers two practical
questions before Linux or WSL re-entry work starts:

1. Does the restored checkout contain the core runtime files for the narrowed
   issue #3 Enter-submit lane?
2. Is the restored checkout missing newer branch-local helper surfaces, meaning
   the next run should keep using the live helper checkout with
   ``--repo-root <restored-checkout>`` rather than trying to run those helpers
   inside the restored snapshot itself?
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest


CORE_RUNTIME_FILES: tuple[tuple[str, str], ...] = (
    ("build.zig.zon", "build manifest for minimum Zig and sibling deps"),
    ("src/browser/Page.zig", "Page runtime surface for deferred Enter-submit fixes"),
    ("src/display/win32_backend.zig", "Win32 input suppression surface for issue #3"),
)

REENTRY_HELPER_FILES: tuple[tuple[str, str], ...] = (
    ("docs/ISSUE3_RUNTIME_REENTRY_GATES.md", "read-first runtime gate note"),
    ("docs/ISSUE3_ENTER_SUBMIT_RUNTIME_REVALIDATION.md", "read-first runtime revalidation note"),
    ("docs/ISSUE3_LINUX_BUILD_READINESS_ROUTE.md", "Linux build-readiness note"),
    ("scripts/check_issue3_saved_memory_inputs.py", "saved Memory preflight helper"),
    ("scripts/check_linux_build_readiness.py", "Linux build-readiness checker"),
    ("scripts/linux/show_issue3_linux_build_readiness_route.sh", "Linux route printer"),
    (
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
        "direct runtime route printer",
    ),
)

REQUIRED_MEMORY_FILES: tuple[str, ...] = (
    "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip",
    "repo_archives/browser/README.md",
    "repo_archives/browser/blocker_intelligence.yaml",
    "repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz",
    "repo_archives/browser/dependencies/02-litefetch-html5ever-linux-x86_64-deps-20260509-230736.zip",
    "repo_archives/browser/dependencies/03-boringssl-zig-main.zip",
    "repo_archives/browser/dependencies/04-zig-browser-depo.tar.zip",
)

MINIMUM_ZIG_RE = re.compile(r'\.minimum_zig_version\s*=\s*"([^"]+)"')


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether a restored Memory checkout is ready for issue #3 re-entry "
            "and whether the live helper checkout should remain the command surface."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the restored or target browser checkout to inspect",
    )
    parser.add_argument(
        "--helper-root",
        default=None,
        help=(
            "Path to the newer helper checkout that should host the route commands "
            "(default: current working directory)"
        ),
    )
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Path to the workspace memory root (default: ../memory beside helper root)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON instead of the line-oriented report",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused tests and exit",
    )
    return parser


def resolve_default_memory_root(helper_root: Path) -> Path:
    return (helper_root.parent / "memory").resolve()


def check_paths(base: Path, expectations: tuple[tuple[str, str], ...]) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for relative_path, purpose in expectations:
        path = (base / relative_path).resolve()
        rows.append(
            {
                "relative_path": relative_path,
                "purpose": purpose,
                "path": str(path),
                "exists": path.is_file(),
            }
        )
    return rows


def check_memory_paths(memory_root: Path) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for relative_path in REQUIRED_MEMORY_FILES:
        path = (memory_root / relative_path).resolve()
        rows.append(
            {
                "relative_path": relative_path,
                "path": str(path),
                "exists": path.is_file(),
            }
        )
    return rows


def extract_minimum_zig(repo_root: Path) -> str | None:
    build_zon = repo_root / "build.zig.zon"
    if not build_zon.is_file():
        return None
    match = MINIMUM_ZIG_RE.search(build_zon.read_text(encoding="utf-8"))
    return match.group(1) if match else None


def build_command(helper_root: Path, relative_path: str, repo_root: Path) -> str:
    return f"cd {helper_root} && {relative_path} --repo-root {repo_root}"


def collect_results(repo_root: Path, helper_root: Path, memory_root: Path) -> dict[str, object]:
    core_rows = check_paths(repo_root, CORE_RUNTIME_FILES)
    target_helper_rows = check_paths(repo_root, REENTRY_HELPER_FILES)
    live_helper_rows = check_paths(helper_root, REENTRY_HELPER_FILES)
    memory_rows = check_memory_paths(memory_root)

    missing_core = [row["relative_path"] for row in core_rows if not row["exists"]]
    missing_target_helpers = [row["relative_path"] for row in target_helper_rows if not row["exists"]]
    missing_live_helpers = [row["relative_path"] for row in live_helper_rows if not row["exists"]]
    missing_memory = [row["relative_path"] for row in memory_rows if not row["exists"]]

    minimum_zig = extract_minimum_zig(repo_root)
    restored_checkout_stale = bool(missing_target_helpers) and not bool(missing_live_helpers)

    next_commands: list[str] = []
    if not missing_live_helpers:
        next_commands = [
            build_command(helper_root, "python scripts/check_issue3_saved_memory_inputs.py", repo_root),
            build_command(helper_root, "bash scripts/linux/show_issue3_linux_build_readiness_route.sh", repo_root),
            build_command(
                helper_root,
                "bash scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
                repo_root,
            ),
        ]

    summary = []
    if missing_core:
        summary.append("Restored checkout is missing core issue #3 runtime files.")
    else:
        summary.append("Restored checkout still contains the core issue #3 runtime files.")
    if restored_checkout_stale:
        summary.append(
            "Restored checkout is older than the newer branch-local reentry helpers; keep using the live helper checkout as the command surface."
        )
    elif missing_target_helpers:
        summary.append(
            "Restored checkout is missing some reentry helpers, and the helper checkout is also incomplete."
        )
    else:
        summary.append("Restored checkout already includes the newer branch-local reentry helpers.")
    if missing_memory:
        summary.append("Saved Memory inputs are incomplete for issue #3 re-entry work.")
    else:
        summary.append("Saved Memory inputs needed for issue #3 re-entry are present.")

    ok = not missing_core and not missing_live_helpers and not missing_memory

    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "helper_root": str(helper_root),
        "memory_root": str(memory_root),
        "minimum_zig": minimum_zig,
        "restored_checkout_stale": restored_checkout_stale,
        "core_runtime_files": core_rows,
        "target_reentry_helpers": target_helper_rows,
        "live_reentry_helpers": live_helper_rows,
        "memory_inputs": memory_rows,
        "missing_core_runtime_files": missing_core,
        "missing_target_reentry_helpers": missing_target_helpers,
        "missing_live_reentry_helpers": missing_live_helpers,
        "missing_memory_inputs": missing_memory,
        "next_commands": next_commands,
        "summary": summary,
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #3 restored-checkout reentry readiness")
    print()
    print(f"Target repo root: {result['repo_root']}")
    print(f"Helper root:     {result['helper_root']}")
    print(f"Memory root:     {result['memory_root']}")
    if result["minimum_zig"]:
        print(f"Minimum Zig:     {result['minimum_zig']}")
    print()

    for line in result["summary"]:
        print(f"- {line}")

    print()
    print("Core runtime files:")
    for row in result["core_runtime_files"]:
        status = "PASS" if row["exists"] else "FAIL"
        print(f"  [{status}] {row['relative_path']}")

    print("Target reentry helpers:")
    for row in result["target_reentry_helpers"]:
        status = "PASS" if row["exists"] else "WARN"
        print(f"  [{status}] {row['relative_path']}")

    print("Live helper checkout:")
    for row in result["live_reentry_helpers"]:
        status = "PASS" if row["exists"] else "FAIL"
        print(f"  [{status}] {row['relative_path']}")

    print("Saved Memory inputs:")
    for row in result["memory_inputs"]:
        status = "PASS" if row["exists"] else "FAIL"
        print(f"  [{status}] {row['relative_path']}")

    if result["next_commands"]:
        print()
        print("Suggested next commands:")
        for command in result["next_commands"]:
            print(f"  {command}")


class RestoredCheckoutReadinessTests(unittest.TestCase):
    def write_file(self, root: Path, relative_path: str, contents: str = "x") -> None:
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(contents, encoding="utf-8")

    def create_memory(self, memory_root: Path) -> None:
        for relative_path in REQUIRED_MEMORY_FILES:
            self.write_file(memory_root, relative_path)

    def create_core_runtime(self, repo_root: Path) -> None:
        self.write_file(repo_root, "build.zig.zon", '.minimum_zig_version = "0.15.2";')
        self.write_file(repo_root, "src/browser/Page.zig")
        self.write_file(repo_root, "src/display/win32_backend.zig")

    def create_helper_files(self, root: Path) -> None:
        for relative_path, _purpose in REENTRY_HELPER_FILES:
            self.write_file(root, relative_path)

    def test_detects_stale_restored_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            repo_root = base / "restored"
            helper_root = base / "live"
            memory_root = base / "memory"
            self.create_core_runtime(repo_root)
            self.create_core_runtime(helper_root)
            self.create_helper_files(helper_root)
            self.create_memory(memory_root)

            result = collect_results(repo_root, helper_root, memory_root)

            self.assertTrue(result["ok"])
            self.assertTrue(result["restored_checkout_stale"])
            self.assertTrue(result["missing_target_reentry_helpers"])
            self.assertFalse(result["missing_live_reentry_helpers"])

    def test_passes_when_target_repo_already_has_helpers(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            repo_root = base / "restored"
            helper_root = base / "live"
            memory_root = base / "memory"
            self.create_core_runtime(repo_root)
            self.create_helper_files(repo_root)
            self.create_core_runtime(helper_root)
            self.create_helper_files(helper_root)
            self.create_memory(memory_root)

            result = collect_results(repo_root, helper_root, memory_root)

            self.assertTrue(result["ok"])
            self.assertFalse(result["restored_checkout_stale"])
            self.assertFalse(result["missing_target_reentry_helpers"])

    def test_fails_when_memory_inputs_are_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            repo_root = base / "restored"
            helper_root = base / "live"
            memory_root = base / "memory"
            self.create_core_runtime(repo_root)
            self.create_core_runtime(helper_root)
            self.create_helper_files(helper_root)

            result = collect_results(repo_root, helper_root, memory_root)

            self.assertFalse(result["ok"])
            self.assertTrue(result["missing_memory_inputs"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(RestoredCheckoutReadinessTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    helper_root = Path(args.helper_root).resolve() if args.helper_root else Path.cwd().resolve()
    memory_root = Path(args.memory_root).resolve() if args.memory_root else resolve_default_memory_root(helper_root)

    result = collect_results(repo_root, helper_root, memory_root)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
