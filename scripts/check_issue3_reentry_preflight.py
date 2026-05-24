#!/usr/bin/env python3

"""Run a compact issue #3 re-entry preflight across existing helper routes.

This helper is intentionally orchestration-only. It does not replace the
existing saved-memory, archive-integrity, restored-checkout, or Linux build
readiness helpers. Instead, it stitches them into one ordered route so the next
run can quickly tell whether issue #3 is ready to reopen on the direct runtime
boundary or still needs restore/build-readiness work first.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import unittest


DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Run the saved-memory, archive-integrity, restored-checkout, and "
            "Linux build-readiness helpers in the order recommended for issue #3 "
            "runtime re-entry."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the live browser helper checkout (default: current directory)",
    )
    parser.add_argument(
        "--restored-checkout-root",
        default=None,
        help=(
            "Optional path to the restored browser snapshot checkout "
            "(default: ../browser-memory-snapshot beside the helper checkout)"
        ),
    )
    parser.add_argument(
        "--python",
        default=sys.executable,
        help="Python executable to use for helper invocations (default: current interpreter)",
    )
    parser.add_argument(
        "--skip-build-readiness",
        action="store_true",
        help="Skip the Linux build-readiness helper even when a restored checkout exists",
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
    return (repo_root.parent / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()


def shell_join(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def helper_path(repo_root: Path, relative_path: str) -> Path:
    return (repo_root / relative_path).resolve()


def build_step(
    *,
    name: str,
    command: list[str] | None,
    status: str,
    summary: str,
    output: str = "",
    required: bool = True,
) -> dict[str, object]:
    return {
        "name": name,
        "command": command,
        "status": status,
        "summary": summary,
        "output": output,
        "required": required,
    }


def run_checked_step(name: str, command: list[str]) -> dict[str, object]:
    try:
        completed = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as exc:
        return build_step(
            name=name,
            command=command,
            status="fail",
            summary=f"required executable not found: {exc.filename}",
        )

    output = "\n".join(
        part.strip() for part in (completed.stdout, completed.stderr) if part and part.strip()
    )
    if completed.returncode == 0:
        return build_step(
            name=name,
            command=command,
            status="pass",
            summary="helper check passed",
            output=output,
        )

    return build_step(
        name=name,
        command=command,
        status="fail",
        summary=f"helper exited with code {completed.returncode}",
        output=output,
    )


def collect_results(
    *,
    repo_root: Path,
    restored_checkout_root: Path,
    python_executable: str,
    skip_build_readiness: bool,
) -> dict[str, object]:
    steps: list[dict[str, object]] = []

    saved_memory_command = [
        python_executable,
        str(helper_path(repo_root, "scripts/check_issue3_saved_memory_inputs.py")),
        "--repo-root",
        str(repo_root),
    ]
    steps.append(run_checked_step("saved-memory-inputs", saved_memory_command))

    archive_integrity_command = [
        python_executable,
        str(helper_path(repo_root, "scripts/check_issue3_saved_archive_integrity.py")),
        "--repo-root",
        str(repo_root),
    ]
    steps.append(run_checked_step("saved-archive-integrity", archive_integrity_command))

    restore_route_command = [
        "bash",
        str(helper_path(repo_root, "scripts/linux/show_issue3_saved_browser_snapshot_route.sh")),
        "--repo-root",
        str(repo_root),
        "--sync-helper-surface",
    ]

    if restored_checkout_root.is_dir():
        restored_checkout_command = [
            python_executable,
            str(helper_path(repo_root, "scripts/check_issue3_restored_checkout.py")),
            "--repo-root",
            str(restored_checkout_root),
            "--helper-root",
            str(repo_root),
            "--expect-helper-surface",
        ]
        steps.append(run_checked_step("restored-checkout", restored_checkout_command))

        if skip_build_readiness:
            steps.append(
                build_step(
                    name="linux-build-readiness",
                    command=None,
                    status="skip",
                    summary="skipped by --skip-build-readiness",
                    required=False,
                )
            )
        else:
            build_readiness_command = [
                python_executable,
                str(helper_path(repo_root, "scripts/check_linux_build_readiness.py")),
                "--repo-root",
                str(restored_checkout_root),
                "--skip-zig-check",
                "--expect-saved-archives",
            ]
            steps.append(run_checked_step("linux-build-readiness", build_readiness_command))
    else:
        steps.append(
            build_step(
                name="restored-checkout",
                command=restore_route_command,
                status="blocked",
                summary=(
                    "restored checkout is missing; run the saved-browser-snapshot "
                    "route before Linux build-readiness or direct runtime work"
                ),
            )
        )
        steps.append(
            build_step(
                name="linux-build-readiness",
                command=None,
                status="blocked",
                summary="skipped because no restored checkout is available yet",
            )
        )

    required_failures = [
        step
        for step in steps
        if step["required"] and step["status"] not in {"pass", "skip"}
    ]
    ready_for_runtime_reentry = not required_failures

    next_commands = [
        shell_join(restore_route_command),
        shell_join(
            [
                python_executable,
                str(helper_path(repo_root, "scripts/check_issue3_saved_memory_inputs.py")),
                "--repo-root",
                str(repo_root),
            ]
        ),
        shell_join(
            [
                python_executable,
                str(helper_path(repo_root, "scripts/check_issue3_saved_archive_integrity.py")),
                "--repo-root",
                str(repo_root),
            ]
        ),
    ]

    if restored_checkout_root.is_dir():
        next_commands.extend(
            [
                shell_join(
                    [
                        python_executable,
                        str(helper_path(repo_root, "scripts/check_issue3_restored_checkout.py")),
                        "--repo-root",
                        str(restored_checkout_root),
                        "--helper-root",
                        str(repo_root),
                        "--expect-helper-surface",
                    ]
                ),
                shell_join(
                    [
                        python_executable,
                        str(helper_path(repo_root, "scripts/check_linux_build_readiness.py")),
                        "--repo-root",
                        str(restored_checkout_root),
                        "--skip-zig-check",
                        "--expect-saved-archives",
                    ]
                ),
                shell_join(
                    [
                        "bash",
                        str(
                            helper_path(
                                repo_root,
                                "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
                            )
                        ),
                        "--repo-root",
                        str(restored_checkout_root),
                    ]
                ),
            ]
        )

    return {
        "ok": ready_for_runtime_reentry,
        "repo_root": str(repo_root),
        "restored_checkout_root": str(restored_checkout_root),
        "steps": steps,
        "next_commands": next_commands,
    }


def emit_text(result: dict[str, object]) -> None:
    print(f"Helper checkout: {result['repo_root']}")
    print(f"Restored checkout: {result['restored_checkout_root']}")
    print("Re-entry steps:")
    for step in result["steps"]:
        status = str(step["status"]).upper()
        print(f"  [{status}] {step['name']}: {step['summary']}")
        command = step.get("command")
        if command:
            print(f"         command: {shell_join(command)}")
    print("Suggested next commands:")
    for command in result["next_commands"]:
        print(f"  - {command}")
    if result["ok"]:
        print("\nIssue #3 re-entry preflight passed.")
    else:
        print("\nIssue #3 re-entry preflight did not clear all required gates.", file=sys.stderr)


class ReentryPreflightTests(unittest.TestCase):
    def test_reports_missing_restored_checkout_as_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            scripts_dir = repo_root / "scripts"
            linux_dir = scripts_dir / "linux"
            linux_dir.mkdir(parents=True)

            for path in (
                scripts_dir / "check_issue3_saved_memory_inputs.py",
                scripts_dir / "check_issue3_saved_archive_integrity.py",
                scripts_dir / "check_issue3_restored_checkout.py",
                scripts_dir / "check_linux_build_readiness.py",
                linux_dir / "show_issue3_saved_browser_snapshot_route.sh",
                linux_dir / "show_issue3_enter_submit_runtime_revalidation_route.sh",
            ):
                path.write_text("placeholder", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                restored_checkout_root=root / "missing-restore",
                python_executable="/bin/true",
                skip_build_readiness=False,
            )

            self.assertFalse(result["ok"])
            statuses = {step["name"]: step["status"] for step in result["steps"]}
            self.assertEqual(statuses["restored-checkout"], "blocked")
            self.assertEqual(statuses["linux-build-readiness"], "blocked")

    def test_skip_build_readiness_marks_optional_skip(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            repo_root = root / "browser"
            restored_root = root / DEFAULT_RESTORED_CHECKOUT_NAME
            scripts_dir = repo_root / "scripts"
            linux_dir = scripts_dir / "linux"
            linux_dir.mkdir(parents=True)
            restored_root.mkdir()

            for path in (
                scripts_dir / "check_issue3_saved_memory_inputs.py",
                scripts_dir / "check_issue3_saved_archive_integrity.py",
                scripts_dir / "check_issue3_restored_checkout.py",
                scripts_dir / "check_linux_build_readiness.py",
                linux_dir / "show_issue3_saved_browser_snapshot_route.sh",
                linux_dir / "show_issue3_enter_submit_runtime_revalidation_route.sh",
            ):
                path.write_text("placeholder", encoding="utf-8")

            result = collect_results(
                repo_root=repo_root,
                restored_checkout_root=restored_root,
                python_executable="/bin/true",
                skip_build_readiness=True,
            )

            statuses = {step["name"]: step["status"] for step in result["steps"]}
            self.assertEqual(statuses["saved-memory-inputs"], "pass")
            self.assertEqual(statuses["saved-archive-integrity"], "pass")
            self.assertEqual(statuses["restored-checkout"], "pass")
            self.assertEqual(statuses["linux-build-readiness"], "skip")


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ReentryPreflightTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    restored_checkout_root = (
        Path(args.restored_checkout_root).resolve()
        if args.restored_checkout_root is not None
        else resolve_default_restored_checkout_root(repo_root)
    )

    result = collect_results(
        repo_root=repo_root,
        restored_checkout_root=restored_checkout_root,
        python_executable=args.python,
        skip_build_readiness=args.skip_build_readiness,
    )

    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        emit_text(result)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
