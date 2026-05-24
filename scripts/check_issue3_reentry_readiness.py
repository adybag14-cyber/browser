#!/usr/bin/env python3

"""Aggregate the saved-checkout re-entry checks for issue #3.

This helper answers one practical question for Linux or WSL follow-up work:
is an existing restored checkout ready to reuse, or does the route still need
restore/sync/archive attention before build-readiness or runtime re-entry?
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Run the restored-checkout, saved-memory, and optional "
            "saved-archive-integrity helpers as one issue #3 re-entry preflight."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the restored browser checkout to validate (default: current directory)",
    )
    parser.add_argument(
        "--helper-root",
        default=None,
        help=(
            "Path to the live helper checkout that owns the helper scripts "
            "(default: this script's repo root)"
        ),
    )
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Optional memory root override passed to saved-memory and archive checks",
    )
    parser.add_argument(
        "--agent-files-root",
        default=None,
        help="Optional agent-files root override passed to saved-memory and archive checks",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional fallback Zig archive override passed to saved-memory and archive checks",
    )
    parser.add_argument(
        "--expect-helper-surface",
        action="store_true",
        help="Require the synced helper surface inside the restored checkout",
    )
    parser.add_argument(
        "--skip-archive-integrity",
        action="store_true",
        help="Skip the saved-archive integrity helper when presence-only checks are enough",
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


def resolve_helper_root(path: str | None) -> Path:
    if path is not None:
        return Path(path).resolve()
    return Path(__file__).resolve().parent.parent


def helper_command(
    script_path: Path,
    *,
    repo_root: Path,
    helper_root: Path,
    expect_helper_surface: bool,
    memory_root: str | None,
    agent_files_root: str | None,
    fallback_zig_archive: str | None,
    include_archive_options: bool,
) -> list[str]:
    command = [sys.executable, str(script_path), "--repo-root", str(repo_root), "--json"]
    if script_path.name == "check_issue3_restored_checkout.py":
        if expect_helper_surface:
            command.extend(["--helper-root", str(helper_root), "--expect-helper-surface"])
        return command
    if memory_root is not None:
        command.extend(["--memory-root", memory_root])
    if agent_files_root is not None:
        command.extend(["--agent-files-root", agent_files_root])
    if fallback_zig_archive is not None:
        command.extend(["--fallback-zig-archive", fallback_zig_archive])
    if include_archive_options:
        command.extend(["--helper-root", str(helper_root)])
    return command


def run_json_helper(command: list[str]) -> dict[str, object]:
    completed = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
    )
    stdout = completed.stdout.strip()
    parsed: dict[str, object] | None = None
    parse_error: str | None = None
    if stdout:
        try:
            candidate = json.loads(stdout)
            if isinstance(candidate, dict):
                parsed = candidate
        except json.JSONDecodeError as exc:
            parse_error = str(exc)
    return {
        "ok": completed.returncode == 0,
        "returncode": completed.returncode,
        "command": command,
        "stdout": completed.stdout,
        "stderr": completed.stderr,
        "json": parsed,
        "parse_error": parse_error,
    }


def summarize_helper_outcome(name: str, outcome: dict[str, object]) -> dict[str, object]:
    parsed = outcome.get("json")
    summary: dict[str, object] = {
        "name": name,
        "ok": bool(outcome["ok"]),
        "returncode": outcome["returncode"],
        "command": outcome["command"],
        "parse_error": outcome["parse_error"],
    }
    if isinstance(parsed, dict):
        summary["reported_ok"] = parsed.get("ok")
        if name == "restored_checkout":
            required_paths = parsed.get("required_paths", [])
            helper_surface = parsed.get("helper_surface", [])
            if isinstance(required_paths, list):
                summary["missing_required_paths"] = [
                    entry.get("path")
                    for entry in required_paths
                    if isinstance(entry, dict) and not entry.get("exists")
                ]
            if isinstance(helper_surface, list):
                summary["missing_helper_surface"] = [
                    entry.get("path")
                    for entry in helper_surface
                    if isinstance(entry, dict)
                    and entry.get("required")
                    and not entry.get("exists")
                ]
                summary["drifted_helper_surface"] = [
                    entry.get("path")
                    for entry in helper_surface
                    if isinstance(entry, dict) and entry.get("matches_helper_root") is False
                ]
        elif name == "saved_memory_inputs":
            memory_checks = parsed.get("memory_files", [])
            restored_checks = parsed.get("restored_helper_files", [])
            if isinstance(memory_checks, list):
                summary["missing_memory_inputs"] = [
                    entry.get("path")
                    for entry in memory_checks
                    if isinstance(entry, dict) and entry.get("required") and not entry.get("exists")
                ]
            if isinstance(restored_checks, list):
                summary["missing_restored_helper_files"] = [
                    entry.get("path")
                    for entry in restored_checks
                    if isinstance(entry, dict) and entry.get("required") and not entry.get("exists")
                ]
        elif name == "saved_archive_integrity":
            archives = parsed.get("archives", [])
            if isinstance(archives, list):
                summary["failing_archives"] = [
                    entry.get("path")
                    for entry in archives
                    if isinstance(entry, dict) and not entry.get("ok")
                ]
            fallback = parsed.get("fallback_zig_archive")
            if isinstance(fallback, dict) and not fallback.get("ok", True):
                summary["fallback_zig_issue"] = fallback.get("path")
    return summary


def collect_results(
    *,
    repo_root: Path,
    helper_root: Path,
    memory_root: str | None,
    agent_files_root: str | None,
    fallback_zig_archive: str | None,
    expect_helper_surface: bool,
    skip_archive_integrity: bool,
) -> dict[str, object]:
    scripts = {
        "restored_checkout": helper_root / "scripts/check_issue3_restored_checkout.py",
        "saved_memory_inputs": helper_root / "scripts/check_issue3_saved_memory_inputs.py",
        "saved_archive_integrity": helper_root / "scripts/check_issue3_saved_archive_integrity.py",
    }

    helper_runs: dict[str, dict[str, object]] = {}
    for name in ("restored_checkout", "saved_memory_inputs"):
        command = helper_command(
            scripts[name],
            repo_root=repo_root,
            helper_root=helper_root,
            expect_helper_surface=expect_helper_surface,
            memory_root=memory_root,
            agent_files_root=agent_files_root,
            fallback_zig_archive=fallback_zig_archive,
            include_archive_options=True,
        )
        helper_runs[name] = summarize_helper_outcome(name, run_json_helper(command))

    if skip_archive_integrity:
        helper_runs["saved_archive_integrity"] = {
            "name": "saved_archive_integrity",
            "ok": True,
            "skipped": True,
            "reason": "skip-archive-integrity requested",
        }
    else:
        command = helper_command(
            scripts["saved_archive_integrity"],
            repo_root=repo_root,
            helper_root=helper_root,
            expect_helper_surface=expect_helper_surface,
            memory_root=memory_root,
            agent_files_root=agent_files_root,
            fallback_zig_archive=fallback_zig_archive,
            include_archive_options=False,
        )
        helper_runs["saved_archive_integrity"] = summarize_helper_outcome(
            "saved_archive_integrity",
            run_json_helper(command),
        )

    overall_ok = all(bool(entry.get("ok")) for entry in helper_runs.values())
    next_steps: list[str] = []

    restored = helper_runs["restored_checkout"]
    if not restored.get("ok"):
        if restored.get("missing_required_paths"):
            next_steps.append(
                "Restore a clean snapshot checkout before reopening Linux or WSL follow-up work."
            )
        if restored.get("missing_helper_surface") or restored.get("drifted_helper_surface"):
            next_steps.append(
                "Refresh the restored checkout with restore_saved_browser_snapshot.sh --sync-only or rerun the restore with --sync-helper-surface."
            )

    memory_inputs = helper_runs["saved_memory_inputs"]
    if not memory_inputs.get("ok"):
        next_steps.append(
            "Repair the saved Memory inputs or helper surface before trusting the restored checkout as the follow-up root."
        )

    archive_integrity = helper_runs["saved_archive_integrity"]
    if not archive_integrity.get("ok") and not archive_integrity.get("skipped"):
        next_steps.append(
            "Resolve archive fingerprint or layout drift before reopening Linux build-readiness or runtime re-entry."
        )

    if overall_ok:
        next_steps.append(
            f"Proceed to bash {helper_root / 'scripts/linux/show_issue3_linux_build_readiness_route.sh'} --repo-root {repo_root}"
        )

    return {
        "ok": overall_ok,
        "repo_root": str(repo_root),
        "helper_root": str(helper_root),
        "expect_helper_surface": expect_helper_surface,
        "skip_archive_integrity": skip_archive_integrity,
        "helpers": helper_runs,
        "next_steps": next_steps,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Restored checkout root: {result['repo_root']}")
    print(f"Helper root:           {result['helper_root']}")
    print(
        f"Expect helper surface: {'yes' if result['expect_helper_surface'] else 'no'}"
    )
    print(
        f"Archive integrity:     {'skipped' if result['skip_archive_integrity'] else 'required'}"
    )
    print()
    for name in ("restored_checkout", "saved_memory_inputs", "saved_archive_integrity"):
        helper = result["helpers"][name]
        status = "PASS" if helper.get("ok") else "FAIL"
        if helper.get("skipped"):
            status = "SKIP"
        print(f"[{status}] {name}")
        for key in (
            "missing_required_paths",
            "missing_helper_surface",
            "drifted_helper_surface",
            "missing_memory_inputs",
            "missing_restored_helper_files",
            "failing_archives",
            "fallback_zig_issue",
        ):
            value = helper.get(key)
            if value:
                print(f"  {key}: {value}")
        if helper.get("parse_error"):
            print(f"  parse_error: {helper['parse_error']}")
    print()
    if result["ok"]:
        print("Issue #3 re-entry readiness check passed.")
    else:
        print("Issue #3 re-entry readiness check failed.", file=sys.stderr)
    if result["next_steps"]:
        print("Next steps:")
        for step in result["next_steps"]:
            print(f"  - {step}")


class ReentryReadinessTests(unittest.TestCase):
    def test_reports_restore_sync_step_when_helper_surface_drift_exists(self) -> None:
        with mock.patch(__name__ + ".run_json_helper") as run_helper:
            run_helper.side_effect = [
                {
                    "ok": False,
                    "returncode": 1,
                    "command": ["restored"],
                    "stdout": "",
                    "stderr": "",
                    "json": {
                        "ok": False,
                        "required_paths": [{"path": "build.zig.zon", "exists": True}],
                        "helper_surface": [
                            {
                                "path": "scripts/check_issue3_saved_memory_inputs.py",
                                "required": True,
                                "exists": True,
                                "matches_helper_root": False,
                            }
                        ],
                    },
                    "parse_error": None,
                },
                {
                    "ok": True,
                    "returncode": 0,
                    "command": ["memory"],
                    "stdout": "",
                    "stderr": "",
                    "json": {"ok": True, "memory_files": [], "restored_helper_files": []},
                    "parse_error": None,
                },
                {
                    "ok": True,
                    "returncode": 0,
                    "command": ["archive"],
                    "stdout": "",
                    "stderr": "",
                    "json": {"ok": True, "archives": []},
                    "parse_error": None,
                },
            ]
            result = collect_results(
                repo_root=Path("/tmp/browser-memory-snapshot"),
                helper_root=Path("/tmp/browser"),
                memory_root=None,
                agent_files_root=None,
                fallback_zig_archive=None,
                expect_helper_surface=True,
                skip_archive_integrity=False,
            )
        self.assertFalse(result["ok"])
        self.assertTrue(
            any("--sync-only" in step for step in result["next_steps"]),
            result["next_steps"],
        )

    def test_success_points_to_linux_build_route(self) -> None:
        with mock.patch(__name__ + ".run_json_helper") as run_helper:
            run_helper.side_effect = [
                {
                    "ok": True,
                    "returncode": 0,
                    "command": ["restored"],
                    "stdout": "",
                    "stderr": "",
                    "json": {
                        "ok": True,
                        "required_paths": [],
                        "helper_surface": [],
                    },
                    "parse_error": None,
                },
                {
                    "ok": True,
                    "returncode": 0,
                    "command": ["memory"],
                    "stdout": "",
                    "stderr": "",
                    "json": {"ok": True, "memory_files": [], "restored_helper_files": []},
                    "parse_error": None,
                },
                {
                    "ok": True,
                    "returncode": 0,
                    "command": ["archive"],
                    "stdout": "",
                    "stderr": "",
                    "json": {"ok": True, "archives": []},
                    "parse_error": None,
                },
            ]
            result = collect_results(
                repo_root=Path("/tmp/browser-memory-snapshot"),
                helper_root=Path("/tmp/browser"),
                memory_root=None,
                agent_files_root=None,
                fallback_zig_archive=None,
                expect_helper_surface=False,
                skip_archive_integrity=False,
            )
        self.assertTrue(result["ok"])
        self.assertTrue(
            any("show_issue3_linux_build_readiness_route.sh" in step for step in result["next_steps"])
        )

    def test_skip_archive_integrity_marks_archive_helper_skipped(self) -> None:
        with mock.patch(__name__ + ".run_json_helper") as run_helper:
            run_helper.side_effect = [
                {
                    "ok": True,
                    "returncode": 0,
                    "command": ["restored"],
                    "stdout": "",
                    "stderr": "",
                    "json": {"ok": True, "required_paths": [], "helper_surface": []},
                    "parse_error": None,
                },
                {
                    "ok": True,
                    "returncode": 0,
                    "command": ["memory"],
                    "stdout": "",
                    "stderr": "",
                    "json": {"ok": True, "memory_files": [], "restored_helper_files": []},
                    "parse_error": None,
                },
            ]
            result = collect_results(
                repo_root=Path("/tmp/browser-memory-snapshot"),
                helper_root=Path("/tmp/browser"),
                memory_root=None,
                agent_files_root=None,
                fallback_zig_archive=None,
                expect_helper_surface=False,
                skip_archive_integrity=True,
            )
        self.assertTrue(result["helpers"]["saved_archive_integrity"]["skipped"])


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ReentryReadinessTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    helper_root = resolve_helper_root(args.helper_root)
    result = collect_results(
        repo_root=repo_root,
        helper_root=helper_root,
        memory_root=args.memory_root,
        agent_files_root=args.agent_files_root,
        fallback_zig_archive=args.fallback_zig_archive,
        expect_helper_surface=args.expect_helper_surface,
        skip_archive_integrity=args.skip_archive_integrity,
    )
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())