#!/usr/bin/env python3

"""Summarize the issue #3 runtime re-entry gates from existing helpers.

This helper does not replace the narrower scripts. It orchestrates them so a
Linux/WSL run can answer one practical question quickly:

- are the saved-input, archive-integrity, restored-checkout, and build-readiness
  gates open?
- if not, which route should run next?

It intentionally leaves the final writable-publication check explicit. The
script can confirm the validation gate from local evidence, but it cannot prove
that the current runtime can safely publish `Page.zig` and
`win32_backend.zig` back to the live branch unless the caller opts in.
"""

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
            "Summarize issue #3 runtime re-entry status from the saved-memory, "
            "archive-integrity, restored-checkout, and Linux build-readiness helpers."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--helper-root",
        default=None,
        help="Optional live helper root forwarded to restored-checkout checks",
    )
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Optional memory root forwarded to saved-memory helpers",
    )
    parser.add_argument(
        "--agent-files-root",
        default=None,
        help="Optional builder-attached files root forwarded to helper checks",
    )
    parser.add_argument(
        "--restored-checkout-root",
        default=None,
        help="Optional restored checkout root forwarded to helper checks",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit fallback Zig archive path",
    )
    parser.add_argument(
        "--zig",
        default="zig",
        help="Zig executable to probe for Linux build readiness (default: zig)",
    )
    parser.add_argument(
        "--cargo",
        default="cargo",
        help="Cargo executable to probe for Linux build readiness (default: cargo)",
    )
    parser.add_argument(
        "--rustc",
        default="rustc",
        help="rustc executable to probe for Linux build readiness (default: rustc)",
    )
    parser.add_argument(
        "--skip-zig-check",
        action="store_true",
        help="Forward --skip-zig-check to the Linux build-readiness helper",
    )
    parser.add_argument(
        "--skip-rust-check",
        action="store_true",
        help="Forward --skip-rust-check to the Linux build-readiness helper",
    )
    parser.add_argument(
        "--expect-offline-deps",
        action="store_true",
        help="Require offline dependency staging in the Linux build-readiness helper",
    )
    parser.add_argument(
        "--offline-deps-root",
        default=None,
        help="Optional offline dependency root forwarded to Linux build readiness",
    )
    parser.add_argument(
        "--require-prebuilt-v8",
        action="store_true",
        help="Require a prebuilt V8 archive in the offline dependency root",
    )
    parser.add_argument(
        "--require-fallback-zig",
        action="store_true",
        help="Require the surfaced fallback Zig archive to exist and match its checksum",
    )
    parser.add_argument(
        "--assume-writable-publication-path",
        action="store_true",
        help=(
            "Mark the publication gate open when the caller already knows a safe "
            "writable publication route exists for Page.zig and win32_backend.zig"
        ),
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


def maybe_append(args: list[str], flag: str, value: str | None) -> None:
    if value is not None:
        args.extend((flag, value))


def run_json_helper(helper_path: Path, args: list[str]) -> dict[str, object]:
    completed = subprocess.run(
        [sys.executable, str(helper_path), *args, "--json"],
        check=False,
        capture_output=True,
        text=True,
    )
    if not completed.stdout.strip():
        raise RuntimeError(
            f"{helper_path.name} produced no JSON output (exit {completed.returncode}): "
            f"{completed.stderr.strip()}"
        )

    try:
        payload = json.loads(completed.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(
            f"{helper_path.name} emitted invalid JSON: {exc}: {completed.stdout!r}"
        ) from exc

    if not isinstance(payload, dict):
        raise RuntimeError(f"{helper_path.name} JSON payload was not an object")
    payload["_exit_code"] = completed.returncode
    payload["_stderr"] = completed.stderr.strip()
    payload["_helper"] = helper_path.name
    return payload


def build_helper_calls(args: argparse.Namespace) -> dict[str, tuple[Path, list[str]]]:
    repo_root = Path(args.repo_root).resolve()
    scripts_root = repo_root / "scripts"
    helpers: dict[str, tuple[Path, list[str]]] = {}

    saved_memory_args = ["--repo-root", str(repo_root)]
    maybe_append(saved_memory_args, "--helper-root", args.helper_root)
    maybe_append(saved_memory_args, "--memory-root", args.memory_root)
    maybe_append(saved_memory_args, "--agent-files-root", args.agent_files_root)
    maybe_append(saved_memory_args, "--restored-checkout-root", args.restored_checkout_root)
    maybe_append(saved_memory_args, "--fallback-zig-archive", args.fallback_zig_archive)
    helpers["saved_memory"] = (
        scripts_root / "check_issue3_saved_memory_inputs.py",
        saved_memory_args,
    )

    archive_args = ["--repo-root", str(repo_root)]
    maybe_append(archive_args, "--memory-root", args.memory_root)
    maybe_append(archive_args, "--agent-files-root", args.agent_files_root)
    maybe_append(archive_args, "--fallback-zig-archive", args.fallback_zig_archive)
    if args.require_fallback_zig:
        archive_args.append("--require-fallback-zig")
    helpers["archive_integrity"] = (
        scripts_root / "check_issue3_saved_archive_integrity.py",
        archive_args,
    )

    build_args = [
        "--repo-root",
        str(repo_root),
        "--zig",
        args.zig,
        "--cargo",
        args.cargo,
        "--rustc",
        args.rustc,
        "--expect-saved-archives",
    ]
    maybe_append(build_args, "--saved-archives-root", args.memory_root)
    maybe_append(build_args, "--fallback-zig-archive", args.fallback_zig_archive)
    maybe_append(build_args, "--toolchains-root", str((repo_root.parent / "toolchains").resolve()))
    if args.skip_zig_check:
        build_args.append("--skip-zig-check")
    if args.skip_rust_check:
        build_args.append("--skip-rust-check")
    if args.expect_offline_deps:
        build_args.append("--expect-offline-deps")
    if args.require_prebuilt_v8:
        build_args.append("--require-prebuilt-v8")
    maybe_append(build_args, "--offline-deps-root", args.offline_deps_root)
    helpers["build_readiness"] = (
        scripts_root / "check_linux_build_readiness.py",
        build_args,
    )

    restored_checkout_root = (
        Path(args.restored_checkout_root).resolve()
        if args.restored_checkout_root is not None
        else (repo_root.parent / "browser-memory-snapshot").resolve()
    )
    restored_args = ["--repo-root", str(restored_checkout_root), "--expect-helper-surface"]
    maybe_append(restored_args, "--helper-root", args.helper_root or str(repo_root))
    helpers["restored_checkout"] = (
        scripts_root / "check_issue3_restored_checkout.py",
        restored_args,
    )
    return helpers


def summarize_publication_gate(assume_open: bool) -> tuple[str, str]:
    if assume_open:
        return (
            "open",
            "Caller asserted that a safe writable publication path exists for the runtime patch.",
        )
    return (
        "manual-check-required",
        "Local helpers cannot prove the live Page.zig/win32_backend.zig publication path; confirm a safe writable route separately.",
    )


def choose_next_step(report: dict[str, object]) -> str:
    saved_memory = report["saved_memory"]
    if not saved_memory["ok"]:
        return (
            "Run `python scripts/check_issue3_saved_memory_inputs.py --repo-root .` and "
            "restore or sync the missing saved-memory inputs before reopening the runtime path."
        )

    archive_integrity = report["archive_integrity"]
    if not archive_integrity["ok"]:
        return (
            "Run `python scripts/check_issue3_saved_archive_integrity.py --repo-root .` and "
            "refresh any mismatched archive before trusting restore or build-readiness work."
        )

    restored_checkout = report["restored_checkout"]
    diagnosis = restored_checkout["diagnosis"]
    if diagnosis in {"stale-helper-surface", "helper-surface-drift", "partial-helper-surface-and-drift"}:
        return (
            "Run `bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh --sync-helper-surface` "
            "or resync the restored checkout helper surface before follow-up Linux/WSL work."
        )
    if diagnosis == "missing-helper-surface":
        return (
            "Restore or resync `../browser-memory-snapshot` with the issue #3 helper surface, "
            "then rerun the restored-checkout helper."
        )
    if diagnosis in {"missing-required-paths", "missing-required-and-stale-helper-surface"}:
        return (
            "Run `bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh` to recreate the "
            "restored checkout before retrying Linux/WSL re-entry."
        )

    build_readiness = report["build_readiness"]
    if not build_readiness["ok"]:
        failures = build_readiness["failures"]
        if any("expected 0.15" in failure or "fallback Zig archive" in failure for failure in failures):
            return (
                "Run `bash ./scripts/linux/show_issue3_zig_toolchain_recovery_route.sh` to stage a "
                "branch-compatible Zig 0.15.x toolchain before retrying build readiness."
            )
        if any("offline dependency root is missing" in failure or "missing prebuilt V8 archive" in failure for failure in failures):
            return (
                "Run `bash ./scripts/linux/show_issue3_offline_build_inputs_route.sh` to restore "
                "offline Linux build inputs before retrying build readiness."
            )
        return (
            "Run `bash ./scripts/linux/show_issue3_linux_build_readiness_route.sh` and clear the "
            "reported Linux/WSL readiness failures before reopening the runtime patch."
        )

    if report["publication_gate"]["status"] != "open":
        return (
            "Validation inputs look ready, but confirm a safe writable publication route for "
            "`src/browser/Page.zig` and `src/display/win32_backend.zig` before reopening the patch."
        )

    return (
        "Both local re-entry gates are green. Reopen `docs/ISSUE3_RUNTIME_REENTRY_GATES.md`, "
        "revalidate the runtime contract markers, and resume the narrowed issue #3 patch."
    )


def build_report(helper_results: dict[str, dict[str, object]], assume_writable_publication_path: bool) -> dict[str, object]:
    publication_status, publication_note = summarize_publication_gate(
        assume_writable_publication_path
    )
    validation_gate_open = (
        helper_results["saved_memory"]["ok"]
        and helper_results["archive_integrity"]["ok"]
        and helper_results["restored_checkout"]["ok"]
        and helper_results["build_readiness"]["status"] == "passed"
    )
    runtime_patch_reentry_ready = validation_gate_open and publication_status == "open"

    report = {
        "profile": "issue3-runtime-reentry-status",
        "saved_memory": {
            "ok": helper_results["saved_memory"]["ok"],
            "status": "open" if helper_results["saved_memory"]["ok"] else "blocked",
            "helper": helper_results["saved_memory"]["_helper"],
        },
        "archive_integrity": {
            "ok": helper_results["archive_integrity"]["ok"],
            "status": "open" if helper_results["archive_integrity"]["ok"] else "blocked",
            "helper": helper_results["archive_integrity"]["_helper"],
        },
        "restored_checkout": {
            "ok": helper_results["restored_checkout"]["ok"],
            "status": "open" if helper_results["restored_checkout"]["ok"] else "blocked",
            "diagnosis": helper_results["restored_checkout"]["diagnosis"],
            "helper": helper_results["restored_checkout"]["_helper"],
        },
        "build_readiness": {
            "ok": helper_results["build_readiness"]["status"] == "passed",
            "status": "open" if helper_results["build_readiness"]["status"] == "passed" else "blocked",
            "minimum_zig": helper_results["build_readiness"].get("minimum_zig"),
            "installed_zig": helper_results["build_readiness"].get("installed_zig"),
            "matching_zig_candidates": helper_results["build_readiness"].get("matching_zig_candidates", []),
            "failures": helper_results["build_readiness"].get("failures", []),
            "helper": helper_results["build_readiness"]["_helper"],
        },
        "publication_gate": {
            "status": publication_status,
            "note": publication_note,
        },
        "validation_gate_open": validation_gate_open,
        "runtime_patch_reentry_ready": runtime_patch_reentry_ready,
    }
    report["next_step"] = choose_next_step(report)
    report["helper_results"] = helper_results
    return report


def emit_text(report: dict[str, object]) -> None:
    print("Issue #3 runtime re-entry status")
    print(f"Validation gate: {'OPEN' if report['validation_gate_open'] else 'BLOCKED'}")
    print(
        f"Publication gate: {report['publication_gate']['status'].upper()} "
        f"({report['publication_gate']['note']})"
    )
    print(
        f"Runtime patch re-entry ready: {'YES' if report['runtime_patch_reentry_ready'] else 'NO'}"
    )
    print("Checks:")
    for key, label in (
        ("saved_memory", "Saved Memory inputs"),
        ("archive_integrity", "Saved archive integrity"),
        ("restored_checkout", "Restored checkout helper surface"),
        ("build_readiness", "Linux/WSL build readiness"),
    ):
        entry = report[key]
        status = "PASS" if entry["status"] == "open" else "FAIL"
        detail = ""
        if key == "restored_checkout" and not entry["ok"]:
            detail = f" diagnosis={entry['diagnosis']}"
        if key == "build_readiness" and not entry["ok"]:
            failures = entry["failures"]
            if failures:
                detail = f" first_failure={failures[0]}"
        print(f"  [{status}] {label}{detail}")
    print(f"Next step: {report['next_step']}")


class RuntimeReentryStatusTests(unittest.TestCase):
    def test_choose_next_step_prefers_saved_memory_blocker(self) -> None:
        report = {
            "saved_memory": {"ok": False},
            "archive_integrity": {"ok": True},
            "restored_checkout": {"ok": True, "diagnosis": "ready"},
            "build_readiness": {"ok": True, "failures": []},
            "publication_gate": {"status": "manual-check-required"},
        }
        self.assertIn("check_issue3_saved_memory_inputs.py", choose_next_step(report))

    def test_choose_next_step_prefers_archive_integrity_blocker(self) -> None:
        report = {
            "saved_memory": {"ok": True},
            "archive_integrity": {"ok": False},
            "restored_checkout": {"ok": True, "diagnosis": "ready"},
            "build_readiness": {"ok": True, "failures": []},
            "publication_gate": {"status": "manual-check-required"},
        }
        self.assertIn("check_issue3_saved_archive_integrity.py", choose_next_step(report))

    def test_choose_next_step_handles_stale_restored_checkout_surface(self) -> None:
        report = {
            "saved_memory": {"ok": True},
            "archive_integrity": {"ok": True},
            "restored_checkout": {"ok": False, "diagnosis": "stale-helper-surface"},
            "build_readiness": {"ok": True, "failures": []},
            "publication_gate": {"status": "manual-check-required"},
        }
        self.assertIn("--sync-helper-surface", choose_next_step(report))

    def test_choose_next_step_prefers_zig_recovery_route(self) -> None:
        report = {
            "saved_memory": {"ok": True},
            "archive_integrity": {"ok": True},
            "restored_checkout": {"ok": True, "diagnosis": "ready"},
            "build_readiness": {
                "ok": False,
                "failures": [
                    "fallback Zig archive zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz surfaces Zig 0.17.0, which does not match the branch's expected 0.15.x line"
                ],
            },
            "publication_gate": {"status": "manual-check-required"},
        }
        self.assertIn("show_issue3_zig_toolchain_recovery_route.sh", choose_next_step(report))

    def test_choose_next_step_stops_on_manual_publication_check(self) -> None:
        report = {
            "saved_memory": {"ok": True},
            "archive_integrity": {"ok": True},
            "restored_checkout": {"ok": True, "diagnosis": "ready"},
            "build_readiness": {"ok": True, "failures": []},
            "publication_gate": {"status": "manual-check-required"},
        }
        self.assertIn("safe writable publication route", choose_next_step(report))

    def test_build_report_only_marks_runtime_ready_when_publication_is_open(self) -> None:
        helper_results = {
            "saved_memory": {"ok": True, "_helper": "a.py"},
            "archive_integrity": {"ok": True, "_helper": "b.py"},
            "restored_checkout": {"ok": True, "diagnosis": "ready", "_helper": "c.py"},
            "build_readiness": {
                "status": "passed",
                "minimum_zig": "0.15.2",
                "installed_zig": "0.15.7",
                "matching_zig_candidates": [],
                "failures": [],
                "_helper": "d.py",
            },
        }
        blocked = build_report(helper_results, assume_writable_publication_path=False)
        self.assertTrue(blocked["validation_gate_open"])
        self.assertFalse(blocked["runtime_patch_reentry_ready"])
        open_report = build_report(helper_results, assume_writable_publication_path=True)
        self.assertTrue(open_report["runtime_patch_reentry_ready"])

    def test_run_json_helper_rejects_missing_json_output(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            helper = Path(tmpdir) / "helper.py"
            helper.write_text(
                "import sys\nprint('', end='')\nsys.exit(1)\n",
                encoding="utf-8",
            )
            with self.assertRaises(RuntimeError):
                run_json_helper(helper, [])


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(RuntimeReentryStatusTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    helper_calls = build_helper_calls(args)
    helper_results: dict[str, dict[str, object]] = {}
    try:
        for key, (helper_path, helper_args) in helper_calls.items():
            helper_results[key] = run_json_helper(helper_path, helper_args)
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    report = build_report(
        helper_results,
        assume_writable_publication_path=args.assume_writable_publication_path,
    )
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        emit_text(report)
    return 0 if report["runtime_patch_reentry_ready"] else 1


if __name__ == "__main__":
    sys.exit(main())
