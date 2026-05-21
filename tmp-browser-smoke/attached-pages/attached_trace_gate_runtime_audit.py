#!/usr/bin/env python3
"""Audit attached-page trace-gate coverage for headed runtime diagnostics."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "win32_trace_helper_present",
        "path": "src/display/win32_backend.zig",
        "snippet": "fn traceUrlContainsIgnoreCase(url: []const u8, needle: []const u8) bool {",
        "why": (
            "The Win32 input trace gate needs a case-insensitive helper before it can "
            "reliably match attached-page filenames and URL-encoded variants."
        ),
    },
    {
        "label": "win32_attached_pages_in_trace_gate",
        "path": "src/display/win32_backend.zig",
        "snippet": (
            '        traceUrlContainsIgnoreCase(url, "google_home_title_probe.html") or\n'
            '        traceUrlContainsIgnoreCase(url, "body_onload_keyboard_input.html") or\n'
            '        traceUrlContainsIgnoreCase(url, "mouse_down_focus_input.html") or\n'
            '        traceUrlContainsIgnoreCase(url, "Control your online safety and privacy") or\n'
            '        traceUrlContainsIgnoreCase(url, "Job%20Application%20for") or\n'
            '        traceUrlContainsIgnoreCase(url, "Presidential Unsealing and Reporting System for UAP Encounters")'
        ),
        "why": (
            "The Win32 runtime-input trace gate should watch the saved attached pages "
            "and local headed fixtures, not only google-home URLs."
        ),
    },
    {
        "label": "win32_trace_gate_regression_test_present",
        "path": "src/display/win32_backend.zig",
        "snippet": 'test "win32 google input trace gate includes attached compatibility pages and headed fixtures" {',
        "why": (
            "The input-trace widening needs a focused regression test so the attached "
            "compatibility pages stay covered after future refactors."
        ),
    },
    {
        "label": "render_trace_helper_present",
        "path": "src/lightpanda.zig",
        "snippet": "fn browseTraceUrlContainsIgnoreCase(url: []const u8, needle: []const u8) bool {",
        "why": (
            "The headed render trace gate also needs a case-insensitive helper before "
            "it can match the attached-page surface cleanly."
        ),
    },
    {
        "label": "render_attached_pages_in_trace_gate",
        "path": "src/lightpanda.zig",
        "snippet": (
            '        browseTraceUrlContainsIgnoreCase(url, "google_home_title_probe.html") or\n'
            '        browseTraceUrlContainsIgnoreCase(url, "body_onload_keyboard_input.html") or\n'
            '        browseTraceUrlContainsIgnoreCase(url, "mouse_down_focus_input.html") or\n'
            '        browseTraceUrlContainsIgnoreCase(url, "Control your online safety and privacy") or\n'
            '        browseTraceUrlContainsIgnoreCase(url, "Job%20Application%20for") or\n'
            '        browseTraceUrlContainsIgnoreCase(url, "Presidential Unsealing and Reporting System for UAP Encounters")'
        ),
        "why": (
            "The headed render trace gate should cover the same attached-page and "
            "fixture set as the runtime-input trace gate."
        ),
    },
    {
        "label": "render_trace_gate_regression_test_present",
        "path": "src/lightpanda.zig",
        "snippet": 'test "browse render trace gate includes attached compatibility pages and headed fixtures" {',
        "why": (
            "The render-trace widening needs a focused regression test so the attached "
            "page coverage stays visible on the branch."
        ),
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether headed runtime trace gates cover the attached compatibility "
            "pages and local headed fixtures."
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
        checks.append(
            {
                **expectation,
                "exists": exists,
                "present": present,
            }
        )

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
        print(f"[{status}] attached trace-gate runtime audit")
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