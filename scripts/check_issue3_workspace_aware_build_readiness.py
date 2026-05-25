#!/usr/bin/env python3

"""Run issue #3 Linux/WSL build readiness with surfaced workspace roots first.

This helper keeps the issue #11 re-entry lane compact by:
- running scripts/check_issue3_workspace_context.py first
- reusing the surfaced toolchains, saved-archives, and offline-deps roots
- rerunning scripts/check_linux_build_readiness.py with those resolved paths
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import unittest
from unittest import mock


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Run the issue #3 Linux/WSL readiness helper with workspace-context "
            "root discovery first."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--zig",
        default="zig",
        help="Zig executable to probe (default: zig on PATH)",
    )
    parser.add_argument(
        "--cargo",
        default="cargo",
        help="Cargo executable to probe (default: cargo on PATH)",
    )
    parser.add_argument(
        "--rustc",
        default="rustc",
        help="rustc executable to probe (default: rustc on PATH)",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit path to the surfaced fallback Zig archive",
    )
    parser.add_argument(
        "--skip-zig-check",
        action="store_true",
        help="Skip calling zig version in the downstream readiness helper",
    )
    parser.add_argument(
        "--skip-rust-check",
        action="store_true",
        help="Skip probing cargo/rustc in the downstream readiness helper",
    )
    parser.add_argument(
        "--expect-offline-deps",
        action="store_true",
        help="Require the downstream readiness helper to validate offline deps",
    )
    parser.add_argument(
        "--require-prebuilt-v8",
        action="store_true",
        help="Require a prebuilt libc_v8_*.a archive during readiness validation",
    )
    parser.add_argument(
        "--expect-saved-archives",
        action="store_true",
        help="Require the downstream readiness helper to validate saved archives",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of the line-oriented summary",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def _run_json_command(command: list[str], label: str) -> tuple[int, dict[str, object] | None, str | None]:
    completed = subprocess.run(command, check=False, capture_output=True, text=True)
    stdout = completed.stdout.strip()
    stderr = completed.stderr.strip() or None
    if not stdout:
        return completed.returncode, None, stderr or f"{label} produced no JSON output"
    try:
        payload = json.loads(stdout)
    except json.JSONDecodeError as exc:
        detail = stderr or f"{label} returned non-JSON output: {exc}"
        return completed.returncode, None, detail
    return completed.returncode, payload, stderr


def build_workspace_context_command(repo_root: Path, fallback_zig_archive: str | None) -> list[str]:
    command = [
        sys.executable,
        str(repo_root / "scripts" / "check_issue3_workspace_context.py"),
        "--repo-root",
        str(repo_root),
        "--json",
    ]
    if fallback_zig_archive:
        command.extend(["--fallback-zig-archive", fallback_zig_archive])
    return command


def build_readiness_command(
    repo_root: Path,
    workspace_context: dict[str, object],
    args: argparse.Namespace,
) -> list[str]:
    command = [
        sys.executable,
        str(repo_root / "scripts" / "check_linux_build_readiness.py"),
        "--repo-root",
        str(repo_root),
        "--toolchains-root",
        str(workspace_context["toolchains_root"]),
        "--saved-archives-root",
        str(workspace_context["saved_archives_root"]),
        "--offline-deps-root",
        str(workspace_context["offline_deps_root"]),
        "--zig",
        args.zig,
        "--cargo",
        args.cargo,
        "--rustc",
        args.rustc,
        "--json",
    ]
    if args.fallback_zig_archive:
        command.extend(["--fallback-zig-archive", args.fallback_zig_archive])
    elif workspace_context.get("fallback_zig_archive"):
        command.extend(
            ["--fallback-zig-archive", str(workspace_context["fallback_zig_archive"])]
        )
    if args.skip_zig_check:
        command.append("--skip-zig-check")
    if args.skip_rust_check:
        command.append("--skip-rust-check")
    if args.expect_offline_deps:
        command.append("--expect-offline-deps")
    if args.require_prebuilt_v8:
        command.append("--require-prebuilt-v8")
    if args.expect_saved_archives:
        command.append("--expect-saved-archives")
    return command


def collect_report(args: argparse.Namespace) -> dict[str, object]:
    repo_root = Path(args.repo_root).resolve()
    workspace_command = build_workspace_context_command(
        repo_root, args.fallback_zig_archive
    )
    workspace_returncode, workspace_payload, workspace_error = _run_json_command(
        workspace_command, "workspace-context helper"
    )

    if workspace_payload is None:
        return {
            "status": "failed",
            "repo_root": str(repo_root),
            "workspace_context_status": "failed",
            "workspace_context_command": workspace_command,
            "workspace_context_returncode": workspace_returncode,
            "workspace_context_error": workspace_error,
            "readiness_command": None,
            "readiness_status": "not-run",
            "readiness_returncode": None,
            "readiness_report": None,
        }

    readiness_command = build_readiness_command(repo_root, workspace_payload, args)
    readiness_returncode, readiness_payload, readiness_error = _run_json_command(
        readiness_command, "build-readiness helper"
    )

    workspace_status = str(workspace_payload.get("status", "unknown"))
    readiness_status = (
        str(readiness_payload.get("status", "unknown"))
        if readiness_payload is not None
        else "failed"
    )
    overall_status = (
        "passed"
        if workspace_status == "passed"
        and readiness_returncode == 0
        and readiness_status == "passed"
        else "failed"
    )

    return {
        "status": overall_status,
        "repo_root": str(repo_root),
        "workspace_context_status": workspace_status,
        "workspace_context_command": workspace_command,
        "workspace_context_returncode": workspace_returncode,
        "workspace_context_report": workspace_payload,
        "workspace_context_error": workspace_error,
        "readiness_command": readiness_command,
        "readiness_status": readiness_status,
        "readiness_returncode": readiness_returncode,
        "readiness_report": readiness_payload,
        "readiness_error": readiness_error,
    }


def emit_text(report: dict[str, object]) -> None:
    print(f"Repo root: {report['repo_root']}")
    print(f"Workspace-context status: {report['workspace_context_status']}")
    print(
        "Workspace-context command:\n"
        f"  {' '.join(str(part) for part in report['workspace_context_command'])}"
    )
    if report["readiness_command"] is not None:
        print(f"Build-readiness status: {report['readiness_status']}")
        print(
            "Build-readiness command:\n"
            f"  {' '.join(str(part) for part in report['readiness_command'])}"
        )
    if report["workspace_context_error"]:
        print(f"Workspace-context error: {report['workspace_context_error']}")
    if report["readiness_error"]:
        print(f"Build-readiness error: {report['readiness_error']}")
    if report["status"] == "passed":
        print("\nWorkspace-aware build readiness passed.")
    else:
        print("\nWorkspace-aware build readiness failed.", file=sys.stderr)


class WorkspaceAwareReadinessTests(unittest.TestCase):
    def test_build_readiness_command_reuses_workspace_roots_and_flags(self) -> None:
        args = build_parser().parse_args(
            [
                "--repo-root",
                "/tmp/browser",
                "--zig",
                "/tmp/toolchains/zig/zig",
                "--cargo",
                "/tmp/rust/bin/cargo",
                "--rustc",
                "/tmp/rust/bin/rustc",
                "--expect-saved-archives",
                "--expect-offline-deps",
                "--require-prebuilt-v8",
                "--skip-rust-check",
                "--fallback-zig-archive",
                "/tmp/agent_files/zig.tar.xz",
            ]
        )
        workspace_context = {
            "toolchains_root": "/tmp/toolchains",
            "saved_archives_root": "/tmp/memory/repo_archives/browser",
            "offline_deps_root": "/tmp/offline-deps",
            "fallback_zig_archive": "/tmp/agent_files/default-zig.tar.xz",
        }

        command = build_readiness_command(Path("/tmp/browser"), workspace_context, args)

        self.assertIn("--toolchains-root", command)
        self.assertIn("/tmp/toolchains", command)
        self.assertIn("--saved-archives-root", command)
        self.assertIn("/tmp/memory/repo_archives/browser", command)
        self.assertIn("--offline-deps-root", command)
        self.assertIn("/tmp/offline-deps", command)
        self.assertIn("--expect-saved-archives", command)
        self.assertIn("--expect-offline-deps", command)
        self.assertIn("--require-prebuilt-v8", command)
        self.assertIn("--skip-rust-check", command)
        fallback_index = command.index("--fallback-zig-archive") + 1
        self.assertEqual(command[fallback_index], "/tmp/agent_files/zig.tar.xz")

    @mock.patch("subprocess.run")
    def test_collect_report_short_circuits_on_workspace_failure(self, run_mock: mock.Mock) -> None:
        run_mock.return_value = subprocess.CompletedProcess(
            args=["python", "workspace"],
            returncode=2,
            stdout="",
            stderr="missing build.zig.zon",
        )
        args = build_parser().parse_args(["--repo-root", "/tmp/browser"])

        report = collect_report(args)

        self.assertEqual(report["status"], "failed")
        self.assertEqual(report["workspace_context_status"], "failed")
        self.assertEqual(report["readiness_status"], "not-run")
        self.assertIsNone(report["readiness_command"])

    @mock.patch("subprocess.run")
    def test_collect_report_runs_readiness_after_workspace_context(self, run_mock: mock.Mock) -> None:
        workspace_payload = {
            "status": "passed",
            "toolchains_root": "/tmp/toolchains",
            "saved_archives_root": "/tmp/memory/repo_archives/browser",
            "offline_deps_root": "/tmp/offline-deps",
            "fallback_zig_archive": "/tmp/agent_files/default-zig.tar.xz",
        }
        readiness_payload = {"status": "passed", "failures": []}
        run_mock.side_effect = [
            subprocess.CompletedProcess(
                args=["python", "workspace"],
                returncode=0,
                stdout=json.dumps(workspace_payload),
                stderr="",
            ),
            subprocess.CompletedProcess(
                args=["python", "readiness"],
                returncode=0,
                stdout=json.dumps(readiness_payload),
                stderr="",
            ),
        ]
        args = build_parser().parse_args(
            [
                "--repo-root",
                "/tmp/browser",
                "--expect-saved-archives",
                "--skip-zig-check",
            ]
        )

        report = collect_report(args)

        self.assertEqual(report["status"], "passed")
        self.assertEqual(report["workspace_context_status"], "passed")
        self.assertEqual(report["readiness_status"], "passed")
        self.assertEqual(run_mock.call_count, 2)
        readiness_command = report["readiness_command"]
        self.assertIsNotNone(readiness_command)
        self.assertIn("--expect-saved-archives", readiness_command)
        self.assertIn("--skip-zig-check", readiness_command)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            WorkspaceAwareReadinessTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    report = collect_report(args)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())