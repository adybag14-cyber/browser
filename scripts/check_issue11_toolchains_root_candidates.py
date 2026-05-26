#!/usr/bin/env python3

"""Surface candidate toolchains roots for issue #11 Linux/WSL reruns.

This helper exists for the re-entry lane where headed runtime work is still
blocked on environment readiness. When both `toolchains/` and `.toolchains/`
are visible above a checkout, future runs should stop guessing and pass an
explicit `--toolchains-root` override to the next readiness helper.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


DEFAULT_REPO_ROOT = "."


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Surface visible toolchains roots for issue #11 reruns."
    )
    parser.add_argument(
        "--repo-root",
        default=DEFAULT_REPO_ROOT,
        help="Path to the browser checkout root (default: current directory)",
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


def collect_candidates(repo_root: Path) -> dict[str, object]:
    hidden_root = locate_first_existing(repo_root, ".toolchains")
    visible_root = locate_first_existing(repo_root, "toolchains")

    preferred_root = None
    preferred_reason = ""
    warnings: list[str] = []

    if hidden_root is not None:
        preferred_root = hidden_root
        preferred_reason = "prefer hidden .toolchains when it exists because staged shared toolchains may live there"
        if visible_root is not None:
            warnings.append(
                "both .toolchains and toolchains are visible; pass --toolchains-root explicitly so later reruns do not pick the wrong surface"
            )
    elif visible_root is not None:
        preferred_root = visible_root
        preferred_reason = "use visible toolchains because no hidden .toolchains root was found"
    else:
        preferred_root = (repo_root.parent / "toolchains").resolve()
        preferred_reason = "no existing toolchains root was found; default to ../toolchains for the next staged-toolchain attempt"
        warnings.append(
            "no existing toolchains root was found above the checkout; later helpers will need a staged toolchain or an explicit restore path"
        )

    workspace_context_command = [
        "python",
        "scripts/check_issue3_workspace_context.py",
        "--repo-root",
        str(repo_root),
    ]
    readiness_command = [
        "python",
        "scripts/check_linux_build_readiness.py",
        "--repo-root",
        str(repo_root),
        "--toolchains-root",
        str(preferred_root),
    ]
    nested_preflight_command = [
        "bash",
        "scripts/linux/run_issue11_nested_workspace_saved_memory_preflight.sh",
        "--repo-root",
        str(repo_root),
    ]
    zig_recovery_command = [
        "bash",
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
        "--repo-root",
        str(repo_root),
        "--toolchains-root",
        str(preferred_root),
    ]

    status = "attention" if warnings else "passed"

    return {
        "status": status,
        "repo_root": str(repo_root),
        "hidden_toolchains_root": None if hidden_root is None else str(hidden_root),
        "visible_toolchains_root": None if visible_root is None else str(visible_root),
        "preferred_toolchains_root": str(preferred_root),
        "preferred_reason": preferred_reason,
        "warnings": warnings,
        "suggested_workspace_context_command": workspace_context_command,
        "suggested_readiness_command": readiness_command,
        "suggested_nested_preflight_command": nested_preflight_command,
        "suggested_zig_recovery_command": zig_recovery_command,
    }


def emit_text(report: dict[str, object]) -> None:
    print(f"Repo root: {report['repo_root']}")
    print(f"Hidden .toolchains root: {report['hidden_toolchains_root'] or 'not found'}")
    print(f"Visible toolchains root: {report['visible_toolchains_root'] or 'not found'}")
    print(f"Preferred toolchains root: {report['preferred_toolchains_root']}")
    print(f"Reason: {report['preferred_reason']}")
    print("Suggested workspace-context command:")
    print("  " + " ".join(report["suggested_workspace_context_command"]))
    print("Suggested readiness command:")
    print("  " + " ".join(report["suggested_readiness_command"]))
    print("Suggested nested preflight command:")
    print("  " + " ".join(report["suggested_nested_preflight_command"]))
    print("Suggested Zig recovery command:")
    print("  " + " ".join(report["suggested_zig_recovery_command"]))
    if report["warnings"]:
        print("Warnings:")
        for warning in report["warnings"]:
            print(f"  - {warning}")


class ToolchainsRootCandidateTests(unittest.TestCase):
    def test_prefers_hidden_root_when_both_exist(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            repo_root = base / "restored" / "browser"
            repo_root.mkdir(parents=True)
            hidden_root = base / ".toolchains"
            visible_root = base / "toolchains"
            hidden_root.mkdir()
            visible_root.mkdir()

            report = collect_candidates(repo_root)

            self.assertEqual(report["preferred_toolchains_root"], str(hidden_root.resolve()))
            self.assertEqual(report["visible_toolchains_root"], str(visible_root.resolve()))
            self.assertEqual(report["status"], "attention")
            self.assertEqual(len(report["warnings"]), 1)
            self.assertIn(str(hidden_root.resolve()), report["suggested_readiness_command"])
            self.assertIn(str(hidden_root.resolve()), report["suggested_zig_recovery_command"])

    def test_uses_visible_root_when_hidden_root_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            base = Path(tmpdir)
            repo_root = base / "restored" / "browser"
            repo_root.mkdir(parents=True)
            visible_root = base / "toolchains"
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


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            ToolchainsRootCandidateTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    report = collect_candidates(repo_root)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())
