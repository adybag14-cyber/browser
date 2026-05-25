#!/usr/bin/env python3

"""Chain the issue #3 Zig matching gate into the broader readiness helper."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Run the branch-compatible Zig gate first, then optionally rerun the "
            "Linux build-readiness helper with the best staged candidate."
        )
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument("--toolchains-root", default=None, help="Optional shared toolchains root")
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help="Optional repo_archives/browser or repo_archives/browser/dependencies root",
    )
    parser.add_argument(
        "--offline-deps-root",
        default=None,
        help="Optional offline dependency root for the broader readiness helper",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional fallback Zig archive override",
    )
    parser.add_argument(
        "--skip-rust-check",
        action="store_true",
        help="Pass --skip-rust-check through to check_linux_build_readiness.py",
    )
    parser.add_argument(
        "--skip-offline-deps",
        action="store_true",
        help="Skip --expect-offline-deps/--require-prebuilt-v8 on the readiness rerun",
    )
    parser.add_argument(
        "--skip-build-readiness",
        action="store_true",
        help="Stop after the matching-line gate instead of rerunning broader readiness",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of text")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


def maybe_add_path_arg(command: list[str], flag: str, value: str | None) -> None:
    if value:
        command.extend((flag, value))


def run_json_command(command: list[str], label: str) -> tuple[dict[str, object], int]:
    try:
        completed = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        raise RuntimeError(f"{label} could not run: {exc}") from exc

    stdout = completed.stdout.strip()
    if not stdout:
        detail = completed.stderr.strip()
        if detail:
            raise RuntimeError(f"{label} produced no JSON output; stderr: {detail}")
        raise RuntimeError(f"{label} produced no JSON output")

    try:
        return json.loads(stdout), completed.returncode
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"{label} returned invalid JSON: {exc}") from exc


def build_match_command(args: argparse.Namespace, repo_root: Path) -> list[str]:
    command = [
        "bash",
        str(repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_match.sh"),
        "--repo-root",
        str(repo_root),
        "--json",
    ]
    maybe_add_path_arg(command, "--toolchains-root", args.toolchains_root)
    maybe_add_path_arg(command, "--saved-archives-root", args.saved_archives_root)
    maybe_add_path_arg(command, "--fallback-zig-archive", args.fallback_zig_archive)
    return command


def build_readiness_command(
    args: argparse.Namespace,
    repo_root: Path,
    zig_path: str,
) -> list[str]:
    command = [
        sys.executable,
        str(repo_root / "scripts" / "check_linux_build_readiness.py"),
        "--repo-root",
        str(repo_root),
        "--zig",
        zig_path,
        "--expect-saved-archives",
        "--json",
    ]
    maybe_add_path_arg(command, "--toolchains-root", args.toolchains_root)
    maybe_add_path_arg(command, "--saved-archives-root", args.saved_archives_root)
    maybe_add_path_arg(command, "--fallback-zig-archive", args.fallback_zig_archive)
    if args.offline_deps_root:
        command.extend(("--offline-deps-root", args.offline_deps_root))
    if args.skip_rust_check:
        command.append("--skip-rust-check")
    if not args.skip_offline_deps:
        command.extend(("--expect-offline-deps", "--require-prebuilt-v8"))
    return command


def choose_matching_candidate(match_report: dict[str, object]) -> str | None:
    candidates = match_report.get("matching_zig_candidates") or []
    if not candidates:
        return None
    first = candidates[0]
    if isinstance(first, dict):
        path = first.get("path")
        return path if isinstance(path, str) and path else None
    return None


def summarize_report(
    args: argparse.Namespace,
    repo_root: Path,
    match_report: dict[str, object],
    match_exit_code: int,
    readiness_report: dict[str, object] | None,
    readiness_exit_code: int | None,
    readiness_command: list[str] | None,
) -> dict[str, object]:
    matching_candidate = choose_matching_candidate(match_report)
    preferred_restore_check = match_report.get("preferred_saved_archive_restore_check")
    preferred_restore = match_report.get("preferred_saved_archive_restore")
    failures = list(match_report.get("failures") or [])

    status = "blocked"
    suggested_next_step = match_report.get("suggested_next_step")
    if matching_candidate is not None and args.skip_build_readiness:
        status = "matching-zig-ready"
        suggested_next_step = "rerun this helper without --skip-build-readiness to continue into full readiness"
    elif matching_candidate is not None and readiness_report is not None:
        readiness_failures = list(readiness_report.get("failures") or [])
        if readiness_failures:
            status = "readiness-blocked"
            failures.extend(readiness_failures)
            suggested_next_step = readiness_report.get("suggested_next_step")
        else:
            status = "ready"
            suggested_next_step = None

    return {
        "status": status,
        "repo_root": str(repo_root),
        "minimum_zig": match_report.get("minimum_zig"),
        "match_exit_code": match_exit_code,
        "readiness_exit_code": readiness_exit_code,
        "matching_zig_candidate": matching_candidate,
        "preferred_saved_archive_restore_check": preferred_restore_check,
        "preferred_saved_archive_restore": preferred_restore,
        "readiness_command": readiness_command,
        "match_report": match_report,
        "readiness_report": readiness_report,
        "failures": failures,
        "suggested_next_step": suggested_next_step,
    }


def emit_text(report: dict[str, object]) -> None:
    print("Issue #3 Zig re-entry preflight")
    print()
    print(f"Repo root:                {report['repo_root']}")
    print(f"Minimum Zig line:         {report['minimum_zig']}")
    print(f"Status:                   {report['status']}")
    candidate = report.get("matching_zig_candidate")
    print(
        "Matching staged Zig:      "
        f"{candidate if candidate else 'none'}"
    )
    restore_check = report.get("preferred_saved_archive_restore_check")
    restore = report.get("preferred_saved_archive_restore")
    if restore_check:
        print("Preferred restore check:")
        print(f"  {restore_check}")
    if restore:
        print("Preferred restore:")
        print(f"  {restore}")
    readiness_command = report.get("readiness_command")
    if readiness_command:
        print("Readiness rerun command:")
        print(f"  {' '.join(readiness_command)}")
    failures = report.get("failures") or []
    if failures:
        print()
        print("Preflight blockers:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
    next_step = report.get("suggested_next_step")
    if next_step:
        print()
        print(f"Suggested next step: {next_step}")


class ZigReentryPreflightTests(unittest.TestCase):
    def write_executable(self, path: Path, body: str) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")
        path.chmod(0o755)

    def make_repo(self, root: Path) -> Path:
        repo_root = root / "browser"
        repo_root.mkdir()
        (repo_root / "scripts" / "linux").mkdir(parents=True)
        return repo_root

    def test_blocked_report_surfaces_restore_commands(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = self.make_repo(root)
            match_report = {
                "status": "failed",
                "minimum_zig": "0.15.2",
                "matching_zig_candidates": [],
                "preferred_saved_archive_restore_check": "bash restore --check-only",
                "preferred_saved_archive_restore": "bash restore",
                "failures": ["no staged Zig candidate"],
                "suggested_next_step": "bash restore --check-only",
            }
            self.write_executable(
                repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_match.sh",
                "#!/usr/bin/env bash\npython3 - <<'PY'\nimport json\nreport = json.loads(" + repr(json.dumps(match_report)) + ")\nprint(json.dumps(report))\nPY\nexit 1\n",
            )
            args = build_parser().parse_args(["--repo-root", str(repo_root)])
            match_data, match_code = run_json_command(build_match_command(args, repo_root), "match helper")
            report = summarize_report(args, repo_root, match_data, match_code, None, None, None)
            self.assertEqual(report["status"], "blocked")
            self.assertEqual(report["suggested_next_step"], "bash restore --check-only")

    def test_ready_report_runs_readiness_with_matching_candidate(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = self.make_repo(root)
            match_report = {
                "status": "passed",
                "minimum_zig": "0.15.2",
                "matching_zig_candidates": [{"path": "/tmp/toolchains/zig-0.15.2/zig"}],
                "preferred_saved_archive_restore_check": None,
                "preferred_saved_archive_restore": None,
                "failures": [],
                "suggested_next_step": None,
            }
            readiness_report = {
                "status": "passed",
                "failures": [],
                "suggested_next_step": None,
            }
            self.write_executable(
                repo_root / "scripts" / "linux" / "check_issue3_zig_toolchain_match.sh",
                "#!/usr/bin/env bash\npython3 - <<'PY'\nimport json\nreport = json.loads(" + repr(json.dumps(match_report)) + ")\nprint(json.dumps(report))\nPY\n",
            )
            self.write_executable(
                repo_root / "scripts" / "check_linux_build_readiness.py",
                "#!/usr/bin/env python3\nimport json\nreport = json.loads(" + repr(json.dumps(readiness_report)) + ")\nprint(json.dumps(report))\n",
            )
            args = build_parser().parse_args(["--repo-root", str(repo_root)])
            match_data, match_code = run_json_command(build_match_command(args, repo_root), "match helper")
            readiness_command = build_readiness_command(
                args,
                repo_root,
                "/tmp/toolchains/zig-0.15.2/zig",
            )
            readiness_data, readiness_code = run_json_command(readiness_command, "readiness helper")
            report = summarize_report(
                args,
                repo_root,
                match_data,
                match_code,
                readiness_data,
                readiness_code,
                readiness_command,
            )
            self.assertEqual(report["status"], "ready")
            self.assertEqual(report["matching_zig_candidate"], "/tmp/toolchains/zig-0.15.2/zig")
            self.assertIsNone(report["suggested_next_step"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ZigReentryPreflightTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    match_report, match_exit_code = run_json_command(
        build_match_command(args, repo_root),
        "issue #3 Zig toolchain match helper",
    )

    readiness_report = None
    readiness_exit_code = None
    readiness_command = None
    matching_candidate = choose_matching_candidate(match_report)
    if matching_candidate is not None and not args.skip_build_readiness:
        readiness_command = build_readiness_command(args, repo_root, matching_candidate)
        readiness_report, readiness_exit_code = run_json_command(
            readiness_command,
            "Linux build-readiness helper",
        )

    report = summarize_report(
        args,
        repo_root,
        match_report,
        match_exit_code,
        readiness_report,
        readiness_exit_code,
        readiness_command,
    )

    if args.json:
        print(json.dumps(report, indent=2))
        return 0 if report["status"] in {"ready", "matching-zig-ready"} else 1

    emit_text(report)
    return 0 if report["status"] in {"ready", "matching-zig-ready"} else 1


if __name__ == "__main__":
    sys.exit(main())
