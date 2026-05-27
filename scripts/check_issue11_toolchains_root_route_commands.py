#!/usr/bin/env python3

"""Surface issue #11 route commands with an explicit toolchains-root override.

This helper complements check_issue11_toolchains_root_candidates.py. When the
workspace can expose both toolchains/ and .toolchains/, future Linux/WSL
re-entry runs should stop relying on the route printers' defaults and instead
reuse one explicit toolchains root across the issue #11 progress tracker, saved
Rust bridge, Linux build-readiness, and Zig recovery routes.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shlex
import sys
import tempfile
import unittest


DEFAULT_REPO_ROOT = "."
DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"
REQUIRED_REPO_ROOT_FILE = "build.zig.zon"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Surface issue #11 route commands with one explicit toolchains root."
    )
    parser.add_argument(
        "--repo-root",
        default=DEFAULT_REPO_ROOT,
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--helper-root",
        default=None,
        help=(
            "Path to the live helper checkout that should supply follow-up scripts "
            "(default: repo root, or the current live helper checkout when "
            "repo-root is a restored snapshot)"
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
        help="Run focused unit tests and exit",
    )
    return parser


def shell_join(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


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
        and (path / REQUIRED_REPO_ROOT_FILE).is_file()
        and (path / "scripts" / "check_issue3_workspace_context.py").is_file()
        and (path / "scripts" / "check_linux_build_readiness.py").is_file()
        and (path / "scripts" / "linux" / "show_issue3_progress_tracker_route.sh").is_file()
        and (path / "scripts" / "linux" / "show_issue3_saved_rust_build_readiness_route.sh").is_file()
        and (path / "scripts" / "linux" / "show_issue3_linux_build_readiness_route.sh").is_file()
        and (path / "scripts" / "linux" / "show_issue3_zig_toolchain_recovery_route.sh").is_file()
    )


def resolve_default_helper_root(repo_root: Path) -> Path:
    repo_root = repo_root.resolve()
    cwd = Path.cwd().resolve()
    if (
        repo_root.name == DEFAULT_RESTORED_CHECKOUT_NAME
        and cwd != repo_root
        and path_has_live_helper_surface(cwd)
    ):
        return cwd
    return repo_root


def collect_candidates(repo_root: Path, helper_root: Path | None = None) -> dict[str, object]:
    repo_root = repo_root.resolve()
    helper_root = repo_root if helper_root is None else helper_root.resolve()
    hidden_root = locate_first_existing(repo_root, ".toolchains")
    visible_root = locate_first_existing(repo_root, "toolchains")

    preferred_root: Path
    preferred_reason: str
    warnings: list[str] = []

    if hidden_root is not None:
        preferred_root = hidden_root
        preferred_reason = (
            "prefer hidden .toolchains when it exists because the shared staged "
            "toolchain surface may live there"
        )
        if visible_root is not None:
            warnings.append(
                "both .toolchains and toolchains are visible; future reruns should pass "
                "--toolchains-root explicitly instead of trusting route defaults"
            )
    elif visible_root is not None:
        preferred_root = visible_root
        preferred_reason = "use visible toolchains because no hidden .toolchains root was found"
    else:
        preferred_root = (repo_root.parent / "toolchains").resolve()
        preferred_reason = (
            "no existing toolchains root was found; default to ../toolchains for the next "
            "staged-toolchain attempt"
        )
        warnings.append(
            "no existing toolchains root was found above the checkout; the next rerun still "
            "needs a staged toolchain or an explicit restore path"
        )

    rust_toolchain_dir = preferred_root / "rust-1.79.0"
    commands = {
        "progress_tracker_route": shell_join(
            [
                "bash",
                str(helper_root / "scripts" / "linux" / "show_issue3_progress_tracker_route.sh"),
                "--repo-root",
                str(repo_root),
                "--toolchains-root",
                str(preferred_root),
            ]
        ),
        "saved_rust_build_readiness_route": shell_join(
            [
                "bash",
                str(helper_root / "scripts" / "linux" / "show_issue3_saved_rust_build_readiness_route.sh"),
                "--repo-root",
                str(repo_root),
                "--toolchains-root",
                str(preferred_root),
                "--rust-toolchain-dir",
                str(rust_toolchain_dir),
            ]
        ),
        "linux_build_readiness_route": shell_join(
            [
                "bash",
                str(helper_root / "scripts" / "linux" / "show_issue3_linux_build_readiness_route.sh"),
                "--repo-root",
                str(repo_root),
                "--rust-toolchain-dir",
                str(rust_toolchain_dir),
            ]
        ),
        "zig_toolchain_recovery_route": shell_join(
            [
                "bash",
                str(helper_root / "scripts" / "linux" / "show_issue3_zig_toolchain_recovery_route.sh"),
                "--repo-root",
                str(repo_root),
                "--toolchains-root",
                str(preferred_root),
            ]
        ),
    }

    return {
        "status": "attention" if warnings else "passed",
        "repo_root": str(repo_root),
        "helper_root": str(helper_root),
        "hidden_toolchains_root": None if hidden_root is None else str(hidden_root),
        "visible_toolchains_root": None if visible_root is None else str(visible_root),
        "preferred_toolchains_root": str(preferred_root),
        "preferred_rust_toolchain_dir": str(rust_toolchain_dir),
        "preferred_reason": preferred_reason,
        "warnings": warnings,
        "commands": commands,
    }


def emit_text(report: dict[str, object]) -> None:
    print(f"Repo root: {report['repo_root']}")
    print(f"Helper root: {report['helper_root']}")
    print(f"Hidden .toolchains root: {report['hidden_toolchains_root'] or 'not found'}")
    print(f"Visible toolchains root: {report['visible_toolchains_root'] or 'not found'}")
    print(f"Preferred toolchains root: {report['preferred_toolchains_root']}")
    print(f"Preferred Rust toolchain dir: {report['preferred_rust_toolchain_dir']}")
    print(f"Reason: {report['preferred_reason']}")
    print("Suggested route commands:")
    for label, command in report["commands"].items():
        print(f"  {label}:")
        print(f"    {command}")
    if report["warnings"]:
        print("Warnings:")
        for warning in report["warnings"]:
            print(f"  - {warning}")


class ToolchainsRootRouteCommandTests(unittest.TestCase):
    def test_prefers_hidden_root_when_both_exist(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "nested" / "browser"
            repo_root.mkdir(parents=True)
            hidden_root = root / ".toolchains"
            visible_root = root / "toolchains"
            hidden_root.mkdir()
            visible_root.mkdir()

            report = collect_candidates(repo_root)

            self.assertEqual(report["preferred_toolchains_root"], str(hidden_root.resolve()))
            self.assertEqual(report["visible_toolchains_root"], str(visible_root.resolve()))
            self.assertEqual(report["status"], "attention")
            self.assertIn(str(hidden_root.resolve()), report["commands"]["progress_tracker_route"])
            self.assertIn(str(hidden_root.resolve()), report["commands"]["zig_toolchain_recovery_route"])
            self.assertIn(
                str((hidden_root / "rust-1.79.0").resolve()),
                report["commands"]["linux_build_readiness_route"],
            )

    def test_uses_visible_root_when_hidden_root_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "nested" / "browser"
            repo_root.mkdir(parents=True)
            visible_root = root / "toolchains"
            visible_root.mkdir()

            report = collect_candidates(repo_root)

            self.assertEqual(report["preferred_toolchains_root"], str(visible_root.resolve()))
            self.assertEqual(report["status"], "passed")
            self.assertEqual(report["warnings"], [])

    def test_defaults_to_parent_toolchains_when_no_candidate_exists(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()

            report = collect_candidates(repo_root)

            self.assertEqual(
                report["preferred_toolchains_root"],
                str((repo_root.parent / "toolchains").resolve()),
            )
            self.assertEqual(report["status"], "attention")
            self.assertEqual(len(report["warnings"]), 1)

    def test_default_helper_root_prefers_live_helper_cwd_for_restored_snapshot(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            helper_root = root / "browser"
            restored_root = root / DEFAULT_RESTORED_CHECKOUT_NAME
            helper_root.mkdir()
            restored_root.mkdir()
            (helper_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            (restored_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            (helper_root / "scripts" / "linux").mkdir(parents=True)
            (helper_root / "scripts" / "check_issue3_workspace_context.py").write_text("pass\n", encoding="utf-8")
            (helper_root / "scripts" / "check_linux_build_readiness.py").write_text("pass\n", encoding="utf-8")
            for rel_path in (
                "scripts/linux/show_issue3_progress_tracker_route.sh",
                "scripts/linux/show_issue3_saved_rust_build_readiness_route.sh",
                "scripts/linux/show_issue3_linux_build_readiness_route.sh",
                "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
            ):
                path = helper_root / rel_path
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("#!/usr/bin/env bash\n", encoding="utf-8")

            original_cwd = Path.cwd()
            try:
                os.chdir(helper_root)
                self.assertEqual(resolve_default_helper_root(restored_root), helper_root.resolve())
            finally:
                os.chdir(original_cwd)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            ToolchainsRootRouteCommandTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    helper_root = Path(args.helper_root).resolve() if args.helper_root else resolve_default_helper_root(repo_root)
    report = collect_candidates(repo_root, helper_root=helper_root)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())
