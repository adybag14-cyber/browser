#!/usr/bin/env python3
"""Audit the issue #3 runtime trace gates against attached-page targets."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


TRACE_HINTS: tuple[str, ...] = (
    "google-home-",
    "google.com",
    "google_home_title_probe.html",
    "body_onload_keyboard_input.html",
    "mouse_down_focus_input.html",
    "Control your online safety and privacy",
    "Control%20your%20online%20safety%20and%20privacy",
    "Google Safety Centre",
    "Google%20Safety%20Centre",
    "Anthropic",
    "Job%20Application%20for",
    "Presidential Unsealing and Reporting System for UAP Encounters",
    "Presidential%20Unsealing%20and%20Reporting%20System%20for%20UAP%20Encounters",
    "Department of War",
    "Department%20of%20War",
)

STATIC_EXPECTATIONS: tuple[dict[str, str], ...] = (
    {
        "label": "win32_casefold_trace_helper_present",
        "path": "src/display/win32_backend.zig",
        "snippet": "fn traceUrlContainsIgnoreCase(url: []const u8, needle: []const u8) bool {",
    },
    {
        "label": "win32_trace_gate_regression_present",
        "path": "src/display/win32_backend.zig",
        "snippet": 'test "win32 google input trace gate includes attached compatibility pages and headed fixtures" {',
    },
    {
        "label": "render_casefold_trace_helper_present",
        "path": "src/lightpanda.zig",
        "snippet": "fn browseTraceUrlContainsIgnoreCase(url: []const u8, needle: []const u8) bool {",
    },
    {
        "label": "render_trace_gate_regression_present",
        "path": "src/lightpanda.zig",
        "snippet": 'test "browse render trace gate includes attached compatibility pages and headed fixtures" {',
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether the issue #3 runtime trace gates keep the attached-page "
            "target surface in scope."
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


def build_expectations() -> list[dict[str, str]]:
    expectations = [dict(expectation) for expectation in STATIC_EXPECTATIONS]
    for path, prefix in (
        ("src/display/win32_backend.zig", "win32"),
        ("src/lightpanda.zig", "render"),
    ):
        for hint in TRACE_HINTS:
            expectations.append(
                {
                    "label": f"{prefix}_trace_hint::{hint}",
                    "path": path,
                    "snippet": hint,
                }
            )
    return expectations


def audit(repo_root: Path) -> dict[str, object]:
    checks: list[dict[str, object]] = []
    missing = 0

    for expectation in build_expectations():
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
        "expectation_count": len(checks),
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
        print(f"[{status}] issue #3 trace gate runtime audit")
        print(f"Repo root: {result['repo_root']}")
        print(
            f"Matched {result['expectation_count'] - result['missing_count']} of "
            f"{result['expectation_count']} expectations."
        )
        for check in result["checks"]:
            marker = "ok" if check["present"] else "missing"
            print(f"- {marker}: {check['label']} ({check['path']})")

    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())