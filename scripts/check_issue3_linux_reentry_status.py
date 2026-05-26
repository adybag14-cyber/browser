#!/usr/bin/env python3

"""Summarize the current Linux/WSL re-entry status for issue #11.

This helper keeps the low-volume issue #11 lane on one compact command by
running the workspace-context helper, the saved-Memory preflight, the Zig
matching-line gate, and the broader Linux build-readiness helper in sequence.
It does not replace the richer route notes; it gives future runs one quick
status probe that also surfaces the next command they should run.
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


def extract_workspace_overrides(workspace_context: dict[str, object] | None) -> dict[str, str]:
    if not isinstance(workspace_context, dict):
        return {}

    overrides: dict[str, str] = {}
    for key in (
        "memory_root",
        "agent_files_root",
        "restored_checkout_root",
        "saved_archives_root",
        "toolchains_root",
        "offline_deps_root",
    ):
        value = workspace_context.get(key)
        if isinstance(value, str) and value:
            overrides[key] = value

    fallback_archive = workspace_context.get("fallback_zig_archive")
    fallback_found = workspace_context.get("fallback_zig_archive_found")
    if isinstance(fallback_archive, str) and fallback_archive and fallback_found is True:
        overrides["fallback_zig_archive"] = fallback_archive

    return overrides


def build_component_commands(
    repo_root: pathlib.Path,
    python_executable: str,
    workspace_context: dict[str, object] | None = None,
) -> dict[str, list[str]]:
    overrides = extract_workspace_overrides(workspace_context)

    commands = {
        "workspace_context": [
            python_executable,
            str(repo_root / "scripts" / "check_issue3_workspace_context.py"),
            "--repo-root",
            str(repo_root),
            "--json",
        ]
    }

    saved_memory = [
        python_executable,
        str(repo_root / "scripts" / "check_issue3_saved_memory_inputs.py"),
        "--repo-root",
        str(repo_root),
        "--json",
    ]
    if "memory_root" in overrides:
        saved_memory.extend(("--memory-root", overrides["memory_root"]))
    if "agent_files_root" in overrides:
        saved_memory.extend(("--agent-files-root", overrides["agent_files_root"]))
    if "restored_checkout_root" in overrides:
        saved_memory.extend(("--restored-checkout-root", overrides["restored_checkout_root"]))
    if "fallback_zig_archive" in overrides:
        saved_memory.extend(("--fallback-zig-archive", overrides["fallback_zig_archive"]))
    commands["saved_memory"] = saved_memory

    zig_match = [
        "bash",
        str(repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_match.sh"),
        "--repo-root",
        str(repo_root),
        "--json",
    ]
    if "toolchains_root" in overrides:
        zig_match.extend(("--toolchains-root", overrides["toolchains_root"]))
    if "saved_archives_root" in overrides:
        zig_match.extend(("--saved-archives-root", overrides["saved_archives_root"]))
    if "fallback_zig_archive" in overrides:
        zig_match.extend(("--fallback-zig-archive", overrides["fallback_zig_archive"]))
    commands["zig_match"] = zig_match

    build_readiness = [
        python_executable,
        str(repo_root / "scripts" / "check_linux_build_readiness.py"),
        "--repo-root",
        str(repo_root),
        "--expect-saved-archives",
        "--expect-offline-deps",
        "--require-prebuilt-v8",
        "--json",
    ]
    if "toolchains_root" in overrides:
        build_readiness.extend(("--toolchains-root", overrides["toolchains_root"]))
    if "saved_archives_root" in overrides:
        build_readiness.extend(("--saved-archives-root", overrides["saved_archives_root"]))
    if "offline_deps_root" in overrides:
        build_readiness.extend(("--offline-deps-root", overrides["offline_deps_root"]))
    if "fallback_zig_archive" in overrides:
        build_readiness.extend(("--fallback-zig-archive", overrides["fallback_zig_archive"]))
    commands["build_readiness"] = build_readiness

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


def choose_next_step(results: dict[str, dict[str, object]], repo_root: pathlib.Path) -> str:
    workspace_context = results["workspace_context"]
    if not workspace_context["ok"]:
        return route_command(repo_root, "scripts/linux/show_issue3_workspace_context_route.sh")

    saved_memory = results["saved_memory"]
    if not saved_memory["ok"]:
        return route_command(repo_root, "scripts/linux/show_issue3_saved_memory_inputs_route.sh")

    zig_match = results["zig_match"]
    zig_json = zig_match.get("json") or {}
    if not zig_match["ok"]:
        preferred_restore = None
        saved_archive_discovery = None
        if isinstance(zig_json, dict):
            preferred_restore = zig_json.get("preferred_saved_archive_restore_check")
            saved_archive_discovery = zig_json.get("saved_archive_discovery_command")
        if isinstance(preferred_restore, str) and preferred_restore:
            return preferred_restore
        if isinstance(saved_archive_discovery, str) and saved_archive_discovery:
            return saved_archive_discovery
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
        ("workspace_context", "Workspace context"),
        ("saved_memory", "Saved Memory preflight"),
        ("zig_match", "Zig matching-line gate"),
        ("build_readiness", "Linux build-readiness"),
    ):
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


class ReentryStatusTests(unittest.TestCase):
    def test_build_component_commands_threads_workspace_roots_into_child_helpers(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        commands = build_component_commands(
            repo_root,
            "/usr/bin/python3",
            {
                "memory_root": "/tmp/memory",
                "agent_files_root": "/tmp/agent_files",
                "restored_checkout_root": "/tmp/browser-memory-snapshot",
                "saved_archives_root": "/tmp/memory/repo_archives/browser",
                "toolchains_root": "/tmp/toolchains",
                "offline_deps_root": "/tmp/offline-deps",
                "fallback_zig_archive": "/tmp/agent_files/zig.tar.xz",
                "fallback_zig_archive_found": True,
            },
        )

        self.assertIn("--memory-root", commands["saved_memory"])
        self.assertIn("/tmp/memory", commands["saved_memory"])
        self.assertIn("--agent-files-root", commands["saved_memory"])
        self.assertIn("/tmp/agent_files", commands["saved_memory"])
        self.assertIn("--restored-checkout-root", commands["saved_memory"])
        self.assertIn("/tmp/browser-memory-snapshot", commands["saved_memory"])
        self.assertIn("--saved-archives-root", commands["zig_match"])
        self.assertIn("/tmp/memory/repo_archives/browser", commands["zig_match"])
        self.assertIn("--toolchains-root", commands["build_readiness"])
        self.assertIn("/tmp/toolchains", commands["build_readiness"])
        self.assertIn("--offline-deps-root", commands["build_readiness"])
        self.assertIn("/tmp/offline-deps", commands["build_readiness"])
        self.assertIn("--fallback-zig-archive", commands["build_readiness"])
        self.assertIn("/tmp/agent_files/zig.tar.xz", commands["build_readiness"])

    def test_extract_workspace_overrides_skips_missing_fallback_archive(self) -> None:
        overrides = extract_workspace_overrides(
            {
                "memory_root": "/tmp/memory",
                "fallback_zig_archive": "/tmp/agent_files/zig.tar.xz",
                "fallback_zig_archive_found": False,
            }
        )

        self.assertEqual(overrides["memory_root"], "/tmp/memory")
        self.assertNotIn("fallback_zig_archive", overrides)

    def test_choose_next_step_prefers_workspace_context_route_first(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        results = {
            "workspace_context": {"ok": False},
            "saved_memory": {"ok": False},
            "zig_match": {"ok": False, "json": {}},
            "build_readiness": {"ok": False, "json": {}},
        }

        next_step = choose_next_step(results, repo_root)

        self.assertIn("show_issue3_workspace_context_route.sh", next_step)

    def test_choose_next_step_prefers_saved_memory_route_after_workspace_passes(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        results = {
            "workspace_context": {"ok": True},
            "saved_memory": {"ok": False},
            "zig_match": {"ok": False, "json": {}},
            "build_readiness": {"ok": False, "json": {}},
        }

        next_step = choose_next_step(results, repo_root)

        self.assertIn("show_issue3_saved_memory_inputs_route.sh", next_step)

    def test_choose_next_step_uses_preferred_restore_when_zig_match_fails(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        results = {
            "workspace_context": {"ok": True},
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

    def test_choose_next_step_uses_saved_archive_discovery_when_restore_missing(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        results = {
            "workspace_context": {"ok": True},
            "saved_memory": {"ok": True},
            "zig_match": {
                "ok": False,
                "json": {
                    "saved_archive_discovery_command": "python /tmp/browser/scripts/check_issue3_saved_zig_archive_candidates.py --repo-root /tmp/browser"
                },
            },
            "build_readiness": {"ok": False, "json": {}},
        }

        next_step = choose_next_step(results, repo_root)

        self.assertIn("check_issue3_saved_zig_archive_candidates.py", next_step)

    def test_choose_next_step_falls_back_to_recovery_route_when_restore_missing(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        results = {
            "workspace_context": {"ok": True},
            "saved_memory": {"ok": True},
            "zig_match": {"ok": False, "json": {}},
            "build_readiness": {"ok": False, "json": {}},
        }

        next_step = choose_next_step(results, repo_root)

        self.assertIn("show_issue3_zig_toolchain_recovery_route.sh", next_step)

    def test_choose_next_step_uses_readiness_suggestion(self) -> None:
        repo_root = pathlib.Path("/tmp/browser")
        results = {
            "workspace_context": {"ok": True},
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
            "workspace_context": {"ok": True},
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
    initial_commands = build_component_commands(repo_root, args.python)
    workspace_context = run_json_helper(initial_commands["workspace_context"])
    commands = build_component_commands(
        repo_root,
        args.python,
        workspace_context.get("json") if workspace_context["ok"] else None,
    )

    saved_memory = (
        run_json_helper(commands["saved_memory"])
        if workspace_context["ok"]
        else skipped_result(
            commands["saved_memory"],
            "skipped because the workspace-context helper failed",
        )
    )
    zig_match = (
        run_json_helper(commands["zig_match"])
        if workspace_context["ok"] and saved_memory["ok"]
        else skipped_result(
            commands["zig_match"],
            "skipped because an earlier gate is still failing",
        )
    )
    build_readiness = (
        run_json_helper(commands["build_readiness"])
        if workspace_context["ok"] and saved_memory["ok"] and zig_match["ok"]
        else skipped_result(
            commands["build_readiness"],
            "skipped because an earlier gate is still failing",
        )
    )

    results = {
        "workspace_context": workspace_context,
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