#!/usr/bin/env python3

"""Fail fast when the issue #11 toolchains-root audit surface drifts.

This helper is intentionally small and create-only. It gives Linux/WSL re-entry
runs one branch-local preflight for the existing toolchains-root audit helpers
before they trust broader saved-Memory, Rust, Zig, or build-readiness routes.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tempfile
import unittest


FILES = {
    "preference_audit": "scripts/check_issue11_toolchains_root_preference.py",
    "consistency_audit": "scripts/check_issue11_toolchains_root_consistency.py",
    "candidate_helper": "scripts/check_issue11_toolchains_root_candidates.py",
    "route_printer": "scripts/linux/show_issue11_toolchains_root_audit_route.sh",
}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check that the issue #11 toolchains-root audit helpers are present "
            "before Linux/WSL re-entry follows the wider helper chain."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of line-oriented text",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused unit tests and exit",
    )
    return parser


def collect_report(repo_root: Path) -> dict[str, object]:
    checks: list[dict[str, object]] = []
    failures: list[str] = []

    for label, relative_path in FILES.items():
        target = repo_root / relative_path
        exists = target.is_file()
        checks.append(
            {
                "label": label,
                "path": relative_path,
                "exists": exists,
            }
        )
        if not exists:
            failures.append(f"missing required issue #11 toolchains-root audit file: {relative_path}")

    commands = {
        "route": [
            "bash",
            "scripts/linux/show_issue11_toolchains_root_audit_route.sh",
            "--repo-root",
            str(repo_root),
        ],
        "preference_audit": [
            "python",
            "scripts/check_issue11_toolchains_root_preference.py",
            "--repo-root",
            str(repo_root),
        ],
        "consistency_audit": [
            "python",
            "scripts/check_issue11_toolchains_root_consistency.py",
            "--repo-root",
            str(repo_root),
        ],
        "candidate_helper": [
            "python",
            "scripts/check_issue11_toolchains_root_candidates.py",
            "--repo-root",
            str(repo_root),
        ],
    }

    return {
        "status": "passed" if not failures else "failed",
        "repo_root": str(repo_root),
        "checks": checks,
        "commands": commands,
        "failures": failures,
    }


def emit_text(report: dict[str, object]) -> None:
    print(f"Repo root: {report['repo_root']}")
    print(f"Status: {report['status']}")
    print("Checks:")
    for check in report["checks"]:
        state = "PASS" if check["exists"] else "FAIL"
        print(f"  - [{state}] {check['path']}")
    print("Commands:")
    for label, command in report["commands"].items():
        print(f"  - {label}: {' '.join(command)}")
    if report["failures"]:
        print("Failures:", file=sys.stderr)
        for failure in report["failures"]:
            print(f"  - {failure}", file=sys.stderr)


class AuditSurfaceTests(unittest.TestCase):
    def populate_repo(self, repo_root: Path) -> None:
        for relative_path in FILES.values():
            target = repo_root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("# placeholder\n", encoding="utf-8")

    def test_passes_when_all_required_files_exist(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self.populate_repo(repo_root)
            report = collect_report(repo_root)
            self.assertEqual(report["status"], "passed")
            self.assertEqual(report["failures"], [])

    def test_fails_when_any_required_file_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self.populate_repo(repo_root)
            (repo_root / FILES["route_printer"]).unlink()
            report = collect_report(repo_root)
            self.assertEqual(report["status"], "failed")
            self.assertEqual(len(report["failures"]), 1)
            self.assertIn(FILES["route_printer"], report["failures"][0])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(AuditSurfaceTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    report = collect_report(repo_root)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())