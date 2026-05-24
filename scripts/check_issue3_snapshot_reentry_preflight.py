#!/usr/bin/env python3

"""Run the saved-snapshot restored-checkout and Memory preflights in order."""

from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path
import tempfile
import types
import unittest


RESTORED_CHECK_SCRIPT = "scripts/check_issue3_restored_checkout.py"
SAVED_MEMORY_SCRIPT = "scripts/check_issue3_saved_memory_inputs.py"
REQUIRED_REPO_ROOT_FILE = "build.zig.zon"
DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"
DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Run the restored-checkout readiness gate before the saved-Memory "
            "preflight for the issue #3 saved-snapshot re-entry path."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the live helper checkout root (default: current directory)",
    )
    parser.add_argument(
        "--restored-checkout-root",
        default=None,
        help=(
            "Optional path to the restored checkout to verify "
            "(default: ../browser-memory-snapshot beside the repo root)"
        ),
    )
    parser.add_argument(
        "--helper-root",
        default=None,
        help=(
            "Optional helper checkout to compare the restored helper surface "
            "against (default: repo root)"
        ),
    )
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Optional Memory root override for the saved-memory helper",
    )
    parser.add_argument(
        "--agent-files-root",
        default=None,
        help="Optional builder-attached files root override for the saved-memory helper",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit fallback Zig archive path for the saved-memory helper",
    )
    parser.add_argument(
        "--skip-archive-integrity-check",
        action="store_true",
        help="Forwarded to the saved-memory helper",
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


def resolve_default_restored_checkout_root(repo_root: Path) -> Path:
    if (repo_root / REQUIRED_REPO_ROOT_FILE).is_file():
        return (repo_root.parent / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()
    return (repo_root / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()


def resolve_default_memory_root(repo_root: Path) -> Path:
    return (repo_root.parent / "memory").resolve()


def resolve_default_agent_files_root(repo_root: Path) -> Path:
    return (repo_root.parent / "agent_files").resolve()


def load_python_module(script_path: Path, module_name: str) -> types.ModuleType:
    spec = importlib.util.spec_from_file_location(module_name, script_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"could not load module spec from {script_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def script_presence_result(repo_root: Path) -> dict[str, object]:
    restored_path = repo_root / RESTORED_CHECK_SCRIPT
    saved_memory_path = repo_root / SAVED_MEMORY_SCRIPT
    return {
        "repo_root": str(repo_root),
        "restored_check_script": str(restored_path),
        "saved_memory_script": str(saved_memory_path),
        "restored_check_script_exists": restored_path.is_file(),
        "saved_memory_script_exists": saved_memory_path.is_file(),
        "ok": restored_path.is_file() and saved_memory_path.is_file(),
    }


def collect_results(
    *,
    repo_root: Path,
    restored_checkout_root: Path,
    helper_root: Path,
    memory_root: Path,
    agent_files_root: Path,
    fallback_zig_archive: Path | None,
    skip_archive_integrity_check: bool,
) -> dict[str, object]:
    script_presence = script_presence_result(repo_root)
    if not script_presence["ok"]:
        return {
            "ok": False,
            "diagnosis": "missing-helper-script",
            "script_presence": script_presence,
            "restored_checkout_result": None,
            "saved_memory_result": None,
            "saved_memory_skipped": True,
        }

    restored_module = load_python_module(
        repo_root / RESTORED_CHECK_SCRIPT,
        "issue3_restored_checkout_runtime",
    )
    saved_memory_module = load_python_module(
        repo_root / SAVED_MEMORY_SCRIPT,
        "issue3_saved_memory_runtime",
    )

    restored_checkout_result = restored_module.collect_results(
        repo_root=restored_checkout_root,
        helper_root=helper_root,
        expect_helper_surface=True,
    )
    if not restored_checkout_result["ok"]:
        return {
            "ok": False,
            "diagnosis": "restored-checkout-not-ready",
            "script_presence": script_presence,
            "restored_checkout_result": restored_checkout_result,
            "saved_memory_result": None,
            "saved_memory_skipped": True,
        }

    saved_memory_result = saved_memory_module.collect_results(
        repo_root=restored_checkout_root,
        helper_root=helper_root,
        memory_root=memory_root,
        agent_files_root=agent_files_root,
        restored_checkout_root=restored_checkout_root,
        fallback_zig_archive=fallback_zig_archive,
        check_archive_integrity=not skip_archive_integrity_check,
    )
    if not saved_memory_result["ok"]:
        return {
            "ok": False,
            "diagnosis": "saved-memory-preflight-failed",
            "script_presence": script_presence,
            "restored_checkout_result": restored_checkout_result,
            "saved_memory_result": saved_memory_result,
            "saved_memory_skipped": False,
        }

    return {
        "ok": True,
        "diagnosis": "ready",
        "script_presence": script_presence,
        "restored_checkout_result": restored_checkout_result,
        "saved_memory_result": saved_memory_result,
        "saved_memory_skipped": False,
    }


def emit_text(result: dict[str, object]) -> None:
    script_presence = result["script_presence"]
    print(f"Repo root: {script_presence['repo_root']}")
    restored_script_status = "PASS" if script_presence["restored_check_script_exists"] else "FAIL"
    saved_memory_script_status = "PASS" if script_presence["saved_memory_script_exists"] else "FAIL"
    print(f"Restored-checkout helper: [{restored_script_status}] {script_presence['restored_check_script']}")
    print(f"Saved-memory helper: [{saved_memory_script_status}] {script_presence['saved_memory_script']}")

    if not script_presence["ok"]:
        print("\nIssue #3 snapshot re-entry preflight failed.", file=sys.stderr)
        print(
            "Suggested next step: restore the missing branch-local helper scripts before trusting the saved-snapshot route.",
            file=sys.stderr,
        )
        return

    restored_checkout_result = result["restored_checkout_result"]
    restored_status = "PASS" if restored_checkout_result["ok"] else "FAIL"
    print(
        f"Restored checkout gate: [{restored_status}] "
        f"{restored_checkout_result['repo_root']}"
    )
    if not restored_checkout_result["ok"]:
        print(
            f"         diagnosis: {restored_checkout_result['diagnosis']}"
        )

    if result["saved_memory_skipped"]:
        print("Saved-memory gate: [SKIP] blocked until the restored checkout gate passes")
    else:
        saved_memory_result = result["saved_memory_result"]
        saved_status = "PASS" if saved_memory_result["ok"] else "FAIL"
        print(
            f"Saved-memory gate: [{saved_status}] "
            f"{saved_memory_result['repo_root']}"
        )

    if result["ok"]:
        print("\nIssue #3 snapshot re-entry preflight passed.")
        return

    print("\nIssue #3 snapshot re-entry preflight failed.", file=sys.stderr)
    if result["diagnosis"] == "restored-checkout-not-ready":
        print(
            "Suggested next step: rerun the saved browser snapshot restore with "
            "--sync-helper-surface, or refresh the existing restored checkout "
            "with --sync-only before reopening Linux or WSL follow-up work.",
            file=sys.stderr,
        )
    elif result["diagnosis"] == "saved-memory-preflight-failed":
        print(
            "Suggested next step: keep the restored checkout that already passed, "
            "then fix the saved Memory archive or dependency inputs before "
            "retrying build-readiness or runtime re-entry.",
            file=sys.stderr,
        )


class SnapshotReentryPreflightTests(unittest.TestCase):
    def _write_stub_helper(
        self,
        root: Path,
        relative_path: str,
        collect_results_body: str,
    ) -> None:
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(
            "def collect_results(**kwargs):\n"
            f"    {collect_results_body}\n",
            encoding="utf-8",
        )

    def test_collect_results_passes_when_both_helpers_pass(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            (repo_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            self._write_stub_helper(
                repo_root,
                RESTORED_CHECK_SCRIPT,
                "return {'ok': True, 'diagnosis': 'ready', 'repo_root': str(kwargs['repo_root'])}",
            )
            self._write_stub_helper(
                repo_root,
                SAVED_MEMORY_SCRIPT,
                "return {'ok': True, 'repo_root': str(kwargs['repo_root'])}",
            )

            result = collect_results(
                repo_root=repo_root,
                restored_checkout_root=root / DEFAULT_RESTORED_CHECKOUT_NAME,
                helper_root=repo_root,
                memory_root=root / "memory",
                agent_files_root=root / "agent_files",
                fallback_zig_archive=None,
                skip_archive_integrity_check=False,
            )

            self.assertTrue(result["ok"])
            self.assertEqual(result["diagnosis"], "ready")
            self.assertFalse(result["saved_memory_skipped"])

    def test_collect_results_skips_saved_memory_when_restored_checkout_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            (repo_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            self._write_stub_helper(
                repo_root,
                RESTORED_CHECK_SCRIPT,
                "return {'ok': False, 'diagnosis': 'stale-helper-surface', 'repo_root': str(kwargs['repo_root'])}",
            )
            self._write_stub_helper(
                repo_root,
                SAVED_MEMORY_SCRIPT,
                "raise AssertionError('saved memory helper should not run when restored checkout fails')",
            )

            result = collect_results(
                repo_root=repo_root,
                restored_checkout_root=root / DEFAULT_RESTORED_CHECKOUT_NAME,
                helper_root=repo_root,
                memory_root=root / "memory",
                agent_files_root=root / "agent_files",
                fallback_zig_archive=None,
                skip_archive_integrity_check=False,
            )

            self.assertFalse(result["ok"])
            self.assertEqual(result["diagnosis"], "restored-checkout-not-ready")
            self.assertTrue(result["saved_memory_skipped"])

    def test_collect_results_reports_saved_memory_failure_after_restored_checkout_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            (repo_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            self._write_stub_helper(
                repo_root,
                RESTORED_CHECK_SCRIPT,
                "return {'ok': True, 'diagnosis': 'ready', 'repo_root': str(kwargs['repo_root'])}",
            )
            self._write_stub_helper(
                repo_root,
                SAVED_MEMORY_SCRIPT,
                "return {'ok': False, 'repo_root': str(kwargs['repo_root'])}",
            )

            result = collect_results(
                repo_root=repo_root,
                restored_checkout_root=root / DEFAULT_RESTORED_CHECKOUT_NAME,
                helper_root=repo_root,
                memory_root=root / "memory",
                agent_files_root=root / "agent_files",
                fallback_zig_archive=None,
                skip_archive_integrity_check=False,
            )

            self.assertFalse(result["ok"])
            self.assertEqual(result["diagnosis"], "saved-memory-preflight-failed")
            self.assertFalse(result["saved_memory_skipped"])

    def test_collect_results_fails_when_helper_script_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            repo_root.mkdir()
            (repo_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            self._write_stub_helper(
                repo_root,
                RESTORED_CHECK_SCRIPT,
                "return {'ok': True, 'diagnosis': 'ready', 'repo_root': str(kwargs['repo_root'])}",
            )

            result = collect_results(
                repo_root=repo_root,
                restored_checkout_root=root / DEFAULT_RESTORED_CHECKOUT_NAME,
                helper_root=repo_root,
                memory_root=root / "memory",
                agent_files_root=root / "agent_files",
                fallback_zig_archive=None,
                skip_archive_integrity_check=False,
            )

            self.assertFalse(result["ok"])
            self.assertEqual(result["diagnosis"], "missing-helper-script")
            self.assertTrue(result["saved_memory_skipped"])

    def test_default_root_helpers_follow_workspace_layout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            (repo_root / REQUIRED_REPO_ROOT_FILE).write_text("{}", encoding="utf-8")
            self.assertEqual(
                resolve_default_restored_checkout_root(repo_root),
                Path(tmpdir) / DEFAULT_RESTORED_CHECKOUT_NAME,
            )
            self.assertEqual(resolve_default_memory_root(repo_root), Path(tmpdir) / "memory")
            self.assertEqual(resolve_default_agent_files_root(repo_root), Path(tmpdir) / "agent_files")


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SnapshotReentryPreflightTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    helper_root = Path(args.helper_root).resolve() if args.helper_root else repo_root
    restored_checkout_root = (
        Path(args.restored_checkout_root).resolve()
        if args.restored_checkout_root
        else resolve_default_restored_checkout_root(repo_root)
    )
    memory_root = Path(args.memory_root).resolve() if args.memory_root else resolve_default_memory_root(repo_root)
    agent_files_root = (
        Path(args.agent_files_root).resolve()
        if args.agent_files_root
        else resolve_default_agent_files_root(repo_root)
    )
    fallback_zig_archive = Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None

    result = collect_results(
        repo_root=repo_root,
        restored_checkout_root=restored_checkout_root,
        helper_root=helper_root,
        memory_root=memory_root,
        agent_files_root=agent_files_root,
        fallback_zig_archive=fallback_zig_archive,
        skip_archive_integrity_check=args.skip_archive_integrity_check,
    )
    if args.json:
        print(json.dumps({"profile": "issue3-snapshot-reentry-preflight", **result}, indent=2))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
