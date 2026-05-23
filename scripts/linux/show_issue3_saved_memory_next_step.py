#!/usr/bin/env python3

"""Recommend the next issue #3 helper route from saved Memory state.

This helper stays create-only so scheduled runs can decide whether they should:
- restore the saved browser snapshot
- sync the helper surface into a restored checkout
- stay on Linux or WSL build-readiness
- or reopen the direct runtime re-entry route
"""

from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path
import sys
import unittest


def load_saved_memory_module(repo_root: Path):
    helper_path = repo_root / "scripts" / "check_issue3_saved_memory_inputs.py"
    spec = importlib.util.spec_from_file_location("issue3_saved_memory_inputs", helper_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load helper module from {helper_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def shell_quote(value: str) -> str:
    return "'" + value.replace("'", "'\"'\"'") + "'"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Recommend the next issue #3 Linux or WSL helper route from the "
            "current saved Memory and restored-checkout state."
        )
    )
    parser.add_argument("--repo-root", default=".", help="Path to the browser checkout root.")
    parser.add_argument("--memory-root", default=None, help="Optional override for the memory root.")
    parser.add_argument(
        "--agent-files-root",
        default=None,
        help="Optional override for the attached-files root.",
    )
    parser.add_argument(
        "--restored-checkout-root",
        default=None,
        help="Optional override for the reusable restored checkout root.",
    )
    parser.add_argument(
        "--fallback-zig-archive",
        default=None,
        help="Optional explicit fallback Zig archive path to surface in follow-up commands.",
    )
    parser.add_argument(
        "--skip-archive-integrity-check",
        action="store_true",
        help="Skip archive readability checks when probing saved Memory inputs.",
    )
    parser.add_argument(
        "--build-readiness-green",
        action="store_true",
        help=(
            "Treat Linux or WSL build-readiness as already green so the helper "
            "can recommend the direct runtime re-entry route."
        ),
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of text.")
    parser.add_argument("--self-test", action="store_true", help="Run focused tests and exit.")
    return parser


def with_fallback(command: str, fallback_path: str) -> str:
    if fallback_path:
        return f"{command} --fallback-zig-archive {shell_quote(fallback_path)}"
    return command


def build_commands(repo_root: Path, restored_checkout_root: Path, fallback_path: str) -> dict[str, str]:
    repo_root_str = str(repo_root)
    restored_root_str = str(restored_checkout_root)
    commands = {
        "saved_snapshot_surface": (
            "bash "
            f"{shell_quote(str(repo_root / 'scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh'))} "
            f"--repo-root {shell_quote(repo_root_str)}"
        ),
        "saved_snapshot_route": (
            "bash "
            f"{shell_quote(str(repo_root / 'scripts/linux/show_issue3_saved_browser_snapshot_route.sh'))} "
            f"--repo-root {shell_quote(repo_root_str)}"
        ),
        "saved_snapshot_route_synced": (
            "bash "
            f"{shell_quote(str(repo_root / 'scripts/linux/show_issue3_saved_browser_snapshot_route.sh'))} "
            f"--repo-root {shell_quote(repo_root_str)} --sync-helper-surface"
        ),
        "saved_memory_preflight": (
            "python "
            f"{shell_quote(str(repo_root / 'scripts/check_issue3_saved_memory_inputs.py'))} "
            f"--repo-root {shell_quote(restored_root_str)}"
        ),
        "linux_build_route": (
            "bash "
            f"{shell_quote(str(repo_root / 'scripts/linux/show_issue3_linux_build_readiness_route.sh'))} "
            f"--repo-root {shell_quote(restored_root_str)}"
        ),
        "runtime_route": (
            "bash "
            f"{shell_quote(str(repo_root / 'scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh'))} "
            f"--repo-root {shell_quote(restored_root_str)}"
        ),
    }
    if fallback_path:
        commands["saved_snapshot_route"] = with_fallback(commands["saved_snapshot_route"], fallback_path)
        commands["saved_snapshot_route_synced"] = with_fallback(
            commands["saved_snapshot_route_synced"], fallback_path
        )
        commands["saved_memory_preflight"] = with_fallback(commands["saved_memory_preflight"], fallback_path)
        commands["linux_build_route"] = with_fallback(commands["linux_build_route"], fallback_path)
        commands["runtime_route"] = with_fallback(commands["runtime_route"], fallback_path)
    return commands


def recommend_next_step(result: dict[str, object], *, build_readiness_green: bool) -> dict[str, object]:
    restored_checkout = result["restored_checkout"]
    fallback = result["fallback_zig_archive"]
    fallback_path = fallback["path"] if fallback.get("exists") else ""
    commands = build_commands(
        Path(result["repo_root"]),
        Path(restored_checkout["path"]),
        fallback_path,
    )

    missing_required = [
        entry["label"]
        for entry in result["required_files"]
        if not entry["exists"] or ("archive_readable" in entry and not entry["archive_readable"])
    ]
    if missing_required:
        return {
            "status": "blocked",
            "next_step": "repair-saved-memory-inputs",
            "reason": (
                "Required saved Memory inputs are missing or unreadable, so the "
                "restore and re-entry routes are not trustworthy yet."
            ),
            "commands": {
                "saved_snapshot_surface": commands["saved_snapshot_surface"],
                "saved_snapshot_route": commands["saved_snapshot_route"],
            },
            "missing_required_inputs": missing_required,
        }

    checkout_status = restored_checkout["status"]
    missing_helper_surface = restored_checkout["missing_helper_surface_files"]
    if checkout_status == "missing":
        return {
            "status": "ready",
            "next_step": "restore-saved-browser-snapshot",
            "reason": (
                "The saved Memory inputs are present, but no reusable restored "
                "checkout exists yet for Linux or WSL follow-up work."
            ),
            "commands": {
                "saved_snapshot_surface": commands["saved_snapshot_surface"],
                "saved_snapshot_route": commands["saved_snapshot_route"],
            },
            "missing_required_inputs": [],
        }

    if checkout_status == "incomplete" or missing_helper_surface:
        return {
            "status": "ready",
            "next_step": "sync-restored-helper-surface",
            "reason": (
                "A restored checkout exists, but it is missing build manifest or "
                "helper-surface files needed for the next Linux or WSL route."
            ),
            "commands": {
                "saved_snapshot_surface": commands["saved_snapshot_surface"],
                "saved_snapshot_route_synced": commands["saved_snapshot_route_synced"],
            },
            "missing_required_inputs": [],
            "missing_helper_surface_files": missing_helper_surface,
        }

    if build_readiness_green:
        return {
            "status": "ready",
            "next_step": "runtime-reentry-route",
            "reason": (
                "The restored checkout is present and build-readiness is already "
                "marked green, so the direct runtime re-entry route is the next "
                "honest narrowing step."
            ),
            "commands": {
                "saved_memory_preflight": commands["saved_memory_preflight"],
                "runtime_route": commands["runtime_route"],
            },
            "missing_required_inputs": [],
        }

    return {
        "status": "ready",
        "next_step": "linux-build-readiness-route",
        "reason": (
            "The restored checkout and helper surface are present, so the next "
            "safe move is the Linux or WSL build-readiness route before runtime "
            "re-entry is reopened."
        ),
        "commands": {
            "saved_memory_preflight": commands["saved_memory_preflight"],
            "linux_build_route": commands["linux_build_route"],
        },
        "missing_required_inputs": [],
    }


def emit_text(plan: dict[str, object]) -> None:
    print(f"Status: {plan['status']}")
    print(f"Next step: {plan['next_step']}")
    print(f"Reason: {plan['reason']}")
    if plan.get("missing_required_inputs"):
        print("Missing required inputs:")
        for item in plan["missing_required_inputs"]:
            print(f"  - {item}")
    if plan.get("missing_helper_surface_files"):
        print("Missing helper-surface files:")
        for item in plan["missing_helper_surface_files"]:
            print(f"  - {item}")
    print("Commands:")
    for name, command in plan["commands"].items():
        print(f"  {name}: {command}")


class RecommendationTests(unittest.TestCase):
    def test_missing_inputs_block_route(self) -> None:
        result = {
            "repo_root": "/tmp/browser",
            "required_files": [{"label": "saved repo snapshot", "exists": False}],
            "fallback_zig_archive": {"path": "/tmp/zig.tar.xz", "exists": False},
            "restored_checkout": {
                "path": "/tmp/browser-memory-snapshot",
                "status": "missing",
                "missing_helper_surface_files": [],
            },
        }
        plan = recommend_next_step(result, build_readiness_green=False)
        self.assertEqual(plan["status"], "blocked")
        self.assertEqual(plan["next_step"], "repair-saved-memory-inputs")

    def test_missing_checkout_prefers_restore(self) -> None:
        result = {
            "repo_root": "/tmp/browser",
            "required_files": [{"label": "saved repo snapshot", "exists": True}],
            "fallback_zig_archive": {"path": "/tmp/zig.tar.xz", "exists": False},
            "restored_checkout": {
                "path": "/tmp/browser-memory-snapshot",
                "status": "missing",
                "missing_helper_surface_files": [],
            },
        }
        plan = recommend_next_step(result, build_readiness_green=False)
        self.assertEqual(plan["next_step"], "restore-saved-browser-snapshot")

    def test_incomplete_checkout_prefers_synced_restore(self) -> None:
        result = {
            "repo_root": "/tmp/browser",
            "required_files": [{"label": "saved repo snapshot", "exists": True}],
            "fallback_zig_archive": {"path": "/tmp/zig.tar.xz", "exists": False},
            "restored_checkout": {
                "path": "/tmp/browser-memory-snapshot",
                "status": "incomplete",
                "missing_helper_surface_files": ["scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"],
            },
        }
        plan = recommend_next_step(result, build_readiness_green=False)
        self.assertEqual(plan["next_step"], "sync-restored-helper-surface")

    def test_ready_checkout_prefers_build_route_until_green(self) -> None:
        result = {
            "repo_root": "/tmp/browser",
            "required_files": [{"label": "saved repo snapshot", "exists": True}],
            "fallback_zig_archive": {"path": "/tmp/zig.tar.xz", "exists": True},
            "restored_checkout": {
                "path": "/tmp/browser-memory-snapshot",
                "status": "ready",
                "missing_helper_surface_files": [],
            },
        }
        plan = recommend_next_step(result, build_readiness_green=False)
        self.assertEqual(plan["next_step"], "linux-build-readiness-route")
        self.assertIn("--fallback-zig-archive", plan["commands"]["linux_build_route"])

    def test_green_build_route_allows_runtime_reentry(self) -> None:
        result = {
            "repo_root": "/tmp/browser",
            "required_files": [{"label": "saved repo snapshot", "exists": True}],
            "fallback_zig_archive": {"path": "/tmp/zig.tar.xz", "exists": False},
            "restored_checkout": {
                "path": "/tmp/browser-memory-snapshot",
                "status": "ready",
                "missing_helper_surface_files": [],
            },
        }
        plan = recommend_next_step(result, build_readiness_green=True)
        self.assertEqual(plan["next_step"], "runtime-reentry-route")


def main() -> int:
    args = build_parser().parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(RecommendationTests)
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1

    repo_root = Path(args.repo_root).resolve()
    module = load_saved_memory_module(repo_root)
    memory_root = Path(args.memory_root).resolve() if args.memory_root else module.resolve_default_memory_root(repo_root)
    agent_files_root = (
        Path(args.agent_files_root).resolve()
        if args.agent_files_root
        else module.resolve_default_agent_files_root(repo_root)
    )
    restored_checkout_root = (
        Path(args.restored_checkout_root).resolve()
        if args.restored_checkout_root
        else module.resolve_default_restored_checkout_root(repo_root)
    )
    fallback_zig_archive = Path(args.fallback_zig_archive).resolve() if args.fallback_zig_archive else None

    result = module.collect_results(
        repo_root=repo_root,
        memory_root=memory_root,
        agent_files_root=agent_files_root,
        restored_checkout_root=restored_checkout_root,
        fallback_zig_archive=fallback_zig_archive,
        check_archive_integrity=not args.skip_archive_integrity_check,
    )
    plan = recommend_next_step(result, build_readiness_green=args.build_readiness_green)
    payload = {"profile": "issue3-saved-memory-next-step", "inputs": result, "plan": plan}
    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        emit_text(plan)
    return 0 if plan["status"] == "ready" else 1


if __name__ == "__main__":
    sys.exit(main())
