#!/usr/bin/env python3
"""Audit whether local attached-page query and fragment browse inference is present."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "config_local_path_suffix_trim",
        "path": "src/Config.zig",
        "snippet": 'const path_suffix_end = std.mem.indexOfAny(u8, token, "?#") orelse token.len;',
        "why": "Local attached-page inference should ignore query and fragment suffixes before extension checks.",
    },
    {
        "label": "config_local_path_suffix_slice",
        "path": "src/Config.zig",
        "snippet": "const path_suffix = token[0..path_suffix_end];",
        "why": "Extension checks should run against the path portion only.",
    },
    {
        "label": "config_local_html_query_regression",
        "path": "src/Config.zig",
        "snippet": 'test "infer mode treats bare html filename with query as browse" {',
        "why": "Headed startup should keep local .html targets with ?query on the browse path.",
    },
    {
        "label": "config_local_xhtml_fragment_regression",
        "path": "src/Config.zig",
        "snippet": 'test "infer mode treats bare xhtml filename with fragment as browse" {',
        "why": "Headed startup should keep local .xhtml targets with #fragment on the browse path.",
    },
    {
        "label": "config_local_windows_html_query_regression",
        "path": "src/Config.zig",
        "snippet": 'test "infer mode treats relative windows html path with query as browse" {',
        "why": "Windows-style local .html targets with ?query should stay on the browse path.",
    },
    {
        "label": "config_local_windows_xhtml_fragment_regression",
        "path": "src/Config.zig",
        "snippet": 'test "infer mode treats relative windows xhtml path with fragment as browse" {',
        "why": "Windows-style local .xhtml targets with #fragment should stay on the browse path.",
    },
    {
        "label": "config_local_html_query_shared_flag_regression",
        "path": "src/Config.zig",
        "snippet": 'test "infer mode keeps browse for html target with query after shared flag" {',
        "why": "Shared flags before a local .html target with ?query should not knock startup off browse mode.",
    },
    {
        "label": "config_local_xhtml_fragment_shared_flag_regression",
        "path": "src/Config.zig",
        "snippet": 'test "infer mode keeps browse for xhtml target with fragment after shared flag" {',
        "why": "Shared flags before a local .xhtml target with #fragment should still resolve to browse mode.",
    },
    {
        "label": "config_local_windows_html_query_shared_flag_regression",
        "path": "src/Config.zig",
        "snippet": 'test "infer mode keeps browse for windows html target with query after shared flag" {',
        "why": "Windows-style local .html targets with ?query should still resolve to browse after shared flags.",
    },
    {
        "label": "config_local_windows_xhtml_fragment_shared_flag_regression",
        "path": "src/Config.zig",
        "snippet": 'test "infer mode keeps browse for windows xhtml target with fragment after shared flag" {',
        "why": "Windows-style local .xhtml targets with #fragment should still resolve to browse after shared flags.",
    },
    {
        "label": "local_query_fragment_fixture_base_title",
        "path": "tmp-browser-smoke/local-targets/query-fragment-local-target.html",
        "snippet": "<title>Local Query Target plain</title>",
        "why": "The local smoke fixture should start from the plain title before query or fragment logic rewrites it.",
    },
    {
        "label": "local_query_fragment_fixture_dynamic_title_logic",
        "path": "tmp-browser-smoke/local-targets/query-fragment-local-target.html",
        "snippet": "document.title = `Local Query Target ${mode}`;",
        "why": "The local smoke fixture should surface query and fragment state through the page title.",
    },
    {
        "label": "local_query_fragment_probe_query_target",
        "path": "tmp-browser-smoke/local-targets/chrome-local-query-fragment-probe.ps1",
        "snippet": 'target = "tmp-browser-smoke\\local-targets\\query-fragment-local-target.html?case=1"',
        "why": "The headed smoke probe should launch the local target with a query suffix and no explicit browse command.",
    },
    {
        "label": "local_query_fragment_probe_fragment_target",
        "path": "tmp-browser-smoke/local-targets/chrome-local-query-fragment-probe.ps1",
        "snippet": 'target = "tmp-browser-smoke\\local-targets\\query-fragment-local-target.html#focus-probe"',
        "why": "The headed smoke probe should launch the local target with a fragment suffix and no explicit browse command.",
    },
    {
        "label": "local_query_fragment_probe_query_title_wait",
        "path": "tmp-browser-smoke/local-targets/chrome-local-query-fragment-probe.ps1",
        "snippet": 'expected_title = "Local Query Target query case=1"',
        "why": "The headed smoke probe should wait for the query-specific page title before passing.",
    },
    {
        "label": "local_query_fragment_probe_fragment_title_wait",
        "path": "tmp-browser-smoke/local-targets/chrome-local-query-fragment-probe.ps1",
        "snippet": 'expected_title = "Local Query Target fragment focus-probe"',
        "why": "The headed smoke probe should wait for the fragment-specific page title before passing.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether src/Config.zig preserves headed browse inference for "
            "local attached-page targets that include query or fragment suffixes."
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
        print(f"[{status}] local attached-page query/fragment browse inference audit")
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
