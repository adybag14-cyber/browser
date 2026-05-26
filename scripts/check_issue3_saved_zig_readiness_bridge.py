#!/usr/bin/env python3

"""Bridge saved Zig archive discovery to the broader Linux build-readiness lane."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Summarize whether issue #3 Linux/WSL readiness should reuse a staged "
            "Zig toolchain, restore a saved Zig archive, or fall back to the attached bundle."
        )
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help="Optional saved archives root override",
    )
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Optional toolchains root override",
    )
    parser.add_argument(
        "--offline-deps-root",
        default=None,
        help="Optional offline dependency root override",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit fallback Zig archive path",
    )
    parser.add_argument(
        "--expect-offline-deps",
        action="store_true",
        help="Pass through offline dependency checks to the readiness helper",
    )
    parser.add_argument(
        "--require-prebuilt-v8",
        action="store_true",
        help="Require a prebuilt V8 archive when rerunning readiness",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON output")
    parser.add_argument("--self-test", action="store_true", help="Run focused unit tests and exit")
    return parser


def ancestor_chain(start: Path) -> list[Path]:
    chain: list[Path] = []
    current = start.resolve()
    while True:
        chain.append(current)
        if current.parent == current:
            break
        current = current.parent
    return chain


def locate_first_existing(start: Path, relative_path: str) -> Path | None:
    for ancestor in ancestor_chain(start):
        candidate = ancestor / relative_path
        if candidate.exists():
            return candidate.resolve()
    return None


def resolve_default_saved_archives_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "memory/repo_archives/browser")
    if located is not None and located.is_dir():
        return located.resolve()
    return (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()


def resolve_default_toolchains_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "toolchains")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "toolchains").resolve()


def resolve_default_offline_deps_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "offline-deps")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "offline-deps").resolve()


def resolve_default_fallback_zig_archive(repo_root: Path) -> Path | None:
    located = locate_first_existing(repo_root, f"agent_files/{DEFAULT_FALLBACK_ZIG_ARCHIVE}")
    if located is not None and located.is_file():
        return located
    candidate = (repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve()
    return candidate if candidate.is_file() else None


def helper_command(script: Path, *args: str) -> list[str]:
    return [sys.executable, str(script), *args]


def run_json_command(command: list[str]) -> dict[str, object]:
    completed = subprocess.run(command, capture_output=True, text=True)
    stdout = completed.stdout.strip()
    stderr = completed.stderr.strip()

    if not stdout:
        return {
            "status": "failed",
            "command": command,
            "returncode": completed.returncode,
            "stdout": stdout,
            "stderr": stderr,
            "error": "command produced no JSON output",
        }

    try:
        payload = json.loads(stdout)
    except json.JSONDecodeError as exc:
        return {
            "status": "failed",
            "command": command,
            "returncode": completed.returncode,
            "stdout": stdout,
            "stderr": stderr,
            "error": f"invalid JSON output: {exc}",
        }

    if not isinstance(payload, dict):
        return {
            "status": "failed",
            "command": command,
            "returncode": completed.returncode,
            "stdout": stdout,
            "stderr": stderr,
            "error": "JSON output was not an object",
        }

    payload.setdefault("status", "passed" if completed.returncode == 0 else "failed")
    payload["command"] = command
    payload["returncode"] = completed.returncode
    return payload


def build_readiness_command(
    *,
    repo_root: Path,
    saved_archives_root: Path,
    offline_deps_root: Path | None,
    fallback_zig_archive: Path | None,
    expect_offline_deps: bool,
    require_prebuilt_v8: bool,
    zig_path: Path | None = None,
) -> list[str]:
    command = helper_command(
        repo_root / "scripts" / "check_linux_build_readiness.py",
        "--repo-root",
        str(repo_root),
        "--expect-saved-archives",
        "--saved-archives-root",
        str(saved_archives_root),
        "--skip-rust-check",
        "--json",
    )
    if zig_path is not None:
        command.extend(("--zig", str(zig_path)))
    else:
        command.append("--skip-zig-check")
    if expect_offline_deps:
        command.extend(("--expect-offline-deps", "--offline-deps-root", str(offline_deps_root)))
    if require_prebuilt_v8:
        command.append("--require-prebuilt-v8")
    if fallback_zig_archive is not None:
        command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
    return command


def build_saved_zig_command(
    *,
    repo_root: Path,
    saved_archives_root: Path,
    toolchains_root: Path,
    fallback_zig_archive: Path | None,
) -> list[str]:
    command = helper_command(
        repo_root / "scripts" / "check_issue3_saved_zig_archive_candidates.py",
        "--repo-root",
        str(repo_root),
        "--saved-archives-root",
        str(saved_archives_root),
        "--toolchains-root",
        str(toolchains_root),
        "--json",
    )
    if fallback_zig_archive is not None:
        command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
    return command


def build_matching_readiness_rerun_command(
    *,
    repo_root: Path,
    saved_archives_root: Path,
    offline_deps_root: Path | None,
    fallback_zig_archive: Path | None,
    expect_offline_deps: bool,
    require_prebuilt_v8: bool,
    zig_path: str,
) -> list[str]:
    return build_readiness_command(
        repo_root=repo_root,
        saved_archives_root=saved_archives_root,
        offline_deps_root=offline_deps_root,
        fallback_zig_archive=fallback_zig_archive,
        expect_offline_deps=expect_offline_deps,
        require_prebuilt_v8=require_prebuilt_v8,
        zig_path=Path(zig_path),
    )


def determine_next_action(
    *,
    repo_root: Path,
    saved_archives_root: Path,
    toolchains_root: Path,
    offline_deps_root: Path | None,
    fallback_zig_archive: Path | None,
    expect_offline_deps: bool,
    require_prebuilt_v8: bool,
    readiness_report: dict[str, object],
    saved_zig_report: dict[str, object],
) -> dict[str, object]:
    matching_candidates = readiness_report.get("matching_zig_candidates") or []
    if matching_candidates:
        zig_path = str(matching_candidates[0])
        return {
            "kind": "use-staged-zig",
            "summary": (
                "A branch-compatible staged Zig toolchain is already available; rerun the Linux "
                "build-readiness helper with that executable."
            ),
            "commands": [
                build_matching_readiness_rerun_command(
                    repo_root=repo_root,
                    saved_archives_root=saved_archives_root,
                    offline_deps_root=offline_deps_root,
                    fallback_zig_archive=fallback_zig_archive,
                    expect_offline_deps=expect_offline_deps,
                    require_prebuilt_v8=require_prebuilt_v8,
                    zig_path=zig_path,
                )
            ],
        }

    preferred_archive = saved_zig_report.get("preferred_archive")
    saved_commands = saved_zig_report.get("commands") or {}
    if isinstance(preferred_archive, dict) and saved_commands.get("restore"):
        return {
            "kind": "restore-saved-zig",
            "summary": (
                "No staged branch-compatible Zig toolchain is visible yet, but a saved Zig archive "
                "matches the expected line and should be restored first."
            ),
            "commands": [
                [str(saved_commands["restore_check"])],
                [str(saved_commands["restore"])],
            ],
        }

    if fallback_zig_archive is not None and saved_commands.get("fallback_restore"):
        return {
            "kind": "restore-fallback-zig",
            "summary": (
                "No saved branch-compatible Zig archive is visible; only the surfaced fallback "
                "bundle remains available for staging."
            ),
            "commands": [
                [str(saved_commands["fallback_restore_check"])],
                [str(saved_commands["fallback_restore"])],
            ],
        }

    return {
        "kind": "no-zig-route",
        "summary": (
            "Neither a staged matching Zig toolchain nor a saved restore candidate was found. "
            "Inspect the saved Zig archive route before retrying broader readiness."
        ),
        "commands": [build_saved_zig_command(
            repo_root=repo_root,
            saved_archives_root=saved_archives_root,
            toolchains_root=toolchains_root,
            fallback_zig_archive=fallback_zig_archive,
        )],
    }


def serialize(value: object) -> object:
    if isinstance(value, Path):
        return str(value)
    if isinstance(value, dict):
        return {str(key): serialize(inner) for key, inner in value.items()}
    if isinstance(value, list):
        return [serialize(item) for item in value]
    return value


def build_bridge_report(
    *,
    repo_root: Path,
    saved_archives_root: Path,
    toolchains_root: Path,
    offline_deps_root: Path | None,
    fallback_zig_archive: Path | None,
    expect_offline_deps: bool,
    require_prebuilt_v8: bool,
) -> dict[str, object]:
    readiness_command = build_readiness_command(
        repo_root=repo_root,
        saved_archives_root=saved_archives_root,
        offline_deps_root=offline_deps_root,
        fallback_zig_archive=fallback_zig_archive,
        expect_offline_deps=expect_offline_deps,
        require_prebuilt_v8=require_prebuilt_v8,
    )
    saved_zig_command = build_saved_zig_command(
        repo_root=repo_root,
        saved_archives_root=saved_archives_root,
        toolchains_root=toolchains_root,
        fallback_zig_archive=fallback_zig_archive,
    )

    readiness_report = run_json_command(readiness_command)
    saved_zig_report = run_json_command(saved_zig_command)
    next_action = determine_next_action(
        repo_root=repo_root,
        saved_archives_root=saved_archives_root,
        toolchains_root=toolchains_root,
        offline_deps_root=offline_deps_root,
        fallback_zig_archive=fallback_zig_archive,
        expect_offline_deps=expect_offline_deps,
        require_prebuilt_v8=require_prebuilt_v8,
        readiness_report=readiness_report,
        saved_zig_report=saved_zig_report,
    )

    status = "passed" if next_action["kind"] == "use-staged-zig" else "failed"
    return {
        "status": status,
        "repo_root": repo_root,
        "saved_archives_root": saved_archives_root,
        "toolchains_root": toolchains_root,
        "offline_deps_root": offline_deps_root,
        "fallback_zig_archive": fallback_zig_archive,
        "expect_offline_deps": expect_offline_deps,
        "require_prebuilt_v8": require_prebuilt_v8,
        "readiness_report": readiness_report,
        "saved_zig_report": saved_zig_report,
        "next_action": next_action,
    }


def print_human_report(report: dict[str, object]) -> None:
    print("Issue #3 saved Zig readiness bridge")
    print(f"Repo root:            {report['repo_root']}")
    print(f"Saved archives root:  {report['saved_archives_root']}")
    print(f"Toolchains root:      {report['toolchains_root']}")
    print(f"Fallback Zig archive: {report['fallback_zig_archive'] or 'not found'}")
    print()
    print(report["next_action"]["summary"])
    print()
    print("Suggested command(s):")
    for command in report["next_action"]["commands"]:
        if len(command) == 1:
            print(f"  {command[0]}")
        else:
            print("  " + " ".join(str(part) for part in command))


class SavedZigReadinessBridgeTests(unittest.TestCase):
    def test_run_json_command_accepts_nonzero_json_payload(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            script = Path(tmpdir) / "payload.py"
            script.write_text(
                "import json, sys\n"
                "print(json.dumps({'status': 'failed', 'preferred_archive': None}))\n"
                "sys.exit(1)\n",
                encoding="utf-8",
            )
            result = run_json_command([sys.executable, str(script)])
            self.assertEqual(result["status"], "failed")
            self.assertEqual(result["returncode"], 1)
            self.assertIn("preferred_archive", result)

    def test_determine_next_action_prefers_staged_candidate(self) -> None:
        action = determine_next_action(
            repo_root=Path("/tmp/browser"),
            saved_archives_root=Path("/tmp/memory/repo_archives/browser"),
            toolchains_root=Path("/tmp/toolchains"),
            offline_deps_root=Path("/tmp/offline-deps"),
            fallback_zig_archive=Path("/tmp/agent_files/fallback.tar.xz"),
            expect_offline_deps=True,
            require_prebuilt_v8=True,
            readiness_report={"matching_zig_candidates": ["/tmp/toolchains/zig-0.15.7/zig"]},
            saved_zig_report={
                "preferred_archive": {"path": "/tmp/memory/repo_archives/browser/zig-0.15.2.tar.xz"},
                "commands": {"restore": "restore"},
            },
        )
        self.assertEqual(action["kind"], "use-staged-zig")
        self.assertIn("--zig", action["commands"][0])

    def test_determine_next_action_uses_saved_archive_when_no_staged_match(self) -> None:
        action = determine_next_action(
            repo_root=Path("/tmp/browser"),
            saved_archives_root=Path("/tmp/memory/repo_archives/browser"),
            toolchains_root=Path("/tmp/toolchains"),
            offline_deps_root=None,
            fallback_zig_archive=Path("/tmp/agent_files/fallback.tar.xz"),
            expect_offline_deps=False,
            require_prebuilt_v8=False,
            readiness_report={"matching_zig_candidates": []},
            saved_zig_report={
                "preferred_archive": {"path": "/tmp/memory/repo_archives/browser/zig-0.15.2.tar.xz"},
                "commands": {
                    "restore_check": "bash restore --check-only",
                    "restore": "bash restore",
                },
            },
        )
        self.assertEqual(action["kind"], "restore-saved-zig")
        self.assertEqual(action["commands"][0][0], "bash restore --check-only")

    def test_determine_next_action_falls_back_when_only_fallback_exists(self) -> None:
        action = determine_next_action(
            repo_root=Path("/tmp/browser"),
            saved_archives_root=Path("/tmp/memory/repo_archives/browser"),
            toolchains_root=Path("/tmp/toolchains"),
            offline_deps_root=None,
            fallback_zig_archive=Path("/tmp/agent_files/fallback.tar.xz"),
            expect_offline_deps=False,
            require_prebuilt_v8=False,
            readiness_report={"matching_zig_candidates": []},
            saved_zig_report={
                "preferred_archive": None,
                "commands": {
                    "fallback_restore_check": "bash fallback --check-only",
                    "fallback_restore": "bash fallback",
                },
            },
        )
        self.assertEqual(action["kind"], "restore-fallback-zig")
        self.assertEqual(action["commands"][1][0], "bash fallback")

    def test_default_roots_discover_ancestor_workspace_layout(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            workspace_root = Path(tmpdir)
            repo_root = workspace_root / "restored" / "browser-memory-snapshot" / "browser"
            repo_root.mkdir(parents=True)
            (workspace_root / "memory" / "repo_archives" / "browser").mkdir(parents=True)
            (workspace_root / "toolchains").mkdir()
            (workspace_root / "offline-deps").mkdir()
            agent_files = workspace_root / "agent_files"
            agent_files.mkdir()
            fallback_archive = agent_files / DEFAULT_FALLBACK_ZIG_ARCHIVE
            fallback_archive.write_text("zig", encoding="utf-8")

            self.assertEqual(
                resolve_default_saved_archives_root(repo_root),
                (workspace_root / "memory" / "repo_archives" / "browser").resolve(),
            )
            self.assertEqual(
                resolve_default_toolchains_root(repo_root),
                (workspace_root / "toolchains").resolve(),
            )
            self.assertEqual(
                resolve_default_offline_deps_root(repo_root),
                (workspace_root / "offline-deps").resolve(),
            )
            self.assertEqual(resolve_default_fallback_zig_archive(repo_root), fallback_archive.resolve())


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(SavedZigReadinessBridgeTests)
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
    fallback_zig_archive = (
        Path(args.fallback_zig_archive).resolve()
        if args.fallback_zig_archive
        else resolve_default_fallback_zig_archive(repo_root)
    )

    report = build_bridge_report(
        repo_root=repo_root,
        saved_archives_root=saved_archives_root,
        toolchains_root=toolchains_root,
        offline_deps_root=offline_deps_root,
        fallback_zig_archive=fallback_zig_archive,
        expect_offline_deps=args.expect_offline_deps,
        require_prebuilt_v8=args.require_prebuilt_v8,
    )

    if args.json:
        print(json.dumps(serialize(report), indent=2, sort_keys=True))
    else:
        print_human_report(serialize(report))
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
