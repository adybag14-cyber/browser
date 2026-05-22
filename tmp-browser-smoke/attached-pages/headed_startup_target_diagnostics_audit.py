#!/usr/bin/env python3
"""Audit headed browse startup target diagnostics in src/main.zig."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


SOURCE_PATH = "src/main.zig"

EXPECTATIONS = (
    {
        "label": "browse_startup_logs_target_scheme",
        "snippet": '.target_scheme = browse_target.scheme,',
        "why": "Headed browse startup logs should keep the target scheme visible for quick localhost versus remote diagnosis.",
    },
    {
        "label": "browse_startup_logs_target_scope",
        "snippet": '.target_scope = browse_target.scope,',
        "why": "The startup path should keep surfacing whether a run is internal, local-path, loopback, or remote.",
    },
    {
        "label": "browse_startup_logs_target_host",
        "snippet": '.target_host = browse_target.host,',
        "why": "The host label is needed to distinguish localhost, browser pages, and remote targets in headed validation logs.",
    },
    {
        "label": "browse_startup_logs_target_port",
        "snippet": '.target_port = browse_target.port,',
        "why": "Loopback and remote browse diagnostics should keep the effective port visible.",
    },
    {
        "label": "browser_internal_route_test",
        "snippet": 'const info = browseTargetInfo("browser://downloads");',
        "why": "Internal browser-shell routes should stay covered by the focused target-classification tests.",
    },
    {
        "label": "about_route_test",
        "snippet": 'const info = browseTargetInfo("about:blank#popup-probe");',
        "why": "About-page startup diagnostics should remain pinned as internal routes.",
    },
    {
        "label": "attached_html_local_path_test",
        "snippet": 'const info = browseTargetInfo("attached-page.html?case=1");',
        "why": "Attached HTML launch surfaces should keep reading as local paths in startup diagnostics.",
    },
    {
        "label": "windows_attached_path_test",
        "snippet": 'const info = browseTargetInfo("user_files\\attached-page.xhtml");',
        "why": "Windows attached-page launches should keep their explicit local-path classification coverage.",
    },
    {
        "label": "implicit_loopback_test",
        "snippet": 'const info = browseTargetInfo("localhost:8123/attached-page.html");',
        "why": "Scheme-less localhost launches are a first-line headed validation path and should stay classified as loopback.",
    },
    {
        "label": "implicit_remote_test",
        "snippet": 'const info = browseTargetInfo("example.com/attached-page.html");',
        "why": "The diagnostics surface should keep distinguishing implicit remote launches from attached local pages.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether src/main.zig keeps the headed browse startup "
            "target-diagnostics surface and its focused classification tests."
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=default_repo_root,
        help="Repository root to inspect. Defaults to the current script directory.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit the full audit summary as JSON.",
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
        print(f"[{status}] headed startup target diagnostics audit")
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
