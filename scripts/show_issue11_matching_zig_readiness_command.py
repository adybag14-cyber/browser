#!/usr/bin/env python3

"""Print the exact Linux build-readiness rerun command for a matching Zig toolchain.

This helper is intentionally narrow for issue #11 automation:
- reuse `scripts/check_linux_build_readiness.py --json`
- find the first staged Zig candidate that matches the branch's expected line
- print one exact rerun command that points the readiness helper at that candidate
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


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Print the exact check_linux_build_readiness.py rerun command for the "
            "first staged Zig candidate that matches the branch's expected line."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to the browser checkout root (default: current directory)",
    )
    parser.add_argument(
        "--toolchains-root",
        default=None,
        help="Path to the staged Zig toolchains root (default: ../toolchains beside the repo)",
    )
    parser.add_argument(
        "--saved-archives-root",
        default=None,
        help=(
            "Path to the saved archive root (default: ../memory/repo_archives/browser "
            "beside the repo workspace; either that root or its dependencies "
            "subdirectory is accepted)"
        ),
    )
    parser.add_argument(
        "--offline-deps-root",
        default=None,
        help="Path to the offline dependency root (default: ../offline-deps beside the repo)",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit path to the surfaced fallback Zig archive",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit the selected command and candidate details as JSON",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run focused helper tests and exit",
    )
    return parser


def format_shell_command(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def resolve_default_toolchains_root(repo_root: Path) -> Path:
    return (repo_root.parent / "toolchains").resolve()


def resolve_default_saved_archives_root(repo_root: Path) -> Path:
    return (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()


def resolve_default_offline_deps_root(repo_root: Path) -> Path:
    return (repo_root.parent / "offline-deps").resolve()


def run_readiness_discovery(
    *,
    repo_root: Path,
    toolchains_root: Path,
    saved_archives_root: Path,
    offline_deps_root: Path,
    fallback_zig_archive: Path | None,
) -> dict[str, object]:
    readiness_script = repo_root / "scripts" / "check_linux_build_readiness.py"
    command = [
        sys.executable,
        str(readiness_script),
        "--repo-root",
        str(repo_root),
        "--skip-zig-check",
        "--skip-rust-check",
        "--expect-saved-archives",
        "--saved-archives-root",
        str(saved_archives_root),
        "--toolchains-root",
        str(toolchains_root),
        "--expect-offline-deps",
        "--offline-deps-root",
        str(offline_deps_root),
        "--require-prebuilt-v8",
        "--json",
    ]
    if fallback_zig_archive is not None:
        command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))

    completed = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
    )

    if completed.stdout.strip():
        try:
            payload = json.loads(completed.stdout)
        except json.JSONDecodeError as exc:
            raise RuntimeError(
                "check_linux_build_readiness.py did not return valid JSON"
            ) from exc
    else:
        payload = {}

    payload["_discovery_command"] = command
    payload["_discovery_returncode"] = completed.returncode
    payload["_discovery_stderr"] = completed.stderr.strip()
    return payload


def build_matching_readiness_command(
    *,
    repo_root: Path,
    toolchains_root: Path,
    saved_archives_root: Path,
    offline_deps_root: Path,
    fallback_zig_archive: Path | None,
    matching_candidate: str,
) -> list[str]:
    readiness_script = repo_root / "scripts" / "check_linux_build_readiness.py"
    command = [
        sys.executable,
        str(readiness_script),
        "--repo-root",
        str(repo_root),
        "--zig",
        matching_candidate,
        "--expect-saved-archives",
        "--saved-archives-root",
        str(saved_archives_root),
        "--expect-offline-deps",
        "--offline-deps-root",
        str(offline_deps_root),
        "--require-prebuilt-v8",
        "--toolchains-root",
        str(toolchains_root),
    ]
    if fallback_zig_archive is not None:
        command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))
    return command


def select_matching_candidate(payload: dict[str, object]) -> dict[str, object] | None:
    for candidate in payload.get("zig_candidates", []):
        if isinstance(candidate, dict) and str(candidate.get("status", "")).startswith(
            "matches expected"
        ):
            return candidate
    return None


def build_result(
    *,
    repo_root: Path,
    toolchains_root: Path,
    saved_archives_root: Path,
    offline_deps_root: Path,
    fallback_zig_archive: Path | None,
    payload: dict[str, object],
) -> dict[str, object]:
    selected = select_matching_candidate(payload)
    failures = list(payload.get("failures", [])) if isinstance(payload.get("failures"), list) else []

    result: dict[str, object] = {
        "repo_root": str(repo_root),
        "toolchains_root": str(toolchains_root),
        "saved_archives_root": str(saved_archives_root),
        "offline_deps_root": str(offline_deps_root),
        "fallback_zig_archive": str(fallback_zig_archive) if fallback_zig_archive else None,
        "minimum_zig": payload.get("minimum_zig"),
        "selected_candidate": None,
        "command": None,
        "discovery_command": format_shell_command(
            [str(part) for part in payload.get("_discovery_command", [])]
        ),
        "discovery_returncode": payload.get("_discovery_returncode"),
        "discovery_failures": failures,
        "discovery_stderr": payload.get("_discovery_stderr"),
    }

    if selected is None:
        return result

    matching_command = build_matching_readiness_command(
        repo_root=repo_root,
        toolchains_root=toolchains_root,
        saved_archives_root=saved_archives_root,
        offline_deps_root=offline_deps_root,
        fallback_zig_archive=fallback_zig_archive,
        matching_candidate=str(selected["path"]),
    )
    result["selected_candidate"] = {
        "path": selected.get("path"),
        "version": selected.get("version"),
        "status": selected.get("status"),
    }
    result["command"] = format_shell_command(matching_command)
    return result


def emit_text(result: dict[str, object]) -> int:
    print(f"Repo root: {result['repo_root']}")
    print(f"Toolchains root: {result['toolchains_root']}")
    print(f"Saved archives root: {result['saved_archives_root']}")
    print(f"Offline deps root: {result['offline_deps_root']}")
    if result["fallback_zig_archive"] is not None:
        print(f"Fallback Zig archive: {result['fallback_zig_archive']}")
    print(f"Discovery command: {result['discovery_command']}")

    selected = result["selected_candidate"]
    if selected is None:
        print()
        print("No branch-compatible Zig candidate is currently staged.")
        print("Run the discovery command above, then stage a Zig candidate on the branch's expected line before rerunning this helper.")
        if result["discovery_failures"]:
            print("Discovery failures:")
            for failure in result["discovery_failures"]:
                print(f"  - {failure}")
        return 1

    print()
    print(
        "Selected candidate: "
        f"{selected['path']} [{selected['version']}; {selected['status']}]"
    )
    print("Matching readiness command:")
    print(f"  {result['command']}")
    return 0


class MatchingZigCommandTests(unittest.TestCase):
    def test_select_matching_candidate_prefers_first_match(self) -> None:
        payload = {
            "zig_candidates": [
                {"path": "/tmp/zig-0.17/zig", "version": "0.17.0", "status": "mismatched: expected 0.15.x line"},
                {"path": "/tmp/zig-0.15/zig", "version": "0.15.7", "status": "matches expected 0.15.x line"},
                {"path": "/tmp/zig-0.15b/zig", "version": "0.15.8", "status": "matches expected 0.15.x line"},
            ]
        }
        selected = select_matching_candidate(payload)
        self.assertIsNotNone(selected)
        self.assertEqual(selected["path"], "/tmp/zig-0.15/zig")

    def test_build_matching_readiness_command_threads_paths(self) -> None:
        command = build_matching_readiness_command(
            repo_root=Path("/tmp/browser"),
            toolchains_root=Path("/tmp/toolchains"),
            saved_archives_root=Path("/tmp/memory/repo_archives/browser/dependencies"),
            offline_deps_root=Path("/tmp/offline-deps"),
            fallback_zig_archive=Path("/tmp/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"),
            matching_candidate="/tmp/toolchains/zig-0.15.7/zig",
        )
        rendered = format_shell_command(command)
        self.assertIn("--zig /tmp/toolchains/zig-0.15.7/zig", rendered)
        self.assertIn("--saved-archives-root /tmp/memory/repo_archives/browser/dependencies", rendered)
        self.assertIn("--offline-deps-root /tmp/offline-deps", rendered)
        self.assertIn("--require-prebuilt-v8", rendered)
        self.assertIn("--fallback-zig-archive /tmp/agent_files/zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz", rendered)

    def test_build_result_returns_command_for_matching_candidate(self) -> None:
        payload = {
            "minimum_zig": "0.15.2",
            "zig_candidates": [
                {"path": "/tmp/toolchains/zig-0.15.7/zig", "version": "0.15.7", "status": "matches expected 0.15.x line"}
            ],
            "_discovery_command": ["python", "scripts/check_linux_build_readiness.py", "--json"],
            "_discovery_returncode": 1,
            "_discovery_stderr": "",
            "failures": ["offline dependency root is missing"],
        }
        result = build_result(
            repo_root=Path("/tmp/browser"),
            toolchains_root=Path("/tmp/toolchains"),
            saved_archives_root=Path("/tmp/memory/repo_archives/browser/dependencies"),
            offline_deps_root=Path("/tmp/offline-deps"),
            fallback_zig_archive=None,
            payload=payload,
        )
        self.assertEqual(result["minimum_zig"], "0.15.2")
        self.assertIsNotNone(result["selected_candidate"])
        self.assertIn("--zig /tmp/toolchains/zig-0.15.7/zig", result["command"])
        self.assertEqual(result["discovery_failures"], ["offline dependency root is missing"])

    def test_build_result_reports_no_match_cleanly(self) -> None:
        payload = {
            "minimum_zig": "0.15.2",
            "zig_candidates": [
                {"path": "/tmp/toolchains/zig-0.17.0/zig", "version": "0.17.0", "status": "mismatched: expected 0.15.x line"}
            ],
            "_discovery_command": ["python", "scripts/check_linux_build_readiness.py", "--json"],
            "_discovery_returncode": 1,
            "_discovery_stderr": "",
            "failures": [],
        }
        result = build_result(
            repo_root=Path("/tmp/browser"),
            toolchains_root=Path("/tmp/toolchains"),
            saved_archives_root=Path("/tmp/memory/repo_archives/browser/dependencies"),
            offline_deps_root=Path("/tmp/offline-deps"),
            fallback_zig_archive=None,
            payload=payload,
        )
        self.assertIsNone(result["selected_candidate"])
        self.assertIsNone(result["command"])

    def test_json_contract_from_realistic_payload(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            payload = {
                "minimum_zig": "0.15.2",
                "zig_candidates": [
                    {"path": str(root / "toolchains" / "zig-0.15.7" / "zig"), "version": "0.15.7", "status": "matches expected 0.15.x line"}
                ],
                "_discovery_command": ["python", "scripts/check_linux_build_readiness.py", "--json"],
                "_discovery_returncode": 0,
                "_discovery_stderr": "",
                "failures": [],
            }
            result = build_result(
                repo_root=root / "browser",
                toolchains_root=root / "toolchains",
                saved_archives_root=root / "memory" / "repo_archives" / "browser" / "dependencies",
                offline_deps_root=root / "offline-deps",
                fallback_zig_archive=root / "agent_files" / "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz",
                payload=payload,
            )
            rendered = json.dumps(result)
            self.assertIn("selected_candidate", rendered)
            self.assertIn("command", rendered)


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(MatchingZigCommandTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    toolchains_root = (
        Path(args.toolchains_root).resolve()
        if args.toolchains_root
        else resolve_default_toolchains_root(repo_root)
    )
    saved_archives_root = (
        Path(args.saved_archives_root).resolve()
        if args.saved_archives_root
        else resolve_default_saved_archives_root(repo_root)
    )
    offline_deps_root = (
        Path(args.offline_deps_root).resolve()
        if args.offline_deps_root
        else resolve_default_offline_deps_root(repo_root)
    )
    fallback_zig_archive = (
        Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None
    )

    payload = run_readiness_discovery(
        repo_root=repo_root,
        toolchains_root=toolchains_root,
        saved_archives_root=saved_archives_root,
        offline_deps_root=offline_deps_root,
        fallback_zig_archive=fallback_zig_archive,
    )
    result = build_result(
        repo_root=repo_root,
        toolchains_root=toolchains_root,
        saved_archives_root=saved_archives_root,
        offline_deps_root=offline_deps_root,
        fallback_zig_archive=fallback_zig_archive,
        payload=payload,
    )

    if args.json:
        print(json.dumps(result, indent=2))
        return 0 if result["selected_candidate"] is not None else 1
    return emit_text(result)


if __name__ == "__main__":
    sys.exit(main())
