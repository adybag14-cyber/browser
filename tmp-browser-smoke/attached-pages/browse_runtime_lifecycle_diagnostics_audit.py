#!/usr/bin/env python3
"""Audit headed browse lifecycle diagnostics in src/main.zig."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


SOURCE_PATH = "src/main.zig"

EXPECTATIONS = (
    {
        "label": "browse_startup_debug_log_present",
        "snippet": 'log.debug(.app, "startup", .{',
        "why": "Headed browse runs should keep a dedicated startup log entry for quick launch diagnosis.",
    },
    {
        "label": "browse_startup_logs_target_shape",
        "snippet": (
            '                .mode = "browse",\n'
            "                .requested_browser_mode = @tagName(requested_browser_mode),\n"
            "                .browser_mode = @tagName(browser_mode),\n"
            "                .display_backend = display_backend,\n"
            "                .native_surface_expected = native_headed_surface_expected,\n"
            "                .native_surface_active = headed_runtime_active,\n"
            "                .url = url,\n"
            "                .target_scheme = browse_target.scheme,\n"
            "                .target_scope = browse_target.scope,\n"
            "                .target_host = browse_target.host,\n"
            "                .target_port = browse_target.port,\n"
        ),
        "why": "Startup logs should keep the full browse target shape visible for internal, loopback, local-path, and remote launches.",
    },
    {
        "label": "browse_headed_runtime_log_present",
        "snippet": 'log.info(.app, "browse headed runtime", .{',
        "why": "Native headed runs should keep a dedicated runtime log entry.",
    },
    {
        "label": "browse_fallback_log_present",
        "snippet": 'log.info(.app, "browse headed fallback", .{',
        "why": "Fallback runs should keep a dedicated log entry so headed bring-up failures stay visible.",
    },
    {
        "label": "browse_error_log_present",
        "snippet": 'log.fatal(.app, "browse error", .{',
        "why": "Browse failures should keep a fatal log entry with lifecycle context.",
    },
    {
        "label": "browse_finished_log_present",
        "snippet": 'log.info(.app, "browse finished", .{',
        "why": "Successful browse exits should keep a completion log entry with the final lifecycle state.",
    },
    {
        "label": "browse_error_logs_navigation_state",
        "snippet": (
            "                    .window_closed = app.display.userClosed(),\n"
            "                    .shutdown_requested = app.shutdown,\n"
            "                    .exit_reason = commandExitReason(&app),\n"
            "                    .navigation_state = browseLifecycleLabel(&app),\n"
            "                    .navigation_state_seen = app.display.browse_navigation_state_seen,\n"
            "                    .is_loading = app.display.browse_is_loading,\n"
        ),
        "why": "Failure diagnostics should preserve the visible browse lifecycle state for headed triage.",
    },
    {
        "label": "browse_finished_logs_navigation_state",
        "snippet": (
            "                .window_closed = app.display.userClosed(),\n"
            "                .shutdown_requested = app.shutdown,\n"
            "                .exit_reason = commandExitReason(&app),\n"
            "                .navigation_state = browseLifecycleLabel(&app),\n"
            "                .navigation_state_seen = app.display.browse_navigation_state_seen,\n"
            "                .is_loading = app.display.browse_is_loading,\n"
        ),
        "why": "Completion diagnostics should preserve the final browse lifecycle state for headed validation runs.",
    },
    {
        "label": "browse_error_logs_dynamic_screenshot_status",
        "snippet": (
            "                    .screenshot_bmp_status = browseArtifactStatus(\n"
            "                        opts.screenshot_bmp_path,\n"
            "                        requested_browser_mode,\n"
            "                        browser_mode,\n"
            "                        app.display.browse_screenshot_bmp_attempted,\n"
            "                        app.display.browse_navigation_state_seen,\n"
            "                        app.display.browse_is_loading,\n"
            "                    ),\n"
        ),
        "why": "Failure diagnostics should keep the live screenshot export state visible when headed runs stop early.",
    },
    {
        "label": "browse_finished_logs_dynamic_png_status",
        "snippet": (
            "                .screenshot_png_status = browseArtifactStatus(\n"
            "                    opts.screenshot_png_path,\n"
            "                    requested_browser_mode,\n"
            "                    browser_mode,\n"
            "                    app.display.browse_screenshot_png_attempted,\n"
            "                    app.display.browse_navigation_state_seen,\n"
            "                    app.display.browse_is_loading,\n"
            "                ),\n"
        ),
        "why": "Completion diagnostics should keep the final screenshot export state visible for headed validation and recovery.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether src/main.zig keeps the headed browse lifecycle diagnostics "
            "surface across startup, runtime, fallback, failure, and completion logs."
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
        print(f"[{status}] browse runtime lifecycle diagnostics audit")
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