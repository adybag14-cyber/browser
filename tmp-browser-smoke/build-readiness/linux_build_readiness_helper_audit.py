#!/usr/bin/env python3
"""Audit the Linux build-readiness helper surface."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


SOURCE_PATH = "scripts/check_linux_build_readiness.py"

EXPECTATIONS = (
    {
        "label": "minimum_zig_parser",
        "snippet": 'MINIMUM_ZIG_RE = re.compile(r\'\\\\.minimum_zig_version\\\\s*=\\\\s*"([^"]+)"\')',
        "why": "The helper should keep discovering the branch Zig floor from build.zig.zon instead of hard-coding it elsewhere.",
    },
    {
        "label": "v8_dependency_markers",
        "snippet": '"v8": ("build.zig", "build.zig.zon", "src/v8.zig"),',
        "why": "The helper should keep checking for the expected sibling V8 checkout layout before Linux validation starts.",
    },
    {
        "label": "boringssl_dependency_markers",
        "snippet": '"boringssl-zig": ("build.zig", "README.md", "generated"),',
        "why": "The helper should keep verifying the saved BoringSSL dependency layout before a build is attempted.",
    },
    {
        "label": "skip_zig_check_flag",
        "snippet": '"--skip-zig-check"',
        "why": "Runs that only want to verify the local dependency layout should keep a way to skip the installed Zig probe.",
    },
    {
        "label": "self_test_flag",
        "snippet": '"--self-test"',
        "why": "The helper should keep exposing a focused self-test route so future runs can validate it quickly.",
    },
    {
        "label": "branch_line_mismatch_message",
        "snippet": "does not match the branch's expected",
        "why": "The failure output should keep calling out when a Zig toolchain is on the wrong major/minor line for this fork.",
    },
    {
        "label": "missing_sibling_dependency_message",
        "snippet": 'missing sibling dependency {name}: expected {dep_path}',
        "why": "Missing sibling dependencies should keep failing fast with a direct path message.",
    },
    {
        "label": "url_backed_dependency_reminder",
        "snippet": "URL-backed dependencies still need network access or an offline cache:",
        "why": "The helper should keep reminding the caller that not every dependency comes from a sibling checkout.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parent.parent.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether scripts/check_linux_build_readiness.py keeps the "
            "expected preflight surface for Linux and WSL validation."
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=default_repo_root,
        help="Repository root to inspect. Defaults to the current checkout.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit the full audit result as JSON.",
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
    result = audit(args.repo_root.resolve())

    if args.json:
        json.dump(result, sys.stdout, indent=2)
        sys.stdout.write("\n")
    else:
        status = "PASS" if result["ok"] else "FAIL"
        print(f"[{status}] linux build-readiness helper audit")
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