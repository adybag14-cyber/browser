#!/usr/bin/env python3
"""Audit the attached-page and localhost browse-target routing contract in src/main.zig."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "bare_local_html_helper",
        "path": "src/main.zig",
        "snippet": "fn looksLikeBareLocalHtmlPath(url: []const u8) bool {",
        "why": "Attached HTML inputs should stay on an explicit local-path classifier.",
    },
    {
        "label": "local_html_extension_gate",
        "path": "src/main.zig",
        "snippet": (
            '    return std.ascii.endsWithIgnoreCase(candidate, ".xhtml") or\n'
            '        std.ascii.endsWithIgnoreCase(candidate, ".html") or\n'
            '        std.ascii.endsWithIgnoreCase(candidate, ".htm");'
        ),
        "why": "Bare .html, .htm, and .xhtml targets should keep their local-file treatment.",
    },
    {
        "label": "implicit_loopback_helper",
        "path": "src/main.zig",
        "snippet": "fn browseTargetImplicitLoopback(url: []const u8) ?BrowseTargetInfo {",
        "why": "Scheme-less localhost targets should stay on the loopback route.",
    },
    {
        "label": "implicit_remote_helper",
        "path": "src/main.zig",
        "snippet": "fn browseTargetImplicitRemote(url: []const u8) ?BrowseTargetInfo {",
        "why": "Remote host inference should stay separate from localhost inference.",
    },
    {
        "label": "attached_html_local_path_test",
        "path": "src/main.zig",
        "snippet": 'test "browse target info classifies attached html filenames as local paths" {',
        "why": "The source should keep a direct regression test for attached HTML filenames.",
    },
    {
        "label": "attached_html_query_local_path_test",
        "path": "src/main.zig",
        "snippet": 'test "browse target info keeps attached html queries on the local path route" {',
        "why": "Query-bearing attached HTML targets should stay local during headed validation.",
    },
    {
        "label": "attached_xhtml_fragment_local_path_test",
        "path": "src/main.zig",
        "snippet": 'test "browse target info keeps attached xhtml fragments on the local path route" {',
        "why": "Fragment-bearing attached XHTML targets should stay local during headed validation.",
    },
    {
        "label": "scheme_less_localhost_loopback_test",
        "path": "src/main.zig",
        "snippet": 'test "browse target info classifies scheme-less localhost pages as loopback" {',
        "why": "Localhost pages served without an explicit scheme should keep their loopback classification.",
    },
    {
        "label": "scheme_less_localhost_query_loopback_test",
        "path": "src/main.zig",
        "snippet": 'test "browse target info keeps loopback query targets on the implicit http route" {',
        "why": "Query-bearing localhost pages should keep their implicit-http loopback route.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether src/main.zig still keeps the attached-page and "
            "localhost browse-target routing contract that headed validation depends on."
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
        print(f"[{status}] attached-page browse target route audit")
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