#!/usr/bin/env python3

"""Print the ordered issue #3 recovery ladder for saved-snapshot re-entry."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shlex
import tempfile
import unittest


DEFAULT_RESTORED_CHECKOUT = "browser-memory-snapshot"
DEFAULT_FALLBACK_ZIG = "zig-x86_64-linux-0.17.0-dev.299+a76ce7710.tar.xz"


def shell_join(parts: list[str]) -> str:
    return " ".join(shlex.quote(part) for part in parts)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Print the ordered recovery ladder for issue #3 saved-snapshot, "
            "build-readiness, and runtime re-entry helpers."
        )
    )
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--helper-root", default=None)
    parser.add_argument("--memory-root", default=None)
    parser.add_argument("--restored-checkout", default=None)
    parser.add_argument("--fallback-zig-archive", default=None)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    return parser


def discover_nearby_directory(repo_root: Path, name: str) -> Path | None:
    candidates = [
        repo_root / name,
        repo_root.parent / name,
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate.resolve()
    return None


def resolve_paths(
    repo_root: Path,
    helper_root: Path | None,
    memory_root: Path | None,
    restored_checkout: Path | None,
    fallback_zig_archive: Path | None,
) -> dict[str, Path | None]:
    repo_root = repo_root.resolve()
    helper_root = (helper_root or repo_root).resolve()
    if memory_root is None:
        memory_root = discover_nearby_directory(repo_root, "memory") or (repo_root.parent / "memory")
    memory_root = memory_root.resolve()
    restored_checkout = (restored_checkout or (repo_root.parent / DEFAULT_RESTORED_CHECKOUT)).resolve()
    if fallback_zig_archive is None:
        agent_files_root = discover_nearby_directory(repo_root, "agent_files") or (repo_root.parent / "agent_files")
        candidate = (agent_files_root / DEFAULT_FALLBACK_ZIG).resolve()
        fallback_zig_archive = candidate if candidate.exists() else None
    else:
        fallback_zig_archive = fallback_zig_archive.resolve()
    return {
        "repo_root": repo_root,
        "helper_root": helper_root,
        "memory_root": memory_root,
        "restored_checkout": restored_checkout,
        "fallback_zig_archive": fallback_zig_archive,
        "saved_archive": (memory_root / "repo_archives/browser/01-browser-fork-headed-mode-foundation.zip").resolve(),
    }


def command_with_optional_fallback(parts: list[str], fallback_zig_archive: Path | None) -> str:
    if fallback_zig_archive is not None:
        parts = parts + ["--fallback-zig-archive", str(fallback_zig_archive)]
    return shell_join(parts)


def build_steps(paths: dict[str, Path | None]) -> list[dict[str, object]]:
    helper_root = paths["helper_root"]
    restored_checkout = paths["restored_checkout"]
    fallback_zig_archive = paths["fallback_zig_archive"]
    helper_root_str = str(helper_root)
    restored_checkout_str = str(restored_checkout)
    restore_script = f"{helper_root_str}/scripts/linux/restore_saved_browser_snapshot.sh"
    saved_input_script = f"{helper_root_str}/scripts/check_issue3_saved_memory_inputs.py"
    build_route_script = f"{helper_root_str}/scripts/linux/show_issue3_linux_build_readiness_route.sh"
    runtime_route_script = f"{helper_root_str}/scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"
    surface_script = f"{helper_root_str}/scripts/linux/check_issue3_enter_submit_runtime_revalidation_surface.sh"
    snapshot_route_script = f"{helper_root_str}/scripts/linux/show_issue3_saved_browser_snapshot_route.sh"

    steps: list[dict[str, object]] = [
        {
            "name": "snapshot_route",
            "summary": "Print the saved browser snapshot route and confirm the restore surface.",
            "command": shell_join(["bash", snapshot_route_script, "--helper-root", helper_root_str]),
        }
    ]

    if not restored_checkout.exists():
        steps.append(
            {
                "name": "restore_snapshot",
                "summary": "Restore the saved browser snapshot into a disposable local checkout.",
                "command": command_with_optional_fallback(
                    [
                        "bash",
                        restore_script,
                        "--helper-root",
                        helper_root_str,
                        "--destination",
                        restored_checkout_str,
                    ],
                    fallback_zig_archive,
                ),
            }
        )

    steps.extend(
        [
            {
                "name": "saved_input_preflight",
                "summary": "Check the saved Memory repo and dependency inputs against the target checkout.",
                "command": command_with_optional_fallback(
                    [
                        "python",
                        saved_input_script,
                        "--repo-root",
                        restored_checkout_str,
                    ],
                    fallback_zig_archive,
                ),
            },
            {
                "name": "runtime_surface",
                "summary": "Confirm the runtime re-entry helper surface still exists before build work.",
                "command": shell_join(["bash", surface_script]),
            },
            {
                "name": "build_readiness_route",
                "summary": "Print the Linux or WSL build-readiness route for the restored checkout.",
                "command": command_with_optional_fallback(
                    [
                        "bash",
                        build_route_script,
                        "--repo-root",
                        restored_checkout_str,
                    ],
                    fallback_zig_archive,
                ),
            },
            {
                "name": "runtime_reentry_route",
                "summary": "Print the narrowed runtime re-entry route once the build gate is ready.",
                "command": command_with_optional_fallback(
                    [
                        "bash",
                        runtime_route_script,
                        "--repo-root",
                        restored_checkout_str,
                    ],
                    fallback_zig_archive,
                ),
            },
        ]
    )

    return steps


def emit_text(paths: dict[str, Path | None], steps: list[dict[str, object]]) -> None:
    print("Issue #3 recovery ladder")
    print(f"Repo root: {paths['repo_root']}")
    print(f"Helper root: {paths['helper_root']}")
    print(f"Memory root: {paths['memory_root']}")
    print(f"Saved archive: {paths['saved_archive']}")
    print(f"Restored checkout: {paths['restored_checkout']}")
    if paths["fallback_zig_archive"] is not None:
        print(f"Fallback Zig archive: {paths['fallback_zig_archive']}")
    print("")
    for idx, step in enumerate(steps, 1):
        print(f"{idx}. {step['summary']}")
        print(f"   {step['command']}")


class RecoveryLadderTests(unittest.TestCase):
    def test_missing_checkout_keeps_restore_step(self) -> None:
        root = Path("/tmp/browser")
        paths = resolve_paths(root, None, None, None, None)
        steps = build_steps(paths)
        self.assertEqual("snapshot_route", steps[0]["name"])
        self.assertEqual("restore_snapshot", steps[1]["name"])

    def test_existing_checkout_skips_restore_step(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            browser_root = root / "browser"
            restored = root / DEFAULT_RESTORED_CHECKOUT
            browser_root.mkdir()
            restored.mkdir()
            paths = resolve_paths(browser_root, None, None, restored, None)
            steps = build_steps(paths)
        self.assertEqual("snapshot_route", steps[0]["name"])
        self.assertNotIn("restore_snapshot", [step["name"] for step in steps])


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(RecoveryLadderTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    paths = resolve_paths(
        Path(args.repo_root),
        Path(args.helper_root) if args.helper_root else None,
        Path(args.memory_root) if args.memory_root else None,
        Path(args.restored_checkout) if args.restored_checkout else None,
        Path(args.fallback_zig_archive) if args.fallback_zig_archive else None,
    )
    steps = build_steps(paths)
    payload = {
        "repo_root": str(paths["repo_root"]),
        "helper_root": str(paths["helper_root"]),
        "memory_root": str(paths["memory_root"]),
        "saved_archive": str(paths["saved_archive"]),
        "restored_checkout": str(paths["restored_checkout"]),
        "fallback_zig_archive": None if paths["fallback_zig_archive"] is None else str(paths["fallback_zig_archive"]),
        "steps": steps,
    }
    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        emit_text(paths, steps)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
