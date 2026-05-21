#!/usr/bin/env python3
"""Audit bare local HTML startup diagnostics expectations in src/main.zig."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "main_bare_local_html_helper",
        "path": "src/main.zig",
        "snippet": "fn looksLikeBareLocalHtmlPath(url: []const u8) bool {",
        "why": "Bare local attached-page HTML targets should have a dedicated helper before implicit remote-host classification runs.",
    },
    {
        "label": "main_bare_local_html_uses_trimmed_candidate",
        "path": "src/main.zig",
        "snippet": "const candidate = browseTargetLocalPathCandidate(url);",
        "why": "The helper should classify the path portion only so query and fragment suffixes do not interfere.",
    },
    {
        "label": "main_bare_local_html_rejects_nested_paths",
        "path": "src/main.zig",
        "snippet": "if (std.mem.indexOfScalar(u8, candidate, '/') != null or",
        "why": "Nested paths should stay on the existing local-path branch instead of the bare-file helper.",
    },
    {
        "label": "main_bare_local_html_route_before_implicit_remote",
        "path": "src/main.zig",
        "snippet": "if (looksLikeBareLocalHtmlPath(url)) {",
        "why": "Bare local HTML files should be classified before implicit remote-host detection can mislabel dotted filenames.",
    },
    {
        "label": "main_bare_local_html_dotted_regression",
        "path": "src/main.zig",
        "snippet": "test \"browse target info keeps dotted bare local html files on the local path route\" {",
        "why": "Dotted bare local HTML filenames such as report.v1.html should stay on the local-path route.",
    },
    {
        "label": "main_bare_local_xhtml_dotted_regression",
        "path": "src/main.zig",
        "snippet": "test \"browse target info keeps dotted bare local xhtml files on the local path route\" {",
        "why": "Dotted bare local XHTML filenames with fragments should stay on the local-path route.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether src/main.zig preserves truthful startup diagnostics "
            "for bare local attached-page HTML and XHTML targets."
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
        print(f"[{status}] bare local html startup diagnostics audit")
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