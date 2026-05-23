#!/usr/bin/env python3

"""Inspect the saved browser snapshot archive for issue #3 helper-surface drift."""

from __future__ import annotations

import argparse
import json
import os
import sys
import zipfile
from dataclasses import asdict, dataclass


DEFAULT_ARCHIVE_NAME = "01-browser-fork-headed-mode-foundation.zip"
REQUIRED_PATHS = [
    (
        "build.zig.zon",
        "Snapshot manifest expected in a reusable restored checkout.",
    ),
    (
        "docs/ISSUE3_SAVED_BROWSER_SNAPSHOT_ROUTE.md",
        "Read-first saved-browser-snapshot restore note for the blocked issue #3 runtime lane.",
    ),
    (
        "scripts/linux/restore_saved_browser_snapshot.sh",
        "Restore helper that supports --check-only and --sync-helper-surface.",
    ),
    (
        "scripts/linux/show_issue3_saved_browser_snapshot_route.sh",
        "Compact route printer for the saved-browser-snapshot restore path.",
    ),
    (
        "scripts/check_issue3_saved_memory_inputs.py",
        "Saved-Memory preflight that checks the repo archive, blocker file, and dependency bundles.",
    ),
    (
        "scripts/linux/show_issue3_linux_build_readiness_route.sh",
        "Companion Linux or WSL build-readiness route printer after restore.",
    ),
    (
        "scripts/linux/show_issue3_enter_submit_runtime_revalidation_route.sh",
        "Companion direct runtime re-entry route printer after restore.",
    ),
]


@dataclass
class PathStatus:
    path: str
    present: bool
    purpose: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether the saved browser snapshot archive already contains the "
            "current issue #3 restore-route helper surface or whether "
            "--sync-helper-surface should be preferred."
        )
    )
    parser.add_argument(
        "--repo-root",
        default=os.getcwd(),
        help="Live browser repo root used to infer the default Memory location.",
    )
    parser.add_argument(
        "--memory-root",
        help="Override the default Memory root (<repo-root>/../memory).",
    )
    parser.add_argument(
        "--archive",
        help="Override the saved snapshot archive path.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print a JSON summary instead of the human-readable surface.",
    )
    return parser.parse_args()


def resolve_archive_path(args: argparse.Namespace) -> tuple[str, str]:
    repo_root = os.path.abspath(args.repo_root)
    if args.memory_root:
        memory_root = os.path.abspath(args.memory_root)
    else:
        candidates = [
            os.path.join(os.path.dirname(repo_root), "memory"),
            os.path.join(repo_root, "memory"),
            os.path.join("/workspace", "memory"),
        ]
        memory_root = next((path for path in candidates if os.path.isdir(path)), candidates[0])
    archive_path = (
        os.path.abspath(args.archive)
        if args.archive
        else os.path.join(memory_root, "repo_archives", "browser", DEFAULT_ARCHIVE_NAME)
    )
    return memory_root, archive_path


def infer_top_level_folder(names: set[str]) -> str:
    prefixes = sorted(
        {
            name.split("/", 1)[0]
            for name in names
            if "/" in name and name.split("/", 1)[0]
        }
    )
    if len(prefixes) == 1:
        return prefixes[0]
    return ""


def build_statuses(names: set[str], top_level_folder: str) -> list[PathStatus]:
    prefix = f"{top_level_folder}/" if top_level_folder else ""
    return [
        PathStatus(path=path, present=f"{prefix}{path}" in names, purpose=purpose)
        for path, purpose in REQUIRED_PATHS
    ]


def human_output(archive_path: str, top_level_folder: str, statuses: list[PathStatus]) -> str:
    missing = [status for status in statuses if not status.present]
    recommended_restore_mode = "--sync-helper-surface" if missing else "plain restore is safe"
    lines = [
        "Issue #3 saved browser snapshot archive surface",
        "",
        f"Snapshot archive:       {archive_path}",
        f"Archive top-level root: {top_level_folder or 'unable to infer'}",
        f"Recommended restore:    {recommended_restore_mode}",
        "",
        "Archive helper surface:",
    ]
    for status in statuses:
        prefix = "PASS" if status.present else "WARN"
        lines.append(f"[{prefix}] {status.path}")
        lines.append(f"  {status.purpose}")
    lines.extend(
        [
            "",
            "Working rules:",
            "  - Prefer a plain restore only when the saved archive already contains the current helper surface.",
            "  - Use --sync-helper-surface when any helper path above is missing from the archive.",
            "  - Keep the live helper root for the next follow-up commands when the archive helper surface is stale.",
        ]
    )
    if missing:
        lines.extend(
            [
                "",
                "Missing helper paths detected in the saved archive:",
            ]
        )
        lines.extend(f"  - {status.path}" for status in missing)
    else:
        lines.extend(
            [
                "",
                "The saved archive already carries the current helper surface.",
            ]
        )
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    _, archive_path = resolve_archive_path(args)
    if not os.path.isfile(archive_path):
        print(f"Snapshot archive not found: {archive_path}", file=sys.stderr)
        return 1

    with zipfile.ZipFile(archive_path) as archive:
        names = set(archive.namelist())

    top_level_folder = infer_top_level_folder(names)
    statuses = build_statuses(names, top_level_folder)
    missing_paths = [status.path for status in statuses if not status.present]
    payload = {
        "issue": "issue3-saved-browser-snapshot-archive-surface",
        "archive_path": archive_path,
        "archive_top_level_root": top_level_folder,
        "helper_surface_complete": not missing_paths,
        "recommended_restore_mode": (
            "sync-helper-surface" if missing_paths else "plain"
        ),
        "missing_paths": missing_paths,
        "required_paths": [asdict(status) for status in statuses],
    }

    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        print(human_output(archive_path, top_level_folder, statuses))

    return 0 if not missing_paths else 2


if __name__ == "__main__":
    raise SystemExit(main())
