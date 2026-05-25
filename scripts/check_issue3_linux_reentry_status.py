#!/usr/bin/env python3

"""Summarize the current Linux/WSL re-entry status for issue #11.

This helper keeps the low-volume issue #11 lane on one compact command by
running the saved-Memory preflight, the Zig matching-line gate, and the broader
Linux build-readiness helper in sequence. It does not replace the richer route
notes; it gives future runs one quick status probe that also surfaces the next
command they should run.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import shlex
import subprocess
import sys
import unittest


PROFILE = "issue3-linux-reentry-status"


def format_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Run the issue #11 Linux/WSL re-entry checks in order and surface "
            "the next command to run."
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
        help="Python executable to use for child helper calls (default: current Python)",
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


def build_component_commands(repo_root: pathlib.Path, python_executable: str) -> dict[str, list[str]]:
    return {
        "saved_memory": [
            python_executable,
            str(repo_root / "scripts" / "check_issue3_saved_memory_inputs.py"),
            "--repo-root",
            str(repo_root),
            "--json",
        ],
        "zig_match": [
            "bash",
            str(repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_match.sh"),
            "--repo-root",
            str(repo_root),
            "--json",
        ],
        "build_readiness": [
            python_executable,
            str(repo_root / "scripts" / "check_linux_build_readiness.py"),
            "--repo-root",
            str(repo_root),
            "--expect-saved-archives",
            "--expect-offline-deps",
            "--require-prebuilt-v8",
            "--json",
        ],
    }


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

    if parsed is not None:
        status_value = parsed.get("status")
        ok_value = parsed.get("ok")
        if isinstance(ok_value, bool):
            ok = ok_value
        else:
            ok = status_value in ("passed", "ready", "synced")
        if not summary:
            summary = str(status_value or ("passed" if ok else "failed"))
    else:
        ok = False

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


def route_command(repo_root: pathlib.Path, relative_path: str) -> str:
    return format_command(["bash", str(repo_root / relative_path), "--repo-root", str(repo_root)])


def choose_next_step(results: dict[str, dict[str, object]], repo_root: pathlib.Path) -> str:
    saved_memory = results["saved_memory"]
    if not saved_memory["ok"]:
        return route_command(repo_root, "scripts/linux/show_issue3_saved_memory_inputs_route.sh")

    zig_match = results["zig_match"]
    zig_json = zig_match.get("json") or {}
    if not zig_match["ok"]:
        preferred_restore = None
        if isinstance(zig_json, dict):
            preferred_restore = zig_json.get("preferred_saved_archive_restore_check")
        if isinstance(preferred_restore, str) and preferred_restore:
            return preferred_restore
        return route_command(repo_root, "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh")

    build_readiness = results["build_readiness"]
    readiness_json = build_readiness.get("json") or {}
    if not build_readiness["ok"]:
        suggested = None
        if isinstance(readiness_json, dict):
            suggested = readiness_json.get("suggested_next_step")
        if isinstance(suggested, str) and suggested:
            return suggested
        return route_command(repo_root, "scripts/linux/show_issue3_linux_build_readiness_route.sh")

    return route_command(repo_root, "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh")


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
    print("Issue #11 Linux/WSL re-entry status")
    print()
    print(f"Repo root:            {report['repo_root']}")
    print(f"Python helper:        {report['python']}")
    print(f"Overall status:       {report['status']}")
    print()
    print("Components")
    print("==========")
    components = report["components"]
    assert isinstance(components, dict)
    for key, label in (
        ("saved_memory", "Saved Memory preflight"),
        ("zig_match", "Zig matching-line gate"),
        ("build_readiness", "Linux build-readiness"),
    ):
        result = components[key]
        assert isinstance(result, dict)
        state = "passed" if result["ok"] else "failed"
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


class ReentryStatusTests(unittest.TestCase):
    def test_choose_next_step_prefers_saved_memory_route_first(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        results = {
            "saved_memory": {"ok": False},
            "zig_match": {"ok": False, "json": {}},
            "build_readiness": {"ok": False, "json": {}},
        }

        next_step = choose_next_step(results, repo_root)

        self.assertIn("show_issue3_saved_memory_inputs_route.sh", next_step)

    def test_choose_next_step_uses_preferred_restore_when_zig_match_fails(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        results = {
            "saved_memory": {"ok": True},
            "zig_match": {
                "ok": False,
                "json": {
                    "preferred_saved_archive_restore_check": "bash /tmp/browser/scripts/linux/restore_zig_toolchain_archive.sh --check-only"
                },
            },
            "build_readiness": {"ok": False, "json": {}},
        }

        next_step = choose_next_step(results, repo_root)

        self.assertIn("restore_zig_toolchain_archive.sh --check-only", next_step)

    def test_choose_next_step_falls_back_to_recovery_route_when_restore_missing(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        results = {
            "saved_memory": {"ok": True},
            "zig_match": {"ok": False, "json": {}},
            "build_readiness": {"ok": False, "json": {}},
        }

        next_step = choose_next_step(results, repo_root)

        self.assertIn("show_issue3_zig_toolchain_recovery_route.sh", next_step)

    def test_choose_next_step_uses_readiness_suggestion(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        results = {
            "saved_memory": {"ok": True},
            "zig_match": {"ok": True, "json": {}},
            "build_readiness": {
                "ok": False,
                "json": {"suggested_next_step": "python /tmp/browser/scripts/check_linux_build_readiness.py --repo-root /tmp/browser"},
            },
        }

        next_step = choose_next_step(results, repo_root)

        self.assertIn("check_linux_build_readiness.py", next_step)

    def test_choose_next_step_hands_back_to_runtime_route_on_pass(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        results = {
            "saved_memory": {"ok": True},
            "zig_match": {"ok": True, "json": {}},
            "build_readiness": {"ok": True, "json": {}},
        }

        next_step = choose_next_step(results, repo_root)

        self.assertIn("show_issue3_enter_submit_runtime_revalidation_route.sh", next_step)

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
        import tempfile

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
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ReentryStatusTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    commands = build_component_commands(repo_root, args.python)

    saved_memory = run_json_helper(commands["saved_memory"])
    zig_match = run_json_helper(commands["zig_match"]) if saved_memory["ok"] else {
        "status": "skipped",
        "ok": False,
        "command": format_command(commands["zig_match"]),
        "exit_code": None,
        "stdout": "",
        "stderr": "",
        "json": None,
        "summary": "skipped because the saved-Memory preflight failed",
    }
    build_readiness = run_json_helper(commands["build_readiness"]) if saved_memory["ok"] and zig_match["ok"] else {
        "status": "skipped",
        "ok": False,
        "command": format_command(commands["build_readiness"]),
        "exit_code": None,
        "stdout": "",
        "stderr": "",
        "json": None,
        "summary": "skipped because an earlier gate is still failing",
    }

    results = {
        "saved_memory": saved_memory,
        "zig_match": zig_match,
        "build_readiness": build_readiness,
    }
    next_step = choose_next_step(results, repo_root)
    report = build_report(repo_root, args.python, results, next_step)

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())