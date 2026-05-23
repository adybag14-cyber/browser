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
        "label": "browse_startup_logs_target_scheme",
        "snippet": '.target_scheme = browse_target.scheme,',
        "why": "Headed browse startup should keep surfacing the target scheme for localhost versus remote diagnosis.",
    },
    {
        "label": "browse_headed_runtime_log_exists",
        "snippet": 'log.info(.app, "browse headed runtime", .{',
        "why": "A real headed browse session should keep its explicit runtime log surface.",
    },
    {
        "label": "browse_headed_fallback_log_exists",
        "snippet": 'log.info(.app, "browse headed fallback", .{',
        "why": "Fallback runs need a dedicated headed fallback log surface so local validation failures are obvious.",
    },
    {
        "label": "browse_headed_fallback_disables_window",
        "snippet": '.window = "disabled",',
        "why": "Fallback diagnostics should keep making it clear that no native headed window was active.",
    },
    {
        "label": "browse_headed_fallback_keeps_reason",
        "snippet": '.reason = info.reason,',
        "why": "Fallback diagnostics should keep the human-readable reason attached to the browse log.",
    },
    {
        "label": "browse_error_logs_navigation_state",
        "snippet": '.navigation_state = browseLifecycleLabel(&app),',
        "why": "Browse failures should keep exposing whether the session died before navigation, while loading, or after settle.",
    },
    {
        "label": "browse_error_logs_exit_reason",
        "snippet": '.exit_reason = commandExitReason(&app),',
        "why": "Headed validation needs the exit reason to distinguish a shutdown request from a closed window.",
    },
    {
        "label": "browse_finished_log_exists",
        "snippet": 'log.info(.app, "browse finished", .{',
        "why": "Successful browse completion should keep its structured completion log surface.",
    },
    {
        "label": "browse_finished_keeps_bmp_status",
        "snippet": '.screenshot_bmp_status = browseArtifactStatus(',
        "why": "Completion logs should keep reporting whether the BMP export path was disabled, waiting, or attempted.",
    },
    {
        "label": "browse_finished_keeps_png_status",
        "snippet": '.screenshot_png_status = browseArtifactStatus(',
        "why": "Completion logs should keep reporting whether the PNG export path was disabled, waiting, or attempted.",
    },
    {
        "label": "fallback_test_covers_linux_unsupported_case",
        "snippet": 'const info = browserModeFallbackInfoForEnvironment(.headed, .headless, .hosted, .linux).?;',
        "why": "The focused tests should keep covering the expected Linux hosted fallback path.",
    },
    {
        "label": "fallback_test_covers_windows_supported_case",
        "snippet": 'const info = browserModeFallbackInfoForEnvironment(.headed, .headless, .hosted, .windows).?;',
        "why": "The focused tests should keep covering the unexpected Windows headed fallback path.",
    },
    {
        "label": "artifact_status_test_covers_unavailable_surface",
        "snippet": 'browseArtifactStatus("capture.png", .headed, .headless, false, false, true),',
        "why": "The helper tests should keep covering the no-native-surface artifact status case.",
    },
    {
        "label": "artifact_status_test_covers_settled_surface",
        "snippet": 'browseArtifactStatus("capture.png", .headed, .headed, false, true, false),',
        "why": "The helper tests should keep covering the settled headed artifact status case.",
    },
)


def repo_root_from(start: Path) -> Path:
    current = start.resolve()
    for candidate in (current, *current.parents):
        if (candidate / "build.zig").exists():
            return candidate
    raise FileNotFoundError(f"Could not resolve repo root from {start}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Check whether src/main.zig keeps the headed browse fallback and "
            "completion diagnostics surface."
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=None,
        help="Repository root to inspect. Defaults to the current repo that contains this script.",
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
    repo_root = args.repo_root.resolve() if args.repo_root else repo_root_from(Path(__file__).resolve().parent)
    result = audit(repo_root)

    if args.json:
        json.dump(result, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        status = "PASS" if result["ok"] else "FAIL"
        print(f"[{status}] headed browse fallback diagnostics audit")
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