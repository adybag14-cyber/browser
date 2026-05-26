#!/usr/bin/env python3

"""Summarize which issue #11 re-entry gate is currently blocking issue #3.

This helper stays intentionally create-only and shells out to the existing
branch-local route helpers when they are present. It gives future runs one
compact answer about:
- which Linux/WSL re-entry gates already pass
- which gate is the first failing blocker right now
- which branch-local route should be run next
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


DEFAULT_FALLBACK_ZIG_ARCHIVE = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"
DEFAULT_RESTORED_CHECKOUT_NAME = "browser-memory-snapshot"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Summarize issue #11 Linux/WSL re-entry gate status for issue #3."
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser repo root")
    parser.add_argument(
        "--helper-root",
        default=None,
        help="Optional live helper root when summarizing a restored checkout",
    )
    parser.add_argument(
        "--memory-root",
        default=None,
        help="Optional memory root override (default: nearest ancestor memory or ../memory)",
    )
    parser.add_argument(
        "--restored-checkout-root",
        default=None,
        help="Optional restored checkout root override",
    )
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


def resolve_default_memory_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "memory")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "memory").resolve()


def resolve_default_toolchains_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "toolchains")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "toolchains").resolve()


def resolve_default_saved_archives_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "memory/repo_archives/browser")
    if located is not None and located.is_dir():
        if (located / "dependencies").is_dir():
            return (located / "dependencies").resolve()
        return located.resolve()
    fallback = (repo_root.parent / "memory" / "repo_archives" / "browser").resolve()
    if (fallback / "dependencies").is_dir():
        return (fallback / "dependencies").resolve()
    return fallback


def resolve_default_restored_checkout_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, DEFAULT_RESTORED_CHECKOUT_NAME)
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / DEFAULT_RESTORED_CHECKOUT_NAME).resolve()


def resolve_default_offline_deps_root(repo_root: Path) -> Path:
    located = locate_first_existing(repo_root, "offline-deps")
    if located is not None and located.is_dir():
        return located
    return (repo_root.parent / "offline-deps").resolve()


def resolve_default_helper_root(repo_root: Path) -> Path:
    return repo_root.resolve()


def resolve_default_fallback_zig_archive(repo_root: Path) -> Path | None:
    located = locate_first_existing(repo_root, f"agent_files/{DEFAULT_FALLBACK_ZIG_ARCHIVE}")
    if located is not None and located.is_file():
        return located
    candidate = (repo_root.parent / "agent_files" / DEFAULT_FALLBACK_ZIG_ARCHIVE).resolve()
    if candidate.is_file():
        return candidate
    return None


def serialize(value: object) -> object:
    if isinstance(value, Path):
        return str(value)
    if isinstance(value, dict):
        return {str(key): serialize(inner) for key, inner in value.items()}
    if isinstance(value, list):
        return [serialize(item) for item in value]
    return value


def route_command(script: Path, *args: str) -> list[str]:
    return ["bash", str(script), *args]


def helper_command(script: Path, *args: str) -> list[str]:
    return [sys.executable, str(script), *args]


def run_json_command(command: list[str]) -> dict[str, object]:
    completed = subprocess.run(command, capture_output=True, text=True)
    stdout = completed.stdout.strip()
    stderr = completed.stderr.strip()
    if completed.returncode != 0:
        return {
            "status": "failed",
            "command": command,
            "returncode": completed.returncode,
            "stdout": stdout,
            "stderr": stderr,
            "error": "command failed",
        }

    try:
        payload = json.loads(stdout) if stdout else {}
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

    payload.setdefault("status", "passed")
    payload["command"] = command
    payload["returncode"] = completed.returncode
    return payload


def stage_result(
    *,
    stage_id: str,
    label: str,
    route: str,
    command: list[str],
    result: dict[str, object],
) -> dict[str, object]:
    status = str(result.get("status", "failed"))
    if status not in {"passed", "failed"}:
        status = "failed"
    return {
        "stage_id": stage_id,
        "label": label,
        "route": route,
        "status": status,
        "command": command,
        "result": result,
    }


def choose_next_stage(stages: list[dict[str, object]]) -> dict[str, object] | None:
    for stage in stages:
        if stage["status"] != "passed":
            return stage
    return None


def build_status_summary(
    *,
    repo_root: Path,
    helper_root: Path,
    memory_root: Path,
    restored_checkout_root: Path,
    saved_archives_root: Path,
    toolchains_root: Path,
    offline_deps_root: Path,
    fallback_zig_archive: Path | None,
) -> dict[str, object]:
    saved_memory_inputs_cmd = helper_command(
        helper_root / "scripts/check_issue3_saved_memory_inputs.py",
        "--repo-root",
        str(repo_root),
        "--json",
    )
    if fallback_zig_archive is not None:
        saved_memory_inputs_cmd.extend(("--fallback-zig-archive", str(fallback_zig_archive)))

    saved_archive_integrity_cmd = helper_command(
        helper_root / "scripts/check_issue3_saved_archive_integrity.py",
        "--repo-root",
        str(repo_root),
        "--json",
    )
    if fallback_zig_archive is not None:
        saved_archive_integrity_cmd.extend(("--fallback-zig-archive", str(fallback_zig_archive)))

    restored_checkout_cmd = helper_command(
        helper_root / "scripts/check_issue3_restored_checkout.py",
        "--repo-root",
        str(restored_checkout_root),
        "--helper-root",
        str(helper_root),
        "--expect-helper-surface",
        "--json",
    )

    staged_rust_cmd = helper_command(
        helper_root / "scripts/check_issue3_staged_rust_toolchain_candidates.py",
        "--repo-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
        "--json",
    )

    offline_inputs_cmd = helper_command(
        helper_root / "scripts/check_linux_build_readiness.py",
        "--repo-root",
        str(repo_root),
        "--skip-zig-check",
        "--skip-rust-check",
        "--expect-saved-archives",
        "--saved-archives-root",
        str(saved_archives_root),
        "--expect-offline-deps",
        "--offline-deps-root",
        str(offline_deps_root),
        "--require-prebuilt-v8",
        "--json",
    )
    if fallback_zig_archive is not None:
        offline_inputs_cmd.extend(("--fallback-zig-archive", str(fallback_zig_archive)))

    staged_zig_cmd = helper_command(
        helper_root / "scripts/check_issue3_staged_zig_toolchain_candidates.py",
        "--repo-root",
        str(repo_root),
        "--toolchains-root",
        str(toolchains_root),
        "--json",
    )

    full_readiness_cmd = helper_command(
        helper_root / "scripts/check_linux_build_readiness.py",
        "--repo-root",
        str(repo_root),
        "--expect-saved-archives",
        "--saved-archives-root",
        str(saved_archives_root),
        "--expect-offline-deps",
        "--offline-deps-root",
        str(offline_deps_root),
        "--require-prebuilt-v8",
        "--json",
    )
    if fallback_zig_archive is not None:
        full_readiness_cmd.extend(("--fallback-zig-archive", str(fallback_zig_archive)))

    stages = [
        stage_result(
            stage_id="saved-memory-inputs",
            label="Saved Memory inputs",
            route="saved-memory inputs route",
            command=saved_memory_inputs_cmd,
            result=run_json_command(saved_memory_inputs_cmd),
        ),
        stage_result(
            stage_id="saved-archive-integrity",
            label="Saved archive integrity",
            route="saved-archive integrity route",
            command=saved_archive_integrity_cmd,
            result=run_json_command(saved_archive_integrity_cmd),
        ),
    ]

    if restored_checkout_root.exists():
        stages.append(
            stage_result(
                stage_id="restored-checkout",
                label="Restored checkout readiness",
                route="restored-checkout re-entry route",
                command=restored_checkout_cmd,
                result=run_json_command(restored_checkout_cmd),
            )
        )
    else:
        stages.append(
            {
                "stage_id": "restored-checkout",
                "label": "Restored checkout readiness",
                "route": "saved-browser snapshot route",
                "status": "failed",
                "command": route_command(
                    helper_root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
                    "--repo-root",
                    str(repo_root),
                    "--memory-root",
                    str(memory_root),
                    "--destination",
                    str(restored_checkout_root),
                    "--sync-helper-surface",
                ),
                "result": {
                    "status": "failed",
                    "error": f"restored checkout root does not exist: {restored_checkout_root}",
                },
            }
        )

    stages.extend(
        [
            stage_result(
                stage_id="staged-rust",
                label="Staged Rust toolchain",
                route="saved Rust toolchain route",
                command=staged_rust_cmd,
                result=run_json_command(staged_rust_cmd),
            ),
            stage_result(
                stage_id="offline-inputs",
                label="Offline build inputs",
                route="offline build inputs route",
                command=offline_inputs_cmd,
                result=run_json_command(offline_inputs_cmd),
            ),
            stage_result(
                stage_id="staged-zig",
                label="Staged Zig toolchain",
                route="Zig toolchain recovery route",
                command=staged_zig_cmd,
                result=run_json_command(staged_zig_cmd),
            ),
            stage_result(
                stage_id="linux-build-readiness",
                label="Linux build readiness",
                route="Linux build-readiness route",
                command=full_readiness_cmd,
                result=run_json_command(full_readiness_cmd),
            ),
        ]
    )

    next_stage = choose_next_stage(stages)
    next_route_command = None
    if next_stage is not None:
        stage_id = str(next_stage["stage_id"])
        if stage_id == "saved-memory-inputs":
            next_route_command = route_command(
                helper_root / "scripts/linux/show_issue3_saved_memory_inputs_route.sh",
                "--repo-root",
                str(repo_root),
                "--helper-root",
                str(helper_root),
                "--memory-root",
                str(memory_root),
                "--restored-checkout-root",
                str(restored_checkout_root),
            )
        elif stage_id == "saved-archive-integrity":
            next_route_command = route_command(
                helper_root / "scripts/linux/show_issue3_saved_archive_integrity_route.sh",
                "--repo-root",
                str(repo_root),
                "--memory-root",
                str(memory_root),
            )
        elif stage_id == "restored-checkout":
            if restored_checkout_root.exists():
                next_route_command = route_command(
                    helper_root / "scripts/linux/show_issue3_restored_checkout_reentry_route.sh",
                    "--repo-root",
                    str(repo_root),
                    "--helper-root",
                    str(helper_root),
                    "--memory-root",
                    str(memory_root),
                    "--restored-checkout-root",
                    str(restored_checkout_root),
                )
            else:
                next_route_command = route_command(
                    helper_root / "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
                    "--repo-root",
                    str(repo_root),
                    "--memory-root",
                    str(memory_root),
                    "--destination",
                    str(restored_checkout_root),
                    "--sync-helper-surface",
                )
        elif stage_id == "staged-rust":
            next_route_command = route_command(
                helper_root / "scripts/linux/show_issue3_saved_rust_toolchain_route.sh",
                "--browser-root",
                str(repo_root),
                "--dependencies-root",
                str(saved_archives_root),
                "--toolchain-root",
                str((toolchains_root / "rust-1.79.0").resolve()),
            )
        elif stage_id == "offline-inputs":
            next_route_command = route_command(
                helper_root / "scripts/linux/show_issue3_offline_build_inputs_route.sh",
                "--repo-root",
                str(repo_root),
                "--saved-archives-root",
                str(saved_archives_root),
                "--offline-deps-root",
                str(offline_deps_root),
            )
        elif stage_id == "staged-zig":
            next_route_command = route_command(
                helper_root / "scripts/linux/show_issue3_zig_toolchain_recovery_route.sh",
                "--repo-root",
                str(repo_root),
                "--toolchains-root",
                str(toolchains_root),
                "--saved-archives-root",
                str(saved_archives_root),
                "--offline-deps-root",
                str(offline_deps_root),
            )
        else:
            next_route_command = route_command(
                helper_root / "scripts/linux/show_issue3_linux_build_readiness_route.sh",
                "--repo-root",
                str(repo_root),
                "--memory-root",
                str(memory_root),
                "--restored-checkout-root",
                str(restored_checkout_root),
                "--saved-archives-root",
                str(saved_archives_root),
                "--rust-toolchain-dir",
                str((toolchains_root / "rust-1.79.0").resolve()),
                "--offline-deps-root",
                str(offline_deps_root),
            )
        if fallback_zig_archive is not None:
            next_route_command.extend(("--fallback-zig-archive", str(fallback_zig_archive)))

    return {
        "status": "passed" if next_stage is None else "failed",
        "repo_root": repo_root,
        "helper_root": helper_root,
        "memory_root": memory_root,
        "restored_checkout_root": restored_checkout_root,
        "saved_archives_root": saved_archives_root,
        "toolchains_root": toolchains_root,
        "offline_deps_root": offline_deps_root,
        "fallback_zig_archive": fallback_zig_archive,
        "stages": stages,
        "next_blocker": next_stage,
        "next_route_command": next_route_command,
        "success_note": (
            "all Linux/WSL re-entry gates passed; the next honest step is the Windows runtime handoff"
            if next_stage is None
            else None
        ),
    }


def print_human_report(summary: dict[str, object]) -> None:
    print("Issue #11 re-entry gate summary")
    print(f"Repo root: {summary['repo_root']}")
    print(f"Helper root: {summary['helper_root']}")
    print("")
    for stage in summary["stages"]:
        marker = "PASS" if stage["status"] == "passed" else "FAIL"
        print(f"[{marker}] {stage['label']}")
    print("")
    next_blocker = summary.get("next_blocker")
    if next_blocker is None:
        print("All Linux/WSL re-entry gates passed.")
        print("Next step: Windows runtime handoff for the direct issue #3 replay.")
        return
    print(f"Next blocker: {next_blocker['label']}")
    print(f"Route: {next_blocker['route']}")
    next_route_command = summary.get("next_route_command")
    if next_route_command:
        print("Suggested command:")
        print("  " + " ".join(str(part) for part in next_route_command))


class ReentryGateStatusTests(unittest.TestCase):
    def test_choose_next_stage_returns_first_failure(self) -> None:
        stages = [
            {"status": "passed", "label": "A"},
            {"status": "failed", "label": "B"},
            {"status": "failed", "label": "C"},
        ]
        self.assertEqual(choose_next_stage(stages), stages[1])

    def test_choose_next_stage_returns_none_when_all_pass(self) -> None:
        stages = [{"status": "passed"}, {"status": "passed"}]
        self.assertIsNone(choose_next_stage(stages))

    def test_run_json_command_captures_failure(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            script = Path(tmpdir) / "bad.py"
            script.write_text("import sys\nprint('oops')\nsys.exit(2)\n", encoding="utf-8")
            result = run_json_command([sys.executable, str(script)])
            self.assertEqual(result["status"], "failed")
            self.assertEqual(result["returncode"], 2)

    def test_run_json_command_parses_object_payload(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            script = Path(tmpdir) / "ok.py"
            script.write_text("import json\nprint(json.dumps({'status': 'passed', 'value': 3}))\n", encoding="utf-8")
            result = run_json_command([sys.executable, str(script)])
            self.assertEqual(result["status"], "passed")
            self.assertEqual(result["value"], 3)


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(ReentryGateStatusTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    helper_root = Path(args.helper_root).resolve() if args.helper_root else resolve_default_helper_root(repo_root)
    memory_root = Path(args.memory_root).resolve() if args.memory_root else resolve_default_memory_root(repo_root)
    restored_checkout_root = (
        Path(args.restored_checkout_root).resolve()
        if args.restored_checkout_root
        else resolve_default_restored_checkout_root(repo_root)
    )
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

    summary = build_status_summary(
        repo_root=repo_root,
        helper_root=helper_root,
        memory_root=memory_root,
        restored_checkout_root=restored_checkout_root,
        saved_archives_root=saved_archives_root,
        toolchains_root=toolchains_root,
        offline_deps_root=offline_deps_root,
        fallback_zig_archive=fallback_zig_archive,
    )

    if args.json:
        print(json.dumps(serialize(summary), indent=2, sort_keys=True))
    else:
        print_human_report(serialize(summary))

    return 0 if summary["status"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
