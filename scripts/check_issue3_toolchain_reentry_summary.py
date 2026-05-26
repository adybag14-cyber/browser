#!/usr/bin/env python3

"""Summarize Rust and Zig re-entry toolchain candidates for issue #11."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


HELPERS = {
    "saved_rust": "scripts/check_issue3_saved_rust_archive_candidates.py",
    "staged_rust": "scripts/check_issue3_staged_rust_toolchain_candidates.py",
    "saved_zig": "scripts/check_issue3_saved_zig_archive_candidates.py",
    "staged_zig": "scripts/check_issue3_staged_zig_toolchain_candidates.py",
}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Summarize the saved and staged Rust/Zig candidates that matter for "
            "the issue #11 Linux/WSL headed-mode re-entry lane."
        )
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help="Optional override for repo_archives/browser or its dependencies subdirectory",
    )
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Optional override for the shared toolchains directory",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional override for the surfaced fallback Zig archive",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of text")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


def build_helper_command(
    repo_root: Path,
    helper_relative_path: str,
    *,
    saved_archives_root: Path | None,
    toolchains_root: Path | None,
    fallback_zig_archive: Path | None,
) -> list[str]:
    helper_path = repo_root / helper_relative_path
    command = [sys.executable, str(helper_path), "--repo-root", str(repo_root), "--json"]
    if saved_archives_root is not None and "saved_" in helper_relative_path:
        command.extend(["--saved-archives-root", str(saved_archives_root)])
    if toolchains_root is not None and ("toolchain" in helper_relative_path or "staged_" in helper_relative_path):
        command.extend(["--toolchains-root", str(toolchains_root)])
    if fallback_zig_archive is not None and "saved_zig" in helper_relative_path:
        command.extend(["--fallback-zig-archive", str(fallback_zig_archive)])
    return command


def run_helper(command: list[str], label: str) -> tuple[dict[str, object], list[str]]:
    failures: list[str] = []
    try:
        completed = subprocess.run(
            command,
            capture_output=True,
            check=False,
            text=True,
        )
    except OSError as exc:
        failures.append(f"{label} helper could not start: {exc}")
        return {"status": "failed", "failures": failures}, failures

    stdout = completed.stdout.strip()
    if not stdout:
        failures.append(f"{label} helper returned no JSON output")
        return {"status": "failed", "failures": failures}, failures

    try:
        payload = json.loads(stdout)
    except json.JSONDecodeError as exc:
        failures.append(f"{label} helper returned invalid JSON: {exc}")
        return {"status": "failed", "stdout": stdout, "stderr": completed.stderr.strip(), "failures": failures}, failures

    if completed.returncode != 0 and not payload.get("failures"):
        failures.append(f"{label} helper exited with status {completed.returncode}")
        payload["failures"] = failures

    return payload, failures


def summarize_results(results: dict[str, dict[str, object]]) -> dict[str, object]:
    saved_rust = results["saved_rust"]
    staged_rust = results["staged_rust"]
    saved_zig = results["saved_zig"]
    staged_zig = results["staged_zig"]

    summary = {
        "rust_saved_ready": saved_rust.get("preferred_archive") is not None,
        "rust_staged_ready": staged_rust.get("preferred_candidate") is not None,
        "zig_saved_ready": saved_zig.get("preferred_archive") is not None,
        "zig_staged_ready": staged_zig.get("preferred_candidate") is not None,
        "fallback_zig_only": False,
        "next_steps": [],
    }

    if (
        not summary["zig_saved_ready"]
        and not summary["zig_staged_ready"]
        and saved_zig.get("fallback_archive")
    ):
        summary["fallback_zig_only"] = True

    next_steps: list[str] = []
    if not summary["rust_staged_ready"]:
        restore_check = (
            saved_rust.get("commands", {}).get("restore_check")
            if isinstance(saved_rust.get("commands"), dict)
            else None
        )
        if restore_check:
            next_steps.append(f"Run the saved Rust restore check: {restore_check}")
    if not summary["zig_staged_ready"]:
        restore_check = (
            saved_zig.get("commands", {}).get("restore_check")
            if isinstance(saved_zig.get("commands"), dict)
            else None
        )
        fallback_check = (
            saved_zig.get("commands", {}).get("fallback_restore_check")
            if isinstance(saved_zig.get("commands"), dict)
            else None
        )
        if restore_check:
            next_steps.append(f"Run the saved Zig restore check: {restore_check}")
        elif fallback_check:
            next_steps.append(
                "Only the fallback Zig archive is surfaced; use it only as a stopgap: "
                f"{fallback_check}"
            )

    summary["next_steps"] = next_steps
    summary["status"] = (
        "passed"
        if summary["rust_staged_ready"] and summary["zig_staged_ready"]
        else "needs-attention"
    )
    return summary


def collect_results(
    repo_root: Path,
    *,
    saved_archives_root: Path | None,
    toolchains_root: Path | None,
    fallback_zig_archive: Path | None,
) -> dict[str, object]:
    helper_results: dict[str, dict[str, object]] = {}
    helper_failures: list[str] = []

    for key, relative_path in HELPERS.items():
        command = build_helper_command(
            repo_root,
            relative_path,
            saved_archives_root=saved_archives_root,
            toolchains_root=toolchains_root,
            fallback_zig_archive=fallback_zig_archive,
        )
        payload, failures = run_helper(command, key.replace("_", " "))
        helper_results[key] = payload
        helper_failures.extend(failures)

    summary = summarize_results(helper_results)
    failures = helper_failures[:]
    for key, payload in helper_results.items():
        payload_failures = payload.get("failures")
        if isinstance(payload_failures, list):
            failures.extend(f"{key}: {failure}" for failure in payload_failures)

    return {
        "status": "failed" if failures else summary["status"],
        "repo_root": str(repo_root),
        "saved_archives_root": str(saved_archives_root) if saved_archives_root is not None else "",
        "toolchains_root": str(toolchains_root) if toolchains_root is not None else "",
        "fallback_zig_archive": str(fallback_zig_archive) if fallback_zig_archive is not None else "",
        "summary": summary,
        "helpers": helper_results,
        "failures": failures,
    }


def emit_text(report: dict[str, object]) -> None:
    summary = report["summary"]
    assert isinstance(summary, dict)
    print("Issue #11 toolchain re-entry summary")
    print()
    print(f"Repo root: {report['repo_root']}")
    if report["saved_archives_root"]:
        print(f"Saved archives root override: {report['saved_archives_root']}")
    if report["toolchains_root"]:
        print(f"Toolchains root override:    {report['toolchains_root']}")
    if report["fallback_zig_archive"]:
        print(f"Fallback Zig override:      {report['fallback_zig_archive']}")
    print()
    print(f"Saved Rust archive ready:   {summary['rust_saved_ready']}")
    print(f"Staged Rust ready:          {summary['rust_staged_ready']}")
    print(f"Saved Zig archive ready:    {summary['zig_saved_ready']}")
    print(f"Staged Zig ready:           {summary['zig_staged_ready']}")
    print(f"Fallback Zig only:          {summary['fallback_zig_only']}")
    print()
    next_steps = summary.get("next_steps", [])
    if next_steps:
        print("Suggested next steps:")
        for step in next_steps:
            print(f"  - {step}")
    else:
        print("Suggested next steps: none")

    failures = report.get("failures", [])
    if failures:
        print()
        print("Helper failures:")
        for failure in failures:
            print(f"  - {failure}")


class ToolchainSummaryTests(unittest.TestCase):
    def make_helper(self, root: Path, relative_path: str, payload: dict[str, object], exit_code: int = 0) -> None:
        helper_path = root / relative_path
        helper_path.parent.mkdir(parents=True, exist_ok=True)
        payload_text = json.dumps(payload)
        helper_path.write_text(
            "#!/usr/bin/env python3\n"
            "import sys\n"
            f"print({payload_text!r})\n"
            f"raise SystemExit({exit_code})\n",
            encoding="utf-8",
        )

    def test_summary_marks_pass_when_staged_rust_and_zig_are_ready(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            passing_payload = {"status": "passed", "preferred_candidate": {"path": "/tmp/tool"}, "failures": []}
            self.make_helper(repo_root, HELPERS["staged_rust"], passing_payload)
            self.make_helper(repo_root, HELPERS["staged_zig"], passing_payload)
            self.make_helper(repo_root, HELPERS["saved_rust"], {"status": "passed", "preferred_archive": {"path": "/tmp/a"}, "commands": {}, "failures": []})
            self.make_helper(repo_root, HELPERS["saved_zig"], {"status": "passed", "preferred_archive": {"path": "/tmp/b"}, "commands": {}, "failures": []})

            report = collect_results(repo_root, saved_archives_root=None, toolchains_root=None, fallback_zig_archive=None)

            self.assertEqual(report["status"], "passed")
            self.assertEqual(report["summary"]["status"], "passed")

    def test_summary_surfaces_restore_commands_when_staged_candidates_are_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self.make_helper(repo_root, HELPERS["staged_rust"], {"status": "failed", "preferred_candidate": None, "failures": []})
            self.make_helper(repo_root, HELPERS["staged_zig"], {"status": "failed", "preferred_candidate": None, "failures": []})
            self.make_helper(
                repo_root,
                HELPERS["saved_rust"],
                {"status": "passed", "preferred_archive": {"path": "/tmp/rust.tar.xz"}, "commands": {"restore_check": "rust-check"}, "failures": []},
            )
            self.make_helper(
                repo_root,
                HELPERS["saved_zig"],
                {"status": "failed", "preferred_archive": None, "fallback_archive": "/tmp/fallback.tar.xz", "commands": {"fallback_restore_check": "zig-fallback"}, "failures": []},
            )

            report = collect_results(repo_root, saved_archives_root=None, toolchains_root=None, fallback_zig_archive=None)

            self.assertEqual(report["summary"]["status"], "needs-attention")
            next_steps = report["summary"]["next_steps"]
            self.assertIn("rust-check", next_steps[0])
            self.assertIn("zig-fallback", next_steps[1])
            self.assertTrue(report["summary"]["fallback_zig_only"])

    def test_collect_results_records_helper_failures(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir)
            self.make_helper(repo_root, HELPERS["saved_rust"], {"status": "failed", "failures": ["bad rust"]}, exit_code=1)
            self.make_helper(repo_root, HELPERS["staged_rust"], {"status": "failed", "preferred_candidate": None, "failures": []})
            self.make_helper(repo_root, HELPERS["saved_zig"], {"status": "failed", "preferred_archive": None, "commands": {}, "failures": []})
            self.make_helper(repo_root, HELPERS["staged_zig"], {"status": "failed", "preferred_candidate": None, "failures": []})

            report = collect_results(repo_root, saved_archives_root=None, toolchains_root=None, fallback_zig_archive=None)

            self.assertEqual(report["status"], "failed")
            self.assertTrue(report["failures"])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ToolchainSummaryTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    saved_archives_root = Path(args.saved_archives_root).resolve() if args.saved_archives_root else None
    toolchains_root = Path(args.toolchains_root).resolve() if args.toolchains_root else None
    fallback_zig_archive = Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None

    report = collect_results(
        repo_root,
        saved_archives_root=saved_archives_root,
        toolchains_root=toolchains_root,
        fallback_zig_archive=fallback_zig_archive,
    )
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 1 if report["status"] == "failed" else 0


if __name__ == "__main__":
    raise SystemExit(main())
