#!/usr/bin/env python3
"""Audit main.zig startup target routing safeguards for headed local pages."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "bare_local_html_helper_present",
        "path": "src/main.zig",
        "snippet": "fn looksLikeBareLocalHtmlPath(url: []const u8) bool {",
        "why": (
            "Bare local HTML names need a dedicated helper so headed startup "
            "diagnostics can distinguish saved pages from scheme-less remote hosts."
        ),
    },
    {
        "label": "bare_local_html_guard_precedes_implicit_remote",
        "path": "src/main.zig",
        "snippet": (
            "        if (looksLikeBareLocalHtmlPath(url)) {\n"
            "            return .{\n"
            "                .scheme = \"path\",\n"
            "                .scope = \"local_path\",\n"
            "                .host = \"(none)\",\n"
            "                .port = \"(none)\",\n"
            "            };\n"
            "        }\n"
            "        if (browseTargetImplicitRemote(url)) |implicit_remote| {\n"
        ),
        "why": (
            "The bare local HTML guard should run before implicit remote-host "
            "classification so attached pages do not get mislabeled at startup."
        ),
    },
    {
        "label": "dotted_bare_html_regression_test_present",
        "path": "src/main.zig",
        "snippet": (
            "test \"browse target info keeps dotted bare local html files on "
            "the local path route\" {"
        ),
        "why": (
            "Regression coverage should keep dotted bare HTML filenames on the "
            "local-path route."
        ),
    },
    {
        "label": "dotted_bare_xhtml_regression_test_present",
        "path": "src/main.zig",
        "snippet": (
            "test \"browse target info keeps dotted bare local xhtml files on "
            "the local path route\" {"
        ),
        "why": (
            "Regression coverage should keep dotted bare XHTML filenames with "
            "fragments on the local-path route."
        ),
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether src/main.zig protects bare local HTML browse targets "
            "from being classified as implicit remote hosts."
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
        print(f"[{status}] main.zig startup target route audit")
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
