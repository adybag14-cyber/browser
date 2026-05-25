#!/usr/bin/env python3

"""Bridge Linux build readiness with saved Zig archive restore guidance."""

from __future__ import annotations

import argparse
import json
import pathlib
import subprocess
import sys
import tempfile
import textwrap
import unittest


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Run the Linux build-readiness helper and the saved Zig archive helper "
            "together so issue #3 re-entry gets an exact next step."
        )
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help="Optional path to repo_archives/browser or repo_archives/browser/dependencies",
    )
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Optional path to the shared toolchains directory",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional path to the surfaced fallback Zig archive",
    )
    parser.add_argument(
        "--skip-rust-check",
        action="store_true",
        help="Pass through to the Linux build-readiness helper",
    )
    parser.add_argument(
        "--expect-offline-deps",
        action="store_true",
        help="Pass through to the Linux build-readiness helper",
    )
    parser.add_argument(
        "--offline-deps-root",
        default=None,
        help="Optional path to the offline dependency root",
    )
    parser.add_argument(
        "--require-prebuilt-v8",
        action="store_true",
        help="Pass through to the Linux build-readiness helper",
    )
    parser.add_argument(
        "--expect-saved-archives",
        action="store_true",
        help="Pass through to the Linux build-readiness helper",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit combined JSON instead of the human-readable summary",
    )
    parser.add_argument("--self-test", action="store_true", help="Run focused tests and exit")
    return parser


def build_script_path(repo_root: pathlib.Path, relative_path: str) -> pathlib.Path:
    return repo_root / relative_path


def build_command(
    script_path: pathlib.Path,
    repo_root: pathlib.Path,
    *,
    saved_archives_root: pathlib.Path | None,
    toolchains_root: pathlib.Path | None,
    fallback_zig_archive: pathlib.Path | None,
    skip_rust_check: bool,
    expect_offline_deps: bool,
    offline_deps_root: pathlib.Path | None,
    require_prebuilt_v8: bool,
    expect_saved_archives: bool,
    kind: str,
) -> list[str]:
    command = [sys.executable, str(script_path), "--repo-root", str(repo_root), "--json"]
    if saved_archives_root is not None:
        command.extend(("--saved-archives-root", str(saved_archives_root)))
    if toolchains_root is not None:
        command.extend(("--toolchains-root", str(toolchains_root)))
    if fallback_zig_archive is not None:
        command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
    if kind == "readiness":
        if skip_rust_check:
            command.append("--skip-rust-check")
        if expect_offline_deps:
            command.append("--expect-offline-deps")
        if offline_deps_root is not None:
            command.extend(("--offline-deps-root", str(offline_deps_root)))
        if require_prebuilt_v8:
            command.append("--require-prebuilt-v8")
        if expect_saved_archives:
            command.append("--expect-saved-archives")
    return command


def run_json_command(command: list[str]) -> tuple[int, dict[str, object]]:
    completed = subprocess.run(command, check=False, capture_output=True, text=True)
    stdout = completed.stdout.strip()
    if not stdout:
        stderr = completed.stderr.strip() or "no JSON output received"
        raise RuntimeError(f"command failed before emitting JSON: {stderr}")
    try:
        payload = json.loads(stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"command did not emit valid JSON: {exc}") from exc
    return completed.returncode, payload


def choose_combined_next_step(
    readiness_report: dict[str, object],
    saved_zig_report: dict[str, object],
) -> str | None:
    matching_candidates = readiness_report.get("matching_zig_candidates") or []
    if matching_candidates:
        candidate = matching_candidates[0]
        return f"rerun the readiness helper with --zig {candidate} to use the staged matching Zig toolchain"

    saved_zig_commands = saved_zig_report.get("commands") or {}
    restore_check = saved_zig_commands.get("restore_check")
    restore = saved_zig_commands.get("restore")
    if restore_check and restore:
        return (
            f"run {restore_check}, then {restore}, and rerun the Linux build-readiness helper"
        )

    readiness_next = readiness_report.get("suggested_next_step")
    if isinstance(readiness_next, str) and readiness_next:
        return readiness_next
    return None


def build_combined_report(
    readiness_exit_code: int,
    readiness_report: dict[str, object],
    saved_zig_exit_code: int,
    saved_zig_report: dict[str, object],
) -> dict[str, object]:
    combined_next_step = choose_combined_next_step(readiness_report, saved_zig_report)
    return {
        "status": "passed"
        if readiness_exit_code == 0 and saved_zig_exit_code == 0
        else "failed",
        "readiness_exit_code": readiness_exit_code,
        "saved_zig_exit_code": saved_zig_exit_code,
        "readiness": readiness_report,
        "saved_zig": saved_zig_report,
        "combined_next_step": combined_next_step,
    }


def emit_text(report: dict[str, object]) -> None:
    readiness = report["readiness"]
    saved_zig = report["saved_zig"]
    print("Issue #3 Linux build-readiness re-entry bridge")
    print()
    print(f"Readiness status: {readiness.get('status')}")
    print(f"Saved Zig status: {saved_zig.get('status')}")
    print(f"Minimum Zig line: {readiness.get('minimum_zig')}")
    installed_zig = readiness.get("installed_zig") or "not probed or unavailable"
    print(f"Installed zig: {installed_zig}")
    matching_candidates = readiness.get("matching_zig_candidates") or []
    if matching_candidates:
        print("Matching staged Zig candidates:")
        for candidate in matching_candidates:
            print(f"  - {candidate}")
    else:
        print("Matching staged Zig candidates: none")

    preferred_archive = saved_zig.get("preferred_archive")
    if isinstance(preferred_archive, dict) and preferred_archive:
        print("Preferred saved Zig archive:")
        print(f"  - {preferred_archive.get('path')} [{preferred_archive.get('version')}]")
        commands = saved_zig.get("commands") or {}
        print("Saved Zig restore commands:")
        print(f"  - check: {commands.get('restore_check')}")
        print(f"  - run:   {commands.get('restore')}")
    else:
        print("Preferred saved Zig archive: none")

    combined_next_step = report.get("combined_next_step")
    if combined_next_step:
        print()
        print(f"Combined next step: {combined_next_step}")

    if report["status"] == "passed":
        print()
        print("Bridge check passed.")
        return

    print()
    print("Bridge check failed.", file=sys.stderr)
    readiness_failures = readiness.get("failures") or []
    saved_zig_failures = saved_zig.get("failures") or []
    if readiness_failures:
        print("Readiness failures:", file=sys.stderr)
        for failure in readiness_failures:
            print(f"  - {failure}", file=sys.stderr)
    if saved_zig_failures:
        print("Saved Zig failures:", file=sys.stderr)
        for failure in saved_zig_failures:
            print(f"  - {failure}", file=sys.stderr)
    if combined_next_step:
        print(f"Suggested next step: {combined_next_step}", file=sys.stderr)


class LinuxBuildReadinessReentryTests(unittest.TestCase):
    def test_choose_combined_next_step_prefers_matching_candidate(self) -> None:
        next_step = choose_combined_next_step(
            {"matching_zig_candidates": ["/tmp/toolchains/zig-0.15.2/zig"]},
            {"commands": {"restore_check": "check", "restore": "run"}},
        )
        self.assertIn("--zig /tmp/toolchains/zig-0.15.2/zig", next_step)

    def test_choose_combined_next_step_falls_back_to_saved_zig_restore_commands(self) -> None:
        next_step = choose_combined_next_step(
            {"matching_zig_candidates": [], "suggested_next_step": "generic"},
            {"commands": {"restore_check": "check-cmd", "restore": "run-cmd"}},
        )
        self.assertEqual(
            next_step,
            "run check-cmd, then run-cmd, and rerun the Linux build-readiness helper",
        )

    def test_choose_combined_next_step_uses_readiness_fallback_when_no_archive_commands_exist(self) -> None:
        next_step = choose_combined_next_step(
            {"matching_zig_candidates": [], "suggested_next_step": "generic"},
            {"commands": {}},
        )
        self.assertEqual(next_step, "generic")

    def test_run_json_command_accepts_nonzero_exit_with_json_payload(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            script_path = pathlib.Path(tmpdir) / "payload.py"
            script_path.write_text(
                textwrap.dedent(
                    """\
                    #!/usr/bin/env python3
                    import json
                    import sys
                    print(json.dumps({"status": "failed", "failures": ["x"]}))
                    sys.exit(1)
                    """
                ),
                encoding="utf-8",
            )
            exit_code, payload = run_json_command([sys.executable, str(script_path)])
            self.assertEqual(exit_code, 1)
            self.assertEqual(payload["status"], "failed")

    def test_build_combined_report_tracks_both_reports(self) -> None:
        report = build_combined_report(
            1,
            {"status": "failed", "matching_zig_candidates": [], "suggested_next_step": "generic"},
            0,
            {"status": "passed", "commands": {"restore_check": "check", "restore": "run"}},
        )
        self.assertEqual(report["status"], "failed")
        self.assertEqual(
            report["combined_next_step"],
            "run check, then run, and rerun the Linux build-readiness helper",
        )


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            LinuxBuildReadinessReentryTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    saved_archives_root = (
        pathlib.Path(args.saved_archives_root).resolve()
        if args.saved_archives_root
        else None
    )
    toolchains_root = (
        pathlib.Path(args.toolchains_root).resolve()
        if args.toolchains_root
        else None
    )
    fallback_zig_archive = (
        pathlib.Path(args.fallback_zig_archive).resolve()
        if args.fallback_zig_archive
        else None
    )
    offline_deps_root = (
        pathlib.Path(args.offline_deps_root).resolve()
        if args.offline_deps_root
        else None
    )

    readiness_command = build_command(
        build_script_path(repo_root, "scripts/check_linux_build_readiness.py"),
        repo_root,
        saved_archives_root=saved_archives_root,
        toolchains_root=toolchains_root,
        fallback_zig_archive=fallback_zig_archive,
        skip_rust_check=args.skip_rust_check,
        expect_offline_deps=args.expect_offline_deps,
        offline_deps_root=offline_deps_root,
        require_prebuilt_v8=args.require_prebuilt_v8,
        expect_saved_archives=args.expect_saved_archives,
        kind="readiness",
    )
    saved_zig_command = build_command(
        build_script_path(repo_root, "scripts/check_issue3_saved_zig_archive_candidates.py"),
        repo_root,
        saved_archives_root=saved_archives_root,
        toolchains_root=toolchains_root,
        fallback_zig_archive=fallback_zig_archive,
        skip_rust_check=False,
        expect_offline_deps=False,
        offline_deps_root=None,
        require_prebuilt_v8=False,
        expect_saved_archives=False,
        kind="saved-zig",
    )

    readiness_exit_code, readiness_report = run_json_command(readiness_command)
    saved_zig_exit_code, saved_zig_report = run_json_command(saved_zig_command)
    report = build_combined_report(
        readiness_exit_code,
        readiness_report,
        saved_zig_exit_code,
        saved_zig_report,
    )

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())