#!/usr/bin/env python3
"""Audit stateful localhost probes for explicit headed launches."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


EXPECTATIONS = (
    {
        "label": "sessionstorage_common_headed_launch",
        "path": "tmp-browser-smoke/sessionstorage-scope/SessionStorageProbeCommon.ps1",
        "snippet": 'return Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Session storage probes should keep using an explicit headed browser launch on localhost pages.",
    },
    {
        "label": "cookie_common_headed_launch",
        "path": "tmp-browser-smoke/cookie-persistence/CookieProbeCommon.ps1",
        "snippet": 'return Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Cookie persistence checks should stay on an explicit headed route while exercising saved browser state.",
    },
    {
        "label": "localstorage_common_headed_launch",
        "path": "tmp-browser-smoke/localstorage-persistence/StorageProbeCommon.ps1",
        "snippet": 'return Start-Process -FilePath $BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "Local storage probes should not fall back to implicit mode selection during localhost validation.",
    },
    {
        "label": "indexeddb_common_headed_launch",
        "path": "tmp-browser-smoke/indexeddb-persistence/IndexedDbProbeCommon.ps1",
        "snippet": 'return Start-Process -FilePath $script:BrowserExe -ArgumentList @("browse","--browser_mode","headed","--window_width","960","--window_height","640",$StartupUrl)',
        "why": "IndexedDB persistence helpers should keep the headed launch request explicit for realistic local state checks.",
    },
    {
        "label": "find_probe_headed_launch",
        "path": "tmp-browser-smoke/find/chrome-find-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList "browse","--browser_mode","headed","http://127.0.0.1:$port/index.html","--window_width","360","--window_height","420","--screenshot_png",$readyPng',
        "why": "Find-in-page localhost probes should stay pinned to headed mode because they validate native window controls and screenshots.",
    },
    {
        "label": "rendered_link_dom_headed_launch",
        "path": "tmp-browser-smoke/rendered-link-dom/chrome-rendered-link-dom-probe.ps1",
        "snippet": '$browser = Start-Process -FilePath $browserExe -ArgumentList @("browse", "--browser_mode", "headed", "--window_width", "960", "--window_height", "720", $indexUrl)',
        "why": "Rendered-link DOM probes should keep an explicit headed launch because they validate live click routing on local pages.",
    },
)


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo_root = script_path.parents[2] if len(script_path.parents) > 2 else script_path.parent

    parser = argparse.ArgumentParser(
        description=(
            "Check whether stateful localhost validation probes launch browse "
            "with an explicit headed request."
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
        print(f"[{status}] headed stateful localhost launch audit")
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