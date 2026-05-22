from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from issue3_trace_target_catalog import ISSUE3_TRACE_HINTS


EXPECTATIONS = (
    {
        "label": "win32_ignore_case_trace_helper_present",
        "path": "src/display/win32_backend.zig",
        "kind": "snippet",
        "snippet": "fn traceUrlContainsIgnoreCase(url: []const u8, needle: []const u8) bool {",
        "why": (
            "The Win32 input trace gate should use case-insensitive matching so "
            "saved attached-page names and URL-encoded variants stay traceable."
        ),
    },
    {
        "label": "win32_trace_gate_covers_issue3_catalog_hints",
        "path": "src/display/win32_backend.zig",
        "kind": "catalog_hints",
        "why": (
            "The Win32 input trace gate should cover the shared issue #3 target "
            "catalog instead of only direct google.com-shaped URLs."
        ),
    },
    {
        "label": "win32_trace_gate_regression_test_present",
        "path": "src/display/win32_backend.zig",
        "kind": "snippet",
        "snippet": 'test "win32 google input trace gate includes attached compatibility pages and headed fixtures" {',
        "why": (
            "The Win32 trace gate should keep a focused Zig regression test for "
            "the attached compatibility pages and headed fixtures."
        ),
    },
    {
        "label": "render_ignore_case_trace_helper_present",
        "path": "src/lightpanda.zig",
        "kind": "snippet",
        "snippet": "fn browseTraceUrlContainsIgnoreCase(url: []const u8, needle: []const u8) bool {",
        "why": (
            "The headed browse render trace gate should use case-insensitive "
            "matching for the same attached-page targets."
        ),
    },
    {
        "label": "render_trace_gate_covers_issue3_catalog_hints",
        "path": "src/lightpanda.zig",
        "kind": "catalog_hints",
        "why": (
            "The headed browse render trace gate should cover the shared issue "
            "#3 target catalog instead of only the short Google URL matches."
        ),
    },
    {
        "label": "render_trace_gate_regression_test_present",
        "path": "src/lightpanda.zig",
        "kind": "snippet",
        "snippet": 'test "browse render trace gate includes attached compatibility pages and headed fixtures" {',
        "why": (
            "The headed browse render trace gate should keep a focused Zig "
            "regression test for the attached compatibility pages and fixtures."
        ),
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether the live issue #3 trace gates cover the shared "
            "attached-page and fixture target catalog."
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


def missing_catalog_hints(text: str) -> list[str]:
    normalized = text.casefold()
    return [hint for hint in ISSUE3_TRACE_HINTS if hint.casefold() not in normalized]


def audit(repo_root: Path) -> dict[str, object]:
    checks: list[dict[str, object]] = []
    missing = 0

    for expectation in EXPECTATIONS:
        target = repo_root / expectation["path"]
        exists = target.is_file()
        details: list[str] = []
        present = False

        if exists:
            text = target.read_text(encoding="utf-8")
            if expectation["kind"] == "snippet":
                snippet = expectation["snippet"]
                present = snippet in text
            else:
                details = missing_catalog_hints(text)
                present = not details

        if not present:
            missing += 1

        checks.append(
            {
                **expectation,
                "exists": exists,
                "present": present,
                "details": details,
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
        print(f"[{status}] issue #3 trace-gate runtime audit")
        print(f"Repo root: {result['repo_root']}")
        print(
            f"Matched {result['expectation_count'] - result['missing_count']} of "
            f"{result['expectation_count']} expectations."
        )
        for check in result["checks"]:
            marker = "ok" if check["present"] else "missing"
            print(f"- {marker}: {check['label']} ({check['path']})")
            if check["details"]:
                print("  Missing catalog hints:")
                for item in check["details"]:
                    print(f"  - {item}")
            if not check["present"]:
                print(f"  Why: {check['why']}")

    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())