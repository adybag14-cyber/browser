#!/usr/bin/env python3

"""Run the issue #11 Linux/WSL headed-mode re-entry preflight as one command."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


def resolve_default_saved_archives_root(repo_root: Path) -> Path:
    return (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()


def resolve_default_toolchains_root(repo_root: Path) -> Path:
    return (repo_root.parent / "toolchains").resolve()


def resolve_default_offline_deps_root(repo_root: Path) -> Path:
    return (repo_root.parent / "offline-deps").resolve()


def helper_path(repo_root: Path, relative_path: str) -> Path:
    return (repo_root / relative_path).resolve()


def build_subchecks(
    repo_root: Path,
    *,
    saved_archives_root: Path,
    toolchains_root: Path,
    offline_deps_root: Path,
    expect_offline_deps: bool,
    require_prebuilt_v8: bool,
) -> list[dict[str, object]]:
    python = sys.executable
    checks: list[dict[str, object]] = [
        {
            "key": "saved_memory_inputs",
            "label": "Saved Memory inputs",
            "command": [
                python,
                str(helper_path(repo_root, "scripts/check_issue3_saved_memory_inputs.py")),
                "--repo-root",
                str(repo_root),
                "--json",
            ],
        },
        {
            "key": "saved_archive_integrity",
            "label": "Saved archive integrity",
            "command": [
                python,
                str(helper_path(repo_root, "scripts/check_issue3_saved_archive_integrity.py")),
                "--repo-root",
                str(repo_root),
                "--json",
            ],
        },
        {
            "key": "saved_rust_archives",
            "label": "Saved Rust archives",
            "command": [
                python,
                str(helper_path(repo_root, "scripts/check_issue3_saved_rust_archive_candidates.py")),
                "--repo-root",
                str(repo_root),
                "--saved-archives-root",
                str(saved_archives_root),
                "--toolchains-root",
                str(toolchains_root),
                "--json",
            ],
        },
        {
            "key": "staged_rust_toolchains",
            "label": "Staged Rust toolchains",
            "command": [
                python,
                str(helper_path(repo_root, "scripts/check_issue3_staged_rust_toolchain_candidates.py")),
                "--repo-root",
                str(repo_root),
                "--toolchains-root",
                str(toolchains_root),
                "--json",
            ],
        },
        {
            "key": "saved_zig_archives",
            "label": "Saved Zig archives",
            "command": [
                python,
                str(helper_path(repo_root, "scripts/check_issue3_saved_zig_archive_candidates.py")),
                "--repo-root",
                str(repo_root),
                "--saved-archives-root",
                str(saved_archives_root),
                "--toolchains-root",
                str(toolchains_root),
                "--json",
            ],
        },
    ]

    readiness_command = [
        python,
        str(helper_path(repo_root, "scripts/check_linux_build_readiness.py")),
        "--repo-root",
        str(repo_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--toolchains-root",
        str(toolchains_root),
        "--expect-saved-archives",
        "--json",
    ]
    if expect_offline_deps:
        readiness_command.extend(["--expect-offline-deps", "--offline-deps-root", str(offline_deps_root)])
    if require_prebuilt_v8:
        readiness_command.append("--require-prebuilt-v8")

    checks.append(
        {
            "key": "build_readiness",
            "label": "Linux build readiness",
            "command": readiness_command,
        }
    )
    return checks


def run_subcheck(check: dict[str, object]) -> dict[str, object]:
    command = [str(part) for part in check["command"]]
    completed = subprocess.run(command, capture_output=True, text=True, check=False)
    stdout = completed.stdout.strip()
    stderr = completed.stderr.strip()
    parsed_json = None
    parse_error = None
    if stdout:
        try:
            parsed_json = json.loads(stdout)
        except json.JSONDecodeError as exc:
            parse_error = str(exc)

    status = "passed" if completed.returncode == 0 else "failed"
    suggested_next_step = None
    if isinstance(parsed_json, dict):
        suggested_next_step = parsed_json.get("suggested_next_step")
        nested_status = parsed_json.get("status")
        if isinstance(nested_status, str) and completed.returncode == 0:
            status = nested_status

    return {
        "key": check["key"],
        "label": check["label"],
        "command": command,
        "returncode": completed.returncode,
        "status": status,
        "stdout": stdout,
        "stderr": stderr,
        "json": parsed_json,
        "parse_error": parse_error,
        "suggested_next_step": suggested_next_step,
    }


def collect_results(
    repo_root: Path,
    *,
    saved_archives_root: Path,
    toolchains_root: Path,
    offline_deps_root: Path,
    expect_offline_deps: bool,
    require_prebuilt_v8: bool,
) -> dict[str, object]:
    checks = build_subchecks(
        repo_root,
        saved_archives_root=saved_archives_root,
        toolchains_root=toolchains_root,
        offline_deps_root=offline_deps_root,
        expect_offline_deps=expect_offline_deps,
        require_prebuilt_v8=require_prebuilt_v8,
    )
    results = [run_subcheck(check) for check in checks]

    failures = [result for result in results if result["returncode"] != 0]
    suggested_next_step = None
    for result in failures:
        if result["suggested_next_step"]:
            suggested_next_step = result["suggested_next_step"]
            break
    if suggested_next_step is None and failures:
        suggested_next_step = f"fix the first failing gate: {failures[0]['label']}"

    return {
        "status": "passed" if not failures else "failed",
        "repo_root": str(repo_root),
        "saved_archives_root": str(saved_archives_root),
        "toolchains_root": str(toolchains_root),
        "offline_deps_root": str(offline_deps_root),
        "expect_offline_deps": expect_offline_deps,
        "require_prebuilt_v8": require_prebuilt_v8,
        "checks": results,
        "suggested_next_step": suggested_next_step,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run the issue #11 Linux/WSL headed-mode re-entry preflight as one command."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help="Path to repo_archives/browser or repo_archives/browser/dependencies",
    )
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Path to the shared toolchains directory (default: ../toolchains)",
    )
    parser.add_argument(
        "--offline-deps-root",
        default=None,
        help="Path to the shared offline-deps directory (default: ../offline-deps)",
    )
    parser.add_argument(
        "--expect-offline-deps",
        action="store_true",
        help="Also require offline dependency staging in the final build-readiness pass",
    )
    parser.add_argument(
        "--require-prebuilt-v8",
        action="store_true",
        help="Require a prebuilt libc_v8 archive in the final build-readiness pass",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON output")
    parser.add_argument("--self-test", action="store_true", help="Run focused tests and exit")
    return parser


class ReentryPreflightTests(unittest.TestCase):
    def write_helper(self, repo_root: Path, relative_path: str, payload: dict[str, object], exit_code: int) -> None:
        target = repo_root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(
            "#!/usr/bin/env python3\n"
            "import json, sys\n"
            f"print(json.dumps({payload!r}))\n"
            f"raise SystemExit({exit_code})\n",
            encoding="utf-8",
        )

    def test_collect_results_passes_when_all_subchecks_pass(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            for relative_path in (
                "scripts/check_issue3_saved_memory_inputs.py",
                "scripts/check_issue3_saved_archive_integrity.py",
                "scripts/check_issue3_saved_rust_archive_candidates.py",
                "scripts/check_issue3_staged_rust_toolchain_candidates.py",
                "scripts/check_issue3_saved_zig_archive_candidates.py",
                "scripts/check_linux_build_readiness.py",
            ):
                self.write_helper(repo_root, relative_path, {"status": "passed"}, 0)

            result = collect_results(
                repo_root,
                saved_archives_root=resolve_default_saved_archives_root(repo_root),
                toolchains_root=resolve_default_toolchains_root(repo_root),
                offline_deps_root=resolve_default_offline_deps_root(repo_root),
                expect_offline_deps=False,
                require_prebuilt_v8=False,
            )

            self.assertEqual(result["status"], "passed")
            self.assertEqual(len(result["checks"]), 6)

    def test_collect_results_reports_first_nested_next_step(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            self.write_helper(repo_root, "scripts/check_issue3_saved_memory_inputs.py", {"status": "passed"}, 0)
            self.write_helper(repo_root, "scripts/check_issue3_saved_archive_integrity.py", {"status": "passed"}, 0)
            self.write_helper(
                repo_root,
                "scripts/check_issue3_saved_rust_archive_candidates.py",
                {"status": "failed", "suggested_next_step": "restore the saved Rust 1.79.0 archive"},
                1,
            )
            self.write_helper(repo_root, "scripts/check_issue3_staged_rust_toolchain_candidates.py", {"status": "failed"}, 1)
            self.write_helper(repo_root, "scripts/check_issue3_saved_zig_archive_candidates.py", {"status": "failed"}, 1)
            self.write_helper(repo_root, "scripts/check_linux_build_readiness.py", {"status": "failed"}, 1)

            result = collect_results(
                repo_root,
                saved_archives_root=resolve_default_saved_archives_root(repo_root),
                toolchains_root=resolve_default_toolchains_root(repo_root),
                offline_deps_root=resolve_default_offline_deps_root(repo_root),
                expect_offline_deps=True,
                require_prebuilt_v8=True,
            )

            self.assertEqual(result["status"], "failed")
            self.assertEqual(result["suggested_next_step"], "restore the saved Rust 1.79.0 archive")


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ReentryPreflightTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    saved_archives_root = (
        Path(args.saved_archives_root).resolve()
        if args.saved_archives_root
        else resolve_default_saved_archives_root(repo_root)
    )
    toolchains_root = (
        Path(args.toolchains_root).resolve()
        if args.toolchains_root
        else resolve_default_toolchains_root(repo_root)
    )
    offline_deps_root = (
        Path(args.offline_deps_root).resolve()
        if args.offline_deps_root
        else resolve_default_offline_deps_root(repo_root)
    )

    results = collect_results(
        repo_root,
        saved_archives_root=saved_archives_root,
        toolchains_root=toolchains_root,
        offline_deps_root=offline_deps_root,
        expect_offline_deps=args.expect_offline_deps,
        require_prebuilt_v8=args.require_prebuilt_v8,
    )

    if args.json:
        print(json.dumps(results, indent=2))
        return 0 if results["status"] == "passed" else 1

    print("Issue #11 Linux/WSL re-entry preflight")
    print()
    print(f"Repo root:           {results['repo_root']}")
    print(f"Saved archives root: {results['saved_archives_root']}")
    print(f"Toolchains root:     {results['toolchains_root']}")
    print(f"Offline deps root:   {results['offline_deps_root']}")
    print()
    for check in results["checks"]:
        marker = "PASS" if check["returncode"] == 0 else "FAIL"
        print(f"[{marker}] {check['label']}")
        if check["suggested_next_step"]:
            print(f"  next: {check['suggested_next_step']}")
        if check["parse_error"]:
            print(f"  parse error: {check['parse_error']}")

    if results["status"] == "passed":
        print("\nLinux/WSL re-entry preflight passed.")
        return 0

    print("\nLinux/WSL re-entry preflight failed.", file=sys.stderr)
    if results["suggested_next_step"]:
        print(f"Suggested next step: {results['suggested_next_step']}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())