#!/usr/bin/env python3
"""Audit main.zig startup routing safeguards for headed runtime diagnostics."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "loopback_helper_present",
        "path": "src/main.zig",
        "snippet": "fn browseTargetImplicitLoopback(url: []const u8) ?BrowseTargetInfo {",
        "why": (
            "Scheme-less localhost and loopback targets need a dedicated helper "
            "so headed startup diagnostics stay on the loopback route."
        ),
    },
    {
        "label": "browser_internal_guard_present",
        "path": "src/main.zig",
        "snippet": "    if (browseTargetInternal(url, scheme)) |internal| {\n        return internal;\n    }\n",
        "why": (
            "Internal browser pages should keep their own startup classification "
            "instead of falling through to remote or local-path labels."
        ),
    },
    {
        "label": "about_internal_guard_present",
        "path": "src/main.zig",
        "snippet": "    if (browseTargetAbout(url)) |about| {\n        return about;\n    }\n",
        "why": (
            "about: targets should stay on the internal route during startup "
            "logging and completion diagnostics."
        ),
    },
    {
        "label": "browser_internal_test_present",
        "path": "src/main.zig",
        "snippet": 'test "browse target info classifies browser downloads pages as internal" {',
        "why": (
            "Regression coverage should keep browser shell pages on the internal "
            "route."
        ),
    },
    {
        "label": "about_fragment_test_present",
        "path": "src/main.zig",
        "snippet": 'test "browse target info keeps about fragments on the internal path" {',
        "why": (
            "Regression coverage should keep about-fragment probes on the "
            "internal path."
        ),
    },
    {
        "label": "schemeless_loopback_test_present",
        "path": "src/main.zig",
        "snippet": 'test "browse target info classifies scheme-less localhost pages as loopback" {',
        "why": (
            "Regression coverage should keep common localhost headed probes on "
            "the loopback route."
        ),
    },
    {
        "label": "fqdn_loopback_test_present",
        "path": "src/main.zig",
        "snippet": 'test "browse target info keeps fully qualified localhost subdomains on the loopback path" {',
        "why": (
            "Regression coverage should keep fully qualified localhost subdomains "
            "on the loopback route."
        ),
    },
    {
        "label": "ipv6_loopback_test_present",
        "path": "src/main.zig",
        "snippet": 'test "browse target info keeps ipv6 loopback hosts on the implicit http route" {',
        "why": (
            "Regression coverage should keep IPv6 loopback headed probes on the "
            "implicit-http loopback route."
        ),
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether src/main.zig keeps browser://, about:, and scheme-less "
            "loopback browse targets on their intended startup routes."
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
        print(f"[{status}] main.zig startup runtime route audit")
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