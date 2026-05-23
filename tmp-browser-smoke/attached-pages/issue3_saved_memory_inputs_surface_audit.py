#!/usr/bin/env python3
"""Audit the saved-Memory input re-entry surface for the blocked issue #3 lane."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "runtime_gates_saved_snapshot_note",
        "path": "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "snippet": "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "why": "The runtime re-entry gates should keep the saved-browser-snapshot route in the read-first set.",
    },
    {
        "label": "runtime_gates_saved_memory_preflight",
        "path": "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "snippet": "python scripts/check_issue3_saved_memory_inputs.py --repo-root .",
        "why": "The runtime gates should keep the saved-Memory preflight visible before Linux or WSL replay.",
    },
    {
        "label": "runtime_gates_snapshot_route_command",
        "path": "docs/ISSUE3_RUNTIME_REENTRY_GATES.md",
        "snippet": "bash ./scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "why": "The runtime gates should keep the saved-browser-snapshot route printer visible.",
    },
    {
        "label": "saved_memory_helper_repo_snapshot",
        "path": "scripts/check_issue3_saved_memory_inputs.py",
        "snippet": '("repo_archives/browser/01-browser-fork-headed-mode-foundation.zip", "saved repo snapshot")',
        "why": "The saved-Memory helper should keep checking for the saved repo snapshot.",
    },
    {
        "label": "saved_memory_helper_blocker_file",
        "path": "scripts/check_issue3_saved_memory_inputs.py",
        "snippet": '("repo_archives/browser/blocker_intelligence.yaml", "blocker intelligence")',
        "why": "The saved-Memory helper should keep checking for blocker intelligence.",
    },
    {
        "label": "saved_memory_helper_readiness_helper_surface",
        "path": "scripts/check_issue3_saved_memory_inputs.py",
        "snippet": '("scripts/check_linux_build_readiness.py", "Linux build-readiness helper")',
        "why": "The restored helper-surface audit should keep the Linux build-readiness helper in scope.",
    },
    {
        "label": "saved_memory_helper_snapshot_surface_checker",
        "path": "scripts/check_issue3_saved_memory_inputs.py",
        "snippet": '"scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh"',
        "why": "The restored helper-surface audit should keep the snapshot route checker in scope.",
    },
    {
        "label": "saved_memory_helper_snapshot_route",
        "path": "scripts/check_issue3_saved_memory_inputs.py",
        "snippet": '"scripts/linux/show_issue3_saved_browser_snapshot_route.sh"',
        "why": "The restored helper-surface audit should keep the snapshot route printer in scope.",
    },
    {
        "label": "saved_memory_helper_runtime_route",
        "path": "scripts/check_issue3_saved_memory_inputs.py",
        "snippet": '"scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh"',
        "why": "The restored helper-surface audit should keep the direct runtime route in scope.",
    },
    {
        "label": "saved_memory_helper_fallback_zig_arg",
        "path": "scripts/check_issue3_saved_memory_inputs.py",
        "snippet": '"--fallback-zig-archive"',
        "why": "The saved-Memory helper should keep the explicit fallback Zig override visible.",
    },
    {
        "label": "saved_memory_helper_success_output",
        "path": "scripts/check_issue3_saved_memory_inputs.py",
        "snippet": "Saved Memory input check passed.",
        "why": "The saved-Memory helper should keep a clear pass surface.",
    },
    {
        "label": "snapshot_route_saved_memory_step",
        "path": "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "snippet": "Saved-Memory preflight against the restored checkout:",
        "why": "The snapshot route printer should keep the restored-checkout preflight step visible.",
    },
    {
        "label": "snapshot_route_synced_restore_section",
        "path": "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "snippet": "Recommended synced restore when the archive helper surface is stale:",
        "why": "The snapshot route printer should keep the synced restore fallback visible.",
    },
    {
        "label": "snapshot_route_sync_preflight",
        "path": "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "snippet": "Synced saved-Memory preflight:",
        "why": "The snapshot route printer should keep the synced preflight step visible.",
    },
    {
        "label": "snapshot_route_runtime_follow_up",
        "path": "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "snippet": "show_issue3_enter_submit_runtime_revalidation_route.sh",
        "why": "The snapshot route printer should keep the direct runtime follow-up route visible.",
    },
    {
        "label": "snapshot_route_sync_mode",
        "path": "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "snippet": "--sync-helper-surface",
        "why": "The snapshot route printer should keep helper-surface sync mode visible.",
    },
    {
        "label": "snapshot_route_follow_up_root",
        "path": "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "snippet": "follow_up_helper_root",
        "why": "The snapshot route printer should keep the follow-up helper root in JSON output for downstream tooling.",
    },
    {
        "label": "snapshot_surface_checker_sync_mode",
        "path": "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "snippet": "--sync-helper-surface",
        "why": "The snapshot route surface checker should keep sync-mode coverage visible.",
    },
    {
        "label": "snapshot_surface_checker_saved_memory_helper",
        "path": "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "snippet": "scripts/check_issue3_saved_memory_inputs.py",
        "why": "The snapshot route surface checker should keep the saved-Memory helper in its reference set.",
    },
    {
        "label": "snapshot_surface_checker_sync_reason",
        "path": "scripts/linux/check_issue3_saved_browser_snapshot_route_surface.sh",
        "snippet": "the saved archive can lag the current",
        "why": "The snapshot route surface checker should keep the synced-restore rationale visible.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether the saved-Memory preflight and snapshot-restore route "
            "surfaces for the blocked issue #3 lane still expose their key markers."
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=default_repo_root,
        help="Repository root to inspect. Defaults to the current script's repo.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit the full audit summary as JSON.",
    )
    return parser.parse_args()


def audit(repo_root: Path) -> dict[str, object]:
    checks: list[dict[str, object]] = []
    missing = 0

    for expectation in EXPECTATIONS:
        target = repo_root / expectation["path"]
        exists = target.is_file()
        if exists:
            text = target.read_text(encoding="utf-8")
            present = expectation["snippet"] in text
        else:
            present = False
        if not present:
            missing += 1
        checks.append({**expectation, "exists": exists, "present": present})

    return {
        "repo_root": str(repo_root),
        "expectation_count": len(EXPECTATIONS),
        "missing_count": missing,
        "ok": missing == 0,
        "checks": checks,
    }


def main() -> int:
    args = parse_args()
    result = audit(args.repo_root.resolve())

    if args.json:
        json.dump(result, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        status = "PASS" if result["ok"] else "FAIL"
        print(f"[{status}] issue #3 saved-Memory input surface audit")
        print(f"Repo root: {result['repo_root']}")
        print(
            f"Matched {result['expectation_count'] - result['missing_count']} of "
            f"{result['expectation_count']} expectations."
        )
        for check in result["checks"]:
            marker = "ok" if check["present"] else "missing"
            print(f"- {marker}: {check['label']} ({check['path']})")
            if not check["present"]:
                print(f"  Why: {check['why']}")

    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
