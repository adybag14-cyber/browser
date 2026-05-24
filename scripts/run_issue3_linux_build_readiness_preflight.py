#!/usr/bin/env python3

"""Run the issue #3 Linux build-readiness preflight chain.

This helper turns the current branch-local route notes and "show" scripts into a
single runnable preflight for scheduled or manual reruns. It intentionally stops
at the first failing gate so the next recovery step stays obvious.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import unittest


DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"


@dataclass(frozen=True)
class Step:
    key: str
    title: str
    command: tuple[str, ...]
    failure_follow_up: tuple[str, ...]


def shell_join(command: tuple[str, ...] | list[str]) -> str:
    return " ".join(shlex.quote(part) for part in command)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Run the issue #3 Linux build-readiness preflight chain and stop at "
            "the first failing gate."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help=(
            "Path to the saved browser archive root "
            "(default: ../memory/repo_archives/browser beside the repo workspace)"
        ),
    )
    parser.add_argument(
        "--offline-deps-root",
        default=None,
        help="Optional offline dependency root to thread into the readiness helper",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit fallback Zig archive to thread into the preflight helpers",
    )
    parser.add_argument(
        "--expect-offline-deps",
        action="store_true",
        help="Also run the offline dependency readiness gate after the saved-archive preflight",
    )
    parser.add_argument(
        "--require-prebuilt-v8",
        action="store_true",
        help="Require a prebuilt libc_v8_*.a archive when --expect-offline-deps is enabled",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the preflight chain without executing it",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON output",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def resolve_saved_archives_root(repo_root: Path, override: str | None) -> Path:
    if override:
        return Path(override).resolve()
    return (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()


def resolve_fallback_zig_archive(repo_root: Path, override: str | None) -> Path | None:
    if override:
        return Path(override).resolve()
    candidate = (repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG).resolve()
    return candidate if candidate.is_file() else None


def build_steps(
    *,
    repo_root: Path,
    saved_archives_root: Path,
    fallback_zig_archive: Path | None,
    offline_deps_root: Path | None,
    expect_offline_deps: bool,
    require_prebuilt_v8: bool,
) -> list[Step]:
    dependencies_root = saved_archives_root / "dependencies"

    def with_repo_root(script: str) -> list[str]:
        return ["bash", str(repo_root / script), "--repo-root", str(repo_root)]

    def maybe_fallback(command: list[str]) -> list[str]:
        if fallback_zig_archive is not None:
            command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
        return command

    steps = [
        Step(
            key="surface",
            title="Linux build-readiness route surface",
            command=tuple(with_repo_root("scripts/linux/check_issue3_linux_build_readiness_route_surface.sh")),
            failure_follow_up=(
                "bash",
                str(repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"),
                "--repo-root",
                str(repo_root),
            ),
        ),
        Step(
            key="saved_memory_inputs",
            title="Saved Memory inputs",
            command=tuple(
                maybe_fallback(
                    [
                        sys.executable,
                        str(repo_root / "scripts/check_issue3_saved_memory_inputs.py"),
                        "--repo-root",
                        str(repo_root),
                    ]
                )
            ),
            failure_follow_up=(
                "bash",
                str(repo_root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh"),
                "--repo-root",
                str(repo_root),
            ),
        ),
        Step(
            key="saved_archive_surface",
            title="Saved archive integrity route surface",
            command=tuple(with_repo_root("scripts/linux/check_issue3_saved_archive_integrity_route_surface.sh")),
            failure_follow_up=(
                "bash",
                str(repo_root / "scripts/linux/show_issue3_saved_archive_integrity_route.sh"),
                "--repo-root",
                str(repo_root),
            ),
        ),
        Step(
            key="saved_archive_integrity",
            title="Saved archive integrity",
            command=tuple(
                maybe_fallback(
                    [
                        sys.executable,
                        str(repo_root / "scripts/check_issue3_saved_archive_integrity.py"),
                        "--repo-root",
                        str(repo_root),
                    ]
                )
            ),
            failure_follow_up=(
                "bash",
                str(repo_root / "scripts/linux/show_issue3_saved_archive_integrity_route.sh"),
                "--repo-root",
                str(repo_root),
            ),
        ),
        Step(
            key="saved_archive_preflight",
            title="Saved archive build-readiness preflight",
            command=tuple(
                maybe_fallback(
                    [
                        sys.executable,
                        str(repo_root / "scripts/check_linux_build_readiness.py"),
                        "--repo-root",
                        str(repo_root),
                        "--skip-zig-check",
                        "--expect-saved-archives",
                        "--saved-archives-root",
                        str(dependencies_root),
                    ]
                )
            ),
            failure_follow_up=(
                "bash",
                str(repo_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh"),
                "--repo-root",
                str(repo_root),
                "--saved-archives-root",
                str(saved_archives_root),
            ),
        ),
    ]

    if expect_offline_deps:
        command = [
            sys.executable,
            str(repo_root / "scripts/check_linux_build_readiness.py"),
            "--repo-root",
            str(repo_root),
            "--skip-zig-check",
            "--expect-saved-archives",
            "--saved-archives-root",
            str(dependencies_root),
            "--expect-offline-deps",
        ]
        if require_prebuilt_v8:
            command.append("--require-prebuilt-v8")
        if offline_deps_root is not None:
            command.extend(("--offline-deps-root", str(offline_deps_root)))
        command = maybe_fallback(command)
        follow_up = [
            "bash",
            str(repo_root / "scripts/linux/show_issue3_offline_build_inputs_route.sh"),
            "--repo-root",
            str(repo_root),
            "--saved-archives-root",
            str(dependencies_root),
        ]
        if fallback_zig_archive is not None:
            follow_up.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
        steps.append(
            Step(
                key="offline_preflight",
                title="Offline dependency build-readiness preflight",
                command=tuple(command),
                failure_follow_up=tuple(follow_up),
            )
        )

    return steps


def execute_steps(steps: list[Step]) -> dict[str, object]:
    results: list[dict[str, object]] = []
    for step in steps:
        completed = subprocess.run(
            list(step.command),
            check=False,
            capture_output=True,
            text=True,
        )
        step_result = {
            "key": step.key,
            "title": step.title,
            "command": shell_join(step.command),
            "exit_code": completed.returncode,
            "stdout": completed.stdout,
            "stderr": completed.stderr,
            "ok": completed.returncode == 0,
            "failure_follow_up": shell_join(step.failure_follow_up),
        }
        results.append(step_result)
        if completed.returncode != 0:
            return {
                "ok": False,
                "failed_step": step_result,
                "results": results,
            }
    return {
        "ok": True,
        "failed_step": None,
        "results": results,
    }


def emit_text(report: dict[str, object], *, dry_run: bool) -> None:
    mode = "Planned" if dry_run else "Executed"
    print(f"{mode} issue #3 Linux build-readiness preflight chain")
    print()
    for index, step in enumerate(report["results"], start=1):
        status = "PASS" if step["ok"] else "FAIL"
        print(f"{index}. [{status}] {step['title']}")
        print(f"   {step['command']}")
        if not dry_run and step["stdout"].strip():
            print("   stdout:")
            for line in step["stdout"].strip().splitlines():
                print(f"     {line}")
        if not dry_run and step["stderr"].strip():
            print("   stderr:")
            for line in step["stderr"].strip().splitlines():
                print(f"     {line}")
        if not step["ok"]:
            print(f"   follow-up: {step['failure_follow_up']}")
            break
    if report["ok"]:
        print()
        print("All build-readiness preflight gates passed.")
    elif dry_run:
        print()
        print("Dry run only; no commands were executed.")
    else:
        print()
        print("Stopped at the first failing gate.")


class Issue3LinuxBuildReadinessPreflightRunnerTests(unittest.TestCase):
    def test_default_saved_archives_root_uses_workspace_memory_layout(self) -> None:
        repo_root = Path("/tmp/workspace/browser")
        self.assertEqual(
            resolve_saved_archives_root(repo_root, None),
            Path("/tmp/workspace/memory/repo_archives/browser"),
        )

    def test_default_fallback_zig_archive_is_optional(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_root = Path(tmpdir) / "browser"
            repo_root.mkdir()
            self.assertIsNone(resolve_fallback_zig_archive(repo_root, None))

    def test_build_steps_threads_saved_archives_root_and_optional_fallback(self) -> None:
        repo_root = Path("/tmp/workspace/browser")
        saved_archives_root = Path("/tmp/workspace/memory/repo_archives/browser")
        fallback_zig = Path("/tmp/workspace/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz")

        steps = build_steps(
            repo_root=repo_root,
            saved_archives_root=saved_archives_root,
            fallback_zig_archive=fallback_zig,
            offline_deps_root=None,
            expect_offline_deps=True,
            require_prebuilt_v8=True,
        )

        self.assertEqual(steps[0].key, "surface")
        self.assertEqual(steps[-1].key, "offline_preflight")
        self.assertIn(str(saved_archives_root / "dependencies"), steps[4].command)
        self.assertIn("--fallback-zig-archive", steps[1].command)
        self.assertIn("--require-prebuilt-v8", steps[-1].command)

    def test_execute_steps_stops_at_first_failure(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            ok_script = root / "ok.sh"
            fail_script = root / "fail.sh"
            ok_script.write_text("#!/usr/bin/env bash\necho ok\n", encoding="utf-8")
            fail_script.write_text("#!/usr/bin/env bash\necho bad >&2\nexit 7\n", encoding="utf-8")
            ok_script.chmod(0o755)
            fail_script.chmod(0o755)

            steps = [
                Step("first", "first", (str(ok_script),), ("echo", "recover")),
                Step("second", "second", (str(fail_script),), ("echo", "route")),
                Step("third", "third", (str(ok_script),), ("echo", "unused")),
            ]

            report = execute_steps(steps)

            self.assertFalse(report["ok"])
            self.assertEqual(report["failed_step"]["key"], "second")
            self.assertEqual(len(report["results"]), 2)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(
            Issue3LinuxBuildReadinessPreflightRunnerTests
        )
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    saved_archives_root = resolve_saved_archives_root(repo_root, args.saved_archives_root)
    fallback_zig_archive = resolve_fallback_zig_archive(repo_root, args.fallback_zig_archive)
    offline_deps_root = Path(args.offline_deps_root).resolve() if args.offline_deps_root else None

    steps = build_steps(
        repo_root=repo_root,
        saved_archives_root=saved_archives_root,
        fallback_zig_archive=fallback_zig_archive,
        offline_deps_root=offline_deps_root,
        expect_offline_deps=args.expect_offline_deps,
        require_prebuilt_v8=args.require_prebuilt_v8,
    )

    if args.dry_run:
        report = {
            "ok": True,
            "failed_step": None,
            "results": [
                {
                    "key": step.key,
                    "title": step.title,
                    "command": shell_join(step.command),
                    "exit_code": None,
                    "stdout": "",
                    "stderr": "",
                    "ok": True,
                    "failure_follow_up": shell_join(step.failure_follow_up),
                }
                for step in steps
            ],
        }
    else:
        report = execute_steps(steps)

    output = {
        "profile": "issue3-linux-build-readiness-preflight-runner",
        "repo_root": str(repo_root),
        "saved_archives_root": str(saved_archives_root),
        "fallback_zig_archive": str(fallback_zig_archive) if fallback_zig_archive else None,
        "offline_deps_root": str(offline_deps_root) if offline_deps_root else None,
        "expect_offline_deps": args.expect_offline_deps,
        "require_prebuilt_v8": args.require_prebuilt_v8,
        "dry_run": args.dry_run,
        **report,
    }

    if args.json:
        print(json.dumps(output, indent=2))
    else:
        emit_text(output, dry_run=args.dry_run)
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
