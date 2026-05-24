#!/usr/bin/env python3

"""Check whether a local checkout is ready to carry the issue #3 runtime patch."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
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
            "Check whether the current checkout has enough local branch-write "
            "signals to reopen the direct issue #3 runtime patch honestly."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--expect-branch",
        default="fork/headed-mode-foundation",
        help="Branch name expected for the headed-mode runtime lane",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented output",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def run_command(argv: list[str], cwd: Path) -> dict[str, object]:
    try:
        completed = subprocess.run(
            argv,
            cwd=cwd,
            check=False,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        return {
            "ok": False,
            "returncode": None,
            "stdout": "",
            "stderr": "command not found",
        }

    return {
        "ok": completed.returncode == 0,
        "returncode": completed.returncode,
        "stdout": completed.stdout.strip(),
        "stderr": completed.stderr.strip(),
    }


def collect_results(repo_root: Path, expect_branch: str) -> dict[str, object]:
    repo_root = repo_root.resolve()
    target_results = [
        {
            "path": relative_path,
            "exists": (repo_root / relative_path).is_file(),
        }
        for relative_path in TARGET_FILES
    ]
    targets_present = all(entry["exists"] for entry in target_results)

    git_available = shutil.which("git") is not None
    gh_available = shutil.which("gh") is not None

    git_root_check = (
        run_command(["git", "rev-parse", "--show-toplevel"], repo_root)
        if git_available
        else {"ok": False, "stdout": "", "stderr": "git unavailable", "returncode": None}
    )
    is_git_checkout = bool(git_root_check["ok"])

    branch_check = (
        run_command(["git", "branch", "--show-current"], repo_root)
        if is_git_checkout
        else {"ok": False, "stdout": "", "stderr": "not a git checkout", "returncode": None}
    )
    current_branch = branch_check["stdout"] if branch_check["ok"] else ""
    branch_matches = current_branch == expect_branch

    remote_check = (
        run_command(["git", "remote"], repo_root)
        if is_git_checkout
        else {"ok": False, "stdout": "", "stderr": "not a git checkout", "returncode": None}
    )
    remote_names = [
        line.strip()
        for line in str(remote_check["stdout"]).splitlines()
        if line.strip()
    ]
    has_remote = bool(remote_names)

    gh_auth_check = (
        run_command(["gh", "auth", "status"], repo_root)
        if gh_available
        else {"ok": False, "stdout": "", "stderr": "gh unavailable", "returncode": None}
    )
    gh_authenticated = bool(gh_auth_check["ok"])

    token_hints = [
        name
        for name in ("GITHUB_TOKEN", "GH_TOKEN")
        if os.environ.get(name)
    ]

    plausible_write_signal = any(
        (
            gh_authenticated,
            bool(token_hints),
            has_remote and branch_matches,
        )
    )

    if targets_present and is_git_checkout and branch_matches and plausible_write_signal:
        verdict = "ready"
    elif targets_present and is_git_checkout:
        verdict = "partial"
    else:
        verdict = "blocked"

    next_steps: list[str]
    if verdict == "ready":
        next_steps = [
            "Re-check the issue #3 runtime contract markers before editing Page.zig and win32_backend.zig.",
            "Use the runtime re-entry gates note and narrowed revalidation note for the next direct patch replay.",
        ]
    elif verdict == "partial":
        next_steps = [
            "Confirm the actual branch-write method before editing large existing files.",
            "If write access is still uncertain, stay on helper, docs, or validation slices instead of reopening the direct runtime patch.",
        ]
    else:
        next_steps = [
            "Restore or sync a reusable checkout before reopening the direct runtime patch.",
            "Keep working on build-readiness or validation helpers until a real branch-write path exists.",
        ]

    return {
        "profile": "issue3-branch-write-readiness",
        "repo_root": str(repo_root),
        "expect_branch": expect_branch,
        "target_files": target_results,
        "targets_present": targets_present,
        "git_available": git_available,
        "gh_available": gh_available,
        "is_git_checkout": is_git_checkout,
        "git_root_check": git_root_check,
        "current_branch": current_branch,
        "branch_matches": branch_matches,
        "remote_names": remote_names,
        "has_remote": has_remote,
        "gh_auth_check": gh_auth_check,
        "gh_authenticated": gh_authenticated,
        "token_hints": token_hints,
        "plausible_write_signal": plausible_write_signal,
        "verdict": verdict,
        "next_steps": next_steps,
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #3 branch-write readiness")
    print("")
    print(f"Repo root:         {result['repo_root']}")
    print(f"Expected branch:   {result['expect_branch']}")
    print(f"Verdict:           {result['verdict']}")
    print("")
    print("Target files")
    print("============")
    for entry in result["target_files"]:
        status = "PASS" if entry["exists"] else "FAIL"
        print(f"  [{status}] {entry['path']}")
    print("")
    print("Checkout signals")
    print("================")
    print(f"  git available:         {'yes' if result['git_available'] else 'no'}")
    print(f"  gh available:          {'yes' if result['gh_available'] else 'no'}")
    print(f"  git checkout:          {'yes' if result['is_git_checkout'] else 'no'}")
    print(f"  current branch:        {result['current_branch'] or 'unavailable'}")
    print(f"  branch matches:        {'yes' if result['branch_matches'] else 'no'}")
    print(f"  remotes configured:    {', '.join(result['remote_names']) if result['remote_names'] else 'none'}")
    print(f"  gh authenticated:      {'yes' if result['gh_authenticated'] else 'no'}")
    print(f"  token hints present:   {', '.join(result['token_hints']) if result['token_hints'] else 'none'}")
    print(f"  plausible write path:  {'yes' if result['plausible_write_signal'] else 'no'}")
    print("")
    print("Next steps")
    print("==========")
    for step in result["next_steps"]:
        print(f"  - {step}")


class BranchWriteReadinessTests(unittest.TestCase):
    def test_verdict_blocked_without_targets(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            result = collect_results(Path(tmpdir), "fork/headed-mode-foundation")
            self.assertEqual(result["verdict"], "blocked")
            self.assertFalse(result["targets_present"])

    def test_verdict_blocked_for_plain_checkout_shape_without_git(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            for relative_path in TARGET_FILES:
                target = repo_root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("// stub\n", encoding="utf-8")

            original_which = shutil.which
            try:
                shutil.which = lambda name: None if name in {"git", "gh"} else original_which(name)
                result = collect_results(repo_root, "fork/headed-mode-foundation")
            finally:
                shutil.which = original_which

            self.assertEqual(result["verdict"], "blocked")

    def test_emit_text_mentions_verdict(self) -> None:
        sample = {
            "repo_root": "/tmp/browser",
            "expect_branch": "fork/headed-mode-foundation",
            "verdict": "partial",
            "target_files": [{"path": TARGET_FILES[0], "exists": True}],
            "git_available": True,
            "gh_available": False,
            "is_git_checkout": True,
            "current_branch": "fork/headed-mode-foundation",
            "branch_matches": True,
            "remote_names": ["origin"],
            "gh_authenticated": False,
            "token_hints": [],
            "plausible_write_signal": True,
            "next_steps": ["Do the next thing."],
        }
        with tempfile.TemporaryFile(mode="w+") as handle:
            stdout = sys.stdout
            try:
                sys.stdout = handle
                emit_text(sample)
            finally:
                sys.stdout = stdout
            handle.seek(0)
            output = handle.read()
        self.assertIn("Verdict:           partial", output)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(BranchWriteReadinessTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    result = collect_results(Path(args.repo_root), args.expect_branch)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["verdict"] == "ready" else 1


if __name__ == "__main__":
    sys.exit(main())
