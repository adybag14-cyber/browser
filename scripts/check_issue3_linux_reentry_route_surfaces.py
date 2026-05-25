#!/usr/bin/env python3

"""Fail-fast surface aggregation for issue #11 Linux/WSL re-entry routes."""

from __future__ import annotations

import argparse
import json
import pathlib
import shlex
import subprocess
import sys
import tempfile
import unittest


PROFILE = "issue3-linux-reentry-route-surfaces"
ROUTE_SURFACE_STEPS: tuple[tuple[str, str, str, str], ...] = (
    (
        "workspace_context",
        "Workspace-context surface",
        "scripts/linux/check_issue3_workspace_context_route_surface.sh",
        "scripts/linux/show_issue3_workspace_context_route.sh",
    ),
    (
        "progress_tracker",
        "Issue #11 progress-tracker surface",
        "scripts/linux/check_issue3_progress_tracker_route_surface.sh",
        "scripts/linux/show_issue3_progress_tracker_route.sh",
    ),
    (
        "saved_snapshot",
        "Saved snapshot route surface",
        "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
    ),
    (
        "restored_checkout",
        "Restored-checkout route surface",
        "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh",
        "scripts/linux/show_issue3_restored_checkout_reentry_route.sh",
    ),
    (
        "saved_memory",
        "Saved-Memory route surface",
        "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh",
        "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
    ),
    (
        "saved_archive_integrity",
        "Saved-archive integrity surface",
        "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh",
        "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
    ),
    (
        "saved_rust_toolchain",
        "Saved-Rust route surface",
        "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh",
        "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
    ),
    (
        "saved_zig_candidates",
        "Saved-Zig candidates route surface",
        "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh",
        "scripts/linux/show_issue3_saved_zig_archive_candidates_route.sh",
    ),
    (
        "zig_recovery",
        "Zig recovery route surface",
        "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh",
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
    ),
    (
        "zig_archive_restore",
        "Zig archive-restore route surface",
        "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh",
        "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
    ),
    (
        "offline_build_inputs",
        "Offline build-inputs route surface",
        "scripts/linux/check_issue3_offline_build_inputs_route_surface.sh",
        "scripts/linux/show_issue3_offline_build_inputs_route.sh",
    ),
    (
        "linux_build_readiness",
        "Linux build-readiness route surface",
        "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
    ),
    (
        "runtime_revalidation",
        "Runtime revalidation surface",
        "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
    ),
    (
        "windows_runtime_handoff",
        "Windows runtime handoff surface",
        "scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh",
        "scripts/linux/show_issue3_windows_runtime_handoff_route.sh",
    ),
)


def format_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Run the issue #11 Linux/WSL re-entry route surface checks in order "
            "and stop on the first broken helper surface."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser repo root (default: current directory)",
    )
    parser.add_argument(
        "--python",
        default=sys.executable,
        help="Python executable to use for the next-step status helper",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON instead of the human-readable summary",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run the helper's focused unit tests and exit",
    )
    return parser


def build_component_commands(repo_root: pathlib.Path) -> dict[str, list[str]]:
    commands: dict[str, list[str]] = {}
    for key, _label, check_relative_path, _show_relative_path in ROUTE_SURFACE_STEPS:
        commands[key] = [
            "bash",
            str(repo_root / check_relative_path),
            "--repo-root",
            str(repo_root),
            "--json",
        ]
    return commands


def run_json_helper(command: list[str]) -> dict[str, object]:
    try:
        completed = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        return {
            "status": "error",
            "ok": False,
            "command": format_command(command),
            "exit_code": None,
            "stdout": "",
            "stderr": str(exc),
            "json": None,
            "summary": f"helper failed to start: {exc}",
        }

    stdout = completed.stdout.strip()
    stderr = completed.stderr.strip()
    parsed: dict[str, object] | None = None
    summary = ""
    if stdout:
        try:
            loaded = json.loads(stdout)
            if isinstance(loaded, dict):
                parsed = loaded
            else:
                summary = "helper returned non-object JSON"
        except json.JSONDecodeError as exc:
            summary = f"helper returned invalid JSON: {exc}"
    else:
        summary = "helper returned no JSON output"

    ok = completed.returncode == 0
    if parsed is None:
        ok = False
    if parsed is not None:
        if "ok" in parsed and isinstance(parsed["ok"], bool):
            ok = parsed["ok"]
        elif "status" in parsed and isinstance(parsed["status"], str):
            ok = parsed["status"] in ("passed", "ready", "synced")
        elif "missing_count" in parsed and isinstance(parsed["missing_count"], int):
            ok = parsed["missing_count"] == 0

        if not summary:
            if "summary" in parsed and isinstance(parsed["summary"], str):
                summary = parsed["summary"]
            elif "missing_count" in parsed and isinstance(parsed["missing_count"], int):
                summary = f"missing_count={parsed['missing_count']}"
            elif "status" in parsed and isinstance(parsed["status"], str):
                summary = parsed["status"]
            else:
                summary = "passed" if ok else "failed"

    return {
        "status": "passed" if ok else "failed",
        "ok": ok,
        "command": format_command(command),
        "exit_code": completed.returncode,
        "stdout": stdout,
        "stderr": stderr,
        "json": parsed,
        "summary": summary,
    }


def skipped_result(command: list[str], summary: str) -> dict[str, object]:
    return {
        "status": "skipped",
        "ok": False,
        "command": format_command(command),
        "exit_code": None,
        "stdout": "",
        "stderr": "",
        "json": None,
        "summary": summary,
    }


def route_command(repo_root: pathlib.Path, relative_path: str) -> str:
    return format_command(["bash", str(repo_root / relative_path), "--repo-root", str(repo_root)])


def choose_next_step(results: dict[str, dict[str, object]], repo_root: pathlib.Path, python_executable: str) -> str:
    for key, _label, _check_relative_path, show_relative_path in ROUTE_SURFACE_STEPS:
        result = results[key]
        if not result["ok"]:
            return route_command(repo_root, show_relative_path)

    return format_command(
        [
            python_executable,
            str(repo_root / "scripts" / "check_issue3_linux_reentry_status.py"),
            "--repo-root",
            str(repo_root),
        ]
    )


def build_report(
    repo_root: pathlib.Path,
    python_executable: str,
    results: dict[str, dict[str, object]],
    next_step: str,
) -> dict[str, object]:
    overall_ok = all(result["ok"] for result in results.values())
    return {
        "profile": PROFILE,
        "status": "passed" if overall_ok else "failed",
        "repo_root": str(repo_root),
        "python": python_executable,
        "components": results,
        "suggested_next_step": next_step,
    }


def emit_text(report: dict[str, object]) -> None:
    print("Issue #11 Linux/WSL re-entry route surfaces")
    print()
    print(f"Repo root:       {report['repo_root']}")
    print(f"Python helper:   {report['python']}")
    print(f"Overall status:  {report['status']}")
    print()
    print("Components")
    print("==========")
    components = report["components"]
    assert isinstance(components, dict)
    for key, label, _check_relative_path, _show_relative_path in ROUTE_SURFACE_STEPS:
        result = components[key]
        assert isinstance(result, dict)
        state = "passed" if result["ok"] else result["status"]
        print(f"  - {label}: {state}")
        print(f"    Command: {result['command']}")
        if result.get("summary"):
            print(f"    Summary: {result['summary']}")
        if result.get("stderr"):
            print(f"    Stderr:  {result['stderr']}")
    print()
    print("Suggested next step")
    print("===================")
    print(f"  {report['suggested_next_step']}")


class LinuxReentryRouteSurfaceTests(unittest.TestCase):
    def test_build_component_commands_keeps_all_surface_checks(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        commands = build_component_commands(repo_root)

        self.assertEqual(set(commands), {entry[0] for entry in ROUTE_SURFACE_STEPS})
        self.assertTrue(
            any(
                part.endswith("scripts/linux/check_issue3_workspace_context_route_surface.sh")
                for part in commands["workspace_context"]
            )
        )
        self.assertTrue(
            any(
                part.endswith("scripts/linux/check_issue3_progress_tracker_route_surface.sh")
                for part in commands["progress_tracker"]
            )
        )
        self.assertTrue(
            any(
                part.endswith("scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh")
                for part in commands["runtime_revalidation"]
            )
        )
        self.assertTrue(
            any(
                part.endswith("scripts/linux/check_issue3_windows_runtime_handoff_route_surface.sh")
                for part in commands["windows_runtime_handoff"]
            )
        )

    def test_choose_next_step_returns_first_failing_route(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        results = {
            key: {"ok": True}
            for key, _label, _check_relative_path, _show_relative_path in ROUTE_SURFACE_STEPS
        }
        results["saved_memory"] = {"ok": False}

        next_step = choose_next_step(results, repo_root, "/usr/bin/python3")

        self.assertIn("show_issue3_saved_memory_inputs_route.sh", next_step)

    def test_choose_next_step_returns_status_helper_after_all_surfaces_pass(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        results = {
            key: {"ok": True}
            for key, _label, _check_relative_path, _show_relative_path in ROUTE_SURFACE_STEPS
        }

        next_step = choose_next_step(results, repo_root, "/usr/bin/python3")

        self.assertIn("check_issue3_linux_reentry_status.py", next_step)
        self.assertIn("/usr/bin/python3", next_step)

    def test_skipped_result_marks_component_skipped(self) -> None:
        result = skipped_result(["bash", "/tmp/helper.sh"], "earlier gate failed")

        self.assertEqual(result["status"], "skipped")
        self.assertFalse(result["ok"])
        self.assertIn("/tmp/helper.sh", result["command"])

    def test_run_json_helper_reports_invalid_json(self) -> None:
        with tempfile_script("print('not-json')") as script_path:
            result = run_json_helper([sys.executable, str(script_path)])

        self.assertFalse(result["ok"])
        self.assertIn("invalid JSON", result["summary"])


class tempfile_script:
    def __init__(self, body: str) -> None:
        self.body = body
        self.path: pathlib.Path | None = None

    def __enter__(self) -> pathlib.Path:
        directory = tempfile.TemporaryDirectory()
        self._directory = directory
        self.path = pathlib.Path(directory.name) / "helper.py"
        self.path.write_text(self.body, encoding="utf-8")
        return self.path

    def __exit__(self, exc_type, exc, tb) -> None:
        self._directory.cleanup()


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(LinuxReentryRouteSurfaceTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    commands = build_component_commands(repo_root)
    results: dict[str, dict[str, object]] = {}
    earlier_failure = False
    for key, _label, _check_relative_path, _show_relative_path in ROUTE_SURFACE_STEPS:
        if earlier_failure:
            results[key] = skipped_result(
                commands[key],
                "skipped because an earlier route surface is still failing",
            )
            continue

        result = run_json_helper(commands[key])
        results[key] = result
        if not result["ok"]:
            earlier_failure = True

    next_step = choose_next_step(results, repo_root, args.python)
    report = build_report(repo_root, args.python, results, next_step)

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())