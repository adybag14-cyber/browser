#!/usr/bin/env python3
"""Audit the dotted local browse-target contract across Config and startup logs."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "config_trim_helper_present",
        "path": "src/Config.zig",
        "snippet": "fn trimLocalBrowseTarget(token: []const u8) []const u8 {",
        "why": "Local browse inference should trim query and fragment suffixes before checking the extension.",
    },
    {
        "label": "config_trim_query_guard",
        "path": "src/Config.zig",
        "snippet": "const query_index = std.mem.indexOfScalar(u8, token, '?') orelse token.len;",
        "why": "Dotted local HTML targets with ?query should keep the browse path.",
    },
    {
        "label": "config_trim_fragment_guard",
        "path": "src/Config.zig",
        "snippet": "const fragment_index = std.mem.indexOfScalar(u8, token, '#') orelse token.len;",
        "why": "Dotted local XHTML targets with #fragment should keep the browse path.",
    },
    {
        "label": "config_trim_candidate_use",
        "path": "src/Config.zig",
        "snippet": "const candidate = trimLocalBrowseTarget(token);",
        "why": "The suffix checks should run against the trimmed local candidate.",
    },
    {
        "label": "config_remote_url_guard",
        "path": "src/Config.zig",
        "snippet": "if (std.mem.indexOf(u8, token, \"://\") != null) {",
        "why": "Remote URLs should not be mistaken for local dotted browse targets.",
    },
    {
        "label": "config_xhtml_suffix_support",
        "path": "src/Config.zig",
        "snippet": "if (candidate.len >= 6 and std.ascii.eqlIgnoreCase(candidate[candidate.len - 6 ..], \".xhtml\")) {",
        "why": "Local XHTML files should stay on the browse path.",
    },
    {
        "label": "config_html_suffix_support",
        "path": "src/Config.zig",
        "snippet": "if (candidate.len >= 5 and std.ascii.eqlIgnoreCase(candidate[candidate.len - 5 ..], \".html\")) {",
        "why": "Local HTML files should stay on the browse path.",
    },
    {
        "label": "main_bare_local_helper_present",
        "path": "src/main.zig",
        "snippet": "fn looksLikeBareLocalHtmlPath(url: []const u8) bool {",
        "why": "Startup diagnostics should recognize bare local HTML and XHTML names before implicit remote classification.",
    },
    {
        "label": "main_bare_local_slash_guard",
        "path": "src/main.zig",
        "snippet": "std.mem.indexOfScalar(u8, candidate, '/') != null or",
        "why": "Only bare local filenames should take the special dotted-file startup route.",
    },
    {
        "label": "main_bare_local_backslash_guard",
        "path": "src/main.zig",
        "snippet": "std.mem.indexOfScalar(u8, candidate, '\\\\') != null",
        "why": "Windows path separators should keep path-like targets out of the bare-filename route.",
    },
    {
        "label": "main_bare_local_helper_use",
        "path": "src/main.zig",
        "snippet": "if (looksLikeBareLocalHtmlPath(url)) {",
        "why": "Browse startup logs should classify bare local HTML/XHTML names as local paths.",
    },
    {
        "label": "main_dotted_html_regression_test",
        "path": "src/main.zig",
        "snippet": "test \"browse target info keeps dotted bare local html files on the local path route\" {",
        "why": "Dotted local HTML filenames should stay pinned to local-path startup diagnostics.",
    },
    {
        "label": "main_dotted_xhtml_regression_test",
        "path": "src/main.zig",
        "snippet": "test \"browse target info keeps dotted bare local xhtml files on the local path route\" {",
        "why": "Dotted local XHTML filenames with fragments should stay pinned to local-path startup diagnostics.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether dotted local HTML/XHTML browse targets stay pinned "
            "to the local-path contract across Config inference and startup diagnostics."
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
        print(f"[{status}] dotted local browse-target contract audit")
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
