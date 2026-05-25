#!/usr/bin/env python3

"""Aggregate issue #11 Linux/WSL re-entry surface checks.

This helper gives scheduled runs a single preflight command that answers:
- do the saved-snapshot, restored-checkout, saved-input, archive-integrity,
  saved-Rust, saved-Zig, Zig-recovery, and Linux build-readiness surfaces exist
- do those surface checks still pass from this repo root

It is intentionally lightweight and does not stage archives or mutate the tree.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import textwrap
import unittest


SURFACE_CHECKS: tuple[tuple[str, str], ...] = (
    ("saved-browser-snapshot", "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"),
    ("restored-checkout-reentry", "scripts/linux/check_issue3_restored_checkout_reentry_route_surface.sh"),
    ("saved-memory-inputs", "scripts/linux/check_issue3_saved_memory_inputs_route_surface.sh"),
    ("progress-tracker", "scripts/linux/check_issue3_progress_tracker_route_surface.sh"),
    ("saved-archive-integrity", "scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh"),
    ("saved-rust-toolchain", "scripts/linux/check_issue3_saved_rust_toolchain_route_surface.sh"),
    ("saved-zig-archive-candidates", "scripts/linux/check_issue3_saved_zig_archive_candidates_route_surface.sh"),
    ("zig-toolchain-recovery", "scripts/linux/check_issue3_zig_toolchain_recovery_route_surface.sh"),
    ("zig-toolchain-archive-restore", "scripts/linux/check_issue3_zig_toolchain_archive_restore_route_surface.sh"),
    ("linux-build-readiness", "scripts/linux/check_issue3_linux_build_readiness_route_surface.sh"),
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run the issue #11 Linux/WSL route surface checks as one bundled preflight."
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser repo root (default: current directory)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of the line-oriented summary",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused unit tests and exit",
    )
    return parser


def run_surface_check(repo_root: Path, label: str, relative_path: str) -> dict[str, object]:
    script_path = (repo_root / relative_path).resolve()
    result: dict[str, object] = {
        "label": label,
        "path": str(script_path),
        "exists": script_path.is_file(),
        "exit_code": None,
        "ok": False,
        "surface_summary": None,
        "stdout": "",
        "stderr": "",
    }
    if not script_path.is_file():
        result["stderr"] = f"missing surface script: {script_path}"
        return result

    completed = subprocess.run(
        ["bash", str(script_path), "--repo-root", str(repo_root), "--json"],
        capture_output=True,
        text=True,
    )
    result["exit_code"] = completed.returncode
    result["stdout"] = completed.stdout.strip()
    result["stderr"] = completed.stderr.strip()
    result["ok"] = completed.returncode == 0

    if completed.stdout.strip():
        try:
            payload = json.loads(completed.stdout)
        except json.JSONDecodeError:
            result["surface_summary"] = {"parse_error": "stdout was not valid JSON"}
        else:
            summary: dict[str, object] = {}
            for key in ("profile", "status", "missing_count", "reference_count", "content_check_count"):
                if key in payload:
                    summary[key] = payload[key]
            result["surface_summary"] = summary or payload

    return result


def collect_results(repo_root: Path) -> dict[str, object]:
    checks = [run_surface_check(repo_root, label, relative_path) for label, relative_path in SURFACE_CHECKS]
    failures = [
        check["label"]
        for check in checks
        if not bool(check["ok"])
    ]
    return {
        "status": "passed" if not failures else "failed",
        "repo_root": str(repo_root),
        "check_count": len(checks),
        "failed_checks": failures,
        "checks": checks,
        "suggested_follow_up": (
            [
                "python scripts/check_issue3_workspace_context.py --repo-root .",
                "bash scripts/linux/show_issue3_progress_tracker_route.sh --repo-root .",
                "bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root .",
            ]
            if failures
            else [
                "bash scripts/linux/show_issue3_progress_tracker_route.sh --repo-root .",
                "bash scripts/linux/show_issue3_linux_build_readiness_route.sh --repo-root .",
            ]
        ),
    }


def emit_text(report: dict[str, object]) -> None:
    print(f"Repo root: {report['repo_root']}")
    print(f"Surface checks: {report['check_count']}")
    print(f"Status: {report['status']}")
    print("Checks:")
    for check in report["checks"]:
        state = "ok" if check["ok"] else "failed"
        exit_code = check["exit_code"]
        print(f"  - {check['label']}: {state} [{exit_code if exit_code is not None else 'missing'}]")
        summary = check["surface_summary"]
        if isinstance(summary, dict) and summary:
            if "missing_count" in summary:
                print(f"    summary: missing_count={summary['missing_count']}")
            elif "status" in summary:
                print(f"    summary: status={summary['status']}")
    if report["failed_checks"]:
        print("\nFailed checks:", file=sys.stderr)
        for label in report["failed_checks"]:
            print(f"  - {label}", file=sys.stderr)
    print("\nSuggested follow-up:")
    for command in report["suggested_follow_up"]:
        print(f"  {command}")


class ReentryRouteSurfaceBundleTests(unittest.TestCase):
    def write_surface_script(
        self,
        repo_root: Path,
        relative_path: str,
        *,
        json_body: str,
        exit_code: int = 0,
    ) -> None:
        script_path = repo_root / relative_path
        script_path.parent.mkdir(parents=True, exist_ok=True)
        script_path.write_text(
            textwrap.dedent(
                f"""\
                #!/usr/bin/env bash
                set -euo pipefail
                cat <<'JSON'
                {json_body}
                JSON
                exit {exit_code}
                """
            ),
            encoding="utf-8",
        )
        script_path.chmod(0o755)

    def test_collect_results_passes_when_all_surface_scripts_pass(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            for label, relative_path in SURFACE_CHECKS:
                self.write_surface_script(
                    repo_root,
                    relative_path,
                    json_body=json.dumps(
                        {"profile": label, "status": "passed", "missing_count": 0}
                    ),
                )

            report = collect_results(repo_root)

            self.assertEqual(report["status"], "passed")
            self.assertEqual(report["failed_checks"], [])
            self.assertEqual(report["check_count"], len(SURFACE_CHECKS))

    def test_collect_results_reports_missing_scripts_as_failures(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            label, relative_path = SURFACE_CHECKS[0]
            self.write_surface_script(
                repo_root,
                relative_path,
                json_body=json.dumps({"profile": label, "status": "passed", "missing_count": 0}),
            )

            report = collect_results(repo_root)

            self.assertEqual(report["status"], "failed")
            self.assertIn(SURFACE_CHECKS[1][0], report["failed_checks"])

    def test_collect_results_reports_nonzero_surface_exit(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            for index, (label, relative_path) in enumerate(SURFACE_CHECKS):
                self.write_surface_script(
                    repo_root,
                    relative_path,
                    json_body=json.dumps(
                        {
                            "profile": label,
                            "status": "failed" if index == 3 else "passed",
                            "missing_count": 2 if index == 3 else 0,
                        }
                    ),
                    exit_code=1 if index == 3 else 0,
                )

            report = collect_results(repo_root)

            self.assertEqual(report["status"], "failed")
            self.assertEqual(report["failed_checks"], [SURFACE_CHECKS[3][0]])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ReentryRouteSurfaceBundleTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    report = collect_results(repo_root)
    if args.json:
        print(json.dumps(report, indent=2))
        return 0 if report["status"] == "passed" else 1

    emit_text(report)
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())
