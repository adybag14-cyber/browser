#!/usr/bin/env python3

"""Check whether a checkout is safe for the direct issue #3 runtime edit.

This is the small companion to the broader issue #3 re-entry helpers. It only
answers the publication-path question for the large existing-file runtime patch:
is this a real writable checkout on a branch, with the target files present and
writable, or is it just an extracted snapshot that should not be used for the
direct Page.zig and win32_backend.zig edit?
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import os
import subprocess
import sys
import tempfile
import unittest


TARGET_FILES: tuple[str, ...] = (
    "src/browser/Page.zig",
    "src/display/win32_backend.zig",
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the current checkout is a writable publication path "
            "for the direct issue #3 runtime patch."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
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
        help="Run focused helper tests and exit",
    )
    return parser


def run_git(repo_root: Path, *args: str) -> tuple[bool, str]:
    try:
        completed = subprocess.run(
            ["git", *args],
            cwd=repo_root,
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as exc:
        return False, str(exc)
    except subprocess.CalledProcessError as exc:
        detail = exc.stderr.strip() or exc.stdout.strip() or str(exc)
        return False, detail
    return True, completed.stdout.strip() or completed.stderr.strip()


def collect_result(repo_root: Path) -> dict[str, object]:
    git_dir_exists = (repo_root / ".git").exists()
    branch_name = None
    detached_head = False
    git_status_short = None
    git_status_error = None
    if git_dir_exists:
        ok, output = run_git(repo_root, "rev-parse", "--abbrev-ref", "HEAD")
        if ok:
            branch_name = output
            detached_head = output == "HEAD"
        else:
            git_status_error = output

        ok, output = run_git(repo_root, "status", "--short")
        if ok:
            git_status_short = output
        elif git_status_error is None:
            git_status_error = output

    targets = []
    missing_targets = []
    non_writable_targets = []
    for relative_path in TARGET_FILES:
        full_path = repo_root / relative_path
        exists = full_path.is_file()
        writable = exists and os.access(full_path, os.W_OK)
        targets.append(
            {
                "path": relative_path,
                "exists": exists,
                "writable": writable,
            }
        )
        if not exists:
            missing_targets.append(relative_path)
        elif not writable:
            non_writable_targets.append(relative_path)

    ready = (
        git_dir_exists
        and not detached_head
        and not missing_targets
        and not non_writable_targets
    )

    blockers = []
    if not git_dir_exists:
        blockers.append("repo root does not expose a local .git checkout")
    if detached_head:
        blockers.append("git checkout is detached at HEAD instead of a writable branch")
    if missing_targets:
        blockers.append("target files are missing from this checkout")
    if non_writable_targets:
        blockers.append("target files are not writable in this checkout")
    if git_status_error is not None:
        blockers.append(f"git probe failed: {git_status_error}")

    next_steps = []
    if not git_dir_exists:
        next_steps.append("restore or clone a writable fork/headed-mode-foundation checkout before reopening the direct runtime patch")
    if detached_head:
        next_steps.append("switch to a real writable branch checkout instead of an extracted or detached snapshot")
    if missing_targets or non_writable_targets:
        next_steps.append("re-stage the live branch checkout that contains writable Page.zig and win32_backend.zig surfaces")

    return {
        "repo_root": str(repo_root),
        "ready": ready,
        "git_checkout_present": git_dir_exists,
        "git_branch": branch_name,
        "git_detached_head": detached_head,
        "git_status_short": git_status_short,
        "targets": targets,
        "blockers": blockers,
        "next_steps": next_steps,
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #3 writable checkout gate")
    print("")
    print(f"Repo root: {result['repo_root']}")
    if result["git_branch"] is not None:
        print(f"Branch: {result['git_branch']}")
    print("")

    for target in result["targets"]:
        status = "PASS" if target["exists"] and target["writable"] else "FAIL"
        print(f"[{status}] {target['path']}")

    print("")
    gate_status = "OPEN" if result["ready"] else "CLOSED"
    print(f"Writable checkout gate: {gate_status}")

    if result["blockers"]:
        print("Blockers:")
        for blocker in result["blockers"]:
            print(f"  - {blocker}")

    if result["git_status_short"]:
        print("Local git status:")
        for line in result["git_status_short"].splitlines():
            print(f"  {line}")

    if result["next_steps"]:
        print("Next steps:")
        for step in result["next_steps"]:
            print(f"  - {step}")


class WritableCheckoutGateTests(unittest.TestCase):
    def test_reports_missing_git_checkout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            for relative_path in TARGET_FILES:
                full_path = repo_root / relative_path
                full_path.parent.mkdir(parents=True, exist_ok=True)
                full_path.write_text("// test\n", encoding="utf-8")

            result = collect_result(repo_root)
            self.assertFalse(result["ready"])
            self.assertIn("repo root does not expose a local .git checkout", result["blockers"])

    def test_reports_missing_target_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            (repo_root / ".git").mkdir()
            page_path = repo_root / TARGET_FILES[0]
            page_path.parent.mkdir(parents=True, exist_ok=True)
            page_path.write_text("// page\n", encoding="utf-8")

            result = collect_result(repo_root)
            self.assertFalse(result["ready"])
            self.assertIn("target files are missing from this checkout", result["blockers"])


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(WritableCheckoutGateTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    result = collect_result(Path(args.repo_root).resolve())
    if args.json:
        json.dump(result, sys.stdout, indent=2)
        print()
    else:
        emit_text(result)

    return 0 if result["ready"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
