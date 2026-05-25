#!/usr/bin/env python3

"""Choose the best issue #11 Rust re-entry path from staged and saved inputs."""

from __future__ import annotations

import argparse
import json
import pathlib
import shlex
import subprocess
import sys
import tempfile
import unittest


DEFAULT_EXPECTED_RUST = "1.79.0"
DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"


def format_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def format_env_command(env_pairs: list[tuple[str, str]], parts: list[str]) -> str:
    env_chunks = ["env"]
    for key, value in env_pairs:
        env_chunks.append(f"{key}={shlex.quote(value)}")
    env_chunks.extend(shlex.quote(part) for part in parts)
    return " ".join(env_chunks)


def resolve_default_saved_archives_root(repo_root: pathlib.Path) -> pathlib.Path:
    return (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()


def resolve_default_toolchains_root(repo_root: pathlib.Path) -> pathlib.Path:
    return (repo_root.parent / "toolchains").resolve()


def resolve_default_offline_deps_root(repo_root: pathlib.Path) -> pathlib.Path:
    return (repo_root.parent / "offline-deps").resolve()


def resolve_default_fallback_zig_archive(repo_root: pathlib.Path) -> pathlib.Path | None:
    candidate = (repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve()
    return candidate if candidate.is_file() else None


def load_json_helper(command: list[str], label: str) -> tuple[dict[str, object] | None, str | None]:
    try:
        completed = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        return None, f"{label} could not run: {exc}"

    helper_stdout = completed.stdout.strip()
    if not helper_stdout:
        detail = completed.stderr.strip()
        suffix = f"; stderr: {detail}" if detail else ""
        return None, f"{label} produced no JSON output{suffix}"

    try:
        return json.loads(helper_stdout), None
    except json.JSONDecodeError as exc:
        return None, f"{label} returned invalid JSON: {exc}"


def load_staged_candidate_report(
    repo_root: pathlib.Path,
    toolchains_root: pathlib.Path,
) -> tuple[dict[str, object] | None, str | None]:
    helper = repo_root / "scripts" / "check_issue3_staged_rust_toolchain_candidates.py"
    if not helper.is_file():
        return None, f"staged Rust candidate helper is missing: {helper}"
    return load_json_helper(
        [
            sys.executable,
            str(helper),
            "--repo-root",
            str(repo_root),
            "--toolchains-root",
            str(toolchains_root),
            "--json",
        ],
        "staged Rust candidate helper",
    )


def load_saved_archive_report(
    repo_root: pathlib.Path,
    saved_archives_root: pathlib.Path,
    toolchains_root: pathlib.Path,
) -> tuple[dict[str, object] | None, str | None]:
    helper = repo_root / "scripts" / "check_issue3_saved_rust_archive_candidates.py"
    if not helper.is_file():
        return None, f"saved Rust archive helper is missing: {helper}"
    return load_json_helper(
        [
            sys.executable,
            str(helper),
            "--repo-root",
            str(repo_root),
            "--saved-archives-root",
            str(saved_archives_root),
            "--toolchains-root",
            str(toolchains_root),
            "--expected-rust",
            DEFAULT_EXPECTED_RUST,
            "--json",
        ],
        "saved Rust archive helper",
    )


def build_report(
    *,
    repo_root: pathlib.Path,
    saved_archives_root: pathlib.Path,
    toolchains_root: pathlib.Path,
    offline_deps_root: pathlib.Path,
    fallback_zig_archive: pathlib.Path | None,
    staged_candidate_report: dict[str, object] | None,
    staged_candidate_warning: str | None,
    saved_archive_report: dict[str, object] | None,
    saved_archive_warning: str | None,
) -> dict[str, object]:
    preferred_staged = None
    if isinstance(staged_candidate_report, dict):
        candidate = staged_candidate_report.get("preferred_candidate")
        if isinstance(candidate, dict):
            preferred_staged = candidate

    preferred_saved_archive = None
    if isinstance(saved_archive_report, dict):
        archive = saved_archive_report.get("preferred_archive")
        if isinstance(archive, dict):
            preferred_saved_archive = archive

    preferred_action = "blocked"
    reason = ""
    next_command = ""

    if preferred_staged is not None:
        preferred_action = "use-staged"
        reason = (
            f"staged Rust candidate {preferred_staged.get('cargo_version') or DEFAULT_EXPECTED_RUST} "
            f"is already available under {toolchains_root}"
        )
        env_pairs = [
            ("PATH", f"{preferred_staged['toolchain_root']}/cargo/bin:{preferred_staged['toolchain_root']}/rustc/bin:$PATH"),
            ("CARGO", str(preferred_staged["cargo_bin"])),
            ("RUSTC", str(preferred_staged["rustc_bin"])),
        ]
        zig_plan_command = [
            sys.executable,
            str(repo_root / "scripts" / "check_issue3_zig_toolchain_plan.py"),
            "--repo-root",
            str(repo_root),
            "--saved-archives-root",
            str(saved_archives_root),
            "--toolchains-root",
            str(toolchains_root),
            "--offline-deps-root",
            str(offline_deps_root),
        ]
        if fallback_zig_archive is not None:
            zig_plan_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
        next_command = format_env_command(env_pairs, zig_plan_command)
    elif preferred_saved_archive is not None:
        preferred_action = "restore-saved-archive"
        reason = (
            f"saved Rust archive {pathlib.Path(str(preferred_saved_archive['path'])).name} "
            "matches the expected 1.79.x line but is not staged yet"
        )
        commands = saved_archive_report.get("commands") if isinstance(saved_archive_report, dict) else {}
        if isinstance(commands, dict):
            next_command = str(commands.get("restore_check") or "")
    else:
        reason = "no staged or saved Rust 1.79.x toolchain path is ready"
        next_command = format_command(
            [
                "bash",
                str(repo_root / "scripts" / "linux" / "show_issue3_saved_rust_toolchain_route.sh"),
            ]
        )

    failures: list[str] = []
    if preferred_action != "use-staged":
        failures.append(reason)
    if staged_candidate_warning is not None:
        failures.append(staged_candidate_warning)
    if saved_archive_warning is not None:
        failures.append(saved_archive_warning)

    return {
        "status": "passed" if preferred_action == "use-staged" else "failed",
        "repo_root": str(repo_root),
        "saved_archives_root": str(saved_archives_root),
        "toolchains_root": str(toolchains_root),
        "offline_deps_root": str(offline_deps_root),
        "fallback_zig_archive": str(fallback_zig_archive) if fallback_zig_archive else "",
        "expected_rust": DEFAULT_EXPECTED_RUST,
        "staged_candidate_report": staged_candidate_report,
        "staged_candidate_warning": staged_candidate_warning or "",
        "saved_archive_report": saved_archive_report,
        "saved_archive_warning": saved_archive_warning or "",
        "preferred_action": preferred_action,
        "reason": reason,
        "next_command": next_command,
        "failures": failures,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Choose the best issue #11 Rust re-entry path for Linux/WSL."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help="Path to repo_archives/browser or its dependencies directory",
    )
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Path to the shared toolchains directory",
    )
    parser.add_argument(
        "--offline-deps-root",
        default=None,
        help="Path to the offline dependency staging directory",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional path to the surfaced fallback Zig archive for the Zig planner handoff",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON output")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


class RustToolchainPlanTests(unittest.TestCase):
    def test_build_report_prefers_staged_candidate(self) -> None:
        report = build_report(
            repo_root=pathlib.Path("/tmp/browser"),
            saved_archives_root=pathlib.Path("/tmp/memory/repo_archives/browser"),
            toolchains_root=pathlib.Path("/tmp/toolchains"),
            offline_deps_root=pathlib.Path("/tmp/offline-deps"),
            fallback_zig_archive=pathlib.Path("/tmp/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"),
            staged_candidate_report={
                "preferred_candidate": {
                    "toolchain_root": "/tmp/toolchains/rust-1.79.0",
                    "cargo_bin": "/tmp/toolchains/rust-1.79.0/cargo/bin/cargo",
                    "rustc_bin": "/tmp/toolchains/rust-1.79.0/rustc/bin/rustc",
                    "cargo_version": "1.79.0",
                }
            },
            staged_candidate_warning=None,
            saved_archive_report=None,
            saved_archive_warning=None,
        )

        self.assertEqual(report["status"], "passed")
        self.assertEqual(report["preferred_action"], "use-staged")
        self.assertIn("check_issue3_zig_toolchain_plan.py", report["next_command"])
        self.assertIn("CARGO=", report["next_command"])
        self.assertIn("RUSTC=", report["next_command"])

    def test_build_report_uses_saved_archive_when_staged_candidate_missing(self) -> None:
        report = build_report(
            repo_root=pathlib.Path("/tmp/browser"),
            saved_archives_root=pathlib.Path("/tmp/memory/repo_archives/browser"),
            toolchains_root=pathlib.Path("/tmp/toolchains"),
            offline_deps_root=pathlib.Path("/tmp/offline-deps"),
            fallback_zig_archive=None,
            staged_candidate_report=None,
            staged_candidate_warning=None,
            saved_archive_report={
                "preferred_archive": {
                    "path": "/tmp/memory/repo_archives/browser/dependencies/01-rust-1.79.0-x86_64-unknown-linux-gnu.tar.xz"
                },
                "commands": {
                    "restore_check": "bash /tmp/browser/scripts/linux/restore_saved_rust_toolchain.sh --check-only"
                },
            },
            saved_archive_warning=None,
        )

        self.assertEqual(report["status"], "failed")
        self.assertEqual(report["preferred_action"], "restore-saved-archive")
        self.assertIn("restore_saved_rust_toolchain.sh", report["next_command"])

    def test_build_report_blocks_when_no_rust_route_is_ready(self) -> None:
        report = build_report(
            repo_root=pathlib.Path("/tmp/browser"),
            saved_archives_root=pathlib.Path("/tmp/memory/repo_archives/browser"),
            toolchains_root=pathlib.Path("/tmp/toolchains"),
            offline_deps_root=pathlib.Path("/tmp/offline-deps"),
            fallback_zig_archive=None,
            staged_candidate_report=None,
            staged_candidate_warning=None,
            saved_archive_report=None,
            saved_archive_warning="saved Rust archive helper produced no JSON output",
        )

        self.assertEqual(report["status"], "failed")
        self.assertEqual(report["preferred_action"], "blocked")
        self.assertIn("show_issue3_saved_rust_toolchain_route.sh", report["next_command"])
        self.assertIn("saved Rust archive helper produced no JSON output", report["failures"])

    def test_resolve_default_fallback_zig_archive_uses_agent_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = pathlib.Path(tmpdir)
            repo_root = root / "browser"
            agent_files_root = root / "agent_files"
            repo_root.mkdir()
            agent_files_root.mkdir()
            archive_path = agent_files_root / DEFAULT_FALLBACK_ZIG_ARCHIVE
            archive_path.write_text("zig", encoding="utf-8")

            resolved = resolve_default_fallback_zig_archive(repo_root)

            self.assertEqual(resolved, archive_path.resolve())


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(RustToolchainPlanTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = pathlib.Path(args.repo_root).resolve()
    saved_archives_root = (
        pathlib.Path(args.saved_archives_root).resolve()
        if args.saved_archives_root
        else resolve_default_saved_archives_root(repo_root)
    )
    toolchains_root = (
        pathlib.Path(args.toolchains_root).resolve()
        if args.toolchains_root
        else resolve_default_toolchains_root(repo_root)
    )
    offline_deps_root = (
        pathlib.Path(args.offline_deps_root).resolve()
        if args.offline_deps_root
        else resolve_default_offline_deps_root(repo_root)
    )
    fallback_zig_archive = (
        pathlib.Path(args.fallback_zig_archive).resolve()
        if args.fallback_zig_archive
        else resolve_default_fallback_zig_archive(repo_root)
    )

    staged_candidate_report, staged_candidate_warning = load_staged_candidate_report(
        repo_root,
        toolchains_root,
    )
    saved_archive_report, saved_archive_warning = load_saved_archive_report(
        repo_root,
        saved_archives_root,
        toolchains_root,
    )

    report = build_report(
        repo_root=repo_root,
        saved_archives_root=saved_archives_root,
        toolchains_root=toolchains_root,
        offline_deps_root=offline_deps_root,
        fallback_zig_archive=fallback_zig_archive,
        staged_candidate_report=staged_candidate_report,
        staged_candidate_warning=staged_candidate_warning,
        saved_archive_report=saved_archive_report,
        saved_archive_warning=saved_archive_warning,
    )

    if args.json:
        print(json.dumps(report, indent=2))
        return 0 if report["status"] == "passed" else 1

    print("Issue #11 Rust toolchain re-entry planner")
    print()
    print(f"Repo root:            {report['repo_root']}")
    print(f"Saved archives root:  {report['saved_archives_root']}")
    print(f"Toolchains root:      {report['toolchains_root']}")
    print(f"Offline deps root:    {report['offline_deps_root']}")
    print(f"Expected Rust line:   {report['expected_rust']}")
    if report["fallback_zig_archive"]:
        print(f"Fallback Zig archive: {report['fallback_zig_archive']}")
    print()
    print(f"Preferred action:     {report['preferred_action']}")
    print(f"Reason:               {report['reason']}")
    print(f"Next command:         {report['next_command']}")

    if report["failures"]:
        print()
        print("Planner notes:")
        for failure in report["failures"]:
            print(f"  - {failure}")

    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main())