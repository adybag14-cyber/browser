#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shlex
import subprocess
import sys
import unittest


ZIG_RELATED_FAILURE_PREFIXES = (
    "zig ",
    "zig not found on PATH",
    "fallback Zig archive ",
    "discovered a staged Zig candidate at ",
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Wrap scripts/check_linux_build_readiness.py and surface an exact "
            "rerun command when a branch-compatible staged Zig toolchain is "
            "already available."
        )
    )
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--cargo", default="cargo")
    parser.add_argument("--rustc", default="rustc")
    parser.add_argument("--expect-offline-deps", action="store_true")
    parser.add_argument("--offline-deps-root", default=None)
    parser.add_argument("--require-prebuilt-v8", action="store_true")
    parser.add_argument("--expect-saved-archives", action="store_true")
    parser.add_argument("--saved-archives-root", default=None)
    parser.add_argument("--fallback-zig-archive", default=None)
    parser.add_argument("--toolchains-root", default=None)
    parser.add_argument("--readiness-script", default=None)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    return parser


def resolve_readiness_script(repo_root: Path, readiness_script: str | None) -> Path:
    if readiness_script is not None:
        return Path(readiness_script).resolve()
    return (repo_root / "scripts" / "check_linux_build_readiness.py").resolve()


def build_readiness_probe_command(args: argparse.Namespace, repo_root: Path, readiness_script: Path) -> list[str]:
    command = [
        sys.executable,
        str(readiness_script),
        "--repo-root",
        str(repo_root),
        "--cargo",
        args.cargo,
        "--rustc",
        args.rustc,
        "--json",
    ]
    if args.expect_offline_deps:
        command.append("--expect-offline-deps")
    if args.offline_deps_root is not None:
        command.extend(("--offline-deps-root", args.offline_deps_root))
    if args.require_prebuilt_v8:
        command.append("--require-prebuilt-v8")
    if args.expect_saved_archives:
        command.append("--expect-saved-archives")
    if args.saved_archives_root is not None:
        command.extend(("--saved-archives-root", args.saved_archives_root))
    if args.fallback_zig_archive is not None:
        command.extend(("--fallback-zig-archive", args.fallback_zig_archive))
    if args.toolchains_root is not None:
        command.extend(("--toolchains-root", args.toolchains_root))
    return command


def build_matching_zig_rerun_command(
    args: argparse.Namespace,
    repo_root: Path,
    readiness_script: Path,
    zig_path: str,
) -> list[str]:
    command = [
        sys.executable,
        str(readiness_script),
        "--repo-root",
        str(repo_root),
        "--zig",
        zig_path,
        "--cargo",
        args.cargo,
        "--rustc",
        args.rustc,
    ]
    if args.expect_offline_deps:
        command.append("--expect-offline-deps")
    if args.offline_deps_root is not None:
        command.extend(("--offline-deps-root", args.offline_deps_root))
    if args.require_prebuilt_v8:
        command.append("--require-prebuilt-v8")
    if args.expect_saved_archives:
        command.append("--expect-saved-archives")
    if args.saved_archives_root is not None:
        command.extend(("--saved-archives-root", args.saved_archives_root))
    if args.fallback_zig_archive is not None:
        command.extend(("--fallback-zig-archive", args.fallback_zig_archive))
    if args.toolchains_root is not None:
        command.extend(("--toolchains-root", args.toolchains_root))
    return command


def is_zig_only_failure(failure: str) -> bool:
    return failure.startswith(ZIG_RELATED_FAILURE_PREFIXES)


def analyze_readiness_report(
    report: dict[str, object],
    rerun_command: list[str] | None,
) -> dict[str, object]:
    matching_candidates = report.get("matching_zig_candidates") or []
    failures = report.get("failures") or []

    preferred_candidate = matching_candidates[0] if matching_candidates else None
    preferred_zig_path = None
    if isinstance(preferred_candidate, dict):
        preferred_zig_path = preferred_candidate.get("path")

    rerun_ready = bool(
        preferred_zig_path
        and failures
        and all(isinstance(failure, str) and is_zig_only_failure(failure) for failure in failures)
    )

    if preferred_zig_path is None:
        status = "no-matching-zig"
    elif rerun_ready:
        status = "rerun-ready"
    else:
        status = "matching-zig-available"

    return {
        "status": status,
        "rerun_ready": rerun_ready,
        "preferred_matching_zig": preferred_candidate,
        "matching_zig_rerun_command": rerun_command,
        "readiness_report": report,
    }


def format_shell_command(command: list[str] | None) -> str | None:
    if command is None:
        return None
    return " ".join(shlex.quote(part) for part in command)


class MatchingZigRerunTests(unittest.TestCase):
    def test_build_matching_zig_rerun_command_threads_relevant_flags(self) -> None:
        parser = build_parser()
        args = parser.parse_args(
            [
                "--repo-root",
                "/tmp/browser",
                "--cargo",
                "/tmp/rust/bin/cargo",
                "--rustc",
                "/tmp/rust/bin/rustc",
                "--expect-offline-deps",
                "--offline-deps-root",
                "/tmp/offline-deps",
                "--require-prebuilt-v8",
                "--expect-saved-archives",
                "--saved-archives-root",
                "/tmp/memory/repo_archives/browser",
                "--fallback-zig-archive",
                "/tmp/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
                "--toolchains-root",
                "/tmp/toolchains",
            ]
        )

        command = build_matching_zig_rerun_command(
            args,
            Path("/tmp/browser"),
            Path("/tmp/browser/scripts/check_linux_build_readiness.py"),
            "/tmp/toolchains/zig-0.15.7/zig",
        )

        self.assertIn("--zig", command)
        self.assertIn("/tmp/toolchains/zig-0.15.7/zig", command)
        self.assertIn("--expect-offline-deps", command)
        self.assertIn("--require-prebuilt-v8", command)
        self.assertIn("--expect-saved-archives", command)
        self.assertIn("--saved-archives-root", command)
        self.assertIn("--fallback-zig-archive", command)
        self.assertIn("--toolchains-root", command)

    def test_analyze_readiness_report_marks_zig_only_failures_as_rerun_ready(self) -> None:
        report = {
            "matching_zig_candidates": [
                {
                    "path": "/tmp/toolchains/zig-0.15.7/zig",
                    "version": "0.15.7",
                    "status": "matches expected 0.15.x line",
                }
            ],
            "failures": [
                "zig 0.17.0-dev.299+a76ce7710 does not match the branch's expected 0.15.x line",
                "discovered a staged Zig candidate at /tmp/toolchains/zig-0.15.7/zig; rerun with `--zig /tmp/toolchains/zig-0.15.7/zig` to use the branch-compatible toolchain",
            ],
        }

        result = analyze_readiness_report(
            report,
            [sys.executable, "/tmp/browser/scripts/check_linux_build_readiness.py", "--zig", "/tmp/toolchains/zig-0.15.7/zig"],
        )

        self.assertEqual(result["status"], "rerun-ready")
        self.assertTrue(result["rerun_ready"])

    def test_analyze_readiness_report_keeps_other_failures_outside_rerun_ready(self) -> None:
        report = {
            "matching_zig_candidates": [
                {
                    "path": "/tmp/toolchains/zig-0.15.7/zig",
                    "version": "0.15.7",
                    "status": "matches expected 0.15.x line",
                }
            ],
            "failures": [
                "zig not found on PATH (expected `zig` or an explicit override)",
                "offline dependency root is missing: expected /tmp/offline-deps (run scripts/linux/prepare_offline_build_inputs.sh first)",
            ],
        }

        result = analyze_readiness_report(
            report,
            [sys.executable, "/tmp/browser/scripts/check_linux_build_readiness.py", "--zig", "/tmp/toolchains/zig-0.15.7/zig"],
        )

        self.assertEqual(result["status"], "matching-zig-available")
        self.assertFalse(result["rerun_ready"])

    def test_probe_command_uses_json_output(self) -> None:
        parser = build_parser()
        args = parser.parse_args(["--repo-root", "/tmp/browser"])
        command = build_readiness_probe_command(
            args,
            Path("/tmp/browser"),
            Path("/tmp/browser/scripts/check_linux_build_readiness.py"),
        )
        self.assertEqual(command[:2], [sys.executable, "/tmp/browser/scripts/check_linux_build_readiness.py"])
        self.assertIn("--json", command)



def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(MatchingZigRerunTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    readiness_script = resolve_readiness_script(repo_root, args.readiness_script)
    if not readiness_script.is_file():
        print(f"ERROR: readiness helper not found at {readiness_script}", file=sys.stderr)
        return 2

    probe_command = build_readiness_probe_command(args, repo_root, readiness_script)
    completed = subprocess.run(
        probe_command,
        check=False,
        capture_output=True,
        text=True,
    )
    stdout = completed.stdout.strip()
    if not stdout:
        detail = completed.stderr.strip()
        if detail:
            print(f"ERROR: readiness helper produced no JSON output: {detail}", file=sys.stderr)
        else:
            print("ERROR: readiness helper produced no JSON output", file=sys.stderr)
        return 2

    try:
        report = json.loads(stdout)
    except json.JSONDecodeError as exc:
        print(f"ERROR: readiness helper returned invalid JSON: {exc}", file=sys.stderr)
        return 2

    matching_candidates = report.get("matching_zig_candidates") or []
    rerun_command = None
    if matching_candidates and isinstance(matching_candidates[0], dict):
        zig_path = matching_candidates[0].get("path")
        if isinstance(zig_path, str) and zig_path:
            rerun_command = build_matching_zig_rerun_command(args, repo_root, readiness_script, zig_path)

    summary = analyze_readiness_report(report, rerun_command)

    if args.json:
        output = dict(summary)
        output["matching_zig_rerun_command"] = rerun_command
        print(json.dumps(output, indent=2))
        return 0 if summary["rerun_ready"] else 1

    print(f"Repo root: {repo_root}")
    print(f"Readiness helper: {readiness_script}")
    print(f"Status: {summary['status']}")

    preferred_matching_zig = summary["preferred_matching_zig"]
    if isinstance(preferred_matching_zig, dict):
        print(
            "Preferred matching Zig: "
            f"{preferred_matching_zig.get('path')} "
            f"[{preferred_matching_zig.get('version')}; {preferred_matching_zig.get('status')}]"
        )
    else:
        print("Preferred matching Zig: none")

    rerun_command_text = format_shell_command(rerun_command)
    if rerun_command_text is not None:
        print("Exact rerun command:")
        print(f"  {rerun_command_text}")

    failures = report.get("failures") or []
    if failures:
        print("Readiness failures:")
        for failure in failures:
            print(f"  - {failure}")

    if summary["rerun_ready"]:
        print("\nThe current readiness failures are Zig-selection-only; rerun with the staged matching toolchain above.")
        return 0

    if rerun_command_text is not None:
        print("\nA matching staged Zig exists, but the readiness report still has other blockers to clear first.")
    else:
        print("\nNo branch-compatible staged Zig toolchain is available yet.")
    return 1


if __name__ == "__main__":
    sys.exit(main())