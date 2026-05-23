#!/usr/bin/env python3

"""Bundle the issue #3 runtime re-entry gate checks into one preflight."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


CHECK_ORDER: tuple[dict[str, object], ...] = (
    {
        "id": "runtime_surface",
        "label": "Runtime route surface",
        "kind": "bash",
        "relative_path": "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh",
        "next_step": "Repair branch-local direct runtime helper drift before retrying the runtime route.",
    },
    {
        "id": "saved_snapshot_surface",
        "label": "Saved snapshot route surface",
        "kind": "bash",
        "relative_path": "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "next_step": "Repair the saved-browser-snapshot helper surface before relying on restored checkout guidance.",
    },
    {
        "id": "linux_build_surface",
        "label": "Linux build-readiness surface",
        "kind": "bash",
        "relative_path": "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh",
        "next_step": "Repair Linux build-readiness route drift before trusting focused Zig output.",
    },
    {
        "id": "saved_memory_inputs",
        "label": "Saved Memory inputs",
        "kind": "python",
        "relative_path": "scripts/check_issue3_saved_memory_inputs.py",
        "next_step": "Restore missing or unreadable saved Memory inputs before reopening the runtime route.",
    },
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Run the branch-local issue #3 re-entry gate checks in one place so "
            "Linux or WSL reruns can fail fast before reopening the blocked "
            "Page.zig and win32_backend.zig runtime lane."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Optional override for the memory root passed to saved-memory preflight",
    )
    parser.add_argument(
        "--agent-files-root",
        default=None,
        help="Optional override for the agent-files root passed to saved-memory preflight",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit fallback Zig archive passed to saved-memory preflight",
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


def run_check(
    *,
    repo_root: Path,
    memory_root: Path | None,
    agent_files_root: Path | None,
    fallback_zig_archive: Path | None,
    check: dict[str, object],
) -> dict[str, object]:
    script_path = repo_root / str(check["relative_path"])
    command: list[str]
    if check["kind"] == "bash":
        command = ["bash", str(script_path), "--repo-root", str(repo_root), "--json"]
    else:
        command = [sys.executable, str(script_path), "--repo-root", str(repo_root), "--json"]
        if memory_root is not None:
            command.extend(["--memory-root", str(memory_root)])
        if agent_files_root is not None:
            command.extend(["--agent-files-root", str(agent_files_root)])
        if fallback_zig_archive is not None:
            command.extend(["--fallback-zig-archive", str(fallback_zig_archive)])

    completed = subprocess.run(
        command,
        capture_output=True,
        text=True,
    )
    stdout = completed.stdout.strip()
    stderr = completed.stderr.strip()

    parsed: dict[str, object]
    try:
        parsed = json.loads(stdout) if stdout else {}
    except json.JSONDecodeError as exc:
        parsed = {
            "parse_error": str(exc),
            "raw_stdout": stdout,
        }

    missing_count = parsed.get("missing_count")
    ok = completed.returncode == 0
    if isinstance(missing_count, int):
        ok = ok and missing_count == 0
    elif "ok" in parsed and isinstance(parsed["ok"], bool):
        ok = ok and bool(parsed["ok"])

    return {
        "id": check["id"],
        "label": check["label"],
        "script_path": str(script_path),
        "command": command,
        "ok": ok,
        "returncode": completed.returncode,
        "missing_count": missing_count,
        "payload": parsed,
        "stdout": stdout,
        "stderr": stderr,
        "next_step": check["next_step"],
    }


def determine_recommended_next_step(results: list[dict[str, object]]) -> str:
    for result in results:
        if not result["ok"]:
            return str(result["next_step"])
    return (
        "All re-entry gate checks passed. Proceed to the source contract check, "
        "then the saved-browser-snapshot or Linux build-readiness route as needed."
    )


def collect_results(
    *,
    repo_root: Path,
    memory_root: Path | None,
    agent_files_root: Path | None,
    fallback_zig_archive: Path | None,
) -> dict[str, object]:
    checks = [
        run_check(
            repo_root=repo_root,
            memory_root=memory_root,
            agent_files_root=agent_files_root,
            fallback_zig_archive=fallback_zig_archive,
            check=check,
        )
        for check in CHECK_ORDER
    ]
    ok = all(check["ok"] for check in checks)
    return {
        "ok": ok,
        "repo_root": str(repo_root),
        "memory_root": str(memory_root) if memory_root is not None else None,
        "agent_files_root": str(agent_files_root) if agent_files_root is not None else None,
        "fallback_zig_archive": str(fallback_zig_archive) if fallback_zig_archive is not None else None,
        "checks": checks,
        "recommended_next_step": determine_recommended_next_step(checks),
    }


def emit_text(result: dict[str, object]) -> None:
    print("Issue #3 re-entry gate bundle")
    print(f"Repo root: {result['repo_root']}")
    if result["memory_root"]:
        print(f"Memory root override: {result['memory_root']}")
    if result["agent_files_root"]:
        print(f"Agent files override: {result['agent_files_root']}")
    if result["fallback_zig_archive"]:
        print(f"Fallback Zig override: {result['fallback_zig_archive']}")
    print("")
    for check in result["checks"]:
        status = "PASS" if check["ok"] else "FAIL"
        detail = ""
        if isinstance(check["missing_count"], int):
            detail = f" missing={check['missing_count']}"
        print(f"[{status}] {check['label']}{detail}")
        print(f"  Script: {check['script_path']}")
        if check["stderr"]:
            print(f"  stderr: {check['stderr']}")
        parse_error = check["payload"].get("parse_error") if isinstance(check["payload"], dict) else None
        if parse_error:
            print(f"  parse error: {parse_error}")
    print("")
    print(f"Recommended next step: {result['recommended_next_step']}")
    if result["ok"]:
        print("Bundle status: PASS")
    else:
        print("Bundle status: FAIL", file=sys.stderr)


class ReentryGateBundleTests(unittest.TestCase):
    def write_file(self, path: Path, content: str) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")

    def build_fake_repo(self, root: Path, *, memory_ok: bool = True, build_ok: bool = True) -> None:
        runtime_script = """#!/usr/bin/env bash
set -euo pipefail
printf '{\"profile\":\"runtime\",\"missing_count\":0}\\n'
"""
        snapshot_script = """#!/usr/bin/env bash
set -euo pipefail
printf '{\"profile\":\"snapshot\",\"missing_count\":0}\\n'
"""
        build_script = """#!/usr/bin/env bash
set -euo pipefail
printf '{\"profile\":\"build\",\"missing_count\":%s}\\n'
exit %s
""" % (
            "0" if build_ok else "2",
            "0" if build_ok else "2",
        )
        memory_script = """#!/usr/bin/env python3
import json
import sys
ok = %s
payload = {\"ok\": ok}
print(json.dumps(payload))
raise SystemExit(0 if ok else 1)
""" % (
            "True" if memory_ok else "False",
        )

        self.write_file(root / "scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh", runtime_script)
        self.write_file(root / "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh", snapshot_script)
        self.write_file(root / "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh", build_script)
        self.write_file(root / "scripts/check_issue3_saved_memory_inputs.py", memory_script)

    def test_collect_results_passes_when_all_checks_pass(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "repo"
            self.build_fake_repo(repo_root)
            result = collect_results(
                repo_root=repo_root,
                memory_root=None,
                agent_files_root=None,
                fallback_zig_archive=None,
            )
            self.assertTrue(result["ok"])
            self.assertIn("All re-entry gate checks passed", result["recommended_next_step"])

    def test_collect_results_prefers_first_failing_gate(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "repo"
            self.build_fake_repo(repo_root, memory_ok=False, build_ok=False)
            result = collect_results(
                repo_root=repo_root,
                memory_root=None,
                agent_files_root=None,
                fallback_zig_archive=None,
            )
            self.assertFalse(result["ok"])
            self.assertEqual(
                result["recommended_next_step"],
                "Repair Linux build-readiness route drift before trusting focused Zig output.",
            )


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ReentryGateBundleTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    memory_root = Path(args.memory_root).resolve() if args.memory_root else None
    agent_files_root = Path(args.agent_files_root).resolve() if args.agent_files_root else None
    fallback_zig_archive = Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None

    result = collect_results(
        repo_root=repo_root,
        memory_root=memory_root,
        agent_files_root=agent_files_root,
        fallback_zig_archive=fallback_zig_archive,
    )
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
