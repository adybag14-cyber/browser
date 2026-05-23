#!/usr/bin/env python3
"""Audit headed browse fallback and completion diagnostics in src/main.zig."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


SOURCE_PATH = "src/main.zig"

EXPECTATIONS = (
    {
        "label": "browse_lifecycle_helper",
        "snippet": "fn browseLifecycleLabel(app: *const App) []const u8 {",
        "why": "Browse completion logs should keep a single helper for the current navigation lifecycle label.",
    },
    {
        "label": "browse_error_log",
        "snippet": 'log.fatal(.app, "browse error", .{',
        "why": "Headed browse failures should keep a dedicated fatal log surface.",
    },
    {
        "label": "browse_finished_log",
        "snippet": 'log.info(.app, "browse finished", .{',
        "why": "Successful headed browse runs should keep a dedicated completion log surface.",
    },
    {
        "label": "browse_headed_runtime_log",
        "snippet": 'log.info(.app, "browse headed runtime", .{',
        "why": "The native headed browse path should stay visible before navigation work begins.",
    },
    {
        "label": "browse_headed_fallback_log",
        "snippet": 'log.info(.app, "browse headed fallback", .{',
        "why": "Unexpected fallback to headless should stay obvious in headed startup diagnostics.",
    },
    {
        "label": "fallback_reason_field",
        "snippet": ".reason = info.reason,",
        "why": "Fallback diagnostics should continue surfacing the exact reason when headed mode does not stay native.",
    },
    {
        "label": "completion_navigation_state_field",
        "snippet": ".navigation_state = browseLifecycleLabel(&app),",
        "why": "Completion and failure logs should keep the summarized navigation state visible.",
    },
    {
        "label": "completion_navigation_seen_field",
        "snippet": ".navigation_state_seen = app.display.browse_navigation_state_seen,",
        "why": "Completion logs should keep whether navigation state was ever observed.",
    },
    {
        "label": "completion_loading_field",
        "snippet": ".is_loading = app.display.browse_is_loading,",
        "why": "Completion logs should keep whether the page was still loading when the run ended.",
    },
    {
        "label": "screenshot_bmp_status_field",
        "snippet": ".screenshot_bmp_status = browseArtifactStatus(",
        "why": "Browse completion should keep the BMP export status visible for headed validation runs.",
    },
    {
        "label": "screenshot_png_status_field",
        "snippet": ".screenshot_png_status = browseArtifactStatus(",
        "why": "Browse completion should keep the PNG export status visible for headed validation runs.",
    },
    {
        "label": "unavailable_without_native_surface_status",
        "snippet": 'return "unavailable_without_native_surface";',
        "why": "Browse artifact status should keep a dedicated label for headed runs that fall back before a native surface exists.",
    },
    {
        "label": "waiting_for_load_status",
        "snippet": 'return if (is_loading) "waiting_for_load" else "settled_without_export";',
        "why": "Artifact diagnostics should distinguish still-loading pages from settled pages that simply did not export.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether src/main.zig keeps the headed browse fallback and "
            "completion diagnostics surface."
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=default_repo_root,
        help="Repository root to inspect. Defaults to the current script directory.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit the full audit summary as JSON.",
    )
    return parser.parse_args()


def audit(repo_root: Path) -> dict[str, object]:
    target = repo_root / SOURCE_PATH
    exists = target.is_file()
    text = target.read_text(encoding="utf-8") if exists else ""

    checks: list[dict[str, object]] = []
    missing = 0
    for expectation in EXPECTATIONS:
        present = expectation["snippet"] in text
        if not present:
            missing += 1
        checks.append(
            {
                **expectation,
                "path": SOURCE_PATH,
                "exists": exists,
                "present": present,
            }
        )

    return {
        "repo_root": str(repo_root),
        "source_path": SOURCE_PATH,
        "expectation_count": len(EXPECTATIONS),
        "missing_count": missing,
        "ok": exists and missing == 0,
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
        print(f"[{status}] headed browse completion diagnostics audit")
        print(f"Repo root: {result['repo_root']}")
        print(f"Source path: {result['source_path']}")
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
